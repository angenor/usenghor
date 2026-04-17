# API Contract: Public Albums Endpoints

**Branch**: `015-mediatheque` | **Date**: 2026-03-28

## GET /api/public/albums

Liste tous les albums publiés non vides pour la médiathèque publique.

### Request

| Paramètre | Type | Défaut | Description |
|-----------|------|--------|-------------|
| `page` | `int` | `1` | Numéro de page |
| `limit` | `int` | `24` | Nombre d'albums par page |
| `search` | `string` | `null` | Recherche textuelle sur titre et description |
| `media_type` | `string` | `null` | Filtre : `image`, `video`, `audio`, `document` — retourne les albums contenant au moins un média de ce type |

### Response `200 OK`

```json
{
  "items": [
    {
      "id": "uuid",
      "title": "Logos institutionnels",
      "description": "Logos officiels de l'Université Senghor",
      "slug": "logos-institutionnels",
      "status": "published",
      "created_at": "2026-03-28T10:00:00Z",
      "updated_at": "2026-03-28T10:00:00Z",
      "media_count": 12,
      "media_types": ["image", "document"],
      "cover_media": {
        "id": "uuid",
        "url": "/uploads/general/image.jpg",
        "type": "image",
        "name": "Logo principal"
      }
    }
  ],
  "total": 15,
  "page": 1,
  "limit": 24,
  "pages": 1
}
```

### Règles métier

- Seuls les albums avec `status = 'published'` sont retournés
- Seuls les albums contenant au moins 1 média sont retournés
- Le tri par défaut est par `created_at` DESC (plus récent en premier)
- `cover_media` : premier média de l'album (par `display_order`)
- `media_types` : types distincts de médias présents dans l'album

---

## GET /api/public/albums/by-slug/{slug}

Récupère un album publié par son slug avec tous ses médias.

### Request

| Paramètre | Type | Description |
|-----------|------|-------------|
| `slug` | `string` (path) | Slug de l'album |

### Response `200 OK`

```json
{
  "id": "uuid",
  "title": "Logos institutionnels",
  "description": "Logos officiels de l'Université Senghor",
  "slug": "logos-institutionnels",
  "status": "published",
  "created_at": "2026-03-28T10:00:00Z",
  "updated_at": "2026-03-28T10:00:00Z",
  "media_items": [
    {
      "id": "uuid",
      "name": "Logo principal",
      "description": "Logo officiel haute résolution",
      "type": "image",
      "url": "/uploads/general/logo.png",
      "mime_type": "image/png",
      "size_bytes": 245760,
      "width": 1200,
      "height": 800,
      "alt_text": "Logo Université Senghor",
      "credits": "Service communication"
    }
  ]
}
```

### Response `404 Not Found`

Album non trouvé, en brouillon ou vide.

```json
{
  "detail": "Album non trouvé"
}
```

### Règles métier

- Seuls les albums avec `status = 'published'` sont accessibles
- Les médias sont triés par `display_order` ASC
- Aucune authentification requise
