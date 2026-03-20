# Implementation Plan: Campagnes de sondages et formulaires

**Branch**: `008-survey-campaigns` | **Date**: 2026-03-20 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/008-survey-campaigns/spec.md`

## Summary

Système de campagnes de sondages/formulaires intégré remplaçant Google Forms. Le backend FastAPI gère le CRUD des campagnes, le stockage des réponses en JSONB, les statistiques agrégées et l'export CSV. Le frontend Nuxt utilise une interface admin sur mesure pour construire les formulaires (génération de JSON SurveyJS) et SurveyJS Form Library (MIT) pour le rendu public. Permissions basées sur `survey.manage`, visibilité isolée par gestionnaire (super_admin voit tout). Anti-spam par rate limiting + honeypot. Email de confirmation optionnel via l'infrastructure SMTP existante.

## Technical Context

**Language/Version**: Python 3.14 (backend FastAPI) + TypeScript (frontend Nuxt 4 / Vue 3)
**Primary Dependencies**: FastAPI, SQLAlchemy (async), Pydantic v2, SurveyJS Form Library (`survey-vue3-ui`), aiosmtplib, Jinja2
**Storage**: PostgreSQL 16 (Docker: `usenghor_postgres` local, `usenghor_db` prod) — JSONB pour survey_json et response_data
**Testing**: Tests manuels via Swagger `/api/docs` + navigation frontend
**Target Platform**: Web (Linux VPS en production, macOS en dev)
**Project Type**: Web application (monorepo frontend + backend)
**Performance Goals**: Stats de 500 réponses < 3s, export CSV 1000 réponses < 10s
**Constraints**: Trilingue FR/EN/AR avec RTL, composant SurveyJS client-only (pas de SSR), formulaires anonymes
**Scale/Scope**: ~20 fichiers à créer/modifier, 3 nouvelles tables, 4 pages admin, 1 page publique

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Constitution non configurée (template par défaut). Aucun gate bloquant.

**Post-Phase 1 re-check** : Le design respecte les patterns existants du projet (services, routers admin/public, PermissionChecker, pagination, composables, .client.vue). Aucune violation.

## Project Structure

### Documentation (this feature)

```text
specs/008-survey-campaigns/
├── plan.md              # Ce fichier
├── spec.md              # Spécification fonctionnelle
├── research.md          # Phase 0 — recherches et décisions techniques
├── data-model.md        # Phase 1 — modèle de données (3 tables + ENUM + permission)
├── quickstart.md        # Phase 1 — guide de démarrage rapide
├── contracts/
│   └── api-endpoints.md # Phase 1 — contrats API (admin + public)
├── checklists/
│   └── requirements.md  # Checklist de validation de la spec
└── tasks.md             # Phase 2 — tâches d'implémentation (via /speckit.tasks)
```

### Source Code (repository root)

```text
usenghor_backend/
├── app/
│   ├── models/
│   │   ├── base.py              # (existant) Ajout de SurveyCampaignStatus enum
│   │   └── survey.py            # (nouveau) SurveyCampaign, SurveyResponse, SurveyAssociation
│   ├── schemas/
│   │   └── survey.py            # (nouveau) Pydantic schemas (Create/Update/Read/Stats)
│   ├── services/
│   │   └── survey_service.py    # (nouveau) Logique métier CRUD, stats, export CSV
│   ├── routers/
│   │   ├── admin/
│   │   │   ├── __init__.py      # (modifier) Enregistrer le routeur surveys
│   │   │   └── surveys.py       # (nouveau) Endpoints admin
│   │   └── public/
│   │       ├── __init__.py      # (modifier) Enregistrer le routeur surveys
│   │       └── surveys.py       # (nouveau) Endpoints publics
│   └── templates/
│       └── email/
│           └── survey_confirmation.html  # (nouveau) Template email confirmation
└── documentation/
    └── modele_de_données/
        ├── services/
        │   ├── main.sql          # (modifier) Ajouter \i 13_survey.sql
        │   └── 13_survey.sql     # (nouveau) Tables + ENUM + permission
        └── migrations/
            └── 009_survey_campaigns.sql  # (nouveau) Migration

usenghor_nuxt/
├── app/
│   ├── components/
│   │   └── survey/
│   │       ├── SurveyRenderer.client.vue   # (nouveau) Rendu SurveyJS public
│   │       ├── QuestionBuilder.vue         # (nouveau) Config d'une question
│   │       ├── QuestionList.vue            # (nouveau) Liste ordonnée + drag
│   │       ├── CampaignStatusBadge.vue     # (nouveau) Badge statut
│   │       └── ResponseStats.vue           # (nouveau) Graphiques stats
│   ├── composables/
│   │   ├── useAdminSurveyApi.ts            # (nouveau) API admin
│   │   └── usePublicSurveyApi.ts           # (nouveau) API publique
│   ├── pages/
│   │   ├── admin/
│   │   │   └── campagnes/
│   │   │       ├── index.vue               # (nouveau) Liste campagnes
│   │   │       ├── nouveau.vue             # (nouveau) Créer campagne
│   │   │       └── [id]/
│   │   │           ├── edit.vue            # (nouveau) Modifier campagne
│   │   │           └── resultats.vue       # (nouveau) Résultats & stats
│   │   └── formulaires/
│   │       └── [slug].vue                  # (nouveau) Page publique formulaire
│   └── assets/css/
│       └── survey-theme.css                # (nouveau) Thème SurveyJS custom
├── i18n/locales/
│   ├── fr/survey.json                      # (nouveau) Traductions FR
│   ├── en/survey.json                      # (nouveau) Traductions EN
│   └── ar/survey.json                      # (nouveau) Traductions AR
└── package.json                            # (modifier) Ajouter survey-vue3-ui
```

**Structure Decision** : Suit le pattern existant du monorepo (usenghor_backend/ + usenghor_nuxt/). Les fichiers survey sont organisés par couche (models, schemas, services, routers côté backend ; components/survey, composables, pages côté frontend), cohérent avec les modules existants (news, media, projects, etc.).

## Complexity Tracking

Aucune violation de constitution à justifier.
