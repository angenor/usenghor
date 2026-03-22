# Implementation Plan: Refonte Page Levée de Fonds

**Branch**: `010-fundraising-revamp` | **Date**: 2026-03-22 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/010-fundraising-revamp/spec.md`

## Summary

Refonte complète du module levée de fonds : suppression de l'implémentation 004 et recréation depuis zéro. Ajout de sections éditoriales structurées (icône + titre + description en grille/cards), manifestation d'intérêt avec anti-spam (honeypot + challenge JS + délai minimum), médiathèque par campagne, consentement d'affichage des montants contributeurs, interface admin dédiée avec export CSV, et page principale avec barre d'ancres sticky.

## Technical Context

**Language/Version**: Python 3.14 (FastAPI backend), TypeScript (Nuxt 4 / Vue 3 frontend)
**Primary Dependencies**: FastAPI, SQLAlchemy (async), Pydantic v2, aiosmtplib, Jinja2, Nuxt 4, Vue 3, Tailwind CSS, @nuxtjs/i18n
**Storage**: PostgreSQL 16 (Docker: `usenghor_postgres` local, `usenghor_db` prod)
**Testing**: Manuel (pas de framework de test automatisé en place)
**Target Platform**: Web (serveur VPS Linux, navigateurs modernes)
**Project Type**: Web application (monorepo frontend + backend)
**Performance Goals**: Pages < 3s, emails < 30s après soumission
**Constraints**: Trilingue FR/EN/AR (RTL), pas de dépendance CAPTCHA externe, double colonne HTML+MD pour contenu riche
**Scale/Scope**: ~15 pages/composants frontend, ~20 endpoints API, 5 nouvelles tables SQL, 2 templates email

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Constitution non définie (template vide) — aucune gate à vérifier. Procédure de planification libre.

## Project Structure

### Documentation (this feature)

```text
specs/010-fundraising-revamp/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0: Research decisions
├── data-model.md        # Phase 1: Data model
├── quickstart.md        # Phase 1: Setup & file checklist
├── contracts/
│   └── api-endpoints.md # Phase 1: API contracts
├── checklists/
│   └── requirements.md  # Spec quality checklist
└── tasks.md             # Phase 2 (à créer via /speckit.tasks)
```

### Source Code (repository root)

```text
usenghor_backend/
├── app/
│   ├── models/fundraising.py           # SQLAlchemy models (all entities)
│   ├── schemas/fundraising.py          # Pydantic schemas (all I/O)
│   ├── services/fundraising_service.py # Business logic, email triggers
│   ├── routers/
│   │   ├── admin/fundraisers.py        # Admin CRUD, export CSV, interest mgmt
│   │   └── public/fundraisers.py       # Public list, detail, stats, interest form
│   └── templates/email/
│       ├── interest_expression_confirmation.html
│       └── interest_expression_notification.html
├── documentation/modele_de_données/
│   ├── services/13_fundraising.sql     # Schema complet (rewritten)
│   └── migrations/0XX_fundraising_revamp.sql

usenghor_nuxt/
├── app/
│   ├── types/fundraising.ts
│   ├── composables/
│   │   ├── usePublicFundraisingApi.ts
│   │   └── useAdminFundraisingApi.ts
│   ├── pages/
│   │   ├── levees-de-fonds/
│   │   │   ├── index.vue               # Page principale (hero, ancres, sections)
│   │   │   └── [slug].vue              # Page campagne (detail, onglets)
│   │   └── admin/contenus/levees-de-fonds/
│   │       ├── index.vue               # Admin liste campagnes
│   │       ├── nouveau.vue             # Admin création
│   │       ├── [id]/edit.vue           # Admin édition
│   │       ├── interets.vue            # Admin manifestations d'intérêt
│   │       └── sections-editoriales.vue # Admin sections éditoriales
│   └── components/
│       ├── cards/CardFundraiser.vue
│       └── fundraising/
│           ├── HeroSection.vue
│           ├── AnchorNav.vue
│           ├── EditorialSection.vue
│           ├── ProgressBar.vue
│           ├── ContributorsList.vue
│           ├── MediaGallery.vue
│           └── InterestForm.vue
├── bank/mock-data/fundraising.ts
└── i18n/locales/{fr,en,ar}/levees-de-fonds.json
```

**Structure Decision**: Web application monorepo existant (backend/ + frontend/). Toute l'implémentation fundraising est contenue dans les fichiers listés ci-dessus. Suppression totale de 004 puis recréation.

## Complexity Tracking

Aucune violation de constitution à justifier (constitution non définie).
