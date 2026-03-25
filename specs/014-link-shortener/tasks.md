# Tasks: Réducteur de liens (backoffice admin)

**Input**: Design documents from `/specs/014-link-shortener/`
**Prerequisites**: plan.md, spec.md, data-model.md, contracts/api.md, research.md, quickstart.md

**Tests**: Non demandés — aucune tâche de test générée.

**Organization**: Tâches groupées par user story (US1-US4) pour permettre une implémentation et un test indépendants de chaque story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut s'exécuter en parallèle (fichiers différents, pas de dépendances)
- **[Story]**: User story associée (US1, US2, US3, US4)
- Chemins exacts inclus dans chaque description

---

## Phase 1: Setup (Infrastructure partagée)

**Purpose**: Schéma SQL et migration de base de données

- [x] T001 Créer le fichier SQL du schéma avec les tables `short_links`, `allowed_domains` et la séquence `short_link_counter_seq` dans `usenghor_backend/documentation/modele_de_données/services/13_short_links.sql`
- [x] T002 Créer le fichier de migration SQL dans `usenghor_backend/documentation/modele_de_données/migrations/013_short_links.sql`
- [x] T003 Ajouter l'inclusion `\i 13_short_links.sql` dans `usenghor_backend/documentation/modele_de_données/services/main.sql`
- [x] T004 Exécuter la migration SQL sur la base locale : `docker exec -i usenghor_postgres psql -U usenghor -d usenghor < usenghor_backend/documentation/modele_de_données/migrations/013_short_links.sql`

---

## Phase 2: Foundational (Prérequis bloquants)

**Purpose**: Modèles, schémas, service de base et câblage des routers — DOIT être terminé avant toute user story

**⚠️ CRITICAL**: Aucun travail sur les user stories ne peut commencer avant la fin de cette phase

- [x] T005 [P] Créer les modèles SQLAlchemy `ShortLink` et `AllowedDomain` (avec `UUIDMixin`, `TimestampMixin`) dans `usenghor_backend/app/models/short_links.py`
- [x] T006 [P] Créer les schémas Pydantic (`ShortLinkCreate`, `ShortLinkRead`, `ShortLinkPublicResolve`, `AllowedDomainCreate`, `AllowedDomainRead`) dans `usenghor_backend/app/schemas/short_links.py`
- [x] T007 Créer le squelette du service `ShortLinkService` avec la fonction utilitaire `int_to_base36(n: int) -> str` (alphabet `0123456789abcdefghijklmnopqrstuvwxyz`) dans `usenghor_backend/app/services/short_links_service.py`
- [x] T008 Enregistrer les modèles `ShortLink` et `AllowedDomain` dans `usenghor_backend/app/models/__init__.py`
- [x] T009 [P] Créer le squelette du router admin (fichier vide avec le prefix `/short-links`) dans `usenghor_backend/app/routers/admin/short_links.py` et l'enregistrer dans `usenghor_backend/app/routers/admin/__init__.py`
- [x] T010 [P] Créer le squelette du router public (fichier vide avec le prefix `/short-links`) dans `usenghor_backend/app/routers/public/short_links.py` et l'enregistrer dans `usenghor_backend/app/routers/public/__init__.py`

**Checkpoint**: Fondation prête — le backend démarre sans erreur, les tables existent en base

---

## Phase 3: User Story 1 — Créer un lien réduit (Priority: P1) 🎯 MVP

**Goal**: Un admin saisit une URL de destination, le système génère un code court base 36 et retourne le lien réduit complet

**Independent Test**: Créer un lien via Swagger (`POST /api/admin/short-links`), vérifier que le code court est retourné et que l'entrée est en base

### Implementation for User Story 1

- [x] T011 [US1] Implémenter `ShortLinkService.create_short_link()` dans `usenghor_backend/app/services/short_links_service.py` : appel `nextval('short_link_counter_seq')` via `text()` SQLAlchemy, conversion base 36, validation de l'URL (non vide, format valide, pas de `/r/...`, domaine autorisé si externe), insertion en base. Gérer l'erreur de capacité maximale (1 679 616)
- [x] T012 [US1] Implémenter `ShortLinkService.validate_target_url()` dans `usenghor_backend/app/services/short_links_service.py` : vérifier URL interne (commence par `/`) ou domaine externe dans `allowed_domains`, rejeter les URLs `/r/...`
- [x] T013 [US1] Implémenter l'endpoint `POST /api/admin/short-links` dans `usenghor_backend/app/routers/admin/short_links.py` : accepte `ShortLinkCreate` (contient `target_url`), appelle le service, retourne `IdResponse` avec status 201. Inclure les dépendances `CurrentUser`, `DbSession`, `PermissionChecker("short_links.create")`

**Checkpoint**: US1 fonctionnelle — un lien peut être créé via Swagger et vérifié en base

---

## Phase 4: User Story 2 — Redirection publique via lien réduit (Priority: P1)

**Goal**: Un visiteur accédant à `/r/{code}` est redirigé (HTTP 302) vers l'URL de destination

**Independent Test**: Créer un lien (US1), puis accéder à `http://localhost:3000/r/{code}` dans le navigateur et vérifier la redirection

### Implementation for User Story 2

- [x] T014 [US2] Implémenter `ShortLinkService.get_by_code()` dans `usenghor_backend/app/services/short_links_service.py` : lookup par `code`, retourner `ShortLink` ou `None`
- [x] T015 [US2] Implémenter l'endpoint `GET /api/public/short-links/{code}` dans `usenghor_backend/app/routers/public/short_links.py` : appelle `get_by_code()`, retourne `{ "target_url": "..." }` ou 404
- [x] T016 [US2] Créer le server route Nuxt `usenghor_nuxt/server/routes/r/[code].get.ts` : appelle le backend public (`/api/public/short-links/{code}`) via `$fetch` ou `fetch` interne, retourne `sendRedirect(event, target_url, 302)` si trouvé, `createError({ statusCode: 404 })` sinon

**Checkpoint**: US2 fonctionnelle — la redirection `/r/{code}` fonctionne de bout en bout dans le navigateur

---

## Phase 5: User Story 3 — Visualiser la liste des liens réduits (Priority: P2)

**Goal**: L'admin voit la liste paginée de tous les liens réduits avec code, URL, date de création

**Independent Test**: Accéder à `http://localhost:3000/admin/liens-courts` et vérifier que les liens créés apparaissent dans la liste

### Implementation for User Story 3

- [x] T017 [US3] Implémenter `ShortLinkService.list_short_links()` dans `usenghor_backend/app/services/short_links_service.py` : query paginée avec filtre `search` optionnel sur `code` et `target_url`, jointure sur `users` pour `created_by_name`
- [x] T018 [US3] Implémenter l'endpoint `GET /api/admin/short-links` dans `usenghor_backend/app/routers/admin/short_links.py` : pagination (`page`, `limit`), filtre `search`, retourne la liste avec `full_short_url` calculé (`https://usenghor-francophonie.org/r/{code}`)
- [x] T019 [P] [US3] Implémenter les endpoints de gestion des domaines autorisés dans `usenghor_backend/app/routers/admin/short_links.py` : `GET /allowed-domains` (liste), `POST /allowed-domains` (ajout), `DELETE /allowed-domains/{id}` (suppression). IMPORTANT : déclarer ces routes statiques AVANT les routes dynamiques `/{id}`
- [x] T020 [US3] Créer le composable `useShortLinksApi()` dans `usenghor_nuxt/app/composables/useShortLinksApi.ts` : fonctions `listShortLinks()`, `createShortLink()`, `deleteShortLink()`, `listAllowedDomains()`, `addAllowedDomain()`, `removeAllowedDomain()` via `useApi().apiFetch()`
- [x] T021 [US3] Créer la page admin `usenghor_nuxt/app/pages/admin/liens-courts/index.vue` : layout admin, tableau des liens (code, URL destination, URL courte copiable, date, auteur), état vide, barre de recherche, formulaire de création en modale, bouton copier le lien complet (Clipboard API), section de gestion des domaines autorisés (liste + ajout + suppression)
- [x] T022 [P] [US3] Créer les fichiers i18n trilingues `usenghor_nuxt/i18n/locales/fr/short-links.json`, `usenghor_nuxt/i18n/locales/en/short-links.json`, `usenghor_nuxt/i18n/locales/ar/short-links.json` avec les clés : titre, description, labels de tableau, messages de succès/erreur, labels de formulaire
- [x] T023 [P] [US3] Importer les fichiers i18n dans les index respectifs : `usenghor_nuxt/i18n/locales/fr/index.ts`, `usenghor_nuxt/i18n/locales/en/index.ts`, `usenghor_nuxt/i18n/locales/ar/index.ts`
- [x] T024 [US3] Ajouter l'entrée "Liens courts" dans le menu sidebar admin dans `usenghor_nuxt/app/composables/useAdminSidebar.ts` : id `short-links`, icon `fa-solid fa-link`, route `/admin/liens-courts`, permission `short_links.view`

**Checkpoint**: US3 fonctionnelle — la page admin affiche la liste, permet de créer des liens et de gérer les domaines autorisés

---

## Phase 6: User Story 4 — Supprimer un lien réduit (Priority: P3)

**Goal**: L'admin peut supprimer un lien réduit avec confirmation. Le compteur ne recule pas.

**Independent Test**: Supprimer un lien depuis la page admin, vérifier qu'il disparaît de la liste et que `/r/{code}` renvoie 404

### Implementation for User Story 4

- [x] T025 [US4] Implémenter `ShortLinkService.delete_short_link()` dans `usenghor_backend/app/services/short_links_service.py` : suppression physique par ID, lever `NotFoundException` si inexistant
- [x] T026 [US4] Implémenter l'endpoint `DELETE /api/admin/short-links/{id}` dans `usenghor_backend/app/routers/admin/short_links.py` : appelle le service, retourne `MessageResponse`
- [x] T027 [US4] Ajouter la modale de confirmation de suppression et le handler `deleteShortLink()` dans `usenghor_nuxt/app/pages/admin/liens-courts/index.vue`

**Checkpoint**: US4 fonctionnelle — suppression avec confirmation, le lien n'est plus accessible via `/r/{code}`

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Finalisation, validation des edge cases et permissions

- [x] T028 Ajouter les permissions `short_links.view`, `short_links.create`, `short_links.delete` dans les données initiales (seed) ou via la migration SQL dans `usenghor_backend/documentation/modele_de_données/migrations/013_short_links.sql`
- [x] T029 Validation complète des edge cases : tester URL vide, URL invalide, URL `/r/...` (boucle), domaine externe non autorisé, capacité maximale atteinte — vérifier les messages d'erreur explicites via Swagger
- [x] T030 Validation de bout en bout : créer un lien depuis la page admin, copier l'URL, accéder via `/r/{code}`, vérifier la redirection, supprimer le lien, vérifier la 404

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Aucune dépendance — peut commencer immédiatement
- **Foundational (Phase 2)**: Dépend de Phase 1 (SQL exécuté) — BLOQUE toutes les user stories
- **US1 (Phase 3)**: Dépend de Phase 2
- **US2 (Phase 4)**: Dépend de Phase 2 (+ US1 pour avoir un lien à tester)
- **US3 (Phase 5)**: Dépend de Phase 2 (+ US1 pour avoir des données à lister)
- **US4 (Phase 6)**: Dépend de Phase 5 (la page admin doit exister avec la liste)
- **Polish (Phase 7)**: Dépend de toutes les phases précédentes

### User Story Dependencies

- **US1 (P1 - Créer)**: Après Phase 2 — indépendante
- **US2 (P1 - Rediriger)**: Après Phase 2 — indépendante (mais a besoin de US1 pour tester)
- **US3 (P2 - Lister)**: Après Phase 2 — indépendante côté backend, mais la page frontend intègre aussi le formulaire de création (US1)
- **US4 (P3 - Supprimer)**: Après US3 (la page admin avec la liste doit exister)

### Within Each User Story

- Service avant router
- Router avant composable frontend
- Composable avant page
- Backend avant frontend

### Parallel Opportunities

- T005 et T006 (modèles et schémas) en parallèle
- T009 et T010 (squelettes routers admin et public) en parallèle
- T019 et T020 (domaines autorisés backend + composable frontend) partiellement en parallèle
- T022 et T023 (fichiers i18n) en parallèle avec T021 (page admin)

---

## Parallel Example: Phase 2 (Foundational)

```bash
# Lancer en parallèle :
Task: T005 "Créer modèles SQLAlchemy dans usenghor_backend/app/models/short_links.py"
Task: T006 "Créer schémas Pydantic dans usenghor_backend/app/schemas/short_links.py"

# Puis en parallèle :
Task: T009 "Squelette router admin dans usenghor_backend/app/routers/admin/short_links.py"
Task: T010 "Squelette router public dans usenghor_backend/app/routers/public/short_links.py"
```

## Parallel Example: Phase 5 (US3 - Liste)

```bash
# Lancer en parallèle :
Task: T022 "Fichiers i18n trilingues"
Task: T023 "Import i18n dans les index"
Task: T024 "Entrée sidebar admin"
# (pendant que T021 - page admin - est en cours)
```

---

## Implementation Strategy

### MVP First (US1 + US2)

1. Phase 1: Setup (SQL) → ~1 tâche
2. Phase 2: Foundational (modèles, schémas, service) → ~6 tâches
3. Phase 3: US1 - Créer un lien → ~3 tâches
4. Phase 4: US2 - Redirection publique → ~3 tâches
5. **STOP et VALIDER** : créer un lien via Swagger, vérifier la redirection dans le navigateur
6. Déployer si prêt

### Incremental Delivery

1. Setup + Foundational → Fondation prête
2. US1 (Créer) → Tester via Swagger → Premier incrément fonctionnel
3. US2 (Rediriger) → Tester redirection navigateur → MVP complet
4. US3 (Lister) → Page admin fonctionnelle → Interface de gestion
5. US4 (Supprimer) → CRUD complet → Feature terminée
6. Polish → Validation edge cases → Prêt pour la production

---

## Notes

- [P] = fichiers différents, pas de dépendances
- [USx] = associe la tâche à une user story spécifique
- Le fichier `index.vue` de la page admin est construit incrémentalement : formulaire (US1/US3), liste (US3), suppression (US4)
- La conversion base 36 utilise l'alphabet standard `0-9a-z` (pas `a-z` en premier)
- Le domaine de production pour les liens copiés est `https://usenghor-francophonie.org`
- Les routes statiques (`/allowed-domains`) DOIVENT être déclarées avant les routes dynamiques (`/{id}`) dans le router FastAPI
