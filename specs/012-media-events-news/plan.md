# Implementation Plan: Associer une médiathèque aux événements et actualités

**Branch**: `012-media-events-news` | **Date**: 2026-03-24 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/012-media-events-news/spec.md`

## Summary

Permettre aux administrateurs d'associer des albums de la médiathèque existante aux événements et actualités (relation N:N), et afficher ces albums dans un onglet "Médiathèque" sur les pages de détail publiques. L'implémentation s'appuie sur la table `event_media_library` existante (enrichie avec `display_order`), une nouvelle table `news_media_library`, et le pattern d'endpoints dédié déjà utilisé pour Album→Media.

## Technical Context

**Language/Version**: Python 3.14 (backend FastAPI), TypeScript (frontend Nuxt 4 / Vue 3)
**Primary Dependencies**: FastAPI, SQLAlchemy (async), Pydantic v2, Nuxt 4, Vue 3, Tailwind CSS
**Storage**: PostgreSQL 16 (Docker: `usenghor_postgres` local, `usenghor_db` prod)
**Testing**: Tests manuels via Swagger + navigateur
**Target Platform**: Web (serveur Linux, navigateurs modernes)
**Project Type**: Web application (monorepo frontend + backend)
**Performance Goals**: Onglet médiathèque < 2s avec 5 albums × 50 médias
**Constraints**: Trilingue (fr/en/ar), dark mode, responsive
**Scale/Scope**: ~5 albums par contenu en moyenne, ~50 médias par album max

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Constitution non configurée (template par défaut). Aucun gate bloquant.

**Post-Phase 1 re-check**: Design conforme aux patterns existants du projet (tables de liaison dédiées, endpoints CRUD dédiés, composants réutilisables).

## Project Structure

### Documentation (this feature)

```text
specs/012-media-events-news/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0: research findings
├── data-model.md        # Phase 1: data model changes
├── quickstart.md        # Phase 1: dev setup guide
├── contracts/           # Phase 1: API contracts
│   ├── admin-events-albums.md
│   ├── admin-news-albums.md
│   └── public-content-albums.md
├── checklists/
│   └── requirements.md  # Spec quality checklist
└── tasks.md             # Phase 2 output (via /speckit.tasks)
```

### Source Code (repository root)

```text
usenghor_backend/
├── app/
│   ├── models/content.py              # + NewsMediaLibrary model, modifier EventMediaLibrary
│   ├── schemas/content.py             # + schemas albums pour events/news
│   ├── services/content_service.py    # + méthodes add/remove/list/reorder albums
│   ├── routers/
│   │   ├── admin/events.py            # + endpoints /{id}/albums
│   │   ├── admin/news.py              # + endpoints /{id}/albums
│   │   ├── public/events.py           # + GET /{slug}/albums
│   │   └── public/news.py             # + GET /{slug}/albums
│   └── ...
└── documentation/
    └── modele_de_données/
        ├── migrations/012_media_events_news.sql   # Migration SQL
        └── services/09_content.sql                # Schéma source mis à jour

usenghor_nuxt/
├── app/
│   ├── components/
│   │   ├── admin/AlbumSelector.vue                # NOUVEAU: sélecteur multi-albums
│   │   └── media/MediaLibraryTab.vue              # NOUVEAU: onglet médiathèque public
│   ├── composables/
│   │   ├── useEventsApi.ts                        # + méthodes albums
│   │   ├── useAdminNewsApi.ts                     # + méthodes albums
│   │   ├── usePublicEventsApi.ts                  # + getEventAlbums()
│   │   └── usePublicNewsApi.ts                    # + getNewsAlbums()
│   ├── pages/
│   │   ├── actualites/evenements/[id].vue         # + onglets + médiathèque
│   │   ├── actualites/[slug].vue                  # + onglets + médiathèque
│   │   ├── admin/contenus/evenements/[id]/edit.vue # remplacer champ texte par AlbumSelector
│   │   └── admin/contenus/actualites/[id]/edit.vue # + section albums avec AlbumSelector
│   └── types/api/
│       └── media.ts                               # + types pour albums associés
└── ...
```

**Structure Decision**: Monorepo existant (backend FastAPI + frontend Nuxt 4). Tous les changements s'intègrent dans les fichiers et patterns existants. Deux nouveaux composants Vue, une nouvelle table SQL, et des extensions aux routers/services/schemas existants.

## Complexity Tracking

Aucune violation de constitution à justifier. Le design suit les patterns établis :
- Tables de liaison dédiées (comme `event_partners`, `news_tags`, `album_media`)
- Endpoints REST dédiés pour les associations N:N (comme `albums/{id}/media`)
- Composants Vue réutilisables (comme `MediaAlbumCard`, `MediaAlbumModal`)

## Key Design Decisions

### 1. Endpoints dédiés vs payload intégré
Les associations albums sont gérées via des **endpoints REST dédiés** (`POST /{id}/albums`, `DELETE /{id}/albums/{album_id}`, `PUT /{id}/albums/reorder`) plutôt que via le payload de create/update. Cela suit le pattern `albums/{id}/media` existant et permet une UX plus réactive (ajout/retrait sans resoumettre tout le formulaire).

### 2. Onglets sur les pages publiques
Les pages de détail publiques (événements et actualités) passent d'un **layout linéaire à un système d'onglets** : "Détails" (contenu existant) + "Médiathèque" (conditionnel). L'onglet "Médiathèque" n'apparaît que si au moins un album publié est associé.

### 3. Composants existants réutilisés
- `MediaAlbumCard.vue` : affichage des albums en cartes avec effet empilé
- `MediaAlbumModal.vue` : lightbox plein écran avec navigation clavier
- `useAlbumsApi()` : composable admin pour la gestion des albums
- `usePublicAlbumsApi()` : composable public pour la récupération des albums

### 4. AlbumSelector.vue (nouveau composant admin)
Composant réutilisable de sélection multi-albums avec recherche et aperçu visuel. Utilisé dans les formulaires d'édition des événements et actualités.

### 5. MediaLibraryTab.vue (nouveau composant public)
Composant réutilisable affichant les albums d'un contenu, organisés par album avec grille de miniatures. Utilise `MediaAlbumCard` et `MediaAlbumModal` existants.
