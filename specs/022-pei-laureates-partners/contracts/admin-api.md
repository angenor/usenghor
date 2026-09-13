# Contrat — API admin `/api/admin/entrepreneurship` (ajouts 022)

Mêmes règles que le contrat 021 ([admin-api.md](../../021-pei-entrepreneurship-core/contracts/admin-api.md)) : JWT, `PermissionChecker` (`entrepreneurship.view` lecture, `.create` création / rattachement, `.edit` modification / publication / mise en avant / famille / reorder, `.delete` suppression / retrait), `_client_meta` → audit sur toute écriture. Erreurs : 401, 403, 404, 409, 422.

Ordre de déclaration dans chaque groupe : `GET ""`, `POST ""`, `PATCH /reorder`, `POST /translate`, `GET /available`, puis `/{id}` et ses sous-routes.

## Transversal (modifiés)

### GET /dashboard → `PeiDashboardStats` (+ 2 blocs)
```json
{ "programs": {...}, "cohorts": {...}, "resources": {...}, "dde_service": {...},
  "laureates": { "published": 3, "total": 5 },
  "partners":  { "active": 6, "total": 7 } }
```
`partners.total` = rattachements ; `partners.active` = rattachements dont le partenaire est actif.

### POST /translate-missing → `PeiTranslateMissingResponse` (+ `laureates`)
`{ "programs": 0, "cohorts": 0, "resources": 0, "laureates": 4, "complete": true }` — champs `department_label` et `quote` (EN / AR vides), avec clamp à 600 caractères.

### DELETE /cohorts/{id} — comportement activé
409 `{ "detail": "Cohorte utilisée par N lauréats" }` dès qu'un portrait référence la cohorte.

## Portraits `/laureates`

| Verbe | Chemin | Perm. | Corps / query | Réponse |
|---|---|---|---|---|
| GET | `/laureates` | view | `q` (nom ou projet, ILIKE), `cohort_id`, `type`, `is_published` (bool), `page`=1, `page_size`=50 (max 100) | `{ items: PeiLaureateAdmin[], total, page, page_size }` tri `cohort.display_order, display_order` |
| POST | `/laureates` | create | `PeiLaureateCreate` | 201 `PeiLaureateAdmin` |
| PATCH | `/laureates/reorder` | edit | `{ "cohort_id": "uuid", "ids": ["uuid", …] }` (tous les portraits de la cohorte) | `{ "updated": n }` |
| POST | `/laureates/translate` | view | `{ department_label?, quote? }` | `{ department_label_en, department_label_ar, quote_en, quote_ar }` sans persistance |
| GET | `/laureates/{id}` | view | | `PeiLaureateAdmin` |
| PATCH | `/laureates/{id}` | edit | `PeiLaureateUpdate` (`exclude_unset`) | `PeiLaureateAdmin` |
| DELETE | `/laureates/{id}` | delete | | 204 (renumérote la cohorte) |
| PATCH | `/laureates/{id}/publish` | edit | `{ "is_published": bool }` | `{ id, is_published, published_at, updated_at }` |
| PATCH | `/laureates/{id}/featured` | edit | `{ "is_featured": bool }` | `{ id, is_featured, updated_at }` |

`PeiLaureateCreate` : `cohort_id` (UUID, requis), `type` (`fse_laureate|student_entrepreneur`), `full_name` (2–200), `project_name` (2–200), `department_label?/_en?/_ar?` (≤ 200), `quote?/_en?/_ar?` (≤ 600, message « Le verbatim ne doit pas dépasser 600 caractères »), `photo_external_id?` (UUID), `website_url?`, `linkedin_url?`, `instagram_url?`, `facebook_url?`, `video_url?` (HttpUrl → str, ≤ 500, chaîne vide → null), `grant_amount?` (Decimal ≥ 0, 2 décimales), `is_featured` (défaut false), `is_published` (défaut false). `display_order` calculé (`MAX + 1` dans la cohorte).

`PeiLaureateUpdate` : mêmes champs, tous optionnels. Changer `cohort_id` → dernière position de la nouvelle cohorte + renumérotation de l'ancienne ; changer `type` ou `cohort_id` déclenche la vérification de cohérence.

`PeiLaureateAdmin` = table + `photo_url` (résolu) + `cohort: { id, code, label, type, year, active }` + `grant_amount` en chaîne (`"5000.00"`) + `created_at`, `updated_at`, `created_by`, `updated_by`.

Règles :
- 404 cohorte inconnue ; 422 « Un lauréat FSE doit appartenir à une cohorte FSE » / « Un étudiant-entrepreneur doit appartenir à une cohorte SEE » ; 422 URL invalide (« Adresse web invalide : linkedin_url ») ; 422 montant négatif.
- Après application, `autofill_translations` sur `department_label` (text) et `quote` (text), traductions tronquées à 600.
- `publish` : `published_at` fixé à la première publication, jamais remis à NULL.
- Audit : `entrepreneurship.laureate.create|update|delete|reorder|publish|unpublish|feature|unfeature`.

## Partenaires du pôle `/partners`

| Verbe | Chemin | Perm. | Corps / query | Réponse |
|---|---|---|---|---|
| GET | `/partners` | view | `family?` | `PeiPartnerLinkAdmin[]` tri `family (rang fixe), display_order` |
| POST | `/partners` | create | `{ "partner_id": "uuid", "family": "academic|support|international" }` | 201 `PeiPartnerLinkAdmin` |
| PATCH | `/partners/reorder` | edit | `{ "family": "support", "ids": ["uuid", …] }` (tous les partenaires de la famille) | `{ "updated": n }` |
| GET | `/partners/available` | view | `q?` (nom ou description, ILIKE), `limit`=20 (max 50) | `PeiPartnerAvailable[]` — partenaires **non rattachés**, actifs d'abord, tri nom |
| PATCH | `/partners/{partner_id}` | edit | `{ "family": "…" }` | `PeiPartnerLinkAdmin` (dernière position de la nouvelle famille) |
| DELETE | `/partners/{partner_id}` | delete | | 204 (retire le rattachement, renumérote la famille ; le partenaire reste) |

`PeiPartnerLinkAdmin` : `{ partner_id, family, display_order, created_at, updated_at, partner: { id, name, type, active, website, logo_url, description } }`.

`PeiPartnerAvailable` : `{ id, name, type, active, logo_url }`.

Règles : 404 partenaire inconnu ; 409 « Ce partenaire est déjà rattaché au pôle » ; 422 famille inconnue ; reorder → 422 si un identifiant manque, est inconnu, dupliqué ou n'appartient pas à la famille. Un partenaire inactif peut être rattaché (badge « Inactif » en admin, exclu du public).

Audit : `entrepreneurship.partner.link|update|unlink|reorder` (`table_name = pei_partners`, `record_id = partner_id`, reorder `record_id = NULL`, `new_values = { family, ids }`).

## Sémantique du `reorder` scopé (portraits et partenaires)
- Le corps porte la portée (`cohort_id` ou `family`) et **tous** les identifiants de cette portée, dans l'ordre voulu.
- Le serveur écrit `display_order = index` (0..n-1) dans la portée uniquement ; une seule entrée d'audit.
- `updated` = nombre de lignes dont l'ordre a changé.
