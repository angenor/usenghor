# Contract: Admin Events Albums API

**Base path**: `/api/admin/events`

## POST /{event_id}/albums

Associe un ou plusieurs albums à un événement.

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
  "event_id": "uuid",
  "albums": [
    {
      "album_external_id": "uuid-1",
      "display_order": 0,
      "album": {
        "id": "uuid-1",
        "title": "Cérémonie de remise des diplômes",
        "description": "...",
        "status": "published",
        "media_count": 24
      }
    },
    {
      "album_external_id": "uuid-2",
      "display_order": 1,
      "album": null
    }
  ]
}
```

**Errors**:
- `404` : événement non trouvé
- `409` : album déjà associé

---

## DELETE /{event_id}/albums/{album_id}

Dissocie un album d'un événement.

**Auth**: JWT required (admin)

**Response 200**:
```json
{
  "message": "Album dissocié de l'événement"
}
```

**Errors**:
- `404` : événement ou association non trouvée

---

## PUT /{event_id}/albums/reorder

Réordonne les albums associés à un événement.

**Auth**: JWT required (admin)

**Request body**:
```json
{
  "album_ids": ["uuid-2", "uuid-1"]
}
```

L'ordre dans la liste détermine le `display_order` (index 0, 1, 2...).

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
- `404` : événement non trouvé

---

## GET /{event_id}/albums

Liste les albums associés à un événement (admin : tous les statuts).

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
        "title": "Photos de la conférence",
        "status": "published",
        "media_count": 15,
        "cover_url": "/api/public/media/uuid/download?variant=low"
      }
    }
  ]
}
```
