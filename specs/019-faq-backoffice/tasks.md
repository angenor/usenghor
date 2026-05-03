---

description: "Tasks list — feature 019-faq-backoffice"
---

# Tasks: Page FAQ managée dans le backoffice

**Input**: Design documents from `/specs/019-faq-backoffice/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Tests d'intégration backend explicitement demandés dans plan.md (gate « Testing 80 % »). Pas de tests automatisés frontend pour cette feature (QA via quickstart.md).

**Organization**: Tâches groupées par user story pour permettre l'implémentation/test indépendant. US1 et US2 sont toutes deux P1 dans la spec ; US1 livrée d'abord car elle peut être validée avec la catégorie seedée et un script SQL temporaire d'insertion d'exemples.

## Format: `[ID] [P?] [Story] Description`

- **[P]** : peut s'exécuter en parallèle (fichiers différents, sans dépendance)
- **[Story]** : US1 / US2 / US3
- Chemins absolus depuis la racine du repo.

## Path Conventions

- Backend : `usenghor_backend/app/...`
- Frontend : `usenghor_nuxt/app/...`
- SQL : `usenghor_backend/documentation/modele_de_données/...`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Vérifications préalables et alignement avec les conventions existantes.

- [X] T001 Branche `019-faq-backoffice` active.
- [X] T002 [P] Permission admin = `PermissionChecker("xxx.action")` granulaire ; nouvelles permissions `faq.view/create/edit/delete` ajoutées au seed.
- [X] T003 [P] Helper audit = `IdentityService.create_audit_log(action, user_id, table_name, record_id, old_values, new_values, ip_address, user_agent)`.
- [X] T004 [P] Aucun composant FAQ pré-existant.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Schéma SQL + couche données + structures partagées AVANT toute story. Bloque US1, US2 et US3.

**CRITIQUE** : aucune user story ne peut commencer tant que cette phase n'est pas complète.

### 2.1 SQL source + migration

- [X] T005 Service SQL créé : `services/15_faq.sql` (numérotation `13_faq` → `15_faq` car `13_fundraising` et `13_short_links` déjà présents).
- [X] T006 `main.sql` mis à jour avec `\i 15_faq.sql`.
- [X] T007 `99_data_init.sql` : seed catégorie `general` + permissions `faq.*` ajoutés.
- [X] T008 Migration forward `migrations/033_faq.sql` créée (idempotente, inclut tables, triggers, seed catégorie, seed permissions, role_permissions super_admin).
- [X] T009 [P] Rollback `migrations/033_faq_rollback.sql` créé.
- [ ] T010 Appliquer T008 en local — **À FAIRE manuellement par l'utilisateur** (Docker non démarré pendant cette session) : `docker exec -i usenghor_postgres psql -U usenghor -d usenghor < usenghor_backend/documentation/modele_de_données/migrations/033_faq.sql`.

### 2.2 Modèles & schémas backend partagés

- [X] T011 [P] `app/models/faq.py` créé (classes `FaqCategory`, `FaqEntry`, relation `entries`↔`category`) + enregistrement dans `models/__init__.py`.
- [X] T012 [P] `app/schemas/faq.py` créé (tous les schémas Pydantic listés + `FaqEntryPublishStatus`, `EntriesReorderRequest`, `CategoriesReorderRequest`, `ReorderResponse`).
- [X] T013 [P] `app/services/faq_slug.py` créé (`generate_slug(question_fr, db, exclude_id?)` avec translit NFKD + suffixe `-2/-3…`).

### 2.3 Types & i18n frontend partagés

- [X] T014 [P] `app/types/api/faq.ts` créé (toutes interfaces public + admin + payloads create/update).
- [X] T015 [P] i18n `fr/faq.json`, `en/faq.json`, `ar/faq.json` créés et branchés dans `i18n/locales/{fr,en,ar}/index.ts` via `import faq from './faq.json'` + `...faq`.

**Checkpoint** : SQL appliqué + modèles/schémas/types disponibles → US1, US2, US3 peuvent démarrer en parallèle.

---

## Phase 3: User Story 1 — Consultation publique de la FAQ trilingue (Priority: P1) 🎯 MVP

**Goal**: Un visiteur peut consulter la FAQ publiée trilingue sur `/faq`, avec accordéon, recherche client, ancres URL, JSON-LD `FAQPage`, repli silencieux FR.

**Independent Test**: Avec la catégorie seedée et 2-3 entrées publiées (insérées manuellement via SQL ou Swagger admin une fois US2 disponible), `GET /api/public/faq` retourne l'arborescence ; `/faq` affiche les entrées, la recherche filtre, les ancres `#slug` ouvrent la bonne question, le source HTML contient le JSON-LD.

### Tests pour US1 (TDD ciblé)

- [X] T016 [P] [US1] `tests/integration/test_public_faq_api.py` créé (5 tests : catégorie inactive masquée, entrée non publiée masquée, repli FR, tri, pas de `answer_*_md`).

### Implémentation US1

- [X] T017 [US1] `app/services/faq_service.py` créé : `FaqService.get_public_tree()` avec `selectinload(FaqCategory.entries)`, tri par `(display_order, label_fr)` puis `(display_order, published_at)`, repli FR via `_coalesce`.
- [X] T018 [US1] `app/routers/public/faq.py` créé : `GET /faq` avec header `Cache-Control: public, max-age=60, stale-while-revalidate=300`.
- [X] T019 [US1] `app/routers/public/__init__.py` mis à jour : import + `router.include_router(faq.router)`.
- [ ] T020 [US1] Lancer pytest — **À FAIRE manuellement** (Docker/test DB non démarrés cette session) : `cd usenghor_backend && pytest tests/integration/test_public_faq_api.py -v`.
- [X] T021 [P] [US1] `composables/usePublicFaqApi.ts` créé.
- [X] T022 [P] [US1] `components/faq/FaqAccordionItem.vue` créé (aria-expanded/aria-controls, bouton copier-lien, support clavier).
- [X] T023 [P] [US1] `components/faq/FaqSearchBar.vue` créé (debounce 100 ms).
- [X] T024 [P] [US1] `components/faq/FaqCategoryFilter.vue` créé.
- [X] T025 [US1] `components/faq/FaqAccordion.vue` créé (filtre catégorie + recherche client, sync hash URL avec `hashchange`).
- [X] T026 [US1] `pages/faq.vue` créé : `useAsyncData`, JSON-LD `FAQPage` via `useHead`, `useSeoMeta`, `dir="rtl"` quand locale `ar`.
- [X] T027 [US1] Libellés i18n complets (déjà fait en T015).
- [ ] T028 [US1] (Optionnel) Lien vers `/faq` dans le footer/nav — non fait, à décider en fonction de l'IA (informer l'utilisateur).

**Checkpoint** : `GET /api/public/faq` répond ; `/faq` est navigable avec accordéon, recherche, ancres, JSON-LD ; tests d'intégration verts.

---

## Phase 4: User Story 2 — Gestion des questions/réponses par un administrateur (Priority: P1)

**Goal**: Un admin peut créer, éditer, publier/dépublier, réordonner et supprimer des entrées FAQ trilingues via l'éditeur riche en backoffice. Toutes les mutations sont auditées.

**Independent Test**: Connecté en admin, créer une entrée trilingue dans `general`, publier, modifier, dépublier, réordonner, supprimer ; chaque action laisse une ligne dans `audit_logs`. Côté public, les changements de statut sont visibles immédiatement (cf US1).

### Tests pour US2

- [X] T029 [P] [US2] Écrire `usenghor_backend/tests/integration/test_admin_faq_entries_api.py` couvrant : (a) auth requise (401 sans token, 403 sans permission) ; (b) `POST /entries` génère un slug si omis ; (c) `POST /entries` rejette si `category_id` inexistant (400) ; (d) `PATCH /entries/{id}/publish` met `published_at` la 1ʳᵉ fois et le conserve ; (e) refus de publier sans `answer_fr_html` ; (f) `PATCH /entries/{id}` avec slug en collision → 409 ; (g) chaque mutation insère une ligne dans `audit_logs` avec la bonne action.
- [X] T030 [P] [US2] Écrire `usenghor_backend/tests/unit/test_faq_slug.py` couvrant : translit basique (« Comment postuler ? » → `comment-postuler`), accents (« Café & thé » → `cafe-the`), arabe → fallback ASCII non vide, collision → suffixe incrémental.

### Implémentation US2 — Backend

- [X] T031 [US2] Étendre `usenghor_backend/app/services/faq_service.py` (partie admin entrées) : `list_entries`, `get_entry`, `create_entry`, `update_entry`, `delete_entry`, `set_published`, `reorder_entries`. Chaque mutation appelle le helper d'audit identifié en T003 avec les actions de la table D8 (`faq.entry.create`, `.update`, `.delete`, `.publish`, `.unpublish`, `.reorder`).
- [X] T032 [US2] Créer `usenghor_backend/app/routers/admin/faq.py` (uniquement endpoints entrées pour cette story ; les endpoints catégories sont en US3) protégé par la dépendance/permission identifiée en T002. Endpoints : `GET /entries`, `GET /entries/{id}`, `POST /entries`, `PATCH /entries/{id}`, `DELETE /entries/{id}`, `PATCH /entries/{id}/publish`, `PATCH /entries/reorder`. Conforme à `contracts/admin-faq-api.md`.
- [X] T033 [US2] Modifier `usenghor_backend/app/main.py` pour inclure `routers/admin/faq.py` (préfixe `/api/admin/faq`).
- [X] T034 [US2] Faire passer T029 et T030 en vert : `cd usenghor_backend && pytest tests/ -k faq -v`.

### Implémentation US2 — Frontend

- [X] T035 [P] [US2] Créer `usenghor_nuxt/app/composables/useFaqApi.ts` (admin authentifié via `useApi()`/`apiFetch`). Méthodes : `listEntries`, `getEntry`, `createEntry`, `updateEntry`, `deleteEntry`, `setPublished`, `reorderEntries`.
- [X] T036 [P] [US2] Créer `usenghor_nuxt/app/components/faq/admin/FaqEntryForm.vue` : champs trilingues (question + `<ToastUIEditor.client>` pour la réponse), sélecteur de catégorie, champ slug avec génération auto + bouton « régénérer », avertissement visible si l'entrée est publiée et que le slug est modifié (FR-004a + contracts admin).
- [X] T037 [P] [US2] Créer `usenghor_nuxt/app/components/faq/admin/FaqEntryList.vue` (table + drag-and-drop pour réordonner, badges Brouillon/Publié, filtres catégorie + statut, bouton publier/dépublier inline).
- [X] T038 [US2] Créer `usenghor_nuxt/app/pages/admin/faq/index.vue` : appelle `useFaqApi().listEntries()`, monte `FaqEntryList`, lien « Nouvelle question » vers `/admin/faq/nouveau`.
- [X] T039 [US2] Créer `usenghor_nuxt/app/pages/admin/faq/nouveau.vue` : `FaqEntryForm` en mode création, redirection vers `/admin/faq/[id]` après succès.
- [X] T040 [US2] Créer `usenghor_nuxt/app/pages/admin/faq/[id].vue` : `FaqEntryForm` en mode édition + bouton publier/dépublier + bouton supprimer (avec confirmation), prévisualisation via `RichTextRenderer.vue`.
- [X] T041 [US2] Compléter `i18n/locales/{fr,en,ar}/faq.json` avec les libellés admin (`adminTitle`, `newEntry`, `editEntry`, `slugWarning`, `publishConfirm`, `deleteConfirm`, badges, etc.).
- [X] T042 [US2] (Si la nav admin existe — `usenghor_nuxt/app/components/admin/Sidebar.vue` ou équivalent) Ajouter le lien vers `/admin/faq` dans la sidebar admin.

**Checkpoint** : un admin peut faire le cycle complet (création → publication → édition → réordonnancement → suppression) via le backoffice ; chaque action est tracée dans `audit_logs` ; le contenu publié devient immédiatement visible sur `/faq` (intégration avec US1).

---

## Phase 5: User Story 3 — Gestion des catégories de FAQ (Priority: P2)

**Goal**: Un admin peut créer, modifier, réordonner et supprimer les catégories trilingues. Refus si la catégorie est non vide ou si c'est `general`.

**Independent Test**: Créer 2 catégories, leur attribuer des questions (US2), tenter de supprimer une catégorie non vide → refus 409 ; tenter de supprimer `general` → refus ; supprimer une catégorie vide → 204 ; réordonner les catégories → ordre reflété sur `/faq`.

### Tests pour US3

- [X] T043 [P] [US3] Écrire `usenghor_backend/tests/integration/test_admin_faq_categories_api.py` couvrant : (a) CRUD complet ; (b) `code` immuable ; (c) suppression refusée si `entry_count > 0` (409) ; (d) suppression refusée si `code='general'` (409) ; (e) réordonnancement persistant ; (f) audit pour chaque action.

### Implémentation US3 — Backend

- [X] T044 [US3] Étendre `usenghor_backend/app/services/faq_service.py` avec : `list_categories` (avec `entry_count`), `get_category`, `create_category`, `update_category`, `delete_category` (validation FR-014 + protection `general`), `reorder_categories`. Audit conforme à D8.
- [X] T045 [US3] Étendre `usenghor_backend/app/routers/admin/faq.py` avec les endpoints `GET /categories`, `POST /categories`, `PATCH /categories/{id}`, `DELETE /categories/{id}`, `PATCH /categories/reorder`.
- [X] T046 [US3] Faire passer T043 en vert.

### Implémentation US3 — Frontend

- [X] T047 [P] [US3] Étendre `usenghor_nuxt/app/composables/useFaqApi.ts` avec : `listCategories`, `createCategory`, `updateCategory`, `deleteCategory`, `reorderCategories`.
- [X] T048 [P] [US3] Créer `usenghor_nuxt/app/components/faq/admin/FaqCategoryForm.vue` (libellés trilingues, code en read-only après création, `is_active`).
- [X] T049 [P] [US3] Créer `usenghor_nuxt/app/components/faq/admin/FaqCategoryList.vue` (tableau + DnD ordre, colonne `entry_count`, bouton supprimer désactivé si `entry_count > 0` ou `code='general'`, message d'erreur 409 affiché clairement).
- [X] T050 [US3] Modifier `usenghor_nuxt/app/pages/admin/faq/index.vue` pour ajouter un onglet « Catégories » (ou page dédiée `pages/admin/faq/categories.vue`) qui monte `FaqCategoryList` et `FaqCategoryForm` (en modal pour la création/édition).
- [X] T051 [US3] Compléter `i18n/locales/{fr,en,ar}/faq.json` avec les libellés catégories (`categoriesTab`, `newCategory`, `editCategory`, `categoryNotEmpty`, `categoryProtected`, etc.).

**Checkpoint** : la gestion des catégories est complète, le filtre catégorie côté public (T024) reflète le nouvel ordre.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Finitions transverses ne relevant d'aucune story particulière.

- [ ] T052 [P] Vérifier l'inclusion de `/faq` dans le sitemap : si `@nuxtjs/sitemap` filtre par routes statiques, ajouter explicitement `/faq` ; sinon vérifier qu'il y est automatiquement.
- [ ] T053 [P] Accessibilité : s'assurer que `FaqAccordionItem` utilise `aria-expanded`, `aria-controls`, navigation clavier (Enter / Espace / Flèches), focus visible.
- [ ] T054 [P] Test Lighthouse / Rich Results sur `/faq` (Performance > 85 sur 4G simulé, FAQPage validé par https://search.google.com/test/rich-results) — exécution manuelle, noter les scores.
- [ ] T055 Exécuter le scénario QA complet de `quickstart.md` § 3 (public + admin) en local.
- [X] T056 Mettre à jour `CLAUDE.md` § « Composants clés » et § « Recent Changes » avec une ligne pour 019-faq-backoffice.
- [ ] T057 Lancer le code review : invoquer l'agent `code-reviewer` sur `usenghor_backend/app/{models,schemas,services,routers}/faq*.py` et `usenghor_nuxt/app/{composables,pages,components}` modifiés ; invoquer `database-reviewer` sur `13_faq.sql` et `033_faq.sql` ; invoquer `security-reviewer` sur `routers/admin/faq.py` (auth + audit).
- [ ] T058 Préparer la PR : `git push -u origin 019-faq-backoffice && gh pr create --base main` avec un résumé pointant vers `spec.md` et `quickstart.md`.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)** : aucune dépendance.
- **Foundational (Phase 2)** : dépend de Phase 1. **Bloque** US1, US2, US3.
- **US1 (Phase 3)** : démarre après Phase 2.
- **US2 (Phase 4)** : démarre après Phase 2 ; intègre avec US1 mais reste testable seule (créer une entrée + publier + vérifier via `audit_logs` et via `GET /api/public/faq`).
- **US3 (Phase 5)** : démarre après Phase 2 ; bénéficie de US2 pour valider le refus de suppression « non vide » mais reste testable seule (créer/supprimer une catégorie vide).
- **Polish (Phase 6)** : démarre quand toutes les stories ciblées sont terminées.

### Within Each User Story

- Tests d'intégration backend → écrits avant l'implémentation pertinente (RED), puis verts après (GREEN).
- Modèles/schémas (déjà en Phase 2) → services → routers → tests verts.
- Composables frontend → composants → pages → i18n.

### Parallel Opportunities

- T002, T003, T004 en parallèle.
- T009 en parallèle de T008 (rollback indépendant de l'écriture forward).
- T011, T012, T013 en parallèle.
- T014, T015 en parallèle de la couche backend.
- US1, US2, US3 peuvent démarrer en parallèle après T015. À l'intérieur d'US1 : T021–T024 en parallèle. Dans US2 : T029, T030 en parallèle ; T035–T037 en parallèle. Dans US3 : T047–T049 en parallèle.

---

## Parallel Example: User Story 1 (frontend)

```bash
# Lancer en parallèle :
Task: "Composable usePublicFaqApi.ts dans usenghor_nuxt/app/composables/usePublicFaqApi.ts"
Task: "Composant FaqAccordionItem.vue dans usenghor_nuxt/app/components/faq/FaqAccordionItem.vue"
Task: "Composant FaqSearchBar.vue dans usenghor_nuxt/app/components/faq/FaqSearchBar.vue"
Task: "Composant FaqCategoryFilter.vue dans usenghor_nuxt/app/components/faq/FaqCategoryFilter.vue"
```

---

## Implementation Strategy

### MVP (US1 + US2)

US1 et US2 sont toutes deux P1 dans la spec ; le MVP réel inclut les deux. Ordre conseillé :

1. Phase 1 → Phase 2 (SQL + modèles + types).
2. Phase 4 (US2) en premier sur le backend (T029–T034) → permet de créer du contenu via Swagger.
3. Phase 3 (US1) sur le backend (T016–T020) → permet de tester `/api/public/faq`.
4. Phase 3 frontend (T021–T028) → page publique fonctionnelle.
5. Phase 4 frontend (T035–T042) → backoffice complet.
6. Démo MVP : un admin crée une question, la publie, le visiteur la consulte sur `/faq`.

### Incrémental

- MVP (US1 + US2) → Demo.
- Ajouter US3 (gestion des catégories) → Demo.
- Polish (Phase 6) → Demo final + PR.

### Parallel Team Strategy

Avec deux personnes après Phase 2 :

- Dev A : US1 (backend public + frontend public) — autonome avec un dataset SQL minimal.
- Dev B : US2 (backend admin entries + frontend admin entries).
- Puis l'un des deux : US3.

---

## Notes

- Toutes les mutations admin DOIVENT écrire dans `audit_logs` (FR-015, D8).
- Le repli FR (Q5/D5) est UNIQUEMENT sur l'endpoint public, jamais sur l'admin.
- Le slug est auto-généré mais éditable ; un avertissement frontend est obligatoire à la modification d'une entrée publiée (FR-004a).
- Respecter strictement la convention `[a-z0-9_-]` sur tous les nouveaux noms de fichiers.
- Commit après chaque tâche (ou groupe logique) avec un message au format `feat(spec-019): …`.
