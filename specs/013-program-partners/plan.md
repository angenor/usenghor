# Implementation Plan: Association Partenaires-Formations

**Branch**: `013-program-partners` | **Date**: 2026-03-25 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/013-program-partners/spec.md`

## Summary

Permettre l'association de partenaires existants à des formations dans l'interface admin (édition et création), puis afficher les logos et noms de ces partenaires sur la page publique de la formation. L'infrastructure backend (table de jonction, endpoints admin, service) existe déjà - le travail porte sur l'ajout d'un endpoint public enrichi, l'UI admin de sélection, et l'affichage public.

## Technical Context

**Language/Version**: Python 3.14 (backend FastAPI), TypeScript (frontend Nuxt 4 / Vue 3)
**Primary Dependencies**: FastAPI, SQLAlchemy (async), Pydantic v2, Nuxt 4, Vue 3, Tailwind CSS
**Storage**: PostgreSQL 16 (Docker: `usenghor_postgres` local, `usenghor_db` prod)
**Testing**: Manuel (pas de framework de test automatisé en place)
**Target Platform**: Web (desktop + mobile responsive)
**Project Type**: Web application (monorepo frontend + backend)
**Performance Goals**: Affichage instantané des partenaires sur la page publique
**Constraints**: Trilingue (fr/en/ar RTL), dark mode, responsive
**Scale/Scope**: ~50 partenaires max, ~30 formations

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Constitution non configurée (template vide). Aucun gate à vérifier. Procédure standard appliquée.

## Project Structure

### Documentation (this feature)

```text
specs/013-program-partners/
├── plan.md              # Ce fichier
├── spec.md              # Spécification
├── research.md          # Phase 0 - Recherche
├── data-model.md        # Phase 1 - Modèle de données
├── quickstart.md        # Phase 1 - Guide de démarrage
├── contracts/           # Phase 1 - Contrats API
│   └── api.md           # Endpoints existants + nouveau
└── checklists/
    └── requirements.md  # Checklist qualité spec
```

### Source Code (repository root)

```text
usenghor_backend/
├── app/
│   ├── models/academic.py              # ProgramPartner (existant, pas de modif)
│   ├── schemas/academic.py             # + ProgramPartnerPublic (nouveau schema)
│   ├── services/academic_service.py    # + get_program_partners_enriched() (nouvelle méthode)
│   └── routers/
│       ├── admin/programs.py           # Endpoints admin (existants, pas de modif)
│       └── public/programs.py          # + GET /{slug}/partners (nouvel endpoint)

usenghor_nuxt/
├── app/
│   ├── composables/
│   │   ├── useProgramsApi.ts           # + méthodes partner admin
│   │   └── usePublicProgramsApi.ts     # + getProgramPartners()
│   ├── components/
│   │   └── formations/
│   │       └── ProgramPartners.vue     # Nouveau composant affichage public
│   └── pages/
│       ├── admin/formations/programmes/
│       │   ├── [id]/edit.vue           # + section partenaires
│       │   └── nouveau.vue             # + section partenaires
│       └── formations/[type]/[slug].vue # + affichage partenaires
├── i18n/locales/
│   ├── fr/                             # + clés traduction partenaires
│   ├── en/                             # + clés traduction partenaires
│   └── ar/                             # + clés traduction partenaires
```

**Structure Decision**: Web application monorepo existante. Modifications ciblées dans les couches existantes, un seul nouveau composant (`ProgramPartners.vue`).

## Complexity Tracking

Aucune violation de constitution à justifier (constitution non configurée).

## Implementation Strategy

### Couche 1 : Backend (endpoint public enrichi)
1. Ajouter `ProgramPartnerPublic` schema dans `schemas/academic.py`
2. Ajouter méthode `get_program_partners_enriched(slug)` dans `academic_service.py` qui joint `program_partners` + `partners` (filtre `active=true`)
3. Ajouter endpoint `GET /api/public/programs/{slug}/partners` dans `routers/public/programs.py`

### Couche 2 : Frontend composables
4. Ajouter méthodes admin dans `useProgramsApi.ts` (listProgramPartners, addPartnerToProgram, removePartnerFromProgram)
5. Ajouter `getProgramPartners(slug)` dans `usePublicProgramsApi.ts`

### Couche 3 : Frontend admin (UI de sélection)
6. Ajouter section "Partenaires" dans la page d'édition `[id]/edit.vue` avec :
   - Liste des partenaires associés (chargés via watch sur program)
   - Dropdown de sélection avec recherche (filtrant les non-associés)
   - Bouton de suppression par partenaire
   - Pattern cohérent avec skills/career opportunities
7. Répliquer dans `nouveau.vue` (sauvegarde après création du programme)

### Couche 4 : Frontend public (affichage)
8. Créer composant `ProgramPartners.vue` (grille responsive de logos + noms, inspiré de `ProjetPartenaires.vue`)
9. Intégrer dans `formations/[type]/[slug].vue` après la section débouchés
10. Ajouter les clés i18n (fr/en/ar)
