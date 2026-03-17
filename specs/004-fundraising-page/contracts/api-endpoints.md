# API Contracts: Page Levée de Fonds

**Feature Branch**: `004-fundraising-page`
**Date**: 2026-03-17

## Public Endpoints (no auth)

### GET /api/public/fundraisers

Liste des levées de fonds publiées (status = active ou completed).

**Query Parameters**:

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| page | int | 1 | Numéro de page |
| limit | int | 20 | Éléments par page (max 500) |
| sort_by | string | "created_at" | Champ de tri |
| sort_order | string | "desc" | Ordre (asc/desc) |
| status | string | null | Filtrer par statut (active/completed) |

**Response** (200):
```json
{
  "items": [
    {
      "id": "uuid",
      "title": "Campagne 2026",
      "slug": "campagne-2026",
      "cover_image_external_id": "uuid | null",
      "goal_amount": 1000000.00,
      "total_raised": 750000.00,
      "progress_percentage": 75.0,
      "status": "active",
      "contributor_count": 42,
      "created_at": "2026-01-15T10:00:00Z"
    }
  ],
  "total": 5,
  "page": 1,
  "limit": 20,
  "pages": 1
}
```

---

### GET /api/public/fundraisers/{slug}

Détail d'une levée de fonds publiée.

**Response** (200):
```json
{
  "id": "uuid",
  "title": "Campagne 2026",
  "slug": "campagne-2026",
  "description_html": "<p>...</p>",
  "description_en_html": "<p>...</p>",
  "description_ar_html": "<p>...</p>",
  "cover_image_external_id": "uuid | null",
  "goal_amount": 1000000.00,
  "total_raised": 750000.00,
  "progress_percentage": 75.0,
  "status": "active",
  "contributors": [
    {
      "id": "uuid",
      "name": "République française",
      "name_en": "French Republic",
      "name_ar": "الجمهورية الفرنسية",
      "category": "state_organization",
      "amount": 200000.00,
      "logo_external_id": "uuid | null"
    }
  ],
  "news": [
    {
      "id": "uuid",
      "title": "Lancement de la campagne",
      "slug": "lancement-campagne",
      "summary": "...",
      "cover_image_external_id": "uuid | null",
      "published_at": "2026-01-20T10:00:00Z"
    }
  ],
  "created_at": "2026-01-15T10:00:00Z"
}
```

**Error** (404): `{ "detail": "Levée de fonds non trouvée" }`

---

## Admin Endpoints (JWT required)

### GET /api/admin/fundraisers

Liste toutes les levées de fonds (tous statuts). Permission: `fundraisers.view`.

**Query Parameters**: Identiques au public + `search` (string, filtre sur titre) + `status` (inclut `draft`).

**Response** (200): Même format paginé, avec champs supplémentaires `description_md`, `description_en_md`, `description_ar_md`.

---

### POST /api/admin/fundraisers

Créer une levée de fonds. Permission: `fundraisers.create`.

**Body**:
```json
{
  "title": "Campagne 2026",
  "slug": "campagne-2026",
  "description_html": "<p>...</p>",
  "description_md": "...",
  "description_en_html": "<p>...</p>",
  "description_en_md": "...",
  "description_ar_html": "<p>...</p>",
  "description_ar_md": "...",
  "cover_image_external_id": "uuid | null",
  "goal_amount": 1000000.00,
  "status": "draft"
}
```

**Response** (201): `{ "id": "uuid", "message": "Levée de fonds créée avec succès" }`

---

### PUT /api/admin/fundraisers/{id}

Modifier une levée de fonds. Permission: `fundraisers.edit`. Tous les champs sont optionnels (exclude_unset).

**Body**: Mêmes champs que POST, tous optionnels.

**Response** (200): Objet FundraiserRead complet.

---

### DELETE /api/admin/fundraisers/{id}

Supprimer une levée de fonds. Permission: `fundraisers.delete`.

**Response** (200): `{ "message": "Levée de fonds supprimée avec succès" }`

---

### POST /api/admin/fundraisers/{id}/contributors

Ajouter un contributeur. Permission: `fundraisers.edit`.

**Body**:
```json
{
  "name": "République française",
  "name_en": "French Republic",
  "name_ar": "الجمهورية الفرنسية",
  "category": "state_organization",
  "amount": 200000.00,
  "logo_external_id": "uuid | null"
}
```

**Response** (201): `{ "id": "uuid", "message": "Contributeur ajouté avec succès" }`

---

### PUT /api/admin/fundraisers/{id}/contributors/{contributor_id}

Modifier un contributeur. Permission: `fundraisers.edit`.

**Body**: Mêmes champs que POST, tous optionnels.

**Response** (200): Objet ContributorRead complet.

---

### DELETE /api/admin/fundraisers/{id}/contributors/{contributor_id}

Supprimer un contributeur. Permission: `fundraisers.delete`.

**Response** (200): `{ "message": "Contributeur supprimé avec succès" }`

---

### POST /api/admin/fundraisers/{id}/news

Associer une actualité. Permission: `fundraisers.edit`.

**Body**:
```json
{
  "news_id": "uuid"
}
```

**Response** (201): `{ "message": "Actualité associée avec succès" }`

---

### DELETE /api/admin/fundraisers/{id}/news/{news_id}

Dissocier une actualité. Permission: `fundraisers.edit`.

**Response** (200): `{ "message": "Actualité dissociée avec succès" }`
