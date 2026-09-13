# Data Model — 021 Socle PEI (Phase 1)

**Spec** : [spec.md](spec.md) · **Research** : [research.md](research.md) (R1 convention additive, R6 clé DDE, R14 rejeu)

> **Point de contrôle FR-005** : le SQL ci-dessous (§4) est la proposition à valider par le responsable du projet **avant** toute écriture de code. Il sera recopié tel quel dans `services/16_entrepreneurship.sql` et `migrations/045_entrepreneurship.sql`.

## 1. Vue d'ensemble

```
pei_programs   (dispositifs du parcours)   — indépendant
pei_cohorts    (cohortes FSE / SEE)        — indépendant ; référencé par pei_laureates en 022
pei_resources  (boîte à outils)            — référence media (UUID inter-service, sans FK)
```

Aucune relation entre les trois tables dans cette feature. Références « inter-service » vers la médiathèque (`cover_image_external_id`, `media_external_id`) **sans FK**, comme partout dans le projet (`services.album_external_id`, `fundraisers.cover_image_external_id`).

Convention trilingue **additive** (R1) : `champ` = FR, `champ_en`, `champ_ar` ; contenu riche `champ_html` / `champ_md` + `champ_en_html` / `champ_en_md` / `champ_ar_html` / `champ_ar_md`.

## 2. Entités

### 2.1 `pei_programs` — Dispositif

| Colonne | Type | Contraintes | Rôle |
|---|---|---|---|
| `id` | UUID | PK, `uuid_generate_v4()` | |
| `code` | VARCHAR(60) | UNIQUE NOT NULL, `^[a-z0-9][a-z0-9-]*$` | Identifiant stable (`oser`, `see`, `mti`, `senghor-innov`, `fse`) ; futur segment d'URL |
| `sigle` | VARCHAR(30) | NULL | Acronyme non traduit (OSER, SEE, MTI, FSE) |
| `title` / `title_en` / `title_ar` | VARCHAR(200) | `title` NOT NULL, min 3 | Titre |
| `phase` | `pei_program_phase` | NOT NULL | `awareness`, `status`, `pre_incubation`, `incubation`, `funding`, `ecosystem` |
| `tagline` / `_en` / `_ar` | TEXT | NULL | Accroche courte (carte du parcours) |
| `content_html` / `content_md` | TEXT | NULL | Contenu riche FR (double colonne) |
| `content_en_html` / `content_en_md` / `content_ar_html` / `content_ar_md` | TEXT | NULL | Contenu riche traduit |
| `highlight` / `_en` / `_ar` | VARCHAR(120) | NULL | Chiffre mis en avant (« 4 crédits », « 5 000 € ») |
| `color` | VARCHAR(20) | NOT NULL DEFAULT `'blue'`, CHECK IN (`blue`, `blue_dark`, `red`, `amber`, `teal`) | Couleur nommée (clarification Q5) |
| `cover_image_external_id` | UUID | NULL, sans FK | Visuel (→ `media.id`) |
| `display_order` | INTEGER | NOT NULL DEFAULT 0 | Ordre d'affichage (renuméroté 0..n-1) |
| `active` | BOOLEAN | NOT NULL DEFAULT TRUE | Visible en public |
| `created_at` / `updated_at` | TIMESTAMPTZ | NOT NULL DEFAULT NOW() ; trigger `update_pei_programs_updated_at` | |
| `created_by` / `updated_by` | UUID | FK `users(id)` ON DELETE SET NULL | Traçabilité (comme FAQ) |

Index : `idx_pei_programs_active_order (active, display_order)`.

Règles : `code` unique (409 « Code déjà utilisé »), `title` ≥ 3 caractères, `color` hors liste refusée (422), modification de `code` autorisée mais signalée dans le formulaire. Suppression physique (permission `entrepreneurship.delete`).

### 2.2 `pei_cohorts` — Cohorte

| Colonne | Type | Contraintes | Rôle |
|---|---|---|---|
| `id` | UUID | PK | |
| `code` | VARCHAR(60) | UNIQUE NOT NULL, `^[a-z0-9][a-z0-9-]*$` | `fse-1`, `fse-2`, `fse-3`, `see-2026`… |
| `label` / `_en` / `_ar` | VARCHAR(200) | `label` NOT NULL | « FSE 1 · Lancement 2023 » |
| `year` | INTEGER | NOT NULL, CHECK 2000–2100 | Année de référence |
| `type` | `pei_cohort_type` | NOT NULL | `fse`, `see` |
| `focus` / `_en` / `_ar` | TEXT | NULL | Focus court (« Preuve de concept ») |
| `summary_html` / `summary_md` + `_en_*` / `_ar_*` | TEXT | NULL | Bilan riche trilingue |
| `display_order` | INTEGER | NOT NULL DEFAULT 0 | |
| `active` | BOOLEAN | NOT NULL DEFAULT TRUE | |
| `created_at` / `updated_at` | TIMESTAMPTZ | trigger | |
| `created_by` / `updated_by` | UUID | FK users SET NULL | |

Index : `idx_pei_cohorts_active_order (active, display_order)`, `idx_pei_cohorts_type_year (type, year DESC)`.

Règles : `code` unique (409). Suppression : dans cette feature toujours possible ; le service expose un point d'extension (`_assert_cohort_deletable`) qui lèvera 409 « Cohorte utilisée par N lauréats » en feature 022 (FK `pei_laureates.cohort_id ON DELETE RESTRICT`).

### 2.3 `pei_resources` — Ressource (boîte à outils)

| Colonne | Type | Contraintes | Rôle |
|---|---|---|---|
| `id` | UUID | PK | |
| `title` / `_en` / `_ar` | VARCHAR(200) | `title` NOT NULL | |
| `description` / `_en` / `_ar` | TEXT | NULL | Texte simple (pas de rich text) |
| `type` | `pei_resource_type` | NOT NULL | `document`, `link`, `video` |
| `media_external_id` | UUID | NULL, sans FK | Document de la médiathèque (type `document`) |
| `url` | VARCHAR(500) | NULL | Adresse (types `link`, `video`) |
| `category` / `_en` / `_ar` | VARCHAR(120) | NULL | Catégorie libre (« Financement », « Juridique ») |
| `display_order` | INTEGER | NOT NULL DEFAULT 0 | |
| `is_published` | BOOLEAN | NOT NULL DEFAULT FALSE | |
| `published_at` | TIMESTAMPTZ | NULL | Première publication (conservée) |
| `created_at` / `updated_at` | TIMESTAMPTZ | trigger | |
| `created_by` / `updated_by` | UUID | FK users SET NULL | |

Contrainte de cohérence (SQL + Pydantic) : `chk_pei_resources_source` — `(type = 'document' AND media_external_id IS NOT NULL) OR (type IN ('link','video') AND url IS NOT NULL)`. URL validée par Pydantic (`HttpUrl` → str) : 422 « URL invalide ».

Index : `idx_pei_resources_published_order (is_published, display_order)`.

### 2.4 Permissions (table `permissions` existante)

| code | name_fr | category |
|---|---|---|
| `entrepreneurship.view` | Voir le pôle Entrepreneuriat | entrepreneurship |
| `entrepreneurship.create` | Créer des contenus du pôle Entrepreneuriat | entrepreneurship |
| `entrepreneurship.edit` | Modifier des contenus du pôle Entrepreneuriat | entrepreneurship |
| `entrepreneurship.delete` | Supprimer des contenus du pôle Entrepreneuriat | entrepreneurship |

Attribuées à `super_admin`, `admin`, `editor` (R10).

### 2.5 Clés éditoriales (table `editorial_contents` existante, catégorie `values`)

Voir [contracts/editorial-keys.md](contracts/editorial-keys.md) pour la liste complète (43 clés) et les valeurs initiales.

### 2.6 Audit (table `audit_logs` existante)

`action` ∈ `entrepreneurship.{program|cohort|resource}.{create|update|delete|reorder|activate|deactivate|publish|unpublish}`, `entrepreneurship.translate_missing` ; `table_name` = table réelle ; `old_values` / `new_values` = dict des champs modifiés.

## 3. Transitions d'état

- Dispositif / cohorte : `active` TRUE ⇄ FALSE (`PATCH /{id}/active`), audit `activate` / `deactivate`.
- Ressource : `is_published` FALSE → TRUE fixe `published_at` si NULL ; TRUE → FALSE conserve `published_at` (comme FAQ). Publication refusée (422) si la source est incohérente.
- `display_order` : réécrit intégralement par `reorder` (0..n-1 dans l'ordre reçu) ; création → `MAX(display_order) + 1`.

## 4. SQL de référence proposé — `services/16_entrepreneurship.sql`

```sql
-- ============================================================================
-- SERVICE: ENTREPRENEURSHIP (Pôle Entrepreneuriat et Innovation — PEI)
-- ============================================================================
-- Tables: pei_programs, pei_cohorts, pei_resources
-- Dépendances externes: IDENTITY (users), MEDIA (media — référence sans FK)
-- Spec: specs/021-pei-entrepreneurship-core/
-- Convention trilingue additive : champ (FR), champ_en, champ_ar ;
-- rich text : champ_html / champ_md + champ_en_html / champ_en_md / champ_ar_*
-- ============================================================================

CREATE TYPE pei_program_phase AS ENUM
    ('awareness', 'status', 'pre_incubation', 'incubation', 'funding', 'ecosystem');
CREATE TYPE pei_cohort_type   AS ENUM ('fse', 'see');
CREATE TYPE pei_resource_type AS ENUM ('document', 'link', 'video');

-- Dispositifs du parcours entrepreneurial
CREATE TABLE IF NOT EXISTS pei_programs (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code                    VARCHAR(60)  UNIQUE NOT NULL,
    sigle                   VARCHAR(30),
    title                   VARCHAR(200) NOT NULL,
    title_en                VARCHAR(200),
    title_ar                VARCHAR(200),
    phase                   pei_program_phase NOT NULL,
    tagline                 TEXT,
    tagline_en              TEXT,
    tagline_ar              TEXT,
    content_html            TEXT,
    content_md              TEXT,
    content_en_html         TEXT,
    content_en_md           TEXT,
    content_ar_html         TEXT,
    content_ar_md           TEXT,
    highlight               VARCHAR(120),
    highlight_en            VARCHAR(120),
    highlight_ar            VARCHAR(120),
    color                   VARCHAR(20)  NOT NULL DEFAULT 'blue',
    cover_image_external_id UUID,                      -- → MEDIA.media.id (sans FK)
    display_order           INTEGER      NOT NULL DEFAULT 0,
    active                  BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at              TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    created_by              UUID REFERENCES users(id) ON DELETE SET NULL,
    updated_by              UUID REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT chk_pei_programs_code  CHECK (code ~ '^[a-z0-9][a-z0-9-]*$'),
    CONSTRAINT chk_pei_programs_title CHECK (LENGTH(title) >= 3),
    CONSTRAINT chk_pei_programs_color CHECK (color IN ('blue', 'blue_dark', 'red', 'amber', 'teal'))
);

CREATE INDEX IF NOT EXISTS idx_pei_programs_active_order ON pei_programs (active, display_order);

-- Cohortes (FSE / SEE)
CREATE TABLE IF NOT EXISTS pei_cohorts (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code            VARCHAR(60)  UNIQUE NOT NULL,
    label           VARCHAR(200) NOT NULL,
    label_en        VARCHAR(200),
    label_ar        VARCHAR(200),
    year            INTEGER      NOT NULL,
    type            pei_cohort_type NOT NULL,
    focus           TEXT,
    focus_en        TEXT,
    focus_ar        TEXT,
    summary_html    TEXT,
    summary_md      TEXT,
    summary_en_html TEXT,
    summary_en_md   TEXT,
    summary_ar_html TEXT,
    summary_ar_md   TEXT,
    display_order   INTEGER      NOT NULL DEFAULT 0,
    active          BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    created_by      UUID REFERENCES users(id) ON DELETE SET NULL,
    updated_by      UUID REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT chk_pei_cohorts_code CHECK (code ~ '^[a-z0-9][a-z0-9-]*$'),
    CONSTRAINT chk_pei_cohorts_year CHECK (year BETWEEN 2000 AND 2100)
);

CREATE INDEX IF NOT EXISTS idx_pei_cohorts_active_order ON pei_cohorts (active, display_order);
CREATE INDEX IF NOT EXISTS idx_pei_cohorts_type_year   ON pei_cohorts (type, year DESC);

-- Boîte à outils (documents, liens, vidéos)
CREATE TABLE IF NOT EXISTS pei_resources (
    id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title             VARCHAR(200) NOT NULL,
    title_en          VARCHAR(200),
    title_ar          VARCHAR(200),
    description       TEXT,
    description_en    TEXT,
    description_ar    TEXT,
    type              pei_resource_type NOT NULL,
    media_external_id UUID,                          -- → MEDIA.media.id (sans FK), type = document
    url               VARCHAR(500),                  -- type = link | video
    category          VARCHAR(120),
    category_en       VARCHAR(120),
    category_ar       VARCHAR(120),
    display_order     INTEGER      NOT NULL DEFAULT 0,
    is_published      BOOLEAN      NOT NULL DEFAULT FALSE,
    published_at      TIMESTAMPTZ,
    created_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    created_by        UUID REFERENCES users(id) ON DELETE SET NULL,
    updated_by        UUID REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT chk_pei_resources_source CHECK (
        (type = 'document' AND media_external_id IS NOT NULL)
        OR (type IN ('link', 'video') AND url IS NOT NULL AND LENGTH(url) > 0)
    )
);

CREATE INDEX IF NOT EXISTS idx_pei_resources_published_order ON pei_resources (is_published, display_order);

COMMENT ON TABLE pei_programs  IS '[PEI] Dispositifs du parcours entrepreneurial (OSER, SEE, MTI, Senghor''Innov, FSE).';
COMMENT ON TABLE pei_cohorts   IS '[PEI] Cohortes de lauréats FSE / étudiants-entrepreneurs SEE (lauréats en feature 022).';
COMMENT ON TABLE pei_resources IS '[PEI] Boîte à outils : documents de la médiathèque, liens, vidéos.';
COMMENT ON COLUMN pei_programs.color IS 'Couleur nommée de la charte : blue | blue_dark | red | amber | teal.';

-- Les triggers `update_*_updated_at` sont créés automatiquement par 99_functions.sql.
-- Permissions et données initiales : 99_data_init.sql (base neuve) / migration 045 (bases existantes).
```

## 5. Migration `045_entrepreneurship.sql` — structure

1. `BEGIN;`
2. Types ENUM gardés (`DO $$ BEGIN CREATE TYPE ... EXCEPTION WHEN duplicate_object THEN NULL; END $$;`) ×3.
3. Tables + index (§4, `IF NOT EXISTS`).
4. Triggers `updated_at` ×3 gardés par `IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = ...)`.
5. Permissions (`ON CONFLICT (code) DO NOTHING`) + attribution `super_admin`, `admin`, `editor` (`ON CONFLICT DO NOTHING`).
6. Seed dispositifs (`INSERT ... ON CONFLICT (code) DO NOTHING`), FR seulement :

| ordre | code | sigle | phase | title | highlight | color |
|---|---|---|---|---|---|---|
| 0 | `oser` | OSER | awareness | Parcours OSER | — | teal |
| 1 | `see` | SEE | status | Statut Étudiant-Entrepreneur | 4 crédits · 10 h libérées | blue_dark |
| 2 | `mti` | MTI | pre_incubation | Mature Ton Idée | 4 crédits | blue |
| 3 | `senghor-innov` | — | incubation | Senghor'Innov | — | red |
| 4 | `fse` | FSE | funding | Fonds de Soutien à l'Entrepreneuriat | 5 000 € | amber |

   `tagline` et `content_md` / `content_html` repris du cahier des charges (`accueil.html`, section « Nos activités » ; `statut-etudiant-entrepreneur.html` pour SEE). `content_html` = conversion simple des paragraphes (`<p>…</p>`).

7. Seed cohortes (`ON CONFLICT (code) DO NOTHING`) :

| ordre | code | label | year | type | focus |
|---|---|---|---|---|---|
| 0 | `fse-3` | FSE 3 · Promotion 2025 | 2025 | fse | Innovation et passage à l'échelle — projets incubés via Senghor'Innov |
| 1 | `fse-2` | FSE 2 · Consolidation | 2024 | fse | Dimension intrapreneuriale — projets à fort impact social et technologique |
| 2 | `fse-1` | FSE 1 · Lancement 2023 | 2023 | fse | Preuve de concept — projets en amorçage |

   (ordre d'affichage = plus récent en premier, comme la maquette `alumni.html`).

8. Seed clés éditoriales (`ON CONFLICT (key) DO NOTHING`, catégorie `values`), dont `entrepreneurship.dde_service_id` par sous-requête sur `services.name` (R6).
9. `COMMIT;` puis `\echo 'Migration 045_entrepreneurship terminée'`.

## 6. Rollback `045_entrepreneurship_rollback.sql`

`BEGIN; DROP TABLE IF EXISTS pei_resources, pei_cohorts, pei_programs; DROP TYPE IF EXISTS pei_resource_type, pei_cohort_type, pei_program_phase; DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'entrepreneurship.%'); DELETE FROM permissions WHERE code LIKE 'entrepreneurship.%'; DELETE FROM editorial_contents WHERE key LIKE 'entrepreneurship.%'; COMMIT;`

## 7. Modèles SQLAlchemy (aperçu)

`app/models/entrepreneurship.py` : `PeiProgramPhase`, `PeiCohortType`, `PeiResourceType` (`str, enum.Enum`) ; `PeiProgram`, `PeiCohort`, `PeiResource` (`Base, UUIDMixin, TimestampMixin`), colonnes `Enum(..., create_type=False, values_callable=...)`, `CheckConstraint` répliqués. Export dans `app/models/__init__.py`.

Listes de traduction (R8) :
```python
_PROGRAM_TRANSLATABLE  = [("title","text"), ("tagline","text"), ("highlight","text"), ("content_html","html"), ("content_md","text")]
_COHORT_TRANSLATABLE   = [("label","text"), ("focus","text"), ("summary_html","html"), ("summary_md","text")]
_RESOURCE_TRANSLATABLE = [("title","text"), ("description","text"), ("category","text")]
```
