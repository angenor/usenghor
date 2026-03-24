# Contract: Admin News Albums API

**Base path**: `/api/admin/news`

## POST /{news_id}/albums

Associe un ou plusieurs albums à une actualité.

**Auth**: JWT required (admin)

**Request body**:
```json
{
  "album_ids": ["uuid-1", "uuid-2"]
}
```

**Response 200**:
```json
{
  "news_id": "uuid",
  "albums": [
    {
      "album_external_id": "uuid-1",
      "display_order": 0,
      "album": {
        "id": "uuid-1",
        "title": "Visite du campus",
        "description": "...",
        "status": "published",
        "media_count": 18
      }
    }
  ]
}
```

**Errors**:
- `404` : actualité non trouvée
- `409` : album déjà associé

---

## DELETE /{news_id}/albums/{album_id}

Dissocie un album d'une actualité.

**Auth**: JWT required (admin)

**Response 200**:
```json
{
  "message": "Album dissocié de l'actualité"
}
```

**Errors**:
- `404` : actualité ou association non trouvée

---

## PUT /{news_id}/albums/reorder

Réordonne les albums associés à une actualité.

**Auth**: JWT required (admin)

**Request body**:
```json
{
  "album_ids": ["uuid-2", "uuid-1"]
}
```

**Response 200**:
```json
{
  "message": "Ordre mis à jour",
  "albums": [
    { "album_external_id": "uuid-2", "display_order": 0 },
    { "album_external_id": "uuid-1", "display_order": 1 }
  ]
}
```

**Errors**:
- `404` : actualité non trouvée

---

## GET /{news_id}/albums

Liste les albums associés à une actualité (admin : tous les statuts).

**Auth**: JWT required (admin)

**Response 200**:
```json
{
  "albums": [
    {
      "album_external_id": "uuid-1",
      "display_order": 0,
      "album": {
        "id": "uuid-1",
        "title": "Inauguration du laboratoire",
        "status": "draft",
        "media_count": 8,
        "cover_url": "/api/public/media/uuid/download?variant=low"
      }
    }
  ]
}
```
