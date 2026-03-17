# Tasks: Page Levée de Fonds

**Input**: Design documents from `/specs/004-fundraising-page/`
**Prerequisites**: plan.md, spec.md, data-model.md, contracts/api-endpoints.md, research.md

**Tests**: Non demandés — pas de tâches de test automatisé.

**Organization**: Tasks groupées par user story pour permettre une implémentation et des tests indépendants.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut être exécuté en parallèle (fichiers différents, pas de dépendances)
- **[Story]**: User story associée (US1–US7)
- Chemins exacts inclus dans les descriptions

---

## Phase 1: Setup (Infrastructure partagée)

**Purpose**: Schéma SQL, migration, ENUMs

- [x] T001 Créer le schéma SQL des tables fundraisers, fundraiser_contributors, fundraiser_news et des ENUMs fundraiser_status, contributor_category dans `usenghor_backend/documentation/modele_de_données/services/13_fundraising.sql`
- [x] T002 Ajouter l'inclusion `\i 13_fundraising.sql` dans `usenghor_backend/documentation/modele_de_données/services/main.sql`
- [x] T003 Créer le script de migration dans `usenghor_backend/documentation/modele_de_données/migrations/` (numéro séquentiel suivant) avec CREATE TYPE + CREATE TABLE
- [x] T004 Appliquer la migration sur la base locale : `docker exec -i usenghor_postgres psql -U usenghor -d usenghor < migration.sql`

---

## Phase 2: Foundational (Prérequis bloquants)

**Purpose**: Backend models, schemas, service, registration des routers — DOIT être complet avant toute user story

**⚠️ CRITICAL**: Aucune tâche de user story ne peut commencer avant la fin de cette phase

- [x] T005 [P] Créer les modèles SQLAlchemy Fundraiser, FundraiserContributor, FundraiserNews (avec UUIDMixin, TimestampMixin, ENUMs, relations) dans `usenghor_backend/app/models/fundraising.py`
- [x] T006 [P] Créer les schemas Pydantic (FundraiserBase, FundraiserCreate, FundraiserUpdate, FundraiserRead, FundraiserPublic, FundraiserPublicDetail, ContributorBase, ContributorCreate, ContributorUpdate, ContributorRead, FundraiserNewsCreate) dans `usenghor_backend/app/schemas/fundraising.py`
- [x] T007 [P] Créer les types TypeScript (FundraiserStatus, ContributorCategory, FundraiserDisplay, FundraiserDetail, ContributorDisplay, FundraiserNewsDisplay, payloads) dans `usenghor_nuxt/app/types/fundraising.ts`
- [x] T008 [P] Créer les fichiers de traduction i18n FR/EN/AR dans `usenghor_nuxt/i18n/locales/fr/levees-de-fonds.json`, `usenghor_nuxt/i18n/locales/en/levees-de-fonds.json`, `usenghor_nuxt/i18n/locales/ar/levees-de-fonds.json`
- [x] T009 Créer le FundraisingService avec les méthodes CRUD pour fundraisers, contributors et news associations (incluant le calcul dynamique de total_raised via SUM et progress_percentage) dans `usenghor_backend/app/services/fundraising_service.py`
- [x] T010 Créer le router public fundraisers (GET list, GET detail par slug) dans `usenghor_backend/app/routers/public/fundraisers.py`
- [x] T011 Créer le router admin fundraisers (CRUD fundraisers + CRUD contributors + association/dissociation news) dans `usenghor_backend/app/routers/admin/fundraisers.py`
- [x] T012 Enregistrer les routers dans `usenghor_backend/app/routers/public/__init__.py` et `usenghor_backend/app/routers/admin/__init__.py`
- [x] T013 [P] Créer les données mock de développement dans `usenghor_nuxt/bank/mock-data/fundraising.ts`
- [x] T014 Enregistrer les fichiers i18n dans les index de locales (`usenghor_nuxt/i18n/locales/fr/index.ts`, `en/index.ts`, `ar/index.ts`)

**Checkpoint**: Fondation prête — les user stories peuvent commencer

---

## Phase 3: User Story 4 — Parcourir la liste des levées de fonds (Priority: P1) 🎯 MVP

**Goal**: Un visiteur peut voir toutes les levées de fonds publiées avec titre, image, somme levée, progression et statut

**Independent Test**: Accéder à `/levees-de-fonds` et vérifier que les campagnes publiées s'affichent avec leurs informations de base

### Implementation

- [x] T015 [P] [US4] Créer le composable public `usePublicFundraisingApi` avec les fonctions listPublishedFundraisers, getFundraiserBySlug, transformToDisplay, formatCurrency dans `usenghor_nuxt/app/composables/usePublicFundraisingApi.ts`
- [x] T016 [P] [US4] Créer le composant CardFundraiser (image, titre, barre de progression, montant levé/objectif, statut, nombre de contributeurs) dans `usenghor_nuxt/app/components/cards/CardFundraiser.vue`
- [x] T017 [US4] Créer la page liste publique des levées de fonds (hero, grille de cartes, état vide, pagination) dans `usenghor_nuxt/app/pages/levees-de-fonds/index.vue`

**Checkpoint**: La page liste est fonctionnelle — les visiteurs peuvent découvrir les campagnes

---

## Phase 4: User Story 1 — Consulter une levée de fonds (Priority: P1)

**Goal**: Un visiteur accède au détail d'une levée de fonds avec hero section, image de couverture, et onglet Présentation (texte enrichi + progression financière)

**Independent Test**: Accéder à `/levees-de-fonds/{slug}` et vérifier le hero, l'image, la description enrichie, l'objectif, le montant levé et la barre de progression

### Implementation

- [x] T018 [US1] Créer la page détail avec hero section, image de couverture, système d'onglets (Présentation actif par défaut), contenu rich text via RichTextRenderer, affichage objectif/montant levé/barre de progression dans `usenghor_nuxt/app/pages/levees-de-fonds/[slug].vue`

**Checkpoint**: La page détail est fonctionnelle avec l'onglet Présentation

---

## Phase 5: User Story 2 — Consulter les contributeurs (Priority: P1)

**Goal**: L'onglet Contributeurs affiche les contributeurs regroupés par catégorie (États, Fondations, Entreprises) avec logo, nom et montant, triés par montant décroissant

**Independent Test**: Naviguer vers l'onglet Contributeurs et vérifier le regroupement par catégorie, les logos, noms, montants et le tri décroissant

### Implementation

- [x] T019 [US2] Ajouter l'onglet Contributeurs à la page détail : affichage groupé par catégorie (state_organization, foundation_philanthropist, company) avec logo optionnel, nom, montant formaté en EUR, tri par montant décroissant, gestion des catégories vides dans `usenghor_nuxt/app/pages/levees-de-fonds/[slug].vue`

**Checkpoint**: Les 2 premiers onglets sont fonctionnels (Présentation + Contributeurs)

---

## Phase 6: User Story 5 — Gérer les levées de fonds - admin (Priority: P2)

**Goal**: Un administrateur peut créer, modifier et publier des levées de fonds (titre, slug, description rich text trilingue, image de couverture, objectif financier, statut)

**Independent Test**: Créer une levée de fonds dans l'admin, la publier, et vérifier qu'elle apparaît côté public

### Implementation

- [x] T020 [P] [US5] Créer le composable admin `useAdminFundraisingApi` avec les fonctions CRUD (create, update, delete, list, getById, getStats), constantes de statuts/labels/couleurs dans `usenghor_nuxt/app/composables/useAdminFundraisingApi.ts`
- [x] T021 [US5] Créer la page admin liste des levées de fonds (table avec recherche, filtres par statut, stats cards, actions rapides : voir/modifier/supprimer, badges de statut) dans `usenghor_nuxt/app/pages/admin/contenus/levees-de-fonds/index.vue`
- [x] T022 [US5] Créer la page admin création d'une levée de fonds (formulaire avec titre, slug auto-généré, description rich text trilingue via RichTextEditor, image de couverture, objectif financier, statut) dans `usenghor_nuxt/app/pages/admin/contenus/levees-de-fonds/nouveau.vue`
- [x] T023 [US5] Créer la page admin édition d'une levée de fonds (même formulaire que création, pré-rempli avec les données existantes, mise à jour via exclude_unset) dans `usenghor_nuxt/app/pages/admin/contenus/levees-de-fonds/[id]/edit.vue`

**Checkpoint**: Le CRUD admin des levées de fonds est complet

---

## Phase 7: User Story 6 — Gérer les contributeurs - admin (Priority: P2)

**Goal**: Un administrateur peut ajouter, modifier et supprimer des contributeurs pour chaque levée de fonds (nom trilingue, catégorie, montant, logo)

**Independent Test**: Ajouter des contributeurs à une levée de fonds et vérifier leur affichage dans l'onglet Contributeurs côté public

### Implementation

- [x] T024 [US6] Ajouter les fonctions CRUD contributeurs (addContributor, updateContributor, deleteContributor, listContributors) au composable admin dans `usenghor_nuxt/app/composables/useAdminFundraisingApi.ts`
- [x] T025 [US6] Ajouter la section gestion des contributeurs à la page admin édition : liste des contributeurs existants, formulaire d'ajout (nom FR/EN/AR, catégorie dropdown, montant EUR, logo upload optionnel), actions modifier/supprimer, recalcul du total affiché dans `usenghor_nuxt/app/pages/admin/contenus/levees-de-fonds/[id]/edit.vue`

**Checkpoint**: La gestion admin des contributeurs est fonctionnelle, le total se recalcule automatiquement

---

## Phase 8: User Story 3 — Consulter les actualités liées (Priority: P2)

**Goal**: L'onglet Actualités affiche les actualités associées à la levée de fonds avec titre, résumé, image et lien vers le détail

**Independent Test**: Associer des actualités à une levée de fonds (via admin, Phase 9) et vérifier leur affichage dans l'onglet Actualités

### Implementation

- [x] T026 [US3] Ajouter l'onglet Actualités à la page détail : liste des actualités associées (titre, résumé, image, date de publication), lien vers la page détail de l'actualité via NuxtLink + localePath, message d'état vide si aucune actualité associée dans `usenghor_nuxt/app/pages/levees-de-fonds/[slug].vue`

**Checkpoint**: Les 3 onglets sont fonctionnels côté public

---

## Phase 9: User Story 7 — Associer des actualités - admin (Priority: P3)

**Goal**: Un administrateur peut associer et dissocier des actualités existantes à une levée de fonds

**Independent Test**: Associer une actualité existante à une levée de fonds et vérifier son apparition dans l'onglet Actualités côté public

### Implementation

- [x] T027 [US7] Ajouter les fonctions association/dissociation actualités (associateNews, dissociateNews, searchPublishedNews) au composable admin dans `usenghor_nuxt/app/composables/useAdminFundraisingApi.ts`
- [x] T028 [US7] Ajouter la section association d'actualités à la page admin édition : recherche d'actualités publiées, sélection, liste des actualités associées avec action dissocier dans `usenghor_nuxt/app/pages/admin/contenus/levees-de-fonds/[id]/edit.vue`

**Checkpoint**: Le cycle complet est fonctionnel (admin + public pour les 3 onglets)

---

## Phase 10: Polish & Cross-Cutting Concerns

**Purpose**: Améliorations transversales, support RTL, navigation

- [x] T029 [P] Ajouter le lien « Levées de fonds » dans la navigation principale du site (header/menu) avec traduction trilingue
- [x] T030 [P] Vérifier et ajuster le support RTL (arabe) sur toutes les pages : liste, détail (hero, onglets, contributeurs, actualités), admin
- [x] T031 Vérifier le rendu responsive (mobile/tablette/desktop) des pages publiques et admin
- [x] T032 Valider le parcours complet quickstart.md : création via admin → publication → consultation publique des 3 onglets

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Pas de dépendance — peut démarrer immédiatement
- **Foundational (Phase 2)**: Dépend de Phase 1 (T004) — BLOQUE toutes les user stories
- **US4 (Phase 3)**: Dépend de Phase 2 — page liste publique
- **US1 (Phase 4)**: Dépend de Phase 2 — page détail + onglet Présentation
- **US2 (Phase 5)**: Dépend de Phase 4 (T018) — ajoute l'onglet Contributeurs à la page détail
- **US5 (Phase 6)**: Dépend de Phase 2 — admin CRUD (indépendant de US1-US4)
- **US6 (Phase 7)**: Dépend de Phase 6 (T023) — ajoute la gestion contributeurs à la page édition
- **US3 (Phase 8)**: Dépend de Phase 4 (T018) — ajoute l'onglet Actualités à la page détail
- **US7 (Phase 9)**: Dépend de Phase 6 (T023) — ajoute l'association actualités à la page édition
- **Polish (Phase 10)**: Dépend de toutes les phases précédentes

### User Story Dependencies

```
Phase 1 (Setup)
  └─→ Phase 2 (Foundational)
        ├─→ Phase 3 (US4: Liste publique) ── indépendant
        ├─→ Phase 4 (US1: Détail + Présentation)
        │     ├─→ Phase 5 (US2: Onglet Contributeurs)
        │     └─→ Phase 8 (US3: Onglet Actualités)
        └─→ Phase 6 (US5: Admin CRUD)
              ├─→ Phase 7 (US6: Admin Contributeurs)
              └─→ Phase 9 (US7: Admin Actualités)
```

### Within Each User Story

- Composables avant pages
- Composants avant pages qui les utilisent
- Core implementation avant intégration

### Parallel Opportunities

**Après Phase 2** :
- US4 (liste publique) et US1 (détail) peuvent être développées en parallèle
- US4 et US5 (admin CRUD) peuvent être développées en parallèle
- US1 et US5 peuvent être développées en parallèle

**Après Phase 4 + Phase 6** :
- US2 (onglet contributeurs public) et US6 (admin contributeurs) en parallèle
- US3 (onglet actualités public) et US7 (admin actualités) en parallèle

---

## Parallel Example: Phase 2 (Foundational)

```bash
# Lancer en parallèle (fichiers différents) :
Task T005: "Créer les modèles SQLAlchemy dans usenghor_backend/app/models/fundraising.py"
Task T006: "Créer les schemas Pydantic dans usenghor_backend/app/schemas/fundraising.py"
Task T007: "Créer les types TypeScript dans usenghor_nuxt/app/types/fundraising.ts"
Task T008: "Créer les fichiers i18n dans usenghor_nuxt/i18n/locales/"
Task T013: "Créer les données mock dans usenghor_nuxt/bank/mock-data/fundraising.ts"
```

## Parallel Example: Après Phase 2

```bash
# Deux branches parallèles possibles :
# Branche publique :
Task T015-T018: US4 + US1 (liste + détail publics)

# Branche admin :
Task T020-T023: US5 (admin CRUD)
```

---

## Implementation Strategy

### MVP First (US4 + US1 uniquement)

1. Compléter Phase 1: Setup (SQL + migration)
2. Compléter Phase 2: Foundational (models, schemas, service, routers)
3. Compléter Phase 3: US4 (page liste publique)
4. Compléter Phase 4: US1 (page détail + onglet Présentation)
5. **STOP et VALIDER**: Tester la navigation liste → détail avec données mock
6. Déployer/démo si prêt

### Incremental Delivery

1. Setup + Foundational → Fondation prête
2. US4 (liste) → Test indépendant → Démo (page liste visible)
3. US1 (détail + présentation) → Test indépendant → Démo (parcours complet)
4. US2 (contributeurs) → Test indépendant → Démo (onglet contributeurs)
5. US5 (admin CRUD) → Test indépendant → Démo (création via admin)
6. US6 (admin contributeurs) → Test indépendant → Démo (gestion contributeurs)
7. US3 + US7 (actualités) → Test indépendant → Démo (cycle complet)
8. Polish → Validation finale

---

## Notes

- [P] = fichiers différents, pas de dépendances
- [Story] = traçabilité vers la user story de la spec
- Chaque user story peut être testée indépendamment
- Commit après chaque tâche ou groupe logique
- S'arrêter à chaque checkpoint pour valider la story
- Les montants sont tous en EUR, formatés avec le séparateur de milliers approprié à la locale
- Le contenu rich text suit le pattern dual HTML/Markdown existant (TOAST UI Editor)
