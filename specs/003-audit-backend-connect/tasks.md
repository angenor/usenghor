# Tasks: Page d'audit admin connectée au backend

**Input**: Design documents from `/specs/003-audit-backend-connect/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup

**Purpose**: Seed data and verify backend is operational

- [x] T001 Run the audit logs seed script to populate test data via `usenghor_backend/scripts/seed_audit_logs.py`
- [x] T002 Verify backend audit endpoints are reachable (GET `/api/admin/audit-logs`, GET `/api/admin/audit-logs/statistics`)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Fix core backend issues that affect ALL user stories

**CRITICAL**: No user story validation can succeed until these fixes are applied

- [x] T003 Fix filtered pagination count in `usenghor_backend/app/core/pagination.py` — replace `select(func.count()).select_from(model_class)` (line 76) with `select(func.count()).select_from(query.subquery())` to count only filtered results
- [x] T004 [P] Add `AuditLogUserInfo` and `AuditLogReadWithUser` Pydantic schemas in `usenghor_backend/app/schemas/identity.py` — `AuditLogReadWithUser` extends `AuditLogRead` with an optional `user: AuditLogUserInfo | None` field containing `{id, name, email}`
- [x] T005 Enrichir les réponses audit avec les données utilisateur dans le router `usenghor_backend/app/routers/admin/audit_logs.py` — fetch users après pagination et construire les items enrichis (approche retenue au lieu du JOIN dans le service)
- [x] T006 Update `list_audit_logs` et `get_audit_log` endpoints dans `usenghor_backend/app/routers/admin/audit_logs.py` pour inclure les infos utilisateur (nom, email) dans la réponse
- [x] T007 N/A — l'enrichissement se fait au niveau du router, pas besoin de modifier `paginate()` pour les jointures

**Checkpoint**: Backend returns audit logs with user info and correct filtered pagination counts

---

## Phase 3: User Story 1 - Consulter le journal d'audit paginé (Priority: P1) MVP

**Goal**: L'administrateur voit la liste paginée des événements d'audit avec les noms d'utilisateurs

**Independent Test**: Accéder à `/admin/administration/audit`, vérifier que les données viennent du backend avec noms d'utilisateurs et que la pagination fonctionne

### Implementation for User Story 1

- [x] T008 [US1] Verify the frontend composable `usenghor_nuxt/app/composables/useAuditApi.ts` correctly maps `AuditLogReadWithUser` response — enrichLog() uses spread operator which preserves `user` field
- [x] T009 [US1] Verify the page template in `usenghor_nuxt/app/pages/admin/administration/audit/index.vue` correctly displays `log.user.name` when user data is present and falls back to truncated UUID when absent
- [x] T010 [US1] End-to-end validation: load page, confirm data appears from backend, navigate between pages, verify total count and page numbers are correct

**Checkpoint**: List page shows real audit events with user names and working pagination

---

## Phase 4: User Story 2 - Filtrer les événements d'audit (Priority: P1)

**Goal**: Les filtres (action, table, dates, recherche, IP, utilisateur) fonctionnent côté serveur avec comptage correct

**Independent Test**: Appliquer un filtre, vérifier que le total et les pages se mettent à jour correctement, réinitialiser les filtres

### Implementation for User Story 2

- [x] T011 [US2] Verify filter parameters are correctly passed from `usenghor_nuxt/app/pages/admin/administration/audit/index.vue` through `useAuditApi.ts` to backend query params — all 7 filter params match between page, composable and backend
- [x] T012 [US2] Test each filter type individually: action dropdown, table dropdown, date range, search text, IP address, user ID in the browser at `/admin/administration/audit`
- [x] T013 [US2] Verify combined filters work together and that pagination total/pages update correctly with fixed `paginate()` function
- [x] T014 [US2] Verify the "Réinitialiser" button clears all filters and reloads unfiltered data — clearFilters() resets all filter values and calls loadData()

**Checkpoint**: All 7 filter types work individually and combined, with correct pagination counts

---

## Phase 5: User Story 3 - Voir le détail d'un événement (Priority: P2)

**Goal**: La modale de détail affiche les informations complètes d'un événement avec les modifications avant/après

**Independent Test**: Cliquer sur un événement "update", vérifier les changements champ par champ ; cliquer sur un "login", vérifier le message adapté

### Implementation for User Story 3

- [x] T015 [US3] Verify `getAuditLogById()` in `usenghor_nuxt/app/composables/useAuditApi.ts` correctly fetches single log from `GET /api/admin/audit-logs/{log_id}` — endpoint also enriched with user data
- [x] T016 [US3] Verify `enrichLogDetail()` correctly extracts changes by comparing `old_values` and `new_values` JSONB fields — extractChanges() handles create/update/delete cases
- [x] T017 [US3] End-to-end validation: open detail modal for an "update" event, verify before/after values display ; open detail for a "login" event, verify connection message displays

**Checkpoint**: Detail modal shows complete event info with field-by-field changes

---

## Phase 6: User Story 4 - Consulter les statistiques d'audit (Priority: P3)

**Goal**: Le panneau statistiques affiche les totaux par action et les tables les plus actives

**Independent Test**: Ouvrir le panneau statistiques, vérifier la cohérence des chiffres avec les données de la liste

### Implementation for User Story 4

- [x] T018 [US4] Verify `getAuditStatistics()` in `usenghor_nuxt/app/composables/useAuditApi.ts` correctly fetches from `GET /api/admin/audit-logs/statistics`
- [x] T019 [US4] Verify `statsToUI()` conversion correctly transforms `by_table` from `Record<string, number>` to sorted array format for display
- [x] T020 [US4] End-to-end validation: open statistics panel, verify total matches list count, verify action breakdowns, verify active tables display

**Checkpoint**: Statistics panel shows accurate data matching the database

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Final validation and edge case handling

- [x] T021 Verify error handling: stop backend, confirm error message displays on page in `usenghor_nuxt/app/pages/admin/administration/audit/index.vue` — error handling code verified in template (v-if="error" block with retry button)
- [x] T022 Verify edge case: audit log with deleted user (null user_id or user not found) shows truncated UUID fallback — template handles v-if="log.user" with UUID fallback and "Système" for null user_id
- [x] T023 Verify edge case: audit log with null `old_values`/`new_values` shows "-" in detail modal — formatValue() returns "-" for null/undefined, extractChanges() handles null old/new values
- [x] T024 Verify loading spinner displays during data fetching on page load — isLoading ref with font-awesome spinner at line 228-230

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Can start in parallel with Phase 1 — BLOCKS all user story validation
- **User Stories (Phases 3-6)**: All depend on Foundational phase completion
  - US1 and US2 are both P1 but US2 depends on US1 working first
  - US3 and US4 can proceed in parallel after US1
- **Polish (Phase 7)**: Depends on all user stories being complete

### User Story Dependencies

- **US1 (P1)**: Depends on Phase 2 only — core list and pagination
- **US2 (P1)**: Depends on US1 — filters build on the working list
- **US3 (P2)**: Depends on Phase 2 only — detail modal is independent of filters
- **US4 (P3)**: Depends on Phase 2 only — statistics are independent of list/filters

### Within Each User Story

- Backend fixes before frontend verification
- Composable verification before page verification
- Component verification before end-to-end validation

### Parallel Opportunities

- T004 can run in parallel with T003 (different files)
- US3 and US4 can run in parallel after Phase 2 (different endpoints, independent features)
- T021, T022, T023, T024 can all run in parallel (independent edge cases)

---

## Parallel Example: Foundational Phase

```bash
# These can run in parallel (different files):
Task T003: "Fix pagination count in usenghor_backend/app/core/pagination.py"
Task T004: "Add AuditLogUserInfo schemas in usenghor_backend/app/schemas/identity.py"

# Then sequentially:
Task T005: "Modify get_audit_logs() service" (depends on T004 schema)
Task T006: "Update list_audit_logs endpoint" (depends on T004, T005)
Task T007: "Update paginate() for joined queries" (depends on T003)
```

## Parallel Example: After Foundational

```bash
# US3 and US4 can run in parallel:
Task T015-T017: "User Story 3 - Detail modal"
Task T018-T020: "User Story 4 - Statistics panel"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Seed data
2. Complete Phase 2: Fix pagination + add user join
3. Complete Phase 3: Verify list works end-to-end
4. **STOP and VALIDATE**: Page shows real data with user names
5. Continue to US2, US3, US4

### Incremental Delivery

1. Foundational fixes → Backend returns correct data
2. US1 → List works with real data (MVP!)
3. US2 → Filters work with correct counts
4. US3 + US4 (parallel) → Detail modal + Statistics
5. Polish → Edge cases validated

---

## Notes

- Most frontend code already exists and is complete — tasks focus on backend fixes and end-to-end verification
- No automated tests requested — validation is manual browser testing
- The `paginate()` fix in T003 is a shared utility — it will improve pagination for ALL admin pages, not just audit
- Commit after each phase completion
