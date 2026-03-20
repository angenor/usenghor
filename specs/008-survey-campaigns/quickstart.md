# Quickstart: 008-survey-campaigns

**Date**: 2026-03-20 | **Branch**: `008-survey-campaigns`

## Prérequis

```bash
# Backend en cours d'exécution
cd usenghor_backend
docker compose up -d
source .venv/bin/activate
uvicorn app.main:app --reload

# Frontend en cours d'exécution
cd usenghor_nuxt
pnpm dev
```

## Installation SurveyJS

```bash
cd usenghor_nuxt
pnpm add survey-vue3-ui
```

Le package `survey-core` est installé automatiquement comme dépendance.

## Fichiers à créer

### Backend

```
usenghor_backend/
├── app/
│   ├── models/
│   │   └── survey.py                    # SurveyCampaign, SurveyResponse, SurveyAssociation
│   ├── schemas/
│   │   └── survey.py                    # Create/Update/Read schemas Pydantic
│   ├── services/
│   │   └── survey_service.py            # Logique métier (CRUD, stats, export CSV)
│   ├── routers/
│   │   ├── admin/
│   │   │   └── surveys.py               # Endpoints admin (CRUD, lifecycle, stats)
│   │   └── public/
│   │       └── surveys.py               # Endpoints publics (formulaire, soumission)
│   └── templates/
│       └── email/
│           └── survey_confirmation.html  # Template email de confirmation
└── documentation/
    └── modele_de_données/
        ├── services/
        │   └── 13_survey.sql             # Tables + ENUM + permission
        └── migrations/
            └── 009_survey_campaigns.sql  # Migration
```

### Frontend

```
usenghor_nuxt/
├── app/
│   ├── components/
│   │   └── survey/
│   │       ├── SurveyRenderer.client.vue     # Rendu SurveyJS (public)
│   │       ├── QuestionBuilder.vue           # Constructeur de question (admin)
│   │       ├── QuestionList.vue              # Liste ordonnée des questions (admin)
│   │       ├── CampaignStatusBadge.vue       # Badge de statut
│   │       └── ResponseStats.vue             # Graphiques de statistiques
│   ├── composables/
│   │   ├── useAdminSurveyApi.ts              # API admin (CRUD, lifecycle, stats)
│   │   └── usePublicSurveyApi.ts             # API publique (formulaire, soumission)
│   ├── pages/
│   │   ├── admin/
│   │   │   └── campagnes/
│   │   │       ├── index.vue                 # Liste des campagnes
│   │   │       ├── nouveau.vue               # Créer une campagne
│   │   │       └── [id]/
│   │   │           ├── edit.vue              # Modifier une campagne
│   │   │           └── resultats.vue         # Tableau de bord des réponses
│   │   └── formulaires/
│   │       └── [slug].vue                    # Page publique du formulaire
│   └── assets/css/
│       └── survey-theme.css                  # Thème SurveyJS personnalisé (optionnel)
├── i18n/locales/
│   ├── fr/survey.json                        # Traductions FR
│   ├── en/survey.json                        # Traductions EN
│   └── ar/survey.json                        # Traductions AR
```

## Migration SQL

```bash
# Créer la migration
docker exec -i usenghor_postgres psql -U usenghor -d usenghor < \
  usenghor_backend/documentation/modele_de_données/migrations/009_survey_campaigns.sql
```

## Vérification rapide

1. Créer la migration SQL et l'appliquer
2. Ajouter le modèle SQLAlchemy + schemas Pydantic
3. Ajouter le service + routeurs backend
4. Vérifier les endpoints via Swagger (`/api/docs`)
5. Installer SurveyJS et créer le composant de rendu
6. Créer les pages admin (liste, créer, modifier, résultats)
7. Créer la page publique du formulaire
8. Tester le flux complet : créer → publier → remplir → voir les résultats
