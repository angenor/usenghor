# API Contracts: 008-survey-campaigns

**Date**: 2026-03-20 | **Branch**: `008-survey-campaigns`

## Admin Endpoints (`/api/admin/surveys`)

Tous les endpoints nécessitent : JWT + `PermissionChecker("survey.manage")`.
Filtrage automatique par `created_by = current_user.id` (sauf super_admin).

### Campagnes CRUD

#### `GET /api/admin/surveys`
Liste des campagnes du gestionnaire connecté (paginée).

**Query params** : `page`, `limit`, `search`, `status`, `sort_by`, `sort_order`

**Response** :
```json
{
  "items": [
    {
      "id": "uuid",
      "slug": "enquete-satisfaction-2026",
      "title_fr": "Enquête de satisfaction",
      "title_en": "Satisfaction survey",
      "title_ar": "استطلاع رضا",
      "status": "active",
      "confirmation_email_enabled": false,
      "closes_at": "2026-04-30T23:59:59Z",
      "response_count": 42,
      "last_response_at": "2026-03-20T14:30:00Z",
      "created_by": "uuid",
      "created_at": "2026-03-01T10:00:00Z",
      "updated_at": "2026-03-15T08:00:00Z"
    }
  ],
  "total": 5,
  "page": 1,
  "limit": 20,
  "pages": 1
}
```

#### `GET /api/admin/surveys/{id}`
Détail d'une campagne avec le JSON du formulaire.

**Response** : Objet campagne complet avec `survey_json`.

#### `POST /api/admin/surveys`
Créer une campagne (statut `draft` par défaut).

**Body** :
```json
{
  "slug": "enquete-satisfaction-2026",
  "title_fr": "Enquête de satisfaction",
  "title_en": "Satisfaction survey",
  "title_ar": "استطلاع رضا",
  "description_fr": "...",
  "description_en": "...",
  "description_ar": "...",
  "survey_json": { "elements": [...] },
  "confirmation_email_enabled": false,
  "closes_at": "2026-04-30T23:59:59Z"
}
```

**Response** : `201` `{ "id": "uuid", "message": "Campagne créée avec succès" }`

#### `PUT /api/admin/surveys/{id}`
Mettre à jour une campagne (partial update via `exclude_unset`).

**Body** : Mêmes champs que POST, tous optionnels.

**Response** : Objet campagne mis à jour.

#### `DELETE /api/admin/surveys/{id}`
Supprimer une campagne et toutes ses réponses (CASCADE).

**Response** : `200` `{ "message": "Campagne supprimée avec succès" }`

### Actions sur le cycle de vie

#### `POST /api/admin/surveys/{id}/publish`
Publier (draft/paused → active).

**Response** : Objet campagne avec `status: "active"`.

#### `POST /api/admin/surveys/{id}/pause`
Mettre en pause (active → paused).

**Response** : Objet campagne avec `status: "paused"`.

#### `POST /api/admin/surveys/{id}/close`
Clôturer (active/paused → closed).

**Response** : Objet campagne avec `status: "closed"`.

#### `POST /api/admin/surveys/{id}/duplicate`
Dupliquer une campagne (structure uniquement, sans réponses).

**Body** :
```json
{
  "slug": "enquete-satisfaction-2026-v2"
}
```

**Response** : `201` `{ "id": "uuid", "message": "Campagne dupliquée avec succès" }`

### Réponses & Statistiques

#### `GET /api/admin/surveys/{id}/responses`
Liste paginée des réponses individuelles.

**Query params** : `page`, `limit`, `sort_by`, `sort_order`

**Response** :
```json
{
  "items": [
    {
      "id": "uuid",
      "response_data": { "fullName": "Jean Dupont", "email": "jean@mail.com", ... },
      "submitted_at": "2026-03-20T14:30:00Z"
    }
  ],
  "total": 42,
  "page": 1,
  "limit": 20,
  "pages": 3
}
```

#### `GET /api/admin/surveys/{id}/stats`
Statistiques agrégées d'une campagne.

**Response** :
```json
{
  "total_responses": 42,
  "first_response_at": "2026-03-05T09:00:00Z",
  "last_response_at": "2026-03-20T14:30:00Z",
  "questions": [
    {
      "name": "satisfaction",
      "type": "rating",
      "title": "Niveau de satisfaction",
      "stats": {
        "average": 4.2,
        "distribution": { "1": 2, "2": 3, "3": 5, "4": 15, "5": 17 }
      }
    },
    {
      "name": "department",
      "type": "dropdown",
      "title": "Département",
      "stats": {
        "distribution": { "Sciences": 12, "Lettres": 18, "Droit": 12 }
      }
    }
  ]
}
```

#### `GET /api/admin/surveys/{id}/export`
Export CSV des réponses.

**Response** : `Content-Type: text/csv`, fichier téléchargeable.

### Associations

#### `GET /api/admin/surveys/{id}/associations`
Liste des associations de la campagne.

#### `POST /api/admin/surveys/{id}/associations`
Associer une campagne à un élément.

**Body** :
```json
{
  "entity_type": "event",
  "entity_id": "uuid"
}
```

#### `DELETE /api/admin/surveys/{id}/associations/{association_id}`
Retirer une association.

---

## Public Endpoints (`/api/public/surveys`)

Aucune authentification requise.

#### `GET /api/public/surveys/{slug}`
Récupérer le formulaire d'une campagne active par son slug.

**Response** :
```json
{
  "id": "uuid",
  "slug": "enquete-satisfaction-2026",
  "title_fr": "Enquête de satisfaction",
  "title_en": "Satisfaction survey",
  "title_ar": "استطلاع رضا",
  "description_fr": "...",
  "description_en": "...",
  "description_ar": "...",
  "survey_json": { "elements": [...] },
  "status": "active"
}
```

**Erreurs** :
- `404` si slug inexistant
- `410 Gone` si campagne `paused` ou `closed` (avec message approprié)

#### `POST /api/public/surveys/{slug}/submit`
Soumettre une réponse à un formulaire.

**Headers** : `X-Forwarded-For` (IP), `X-Session-Id` (dédoublonnage)

**Body** :
```json
{
  "response_data": { "fullName": "Jean Dupont", "email": "jean@mail.com", ... },
  "honeypot": ""
}
```

**Validations** :
- Campagne doit être `active`
- Honeypot doit être vide (sinon rejet silencieux 200)
- Rate limiting : max 5 soumissions/IP/heure
- Session unique : pas de doublon `(campaign_id, session_id)`
- Champs obligatoires validés côté serveur (d'après `survey_json`)

**Response** : `201` `{ "message": "Réponse enregistrée avec succès" }`

#### `GET /api/public/surveys/by-entity/{entity_type}/{entity_id}`
Récupérer les campagnes actives associées à un élément du site.

**Response** : Liste de campagnes (id, slug, titre trilingue, description trilingue) sans le `survey_json`.

#### `POST /api/public/surveys/{slug}/upload`
Upload de fichier pour une question de type `file`.

**Body** : `multipart/form-data` avec le fichier.

**Response** :
```json
{
  "url": "/api/public/media/{id}/download",
  "name": "cv-jean-dupont.pdf",
  "size": 245760
}
```
