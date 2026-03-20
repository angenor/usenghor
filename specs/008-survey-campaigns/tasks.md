# Tasks: Campagnes de sondages et formulaires

**Input**: Design documents from `/specs/008-survey-campaigns/`
**Prerequisites**: plan.md, spec.md, data-model.md, contracts/api-endpoints.md, research.md

**Tests**: Non demandés — pas de tâches de tests automatisés.

**Organization**: Tâches groupées par user story pour implémentation et validation indépendantes.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut être exécuté en parallèle (fichiers différents, pas de dépendances)
- **[Story]**: User story associée (US1, US2, US3, US4, US5)
- Chemins exacts inclus dans chaque description

---

## Phase 1: Setup

**Purpose**: Installation des dépendances et initialisation du schéma de données

- [x] T001 Installer la dépendance `survey-vue3-ui` dans `usenghor_nuxt/package.json` via `pnpm add survey-vue3-ui`
- [x] T002 [P] Créer le fichier SQL `usenghor_backend/documentation/modele_de_données/services/14_survey.sql` avec l'ENUM `survey_campaign_status`, les tables `survey_campaigns`, `survey_responses`, `survey_associations`, la permission `survey.manage` et la vue `v_survey_campaigns_with_stats`
- [x] T003 [P] Créer la migration `usenghor_backend/documentation/modele_de_données/migrations/009_survey_campaigns.sql`
- [x] T004 Ajouter `\i 14_survey.sql` dans `usenghor_backend/documentation/modele_de_données/services/main.sql`
- [x] T005 Appliquer la migration sur la base locale
- [x] T006 [P] Créer les fichiers de traduction i18n : `usenghor_nuxt/i18n/locales/fr/survey.json`, `en/survey.json`, `ar/survey.json` et les enregistrer dans les index.ts respectifs

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Modèles, schémas, service et composables partagés par toutes les user stories

**CRITICAL**: Aucune user story ne peut commencer avant la fin de cette phase

- [x] T007 Ajouter l'enum `SurveyCampaignStatus` dans `usenghor_backend/app/models/base.py` (DRAFT, ACTIVE, PAUSED, CLOSED)
- [x] T008 Créer le modèle SQLAlchemy `SurveyCampaign`, `SurveyResponse`, `SurveyAssociation` dans `usenghor_backend/app/models/survey.py`
- [x] T009 Créer les schémas Pydantic dans `usenghor_backend/app/schemas/survey.py`
- [x] T010 Créer le service `SurveyService` dans `usenghor_backend/app/services/survey_service.py` (CRUD complet + lifecycle + responses + stats + CSV export + associations)
- [x] T011 [P] Créer le composable `useAdminSurveyApi` dans `usenghor_nuxt/app/composables/useAdminSurveyApi.ts`
- [x] T012 [P] Créer le composable `usePublicSurveyApi` dans `usenghor_nuxt/app/composables/usePublicSurveyApi.ts`
- [x] T013 [P] Créer le composant `CampaignStatusBadge.vue` dans `usenghor_nuxt/app/components/survey/CampaignStatusBadge.vue`

**Checkpoint**: Fondations prêtes — l'implémentation des user stories peut commencer

---

## Phase 3: User Story 1 — Créer et publier un formulaire (Priority: P1) MVP

**Goal**: Un gestionnaire peut créer un formulaire via l'interface admin, le publier, et le rendre accessible au public via un lien dédié

**Independent Test**: Créer un formulaire avec 3 types de questions, le publier, accéder au lien public et vérifier l'affichage du formulaire via SurveyJS

### Backend US1

- [x] T014 [US1] Créer le routeur admin `usenghor_backend/app/routers/admin/surveys.py` avec les endpoints CRUD : `GET /`, `GET /{id}`, `POST /`, `PUT /{id}`, `DELETE /{id}` + actions lifecycle `POST /{id}/publish`, `POST /{id}/pause` — tous protégés par `PermissionChecker("survey.manage")` avec filtrage `created_by` (super_admin voit tout)
- [x] T015 [US1] Enregistrer le routeur admin surveys dans `usenghor_backend/app/routers/admin/__init__.py`
- [x] T016 [P] [US1] Créer le routeur public `usenghor_backend/app/routers/public/surveys.py` avec l'endpoint `GET /{slug}` (retourne le formulaire d'une campagne active, 410 si paused/closed, 404 si inexistant)
- [x] T017 [US1] Enregistrer le routeur public surveys dans `usenghor_backend/app/routers/public/__init__.py`

### Frontend US1 — Constructeur de formulaires admin

- [x] T018 [US1] Créer le composant `QuestionBuilder.vue` dans `usenghor_nuxt/app/components/survey/QuestionBuilder.vue` — formulaire de configuration d'une question : sélection du type (text, comment, radiogroup, checkbox, dropdown, tagbox, rating, file, boolean, date), titre trilingue (FR/EN/AR), obligatoire, choix/options pour les types à choix, validateurs. Émet un objet question au format SurveyJS JSON.
- [x] T019 [US1] Créer le composant `QuestionList.vue` dans `usenghor_nuxt/app/components/survey/QuestionList.vue` — liste ordonnée des questions avec réordonnement (drag & drop ou boutons haut/bas), ajout/suppression, édition inline via QuestionBuilder, prévisualisation du type. Émet le tableau de questions au format SurveyJS JSON `{ elements: [...] }`.
- [x] T020 [US1] Créer la page admin `usenghor_nuxt/app/pages/admin/campagnes/nouveau.vue` — formulaire de création : slug, titre trilingue, description trilingue, QuestionList pour construire le formulaire, options (confirmation_email_enabled, closes_at). Sauvegarde en brouillon via `createCampaign()`.
- [x] T021 [US1] Créer la page admin `usenghor_nuxt/app/pages/admin/campagnes/[id]/edit.vue` — même formulaire que nouveau.vue mais pré-rempli avec les données existantes. Boutons : sauvegarder, publier (si draft/paused), mettre en pause (si active). Utilise `updateCampaign()`, `publishCampaign()`, `pauseCampaign()`.

### Frontend US1 — Rendu public

- [x] T022 [US1] Créer le composant `SurveyRenderer.client.vue` dans `usenghor_nuxt/app/components/survey/SurveyRenderer.client.vue` — wrapper SurveyJS Form Library : reçoit `surveyJson` en prop, crée une instance `Model`, configure la locale (fr/en/ar) depuis `useI18n()`, applique le thème custom (CSS variables brand-blue/brand-red), émet `complete` avec les données de réponse.
- [x] T023 [US1] Créer la page publique `usenghor_nuxt/app/pages/formulaires/[slug].vue` — charge le formulaire via `getSurveyBySlug(slug)`, affiche titre/description trilingue, rend le formulaire via `SurveyRenderer`, gère les états (loading, 404, 410 paused/closed avec message).

**Checkpoint**: Un gestionnaire peut créer un formulaire, le publier, et le voir s'afficher publiquement. MVP fonctionnel pour la construction et l'affichage.

---

## Phase 4: User Story 2 — Répondre à un formulaire (Priority: P1)

**Goal**: Un visiteur peut remplir et soumettre un formulaire publié, avec anti-spam et email de confirmation optionnel

**Independent Test**: Remplir un formulaire publié, soumettre, vérifier la confirmation à l'écran et la présence de la réponse en base

### Backend US2

- [x] T024 [US2] Ajouter les méthodes au `SurveyService` dans `usenghor_backend/app/services/survey_service.py` : `submit_response(slug, response_data, ip_address, session_id)` avec validations (campagne active, honeypot vide, session unique, champs obligatoires côté serveur d'après survey_json), `check_rate_limit(ip_address)` (max 5 soumissions/IP/heure)
- [x] T025 [US2] Ajouter l'endpoint `POST /{slug}/submit` dans `usenghor_backend/app/routers/public/surveys.py` — reçoit `SurveySubmitRequest`, extrait IP depuis `Request`, session_id depuis header `X-Session-Id`, appelle `submit_response()`, retourne 201 ou rejet silencieux 200 si honeypot rempli
- [x] T026 [P] [US2] Créer le template email `usenghor_backend/app/templates/email/survey_confirmation.html` (hérite de base.html) — message de confirmation avec le nom de la campagne, date de soumission, lien vers le site
- [x] T027 [US2] Ajouter la logique d'envoi d'email de confirmation dans `submit_response()` : si `confirmation_email_enabled` et qu'un champ email est trouvé dans response_data (clé `email` ou question avec `inputType: "email"`), envoyer via `EmailService.send_email()`

### Frontend US2

- [x] T028 [US2] Enrichir `SurveyRenderer.client.vue` : ajouter le champ honeypot invisible au formulaire, gérer le callback `onComplete` pour envoyer les données au backend via `submitResponse()`, gérer le `onUploadFiles` pour les questions de type file via `uploadFile()`, afficher un écran de confirmation après soumission réussie
- [x] T029 [US2] Enrichir la page `usenghor_nuxt/app/pages/formulaires/[slug].vue` : générer un session_id unique (UUID stocké en sessionStorage), le transmettre au SurveyRenderer, afficher un message si l'utilisateur a déjà soumis (vérification locale via sessionStorage)

**Checkpoint**: Flux complet fonctionnel — créer, publier, remplir, soumettre. Anti-spam et email de confirmation opérationnels.

---

## Phase 5: User Story 3 — Consulter et analyser les réponses (Priority: P2)

**Goal**: Un gestionnaire peut visualiser les statistiques, parcourir les réponses individuelles et exporter en CSV

**Independent Test**: Après plusieurs soumissions, vérifier que les stats reflètent les données, que le tableau des réponses est filtrable, et que le CSV se télécharge correctement

### Backend US3

- [x] T030 [US3] Ajouter les méthodes au `SurveyService` dans `usenghor_backend/app/services/survey_service.py` : `get_responses(campaign_id, pagination, sort)` (paginé), `get_stats(campaign_id)` (agrégation JSONB : compteurs par question à choix, moyennes pour rating, distribution), `export_csv(campaign_id)` (extraction des clés du JSON, aplatissement en colonnes, StreamingResponse)
- [x] T031 [US3] Ajouter les endpoints dans `usenghor_backend/app/routers/admin/surveys.py` : `GET /{id}/responses` (paginé), `GET /{id}/stats`, `GET /{id}/export` (Content-Type: text/csv)

### Frontend US3

- [x] T032 [US3] Créer le composant `ResponseStats.vue` dans `usenghor_nuxt/app/components/survey/ResponseStats.vue` — affiche le nombre total de réponses, la date de la dernière réponse, et des graphiques de répartition pour chaque question à choix (camembert/barres). Utiliser Chart.js ou des barres CSS simples pour le MVP.
- [x] T033 [US3] Créer la page admin `usenghor_nuxt/app/pages/admin/campagnes/[id]/resultats.vue` — deux vues : "Statistiques" (composant ResponseStats) et "Réponses individuelles" (tableau paginé, filtrable, triable). Bouton "Exporter CSV" qui déclenche le téléchargement.

**Checkpoint**: Le gestionnaire peut exploiter les données collectées — stats visuelles, tableau détaillé, export CSV.

---

## Phase 6: User Story 4 — Gérer le cycle de vie d'une campagne (Priority: P2)

**Goal**: Un gestionnaire peut lister, filtrer, clôturer, dupliquer et supprimer ses campagnes

**Independent Test**: Créer plusieurs campagnes, vérifier les transitions de statut, dupliquer une campagne, supprimer avec confirmation

### Backend US4

- [x] T034 [US4] Ajouter les méthodes au `SurveyService` dans `usenghor_backend/app/services/survey_service.py` : `close_campaign(id, user_id)` (transition → closed), `duplicate_campaign(id, new_slug, user_id)` (copie survey_json, reset statut à draft, pas de réponses)
- [x] T035 [US4] Ajouter les endpoints dans `usenghor_backend/app/routers/admin/surveys.py` : `POST /{id}/close`, `POST /{id}/duplicate` (body: `{ slug }`)

### Frontend US4

- [x] T036 [US4] Créer la page admin `usenghor_nuxt/app/pages/admin/campagnes/index.vue` — liste paginée des campagnes du gestionnaire : colonnes (titre, statut via CampaignStatusBadge, nombre de réponses, date de création), recherche par texte, filtre par statut, tri par colonne. Actions par ligne : voir résultats, modifier, dupliquer, clôturer, supprimer. Modale de confirmation pour la suppression (avec avertissement sur les réponses). Bouton "Nouvelle campagne".

**Checkpoint**: Gestion complète du cycle de vie — le gestionnaire a une vue d'ensemble de ses campagnes.

---

## Phase 7: User Story 5 — Associer une campagne à un élément du site (Priority: P3)

**Goal**: Un gestionnaire peut lier une campagne à un événement, appel à candidature ou programme, et le formulaire s'affiche sur la page publique correspondante

**Independent Test**: Associer une campagne à un événement, vérifier que le formulaire apparaît sur la page de l'événement, retirer l'association et vérifier la disparition

### Backend US5

- [x] T037 [US5] Ajouter les méthodes au `SurveyService` dans `usenghor_backend/app/services/survey_service.py` : `get_associations(campaign_id)`, `create_association(campaign_id, entity_type, entity_id)`, `delete_association(association_id)`, `get_campaigns_by_entity(entity_type, entity_id)` (retourne les campagnes actives liées)
- [x] T038 [US5] Ajouter les endpoints admin dans `usenghor_backend/app/routers/admin/surveys.py` : `GET /{id}/associations`, `POST /{id}/associations`, `DELETE /{id}/associations/{association_id}`
- [x] T039 [P] [US5] Ajouter l'endpoint public `GET /by-entity/{entity_type}/{entity_id}` dans `usenghor_backend/app/routers/public/surveys.py` (route statique AVANT `/{slug}`)

### Frontend US5

- [x] T040 [US5] Ajouter une section "Associations" dans la page `usenghor_nuxt/app/pages/admin/campagnes/[id]/edit.vue` — sélecteur de type d'entité (événement, appel à candidature, programme), recherche de l'entité cible via les composables existants (useReferenceData), liste des associations existantes avec bouton de suppression
- [x] T041 [US5] Intégrer l'affichage des formulaires associés dans les pages publiques d'événements — dans la page concernée, appeler `getCampaignsByEntity('event', eventId)` via `usePublicSurveyApi`, et si des campagnes sont retournées, afficher le composant `SurveyRenderer` en bas de page

**Checkpoint**: Les campagnes peuvent être liées à des éléments du site et s'affichent automatiquement sur les pages publiques correspondantes.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Améliorations transverses et finitions

- [x] T042 [P] Créer le fichier `usenghor_nuxt/app/assets/css/survey-theme.css` — thème SurveyJS personnalisé avec CSS variables brand-blue (#1e3a5f) et brand-red (#c0392b), support dark mode, ajustements RTL
- [x] T043 [P] Ajouter la clôture automatique des campagnes : dans le backend, implémenter un check au moment de l'accès public (`GET /{slug}`) — si `closes_at` est dépassé et statut encore `active`, passer automatiquement à `closed`
- [x] T044 Ajouter le lien "Campagnes" dans la navigation admin (sidebar) dans le layout admin existant, conditionné par la permission `survey.manage`
- [x] T045 Valider le flux complet en suivant `specs/008-survey-campaigns/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)** : Pas de dépendances — peut commencer immédiatement
- **Foundational (Phase 2)** : Dépend de Phase 1 (T005 migration appliquée) — BLOQUE toutes les user stories
- **US1 (Phase 3)** : Dépend de Phase 2
- **US2 (Phase 4)** : Dépend de Phase 3 (nécessite le formulaire public et le SurveyRenderer)
- **US3 (Phase 5)** : Dépend de Phase 4 (nécessite des réponses en base pour tester les stats)
- **US4 (Phase 6)** : Dépend de Phase 2 (peut être fait en parallèle avec US3)
- **US5 (Phase 7)** : Dépend de Phase 3 (nécessite les campagnes et le rendu public)
- **Polish (Phase 8)** : Dépend de toutes les phases précédentes souhaitées

### User Story Dependencies

```
Phase 1 (Setup) → Phase 2 (Foundational)
                      │
                      ├── Phase 3 (US1: Créer & publier) ──→ Phase 4 (US2: Répondre) ──→ Phase 5 (US3: Stats)
                      │                                                                        │
                      ├── Phase 6 (US4: Cycle de vie) ─────────────────────────────────────────┤
                      │                                                                        │
                      └── Phase 7 (US5: Associations) ── après US1 ────────────────────────────┤
                                                                                               │
                                                                                        Phase 8 (Polish)
```

### Within Each User Story

- Backend avant frontend (les endpoints doivent exister avant les pages)
- Modèles/Service avant routeurs
- Composants avant pages (les pages utilisent les composants)

### Parallel Opportunities

- **Phase 1** : T002 + T003 + T006 en parallèle
- **Phase 2** : T011 + T012 + T013 en parallèle (composables frontend pendant que le backend T010 se termine)
- **Phase 3** : T016 en parallèle avec T014 (routeurs public et admin)
- **Phase 4** : T026 en parallèle avec T024 (template email pendant le service)
- **Phase 6** : Peut être fait en parallèle avec Phase 5 (pas de dépendance directe)
- **Phase 8** : T042 + T043 en parallèle

---

## Parallel Example: Phase 2 (Foundational)

```bash
# Séquentiels (dépendances) :
T007 → T008 → T009 → T010

# En parallèle avec T010 (fichiers frontend différents) :
T011: "Créer useAdminSurveyApi dans usenghor_nuxt/app/composables/useAdminSurveyApi.ts"
T012: "Créer usePublicSurveyApi dans usenghor_nuxt/app/composables/usePublicSurveyApi.ts"
T013: "Créer CampaignStatusBadge dans usenghor_nuxt/app/components/survey/CampaignStatusBadge.vue"
```

## Parallel Example: Phase 3 (US1)

```bash
# Backend en parallèle :
T014: "Routeur admin surveys.py"
T016: "Routeur public surveys.py"

# Frontend (après backend) — composants en parallèle :
T018: "QuestionBuilder.vue"
T022: "SurveyRenderer.client.vue"

# Pages (après composants) — en parallèle :
T020: "Page nouveau.vue"
T023: "Page [slug].vue"
```

---

## Implementation Strategy

### MVP First (US1 + US2 uniquement)

1. Phase 1: Setup (T001–T006)
2. Phase 2: Foundational (T007–T013)
3. Phase 3: US1 — Créer & publier (T014–T023)
4. Phase 4: US2 — Répondre (T024–T029)
5. **STOP et VALIDER** : Flux complet créer → publier → remplir → soumettre
6. Déployer si prêt

### Incremental Delivery

1. Setup + Foundational → Fondations prêtes
2. US1 → Formulaires créés et publiés (MVP de construction)
3. US2 → Soumissions fonctionnelles (MVP complet)
4. US3 → Stats et export CSV (remplacement Google Forms complet)
5. US4 → Gestion avancée (liste, duplication, cycle de vie)
6. US5 → Associations avec éléments du site
7. Chaque incrément ajoute de la valeur sans casser les précédents

---

## Notes

- [P] = fichiers différents, pas de dépendances
- [Story] = associe la tâche à une user story pour traçabilité
- Chaque user story est testable indépendamment après son checkpoint
- Les chemins font référence aux fichiers réels du monorepo
- Commiter après chaque tâche ou groupe logique
