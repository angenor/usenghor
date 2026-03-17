# Implementation Plan: Page Levée de Fonds

**Branch**: `004-fundraising-page` | **Date**: 2026-03-17 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/004-fundraising-page/spec.md`

## Summary

Créer un module complet « Levée de fonds » pour le site de l'Université Senghor. Le module comprend : des tables PostgreSQL (fundraisers, fundraiser_contributors, fundraiser_news), un backend FastAPI avec endpoints admin (CRUD) et publics (lecture), et un frontend Nuxt 4 avec pages publiques (liste + détail à 3 onglets) et pages admin (CRUD + gestion contributeurs + association actualités). Le contenu enrichi suit le pattern dual HTML/Markdown existant. La somme totale est calculée dynamiquement depuis les contributions.

## Technical Context

**Language/Version**: Python 3.14 (backend), TypeScript (frontend Nuxt 4 / Vue 3)
**Primary Dependencies**: FastAPI, SQLAlchemy (async), Pydantic v2, Nuxt 4, Vue 3, Tailwind CSS, TOAST UI Editor
**Storage**: PostgreSQL 16 (Docker: `usenghor_postgres` local, `usenghor_db` prod)
**Testing**: Manuel (pas de framework de test automatisé en place)
**Target Platform**: Web (serveur Linux, navigateurs modernes)
**Project Type**: Web application (monorepo frontend + backend)
**Performance Goals**: Standard web app (pages < 3s, navigation onglets instantanée)
**Constraints**: Trilingue (FR/EN/AR avec RTL), rich text dual-column (HTML + Markdown)
**Scale/Scope**: ~10 levées de fonds, ~100 contributeurs, ~50 actualités associées

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Constitution non configurée (template par défaut). Aucun gate bloquant.

**Post-Phase 1 re-check**: Le design suit fidèlement les patterns existants du projet (modèles, services, routers, schemas, composables, pages). Pas de nouvelle dépendance, pas de pattern architectural nouveau. Conforme.

## Project Structure

### Documentation (this feature)

```text
specs/004-fundraising-page/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0: Research findings
├── data-model.md        # Phase 1: Entity definitions
├── quickstart.md        # Phase 1: Setup guide
├── contracts/           # Phase 1: API contracts
│   └── api-endpoints.md
├── checklists/
│   └── requirements.md  # Spec quality checklist
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
usenghor_backend/
├── app/
│   ├── models/
│   │   └── fundraising.py          # Fundraiser, FundraiserContributor, FundraiserNews
│   ├── schemas/
│   │   └── fundraising.py          # Pydantic schemas (Base/Create/Update/Read/Public)
│   ├── services/
│   │   └── fundraising_service.py  # FundraisingService (CRUD + agrégations)
│   └── routers/
│       ├── admin/
│       │   └── fundraisers.py      # Admin CRUD endpoints
│       └── public/
│           └── fundraisers.py      # Public read endpoints
└── documentation/
    └── modele_de_données/
        ├── services/
        │   └── 13_fundraising.sql  # Table definitions + ENUMs
        └── migrations/
            └── 00X_fundraisers.sql # Migration script

usenghor_nuxt/
├── app/
│   ├── pages/
│   │   ├── levees-de-fonds/
│   │   │   ├── index.vue           # Page liste publique
│   │   │   └── [slug].vue          # Page détail (hero + 3 onglets)
│   │   └── admin/
│   │       └── contenus/
│   │           └── levees-de-fonds/
│   │               ├── index.vue   # Admin liste
│   │               ├── nouveau.vue # Admin création
│   │               └── [id]/
│   │                   └── edit.vue # Admin édition
│   ├── components/
│   │   └── cards/
│   │       └── CardFundraiser.vue  # Carte aperçu levée de fonds
│   ├── composables/
│   │   ├── usePublicFundraisingApi.ts  # API publique
│   │   └── useAdminFundraisingApi.ts   # API admin
│   └── types/
│       └── fundraising.ts          # Types TypeScript
├── bank/
│   └── mock-data/
│       └── fundraising.ts          # Données de développement
└── i18n/
    └── locales/
        ├── fr/levees-de-fonds.json
        ├── en/levees-de-fonds.json
        └── ar/levees-de-fonds.json
```

**Structure Decision**: Web application (Option 2) — suit la structure monorepo existante `usenghor_backend/` + `usenghor_nuxt/`. Tous les nouveaux fichiers sont des ajouts dans les répertoires existants, suivant les conventions de nommage et d'organisation déjà en place.

## Complexity Tracking

> Aucune violation — le design suit les patterns existants sans complexité additionnelle.
