# Implementation Plan: Ajouter le type de formation CLOM

**Branch**: `011-add-cloms-formation` | **Date**: 2026-03-24 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/011-add-cloms-formation/spec.md`

## Summary

Ajouter `clom` comme 5ème valeur de l'énumération `program_type` existante (aux côtés de `master`, `doctorate`, `university_diploma`, `certificate`). L'implémentation traverse toutes les couches : migration PostgreSQL, modèle Python, types TypeScript, composables Vue, routage frontend, et traductions i18n trilingues. Aucune nouvelle table ni nouveau endpoint n'est requis — il s'agit uniquement d'étendre les structures existantes.

## Technical Context

**Language/Version** : Python 3.14 (FastAPI backend), TypeScript (Nuxt 4 / Vue 3 frontend)
**Primary Dependencies** : FastAPI, SQLAlchemy (async), Pydantic v2, Nuxt 4, Vue 3, Tailwind CSS, @nuxtjs/i18n
**Storage** : PostgreSQL 16 (Docker : `usenghor_postgres` local, `usenghor_db` prod)
**Testing** : Tests manuels (pas de framework de tests automatisés configuré)
**Target Platform** : Web (SSR Nuxt + API FastAPI)
**Project Type** : Web application (monorepo frontend + backend)
**Performance Goals** : Standard web app — aucun impact performance (ajout d'une valeur ENUM)
**Constraints** : Migration ENUM PostgreSQL sans downtime, compatibilité trilingue FR/EN/AR (RTL)
**Scale/Scope** : ~11 fichiers à modifier, 0 nouveau fichier source (1 migration SQL)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Constitution non configurée (template par défaut). Aucune gate spécifique à vérifier. Passage automatique.

**Post-Phase 1 re-check** : Conforme — aucune nouvelle abstraction, aucun nouveau service, modification minimale et ciblée.

## Project Structure

### Documentation (this feature)

```text
specs/011-add-cloms-formation/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── api-endpoints.md
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (fichiers impactés)

```text
usenghor_backend/
├── documentation/modele_de_données/
│   ├── services/07_academic.sql                    # ENUM program_type : ajouter 'clom'
│   └── migrations/029_add_clom_program_type.sql    # NOUVEAU : migration ALTER TYPE
├── app/
│   └── models/academic.py                          # ProgramType enum : ajouter CLOM
│   # schemas/academic.py → auto-propagé via import
│   # routers/ → auto-propagé via ProgramType
│   # services/ → auto-propagé via filtrage générique

usenghor_nuxt/
├── app/
│   ├── types/api/programs.ts                       # ProgramType union : ajouter 'clom'
│   ├── composables/
│   │   ├── useProgramsApi.ts                       # Labels + colors admin
│   │   └── usePublicProgramsApi.ts                 # Slug mappings + colors public
│   └── pages/formations/[type]/index.vue           # validTypes : ajouter 'cloms'
└── i18n/locales/
    ├── fr/formations.json                          # Traductions françaises
    ├── en/formations.json                          # Traductions anglaises
    └── ar/formations.json                          # Traductions arabes
```

**Structure Decision** : Application web existante (monorepo). Aucun nouveau fichier source — uniquement modification de fichiers existants + 1 migration SQL.

## Fichiers auto-propagés (aucune modification directe)

Ces fichiers utilisent `ProgramType` via import et fonctionneront automatiquement :

- `usenghor_backend/app/schemas/academic.py` — Pydantic schemas importent ProgramType
- `usenghor_backend/app/routers/admin/programs.py` — routes admin utilisent ProgramType en Query param
- `usenghor_backend/app/routers/public/programs.py` — routes publiques utilisent ProgramType
- `usenghor_backend/app/services/academic_service.py` — filtrage générique `Program.type == program_type`
- `usenghor_nuxt/app/pages/admin/formations/programmes/nouveau.vue` — utilise programTypeLabels importé
- `usenghor_nuxt/app/pages/admin/formations/programmes/index.vue` — utilise programTypeLabels/Colors importés

## Complexity Tracking

Aucune violation de constitution. Feature à complexité minimale (extension d'ENUM existant).
