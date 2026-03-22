# Tasks: Refonte Page Levée de Fonds

**Input**: Design documents from `/specs/010-fundraising-revamp/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/api-endpoints.md, quickstart.md

**Tests**: Non demandés — pas de tâches de test automatisé.

**Organization**: Tâches groupées par user story pour permettre une implémentation et des tests indépendants.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut s'exécuter en parallèle (fichiers différents, pas de dépendances)
- **[Story]**: User story associée (US1, US2, US3, US4, US5)
- Chemins exacts inclus dans chaque description

---

## Phase 1: Setup (Nettoyage et infrastructure)

**Purpose**: Suppression de l'implémentation 004 et création de la migration SQL

- [x] T001 Supprimer les fichiers backend 004 : `usenghor_backend/app/models/fundraising.py`, `usenghor_backend/app/schemas/fundraising.py`, `usenghor_backend/app/services/fundraising_service.py`, `usenghor_backend/app/routers/admin/fundraisers.py`, `usenghor_backend/app/routers/public/fundraisers.py`
- [x] T000 Supprimer les fichiers frontend 004 : `usenghor_nuxt/app/pages/levees-de-fonds/`, `usenghor_nuxt/app/pages/admin/contenus/levees-de-fonds/`, `usenghor_nuxt/app/components/cards/CardFundraiser.vue`, `usenghor_nuxt/app/composables/usePublicFundraisingApi.ts`, `usenghor_nuxt/app/composables/useAdminFundraisingApi.ts`, `usenghor_nuxt/app/types/fundraising.ts`, `usenghor_nuxt/bank/mock-data/fundraising.ts`
- [x] T000 Nettoyer les imports/références à 004 dans les fichiers de routage backend (`usenghor_backend/app/main.py` ou équivalent) et les éventuels index de composants frontend
- [x] T000 Créer la migration SQL `usenghor_backend/documentation/modele_de_données/migrations/010_fundraising_revamp.sql` : ALTER `fundraiser_contributors` ADD `show_amount_publicly`, CREATE `fundraiser_interest_expressions`, CREATE `fundraiser_editorial_sections`, CREATE `fundraiser_editorial_items`, CREATE `fundraiser_media`, INSERT seed 3 sections éditoriales avec items d'exemple. Voir `data-model.md` pour les schémas complets.
- [x] T000 Mettre à jour le schéma SQL de référence `usenghor_backend/documentation/modele_de_données/services/13_fundraising.sql` pour refléter toutes les nouvelles tables et modifications
- [x] T000 Exécuter la migration SQL sur la base locale : `docker exec -i usenghor_postgres psql -U usenghor -d usenghor < usenghor_backend/documentation/modele_de_données/migrations/010_fundraising_revamp.sql`

---

## Phase 2: Foundational (Prérequis bloquants)

**Purpose**: Modèles, schémas, service, routeurs et types de base nécessaires à TOUTES les user stories

**⚠️ CRITICAL**: Aucune user story ne peut commencer avant la fin de cette phase

- [x] T000 Créer les modèles SQLAlchemy dans `usenghor_backend/app/models/fundraising.py` : Fundraiser, FundraiserContributor (avec `show_amount_publicly`), FundraiserNews, FundraiserInterestExpression, FundraiserEditorialSection, FundraiserEditorialItem, FundraiserMedia. Définir les enums FundraiserStatus, ContributorCategory, InterestExpressionStatus. Suivre le pattern existant du projet (UUID pk, timestamps, relationships avec cascade).
- [x] T000 Créer les schémas Pydantic dans `usenghor_backend/app/schemas/fundraising.py` : FundraiserCreate/Update/Read, ContributorCreate/Update/Read/Public (avec logique `show_amount_publicly`), FundraiserPublic/PublicDetail, InterestExpressionCreate/Read/StatusUpdate, EditorialSectionRead/Update, EditorialItemCreate/Update/Read, FundraiserMediaCreate/Read, GlobalStats, AllContributorsPublic. Voir `contracts/api-endpoints.md` pour les formats de réponse.
- [x] T000 Créer le service métier dans `usenghor_backend/app/services/fundraising_service.py` : CRUD fundraisers avec enrichissement (total_raised, progress_percentage, contributor_count), CRUD contributors, calcul agrégé global stats, liste contributeurs uniques toutes campagnes. Réutiliser le pattern `_compute_totals()` et `_enrich_fundraiser()`.
- [x] T010 [P] Créer le routeur admin de base dans `usenghor_backend/app/routers/admin/fundraisers.py` : CRUD campagnes (list paginé + search + filtre status, get, create, update, delete), CRUD contributeurs par campagne (list, add, update, delete), statistiques dashboard. Route statique `/statistics` AVANT la route dynamique `/{id}`. Permissions : `fundraisers.view`, `fundraisers.create`, `fundraisers.edit`, `fundraisers.delete`.
- [x] T011 [P] Créer le routeur public de base dans `usenghor_backend/app/routers/public/fundraisers.py` : GET `/api/public/fundraisers` (liste paginée, filtre status active/completed), GET `/api/public/fundraisers/global-stats`, GET `/api/public/fundraisers/all-contributors` (agrégation par nom, pagination, masquage montant si non consenti), GET `/api/public/fundraisers/{slug}` (détail avec contributeurs, news, médias). Routes statiques (`/global-stats`, `/all-contributors`) AVANT `/{slug}`.
- [x] T012 Enregistrer les routeurs dans `usenghor_backend/app/main.py` (ou le fichier de configuration des routes) : inclure admin/fundraisers et public/fundraisers avec les préfixes appropriés
- [x] T013 [P] Créer les types TypeScript dans `usenghor_nuxt/app/types/fundraising.ts` : interfaces FundraiserStatus, ContributorCategory, InterestExpressionStatus, FundraiserPublic, FundraiserPublicDetail, ContributorPublic, GlobalStats, AllContributorsItem, EditorialSection, EditorialItem, FundraiserMedia, InterestExpressionForm, InterestExpressionRead, FundraiserDisplay, FundraiserCreatePayload, FundraiserUpdatePayload. Constantes statusLabels/Colors, categoryLabels/Order.
- [x] T014 [P] Créer le composable public dans `usenghor_nuxt/app/composables/usePublicFundraisingApi.ts` : listPublishedFundraisers(page, limit, status), getFundraiserBySlug(slug), getGlobalStats(), getAllContributors(page, limit), getEditorialSections(), formatCurrency(amount, locale), resolveMediaUrl(externalId), transformToDisplay().
- [x] T015 [P] Créer le composable admin dans `usenghor_nuxt/app/composables/useAdminFundraisingApi.ts` : CRUD fundraisers, CRUD contributors (avec show_amount_publicly), statistics, slugify(). Les fonctions pour interest expressions, editorial sections et media seront ajoutées dans les phases suivantes.
- [x] T016 [P] Créer les données mock dans `usenghor_nuxt/bank/mock-data/fundraising.ts` : campagnes exemples (1 active, 2 completed), contributeurs avec show_amount_publicly varié, sections éditoriales avec items, médias exemples. Helpers : getFundraiserById(), getFundraiserBySlug(), getGlobalStats(), getAllContributors().
- [x] T017 [P] Mettre à jour les traductions i18n de base dans `usenghor_nuxt/i18n/locales/fr/levees-de-fonds.json`, `en/levees-de-fonds.json`, `ar/levees-de-fonds.json` : clés pour hero, sections, onglets, statuts, boutons, formulaire, messages. Couvrir toutes les clés utilisées par les composants et pages des phases suivantes.

**Checkpoint**: Backend fonctionnel (endpoints CRUD campagnes/contributeurs, stats globales), types/composables/mock data prêts. Les pages frontend peuvent commencer.

---

## Phase 3: User Story 1 — Page principale Levée de Fonds (Priority: P1) 🎯 MVP

**Goal**: Un visiteur consulte `/levees-de-fonds` et voit hero, sections éditoriales (données mock/seed), montant total, contributeurs globaux, campagne active mise en évidence, campagnes passées en section secondaire, actualités liées.

**Independent Test**: Naviguer vers `/levees-de-fonds`, vérifier la présence de toutes les sections, le scroll vertical avec barre d'ancres sticky, la distinction campagne active / passées.

### Implementation for User Story 1

- [x] T018 [P] [US1] Créer le composant `usenghor_nuxt/app/components/fundraising/HeroSection.vue` : hero section avec titre (`$t`), sous-titre, image de fond, pattern décoratif et séparateur SVG diagonal. Suivre le pattern de `ActualitesHero.vue` mais adapté au contexte levée de fonds.
- [x] T019 [P] [US1] Créer le composant `usenghor_nuxt/app/components/fundraising/AnchorNav.vue` : barre de navigation sticky (top après scroll passé le hero) avec liens d'ancres vers chaque section de la page. Scroll smooth au clic. Highlight de la section active via IntersectionObserver. Responsive (horizontal scroll sur mobile).
- [x] T020 [P] [US1] Créer le composant `usenghor_nuxt/app/components/fundraising/EditorialSection.vue` : affichage d'une section éditoriale en grille/cards. Props : title, items (icône + titre + description). Grille responsive (3 colonnes desktop, 2 tablette, 1 mobile). Support RTL pour l'arabe.
- [x] T021 [P] [US1] Créer le composant `usenghor_nuxt/app/components/fundraising/ProgressBar.vue` : barre de progression visuelle avec montant atteint / objectif, pourcentage, animation au scroll. Gestion du cas >100%. formatCurrency pour les montants.
- [x] T022 [P] [US1] Créer le composant `usenghor_nuxt/app/components/fundraising/ContributorsList.vue` : liste/grille de contributeurs avec logo, nom, catégorie, montant (si consenti). Props : contributors[], showCampaignCount (pour la page principale). Groupement par catégorie optionnel. Pagination côté client ou "voir plus".
- [x] T023 [P] [US1] Créer le composant `usenghor_nuxt/app/components/cards/CardFundraiser.vue` : carte campagne avec image cover, titre, barre de progression, montant collecté/objectif, nombre de contributeurs, badge statut (vert=active, bleu=clôturée). Lien vers `/levees-de-fonds/[slug]`. Hover animation.
- [x] T024 [US1] Créer le endpoint public GET `/api/public/fundraisers/editorial-sections` dans `usenghor_backend/app/routers/public/fundraisers.py` : retourne les sections éditoriales actives avec leurs items actifs, triés par display_order. Champs titre/description renvoyés dans la langue de la requête (Accept-Language). Route statique AVANT `/{slug}`.
- [x] T025 [US1] Ajouter la méthode `getEditorialSections()` dans le service backend `usenghor_backend/app/services/fundraising_service.py` et les schémas Pydantic correspondants si pas déjà faits en T008.
- [x] T026 [US1] Créer la page principale `usenghor_nuxt/app/pages/levees-de-fonds/index.vue` : assemblage des composants — HeroSection, AnchorNav (sticky), 3x EditorialSection (raisons, engagements, bénéfices), section montant total (GlobalStats), section campagne active (CardFundraiser mis en évidence), section campagnes passées (grille de CardFundraiser plus discrète), section ContributorsList (tous contributeurs), section actualités (cards news liées). Appels API via usePublicFundraisingApi. useSeoMeta + OG tags trilingues.

**Checkpoint**: La page principale affiche toutes les sections. Un visiteur voit le hero, les sections éditoriales, le total collecté, la campagne active, les campagnes passées, les contributeurs et les actualités.

---

## Phase 4: User Story 2 — Page campagne individuelle (Priority: P1)

**Goal**: Un visiteur consulte `/levees-de-fonds/[slug]` et voit la présentation, l'indicateur de progression, les onglets contributeurs et médiathèque.

**Independent Test**: Naviguer vers `/levees-de-fonds/[slug]`, vérifier présentation, progression objectif/atteint, onglet contributeurs avec montants conditionnels, onglet médiathèque.

### Implementation for User Story 2

- [x] T027 [P] [US2] Créer le composant `usenghor_nuxt/app/components/fundraising/MediaGallery.vue` : galerie de médias en grille avec vignettes, lightbox pour agrandissement (photo/vidéo), légendes trilingues, état vide. Support images + vidéos + documents (icône de téléchargement pour documents).
- [x] T028 [US2] Créer la page détail `usenghor_nuxt/app/pages/levees-de-fonds/[slug].vue` : hero avec cover image + titre, section présentation (description_html), section raison (reason_html), ProgressBar avec stats financières (goal, raised, percentage, remaining), système d'onglets (Présentation, Contributeurs, Médiathèque), ContributorsList dans l'onglet contributeurs (montant affiché si consenti, sinon masqué), MediaGallery dans l'onglet médiathèque (masqué si aucun média), badge statut "Clôturée" si completed. Appels API via getFundraiserBySlug(). useSeoMeta + OG tags.

**Checkpoint**: Les pages principale et détail sont fonctionnelles. Navigation complète entre liste et détail.

---

## Phase 5: User Story 3 — Manifestation d'intérêt (Priority: P2)

**Goal**: Un visiteur peut manifester son intérêt via un formulaire anti-spam. L'admin peut consulter, marquer comme contacté, et exporter en CSV les manifestations.

**Independent Test**: Remplir le formulaire sur une campagne active, vérifier l'enregistrement en base, l'email de confirmation, la notification admin. Vérifier que le formulaire est caché sur les campagnes clôturées. Tester le rejet des soumissions bot (honeypot rempli, délai trop court).

### Implementation for User Story 3

- [x] T029 [P] [US3] Créer les templates email Jinja2 dans `usenghor_backend/app/templates/email/interest_expression_confirmation.html` (confirmation visiteur : remerciement, récapitulatif, nom de la campagne) et `usenghor_backend/app/templates/email/interest_expression_notification.html` (notification admin : détails du visiteur, lien vers l'admin, nom de la campagne). Utiliser le base template `base.html` existant.
- [x] T030 [US3] Ajouter dans le service `usenghor_backend/app/services/fundraising_service.py` : méthodes `create_or_update_interest_expression()` (INSERT ON CONFLICT UPDATE sur email+fundraiser_id), `list_interest_expressions()` (paginé, filtrable par campagne/status/search), `update_interest_status()`, `export_interest_expressions_csv()`. Intégrer l'envoi d'email (confirmation visiteur + notification admin) via le service email existant.
- [x] T031 [US3] Ajouter le endpoint public POST `/api/public/fundraisers/{slug}/interest` dans `usenghor_backend/app/routers/public/fundraisers.py` : validation anti-spam (honeypot vide, challenge_token valide, form_opened_at > 3s), vérification campagne active, appel service, réponses 201/200/400/404 selon le cas. Voir `contracts/api-endpoints.md`.
- [x] T032 [US3] Ajouter les endpoints admin dans `usenghor_backend/app/routers/admin/fundraisers.py` : GET `/interest-expressions` (liste paginée + filtres), PUT `/interest-expressions/{id}/status` (changer statut new/contacted), GET `/interest-expressions/export` (StreamingResponse CSV avec csv.writer + io.StringIO, Content-Disposition header). Route statique `/interest-expressions` AVANT les routes dynamiques.
- [x] T033 [P] [US3] Créer le composant `usenghor_nuxt/app/components/fundraising/InterestForm.vue` : formulaire avec champs nom, email, message optionnel + champ honeypot caché en CSS + génération du challenge_token (hash JS timestamp+secret) + enregistrement form_opened_at. Validation côté client (email format, nom requis). État de chargement, message succès/erreur. Visible uniquement si campagne active.
- [x] T034 [US3] Intégrer le composant InterestForm dans la page `usenghor_nuxt/app/pages/levees-de-fonds/[slug].vue` : afficher le bouton "Manifester son intérêt" qui ouvre le formulaire (modal ou section). Masquer si campagne clôturée.
- [x] T035 [US3] Ajouter les méthodes `submitInterest()` dans `usenghor_nuxt/app/composables/usePublicFundraisingApi.ts` et les méthodes admin `listInterestExpressions()`, `updateInterestStatus()`, `exportInterestCSV()` dans `usenghor_nuxt/app/composables/useAdminFundraisingApi.ts`.
- [x] T036 [US3] Créer la page admin `usenghor_nuxt/app/pages/admin/contenus/levees-de-fonds/interets.vue` : tableau paginé des manifestations d'intérêt, filtres (campagne dropdown, statut, recherche texte), bouton changement de statut (new↔contacted), bouton export CSV, badge de compteur "nouveau".

**Checkpoint**: Le formulaire de manifestation d'intérêt fonctionne avec anti-spam. Les emails sont envoyés. L'admin peut consulter, filtrer, changer le statut et exporter en CSV.

---

## Phase 6: User Story 4 — Sections éditoriales admin (Priority: P2)

**Goal**: Un administrateur peut gérer le contenu des 3 sections éditoriales (raisons, engagements, bénéfices) : modifier les titres de section, ajouter/modifier/supprimer des items (icône, titre, description) en trilingue.

**Independent Test**: Modifier un item dans l'admin, vérifier que le changement apparaît sur la page publique. Tester en FR, EN, et AR (RTL).

### Implementation for User Story 4

- [x] T037 [US4] Ajouter dans le service `usenghor_backend/app/services/fundraising_service.py` : méthodes CRUD pour editorial sections (get_all_sections_with_items, update_section, create_item, update_item, delete_item). Les sections elles-mêmes ne sont pas supprimables (seed), seuls les items le sont.
- [x] T038 [US4] Ajouter les endpoints admin CRUD sections éditoriales dans `usenghor_backend/app/routers/admin/fundraisers.py` : GET `/editorial-sections` (liste avec items), PUT `/editorial-sections/{id}` (modifier titre section), POST `/editorial-sections/{section_id}/items` (ajouter item), PUT `/editorial-sections/items/{id}` (modifier item), DELETE `/editorial-sections/items/{id}` (supprimer item).
- [x] T039 [US4] Ajouter les méthodes admin `listEditorialSections()`, `updateSection()`, `createItem()`, `updateItem()`, `deleteItem()` dans `usenghor_nuxt/app/composables/useAdminFundraisingApi.ts`.
- [x] T040 [US4] Créer la page admin `usenghor_nuxt/app/pages/admin/contenus/levees-de-fonds/sections-editoriales.vue` : affichage des 3 sections avec leurs items, formulaire d'édition inline ou modal pour chaque item (icône, titre FR/EN/AR, description FR/EN/AR), drag & drop ou flèches pour réordonner, boutons ajouter/modifier/supprimer item. Switch de langue pour prévisualiser.

**Checkpoint**: L'admin peut gérer le contenu éditorial de la page principale. Les modifications se reflètent en temps réel sur la page publique dans les 3 langues.

---

## Phase 7: User Story 5 — Médiathèque de campagne (Priority: P3)

**Goal**: Un administrateur peut associer des médias à chaque campagne. Les visiteurs voient la galerie dans l'onglet Médiathèque.

**Independent Test**: Ajouter des médias à une campagne dans l'admin, vérifier l'affichage en galerie sur la page publique. Vérifier que l'onglet est masqué quand il n'y a pas de médias.

### Implementation for User Story 5

- [x] T041 [US5] Ajouter dans le service `usenghor_backend/app/services/fundraising_service.py` : méthodes CRUD pour fundraiser_media (list_media, add_media, update_media, remove_media). Vérification UNIQUE(fundraiser_id, media_external_id).
- [x] T042 [US5] Ajouter les endpoints admin CRUD médias campagne dans `usenghor_backend/app/routers/admin/fundraisers.py` : GET `/{id}/media`, POST `/{id}/media`, PUT `/{id}/media/{media_id}`, DELETE `/{id}/media/{media_id}`.
- [x] T043 [US5] Ajouter les méthodes admin `listFundraiserMedia()`, `addMedia()`, `updateMedia()`, `removeMedia()` dans `usenghor_nuxt/app/composables/useAdminFundraisingApi.ts`.
- [x] T044 [US5] Intégrer la gestion des médias dans la page d'édition admin `usenghor_nuxt/app/pages/admin/contenus/levees-de-fonds/[id]/edit.vue` : onglet ou section "Médiathèque" avec sélecteur de médias existants, légendes trilingues, réordonnement, suppression.

**Checkpoint**: Les médias sont gérables par l'admin et s'affichent correctement dans la galerie publique. L'onglet Médiathèque est masqué si aucun média.

---

## Phase 8: Admin CRUD Campagnes (Pages frontend)

**Purpose**: Pages admin complètes pour la gestion des campagnes et contributeurs

- [x] T045 [P] Créer la page admin liste `usenghor_nuxt/app/pages/admin/contenus/levees-de-fonds/index.vue` : tableau paginé des campagnes avec titre, statut (badge couleur), montant collecté/objectif, nombre de contributeurs, actions (éditer, supprimer). Filtres par statut, recherche par titre. Dashboard stats en haut (total campagnes, actives, clôturées, montant total).
- [x] T046 [P] Créer la page admin création `usenghor_nuxt/app/pages/admin/contenus/levees-de-fonds/nouveau.vue` : formulaire de création avec titre, slug (auto-généré), descriptions trilingues (TOAST UI Editor pour HTML+MD), objectif financier, statut, image de couverture (sélecteur média).
- [x] T047 Créer la page admin édition `usenghor_nuxt/app/pages/admin/contenus/levees-de-fonds/[id]/edit.vue` : formulaire d'édition comme création + gestion des contributeurs (liste, ajout, modification avec `show_amount_publicly`, suppression), gestion des actualités associées (association/dissociation), gestion des médias (intégré en Phase 7 T044).

**Checkpoint**: L'admin peut créer, éditer et supprimer des campagnes, gérer les contributeurs et les actualités associées.

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Améliorations transversales, SEO, performance

- [x] T048 [P] Vérifier et compléter les traductions i18n manquantes dans `usenghor_nuxt/i18n/locales/{fr,en,ar}/levees-de-fonds.json` : tous les labels, messages d'erreur, placeholders, titres de sections, métadonnées SEO
- [x] T049 [P] Vérifier le rendu RTL (arabe) sur toutes les pages et composants : direction du texte, alignement des grilles, barre d'ancres, formulaire, galerie, barres de progression
- [x] T050 [P] Vérifier les meta OG et SEO sur les pages `/levees-de-fonds` et `/levees-de-fonds/[slug]` : useSeoMeta avec titre, description, og:image (cover campagne), og:locale alternatives pour les 3 langues
- [x] T051 Vérifier le dark mode sur tous les composants fundraising : couleurs, contrastes, bordures, fonds de cartes
- [x] T052 Vérifier la responsivité mobile de toutes les pages : hero, barre d'ancres (scroll horizontal), grilles éditoriales, cartes campagnes, tableau contributeurs, formulaire, galerie
- [ ] T053 Exécuter la migration SQL en production : `docker exec -i usenghor_db psql -U usenghor -d usenghor < usenghor_backend/documentation/modele_de_données/migrations/010_fundraising_revamp.sql`
- [ ] T054 Run quickstart.md validation : vérifier tous les items de la checklist "Vérifications clés"

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: Pas de dépendances — commence immédiatement
- **Phase 2 (Foundational)**: Dépend de Phase 1 — BLOQUE toutes les user stories
- **Phase 3 (US1)**: Dépend de Phase 2
- **Phase 4 (US2)**: Dépend de Phase 2 — parallélisable avec Phase 3
- **Phase 5 (US3)**: Dépend de Phase 4 (le formulaire est sur la page campagne)
- **Phase 6 (US4)**: Dépend de Phase 2 — parallélisable avec Phases 3/4
- **Phase 7 (US5)**: Dépend de Phase 4 (la galerie est sur la page campagne)
- **Phase 8 (Admin)**: Dépend de Phase 2 — parallélisable avec Phases 3/4
- **Phase 9 (Polish)**: Dépend de toutes les phases précédentes

### User Story Dependencies

- **US1 (Page principale)**: Après Phase 2 — indépendante des autres stories
- **US2 (Page campagne)**: Après Phase 2 — indépendante, parallélisable avec US1
- **US3 (Manifestation intérêt)**: Après US2 (formulaire intégré à la page campagne)
- **US4 (Sections éditoriales admin)**: Après Phase 2 — indépendante, parallélisable avec US1/US2
- **US5 (Médiathèque)**: Après US2 (galerie intégrée à la page campagne)

### Within Each User Story

- Backend (service + endpoints) avant frontend (composants + pages)
- Composables avant pages
- Composants atomiques avant pages d'assemblage

### Parallel Opportunities

- T010/T011 : routeurs admin et public en parallèle
- T013/T014/T015/T016/T017 : types, composables, mock data, i18n en parallèle
- T018/T019/T020/T021/T022/T023 : tous les composants US1 en parallèle
- T027 (MediaGallery) en parallèle avec T028 si le composant est stubbed
- T029/T033 : templates email et InterestForm en parallèle
- T045/T046 : pages admin liste et création en parallèle
- T048/T049/T050 : vérifications polish en parallèle

---

## Parallel Example: Phase 2 (Foundational)

```bash
# Backend en séquentiel (dépendances entre modèles → service → routeurs)
Task T007: "Modèles SQLAlchemy"
Task T008: "Schémas Pydantic"
Task T009: "Service métier"
# Puis en parallèle :
Task T010: "Routeur admin"        # [P]
Task T011: "Routeur public"       # [P]

# Frontend tout en parallèle :
Task T013: "Types TypeScript"     # [P]
Task T014: "Composable public"    # [P]
Task T015: "Composable admin"     # [P]
Task T016: "Mock data"            # [P]
Task T017: "Traductions i18n"     # [P]
```

## Parallel Example: Phase 3 (US1)

```bash
# Tous les composants en parallèle :
Task T018: "HeroSection"          # [P]
Task T019: "AnchorNav"            # [P]
Task T020: "EditorialSection"     # [P]
Task T021: "ProgressBar"          # [P]
Task T022: "ContributorsList"     # [P]
Task T023: "CardFundraiser"       # [P]

# Puis séquentiel : endpoint → page d'assemblage
Task T024: "Endpoint editorial-sections"
Task T025: "Service editorial-sections"
Task T026: "Page principale index.vue"
```

---

## Implementation Strategy

### MVP First (User Story 1 uniquement)

1. Phase 1: Setup (nettoyage 004)
2. Phase 2: Foundational (modèles, service, routeurs, types)
3. Phase 3: User Story 1 (page principale)
4. **STOP & VALIDATE**: Tester la page `/levees-de-fonds` avec toutes les sections
5. Déployer si prêt

### Incremental Delivery

1. Setup + Foundational → Base technique prête
2. US1 (page principale) → **MVP déployable**
3. US2 (page campagne) + Phase 8 (admin CRUD) → Navigation complète
4. US3 (manifestation intérêt) → Conversion activée
5. US4 (sections éditoriales admin) → Contenu administrable
6. US5 (médiathèque) → Enrichissement visuel
7. Phase 9 (Polish) → Production-ready

---

## Notes

- [P] tasks = fichiers différents, pas de dépendances inter-tâches
- [Story] label mappe chaque tâche à sa user story pour la traçabilité
- Chaque user story est testable et livrable indépendamment
- Committer après chaque tâche ou groupe logique
- S'arrêter à chaque checkpoint pour valider l'incrément
- La migration SQL en production (T053) nécessite une confirmation explicite de l'utilisateur
