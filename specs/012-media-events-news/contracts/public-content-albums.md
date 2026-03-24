# Contract: Public Content Albums API

Endpoints publics pour récupérer les albums associés aux événements et actualités.
Seuls les albums avec le statut `published` sont retournés.

## GET /api/public/events/{slug}/albums

Retourne les albums publiés associés à un événement, avec leurs médias.

**Auth**: Aucune

**Response 200**:
```json
{
  "albums": [
    {
      "id": "uuid-1",
      "title": "Photos de la cérémonie",
      "description": "Cérémonie de remise des diplômes 2026",
      "display_order": 0,
      "media_items": [
        {
          "id": "media-uuid-1",
          "name": "photo_01.jpg",
          "type": "image",
          "url": "/api/public/media/media-uuid-1/download",
          "width": 1920,
          "height": 1080,
          "alt_text": "Les lauréats sur scène",
          "display_order": 0
        },
        {
          "id": "media-uuid-2",
          "name": "video_recap.mp4",
          "type": "video",
          "url": "/api/public/media/media-uuid-2/download",
          "duration_seconds": 180,
          "display_order": 1
        }
      ]
    }
  ]
}
```

**Response 200 (aucun album publié)**:
```json
{
  "albums": []
}
```

**Errors**:
- `404` : événement non trouvé ou non publié

---

## GET /api/public/news/{slug}/albums

Retourne les albums publiés associés à une actualité, avec leurs médias.

**Auth**: Aucune

**Response 200**:
```json
{
  "albums": [
    {
      "id": "uuid-1",
      "title": "Visite du nouveau campus",
      "description": "Inauguration du campus de Yaoundé",
      "display_order": 0,
      "media_items": [
        {
          "id": "media-uuid-1",
          "name": "campus_01.jpg",
          "type": "image",
          "url": "/api/public/media/media-uuid-1/download",
          "width": 1600,
          "height": 900,
          "alt_text": "Vue aérienne du campus",
          "display_order": 0
        }
      ]
    }
  ]
}
```

**Errors**:
- `404` : actualité non trouvée ou non publiée
