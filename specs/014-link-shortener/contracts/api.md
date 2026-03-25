# API Contracts: 014-link-shortener

**Date**: 2026-03-25

## Admin Endpoints (authentification requise)

### POST /api/admin/short-links

Crée un nouveau lien réduit. Le code est généré automatiquement.

**Request Body**:
```json
{
  "target_url": "/formations/master-administration-des-entreprises"
}
```

**Response 201**:
```json
{
  "id": "uuid",
  "message": "Lien court créé avec succès"
}
```

**Response 400** (URL invalide, domaine non autorisé, boucle `/r/`, capacité atteinte):
```json
{
  "detail": "L'URL de destination ne doit pas pointer vers un lien réduit (/r/...)"
}
```

---

### GET /api/admin/short-links

Liste paginée des liens réduits.

**Query Parameters**:
- `page` (int, default 1)
- `limit` (int, default 20)
- `search` (string, optionnel) — filtre sur code ou target_url

**Response 200**:
```json
{
  "items": [
    {
      "id": "uuid",
      "code": "a1b2",
      "target_url": "/formations/master-administration-des-entreprises",
      "full_short_url": "https://usenghor-francophonie.org/r/a1b2",
      "created_by_name": "Admin Senghor",
      "created_at": "2026-03-25T10:00:00Z",
      "updated_at": "2026-03-25T10:00:00Z"
    }
  ],
  "total": 42,
  "page": 1,
  "limit": 20,
  "pages": 3
}
```

---

### DELETE /api/admin/short-links/{id}

Supprime un lien réduit par son ID.

**Response 200**:
```json
{
  "message": "Lien court supprimé avec succès"
}
```

**Response 404**:
```json
{
  "detail": "Lien court non trouvé"
}
```

---

### GET /api/admin/short-links/allowed-domains

Liste les domaines autorisés.

**Response 200**:
```json
{
  "items": [
    { "id": "uuid", "domain": "google.com", "created_at": "2026-03-25T10:00:00Z" }
  ]
}
```

---

### POST /api/admin/short-links/allowed-domains

Ajoute un domaine à la liste blanche.

**Request Body**:
```json
{
  "domain": "partenaire.org"
}
```

**Response 201**:
```json
{
  "id": "uuid",
  "message": "Domaine ajouté avec succès"
}
```

---

### DELETE /api/admin/short-links/allowed-domains/{id}

Supprime un domaine de la liste blanche.

**Response 200**:
```json
{
  "message": "Domaine supprimé avec succès"
}
```

---

## Public Endpoint (sans authentification)

### GET /api/public/short-links/{code}

Récupère l'URL de destination pour un code court.

**Response 200**:
```json
{
  "target_url": "/formations/master-administration-des-entreprises"
}
```

**Response 404**:
```json
{
  "detail": "Lien court non trouvé"
}
```

---

## Nuxt Server Route (redirection)

### GET /r/{code}

Redirige vers l'URL de destination (HTTP 302).

- Appelle `GET /api/public/short-links/{code}` en interne.
- Si trouvé : retourne HTTP 302 avec `Location: {target_url}`.
- Si non trouvé : retourne HTTP 404.
