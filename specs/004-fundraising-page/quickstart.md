# Quickstart: Page Levée de Fonds

**Feature Branch**: `004-fundraising-page`
**Date**: 2026-03-17

## Prérequis

- Docker Desktop (PostgreSQL via docker-compose)
- Python 3.14 avec virtualenv
- Node.js + pnpm
- Branche `004-fundraising-page` checkoutée

## Démarrage rapide

### 1. Base de données

```bash
cd usenghor_backend
docker compose up -d
# Appliquer la migration fundraiser
docker exec -i usenghor_postgres psql -U usenghor -d usenghor < documentation/modele_de_données/migrations/00X_fundraisers.sql
```

### 2. Backend

```bash
cd usenghor_backend
source .venv/bin/activate
uvicorn app.main:app --reload
# API: http://localhost:8000
# Swagger: http://localhost:8000/api/docs
```

### 3. Frontend

```bash
cd usenghor_nuxt
pnpm install
pnpm dev
# App: http://localhost:3000
```

## Vérification

1. **API publique** : `GET http://localhost:8000/api/public/fundraisers` → liste vide (200)
2. **Page publique** : `http://localhost:3000/levees-de-fonds` → page liste avec état vide
3. **Admin** : Se connecter → Contenus → Levées de fonds → Créer une campagne
4. **Détail** : Accéder à la campagne créée → Vérifier les 3 onglets

## Fichiers clés à créer

### Backend
- `app/models/fundraising.py` — Modèles SQLAlchemy
- `app/schemas/fundraising.py` — Schemas Pydantic
- `app/services/fundraising_service.py` — Service métier
- `app/routers/admin/fundraisers.py` — Routes admin
- `app/routers/public/fundraisers.py` — Routes publiques
- `documentation/modele_de_données/migrations/00X_fundraisers.sql` — Migration SQL

### Frontend
- `app/pages/levees-de-fonds/index.vue` — Page liste publique
- `app/pages/levees-de-fonds/[slug].vue` — Page détail publique
- `app/pages/admin/contenus/levees-de-fonds/index.vue` — Admin liste
- `app/pages/admin/contenus/levees-de-fonds/nouveau.vue` — Admin création
- `app/pages/admin/contenus/levees-de-fonds/[id]/edit.vue` — Admin édition
- `app/composables/usePublicFundraisingApi.ts` — API publique
- `app/composables/useAdminFundraisingApi.ts` — API admin
- `app/components/cards/CardFundraiser.vue` — Carte levée de fonds
- `app/types/fundraising.ts` — Types TypeScript
- `i18n/locales/fr/levees-de-fonds.json` — Traductions FR
- `i18n/locales/en/levees-de-fonds.json` — Traductions EN
- `i18n/locales/ar/levees-de-fonds.json` — Traductions AR
