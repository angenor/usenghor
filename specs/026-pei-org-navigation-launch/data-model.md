# Data Model — 026 Rattachement du PEI à l'organigramme, navigation et mise en ligne

> **Porte d'accord** : le § 3 (schéma de référence), le § 4 (migration 050) et le § 5 (rollback) sont **à valider avant tout code**. Les fichiers définitifs seront copiés tels quels dans `usenghor_backend/documentation/modele_de_données/migrations/`. Test à blanc du 2026-09-15 en local, en transaction annulée, avec une DDE de test (résultats au § 6).

## 1. Entités

### 1.1 Service (table `services`, étendue)

| Champ | Type | Règles |
|---|---|---|
| `parent_id` *(nouveau)* | UUID NULL | FK `services(id)` `ON DELETE SET NULL` ; ≠ `id` ; le parent n'a pas de parent ; un service qui a des pôles n'a pas de parent ; `sector_id` du pôle = `sector_id` du parent (NULL = NULL) |
| `landing_path` *(nouveau)* | VARCHAR(255) NULL | commence par `/`, pas `//`, pas d'espace (base) ; en plus côté API : pas de préfixe `/en`, `/ar`, pas `/r/`, ni `?` ni `#` ; `''` → NULL |
| `sector_id` | UUID NULL (existant) | le changement est refusé si le service a des pôles |
| autres colonnes | inchangées | — |

**Dérivés (non stockés)** :
- `children` : services dont `parent_id = id`, actifs, triés par `(display_order, name)` ;
- **pôle** : service avec `parent_id` non NULL ;
- **service de premier niveau** : `parent_id` NULL.

**Transitions** :

| Action | Effet sur la hiérarchie |
|---|---|
| Rattacher (`parent_id` ← P) | autorisé si P est de premier niveau, du même secteur, ≠ soi, et que le service n'a pas de pôles |
| Détacher (`parent_id` ← NULL) | toujours autorisé |
| Supprimer le parent | pôles détachés (`SET NULL`), ils deviennent de premier niveau |
| Désactiver le parent | pôles masqués publiquement (organigramme, bloc « Pôles », lien parent), sans modification |
| Changer le secteur d'un parent | refusé tant qu'il a des pôles |
| Dupliquer | copie `parent_id`, pas `landing_path` |

### 1.2 Pôle Entrepreneuriat et Innovation (ligne seedée)

| Champ | Valeur |
|---|---|
| `id` | `5e1c0050-0000-4000-8000-00000000e1ab` (fixe, identifie la ligne créée par 050 pour le rollback) |
| `name` / `name_en` / `name_ar` | Pôle Entrepreneuriat et Innovation / Entrepreneurship and Innovation Hub / قطب ريادة الأعمال والابتكار |
| `sigle` | `PEI` |
| `sector_id`, `color` | ceux de la DDE (production : `SEC-REC`) |
| `parent_id` | DDE (production : `72eca1c4-4109-457e-beae-6a5a4b379b84`) |
| `landing_path` | `/entrepreneuriat` |
| `display_order`, `active` | 0, TRUE |
| description, mission, e-mail, responsable | vides (saisis par l'équipe) |

### 1.3 Entrée de menu (JSON dans `editorial_contents.value`, clé `navbar.secondary.about.children`)

```json
{ "id": "entrepreneurship", "label": "Entreprendre à Senghor", "label_en": "Entrepreneurship at Senghor",
  "label_ar": "ريادة الأعمال في سنغور", "route": "/entrepreneuriat", "icon": "fa-solid fa-lightbulb", "sort_order": 5 }
```

- `label_en` et `label_ar` sont **facultatifs** pour toute entrée (primaire ou « Plus »), avec repli `label`, puis `t('nav.dropdowns.…')`.
- `sort_order` = max existant + 1 (5 en production).
- La réécriture passe par `jsonb` : l'ordre des clés et les espaces du JSON des entrées existantes sont normalisés, mais leurs valeurs sont identiques.

### 1.4 Lien court (table `short_links`)

`code = 'pei'`, `target_url = '/entrepreneuriat'`, `created_by = NULL`. La génération automatique saute tout code existant (R12).

### 1.5 Audit (table `audit_logs`, inchangée)

Rempli par `AuditMiddleware` pour les écritures sur `/api/admin/services/*` : `old_values = to_jsonb(ligne)` (qui inclut les nouvelles colonnes) et `new_values = corps`.

## 2. Modèle et schémas (backend)

- `app/models/organization.py` › `Service` :
  - `parent_id: Mapped[str | None] = mapped_column(UUID(as_uuid=False), ForeignKey("services.id", ondelete="SET NULL"), nullable=True)` ;
  - `landing_path: Mapped[str | None] = mapped_column(String(255))` ;
  - aucune relation ORM `children` / `parent` (évite les cascades et le chargement récursif). Les pôles sont calculés dans le service par requête.
- `app/schemas/organization.py` : voir [contracts/api.md](contracts/api.md) § 1.

## 3. Schéma de référence — `services/04_organization.sql` (à valider)

Dans `CREATE TABLE services`, après `album_external_id` :

```sql
    -- Niveau « pôle » (migration 050) : un seul niveau, même secteur que le parent (trigger)
    parent_id UUID REFERENCES services(id) ON DELETE SET NULL,
    landing_path VARCHAR(255),  -- page dédiée interne sans préfixe de langue, ex. /entrepreneuriat
```

Après la table, avec l'index existant :

```sql
ALTER TABLE services ADD CONSTRAINT services_parent_not_self CHECK (parent_id IS NULL OR parent_id <> id);
ALTER TABLE services ADD CONSTRAINT services_landing_path_format
    CHECK (landing_path IS NULL OR (landing_path ~ '^/' AND landing_path !~ '^//' AND landing_path !~ '\s'));
CREATE INDEX idx_services_parent ON services(parent_id) WHERE parent_id IS NOT NULL;
-- + fonction services_check_hierarchy() et trigger services_check_hierarchy (même corps qu'au § 4)
```

Remarque : dans le `CREATE TABLE`, la contrainte de FK nommée par défaut s'appelle bien `services_parent_id_fkey`, le nom testé par la migration.

## 4. Migration `050_services_parent_landing.sql` (à valider)

```sql
-- ============================================================================
-- Migration 050 : niveau « pôle » des services, rattachement du PEI à la DDE,
--                 entrée de menu « Entreprendre à Senghor », lien court /r/pei
-- Feature 026-pei-org-navigation-launch
-- ============================================================================
-- Effets :
--   1. services.parent_id (FK services.id ON DELETE SET NULL) + services.landing_path,
--      contraintes (pas d'auto-référence, forme du chemin), index partiel,
--      trigger services_check_hierarchy (un seul niveau, même secteur).
--   2. Service « Pôle Entrepreneuriat et Innovation » (PEI, /entrepreneuriat) rattaché
--      à la DDE (clé entrepreneurship.dde_service_id, sinon nom) — identifiant fixe.
--   3. Entrée « entrepreneurship » ajoutée en fin de navbar.secondary.about.children
--      (entrées éditées conservées ; retirée à la main, elle est rajoutée au rejeu).
--   4. Lien court pei → /entrepreneuriat.
-- Rejouable : IF NOT EXISTS, contraintes gardées, insertions conditionnelles, NOTICE.
-- Dépendances : 013 (short_links), 037 (traductions services), 045 (clé DDE, facultative).
-- Rollback : 050_services_parent_landing_rollback.sql — à jouer AVANT les rollbacks 049 → 045.
-- ============================================================================

BEGIN;

-- 1. Structure ----------------------------------------------------------------
ALTER TABLE services ADD COLUMN IF NOT EXISTS parent_id UUID;
ALTER TABLE services ADD COLUMN IF NOT EXISTS landing_path VARCHAR(255);

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'services_parent_id_fkey') THEN
        ALTER TABLE services ADD CONSTRAINT services_parent_id_fkey
            FOREIGN KEY (parent_id) REFERENCES services(id) ON DELETE SET NULL;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'services_parent_not_self') THEN
        ALTER TABLE services ADD CONSTRAINT services_parent_not_self
            CHECK (parent_id IS NULL OR parent_id <> id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'services_landing_path_format') THEN
        ALTER TABLE services ADD CONSTRAINT services_landing_path_format
            CHECK (landing_path IS NULL OR (landing_path ~ '^/' AND landing_path !~ '^//' AND landing_path !~ '\s'));
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_services_parent ON services(parent_id) WHERE parent_id IS NOT NULL;

CREATE OR REPLACE FUNCTION services_check_hierarchy() RETURNS TRIGGER AS $$
DECLARE
    parent_row RECORD;
    n_children INTEGER;
BEGIN
    SELECT count(*) INTO n_children FROM services WHERE parent_id = NEW.id AND id <> NEW.id;

    IF NEW.parent_id IS NOT NULL THEN
        SELECT id, parent_id, sector_id INTO parent_row FROM services WHERE id = NEW.parent_id;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Service parent introuvable' USING ERRCODE = 'check_violation';
        END IF;
        IF parent_row.parent_id IS NOT NULL THEN
            RAISE EXCEPTION 'Le service parent est lui-même un pôle (un seul niveau)' USING ERRCODE = 'check_violation';
        END IF;
        IF n_children > 0 THEN
            RAISE EXCEPTION 'Ce service a % pôle(s) : il ne peut pas être rattaché', n_children USING ERRCODE = 'check_violation';
        END IF;
        IF parent_row.sector_id IS DISTINCT FROM NEW.sector_id THEN
            RAISE EXCEPTION 'Le service parent doit appartenir au même secteur' USING ERRCODE = 'check_violation';
        END IF;
    END IF;

    IF TG_OP = 'UPDATE' AND n_children > 0 AND NEW.sector_id IS DISTINCT FROM OLD.sector_id THEN
        RAISE EXCEPTION 'Déplacez ou détachez d''abord ses % pôle(s)', n_children USING ERRCODE = 'check_violation';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS services_check_hierarchy ON services;
CREATE TRIGGER services_check_hierarchy
    BEFORE INSERT OR UPDATE OF parent_id, sector_id ON services
    FOR EACH ROW EXECUTE FUNCTION services_check_hierarchy();

-- 2. Pôle Entrepreneuriat et Innovation ----------------------------------------
DO $$
DECLARE
    pole_fixed CONSTANT UUID := '5e1c0050-0000-4000-8000-00000000e1ab';
    key_value  TEXT;
    dde_id     UUID;
    dde_sector UUID;
    dde_parent UUID;
    dde_color  VARCHAR(7);
    n_match    INTEGER;
    pole_id    UUID;
BEGIN
    SELECT value INTO key_value FROM editorial_contents WHERE key = 'entrepreneurship.dde_service_id';
    IF key_value ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN
        SELECT id, sector_id, parent_id, color INTO dde_id, dde_sector, dde_parent, dde_color FROM services WHERE id = key_value::uuid;
    END IF;

    IF dde_id IS NULL THEN
        -- « _ » : apostrophe droite ou typographique ; « veloppement » : évite la casse du « é »
        SELECT count(*) INTO n_match FROM services WHERE name ILIKE '%veloppement et de l_entrepreneuriat%';
        IF n_match = 1 THEN
            SELECT id, sector_id, parent_id, color INTO dde_id, dde_sector, dde_parent, dde_color FROM services
            WHERE name ILIKE '%veloppement et de l_entrepreneuriat%';
        ELSE
            RAISE NOTICE 'PEI : DDE non résolue (clé vide ou invalide, % service(s) correspondant au nom) — pôle non créé, rattachement à faire en backoffice', n_match;
            RETURN;
        END IF;
    END IF;

    IF dde_parent IS NOT NULL THEN
        RAISE NOTICE 'PEI : la DDE (%) est elle-même rattachée à un parent — pôle non créé', dde_id;
        RETURN;
    END IF;

    SELECT id INTO pole_id FROM services
    WHERE id = pole_fixed
       OR landing_path = '/entrepreneuriat'
       OR (sigle ILIKE 'PEI' AND sector_id IS NOT DISTINCT FROM dde_sector)
       OR name ILIKE 'p_le entrepreneuriat et innovation'
    ORDER BY (id = pole_fixed) DESC, (landing_path = '/entrepreneuriat') DESC NULLS LAST, created_at
    LIMIT 1;

    IF pole_id IS NULL THEN
        INSERT INTO services (id, sector_id, parent_id, name, name_en, name_ar, sigle, color,
                              landing_path, display_order, active)
        VALUES (pole_fixed, dde_sector, dde_id, 'Pôle Entrepreneuriat et Innovation',
                'Entrepreneurship and Innovation Hub', 'قطب ريادة الأعمال والابتكار', 'PEI', dde_color,
                '/entrepreneuriat', 0, TRUE);
        RAISE NOTICE 'PEI : pôle créé (%) sous la DDE (%)', pole_fixed, dde_id;
    ELSIF pole_id = dde_id THEN
        RAISE NOTICE 'PEI : le service trouvé est la DDE elle-même — rien à faire';
    ELSE
        UPDATE services
        SET parent_id    = COALESCE(parent_id, CASE WHEN sector_id IS NOT DISTINCT FROM dde_sector
                                                     AND NOT EXISTS (SELECT 1 FROM services c WHERE c.parent_id = pole_id)
                                                    THEN dde_id END),
            landing_path = COALESCE(landing_path, '/entrepreneuriat'),
            updated_at   = NOW()
        WHERE id = pole_id
          AND (parent_id IS NULL OR landing_path IS NULL);
        RAISE NOTICE 'PEI : pôle déjà présent (%) — complété si nécessaire, valeurs existantes conservées', pole_id;
    END IF;
END $$;

-- 3. Menu « Plus » › Nous connaître ---------------------------------------------
DO $$
DECLARE
    entry JSONB := jsonb_build_object(
        'id', 'entrepreneurship',
        'label', 'Entreprendre à Senghor',
        'label_en', 'Entrepreneurship at Senghor',
        'label_ar', 'ريادة الأعمال في سنغور',
        'route', '/entrepreneuriat',
        'icon', 'fa-solid fa-lightbulb');
    raw  TEXT;
    arr  JSONB;
    next_order INTEGER;
BEGIN
    SELECT value INTO raw FROM editorial_contents WHERE key = 'navbar.secondary.about.children';

    IF NOT FOUND OR raw IS NULL OR btrim(raw) = '' THEN
        INSERT INTO editorial_contents (key, value, value_type, category_id, description, admin_editable)
        VALUES ('navbar.secondary.about.children',
                jsonb_build_array(entry || '{"sort_order": 1}')::text, 'json',
                (SELECT id FROM editorial_categories WHERE code = 'values'),
                'Sous-items du menu secondaire "Nous connaitre"', TRUE)
        ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, updated_at = NOW()
            WHERE editorial_contents.value IS NULL OR btrim(editorial_contents.value) = '';
        RAISE NOTICE 'Menu : liste « Nous connaître » créée avec l''entrée du pôle';
        RETURN;
    END IF;

    BEGIN
        arr := raw::jsonb;
    EXCEPTION WHEN others THEN
        RAISE NOTICE 'Menu : valeur de navbar.secondary.about.children illisible — non modifiée';
        RETURN;
    END;

    IF jsonb_typeof(arr) <> 'array' THEN
        RAISE NOTICE 'Menu : navbar.secondary.about.children n''est pas un tableau — non modifiée';
        RETURN;
    END IF;

    IF EXISTS (SELECT 1 FROM jsonb_array_elements(arr) e
               WHERE e->>'id' = 'entrepreneurship' OR e->>'route' = '/entrepreneuriat') THEN
        RAISE NOTICE 'Menu : entrée du pôle déjà présente — non modifiée';
        RETURN;
    END IF;

    SELECT COALESCE(max(CASE WHEN (e->>'sort_order') ~ '^-?[0-9]+$' THEN (e->>'sort_order')::int END), 0) + 1
    INTO next_order FROM jsonb_array_elements(arr) e;

    UPDATE editorial_contents
    SET value = (arr || jsonb_build_array(entry || jsonb_build_object('sort_order', next_order)))::text,
        updated_at = NOW()
    WHERE key = 'navbar.secondary.about.children';
    RAISE NOTICE 'Menu : entrée du pôle ajoutée (sort_order %)', next_order;
END $$;

-- 4. Lien court /r/pei -----------------------------------------------------------
INSERT INTO short_links (code, target_url, created_by)
VALUES ('pei', '/entrepreneuriat', NULL)
ON CONFLICT (code) DO NOTHING;

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM short_links WHERE code = 'pei' AND target_url <> '/entrepreneuriat') THEN
        RAISE NOTICE 'Lien court : le code pei existe déjà vers une autre cible — non modifié';
    END IF;
END $$;

COMMIT;

\echo 'Migration 050_services_parent_landing terminée'
```

## 5. Rollback `050_services_parent_landing_rollback.sql` (à valider)

**Ordre** : `050_…_rollback.sql` **avant** `049_pei_see_page_rollback.sql` → … → `045_entrepreneurship_rollback.sql`.

```sql
-- ============================================================================
-- Rollback 050 : à jouer AVANT les rollbacks 049 → 045.
-- Retire exactement ce que la migration 050 a ajouté, dans l'ordre inverse :
-- lien court pei, entrée de menu « entrepreneurship », pôle créé (identifiant fixe),
-- trigger, fonction, contraintes, index et colonnes. Rejouable sans erreur.
-- ============================================================================

BEGIN;

DELETE FROM short_links WHERE code = 'pei' AND target_url = '/entrepreneuriat';

DO $$
DECLARE
    raw TEXT;
    arr JSONB;
BEGIN
    SELECT value INTO raw FROM editorial_contents WHERE key = 'navbar.secondary.about.children';
    IF raw IS NULL OR btrim(raw) = '' THEN
        RETURN;
    END IF;
    BEGIN
        arr := raw::jsonb;
    EXCEPTION WHEN others THEN
        RAISE NOTICE 'Menu : valeur illisible — non modifiée';
        RETURN;
    END;
    IF jsonb_typeof(arr) = 'array' THEN
        UPDATE editorial_contents
        SET value = COALESCE((SELECT jsonb_agg(e ORDER BY ord) FROM jsonb_array_elements(arr) WITH ORDINALITY AS t(e, ord)
                              WHERE e->>'id' IS DISTINCT FROM 'entrepreneurship'), '[]'::jsonb)::text,
            updated_at = NOW()
        WHERE key = 'navbar.secondary.about.children'
          AND EXISTS (SELECT 1 FROM jsonb_array_elements(arr) e WHERE e->>'id' = 'entrepreneurship');
    END IF;
END $$;

DO $$
DECLARE
    pole_fixed CONSTANT UUID := '5e1c0050-0000-4000-8000-00000000e1ab';
    has_content BOOLEAN;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM services WHERE id = pole_fixed) THEN
        RETURN;
    END IF;
    SELECT EXISTS (SELECT 1 FROM service_team WHERE service_id = pole_fixed)
        OR EXISTS (SELECT 1 FROM service_objectives WHERE service_id = pole_fixed)
        OR EXISTS (SELECT 1 FROM service_achievements WHERE service_id = pole_fixed)
        OR EXISTS (SELECT 1 FROM service_projects WHERE service_id = pole_fixed)
        OR EXISTS (SELECT 1 FROM service_media_library WHERE service_id = pole_fixed)
    INTO has_content;
    IF has_content THEN
        RAISE NOTICE 'PEI : le pôle (%) a du contenu rattaché — conservé comme service de premier niveau', pole_fixed;
    ELSE
        DELETE FROM services WHERE id = pole_fixed;
        RAISE NOTICE 'PEI : pôle créé par la migration 050 supprimé';
    END IF;
END $$;

DROP TRIGGER IF EXISTS services_check_hierarchy ON services;
DROP FUNCTION IF EXISTS services_check_hierarchy();
DROP INDEX IF EXISTS idx_services_parent;
ALTER TABLE services DROP CONSTRAINT IF EXISTS services_landing_path_format;
ALTER TABLE services DROP CONSTRAINT IF EXISTS services_parent_not_self;
ALTER TABLE services DROP CONSTRAINT IF EXISTS services_parent_id_fkey;
ALTER TABLE services DROP COLUMN IF EXISTS landing_path;
ALTER TABLE services DROP COLUMN IF EXISTS parent_id;

COMMIT;

\echo 'Rollback 050_services_parent_landing terminé'
```

## 6. Test à blanc (local, 2026-09-15, `BEGIN … ROLLBACK`)

| Cas | Résultat |
|---|---|
| Passage 1 (DDE de test au nom avec apostrophe typographique, clé vide) | colonnes, contraintes, index et trigger créés ; `PEI : pôle créé … sous la DDE` ; `Menu : entrée du pôle ajoutée (sort_order 5)` ; `INSERT 0 1` (lien court) |
| Passage 2 | `pôle déjà présent — complété si nécessaire` ; `entrée du pôle déjà présente` ; `INSERT 0 0` ; comptes identiques : 1 PEI, 5 entrées de menu, 1 lien `pei` |
| Trigger | refus : auto-référence (« Ce service a 1 pôle(s) »), second niveau (« Le service parent est lui-même un pôle »), rattachement d'un parent de pôle, parent d'un autre secteur, changement de secteur du parent (« Déplacez ou détachez d'abord ses 1 pôle(s) ») ; `landing_path='//evil'` refusé par CHECK ; rattachement valide et renommage acceptés ; suppression de la DDE → pôle détaché |
| Rollback ×2 | pôle supprimé, entrée de menu retirée (4 entrées restantes, identiques), lien supprimé, colonnes retirées ; second passage sans erreur |
| Rejeu après rollback | pôle recréé, entrée rajoutée |
| Aucune DDE + menu illisible | NOTICE « DDE non résolue (… 0 service(s)) », aucun pôle ; NOTICE « valeur … illisible — non modifiée » |
| Clé désignant un service au nom différent + menu vide | pôle créé sous le service de la clé ; liste créée avec la seule entrée |
| État de la base locale après tests | inchangé (3 services, pas de colonne `parent_id`) |

**Production (lecture seule, 2026-09-15)** : clé → DDE `72eca1c4-…` (active, sans parent, `SEC-REC`) ; motif de nom → 1 ligne ; aucun `PEI` ni `/entrepreneuriat` ; `pei` libre ; menu `about` à 4 entrées → l'entrée du pôle aura `sort_order` 5.

## 7. Points à confirmer avec l'accord SQL

1. Libellés anglais et arabe du pôle (« Entrepreneurship and Innovation Hub », « قطب ريادة الأعمال والابتكار ») et de l'entrée de menu ou du pied de page (« Entrepreneurship at Senghor », « ريادة الأعمال في سنغور »).
2. Icône `fa-solid fa-lightbulb` (déjà utilisée par KreAfrika dans « Nos projets » ; alternative `fa-solid fa-rocket`, utilisée par Transform'Action).
3. Trigger en base en plus de la validation backend (R1).
4. Rollback : le pôle est conservé s'il a reçu du contenu (équipe, objectifs, médias…), sinon supprimé.
5. Normalisation du JSON du menu (ordre des clés et espaces) lors de l'ajout.
