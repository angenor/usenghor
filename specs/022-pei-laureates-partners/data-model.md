# Data model — 022 Lauréats, étudiants-entrepreneurs et partenaires du pôle

Phase 1 du plan. Le SQL des sections 4 à 6 est une **proposition à valider par le responsable du projet avant tout code** (FR-005).

## 1. Vue d'ensemble

```
pei_cohorts (021) ◄── pei_laureates.cohort_id   (FK, ON DELETE RESTRICT)
media (référence sans FK) ◄── pei_laureates.photo_external_id
partners (06_partner.sql) ◄── pei_partners.partner_id  (FK, PK, ON DELETE CASCADE)
users ◄── created_by / updated_by (ON DELETE SET NULL)
```

Convention trilingue **additive** (021 R1) : `champ` = FR, `champ_en`, `champ_ar`. Aucun contenu riche dans cette feature (verbatim = texte simple, clarification Q4).

## 2. Entités

### 2.1 `pei_laureates` — Portrait (lauréat FSE ou étudiant-entrepreneur)

| Colonne | Type | Contraintes | Rôle |
|---|---|---|---|
| `id` | UUID | PK, `uuid_generate_v4()` | |
| `cohort_id` | UUID | NOT NULL, FK `pei_cohorts(id)` ON DELETE RESTRICT | Cohorte (obligatoire, Q1) |
| `type` | `pei_laureate_type` | NOT NULL | `fse_laureate`, `student_entrepreneur` |
| `full_name` | VARCHAR(200) | NOT NULL, `char_length >= 2` | Nom affiché sur la carte |
| `project_name` | VARCHAR(200) | NOT NULL, `char_length >= 2` | Nom du projet |
| `department_label` / `_en` / `_ar` | VARCHAR(200) | NULL | « Département Santé » (texte libre trilingue) |
| `quote` / `quote_en` / `quote_ar` | TEXT | NULL, `char_length <= 600` chacun | Verbatim (Q4) |
| `photo_external_id` | UUID | NULL, sans FK | → `media.id` (photo portrait) |
| `website_url`, `linkedin_url`, `instagram_url`, `facebook_url`, `video_url` | VARCHAR(500) | NULL | Liens de la carte (validés `HttpUrl` côté API) |
| `grant_amount` | NUMERIC(10,2) | NULL, `>= 0` | Montant de subvention en euros (R9) |
| `is_featured` | BOOLEAN | NOT NULL DEFAULT FALSE | Mis en avant (R12) |
| `is_published` | BOOLEAN | NOT NULL DEFAULT FALSE | Visible en public |
| `published_at` | TIMESTAMPTZ | NULL | Première publication, conservée à la dépublication |
| `display_order` | INTEGER | NOT NULL DEFAULT 0 | **Relatif à la cohorte** (Q3), renuméroté 0..n-1 |
| `created_at` / `updated_at` | TIMESTAMPTZ | NOT NULL DEFAULT NOW(), trigger `update_pei_laureates_updated_at` | |
| `created_by` / `updated_by` | UUID | FK `users(id)` ON DELETE SET NULL | |

Index : `idx_pei_laureates_cohort_order (cohort_id, display_order)`, `idx_pei_laureates_published_type (is_published, type)`.

Règles métier (service, 422) : cohérence `type` ↔ `pei_cohorts.type` (`fse_laureate` ⇔ `fse`, `student_entrepreneur` ⇔ `see`) ; URL valides ; verbatim ≤ 600 par langue (clamp des traductions automatiques, R11) ; montant ≥ 0 (doublé en SQL).

### 2.2 `pei_partners` — Rattachement d'un partenaire au pôle

| Colonne | Type | Contraintes | Rôle |
|---|---|---|---|
| `partner_id` | UUID | **PK**, FK `partners(id)` ON DELETE CASCADE | Un partenaire = une famille au plus (R5) |
| `family` | `pei_partner_family` | NOT NULL | `academic`, `support`, `international` |
| `display_order` | INTEGER | NOT NULL DEFAULT 0 | **Relatif à la famille**, renuméroté 0..n-1 |
| `created_at` / `updated_at` | TIMESTAMPTZ | NOT NULL DEFAULT NOW(), trigger `update_pei_partners_updated_at` | |
| `created_by` / `updated_by` | UUID | FK `users(id)` ON DELETE SET NULL | |

Index : `idx_pei_partners_family_order (family, display_order)`.

Données héritées de `partners` à la lecture (jamais copiées) : `name`, `logo_external_id` → `logo_url`, `description` / `_en` / `_ar`, `website`, `type`, `active`. Public : `active = TRUE` seulement.

### 2.3 Familles (ENUM `pei_partner_family`, ordre fixe)

| Valeur | Libellé FR | Rang |
|---|---|---|
| `academic` | Académiques et institutionnels | 0 |
| `support` | Organisations d'appui | 1 |
| `international` | Organisations internationales | 2 |

### 2.4 Types de portrait (ENUM `pei_laureate_type`)

| Valeur | Libellé FR | Cohorte compatible |
|---|---|---|
| `fse_laureate` | Lauréat FSE | `pei_cohorts.type = 'fse'` |
| `student_entrepreneur` | Étudiant-entrepreneur | `pei_cohorts.type = 'see'` |

### 2.5 Audit (table `audit_logs` existante)

`action` ∈ `entrepreneurship.laureate.{create|update|delete|reorder|publish|unpublish|feature|unfeature}` (`table_name = 'pei_laureates'`) et `entrepreneurship.partner.{link|update|unlink|reorder}` (`table_name = 'pei_partners'`, `record_id = partner_id`). Reorder : `record_id = NULL`, `new_values = {"cohort_id"|"family": …, "ids": [...]}`. `entrepreneurship.translate_missing` inclut désormais `laureates`.

## 3. Transitions d'état et règles d'ordre

- Portrait : `is_published` FALSE → TRUE fixe `published_at` si NULL ; TRUE → FALSE conserve `published_at`. `is_featured` bascule librement.
- Création d'un portrait : `display_order = MAX(display_order) + 1` **dans la cohorte**. Changement de cohorte : `MAX + 1` dans la nouvelle, renumérotation contiguë de l'ancienne. Suppression : renumérotation de la cohorte.
- Rattachement d'un partenaire : `MAX + 1` dans la famille. Changement de famille : idem changement de cohorte. Retrait / cascade : renumérotation de la famille (au retrait ; après cascade, les trous sont tolérés et résorbés au prochain reorder — le tri reste correct).
- Reorder scopé (R2) : le corps porte la portée (`cohort_id` ou `family`) et **tous** les identifiants de cette portée ; identifiant manquant, inconnu, dupliqué ou hors portée → 422.
- Suppression d'une cohorte avec portraits → 409 « Cohorte utilisée par N lauréats » (R4).

## 4. SQL de référence proposé — ajouts à `services/16_entrepreneurship.sql`

À insérer après `pei_resources` (avant le commentaire sur les triggers), en complétant l'en-tête du fichier (« Tables : … pei_laureates, pei_partners ; dépendances : PARTNER (partners) »).

```sql
CREATE TYPE pei_laureate_type  AS ENUM ('fse_laureate', 'student_entrepreneur');
CREATE TYPE pei_partner_family AS ENUM ('academic', 'support', 'international');

-- Portraits : lauréats du FSE et étudiants-entrepreneurs (spec 022)
CREATE TABLE IF NOT EXISTS pei_laureates (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cohort_id           UUID NOT NULL REFERENCES pei_cohorts(id) ON DELETE RESTRICT,
    type                pei_laureate_type NOT NULL,
    full_name           VARCHAR(200) NOT NULL,
    project_name        VARCHAR(200) NOT NULL,
    department_label    VARCHAR(200),
    department_label_en VARCHAR(200),
    department_label_ar VARCHAR(200),
    quote               TEXT,
    quote_en            TEXT,
    quote_ar            TEXT,
    photo_external_id   UUID,                          -- → MEDIA.media.id (sans FK)
    website_url         VARCHAR(500),
    linkedin_url        VARCHAR(500),
    instagram_url       VARCHAR(500),
    facebook_url        VARCHAR(500),
    video_url           VARCHAR(500),
    grant_amount        NUMERIC(10,2),                 -- euros
    is_featured         BOOLEAN      NOT NULL DEFAULT FALSE,
    is_published        BOOLEAN      NOT NULL DEFAULT FALSE,
    published_at        TIMESTAMPTZ,
    display_order       INTEGER      NOT NULL DEFAULT 0,   -- relatif à la cohorte
    created_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    created_by          UUID REFERENCES users(id) ON DELETE SET NULL,
    updated_by          UUID REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT chk_pei_laureates_full_name    CHECK (char_length(full_name) >= 2),
    CONSTRAINT chk_pei_laureates_project_name CHECK (char_length(project_name) >= 2),
    CONSTRAINT chk_pei_laureates_quote_len    CHECK (
        (quote    IS NULL OR char_length(quote)    <= 600) AND
        (quote_en IS NULL OR char_length(quote_en) <= 600) AND
        (quote_ar IS NULL OR char_length(quote_ar) <= 600)),
    CONSTRAINT chk_pei_laureates_grant        CHECK (grant_amount IS NULL OR grant_amount >= 0)
);

CREATE INDEX IF NOT EXISTS idx_pei_laureates_cohort_order   ON pei_laureates (cohort_id, display_order);
CREATE INDEX IF NOT EXISTS idx_pei_laureates_published_type ON pei_laureates (is_published, type);

-- Partenaires du pôle : rattachement + famille (les partenaires vivent dans partners)
CREATE TABLE IF NOT EXISTS pei_partners (
    partner_id     UUID PRIMARY KEY REFERENCES partners(id) ON DELETE CASCADE,
    family         pei_partner_family NOT NULL,
    display_order  INTEGER     NOT NULL DEFAULT 0,       -- relatif à la famille
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by     UUID REFERENCES users(id) ON DELETE SET NULL,
    updated_by     UUID REFERENCES users(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_pei_partners_family_order ON pei_partners (family, display_order);
```

`main.sql` : `16_entrepreneurship.sql` est déjà inclus après `06_partner.sql` (dépendance satisfaite). Triggers `updated_at` : créés par `99_functions.sql` sur base neuve (comme en 021), par la migration sur base existante.

## 5. Migration `migrations/046_pei_laureates_partners.sql` (structure)

```sql
-- 046 : Portraits (lauréats FSE, étudiants-entrepreneurs) et partenaires du pôle PEI
-- Rejouable : types gardés, IF NOT EXISTS, ON CONFLICT DO NOTHING.
-- Dépend de 045_entrepreneurship.sql (pei_cohorts) et de la table partners.
BEGIN;

-- 1. Types ENUM (gardés)
DO $$ BEGIN CREATE TYPE pei_laureate_type  AS ENUM ('fse_laureate', 'student_entrepreneur');
  EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE pei_partner_family AS ENUM ('academic', 'support', 'international');
  EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- 2. Tables et index : bloc identique à la section 4

-- 3. Triggers updated_at (gardés par pg_trigger), boucle FOREACH comme en 045
--    update_pei_laureates_updated_at, update_pei_partners_updated_at → update_updated_at_column()

-- 4. Rattachement initial des partenaires du cahier des charges (R13)
DO $$
DECLARE
  spec  RECORD;
  n     INTEGER;
  rank  INTEGER;
BEGIN
  FOR spec IN
    SELECT * FROM (VALUES
      ('academic',      0, 'r.seau senghor'),
      ('academic',      1, 'campus france'),
      ('support',       0, '\mCEF\M'),
      ('support',       1, '\mCCI\M|chambre de commerce'),
      ('international', 0, '\mAUF\M|agence universitaire de la francophonie'),
      ('international', 1, '\mAFD\M|agence fran.aise de d.veloppement'),
      ('international', 2, '\mOIF\M|organisation internationale de la francophonie')
    ) AS t(family, rank, pattern)
  LOOP
    INSERT INTO pei_partners (partner_id, family, display_order)
    SELECT p.id, spec.family::pei_partner_family, spec.rank
    FROM partners p
    WHERE p.name ~* spec.pattern
    ON CONFLICT (partner_id) DO NOTHING;
    GET DIAGNOSTICS n = ROW_COUNT;
    IF n = 0 THEN
      RAISE NOTICE 'pei_partners : aucun partenaire (nouveau) pour le motif « % » (famille %)', spec.pattern, spec.family;
    END IF;
  END LOOP;
END $$;

-- 5. Renumérotation contiguë par famille (les rangs fixes ci-dessus peuvent laisser des trous)
WITH ranked AS (
  SELECT partner_id, ROW_NUMBER() OVER (PARTITION BY family ORDER BY display_order, created_at) - 1 AS rn
  FROM pei_partners)
UPDATE pei_partners pp SET display_order = r.rn FROM ranked r
WHERE pp.partner_id = r.partner_id AND pp.display_order <> r.rn;

COMMIT;
\echo 'Migration 046_pei_laureates_partners terminée'
```

Le bloc 5 ne réordonne pas les familles déjà contiguës (aucune écriture si rien ne change) ; il ne modifie jamais la famille choisie par un éditeur (bloc 4 : `DO NOTHING`).

## 6. Rollback `migrations/046_pei_laureates_partners_rollback.sql`

```sql
-- Rollback 046 : supprime uniquement ce que 046 a créé. Les portraits et
-- rattachements saisis sont perdus. À jouer AVANT 045_entrepreneurship_rollback.sql.
BEGIN;
DROP TABLE IF EXISTS pei_laureates;
DROP TABLE IF EXISTS pei_partners;
DROP TYPE IF EXISTS pei_laureate_type;
DROP TYPE IF EXISTS pei_partner_family;
COMMIT;
\echo 'Rollback 046_pei_laureates_partners terminé'
```

`045_entrepreneurship_rollback.sql` : ajouter dans l'en-tête « Prérequis : jouer d'abord 046_pei_laureates_partners_rollback.sql (pei_laureates référence pei_cohorts) ».

## 7. Modèles SQLAlchemy et schémas Pydantic (extension des fichiers 021)

- `app/models/entrepreneurship.py` : enums `PeiLaureateType`, `PeiPartnerFamily` ; classes `PeiLaureate(Base, UUIDMixin, TimestampMixin)` (`__tablename__ = "pei_laureates"`, relation `cohort` vers `PeiCohort`) et `PeiPartner(Base, TimestampMixin)` (`__tablename__ = "pei_partners"`, PK `partner_id`, relation `partner` vers `Partner`) ; export dans `app/models/__init__.py`.
- `app/schemas/entrepreneurship.py` : `PeiLaureateCreate` / `Update` / `Admin` / `AdminPage` / `Public` / `TranslateRequest` / `TranslateResponse`, `PeiLaureateReorderRequest {cohort_id, ids}`, `FeaturedRequest {is_featured}`, `FeaturedStatus` ; `PeiPartnerLinkCreate {partner_id, family}`, `PeiPartnerLinkUpdate {family}`, `PeiPartnerLinkAdmin`, `PeiPartnerAvailable`, `PeiPartnerReorderRequest {family, ids}`, `PeiPartnerFamilyPublic {family, partners: PeiPartnerPublic[]}`, `PeiLaureatesPublic {groups, stats}` ; `PeiDashboardStats` + `laureates: PeiPublishedCount`, `partners: PeiActiveCount` ; `PeiTranslateMissingResponse` + `laureates: int`.
- Détail des champs : [contracts/admin-api.md](contracts/admin-api.md), [contracts/public-api.md](contracts/public-api.md).
