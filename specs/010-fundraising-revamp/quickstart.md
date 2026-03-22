# Quickstart: Refonte Page Levée de Fonds

**Branch**: `010-fundraising-revamp` | **Date**: 2026-03-22

## Prérequis

- Docker Compose lancé (`docker compose up -d` dans `usenghor_backend/`)
- Backend (`uvicorn app.main:app --reload` dans `usenghor_backend/`)
- Frontend (`pnpm dev` dans `usenghor_nuxt/`)

## Fichiers à supprimer (nettoyage 004)

### Backend
- [ ] `usenghor_backend/app/models/fundraising.py`
- [ ] `usenghor_backend/app/schemas/fundraising.py`
- [ ] `usenghor_backend/app/services/fundraising_service.py`
- [ ] `usenghor_backend/app/routers/admin/fundraisers.py`
- [ ] `usenghor_backend/app/routers/public/fundraisers.py`

### Frontend
- [ ] `usenghor_nuxt/app/pages/levees-de-fonds/index.vue`
- [ ] `usenghor_nuxt/app/pages/levees-de-fonds/[slug].vue`
- [ ] `usenghor_nuxt/app/pages/admin/contenus/levees-de-fonds/` (tout le dossier)
- [ ] `usenghor_nuxt/app/components/cards/CardFundraiser.vue`
- [ ] `usenghor_nuxt/app/composables/usePublicFundraisingApi.ts`
- [ ] `usenghor_nuxt/app/composables/useAdminFundraisingApi.ts`
- [ ] `usenghor_nuxt/app/types/fundraising.ts`
- [ ] `usenghor_nuxt/bank/mock-data/fundraising.ts`

### Base de données
- [ ] `usenghor_backend/documentation/modele_de_données/services/13_fundraising.sql`

## Fichiers à créer

### Migration SQL
- [ ] `usenghor_backend/documentation/modele_de_données/migrations/0XX_fundraising_revamp.sql`
  - ALTER `fundraiser_contributors` : ajouter `show_amount_publicly`
  - CREATE `fundraiser_interest_expressions`
  - CREATE `fundraiser_editorial_sections`
  - CREATE `fundraiser_editorial_items`
  - CREATE `fundraiser_media`
  - INSERT seed : 3 sections éditoriales

### Backend (recréation)
- [ ] `usenghor_backend/app/models/fundraising.py` — Modèles SQLAlchemy (tous)
- [ ] `usenghor_backend/app/schemas/fundraising.py` — Schémas Pydantic (tous)
- [ ] `usenghor_backend/app/services/fundraising_service.py` — Service CRUD + logique métier
- [ ] `usenghor_backend/app/routers/admin/fundraisers.py` — Routes admin (CRUD campagnes, contributeurs, médias, sections éditoriales, manifestations d'intérêt, export CSV)
- [ ] `usenghor_backend/app/routers/public/fundraisers.py` — Routes publiques (liste, détail, stats globales, contributeurs globaux, sections éditoriales, manifestation d'intérêt)
- [ ] `usenghor_backend/app/templates/email/interest_expression_confirmation.html` — Template email confirmation visiteur
- [ ] `usenghor_backend/app/templates/email/interest_expression_notification.html` — Template email notification admin

### Frontend (recréation)
- [ ] `usenghor_nuxt/app/types/fundraising.ts` — Types TypeScript
- [ ] `usenghor_nuxt/app/composables/usePublicFundraisingApi.ts` — API publique
- [ ] `usenghor_nuxt/app/composables/useAdminFundraisingApi.ts` — API admin
- [ ] `usenghor_nuxt/app/pages/levees-de-fonds/index.vue` — Page principale (hero, ancres, sections, campagnes, contributeurs, actualités)
- [ ] `usenghor_nuxt/app/pages/levees-de-fonds/[slug].vue` — Page campagne (présentation, progression, onglets contributeurs/médiathèque)
- [ ] `usenghor_nuxt/app/pages/admin/contenus/levees-de-fonds/index.vue` — Admin liste campagnes
- [ ] `usenghor_nuxt/app/pages/admin/contenus/levees-de-fonds/nouveau.vue` — Admin création
- [ ] `usenghor_nuxt/app/pages/admin/contenus/levees-de-fonds/[id]/edit.vue` — Admin édition
- [ ] `usenghor_nuxt/app/pages/admin/contenus/levees-de-fonds/interets.vue` — Admin manifestations d'intérêt
- [ ] `usenghor_nuxt/app/pages/admin/contenus/levees-de-fonds/sections-editoriales.vue` — Admin sections éditoriales
- [ ] `usenghor_nuxt/app/components/cards/CardFundraiser.vue` — Carte campagne
- [ ] `usenghor_nuxt/app/components/fundraising/` — Composants dédiés (HeroSection, AnchorNav, EditorialSection, ProgressBar, ContributorsList, MediaGallery, InterestForm)

### Traductions i18n
- [ ] `usenghor_nuxt/i18n/locales/fr/levees-de-fonds.json` — Mise à jour
- [ ] `usenghor_nuxt/i18n/locales/en/levees-de-fonds.json` — Mise à jour
- [ ] `usenghor_nuxt/i18n/locales/ar/levees-de-fonds.json` — Mise à jour

## Vérifications clés

- [ ] L'anti-spam (honeypot + challenge JS + délai) rejette les soumissions automatisées
- [ ] Le consentement `show_amount_publicly` masque/affiche correctement les montants
- [ ] La barre d'ancres sticky fonctionne et scrolle vers chaque section
- [ ] L'export CSV contient toutes les colonnes attendues
- [ ] Les 3 langues (FR, EN, AR/RTL) affichent correctement tous les contenus
- [ ] Les emails de confirmation et notification sont envoyés correctement
