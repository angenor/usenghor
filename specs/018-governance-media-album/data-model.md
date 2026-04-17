# Phase 1 — Data Model: Album médiathèque « Gouvernance »

**Feature**: 018-governance-media-album
**Date**: 2026-04-16
**Sources**: spec.md (FR-001 à FR-023, A1–A7, Q1–Q5), research.md (D1–D8)

## 1. Vue d'ensemble

La feature ne crée pas de nouvelle table. Elle :

1. **Enrichit** la table `media` d'une colonne `thumbnail_url VARCHAR(500) NULL` (résolution d'incohérence schéma ⇄ types TS, cf. research D1).
2. **Crée un jeu de données** :
   - Une ligne unique dans `albums` (slug `gouvernance`).
   - N lignes dans `media` (une par document fondateur).
   - N lignes dans `album_media` (liaison + ordre).
3. **Ne modifie pas** : `editorial_contents` (la clé `governance.foundingTexts.documents` est conservée mais plus utilisée côté public).

## 2. Entités

### 2.1 Album « Gouvernance »

| Champ | Type | Source / règle |
|-------|------|----------------|
| `id` | UUID | Généré par `uuid_generate_v4()` ou conservé si l'album existe déjà (idempotence via slug). |
| `title` | VARCHAR(255) | Littéral `'Gouvernance'`. |
| `description` | TEXT | Littéral `'Textes fondateurs de l''Université Senghor (chartes, conventions, statuts).'`. |
| `slug` | VARCHAR(300) UNIQUE | Littéral `'gouvernance'`. |
| `status` | `publication_status` | `'published'`. |
| `created_at` / `updated_at` | TIMESTAMPTZ | Par défaut. |

**Invariants**
- L'album est unique (contrainte `UNIQUE` sur `slug`).
- Sa suppression casse en CASCADE les lignes `album_media` associées (mais pas les `media`).

### 2.2 Document fondateur (ligne `media` de type `document`)

| Champ `media` | Source JSON (clé éditoriale) | Transformation |
|----------------|------------------------------|----------------|
| `id` | — | Généré ou conservé si URL déjà présente. |
| `name` | `title_fr` | Copie directe. `NOT NULL`, max 255. |
| `description` | `description_fr` | Copie directe, peut être `NULL`. |
| `type` | — | Littéral `'document'` (enum `media_type`). |
| `url` | `file_url` | Copie directe. **Clé d'idempotence.** `NOT NULL`, max 500. |
| `is_external_url` | — | `FALSE` par défaut (les URLs pointent sur le backend ou un CDN maîtrisé). |
| `size_bytes` | `file_size` | Copie directe ou `NULL`. |
| `mime_type` | — | Littéral `'application/pdf'` (cf. A2). |
| `width`, `height`, `duration_seconds` | — | `NULL`. |
| `alt_text` | — | `NULL` (non défini dans la source ; le frontend sait déjà retomber sur `name`). |
| `credits` | `year` | Conversion en chaîne si présent, ex. `2015 → '2015'`. `NULL` sinon. |
| `thumbnail_url` ***(nouveau)*** | `cover_image` | Copie directe ou `NULL`. |
| `created_at` / `updated_at` | — | Par défaut. |

**Invariants**
- Deux documents ne peuvent pas partager la même URL → c'est ce qui garantit l'idempotence. (NB : il n'y a pas de contrainte unique explicite sur `media.url` ; l'idempotence est assurée par la logique de la migration — `WHERE NOT EXISTS`.)
- `mime_type = 'application/pdf'` et `type = 'document'` pour cette feature uniquement. Les valeurs peuvent diverger plus tard si l'admin ajoute d'autres formats.

### 2.3 Liaison `album_media`

| Champ | Valeur |
|-------|--------|
| `album_id` | ID de l'album `gouvernance`. |
| `media_id` | ID du média (créé ou retrouvé). |
| `display_order` | Copie de `sort_order` du JSON, ou index dans le tableau si `sort_order` est absent. |

**Invariants**
- PK composite `(album_id, media_id)` → un même document ne peut être lié deux fois au même album.
- `ON DELETE CASCADE` : supprimer un média retire automatiquement sa liaison ; supprimer l'album retire toutes ses liaisons.
- Le `display_order` est **réapliqué** à chaque run de la migration (via `ON CONFLICT DO UPDATE`) pour permettre la correction de l'ordre.

## 3. Règle de migration (pseudo-code SQL)

```sql
BEGIN;

-- 3.1 Évolution de schéma (idempotente)
ALTER TABLE media ADD COLUMN IF NOT EXISTS thumbnail_url VARCHAR(500);

-- 3.2 Création / upsert de l'album
WITH upsert_album AS (
  INSERT INTO albums (slug, title, description, status)
  VALUES ('gouvernance', 'Gouvernance',
          'Textes fondateurs de l''Université Senghor (chartes, conventions, statuts).',
          'published')
  ON CONFLICT (slug) DO UPDATE
    SET title = EXCLUDED.title,
        description = EXCLUDED.description,
        status = EXCLUDED.status,
        updated_at = NOW()
  RETURNING id
)
SELECT id INTO TEMP TABLE _governance_album_id FROM upsert_album;

-- 3.3 Extraction des documents depuis editorial_contents
CREATE TEMP TABLE _source_docs AS
SELECT
  (elem->>'title_fr')::TEXT          AS name,
  NULLIF(elem->>'description_fr','') AS description,
  (elem->>'file_url')::TEXT          AS url,
  NULLIF(elem->>'file_size','')::BIGINT         AS size_bytes,
  NULLIF(elem->>'cover_image','')    AS thumbnail_url,
  NULLIF(elem->>'year','')           AS credits,
  COALESCE(NULLIF(elem->>'sort_order','')::INT,
           (row_number() OVER ())::INT - 1)     AS display_order
FROM editorial_contents ec,
     jsonb_array_elements(ec.value::jsonb) AS elem
WHERE ec.key = 'governance.foundingTexts.documents'
  AND ec.value_type = 'JSON'
  AND elem->>'file_url' IS NOT NULL;

-- 3.4 Upsert média par URL
INSERT INTO media (name, description, type, url, mime_type,
                   size_bytes, thumbnail_url, credits, is_external_url)
SELECT s.name, s.description, 'document', s.url, 'application/pdf',
       s.size_bytes, s.thumbnail_url, s.credits, FALSE
FROM _source_docs s
WHERE NOT EXISTS (SELECT 1 FROM media m WHERE m.url = s.url);

-- Mise à jour des champs pour les médias déjà existants (même URL)
UPDATE media m
SET name          = s.name,
    description   = s.description,
    size_bytes    = COALESCE(s.size_bytes, m.size_bytes),
    thumbnail_url = COALESCE(s.thumbnail_url, m.thumbnail_url),
    credits       = COALESCE(s.credits, m.credits),
    updated_at    = NOW()
FROM _source_docs s
WHERE m.url = s.url;

-- 3.5 Liaison album ⇄ média
INSERT INTO album_media (album_id, media_id, display_order)
SELECT
  (SELECT id FROM _governance_album_id),
  m.id,
  s.display_order
FROM _source_docs s
JOIN media m ON m.url = s.url
ON CONFLICT (album_id, media_id) DO UPDATE
  SET display_order = EXCLUDED.display_order;

-- 3.6 Cleanup
DROP TABLE IF EXISTS _source_docs;
DROP TABLE IF EXISTS _governance_album_id;

COMMIT;
```

## 4. Règle de rollback (pseudo-code SQL)

```sql
BEGIN;

-- 4.1 Retrouve l'album
-- Si aucun album 'gouvernance' n'existe, sortie silencieuse (RAISE NOTICE).

-- 4.2 Retrouve les URLs à supprimer depuis la source
-- (même requête que 3.3, mais limitée aux URLs effectivement liées à l'album gouvernance).
CREATE TEMP TABLE _to_remove AS
SELECT m.id AS media_id, m.url
FROM media m
JOIN album_media am ON am.media_id = m.id
JOIN albums a ON a.id = am.album_id
WHERE a.slug = 'gouvernance'
  AND m.url IN (
    SELECT (elem->>'file_url')::TEXT
    FROM editorial_contents ec,
         jsonb_array_elements(ec.value::jsonb) AS elem
    WHERE ec.key = 'governance.foundingTexts.documents'
  );

-- 4.3 Supprime les liaisons
DELETE FROM album_media
WHERE media_id IN (SELECT media_id FROM _to_remove)
  AND album_id = (SELECT id FROM albums WHERE slug = 'gouvernance');

-- 4.4 Supprime les médias orphelins (plus référencés par aucun album_media)
DELETE FROM media m
WHERE m.id IN (SELECT media_id FROM _to_remove)
  AND NOT EXISTS (SELECT 1 FROM album_media am WHERE am.media_id = m.id);

-- 4.5 Supprime l'album si vide
DELETE FROM albums
WHERE slug = 'gouvernance'
  AND NOT EXISTS (
    SELECT 1 FROM album_media am
    WHERE am.album_id = (SELECT id FROM albums WHERE slug = 'gouvernance')
  );

DROP TABLE IF EXISTS _to_remove;

COMMIT;
```

**Note rollback**
- La colonne `thumbnail_url` ajoutée n'est **pas supprimée** par le rollback (enrichissement durable de schéma, bénéfique à d'autres features, cf. research D1).
- Si la clé éditoriale `governance.foundingTexts.documents` a été supprimée avant le rollback, le script ne peut plus reconstituer la liste des URLs ; il devient no-op sur la partie suppression de médias. Solution : exécuter le rollback **tant que la clé source est encore présente** (préservée par A6).

## 5. État backend après migration

### 5.1 Schéma Pydantic `MediaRead` (extension)

```python
class MediaRead(MediaBase):
    id: str
    type: MediaType
    url: str
    is_external_url: bool
    size_bytes: int | None
    mime_type: str | None
    width: int | None
    height: int | None
    duration_seconds: int | None
    thumbnail_url: str | None  # <— nouveau champ (D1)
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}
```

### 5.2 Schéma Pydantic `MediaCreate` / `MediaUpdate` / `MediaExternalCreate`

Ajouter `thumbnail_url: str | None = None` pour permettre l'écriture via l'admin.

### 5.3 Modèle SQLAlchemy `Media`

Ajouter `thumbnail_url: Mapped[str | None] = mapped_column(String(500), nullable=True)`.

### 5.4 `CoverMedia` (utilisé dans `PublicAlbumListItem`)

```python
class CoverMedia(BaseModel):
    id: str
    url: str
    thumbnail_url: str | None  # <— nouveau champ (D8)
    type: MediaType
    name: str
```

### 5.5 Service `media_service.get_published_albums_list()`

Vérifier (ou corriger) le tri pour la récupération de `cover_media` :
```sql
-- pour chaque album, prendre le 1er média selon display_order asc puis created_at asc
ORDER BY am.display_order ASC NULLS LAST, m.created_at ASC
LIMIT 1
```

## 6. État frontend après migration

### 6.1 `FoundingDocument` (inchangé)

```typescript
interface FoundingDocument {
  id: string
  title_fr: string
  description_fr?: string
  file_url: string
  file_size?: number
  year?: number
  cover_image?: string
  document_category?: string
  sort_order?: number
}
```

### 6.2 Mapper (ajouté dans `gouvernance.vue`)

```typescript
function mapMediaToFoundingDocument(m: MediaRead, index: number): FoundingDocument {
  return {
    id: m.id,
    title_fr: m.name,
    description_fr: m.description ?? undefined,
    file_url: m.url,
    file_size: m.size_bytes ?? undefined,
    year: m.credits ? Number.parseInt(m.credits, 10) || undefined : undefined,
    cover_image: m.thumbnail_url ?? undefined,
    sort_order: index,  // display_order déjà respecté par l'API
  }
}
```

Le parent `gouvernance.vue` conserve par ailleurs une map `Record<string, MediaRead>` (id → raw) pour passer le `MediaRead` complet au `MediaFilePreviewModal` à l'ouverture.

## 7. Règles d'intégrité (récap)

| Règle | Support |
|-------|---------|
| Idempotence de la migration | Contrainte `UNIQUE (slug)` sur `albums` + logique `WHERE NOT EXISTS` sur `media.url` + `ON CONFLICT` sur `album_media`. |
| Rollback non destructif | Conditionné à l'existence de la clé source et à la non-orphelinage des médias. |
| Préservation des ajouts manuels | Le rollback ne supprime QUE les médias dont l'URL figure dans la clé source. |
| Cohérence d'affichage public | API filtre déjà `status = 'published'` ET album non vide ; pas de changement. |
| Ordre d'affichage public | Garanti par `display_order ASC` (à vérifier dans les queries de service, cf. D8). |
| Trilinguisme | Aucune colonne multilingue ajoutée (cf. A1, Q3) ; les libellés sont en FR partout. |

## 8. Fichiers impactés (récap)

| Fichier | Nature |
|---------|--------|
| `usenghor_backend/documentation/modele_de_données/services/03_media.sql` | Ajout colonne `thumbnail_url` dans la définition canonique. |
| `usenghor_backend/documentation/modele_de_données/migrations/032_gouvernance_album.sql` | Nouveau fichier de migration forward. |
| `usenghor_backend/documentation/modele_de_données/migrations/032_gouvernance_album_rollback.sql` | Nouveau fichier de rollback. |
| `usenghor_backend/app/models/media.py` | Ajout champ `thumbnail_url` sur le modèle `Media`. |
| `usenghor_backend/app/schemas/media.py` | Ajout champ `thumbnail_url` dans `MediaBase`/`MediaCreate`/`MediaUpdate`/`MediaRead`/`MediaExternalCreate` + `thumbnail_url` dans `CoverMedia`. |
| `usenghor_backend/app/services/media_service.py` | Vérification/ajustement du tri `display_order` dans les queries albums. |
| `usenghor_nuxt/app/types/api/media.ts` | Vérifier que `thumbnail_url` est bien déjà exposé (déjà le cas, sinon aligner). |
| `usenghor_nuxt/app/pages/a-propos/gouvernance.vue` | Remplacement lecture JSON → `getAlbumBySlug` + mapper + gestion modal. |
| `usenghor_nuxt/app/components/governance/FoundingTextsSection.vue` | Ajout bouton « Prévisualiser » + émission event `preview`. |
| `usenghor_nuxt/app/composables/editorial-pages-config.ts` | `editable: false` sur le champ `documents` + ajout note de dépréciation + redirect vers l'admin médiathèque. |
| `usenghor_nuxt/i18n/locales/fr/governance.json` + `en/`, `ar/` | Ajout clés : `preview`, `emptyState`. |
