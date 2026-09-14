# Contrat — Lectures publiques consommées (024)

**Aucune évolution d'API dans cette feature.** Les quatre pages consomment uniquement des lectures publiques existantes (sans authentification, `useApiBase()` + `$fetch`, cache `public, max-age=60, stale-while-revalidate=300` pour le pôle).

| Page | Appel | Paramètres | Réponse | Composable |
|---|---|---|---|---|
| alumni | `GET /api/public/entrepreneurship/laureates` | aucun (filtrage par type à l'affichage) | `PeiLaureatesPublic { groups: { cohort, laureates[] }[], stats }` — contrat 022 | `usePublicEntrepreneurshipApi().listLaureates()` |
| partenaires | `GET /api/public/entrepreneurship/partners` | aucun | `PeiPartnerFamilyPublic[]` (3 familles, ordre fixe, `partners: []` si vide) | `listPartners()` |
| ressources | `GET /api/public/entrepreneurship/resources` | aucun (regroupement à l'affichage) | `PeiResourcePublic[]` triés `display_order` | `listResources()` |
| ressources | `GET /api/public/services/{id}` | `id` = `entrepreneurship.dde_service_id` | `ServicePublicWithDetails` dont `album_ids: string[]`, `album_external_id` | `usePublicOrganizationApi().getServiceById()` |
| ressources | `GET /api/public/albums/{id}` (× n) | | `AlbumWithMedia { id, title, description, display_order, media_items: MediaRead[] }` ou `null` | `usePublicAlbumsApi().getAlbumById()` |
| ressources | `GET /api/public/media/{id}/download?download=1` | via `media_url` de la ressource | fichier (`Content-Disposition: attachment`) | lien direct |
| actualités | `GET /api/public/news` | `service_id`, `page` (1..), `limit=12` | `PaginatedResponse<NewsDisplay> { items, total, page, limit, pages }` — tri `published_at` desc | `usePublicNewsApi().listPublishedNews()` |
| actualités | `GET /api/public/events` | `service_id`, `upcoming=true`, `order=asc`, `page`, `limit=10` | `PaginatedResponse<EventPublic>` | `usePublicEventsApi().listPublishedEvents()` |
| actualités | `GET /api/public/events` | `service_id`, `to_date=<now ISO>`, `order=desc`, `page`, `limit=10` | idem — `to_date` filtre `start_date <= to_date` (complément exact de `upcoming`, aucun filtre client) | idem |
| toutes | `GET /api/public/editorial/contents?keys=…` | clés `entrepreneurship.*` | valeurs monolingues FR | `useEditorialContent('entrepreneurship')` |
| toutes (fil d'Ariane) | `GET /api/public/services/{id}` | `dde_service_id` | `name`, `sigle` → `getServiceUrl()` | `usePublicOrganizationApi()` |

## Garanties utilisées

- Portraits : seuls `is_published = true` avec cohorte `active = true` ; cohortes sans portrait omises ; `photo_url` résolue (jamais d'UUID) ; `grant_amount` non exposé.
- Partenaires : seuls `partners.active = true` ; `logo_url` `null` si média absent ; aucun réseau social.
- Ressources : seules `is_published = true` ; `document` → `media_url` non nul (sinon la carte est masquée côté front), `link` / `video` → `url` non nul.
- Actualités : jointure `news_services` sur `service_id` ; une actualité multi-services n'apparaît qu'une fois.
- Événements : filtre `events.service_external_id` ; `upcoming=true` ⇒ `start_date >= now` ; `to_date` ⇒ `start_date <= to_date` ; `order` accepté `asc | desc` (422 sinon).
- Téléchargement : `GET /api/public/media/{id}/download?download=1` renvoie `Content-Disposition: attachment` (vérifié dans `routers/public/media.py`, sinon `inline`).

## Non-régression

Tests backend existants à exécuter sans modification : `tests/integration/test_public_entrepreneurship_api.py`, `tests/integration/test_public_events_service_filter.py`.
