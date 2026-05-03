# Contract — Admin FAQ API

**Branch**: `019-faq-backoffice` | **Date**: 2026-05-02

Endpoints d'administration. Préfixe `/api/admin/faq`. Authentification JWT obligatoire. Permission requise : la même que pour la gestion des news/events (Q1 — à identifier exactement à l'implémentation par grep dans `routers/admin/news.py`). Toutes les mutations écrivent dans `audit_logs` (D8).

Implémenté dans `usenghor_backend/app/routers/admin/faq.py`. Consommé par `useFaqApi.ts` côté Nuxt.

Format d'erreur standard du projet : `{ "detail": "string" }`. Codes courants : `400` (validation), `401` (token absent/invalide), `403` (permission manquante), `404` (entité absente), `409` (conflit — slug en double, suppression catégorie non vide), `422` (Pydantic).

---

## Catégories

### `GET /api/admin/faq/categories`

Liste toutes les catégories (actives et inactives) avec leur ordre. Triées par `display_order ASC`.

**Response 200**

```json
{
  "categories": [
    {
      "id": "uuid",
      "code": "general",
      "label_fr": "Général",
      "label_en": "General",
      "label_ar": "عام",
      "description_fr": null,
      "description_en": null,
      "description_ar": null,
      "display_order": 0,
      "is_active": true,
      "entry_count": 12,
      "created_at": "2026-05-02T10:00:00Z",
      "updated_at": "2026-05-02T10:00:00Z"
    }
  ]
}
```

`entry_count` : nombre total d'entrées (publiées ou non) dans la catégorie. Utile pour décider de la suppression.

---

### `POST /api/admin/faq/categories`

Crée une catégorie.

**Request body**

```json
{
  "code": "admissions",
  "label_fr": "Admissions",
  "label_en": "Admissions",
  "label_ar": "القبول",
  "description_fr": null,
  "description_en": null,
  "description_ar": null,
  "is_active": true
}
```

`display_order` n'est pas dans le payload : la nouvelle catégorie est ajoutée à la fin (`MAX(display_order) + 1`). Modifiable ensuite via `PATCH /reorder`.

Validation : `code` requis, pattern `^[a-z0-9_-]+$`, unique. `label_fr` requis.

**Response 201** : objet catégorie complet (même format que GET item).

**Audit** : `faq.category.create`.

---

### `PATCH /api/admin/faq/categories/{id}`

Met à jour une catégorie. Seuls les champs fournis sont modifiés (semantics `exclude_unset`).

**Request body** (tous optionnels) : `label_fr`, `label_en`, `label_ar`, `description_fr`, `description_en`, `description_ar`, `is_active`. Le champ `code` n'est pas modifiable après création (référence stable interne).

**Response 200** : objet catégorie complet.

**Audit** : `faq.category.update`.

---

### `DELETE /api/admin/faq/categories/{id}`

Supprime une catégorie.

**Erreurs** :
- `404` si l'id n'existe pas.
- `409` si `entry_count > 0` (FR-014). `detail` : « Catégorie non vide : {n} entrées rattachées ».
- `409` si `code = 'general'` (catégorie par défaut protégée).

**Response 204** : pas de corps.

**Audit** : `faq.category.delete`.

---

### `PATCH /api/admin/faq/categories/reorder`

Réordonne en lot.

**Request body**

```json
{ "items": [ { "id": "uuid-1", "display_order": 0 }, { "id": "uuid-2", "display_order": 1 } ] }
```

**Response 200** : `{ "updated": <int> }`.

**Audit** : `faq.category.reorder` (un seul log avec liste des changements).

---

## Entrées

### `GET /api/admin/faq/entries`

Liste paginée des entrées avec filtre.

**Query params** :
- `category_id` (UUID, optionnel)
- `is_published` (bool, optionnel)
- `q` (recherche full-text basique sur `question_fr`, optionnel)
- `page` (int, défaut 1), `page_size` (int, défaut 20, max 100)

**Response 200**

```json
{
  "items": [
    {
      "id": "uuid",
      "category_id": "uuid",
      "category_code": "general",
      "slug": "comment-postuler",
      "question_fr": "Comment postuler ?",
      "question_en": null,
      "question_ar": null,
      "is_published": false,
      "published_at": null,
      "display_order": 0,
      "created_at": "2026-05-02T10:00:00Z",
      "updated_at": "2026-05-02T10:00:00Z"
    }
  ],
  "total": 42,
  "page": 1,
  "page_size": 20
}
```

Note : la liste ne contient PAS les colonnes `answer_*_md|html` (allègement). Pour récupérer le contenu complet d'une entrée, utiliser `GET /entries/{id}`.

---

### `GET /api/admin/faq/entries/{id}`

Récupère une entrée complète, y compris tous les champs Markdown et HTML pour les trois langues. Aucun repli FR appliqué (l'admin doit voir les vrais NULL).

**Response 200** : tous les champs de la table `faq_entries` + `category_code` joint.

---

### `POST /api/admin/faq/entries`

Crée une entrée. Statut initial = brouillon (`is_published = false`).

**Request body**

```json
{
  "category_id": "uuid",
  "slug": null,
  "question_fr": "Comment postuler à l'Université Senghor ?",
  "question_en": null,
  "question_ar": null,
  "answer_fr_md": "## Procédure …",
  "answer_fr_html": "<h2>Procédure …</h2>",
  "answer_en_md": null,
  "answer_en_html": null,
  "answer_ar_md": null,
  "answer_ar_html": null
}
```

- Si `slug` est `null`, le service le génère depuis `question_fr` (D3).
- `answer_fr_md` ET `answer_fr_html` requis.
- `category_id` doit exister, sinon `400`.

**Response 201** : objet entrée complet avec `slug` final résolu.

**Audit** : `faq.entry.create`.

---

### `PATCH /api/admin/faq/entries/{id}`

Met à jour une entrée. Sémantique `exclude_unset`.

**Particularités** :
- Si `slug` est inclus et différent du courant, valider unicité ; conflit → `409`.
- Si `slug` est inclus et l'entrée est déjà publiée, l'API doit accepter mais le frontend admin DOIT afficher un avertissement « ancres existantes seront cassées ».
- `is_published` n'est pas modifié via cet endpoint (utiliser `PATCH /publish`).
- `category_id` peut être changé ; valider l'existence de la nouvelle catégorie.

**Response 200** : objet complet.

**Audit** : `faq.entry.update` (avec diff sur les champs réellement modifiés).

---

### `DELETE /api/admin/faq/entries/{id}`

Suppression définitive (pas de soft delete).

**Response 204**.

**Audit** : `faq.entry.delete`.

---

### `PATCH /api/admin/faq/entries/{id}/publish`

Bascule le statut de publication.

**Request body**

```json
{ "is_published": true }
```

- Sur `true` et `published_at IS NULL` → set `published_at = NOW()`.
- Sur `true` et `published_at` déjà set → laisse inchangé.
- Sur `false` → `published_at` conservé (mémoire de la 1ʳᵉ publi).
- Refuse (`400`) si on tente de publier une entrée dont `answer_fr_html` est vide ou la catégorie n'est plus active.

**Response 200** : objet entrée minimal `{ id, is_published, published_at, updated_at }`.

**Audit** : `faq.entry.publish` ou `faq.entry.unpublish`.

---

### `PATCH /api/admin/faq/entries/reorder`

Réordonne les entrées au sein d'une même catégorie.

**Request body**

```json
{ "category_id": "uuid", "items": [ { "id": "uuid-1", "display_order": 0 } ] }
```

**Response 200** : `{ "updated": <int> }`.

**Audit** : `faq.entry.reorder`.

---

## TypeScript types (à générer dans `app/types/api/faq.ts`)

```ts
export interface FaqCategoryAdmin {
  id: string;
  code: string;
  label_fr: string;
  label_en: string | null;
  label_ar: string | null;
  description_fr: string | null;
  description_en: string | null;
  description_ar: string | null;
  display_order: number;
  is_active: boolean;
  entry_count: number;
  created_at: string;
  updated_at: string;
}

export interface FaqEntryAdminListItem {
  id: string;
  category_id: string;
  category_code: string;
  slug: string;
  question_fr: string;
  question_en: string | null;
  question_ar: string | null;
  is_published: boolean;
  published_at: string | null;
  display_order: number;
  created_at: string;
  updated_at: string;
}

export interface FaqEntryAdminFull extends FaqEntryAdminListItem {
  answer_fr_md: string;
  answer_fr_html: string;
  answer_en_md: string | null;
  answer_en_html: string | null;
  answer_ar_md: string | null;
  answer_ar_html: string | null;
  created_by: string | null;
  updated_by: string | null;
}
```

---

## Synthèse des actions auditées

| Action                  | Endpoint                                            | Code HTTP succès |
|-------------------------|-----------------------------------------------------|------------------|
| `faq.category.create`   | `POST /categories`                                  | 201 |
| `faq.category.update`   | `PATCH /categories/{id}`                            | 200 |
| `faq.category.delete`   | `DELETE /categories/{id}`                           | 204 |
| `faq.category.reorder`  | `PATCH /categories/reorder`                         | 200 |
| `faq.entry.create`      | `POST /entries`                                     | 201 |
| `faq.entry.update`      | `PATCH /entries/{id}`                               | 200 |
| `faq.entry.delete`      | `DELETE /entries/{id}`                              | 204 |
| `faq.entry.publish`     | `PATCH /entries/{id}/publish` (`{ is_published: true }`)  | 200 |
| `faq.entry.unpublish`   | `PATCH /entries/{id}/publish` (`{ is_published: false }`) | 200 |
| `faq.entry.reorder`     | `PATCH /entries/reorder`                            | 200 |
