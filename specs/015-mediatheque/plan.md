# Implementation Plan: Médiathèque publique générale

**Branch**: `015-mediatheque` | **Date**: 2026-03-28 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/015-mediatheque/spec.md`

## Summary

Page publique de médiathèque affichant les albums publiés sous forme de grille de cartes, avec recherche, filtres par type de média, et pages dédiées par album (`/mediatheque/{slug}`). Réutilise le système média/albums existant. Seule modification BDD : ajout d'un champ `slug` à la table `albums`.

## Technical Context

**Language/Version**: Python 3.14 (FastAPI backend), TypeScript (Nuxt 4 / Vue 3 frontend)
**Primary Dependencies**: FastAPI, SQLAlchemy (async), Pydantic v2, Nuxt 4, Vue 3, Tailwind CSS, @nuxtjs/i18n
**Storage**: PostgreSQL 16 (Docker: `usenghor_postgres` local, `usenghor_db` prod)
**Testing**: Manuel (navigateur)
**Target Platform**: Web (desktop, tablette, mobile)
**Project Type**: Web application (monorepo frontend + backend)
**Performance Goals**: Page listing < 2s, page album < 1s
**Constraints**: Responsive, RTL (arabe), dark mode, SEO-friendly URLs
**Scale/Scope**: ~50-100 albums, ~1000 médias

## Constitution Check

*GATE: Constitution non configurée (template par défaut). Aucun gate à vérifier.*

Statut : PASS (pas de violations)

## Project Structure

### Documentation (this feature)

```text
specs/015-mediatheque/
├── plan.md              # Ce fichier
├── spec.md              # Spécification
├── research.md          # Recherche Phase 0
├── data-model.md        # Modèle de données Phase 1
├── quickstart.md        # Guide de démarrage Phase 1
├── contracts/           # Contrats API Phase 1
│   └── public-albums-api.md
├── checklists/
│   └── requirements.md
└── tasks.md             # (Phase 2 — /speckit.tasks)
```

### Source Code (repository root)

```text
usenghor_backend/
├── documentation/modele_de_données/
│   ├── services/03_media.sql          # Schéma source (ajout slug)
│   └── migrations/016_add_album_slug.sql  # Migration
├── app/
│   ├── models/media.py                # Modèle Album (ajout slug)
│   ├── schemas/media.py               # Schémas Pydantic (ajout slug)
│   ├── services/media_service.py      # Service (génération slug)
│   └── routers/public/albums.py       # Endpoints publics (listing + by-slug)

usenghor_nuxt/
├── app/
│   ├── composables/usePublicAlbumsApi.ts  # Ajout listPublicAlbums, getAlbumBySlug
│   ├── pages/
│   │   └── mediatheque/
│   │       ├── index.vue              # Page listing (grille albums)
│   │       └── [slug].vue             # Page dédiée album
│   ├── components/
│   │   └── media/                     # Réutilisation MediaAlbumCard, MediaAlbumModal
│   └── types/api/media.ts             # Types (ajout slug, PublicAlbumListItem)
└── i18n/locales/
    ├── fr/                            # Traductions médiathèque
    ├── en/
    └── ar/
```

**Structure Decision**: Monorepo existant. Pas de nouveau dossier structurel — les fichiers s'intègrent dans l'arborescence existante. 2 nouvelles pages frontend, 2 nouveaux endpoints backend, 1 migration SQL.

## Complexity Tracking

Aucune violation de constitution à justifier.
