# Contrat — API admin `/api/admin/entrepreneurship`

JWT obligatoire (`CurrentUser`), permissions via `PermissionChecker` : lecture `entrepreneurship.view`, création `entrepreneurship.create`, modification / reorder / toggle / traduction `entrepreneurship.edit`, suppression `entrepreneurship.delete`. Chaque handler passe `user_id`, `ip_address`, `user_agent` (`_client_meta`) au service ; toute écriture produit une entrée `audit_logs` (voir [data-model.md](../data-model.md) §2.6).

Erreurs : 401 non authentifié, 403 permission manquante, 404 introuvable, 409 code déjà utilisé / suppression bloquée, 422 validation (Pydantic ou métier).

Ordre de déclaration dans chaque groupe : `GET ""`, `POST ""`, `PATCH /reorder`, `POST /translate`, puis `/{id}`, `PATCH /{id}/active|publish`.

## Transversal

### GET /dashboard → `PeiDashboardStats`
```json
{ "programs": {"active": 5, "total": 5}, "cohorts": {"active": 3, "total": 3}, "resources": {"published": 0, "total": 0},
  "dde_service": {"id": "uuid|null", "name": "Direction du Développement et de l'Entrepreneuriat|null"} }
```
`dde_service` lu depuis la clé éditoriale `entrepreneurship.dde_service_id` et résolu dans `services` (null si clé vide ou service inexistant).

### POST /translate-missing → `PeiTranslateMissingResponse` (edit)
Remplit les champs `_en` / `_ar` vides des trois tables (`autofill_translations`, `force=False`). Réponse `{ "programs": 5, "cohorts": 3, "resources": 0, "complete": true }` = nombre d'objets modifiés ; second appel → zéros. Audit `entrepreneurship.translate_missing`.

Budget de temps (≈ 50 s, sous le `proxy_read_timeout` nginx de 90 s) : si le budget est épuisé, le travail fait est enregistré et `complete` vaut `false` ; le client relance l'appel jusqu'à `complete: true` (les champs déjà remplis ne sont plus retraduits). Le backoffice cesse de relancer si une passe incomplète n'a complété aucun élément (traducteur indisponible) et invite à réessayer plus tard. Ajouté à l'implémentation après mesure : ~80 appels séquentiels au traducteur pour les données initiales.

## Dispositifs `/programs`

| Verbe | Chemin | Perm. | Corps | Réponse |
|---|---|---|---|---|
| GET | `/programs` | view | query `q` (titre FR, ILIKE), `phase`, `active` (bool), `page`=1, `page_size`=50 (max 100) | `{ items: PeiProgramAdmin[], total, page, page_size }` |
| POST | `/programs` | create | `PeiProgramCreate` | 201 `PeiProgramAdmin` |
| PATCH | `/programs/reorder` | edit | `{ "ids": ["uuid", …] }` (liste complète) | `{ "updated": n }` |
| POST | `/programs/translate` | view | `{ title?, tagline?, highlight?, content_md?, content_html? }` | `{ title_en, title_ar, tagline_en, …, content_en_html, … }` sans persistance |
| GET | `/programs/{id}` | view | | `PeiProgramAdmin` |
| PATCH | `/programs/{id}` | edit | `PeiProgramUpdate` (tous champs optionnels, `exclude_unset`) | `PeiProgramAdmin` |
| DELETE | `/programs/{id}` | delete | | 204 |
| PATCH | `/programs/{id}/active` | edit | `{ "active": true\|false }` | `{ id, active, updated_at }` |

`PeiProgramCreate` : `code` (regex `^[a-z0-9][a-z0-9-]*$`, ≤ 60), `sigle?`, `title` (3–200), `title_en?`, `title_ar?`, `phase` (enum), `tagline?/_en?/_ar?`, `content_md?`, `content_html?`, `content_en_md?`, `content_en_html?`, `content_ar_md?`, `content_ar_html?`, `highlight?/_en?/_ar?` (≤ 120), `color` (enum `blue|blue_dark|red|amber|teal`, défaut `blue`), `cover_image_external_id?` (UUID), `active` (défaut true). `display_order` calculé (`MAX + 1`) — non fourni à la création.

`PeiProgramAdmin` = tous les champs de la table + `cover_image_url` (résolu) + `created_at`, `updated_at`, `created_by`, `updated_by`.

Règles : 409 si `code` existe (création ou modification vers un code existant) ; après application des changements, `autofill_translations` complète les champs EN/AR vides.

## Cohortes `/cohorts`

| Verbe | Chemin | Perm. | Corps | Réponse |
|---|---|---|---|---|
| GET | `/cohorts` | view | query `q` (label), `type`, `active`, `page`, `page_size` | `{ items: PeiCohortAdmin[], total, page, page_size }` |
| POST | `/cohorts` | create | `PeiCohortCreate` | 201 |
| PATCH | `/cohorts/reorder` | edit | `{ "ids": [...] }` | `{ "updated": n }` |
| POST | `/cohorts/translate` | view | `{ label?, focus?, summary_md?, summary_html? }` | traductions sans persistance |
| GET | `/cohorts/{id}` | view | | `PeiCohortAdmin` |
| PATCH | `/cohorts/{id}` | edit | `PeiCohortUpdate` | `PeiCohortAdmin` |
| DELETE | `/cohorts/{id}` | delete | | 204 · **409** réservé (feature 022 : « Cohorte utilisée par N lauréats ») |
| PATCH | `/cohorts/{id}/active` | edit | `{ "active": bool }` | `{ id, active, updated_at }` |

`PeiCohortCreate` : `code`, `label` (1–200), `label_en?`, `label_ar?`, `year` (2000–2100), `type` (`fse|see`), `focus?/_en?/_ar?`, `summary_md?`, `summary_html?`, `summary_en_*?`, `summary_ar_*?`, `active`.

## Ressources `/resources`

| Verbe | Chemin | Perm. | Corps | Réponse |
|---|---|---|---|---|
| GET | `/resources` | view | query `q` (titre), `type`, `category`, `is_published`, `page`, `page_size` | `{ items: PeiResourceAdmin[], total, page, page_size }` |
| GET | `/resources/categories` | view | | `string[]` (catégories FR distinctes, pour le filtre) |
| POST | `/resources` | create | `PeiResourceCreate` | 201 |
| PATCH | `/resources/reorder` | edit | `{ "ids": [...] }` | `{ "updated": n }` |
| POST | `/resources/translate` | view | `{ title?, description?, category? }` | traductions sans persistance |
| GET | `/resources/{id}` | view | | `PeiResourceAdmin` |
| PATCH | `/resources/{id}` | edit | `PeiResourceUpdate` | `PeiResourceAdmin` |
| DELETE | `/resources/{id}` | delete | | 204 |
| PATCH | `/resources/{id}/publish` | edit | `{ "is_published": bool }` | `{ id, is_published, published_at, updated_at }` |

`PeiResourceCreate` : `title` (1–200), `title_en?`, `title_ar?`, `description?/_en?/_ar?`, `type` (`document|link|video`), `media_external_id?` (UUID), `url?` (HttpUrl, ≤ 500), `category?/_en?/_ar?` (≤ 120), `is_published` (défaut false). Validateur de modèle (Pydantic `model_validator`) : `document` ⇒ `media_external_id` requis ; `link|video` ⇒ `url` requis ; messages 422 « Un document de la médiathèque est requis pour le type document » / « Une URL est requise pour le type lien ou vidéo ». Même règle en base (`chk_pei_resources_source`).

`PeiResourceAdmin` = table + `media_url` (résolu).

## Sémantique de `reorder` (les trois entités)
- Le corps contient **tous** les identifiants de l'entité dans l'ordre voulu ; un identifiant inconnu → 422 ; un identifiant manquant → 422 (« liste incomplète »).
- Le serveur écrit `display_order = index` (0..n-1), une seule entrée d'audit `…reorder` avec `new_values = {"ids": [...]}`.
- `updated` = nombre de lignes dont l'ordre a changé.
