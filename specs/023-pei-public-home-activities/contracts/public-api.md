# Contrat — Lectures publiques consommées et modifiées (023)

Sans authentification, lecture seule. Les lectures du pôle (021 / 022) sont **inchangées** ; seule la liste publique des événements évolue (additif, défauts préservés).

## Inchangé — pôle (`/api/public/entrepreneurship`)

| Méthode | Route | Réponse | Utilisée par |
|---|---|---|---|
| GET | `/programs` | `PeiProgramPublic[]` (actifs, `display_order`) | accueil, activités |
| GET | `/partners` | `PeiPartnerFamilyPublic[]` (3 familles fixes, partenaires actifs) | accueil |
| GET | `/programs/{code}`, `/cohorts`, `/cohorts/{code}`, `/laureates`, `/resources` | (022 / 021) | exposées par le composable pour 024, non utilisées ici |

Cache : `Cache-Control: public, max-age=60, stale-while-revalidate=300`.

## Inchangé — actualités

`GET /api/public/news?service_id={uuid}&limit=3&page=1` → `PaginatedResponse<NewsPublicEnriched>` (publiées, `published_at` desc). Front : `usePublicNewsApi().getAllPublishedNews({ service_id, limit: 3 })` → `NewsDisplay[]`.

## Inchangé — service

`GET /api/public/services/{id}` → `ServicePublicWithDetails` (`name`, `acronym`, …). Front : `usePublicOrganizationApi().getServiceById(id)` ; 404 ou id invalide → fil d'Ariane « DDE » sans lien, sections dépendantes masquées.

## Modifié — événements

`GET /api/public/events`

| Paramètre | Type | Défaut | Nouveau ? | Effet |
|---|---|---|---|---|
| `page`, `limit` | int | 1, 20 | non | pagination |
| `from_date`, `to_date` | datetime | — | non | bornes sur `start_date` |
| `campus_id` | str | — | non | `campus_external_id = campus_id` |
| `upcoming` | bool | false | non | `from_date = now()` |
| **`service_id`** | str (UUID) | — | **oui** | `service_external_id = service_id` |
| **`order`** | `asc` \| `desc` | `desc` | **oui** | tri sur `start_date` |

Réponse inchangée (`items: EventPublic[]`, `total`, `page`, `limit`, `pages`). Toute valeur d'`order` hors `asc` / `desc` → 422. Appel du mini-site : `?service_id={dde}&upcoming=true&order=asc&limit=6`.

Front : `usePublicEventsApi().listPublishedEvents({ service_id, upcoming: true, order: 'asc', limit: 6 })`.

Tests (`tests/integration/test_public_events_service_filter.py`) : (1) deux événements publiés rattachés à deux services, filtre → un seul ; (2) `order=asc` renvoie du plus proche au plus lointain, défaut inchangé (desc) ; (3) `upcoming=true&order=asc` exclut les passés ; (4) brouillon exclu ; (5) `order=foo` → 422.
