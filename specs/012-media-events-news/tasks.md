# Tasks: Associer une médiathèque aux événements et actualités

**Input**: Design documents from `/specs/012-media-events-news/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Non requis (tests manuels via Swagger + navigateur)

**Organization**: Tasks groupées par user story pour une implémentation et un test indépendants de chaque story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut être exécuté en parallèle (fichiers différents, pas de dépendances)
- **[Story]**: User story concernée (US1, US2, US3, US4)
- Chemins exacts inclus dans chaque description

---

## Phase 1: Setup

**Purpose**: Migration de base de données et mise à jour du schéma source

- [x] T001 Créer le fichier de migration SQL dans `usenghor_backend/documentation/modele_de_données/migrations/012_media_events_news.sql` : ALTER TABLE `event_media_library` ADD COLUMN `display_order` INT DEFAULT 0, CREATE TABLE `news_media_library` (news_id UUID, album_external_id UUID, display_order INT, PK composite)
- [x] T002 Appliquer la migration sur la base locale : `docker exec -i usenghor_postgres psql -U usenghor -d usenghor < usenghor_backend/documentation/modele_de_données/migrations/012_media_events_news.sql`
- [x] T003 [P] Mettre à jour le schéma source de vérité dans `usenghor_backend/documentation/modele_de_données/services/09_content.sql` : ajouter `display_order` à `event_media_library` et ajouter la définition de `news_media_library`

---

## Phase 2: Foundational (Prérequis bloquants)

**Purpose**: Modèles, schemas et types partagés qui doivent être complétés avant toute user story

**⚠️ CRITICAL**: Aucune user story ne peut commencer avant la fin de cette phase

- [x] T004 Modifier le modèle `EventMediaLibrary` dans `usenghor_backend/app/models/content.py` : ajouter le champ `display_order` (Mapped[int], Integer, default=0)
- [x] T005 Créer le modèle `NewsMediaLibrary` dans `usenghor_backend/app/models/content.py` : table `news_media_library` avec `news_id` (FK → news.id, PK, CASCADE), `album_external_id` (UUID, PK), `display_order` (INT, default 0). Suivre le pattern exact de `EventMediaLibrary`
- [x] T006 Ajouter la relation `media_library` au modèle `Event` dans `usenghor_backend/app/models/content.py` : relationship vers `EventMediaLibrary` avec cascade="all, delete-orphan", lazy="selectin"
- [x] T007 Ajouter la relation `media_library` au modèle `News` dans `usenghor_backend/app/models/content.py` : relationship vers `NewsMediaLibrary` avec cascade="all, delete-orphan", lazy="selectin"
- [x] T008 [P] Créer les schemas Pydantic pour les associations album dans `usenghor_backend/app/schemas/content.py` : `ContentAlbumAdd` (album_ids: list[str]), `ContentAlbumReorder` (album_ids: list[str]), `ContentAlbumEntry` (album_external_id, display_order, album: AlbumSummary | None), `AlbumSummary` (id, title, status, media_count, cover_url), `ContentAlbumsResponse` (albums: list[ContentAlbumEntry])
- [x] T009 [P] Ajouter les types TypeScript dans `usenghor_nuxt/app/types/api/media.ts` : `ContentAlbumEntry` (album_external_id, display_order, album: AlbumSummary | null), `AlbumSummary` (id, title, status, media_count, cover_url), `PublicAlbumWithMedia` (id, title, description, display_order, media_items: MediaRead[])

**Checkpoint**: Fondation prête — les user stories peuvent maintenant commencer

---

## Phase 3: User Story 1 - Associer des albums à un événement (Priority: P1) 🎯 MVP

**Goal**: Permettre aux administrateurs d'associer/dissocier des albums à un événement via l'admin, et exposer les albums publiquement

**Independent Test**: Créer un événement dans l'admin → lui associer un album existant → vérifier via Swagger que GET /api/admin/events/{id}/albums retourne l'album → vérifier que GET /api/public/events/{slug}/albums retourne l'album publié

### Backend US1

- [x] T010 [US1] Ajouter les méthodes de service pour event→albums dans `usenghor_backend/app/services/content_service.py` : `add_albums_to_event(event_id, album_ids)`, `remove_album_from_event(event_id, album_id)`, `get_event_albums(event_id)`, `get_event_published_albums(event_slug)` (jointure avec albums pour récupérer titre/status/media_count). Suivre le pattern de `add_media_to_album()` dans `media_service.py`
- [x] T011 [US1] Ajouter les endpoints admin dans `usenghor_backend/app/routers/admin/events.py` : POST `/{event_id}/albums` (body: ContentAlbumAdd), GET `/{event_id}/albums`, DELETE `/{event_id}/albums/{album_id}`. IMPORTANT: déclarer ces routes AVANT la route `/{event_id}` dynamique pour éviter les conflits de path
- [x] T012 [US1] Ajouter l'endpoint public dans `usenghor_backend/app/routers/public/events.py` : GET `/{slug}/albums` retournant les albums publiés avec leurs médias (jointure albums → album_media → media, filtré par status=published). IMPORTANT: déclarer AVANT la route `/{slug}` dynamique

### Frontend US1

- [x] T013 [P] [US1] Ajouter les méthodes albums au composable `usenghor_nuxt/app/composables/useEventsApi.ts` : `getEventAlbums(eventId)`, `addAlbumsToEvent(eventId, albumIds)`, `removeAlbumFromEvent(eventId, albumId)` via `apiFetch()`
- [x] T014 [P] [US1] Ajouter `getEventAlbums(slug)` au composable `usenghor_nuxt/app/composables/usePublicEventsApi.ts` : GET `/api/public/events/${slug}/albums` via `useApiBase()` + `$fetch()`
- [x] T015 [US1] Créer le composant `usenghor_nuxt/app/components/admin/AlbumSelector.vue` : composant réutilisable de sélection multi-albums. Charge la liste des albums via `useAlbumsApi().listAlbums()`, affiche les albums sous forme de cartes avec titre + miniature du premier média + badge de statut, permet ajout/retrait par clic, émet les changements via `@add` et `@remove` events. Inclure un champ de recherche par titre
- [x] T016 [US1] Intégrer `AlbumSelector` dans le formulaire admin d'édition d'événement `usenghor_nuxt/app/pages/admin/contenus/evenements/[id]/edit.vue` : remplacer le champ texte UUID `album_external_id` dans l'onglet "Options" par une section "Médiathèque" utilisant `AlbumSelector`. Au montage, charger les albums associés via `getEventAlbums()`. Sur ajout/retrait, appeler `addAlbumsToEvent()`/`removeAlbumFromEvent()` immédiatement (pattern temps réel, pas à la sauvegarde)

**Checkpoint**: US1 testable — un admin peut associer/dissocier des albums à un événement, et les albums sont accessibles via l'API publique

---

## Phase 4: User Story 2 - Associer des albums à une actualité (Priority: P1)

**Goal**: Permettre aux administrateurs d'associer/dissocier des albums à une actualité, symétrique à US1

**Independent Test**: Créer une actualité dans l'admin → lui associer un album → vérifier via Swagger et via le formulaire admin que l'association fonctionne

### Backend US2

- [x] T017 [US2] Ajouter les méthodes de service pour news→albums dans `usenghor_backend/app/services/content_service.py` : `add_albums_to_news(news_id, album_ids)`, `remove_album_from_news(news_id, album_id)`, `get_news_albums(news_id)`, `get_news_published_albums(news_slug)`. Même pattern que les méthodes event (T010), adapté à NewsMediaLibrary
- [x] T018 [US2] Ajouter les endpoints admin dans `usenghor_backend/app/routers/admin/news.py` : POST `/{news_id}/albums`, GET `/{news_id}/albums`, DELETE `/{news_id}/albums/{album_id}`. Déclarer AVANT la route `/{news_id}` dynamique
- [x] T019 [US2] Ajouter l'endpoint public dans `usenghor_backend/app/routers/public/news.py` : GET `/{slug}/albums` retournant les albums publiés avec médias. Déclarer AVANT la route `/{slug}` dynamique

### Frontend US2

- [x] T020 [P] [US2] Ajouter les méthodes albums au composable `usenghor_nuxt/app/composables/useAdminNewsApi.ts` : `getNewsAlbums(newsId)`, `addAlbumsToNews(newsId, albumIds)`, `removeAlbumFromNews(newsId, albumId)`
- [x] T021 [P] [US2] Ajouter `getNewsAlbums(slug)` au composable `usenghor_nuxt/app/composables/usePublicNewsApi.ts` via `useApiBase()` + `$fetch()`
- [x] T022 [US2] Intégrer `AlbumSelector` (créé en T015) dans le formulaire admin d'édition d'actualité `usenghor_nuxt/app/pages/admin/contenus/actualites/[id]/edit.vue` : ajouter une section "Médiathèque" dans la zone "Associations" avec le composant `AlbumSelector`. Au montage, charger les albums via `getNewsAlbums()`. Sur ajout/retrait, appeler les méthodes de `useAdminNewsApi()` en temps réel

**Checkpoint**: US2 testable — un admin peut associer/dissocier des albums à une actualité

---

## Phase 5: User Story 3 - Affichage de la médiathèque dans un onglet dédié (Priority: P1)

**Goal**: Afficher les albums associés dans un onglet "Médiathèque" conditionnel sur les pages de détail publiques des événements et actualités

**Independent Test**: Naviguer vers un événement ou une actualité ayant des albums publiés associés → vérifier que l'onglet "Médiathèque" apparaît → cliquer dessus → voir les albums avec grille de médias → cliquer sur une image pour ouvrir la lightbox

### Implementation US3

- [x] T023 [P] [US3] Ajouter les clés i18n pour l'onglet médiathèque dans `usenghor_nuxt/i18n/locales/fr/`, `en/`, `ar/` : clés `mediaLibrary.tab` ("Médiathèque" / "Media Library" / "مكتبة الوسائط"), `mediaLibrary.details` ("Détails" / "Details" / "التفاصيل"), `mediaLibrary.empty` ("Aucun album disponible" / ...)
- [x] T024 [US3] Créer le composant `usenghor_nuxt/app/components/media/MediaLibraryTab.vue` : props `albums` (PublicAlbumWithMedia[]), affiche les albums avec le composant existant `MediaAlbumCard` en grille responsive, chaque album ouvre `MediaAlbumModal` au clic. Si albums vide, ne rien afficher. Supports dark mode via Tailwind classes existantes
- [x] T025 [US3] Ajouter un système d'onglets à la page de détail publique des événements `usenghor_nuxt/app/pages/actualites/evenements/[id].vue` : onglet "Détails" (contenu existant) + onglet "Médiathèque" (conditionnel, visible seulement si `albums.length > 0`). Au montage, appeler `getEventAlbums(event.slug)`. Utiliser `MediaLibraryTab` dans l'onglet médiathèque. Onglets en Tailwind CSS avec style responsive et dark mode
- [x] T026 [US3] Ajouter un système d'onglets à la page de détail publique des actualités `usenghor_nuxt/app/pages/actualites/[slug].vue` : même pattern que T025 mais pour les actualités. Appeler `getNewsAlbums(slug)`. Onglet "Médiathèque" conditionnel

**Checkpoint**: US3 testable — les visiteurs voient l'onglet "Médiathèque" sur les pages de détail, avec lightbox fonctionnelle

---

## Phase 6: User Story 4 - Gestion de l'ordre d'affichage (Priority: P2)

**Goal**: Permettre aux administrateurs de réordonner les albums associés

**Independent Test**: Associer 3 albums à un événement → réordonner dans l'admin → vérifier que l'ordre est respecté sur la page publique

### Backend US4

- [x] T027 [US4] Ajouter les méthodes de reorder dans `usenghor_backend/app/services/content_service.py` : `reorder_event_albums(event_id, album_ids)` et `reorder_news_albums(news_id, album_ids)`. Pour chaque album_id dans la liste, mettre à jour `display_order` = index
- [x] T028 [P] [US4] Ajouter les endpoints reorder dans `usenghor_backend/app/routers/admin/events.py` : PUT `/{event_id}/albums/reorder` (body: ContentAlbumReorder)
- [x] T029 [P] [US4] Ajouter les endpoints reorder dans `usenghor_backend/app/routers/admin/news.py` : PUT `/{news_id}/albums/reorder` (body: ContentAlbumReorder)

### Frontend US4

- [x] T030 [P] [US4] Ajouter les méthodes `reorderEventAlbums(eventId, albumIds)` dans `usenghor_nuxt/app/composables/useEventsApi.ts` et `reorderNewsAlbums(newsId, albumIds)` dans `usenghor_nuxt/app/composables/useAdminNewsApi.ts`
- [x] T031 [US4] Ajouter la fonctionnalité de réordonnancement dans `usenghor_nuxt/app/components/admin/AlbumSelector.vue` : boutons haut/bas (flèches) sur chaque album sélectionné pour modifier l'ordre. À chaque changement d'ordre, appeler le callback `@reorder` avec la nouvelle liste ordonnée d'IDs

**Checkpoint**: US4 testable — l'ordre des albums est modifiable et persisté

---

## Phase 7: Polish & Vérifications

**Purpose**: Vérifications finales et nettoyage

- [x] T032 Vérifier les cas limites : suppression d'un événement/actualité → les associations sont supprimées en cascade. Suppression d'un album → les associations orphelines sont ignorées au chargement (pas de FK). Album passé en draft → invisible en public mais visible en admin
- [x] T033 [P] Vérifier le responsive et le dark mode de l'onglet médiathèque et du sélecteur d'albums sur mobile
- [x] T034 [P] Vérifier le support RTL (arabe) pour l'onglet médiathèque et le sélecteur d'albums

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Aucune dépendance — peut commencer immédiatement
- **Foundational (Phase 2)**: Dépend de Setup — BLOQUE toutes les user stories
- **US1 (Phase 3)**: Dépend de Foundational
- **US2 (Phase 4)**: Dépend de Foundational + T015 (AlbumSelector créé en US1)
- **US3 (Phase 5)**: Dépend de US1 et US2 (nécessite les endpoints publics)
- **US4 (Phase 6)**: Dépend de US1 et US2 (nécessite les endpoints + AlbumSelector)
- **Polish (Phase 7)**: Dépend de toutes les phases précédentes

### User Story Dependencies

- **US1 (P1)**: Peut commencer après Phase 2 — Crée AlbumSelector (partagé)
- **US2 (P1)**: Peut commencer après Phase 2 + T015 — Réutilise AlbumSelector
- **US3 (P1)**: Dépend des endpoints publics de US1 (T012) et US2 (T019)
- **US4 (P2)**: Dépend de AlbumSelector (T015) et des endpoints backend de US1/US2

### Within Each User Story

- Service methods avant endpoints (router)
- Endpoints admin avant endpoints publics
- Backend avant frontend (les composables appellent les endpoints)
- Composables avant intégration dans les pages

### Parallel Opportunities

- T008 + T009 : schemas Pydantic + types TypeScript (fichiers différents)
- T013 + T014 : composables events admin + public (fichiers différents)
- T020 + T021 : composables news admin + public (fichiers différents)
- T028 + T029 : endpoints reorder events + news (fichiers différents)
- T032 + T033 + T034 : vérifications indépendantes

---

## Parallel Example: Phase 2 (Foundational)

```bash
# Modèles (séquentiel dans le même fichier content.py):
T004 → T005 → T006 → T007

# En parallèle avec les modèles (fichiers différents):
T008: Schemas Pydantic (content.py schemas)
T009: Types TypeScript (media.ts)
```

## Parallel Example: User Story 1

```bash
# Backend séquentiel:
T010 (service) → T011 (admin router) → T012 (public router)

# Frontend en parallèle (après T010):
T013: composable admin events
T014: composable public events

# Frontend séquentiel (après T013+T014):
T015 (AlbumSelector) → T016 (intégration dans edit.vue)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1: Setup (migration SQL)
2. Phase 2: Foundational (modèles + schemas)
3. Phase 3: User Story 1 (événements)
4. **STOP et VALIDER**: Tester l'association d'albums à un événement via l'admin
5. Déployer si prêt

### Incremental Delivery

1. Setup + Foundational → Fondation prête
2. US1 → Événements fonctionnels → Valider
3. US2 → Actualités fonctionnelles → Valider
4. US3 → Onglets publics visibles → Valider (LIVRAISON COMPLÈTE P1)
5. US4 → Réordonnancement → Valider (P2)

---

## Notes

- [P] = fichiers différents, pas de dépendances
- [Story] mappe chaque tâche à sa user story
- Chaque user story est testable indépendamment via Swagger + navigateur
- Committer après chaque tâche ou groupe logique
- Les endpoints statiques (/{id}/albums) doivent être déclarés AVANT les routes dynamiques (/{id}, /{slug})
- Le composant AlbumSelector est créé dans US1 mais réutilisé dans US2 — US2 dépend de T015
