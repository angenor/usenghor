# Tasks: Médiathèque publique générale

**Input**: Design documents from `/specs/015-mediatheque/`
**Prerequisites**: plan.md, spec.md, data-model.md, contracts/public-albums-api.md, research.md

**Tests**: Non requis (testing manuel navigateur).

**Organization**: Tasks groupées par user story pour implémentation et test indépendants.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut s'exécuter en parallèle (fichiers différents, pas de dépendances)
- **[Story]**: User story concernée (US1, US2)

---

## Phase 1: Setup (Migration & Schéma)

**Purpose**: Ajout du champ `slug` à la table `albums` — prérequis pour toute la feature

- [x] T001 Créer la migration SQL `usenghor_backend/documentation/modele_de_données/migrations/016_add_album_slug.sql` : ajouter colonne `slug VARCHAR(300)`, générer les slugs des albums existants via slugification du titre, contrainte UNIQUE NOT NULL, index unique
- [x] T002 Mettre à jour le schéma source `usenghor_backend/documentation/modele_de_données/services/03_media.sql` : ajouter le champ `slug` à la définition de la table `albums`
- [x] T003 Appliquer la migration sur la BDD locale : `docker exec -i usenghor_postgres psql -U usenghor -d usenghor < usenghor_backend/documentation/modele_de_données/migrations/016_add_album_slug.sql`

---

## Phase 2: Foundational (Backend — Modèle, Schémas, Service)

**Purpose**: Intégrer le slug dans le backend existant — prérequis pour les endpoints publics

**⚠️ CRITICAL**: Pas d'endpoint ni de page frontend avant que cette phase soit complète

- [x] T004 Ajouter le champ `slug` au modèle SQLAlchemy `Album` dans `usenghor_backend/app/models/media.py` : colonne `slug = Column(String(300), unique=True, nullable=False, index=True)`
- [x] T005 Mettre à jour les schémas Pydantic dans `usenghor_backend/app/schemas/media.py` : ajouter `slug` à `AlbumBase`, `AlbumRead`, `AlbumWithMedia` ; ajouter `slug` optionnel à `AlbumCreate` et `AlbumUpdate` ; créer `PublicAlbumListItem` avec `media_count`, `media_types`, `cover_media`
- [x] T006 Mettre à jour le service `usenghor_backend/app/services/media_service.py` : ajouter fonction `generate_slug(title)` (slugification + dédoublonnage), appeler `generate_slug` dans `create_album()` si slug non fourni, ajouter méthode `get_published_albums_list(page, limit, search, media_type)` retournant les albums publiés non vides avec media_count/media_types/cover_media, ajouter méthode `get_album_by_slug(slug)` retournant un album publié avec ses médias

**Checkpoint**: Le backend gère les slugs et expose les méthodes de service nécessaires

---

## Phase 3: User Story 1 — Consulter la médiathèque publique (Priority: P1) 🎯 MVP

**Goal**: Page publique listant les albums publiés en grille avec recherche et filtres

**Independent Test**: Accéder à `http://localhost:3000/mediatheque`, voir les albums, filtrer, rechercher

### Implementation

- [x] T007 [P] [US1] Créer l'endpoint `GET /api/public/albums` dans `usenghor_backend/app/routers/public/albums.py` : listing paginé des albums publiés non vides, paramètres `page`, `limit`, `search`, `media_type`, réponse conforme au contrat `contracts/public-albums-api.md`
- [x] T008 [P] [US1] Créer l'endpoint `GET /api/public/albums/by-slug/{slug}` dans `usenghor_backend/app/routers/public/albums.py` : retourne album publié avec ses médias, 404 si non trouvé/brouillon/vide. Attention à déclarer cette route AVANT la route existante `/{album_id}` pour éviter le conflit de path parameter
- [x] T009 [P] [US1] Ajouter les types TypeScript dans `usenghor_nuxt/app/types/api/media.ts` : `PublicAlbumListItem` (avec `slug`, `media_count`, `media_types`, `cover_media`), `PublicAlbumListResponse` (paginé)
- [x] T010 [P] [US1] Étendre le composable `usenghor_nuxt/app/composables/usePublicAlbumsApi.ts` : ajouter `listPublicAlbums(params)` et `getAlbumBySlug(slug)` utilisant `useApiBase()` + `$fetch()`
- [x] T011 [P] [US1] Ajouter les traductions i18n pour la médiathèque dans `usenghor_nuxt/i18n/locales/fr/`, `en/`, `ar/` : clés pour titre de page, sous-titre, filtres (tous, images, vidéos, audio, documents), recherche, pagination, états vides
- [x] T012 [US1] Créer la page listing `usenghor_nuxt/app/pages/mediatheque/index.vue` : hero section (titre, sous-titre), barre de recherche, filtres par type de média (tous/image/vidéo/audio/document), grille responsive de `MediaAlbumCard`, pagination, état vide si aucun album, SEO meta tags via `useSeoMeta()`, support dark mode et RTL

**Checkpoint**: La page `/mediatheque` affiche les albums publiés avec recherche et filtres. MVP fonctionnel.

---

## Phase 4: User Story 2 — Naviguer dans un album depuis la médiathèque (Priority: P2)

**Goal**: Page dédiée par album avec grille de médias et visionneuse

**Independent Test**: Cliquer sur un album depuis `/mediatheque` mène à `/mediatheque/{slug}`, parcourir les médias, télécharger un fichier

### Implementation

- [x] T013 [US2] Créer la page dédiée album `usenghor_nuxt/app/pages/mediatheque/[slug].vue` : appel `getAlbumBySlug(slug)`, header avec titre/description de l'album, breadcrumb (Médiathèque > Nom album), grille de médias (images en miniatures, icônes pour vidéos/audio/documents), bouton téléchargement par média, visionneuse modale au clic sur un média (réutiliser la logique de `MediaAlbumModal.vue` : navigation précédent/suivant, lecture vidéo/audio, aperçu image plein écran), SEO meta tags dynamiques, support dark mode et RTL, gestion erreur 404 si album non trouvé

**Checkpoint**: Navigation complète médiathèque → album → média. Les deux user stories fonctionnent indépendamment.

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Finitions multi-pages

- [x] T014 [P] Ajouter le lien "Médiathèque" dans le menu de navigation principal du site (header/navbar) dans le composant de navigation existant
- [x] T015 [P] Vérifier le rendu RTL (arabe) sur les deux pages et corriger les éventuels problèmes de mise en page (padding, marges, direction du texte)
- [x] T016 Valider le parcours complet selon `quickstart.md` : migration, endpoints, pages listing et album, filtres, recherche, téléchargement

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: Pas de dépendances — commence immédiatement
- **Phase 2 (Foundational)**: Dépend de Phase 1 (migration appliquée) — BLOQUE les user stories
- **Phase 3 (US1)**: Dépend de Phase 2 — T007-T011 en parallèle, T012 après
- **Phase 4 (US2)**: Dépend de Phase 2 + T010 (composable) — peut commencer en parallèle de Phase 3 si T010 est fait
- **Phase 5 (Polish)**: Dépend de Phase 3 et Phase 4

### User Story Dependencies

- **US1 (P1)**: Indépendante après Phase 2
- **US2 (P2)**: Dépend du composable `usePublicAlbumsApi` (T010) mais pas de la page listing (T012)

### Within Each User Story

- Backend (endpoints) et frontend (types, composable, i18n) en parallèle
- Page frontend après composable et types

### Parallel Opportunities

Phase 3 offre le maximum de parallélisation :
```
Parallèle : T007 + T008 + T009 + T010 + T011 (5 fichiers différents)
Puis : T012 (dépend de T009, T010, T011)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1 : Migration SQL (T001-T003)
2. Phase 2 : Backend modèle/schémas/service (T004-T006)
3. Phase 3 : Endpoints + page listing (T007-T012)
4. **STOP et VALIDER** : Tester `/mediatheque` de bout en bout
5. Déployer/démontrer si prêt

### Livraison incrémentale

1. Setup + Foundational → Backend prêt
2. US1 → Page listing fonctionnelle → **MVP déployable**
3. US2 → Pages albums dédiées → **Expérience complète**
4. Polish → Navigation, RTL, validation finale

---

## Notes

- Aucune nouvelle table BDD — seul ajout d'une colonne `slug`
- Réutiliser `MediaAlbumCard.vue` tel quel sur la page listing
- Adapter la logique de `MediaAlbumModal.vue` pour la page dédiée album (contenu en pleine page, pas en modale)
- Route `by-slug/{slug}` DOIT être déclarée AVANT `/{album_id}` dans le router public pour éviter le conflit
- Commit après chaque tâche ou groupe logique
