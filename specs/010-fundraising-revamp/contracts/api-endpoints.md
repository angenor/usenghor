# API Contracts: Refonte Page Levée de Fonds

**Branch**: `010-fundraising-revamp` | **Date**: 2026-03-22

## Public Endpoints

### GET /api/public/fundraisers

Liste des campagnes publiées (active + completed).

**Query Params**:
| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `page` | int | 1 | Numéro de page |
| `limit` | int | 10 | Items par page |
| `status` | string | null | Filtre par statut (`active`, `completed`) |

**Response 200**:
```json
{
  "items": [
    {
      "id": "uuid",
      "title": "Campagne 2026",
      "slug": "campagne-2026",
      "cover_image_url": "/api/public/media/{uuid}/download",
      "goal_amount": 500000.00,
      "total_raised": 125000.00,
      "progress_percentage": 25.0,
      "contributor_count": 12,
      "status": "active",
      "created_at": "2026-01-15T10:00:00Z"
    }
  ],
  "total": 5,
  "page": 1,
  "limit": 10
}
```

---

### GET /api/public/fundraisers/{slug}

Détail complet d'une campagne avec contributeurs, médias et actualités.

**Response 200**:
```json
{
  "id": "uuid",
  "title": "Campagne 2026",
  "slug": "campagne-2026",
  "description_html": "<p>Présentation...</p>",
  "reason_html": "<p>Raison de la levée...</p>",
  "cover_image_url": "/api/public/media/{uuid}/download",
  "goal_amount": 500000.00,
  "total_raised": 125000.00,
  "progress_percentage": 25.0,
  "contributor_count": 12,
  "status": "active",
  "contributors": [
    {
      "id": "uuid",
      "name": "Fondation XYZ",
      "category": "foundation_philanthropist",
      "amount": 50000.00,
      "show_amount_publicly": true,
      "logo_url": "/api/public/media/{uuid}/download"
    }
  ],
  "media": [
    {
      "id": "uuid",
      "media_url": "/api/public/media/{uuid}/download",
      "caption": "Légende du média",
      "display_order": 1
    }
  ],
  "news": [
    {
      "id": "uuid",
      "title": "Actualité liée",
      "slug": "actualite-liee",
      "cover_image_url": "/api/public/media/{uuid}/download",
      "published_at": "2026-02-10T10:00:00Z"
    }
  ]
}
```

**Note**: Le champ `amount` des contributeurs est `null` si `show_amount_publicly` est `false`. Le champ `show_amount_publicly` n'est pas exposé au public.

---

### GET /api/public/fundraisers/global-stats

Statistiques agrégées pour la page principale.

**Response 200**:
```json
{
  "total_raised_all_campaigns": 750000.00,
  "total_contributors": 45,
  "active_campaigns_count": 1,
  "completed_campaigns_count": 4
}
```

---

### GET /api/public/fundraisers/all-contributors

Liste de tous les contributeurs uniques toutes campagnes confondues.

**Query Params**:
| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `page` | int | 1 | Numéro de page |
| `limit` | int | 50 | Items par page |

**Response 200**:
```json
{
  "items": [
    {
      "name": "Fondation XYZ",
      "category": "foundation_philanthropist",
      "total_amount": 75000.00,
      "show_amount_publicly": true,
      "logo_url": "/api/public/media/{uuid}/download",
      "campaigns_count": 2
    }
  ],
  "total": 45,
  "page": 1,
  "limit": 50
}
```

**Note**: `total_amount` est `null` si `show_amount_publicly` est `false` pour au moins une contribution du contributeur. Agrégation par nom de contributeur.

---

### GET /api/public/fundraisers/editorial-sections

Sections éditoriales de la page principale.

**Response 200**:
```json
{
  "sections": [
    {
      "slug": "contribution-reasons",
      "title": "Votre contribution sert à",
      "items": [
        {
          "icon": "academic-cap",
          "title": "Former les leaders de demain",
          "description": "Votre soutien finance des bourses..."
        }
      ]
    }
  ]
}
```

**Note**: Les champs `title` et `description` sont renvoyés dans la langue de la requête (`Accept-Language` ou paramètre `lang`).

---

### POST /api/public/fundraisers/{slug}/interest

Manifester son intérêt pour contribuer à une campagne.

**Request Body**:
```json
{
  "full_name": "Jean Dupont",
  "email": "jean.dupont@example.com",
  "message": "Je souhaite contribuer à hauteur de...",
  "honeypot": "",
  "challenge_token": "base64-encoded-token",
  "form_opened_at": 1711100000
}
```

**Validation anti-spam** (côté serveur) :
1. `honeypot` doit être vide (sinon → 400)
2. `challenge_token` doit être valide (hash JS vérifié → sinon → 400)
3. `form_opened_at` doit être > 3 secondes avant la soumission (sinon → 400)

**Response 201** (succès):
```json
{
  "message": "Votre intérêt a bien été enregistré. Un email de confirmation vous a été envoyé."
}
```

**Response 200** (doublon mis à jour):
```json
{
  "message": "Votre intérêt a été mis à jour."
}
```

**Response 400** (anti-spam):
```json
{
  "detail": "Vérification de sécurité échouée."
}
```

**Response 404** (campagne non active):
```json
{
  "detail": "Campagne non trouvée ou clôturée."
}
```

---

## Admin Endpoints

### GET /api/admin/fundraisers/interest-expressions

Liste des manifestations d'intérêt.

**Query Params**:
| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `page` | int | 1 | Numéro de page |
| `limit` | int | 20 | Items par page |
| `fundraiser_id` | uuid | null | Filtre par campagne |
| `status` | string | null | Filtre par statut (`new`, `contacted`) |
| `search` | string | null | Recherche par nom ou email |

**Response 200**:
```json
{
  "items": [
    {
      "id": "uuid",
      "fundraiser_id": "uuid",
      "fundraiser_title": "Campagne 2026",
      "full_name": "Jean Dupont",
      "email": "jean.dupont@example.com",
      "message": "Je souhaite contribuer...",
      "status": "new",
      "created_at": "2026-03-15T14:30:00Z",
      "updated_at": "2026-03-15T14:30:00Z"
    }
  ],
  "total": 25,
  "page": 1,
  "limit": 20
}
```

---

### PUT /api/admin/fundraisers/interest-expressions/{id}/status

Mettre à jour le statut d'une manifestation d'intérêt.

**Request Body**:
```json
{
  "status": "contacted"
}
```

**Response 200**:
```json
{
  "id": "uuid",
  "status": "contacted",
  "updated_at": "2026-03-20T09:00:00Z"
}
```

---

### GET /api/admin/fundraisers/interest-expressions/export

Export CSV des manifestations d'intérêt.

**Query Params**:
| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `fundraiser_id` | uuid | null | Filtre par campagne (toutes si null) |
| `status` | string | null | Filtre par statut |

**Response 200**: `Content-Type: text/csv`
```csv
Nom,Email,Message,Campagne,Statut,Date
Jean Dupont,jean.dupont@example.com,Je souhaite...,Campagne 2026,new,2026-03-15
```

---

### CRUD Admin Sections Éditoriales

Les endpoints admin pour gérer les sections et items éditoriaux suivent le pattern CRUD standard du projet :

- `GET /api/admin/fundraisers/editorial-sections` — Liste des sections avec items
- `PUT /api/admin/fundraisers/editorial-sections/{id}` — Modifier une section
- `POST /api/admin/fundraisers/editorial-sections/{section_id}/items` — Ajouter un item
- `PUT /api/admin/fundraisers/editorial-sections/items/{id}` — Modifier un item
- `DELETE /api/admin/fundraisers/editorial-sections/items/{id}` — Supprimer un item

---

### CRUD Admin Médias de Campagne

- `GET /api/admin/fundraisers/{id}/media` — Liste des médias associés
- `POST /api/admin/fundraisers/{id}/media` — Associer un média
- `PUT /api/admin/fundraisers/{id}/media/{media_id}` — Modifier légende/ordre
- `DELETE /api/admin/fundraisers/{id}/media/{media_id}` — Dissocier un média
