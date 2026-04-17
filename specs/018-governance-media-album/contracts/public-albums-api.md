# Contrats — API publique albums (réutilisés)

**Feature**: 018-governance-media-album
**Statut**: Contrats **existants**, enrichis a minima (ajout d'un champ `thumbnail_url` nullable).

Aucun nouvel endpoint n'est créé pour cette feature (FR-023). Ce document liste les endpoints consommés et les enrichissements de payload.

---

## 1. `GET /api/public/albums/by-slug/{slug}`

**Consommateur** : `usenghor_nuxt/app/pages/a-propos/gouvernance.vue` (via `usePublicAlbumsApi().getAlbumBySlug`), et déjà utilisé par `/mediatheque/[slug]`.

**Path params**
| Nom | Type | Contrainte |
|-----|------|------------|
| `slug` | string | Pour cette feature : `gouvernance`. |

**Réponse 200** — schéma `AlbumWithMedia` :

```jsonc
{
  "id": "uuid",
  "title": "Gouvernance",
  "description": "Textes fondateurs de l'Université Senghor (chartes, conventions, statuts).",
  "slug": "gouvernance",
  "status": "published",
  "created_at": "2026-04-16T10:00:00Z",
  "updated_at": "2026-04-16T10:00:00Z",
  "media_items": [
    {
      "id": "uuid",
      "name": "Charte de l'Université Senghor",
      "description": "Charte fondatrice adoptée en 1990.",
      "type": "document",
      "url": "https://…/charte.pdf",
      "thumbnail_url": "https://…/charte-cover.jpg",  // nouveau champ (D1)
      "is_external_url": false,
      "size_bytes": 1548230,
      "mime_type": "application/pdf",
      "width": null,
      "height": null,
      "duration_seconds": null,
      "alt_text": null,
      "credits": "1990",
      "created_at": "…",
      "updated_at": "…"
    }
  ]
}
```

**Tri des `media_items`** : par `display_order ASC NULLS LAST`, puis par `created_at ASC`. À vérifier dans le service (research D8). C'est une exigence de FR-014.

**Réponse 404** : si l'album n'existe pas, est dépublié, ou est vide. Le frontend interprète ce code comme un état vide discret (Q2, FR-015).

**Authentification** : aucune (endpoint public).

---

## 2. `GET /api/public/albums`

**Consommateur** : `usenghor_nuxt/app/pages/mediatheque/index.vue` (onglets « Tout » et « Albums »).

**Query params** (déjà existants)
| Nom | Type | Défaut |
|-----|------|--------|
| `page` | int | 1 |
| `limit` | int | 24 |
| `search` | string \| null | `null` |
| `media_type` | `'image' \| 'video' \| 'audio' \| 'document' \| null` | `null` |

**Comportement après migration**
- L'album `gouvernance` apparaît dans les résultats dès qu'il est publié et contient au moins un média (filtrage existant inchangé).
- Si l'utilisateur sélectionne `media_type=document`, l'album `gouvernance` reste affiché (tous ses médias sont de type `document`).

**Réponse 200** — schéma `PublicAlbumListResponse`, chaque `PublicAlbumListItem` enrichi :

```jsonc
{
  "items": [
    {
      "id": "uuid",
      "title": "Gouvernance",
      "description": "…",
      "slug": "gouvernance",
      "status": "published",
      "created_at": "…",
      "updated_at": "…",
      "media_count": 5,
      "media_types": ["document"],
      "cover_media": {
        "id": "uuid",
        "url": "https://…/charte.pdf",
        "thumbnail_url": "https://…/charte-cover.jpg",  // nouveau champ (D8)
        "type": "document",
        "name": "Charte de l'Université Senghor"
      }
    }
  ],
  "total": 12,
  "page": 1,
  "limit": 24,
  "pages": 1
}
```

**Dérivation de `cover_media`** : **premier média de l'album selon `display_order ASC`** (contrat durci par Q4). Le frontend affiche `cover_media.thumbnail_url` si non null, sinon fallback sur `cover_media.url` pour les médias non-image (ou icône générique pour les `document` sans thumbnail).

---

## 3. Contrats Pydantic affectés

### 3.1 `MediaRead` (enrichi)

Ajout d'un champ optionnel :

```python
thumbnail_url: str | None = None
```

**Rétrocompatibilité** : tous les clients actuels ignorent les champs supplémentaires qu'ils ne connaissent pas. Le type TS frontend attendait déjà ce champ, donc aucun consommateur ne casse.

### 3.2 `MediaCreate` / `MediaUpdate` / `MediaExternalCreate` (enrichis)

Ajout d'un champ optionnel pour l'admin :

```python
thumbnail_url: str | None = Field(None, max_length=500)
```

### 3.3 `CoverMedia` (enrichi)

```python
class CoverMedia(BaseModel):
    id: str
    url: str
    thumbnail_url: str | None = None  # nouveau
    type: MediaType
    name: str
```

---

## 4. Contrats frontend (`types/api/media.ts`)

Déjà en place — aucun changement requis côté TypeScript :

```typescript
interface MediaRead {
  // …
  thumbnail_url: string | null
  // …
}
```

À vérifier : le type `CoverMedia` ou `PublicAlbumListItem.cover_media` doit également exposer `thumbnail_url`. Si le type actuel côté frontend ne le fait pas, ajouter la propriété (nullable) pour refléter le nouveau contrat backend.

---

## 5. Contrats admin (pour US3)

**Aucun changement requis** : les endpoints admin existants (`POST /api/admin/albums/{id}/media`, `DELETE /api/admin/albums/{id}/media/{media_id}`, `PUT /api/admin/albums/{id}/media/reorder`) permettent déjà toutes les opérations exigées par US3 (ajout, retrait, réordonnancement). La seule subtilité est l'upload de la couverture du document, qui passe par :

- Un upload de fichier image vers `POST /api/admin/media` (retourne un `media.id` + `url`).
- Une éventuelle mise à jour du média document pour renseigner son `thumbnail_url` via `PUT /api/admin/media/{id}` (nouveau champ accepté grâce à l'enrichissement de `MediaUpdate`).

> **À confirmer pendant les tâches** : l'UI admin `/admin/mediatheque/albums/{id}` permet-elle déjà de définir le thumbnail d'un média existant ? Si non, petite itération UI requise (hors-scope nominal, à lever dans `tasks.md` si besoin).

---

## 6. Absence de nouveaux contrats

- Pas de nouveau endpoint.
- Pas de nouveau modèle.
- Pas de nouvelle route frontend.
- Seul enrichissement : un champ nullable `thumbnail_url` répliqué cohéremment dans :
  - `media` (colonne SQL),
  - `Media` (SQLAlchemy),
  - `MediaBase`/`MediaRead`/`MediaCreate`/`MediaUpdate`/`MediaExternalCreate` (Pydantic),
  - `CoverMedia` (Pydantic),
  - Types TS correspondants (déjà alignés ou à aligner).
