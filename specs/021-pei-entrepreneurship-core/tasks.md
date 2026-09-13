---

description: "Liste des tâches d'implémentation — 021 Socle PEI"
---

# Tasks: Socle du Pôle Entrepreneuriat et Innovation (PEI)

**Input**: Design documents from `/specs/021-pei-entrepreneurship-core/`

**Prerequisites**: plan.md, spec.md, research.md (R1–R14), data-model.md (SQL §4–6), contracts/ (admin-api, public-api, editorial-keys, frontend), quickstart.md

**Tests**: Les tests backend `pytest` sont inclus (plan.md « Testing », research R13) et écrits dans la foulée de chaque story, sans approche TDD stricte. Aucun test frontend (pas d'infrastructure) : validation manuelle par quickstart.md.

**Organization**: Tâches groupées par user story (spec.md) dans l'ordre de priorité : US1 dispositifs (P1) → US2 cohortes (P2) → US3 ressources (P2) → US6 lecture publique (P2) → US4 tableau de bord (P3) → US5 page éditoriale (P3).

## Format: `[ID] [P?] [Story] Description`

- **[P]** : parallélisable (fichiers différents, aucune dépendance sur une tâche inachevée)
- **[Story]** : US1…US6 (spec.md)
- Chemins exacts depuis la racine du dépôt ; `BE` = `usenghor_backend/`, `FE` = `usenghor_nuxt/app/`, `SQL` = `usenghor_backend/documentation/modele_de_données/`

## Path Conventions

Monorepo : backend `usenghor_backend/app/{models,schemas,services,routers/admin,routers/public}` + `tests/{integration,unit}` ; frontend `usenghor_nuxt/app/{types/api,composables,components,pages/admin}`. Convention de colonnes **additive** (research R1) : `title`, `title_en`, `title_ar` ; `content_html`, `content_md`, `content_en_html`, `content_en_md`, `content_ar_html`, `content_ar_md`.

---

## Phase 1: Setup (SQL de référence et migration)

**Purpose**: Poser le schéma validé, rejouable, avant tout code applicatif (CLAUDE.md : accord → SQL → code).

- [X] T001 **Porte FR-005** — Présenter au responsable du projet le SQL de `specs/021-pei-entrepreneurship-core/data-model.md` §4 (tables, ENUM, contraintes `chk_pei_*`), §5 (migration, seeds) et §6 (rollback), ainsi que la convention additive (research R1) ; ne commencer T002 qu'après accord explicite, et reporter dans data-model.md toute modification demandée.
- [X] T002 [P] Créer `SQL/services/16_entrepreneurship.sql` en recopiant data-model.md §4 : `CREATE TYPE pei_program_phase AS ENUM ('awareness','status','pre_incubation','incubation','funding','ecosystem')`, `pei_cohort_type ('fse','see')`, `pei_resource_type ('document','link','video')` ; tables `pei_programs` (`code VARCHAR(60) UNIQUE NOT NULL` regex `^[a-z0-9][a-z0-9-]*$`, `title VARCHAR(200) NOT NULL` LENGTH ≥ 3, `color VARCHAR(20) NOT NULL DEFAULT 'blue'` CHECK IN ('blue','blue_dark','red','amber','teal'), `cover_image_external_id UUID` sans FK, `display_order INTEGER NOT NULL DEFAULT 0`, `active BOOLEAN NOT NULL DEFAULT TRUE`, `created_by`/`updated_by` FK users SET NULL), `pei_cohorts` (`year INTEGER NOT NULL` CHECK 2000–2100, `type pei_cohort_type NOT NULL`), `pei_resources` (`url VARCHAR(500)`, `is_published BOOLEAN NOT NULL DEFAULT FALSE`, `published_at TIMESTAMPTZ`, `chk_pei_resources_source`) ; index `idx_pei_programs_active_order`, `idx_pei_cohorts_active_order`, `idx_pei_cohorts_type_year`, `idx_pei_resources_published_order` ; `COMMENT ON TABLE` ×3 ; en-tête « SERVICE: ENTREPRENEURSHIP » sans BEGIN/COMMIT.
- [X] T003 Ajouter dans `SQL/services/main.sql` la ligne `\echo '[18/21] Service ENTREPRENEURSHIP (pôle PEI)...'` puis `\i 16_entrepreneurship.sql` juste après `\i 15_faq.sql` et avant `\i 99_functions.sql`.
- [X] T004 [P] Ajouter dans `SQL/services/99_data_init.sql`, dans le bloc `INSERT INTO permissions (code, name_fr, category)`, les 4 lignes `('entrepreneurship.view','Voir le pôle Entrepreneuriat','entrepreneurship')`, `('entrepreneurship.create','Créer des contenus du pôle Entrepreneuriat','entrepreneurship')`, `('entrepreneurship.edit','Modifier des contenus du pôle Entrepreneuriat','entrepreneurship')`, `('entrepreneurship.delete','Supprimer des contenus du pôle Entrepreneuriat','entrepreneurship')` avant le bloc « Administration » (le `role_permissions` global du super_admin les couvre) ; ajouter un `INSERT INTO role_permissions … WHERE r.code IN ('admin','editor') AND p.category = 'entrepreneurship' ON CONFLICT DO NOTHING`.
- [X] T005 Créer `SQL/migrations/045_entrepreneurship.sql` selon data-model.md §5 : en-tête commenté (contexte, effets, rollback), `BEGIN;`, 3 blocs `DO $$ BEGIN CREATE TYPE … EXCEPTION WHEN duplicate_object THEN NULL; END $$;`, tables et index de T002 en `IF NOT EXISTS`, 3 triggers `update_pei_<table>_updated_at` gardés par `IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = …)`, permissions (`INSERT INTO permissions (code, name_fr, description, category) … ON CONFLICT (code) DO NOTHING`) et attribution `FROM roles r, permissions p WHERE r.code IN ('super_admin','admin','editor') AND p.code IN (…) ON CONFLICT DO NOTHING`, seed des 5 dispositifs (`ON CONFLICT (code) DO NOTHING`, colonnes `code, sigle, title, phase, tagline, content_md, content_html, highlight, color, display_order` avec les valeurs du tableau §5.6 et les textes FR de `specs/maquettes-pei/accueil.html` section « Nos activités » ; SEE complété par `statut-etudiant-entrepreneur.html`), seed des 3 cohortes §5.7 (`fse-3` 2025 ordre 0, `fse-2` 2024 ordre 1, `fse-1` 2023 ordre 2), seed des 43 clés éditoriales de `contracts/editorial-keys.md` (`INSERT INTO editorial_contents (key, value, value_type, category_id, description) SELECT … (SELECT id FROM editorial_categories WHERE code = 'values') … ON CONFLICT (key) DO NOTHING`, `value_type` = `html` pour `entrepreneurship.presentation.content`, `text` ailleurs, images seedées `''`), clé `entrepreneurship.dde_service_id` par `COALESCE((SELECT id::text FROM services WHERE name ILIKE '%Développement et de l''Entrepreneuriat%' ORDER BY created_at LIMIT 1), '')`, `COMMIT;`, `\echo 'Migration 045_entrepreneurship terminée'`.
- [X] T006 [P] Créer `SQL/migrations/045_entrepreneurship_rollback.sql` : `BEGIN; DROP TABLE IF EXISTS pei_resources; DROP TABLE IF EXISTS pei_cohorts; DROP TABLE IF EXISTS pei_programs; DROP TYPE IF EXISTS pei_resource_type; DROP TYPE IF EXISTS pei_cohort_type; DROP TYPE IF EXISTS pei_program_phase; DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'entrepreneurship.%'); DELETE FROM permissions WHERE code LIKE 'entrepreneurship.%'; DELETE FROM editorial_contents WHERE key LIKE 'entrepreneurship.%'; COMMIT;`.
- [X] T007 Jouer la migration deux fois en local (`docker exec -i usenghor_postgres psql -U usenghor -d usenghor < 045_entrepreneurship.sql`), vérifier la requête de comptage de quickstart.md §1 (`5|3|4|43` après chaque passage), jouer le rollback puis rejouer ; corriger T005/T006 jusqu'à zéro erreur.

---

## Phase 2: Foundational (socle backend et frontend partagé)

**Purpose**: Modèles, squelettes de service/routeurs, types, permissions, navigation et deux composants transverses — prérequis de toutes les stories.

**⚠️ CRITICAL**: aucune story ne commence avant la fin de cette phase.

- [X] T008 Créer `BE/app/models/entrepreneurship.py` : enums `PeiProgramPhase`, `PeiCohortType`, `PeiResourceType` (`str, enum.Enum`) ; classes `PeiProgram`, `PeiCohort`, `PeiResource` (`Base, UUIDMixin, TimestampMixin` depuis `app.database` / `app.models.base`) avec toutes les colonnes de data-model.md §2 (types `String(n)`/`Text`/`Integer`/`Boolean`/`UUID(as_uuid=False)`), colonnes ENUM via `sqlalchemy.Enum(PeiProgramPhase, name="pei_program_phase", create_type=False, values_callable=lambda x: [e.value for e in x])`, `__table_args__` répliquant `chk_pei_programs_code`, `chk_pei_programs_title`, `chk_pei_programs_color`, `chk_pei_cohorts_code`, `chk_pei_cohorts_year`, `chk_pei_resources_source` ; `created_by`/`updated_by` `ForeignKey("users.id", ondelete="SET NULL")`.
- [X] T009 Exporter les 3 modèles et 3 enums dans `BE/app/models/__init__.py` (import explicite, nécessaire à `Base.metadata` des tests).
- [X] T010 Créer `BE/app/schemas/entrepreneurship.py` avec les schémas transverses : `ReorderRequest { ids: list[str] = Field(min_length=1) }`, `ReorderResponse { updated: int }`, `ActiveRequest { active: bool }`, `ActiveStatus { id, active, updated_at }` (`from_attributes=True`), `PublishRequest { is_published: bool }`, `PublishStatus { id, is_published, published_at, updated_at }`, générique de page `{ items, total, page, page_size }` (une classe par entité ajoutée dans sa story), `PeiDashboardStats`, `PeiTranslateMissingResponse { programs: int, cohorts: int, resources: int }` ; réexporter les enums Pydantic (`Literal` ou enums Python) `PeiColor = Literal['blue','blue_dark','red','amber','teal']`.
- [X] T011 Créer `BE/app/services/entrepreneurship_service.py` : constantes `_PROGRAM_TRANSLATABLE = [("title","text"),("tagline","text"),("highlight","text"),("content_html","html"),("content_md","text")]`, `_COHORT_TRANSLATABLE = [("label","text"),("focus","text"),("summary_html","html"),("summary_md","text")]`, `_RESOURCE_TRANSLATABLE = [("title","text"),("description","text"),("category","text")]` ; classe `EntrepreneurshipService(db)` avec helpers privés : `_audit(action, user_id, record_id, table_name, old_values, new_values, ip_address, user_agent)` → `IdentityService(self.db).create_audit_log(...)` ; `_next_display_order(model)` = `MAX(display_order)+1` ; `_reorder(model, ids, table_name, action, user_id, ip, ua)` : vérifie que `ids` couvre exactement tous les identifiants (422 `ValidationException` sinon), écrit `display_order = index`, compte les lignes changées, un seul audit `new_values={"ids": ids}`, `record_id=None` ; `_media_url(media: Media | None)` → `resolve_media_url` (`app.core.media_utils`).
- [X] T012 Créer `BE/app/routers/admin/entrepreneurship.py` : `router = APIRouter(prefix="/entrepreneurship", tags=["Entrepreneurship Admin"])`, helper `_client_meta(request)` (IP via `x-forwarded-for` sinon `request.client.host`, user-agent), imports `DbSession, CurrentUser, PermissionChecker` depuis `app.core.dependencies` ; l'enregistrer dans `BE/app/routers/admin/__init__.py` (import alphabétique + `router.include_router(entrepreneurship.router)`).
- [X] T013 Créer `BE/app/routers/public/entrepreneurship.py` : `router = APIRouter(prefix="/entrepreneurship", tags=["Entrepreneurship"])`, helper `_cache(response)` posant `Cache-Control: public, max-age=60, stale-while-revalidate=300` ; l'enregistrer dans `BE/app/routers/public/__init__.py`.
- [X] T014 [P] Créer `FE/types/api/entrepreneurship.ts` : types `PeiProgramPhase`, `PeiCohortType`, `PeiResourceType`, `PeiColor` ; interfaces `PeiProgramAdmin`, `PeiProgramCreatePayload`, `PeiProgramUpdatePayload` (Partial), `PeiProgramPublic`, `PeiCohortAdmin/CreatePayload/UpdatePayload/Public`, `PeiResourceAdmin/CreatePayload/UpdatePayload/Public`, `PeiPage<T> { items, total, page, page_size }`, `ReorderResponse`, `ActiveStatus`, `PublishStatus`, `PeiDashboardStats`, `PeiTranslateMissingResponse`, `PeiProgramTranslateRequest/Response` (et cohort/resource) — champs exactement ceux de `contracts/admin-api.md` et `contracts/public-api.md` (convention additive).
- [X] T015 [P] Ajouter dans `FE/composables/usePermissions.ts` l'entrée `'/admin/entrepreneuriat': ['entrepreneurship.view']` dans `ROUTE_PERMISSIONS` (couvre les sous-routes par préfixe).
- [X] T016 [P] Ajouter dans `FE/composables/useAdminSidebar.ts`, après la section `faq`, la section `entrepreneurship` de `contracts/frontend.md` (label « Entrepreneuriat (PEI) », icône `fa-solid fa-lightbulb`, `permissions: ['entrepreneurship.view']`, 4 enfants : Tableau de bord `/admin/entrepreneuriat`, Dispositifs du parcours `/admin/entrepreneuriat/dispositifs`, Cohortes `/admin/entrepreneuriat/cohortes`, Boîte à outils `/admin/entrepreneuriat/ressources`).
- [X] T017 Créer `FE/composables/useEntrepreneurshipApi.ts` sur `useApi().apiFetch` : exports de module `programPhaseOptions` / `programPhaseLabels` (awareness « Sensibilisation », status « Cadre / statut », pre_incubation « Pré-incubation », incubation « Incubation », funding « Amorçage », ecosystem « Écosystème »), `cohortTypeOptions` (fse « FSE », see « SEE »), `resourceTypeOptions` / `resourceTypeLabels` (document « Document », link « Lien », video « Vidéo »), `colorOptions` (`{ value, label, swatchClass, badgeClass }` : blue « Bleu » `bg-brand-blue-500`, blue_dark « Bleu foncé » `bg-brand-blue-900`, red « Rouge » `bg-brand-red-500`, amber « Ambre » `bg-amber-500`, teal « Turquoise » `bg-teal-600`) ; fonctions `getDashboard`, `translateMissing`, et pour programs/cohorts/resources : `list*(params)`, `get*(id)`, `create*`, `update*`, `delete*`, `reorder*(ids)` (PATCH `/reorder` body `{ ids }`), `setProgramActive`/`setCohortActive` (PATCH `/{id}/active`), `setResourcePublished` (PATCH `/{id}/publish`), `translate*` (POST `/translate`), `listResourceCategories` ; endpoints exacts de `contracts/admin-api.md`.
- [X] T018 [P] Créer le composant transverse `FE/components/admin/MediaPicker.vue` (`<AdminMediaPicker>`) : props `{ open: boolean, type?: MediaType, title?: string }`, emits `select(media: MediaRead)`, `close` ; modale `<Teleport to="body">` (overlay `@click.self="emit('close')"`, Esc), champ de recherche (debounce 300 ms), filtre type prérempli par la prop, grille paginée via `useMediaApi().listMedia({ type, search, page, limit: 24 })`, vignette `getMediaUrl(media.id, 'low')` pour les images / icône + nom pour les documents, bouton « Téléverser un fichier » qui appelle `useMediaApi().uploadMedia(file, { folder: 'entrepreneurship' })` puis émet `select` ; libellés FR en dur, dark mode Tailwind.
- [X] T019 [P] Créer `FE/components/entrepreneurship/admin/LangTabs.vue` : props `modelValue: 'fr'|'en'|'ar'`, emit `update:modelValue`, 3 onglets (Français / English / العربية) avec icônes `fa-solid fa-flag` comme `AdminRichTextEditor`, style onglets Tailwind ; slot par défaut rendu avec `:dir="modelValue === 'ar' ? 'rtl' : 'ltr'"`.

**Checkpoint**: migration rejouée, modèles importables (`python -c "from app.models import PeiProgram"`), routeurs enregistrés (Swagger affiche les tags), `pnpm lint` passe, section visible dans la barre latérale pour un compte `editor`.

---

## Phase 3: User Story 1 — Gérer les dispositifs du parcours (Priority: P1) 🎯 MVP

**Goal**: CRUD trilingue complet des dispositifs (pages liste / nouveau / édition), traduction automatique, glisser-déposer, activation, suppression, lecture publique des dispositifs actifs, audit.

**Independent Test**: quickstart.md §3 — créer un 6e dispositif en FR seul, vérifier EN/AR générés, le déplacer en 2e position, le désactiver, constater son absence de `GET /api/public/entrepreneurship/programs` et les 5 entrées d'audit.

### Backend US1

- [X] T020 [US1] Ajouter dans `BE/app/schemas/entrepreneurship.py` : `PeiProgramCreate` (`code: str = Field(..., max_length=60, pattern=r"^[a-z0-9][a-z0-9-]*$")`, `sigle: str | None (≤30)`, `title: str = Field(..., min_length=3, max_length=200)`, `title_en/title_ar: str | None (≤200)`, `phase: PeiProgramPhase`, `tagline/_en/_ar: str | None`, `content_md/content_html/content_en_md/content_en_html/content_ar_md/content_ar_html: str | None`, `highlight/_en/_ar: str | None (≤120)`, `color: PeiColor = 'blue'`, `cover_image_external_id: str | None` (UUID validé), `active: bool = True`), `PeiProgramUpdate` (tous optionnels, sans héritage), `PeiProgramAdmin` (tous les champs + `cover_image_url`, `display_order`, `created_at`, `updated_at`, `created_by`, `updated_by`, `from_attributes=True`), `PeiProgramsAdminPage`, `PeiProgramPublic` (sans `*_md`, sans `cover_image_external_id`, avec `cover_image_url`), `PeiProgramTranslateRequest { title?, tagline?, highlight?, content_md?, content_html? }` / `PeiProgramTranslateResponse` (variantes `_en`/`_ar`).
- [X] T021 [US1] Implémenter dans `BE/app/services/entrepreneurship_service.py` : `list_programs(q, phase, active, page, page_size)` (ILIKE sur `title`, tri `display_order, created_at`, `page_size` borné 1–100, `count` séparé), `get_program(id)` (404 `NotFoundException`), `create_program(data, user_id, ip, ua)` (409 `ConflictException("Code déjà utilisé : …")`, `display_order = _next_display_order`, `created_by`, `await autofill_translations(program, _PROGRAM_TRANSLATABLE)` avant `db.add`, flush, audit `entrepreneurship.program.create` `table_name="pei_programs"`, commit, refresh), `update_program(id, data, …)` (`model_dump(exclude_unset=True)`, 409 si nouveau code existant, `updated_by`, `autofill_translations` après application, audit `update` avec `old_values`/`new_values` des champs modifiés), `delete_program` (audit `delete` avec `old_values`), `set_program_active(id, active, …)` (audit `activate`/`deactivate`), `reorder_programs(ids, …)` → `_reorder(PeiProgram, ids, "pei_programs", "entrepreneurship.program.reorder", …)`, `translate_program_fields(data)` (`translate_text`/`translate_html` sans persistance), `list_public_programs()` et `get_public_program(code)` (`active IS TRUE`, `outerjoin(Media, PeiProgram.cover_image_external_id == Media.id)`, `cover_image_url` via `_media_url`, 404 si inactif ou inconnu).
- [X] T022 [US1] Ajouter dans `BE/app/routers/admin/entrepreneurship.py` le groupe `/programs` dans cet ordre : `GET /programs` (view, query `q`, `phase`, `active`, `page`, `page_size`), `POST /programs` (create, 201), `PATCH /programs/reorder` (edit), `POST /programs/translate` (view), `GET /programs/{program_id}` (view), `PATCH /programs/{program_id}` (edit), `DELETE /programs/{program_id}` (delete, 204), `PATCH /programs/{program_id}/active` (edit) ; chaque handler d'écriture passe `user_id=current_user.id, ip_address=ip, user_agent=ua`.
- [X] T023 [US1] Ajouter dans `BE/app/routers/public/entrepreneurship.py` : `GET /programs` → `list[PeiProgramPublic]` et `GET /programs/{code}` → `PeiProgramPublic` (404 inactif/inconnu), avec `_cache(response)`.
- [X] T024 [P] [US1] Créer `BE/tests/integration/test_admin_entrepreneurship_api.py` (section dispositifs) : fixture `entrepreneurship_permissions` greffant les 4 codes sur `admin_role` (modèle : `faq_permissions` de `test_admin_faq_entries_api.py`) ; fixture `translator_stub` monkeypatchant `app.services.translation_service.translate_text`/`translate_html` (retourne `f"[{lang}] {src}"`) ; tests : `POST /programs` sans auth → 401/403 ; création FR seule → `title_en == "[en] …"`, `content_ar_html` rempli ; modification du titre FR avec `title_en` saisi → conservé ; code dupliqué → 409 ; `PATCH /programs/reorder` avec liste incomplète → 422, liste complète → `display_order` 0..n-1 en base ; `PATCH /{id}/active false` → `active False` et audit `entrepreneurship.program.deactivate` ; une ligne `AuditLog` par écriture (`table_name == "pei_programs"`).
- [X] T025 [P] [US1] Créer `BE/tests/integration/test_public_entrepreneurship_api.py` (section dispositifs) : deux programmes actifs + un inactif → `GET /api/public/entrepreneurship/programs` renvoie 2 dans l'ordre `display_order`, sans clé `content_md` ni `cover_image_external_id` ; `GET /programs/{code inactif}` → 404 ; `GET /programs/inconnu` → 404 ; en-tête `Cache-Control` présent.

### Frontend US1

- [X] T026 [P] [US1] Créer `FE/components/entrepreneurship/admin/ProgramList.vue` : props `{ items: PeiProgramAdmin[], loading: boolean, canEdit: boolean, canDelete: boolean, dragDisabled: boolean }`, emits `edit(id)`, `delete(id)`, `toggleActive(item)`, `reorder(ids)` ; tableau (`overflow-hidden rounded-xl border`, `table.min-w-full divide-y`) avec `<VueDraggable v-model="localItems" tag="tbody" handle=".drag-handle" :animation="150" ghost-class="opacity-30" :disabled="dragDisabled" @end="emit('reorder', localItems.map(i => i.id))">` (import `{ VueDraggable } from 'vue-draggable-plus'`), colonnes : poignée `fa-solid fa-grip-vertical`, n° (index+1), pastille couleur (`colorOptions`), sigle + titre FR + code, phase (`programPhaseLabels`), chiffre mis en avant, badge Actif/Inactif (`bg-green-100 text-green-800` / `bg-gray-100 text-gray-600`), actions (modifier, activer/désactiver, supprimer si `canDelete`) ; état vide « Aucun dispositif ».
- [X] T027 [P] [US1] Créer `FE/components/entrepreneurship/admin/ProgramForm.vue` : props `{ program?: PeiProgramAdmin, saving: boolean }`, emits `submit(payload: PeiProgramCreatePayload)`, `cancel` ; `reactive` form avec tous les champs ; bloc « Identité » : code (auto-slugifié depuis le titre FR tant que non modifié à la main, bouton « Régénérer », avertissement ambre en édition « Modifier le code change l'adresse publique »), sigle, phase (`<select>` natif `programPhaseOptions`), couleur (5 pastilles radio `colorOptions` avec `swatchClass`, aria-label), actif (`checkbox`) ; bloc trilingue piloté par `<EntrepreneurshipAdminLangTabs v-model="lang">` : titre (FR requis min 3, `maxlength=200`), accroche (`textarea`), chiffre mis en avant (`maxlength=120`), AR en `dir="rtl"` ; `<AdminRichTextEditor mode="modal" title="Contenu du dispositif" v-model="form.content_md" v-model:model-value-en="form.content_en_md" v-model:model-value-ar="form.content_ar_md" v-model:html-value="form.content_html" v-model:html-value-en="form.content_en_html" v-model:html-value-ar="form.content_ar_html" height="350px">` ; visuel : aperçu `getMediaUrl(form.cover_image_external_id)` + boutons « Choisir dans la médiathèque » (ouvre `<AdminMediaPicker type="image">`) / « Retirer » ; encart « Traduire FR → EN/AR » (`translateProgram`, n'écrase que les champs EN/AR vides, libellés `t('adminTranslate.*')`) ; validation locale avant `emit('submit')` (titre FR ≥ 3, code non vide, phase) avec bandeau d'erreur.
- [X] T028 [US1] Créer `FE/pages/admin/entrepreneuriat/dispositifs/index.vue` : `definePageMeta({ layout: 'admin' })` ; en-tête h1 « Dispositifs du parcours » + sous-titre + `NuxtLink` « Nouveau dispositif » (si `hasPermission('entrepreneurship.create')`) ; recherche (`q`, debounce) + `<select>` phase + `<select>` état (tous / actifs / inactifs) ; `listPrograms({ q, phase, active, page: 1, page_size: 100 })` ; `<EntrepreneurshipAdminProgramList :drag-disabled="!!q || phase !== '' || active !== ''">` ; `onReorder(ids)` → `reorderPrograms(ids)` puis rechargement (rollback par rechargement en cas d'erreur) ; `onToggleActive` → `setProgramActive` ; suppression via modale `<Teleport to="body">` de confirmation (titre du dispositif, « Cette action est définitive ») → `deleteProgram` ; bandeau d'erreur inline ; `canEdit`/`canDelete` depuis `usePermissions()`.
- [X] T029 [P] [US1] Créer `FE/pages/admin/entrepreneuriat/dispositifs/nouveau.vue` : `definePageMeta({ layout: 'admin' })`, fil d'Ariane retour liste, `<EntrepreneurshipAdminProgramForm :saving @submit="onSubmit" @cancel="router.push('/admin/entrepreneuriat/dispositifs')">`, `onSubmit` → `createProgram(payload)` → `router.push('/admin/entrepreneuriat/dispositifs/' + created.id)` ; erreur 409 affichée « Code déjà utilisé ».
- [X] T030 [P] [US1] Créer `FE/pages/admin/entrepreneuriat/dispositifs/[id].vue` : `definePageMeta({ layout: 'admin' })`, chargement `getProgram(route.params.id)`, en-tête avec badge Actif/Inactif, boutons « Désactiver/Activer » (`setProgramActive`) et « Supprimer » (modale Teleport, si `entrepreneurship.delete`), `<EntrepreneurshipAdminProgramForm :program :saving @submit="onSubmit">` → `updateProgram(id, payload)` puis rechargement + message succès ; section « Aperçu (FR) » avec `<RichTextRenderer :html="program.content_html" />` et pastille couleur + chiffre.
- [X] T031 [US1] Dérouler quickstart.md §3 (étapes 1 à 7) avec le compte `editor` et un compte sans permission ; corriger jusqu'à validation ; exécuter `pytest tests/integration/test_admin_entrepreneurship_api.py tests/integration/test_public_entrepreneurship_api.py -v`.

**Checkpoint**: US1 livrable seule (MVP) : dispositifs gérables dans les trois langues, ordre persistant, publics filtrés, audit complet.

---

## Phase 4: User Story 2 — Gérer les cohortes (Priority: P2)

**Goal**: CRUD trilingue des cohortes (libellé, année, type FSE/SEE, focus, bilan riche), réordonnancement, activation, suppression avec point d'extension pour la feature 022.

**Independent Test**: quickstart.md §4 (cohortes) — créer `see-2026`, doublon `fse-1` refusé, désactivation → absente de la lecture publique (vérifiable après US6, ou via `active` en liste admin).

- [X] T032 [US2] Ajouter dans `BE/app/schemas/entrepreneurship.py` : `PeiCohortCreate` (`code` regex `^[a-z0-9][a-z0-9-]*$` ≤ 60, `label: str = Field(..., min_length=1, max_length=200)`, `label_en/label_ar` ≤ 200, `year: int = Field(..., ge=2000, le=2100)`, `type: PeiCohortType`, `focus/_en/_ar: str | None`, `summary_md/summary_html/summary_en_md/summary_en_html/summary_ar_md/summary_ar_html: str | None`, `active: bool = True`), `PeiCohortUpdate` (tous optionnels), `PeiCohortAdmin`, `PeiCohortsAdminPage`, `PeiCohortPublic` (sans `*_md`), `PeiCohortTranslateRequest/Response` (`label`, `focus`, `summary_md`, `summary_html`).
- [X] T033 [US2] Implémenter dans `BE/app/services/entrepreneurship_service.py` : `list_cohorts(q, type, active, page, page_size)`, `get_cohort`, `create_cohort` (409 code, `_next_display_order`, `autofill_translations(cohort, _COHORT_TRANSLATABLE)`, audit `entrepreneurship.cohort.create` `table_name="pei_cohorts"`), `update_cohort`, `_assert_cohort_deletable(cohort)` (no-op documenté : « feature 022 : lever ConflictException(f"Cohorte utilisée par {n} lauréats") »), `delete_cohort` (appelle `_assert_cohort_deletable`, audit `delete`), `set_cohort_active` (audit `activate`/`deactivate`), `reorder_cohorts` (→ `_reorder`), `translate_cohort_fields`, `list_public_cohorts(type)` et `get_public_cohort(code)` (`active IS TRUE`, 404 sinon).
- [X] T034 [US2] Ajouter dans `BE/app/routers/admin/entrepreneurship.py` le groupe `/cohorts` dans l'ordre : `GET`, `POST` (201), `PATCH /cohorts/reorder`, `POST /cohorts/translate`, `GET /cohorts/{cohort_id}`, `PATCH /cohorts/{cohort_id}`, `DELETE /cohorts/{cohort_id}` (204 ; 409 réservé), `PATCH /cohorts/{cohort_id}/active` ; permissions view/create/edit/delete comme les dispositifs.
- [X] T035 [P] [US2] Ajouter dans `BE/tests/integration/test_admin_entrepreneurship_api.py` la section cohortes : création avec traduction stub (`label_en`, `focus_ar`), doublon `code` → 409, `year` 1999 → 422, `type` invalide → 422, reorder contigu, toggle + audit `entrepreneurship.cohort.deactivate`, suppression 204 + audit `delete`.
- [x] T036 [P] [US2] Créer `FE/components/entrepreneurship/admin/CohortList.vue` (mêmes props/emits que `ProgramList`, colonnes : poignée, libellé FR + code, année, type (badge FSE bleu / SEE turquoise), focus FR tronqué, badge Actif/Inactif, actions) avec `VueDraggable`.
- [x] T037 [P] [US2] Créer `FE/components/entrepreneurship/admin/CohortForm.vue` : props `{ cohort?, saving }`, emits `submit`, `cancel` ; code (auto depuis le libellé FR), année (`type="number" min=2000 max=2100`), type (`<select>` `cohortTypeOptions`), actif ; `<EntrepreneurshipAdminLangTabs>` pour libellé (FR requis, ≤ 200) et focus (`textarea`) ; `<AdminRichTextEditor mode="modal" title="Bilan de la cohorte">` avec les 6 v-model `summary_*` ; encart « Traduire » (`translateCohort`).
- [x] T038 [US2] Créer `FE/pages/admin/entrepreneuriat/cohortes/index.vue` (gabarit de `dispositifs/index.vue` : recherche, filtres type / état, `<EntrepreneurshipAdminCohortList>`, `reorderCohorts`, `setCohortActive`, modale de suppression → `deleteCohort` avec affichage du message 409 tel quel s'il survient).
- [x] T039 [P] [US2] Créer `FE/pages/admin/entrepreneuriat/cohortes/nouveau.vue` (`createCohort` → redirection `/admin/entrepreneuriat/cohortes/{id}`).
- [x] T040 [P] [US2] Créer `FE/pages/admin/entrepreneuriat/cohortes/[id].vue` (`getCohort`, `updateCohort`, toggle, suppression, aperçu FR du bilan avec `<RichTextRenderer>`).
- [X] T041 [US2] Dérouler quickstart.md §4 (partie cohortes) et `pytest -k cohort -v` ; corriger jusqu'à validation.

**Checkpoint**: US1 et US2 fonctionnent indépendamment.

---

## Phase 5: User Story 3 — Gérer la boîte à outils (Priority: P2)

**Goal**: CRUD trilingue des ressources (document de la médiathèque / lien / vidéo, catégorie), validation de cohérence, publication, filtres type / catégorie / publication, réordonnancement.

**Independent Test**: quickstart.md §4 (ressources) — document sans fichier refusé, lien mal formé refusé, publication d'un document → visible en public avec `media_url` (après US6) ; filtre par catégorie en admin.

- [X] T042 [US3] Ajouter dans `BE/app/schemas/entrepreneurship.py` : `PeiResourceCreate` (`title: str = Field(..., min_length=1, max_length=200)`, `title_en/title_ar` ≤ 200, `description/_en/_ar: str | None`, `type: PeiResourceType`, `media_external_id: str | None` (UUID), `url: str | None` (validé par `pydantic.HttpUrl` puis converti en `str`, ≤ 500), `category/_en/_ar: str | None` ≤ 120, `is_published: bool = False`) avec `@model_validator(mode="after")` : `type == 'document'` ⇒ `media_external_id` requis (message « Un document de la médiathèque est requis pour le type document »), `type in ('link','video')` ⇒ `url` requis (« Une URL est requise pour le type lien ou vidéo ») ; `PeiResourceUpdate` (tous optionnels ; la cohérence finale est revérifiée par le service sur l'objet fusionné), `PeiResourceAdmin` (+ `media_url`), `PeiResourcesAdminPage`, `PeiResourcePublic` (`media_url`, `url`, sans `media_external_id`), `PeiResourceTranslateRequest/Response` (`title`, `description`, `category`).
- [X] T043 [US3] Implémenter dans `BE/app/services/entrepreneurship_service.py` : `_validate_resource_source(obj)` (lève `ValidationException` avec les mêmes messages), `list_resources(q, type, category, is_published, page, page_size)`, `list_resource_categories()` (`SELECT DISTINCT category WHERE category IS NOT NULL ORDER BY category`), `get_resource`, `create_resource` (validation, `autofill_translations(resource, _RESOURCE_TRANSLATABLE)`, `published_at = now()` si `is_published`, audit `entrepreneurship.resource.create` `table_name="pei_resources"`), `update_resource` (fusion puis validation), `delete_resource`, `set_resource_published(id, is_published)` (validation source avant publication ; fixe `published_at` une seule fois, conservé à la dépublication ; audit `publish`/`unpublish`), `reorder_resources`, `translate_resource_fields`, `list_public_resources(type, category)` (`is_published IS TRUE`, `outerjoin(Media, PeiResource.media_external_id == Media.id)`, `media_url`).
- [X] T044 [US3] Ajouter dans `BE/app/routers/admin/entrepreneurship.py` le groupe `/resources` dans l'ordre : `GET /resources`, `GET /resources/categories` (view), `POST /resources` (201), `PATCH /resources/reorder`, `POST /resources/translate`, `GET /resources/{resource_id}`, `PATCH /resources/{resource_id}`, `DELETE /resources/{resource_id}` (204), `PATCH /resources/{resource_id}/publish` (edit, `PublishRequest` → `PublishStatus`).
- [X] T045 [P] [US3] Ajouter dans `BE/tests/integration/test_admin_entrepreneurship_api.py` la section ressources : `document` sans `media_external_id` → 422 avec le message attendu ; `link` avec `url="pas-une-url"` → 422 ; `link` valide → 201 avec traduction stub de `category` ; `PATCH /{id}/publish true` → `published_at` renseigné, puis `false` → `published_at` conservé, audits `publish`/`unpublish` ; `GET /resources/categories` renvoie les catégories distinctes ; filtre `category` sur la liste.
- [x] T046 [P] [US3] Créer `FE/components/entrepreneurship/admin/ResourceList.vue` (props de `ProgramList` + `categories: string[]`, emits `edit`, `delete`, `togglePublish(item)`, `reorder(ids)` ; colonnes : poignée, titre FR, type (`resourceTypeLabels` + icône `fa-file` / `fa-link` / `fa-video`), catégorie, source (lien « Ouvrir » vers `media_url` ou `url`), badge Publiée/Brouillon, actions) avec `VueDraggable`.
- [x] T047 [P] [US3] Créer `FE/components/entrepreneurship/admin/ResourceForm.vue` : type (`<select>` `resourceTypeOptions`) qui bascule l'affichage : `document` → aperçu + « Choisir dans la médiathèque » (`<AdminMediaPicker type="document">`, stocke `media_external_id`) ; `link`/`video` → champ `url` (`type="url"`, `maxlength=500`, validation locale `new URL()`) ; `<EntrepreneurshipAdminLangTabs>` pour titre (FR requis), description (`textarea`), catégorie (`<input list="pei-categories">` avec `<datalist>` alimenté par `listResourceCategories`) ; publié (`checkbox`) ; encart « Traduire » (`translateResource`) ; validation locale reproduisant les règles de cohérence avec messages FR.
- [x] T048 [US3] Créer `FE/pages/admin/entrepreneuriat/ressources/index.vue` (recherche, filtres type / catégorie (`listResourceCategories`) / publication, `<EntrepreneurshipAdminResourceList>`, `reorderResources`, `setResourcePublished`, modale de suppression → `deleteResource`).
- [x] T049 [P] [US3] Créer `FE/pages/admin/entrepreneuriat/ressources/nouveau.vue` (`createResource` → redirection `/admin/entrepreneuriat/ressources/{id}`).
- [x] T050 [P] [US3] Créer `FE/pages/admin/entrepreneuriat/ressources/[id].vue` (`getResource`, `updateResource`, bouton Publier/Dépublier, suppression, aperçu de la source).
- [X] T051 [US3] Dérouler quickstart.md §4 (partie ressources) et `pytest -k resource -v` ; corriger jusqu'à validation.

**Checkpoint**: US1, US2 et US3 fonctionnent indépendamment.

---

## Phase 6: User Story 6 — Lecture publique des données actives (Priority: P2)

**Goal**: Exposer cohortes et ressources en lecture publique (les dispositifs le sont depuis US1), strictement en lecture seule, actifs/publiés uniquement, avec URLs de médias résolues.

**Independent Test**: sans authentification, `GET /api/public/entrepreneurship/{programs,cohorts,resources}` ne renvoient que les éléments actifs/publiés dans l'ordre admin ; `GET /cohorts/{code inactif}` → 404 ; aucun verbe d'écriture n'existe sous ce préfixe.

- [X] T052 [P] [US6] Ajouter dans `BE/app/routers/public/entrepreneurship.py` : `GET /cohorts` (query `type: PeiCohortType | None`) → `list[PeiCohortPublic]`, `GET /cohorts/{code}` → 404 si inactif/inconnu, avec `_cache(response)` ; routes déclarées après `/programs/*` et avant toute route dynamique concurrente.
- [X] T053 [P] [US6] Ajouter dans `BE/app/routers/public/entrepreneurship.py` : `GET /resources` (query `type: PeiResourceType | None`, `category: str | None`) → `list[PeiResourcePublic]`, `_cache(response)`.
- [X] T054 [US6] Compléter `BE/tests/integration/test_public_entrepreneurship_api.py` : cohortes actives/inactive (liste filtrée et triée, filtre `type=see`, 404 par code inactif) ; ressources publiées/non publiées (`media_url` = `/api/public/media/{uuid}/download` pour un document lié à un `Media` local, `url` pour un lien, filtre `category`) ; `POST /api/public/entrepreneurship/programs` → 405 ; aucune clé `content_md`/`summary_md`/`media_external_id` dans les réponses.
- [X] T055 [US6] Vérifier manuellement avec `curl -i` les trois listes et un code inactif (quickstart.md §3 étape 5 et §4), y compris l'en-tête `Cache-Control: public, max-age=60, stale-while-revalidate=300`.

**Checkpoint**: le futur mini-site dispose de ses trois sources publiques.

---

## Phase 7: User Story 4 — Tableau de bord du pôle et raccourcis (Priority: P3)

**Goal**: Page `/admin/entrepreneuriat` avec compteurs, raccourcis vers les 3 CRUD, bloc « Géré ailleurs », identification du service DDE (clé `entrepreneurship.dde_service_id`), action « Traduire les champs manquants ».

**Independent Test**: quickstart.md §5 — compteurs 5/5, 3/3, 0/0 après migration ; chaque raccourci mène à une page existante ; bandeau si la clé DDE est vide ; « Traduire les champs manquants » complète 5 + 3 au premier clic, 0 au second, avec entrée d'audit.

- [X] T056 [US4] Implémenter dans `BE/app/services/entrepreneurship_service.py` `get_dashboard_stats()` : `count(*)` total et `active`/`is_published` pour les trois tables ; lecture de `editorial_contents.key = 'entrepreneurship.dde_service_id'` (via `EditorialService(self.db).get_content_by_key`) ; si valeur UUID valide, `SELECT id, name FROM services WHERE id = :id` ; retourne `PeiDashboardStats { programs: {active,total}, cohorts: {active,total}, resources: {published,total}, dde_service: {id|None, name|None} }`.
- [X] T057 [US4] Implémenter dans `BE/app/services/entrepreneurship_service.py` `translate_missing(user_id, ip, ua)` : pour chaque table, charger toutes les lignes, capturer un instantané des attributs `_en`/`_ar` des listes `_*_TRANSLATABLE`, appeler `autofill_translations(obj, fields, force=False)`, incrémenter le compteur si l'instantané a changé ; `flush`, un audit `entrepreneurship.translate_missing` (`table_name=None`, `record_id=None`, `new_values={"programs": n, "cohorts": n, "resources": n}`), `commit` ; retour `PeiTranslateMissingResponse`.
- [X] T058 [US4] Ajouter dans `BE/app/routers/admin/entrepreneurship.py`, **avant** les groupes d'entités : `GET /dashboard` (view) → `PeiDashboardStats` et `POST /translate-missing` (edit) → `PeiTranslateMissingResponse`.
- [X] T059 [P] [US4] Ajouter dans `BE/tests/integration/test_admin_entrepreneurship_api.py` la section tableau de bord : `GET /dashboard` renvoie les compteurs attendus après création de 2 programmes (1 inactif) ; `dde_service` null sans clé, renseigné avec une clé pointant sur un service créé en fixture ; `POST /translate-missing` avec stub : premier appel `programs == n` et audit présent, second appel `0/0/0` ; 403 pour un rôle sans `entrepreneurship.edit`.
- [x] T060 [P] [US4] Créer `FE/components/entrepreneurship/admin/DashboardCards.vue` : props `{ stats: PeiDashboardStats | null, loading: boolean }` ; 3 cartes (icône, libellé, « actifs / total » ou « publiées / total », couleur bleu / vert / violet à la manière de `pages/admin/index.vue`), chacune `NuxtLink` vers la page CRUD correspondante.
- [x] T061 [US4] Créer `FE/pages/admin/entrepreneuriat/index.vue` : `definePageMeta({ layout: 'admin' })` ; en-tête « Pôle Entrepreneuriat et Innovation (PEI) » + sous-titre « Direction du Développement et de l'Entrepreneuriat — secteur Rectorat » ; `getDashboard()` → `<EntrepreneurshipAdminDashboardCards>` ; bandeau ambre si `stats.dde_service.id` est null (« Le service DDE n'est pas identifié : renseignez la clé « Service DDE » dans la page Entrepreneuriat (Valeurs) », lien `/admin/editorial/valeurs`), sinon ligne « Service DDE : {name} » ; bloc « Géré ailleurs » = tableau des 6 raccourcis de `contracts/frontend.md` (Actualités `/admin/contenus/actualites`, Événements `/admin/contenus/evenements`, Albums `/admin/organisation/services` + `?service_id=` si présent, FAQ `/admin/faq`, Appels `/admin/candidatures/appels`, Page éditoriale `/admin/editorial/valeurs`) avec le rappel de convention ; carte « Traductions » avec bouton « Traduire les champs manquants » (visible si `hasPermission('entrepreneurship.edit')`, état `translating`, `translateMissing()` puis message « {programs} dispositifs, {cohorts} cohortes, {resources} ressources complétés », rechargement des compteurs).
- [X] T062 [US4] Dérouler quickstart.md §5 (compteurs, 6 raccourcis sans 404, bandeau DDE, double clic « Traduire ») et `pytest -k "dashboard or translate_missing" -v`.

**Checkpoint**: l'éditeur navigue depuis un point d'entrée unique ; les données initiales sont traduites en production sans SSH.

---

## Phase 8: User Story 5 — Page éditoriale « Entrepreneuriat » (Priority: P3)

**Goal**: Rendre les 43 clés éditoriales (seedées par la migration en T005) éditables dans la page « Valeurs » via une nouvelle page front-office `entrepreneurship`.

**Independent Test**: quickstart.md §6 — page « Page Entrepreneuriat (PEI) » visible dans « Valeurs » avec 8 sections et les valeurs initiales ; modification d'un chiffre clé conservée après rejeu de la migration ; téléversement d'une image de slider.

- [X] T063 [P] [US5] Ajouter dans `FE/types/api/editorial.ts` les 43 littéraux de `contracts/editorial-keys.md` au type `ValueSectionKey` (bloc commenté `// Page Entrepreneuriat (PEI)`), de `'entrepreneurship.hero.badge'` à `'entrepreneurship.dde_service_id'`.
- [X] T064 [US5] Ajouter dans `FE/composables/editorial-pages-config.ts` : `export const entrepreneurshipPageSections: PageSection[]` avec les 8 sections de `contracts/editorial-keys.md` (`entrepreneurship-hero`, `-presentation`, `-stats`, `-activities`, `-quote`, `-cta`, `-see`, `-settings`), chaque champ avec `key`, `label`, `description` FR, `type` (`text` / `textarea` / `html` / `image` / `list`), `editorialKey`, `editable: true`, `defaultValue` = valeur initiale du contrat ; icônes FontAwesome sans préfixe (`lightbulb`, `align-left`, `chart-bar`, `route`, `quote-left`, `bullhorn`, `gear`) et couleurs Tailwind comme les sections existantes ; puis l'entrée `frontOfficePages` `{ id: 'entrepreneurship', name: 'Page Entrepreneuriat (PEI)', slug: '/entrepreneuriat', description: 'Textes, chiffres clés et réglages du mini-site « Entreprendre à Senghor »', icon: 'lightbulb', sections: entrepreneurshipPageSections }` après `alumni`.
- [X] T065 [US5] Vérifier la cohérence clé par clé entre T005 (seed SQL), T063 (type) et T064 (config) — script ponctuel `grep -o "entrepreneurship\.[a-z0-9_.]*" | sort -u` sur les trois fichiers, différence vide — puis dérouler quickstart.md §6 (valeurs initiales visibles, modification conservée après rejeu de 045, image de slider).

**Checkpoint**: toutes les stories sont livrées ; le mini-site (023) disposera des textes et réglages.

---

## Phase 9: Polish & Cross-Cutting Concerns

- [X] T066 [P] Créer `BE/tests/unit/test_entrepreneurship_service.py` : validation `_validate_resource_source` (4 cas), renumérotation `_reorder` (liste inversée → 0..n-1, liste incomplète → `ValidationException`, identifiant inconnu → `ValidationException`), `_next_display_order` sur table vide → 0.
- [X] T067 Exécuter `cd usenghor_backend && pytest -v` (suite complète, base `usenghor_test`) et corriger toute régression.
- [X] T068 Exécuter `cd usenghor_nuxt && pnpm lint && pnpm build` ; corriger ESLint et erreurs TypeScript (types `ValueSectionKey`, composable, composants).
- [X] T069 [P] Mettre à jour `CLAUDE.md` : ligne `| 16_entrepreneurship.sql | Entrepreneurship | pei_programs, pei_cohorts, pei_resources |` dans le tableau SQL (et « 17 fichiers » au lieu de 16), tableau « Composants clés » (`useEntrepreneurshipApi()` → `/api/admin/entrepreneurship/*`, `components/entrepreneurship/admin/*`, `AdminMediaPicker` sélecteur de médiathèque transverse), précision « Champs trilingues : convention additive (`title`, `title_en`, `title_ar`) pour les domaines à traduction automatique ; `*_fr/*_en/*_ar` pour la FAQ », entrée « Recent Changes » `021-pei-entrepreneurship-core` (socle PEI : SQL + migration 045, API admin/publique, section admin « Entrepreneuriat (PEI) », page éditoriale `entrepreneurship`, permissions `entrepreneurship.*`).
- [X] T070 Dérouler intégralement quickstart.md §1 à §8 sur une base locale fraîche (rollback puis rejeu, puis parcours complet) et consigner les écarts dans `specs/021-pei-entrepreneurship-core/quickstart.md` s'il y en a.
- [ ] T071 Préparer la mise en production (quickstart.md §9) : `./deploy.sh backup`, jouer `045_entrepreneurship.sql` deux fois sur `usenghor_db`, vérifier `5|3|4|43` et la clé `entrepreneurship.dde_service_id` renseignée, puis lancer « Traduire les champs manquants » depuis le backoffice — **après accord explicite du responsable** (commit + push `origin/main` préalables, `deploy.sh update --force-recreate`).

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)** : T001 bloque tout (accord SQL) ; T002/T004/T006 parallèles ; T003 après T002 ; T005 après T002 ; T007 après T005+T006.
- **Foundational (Phase 2)** : après T007 ; T008 → T009 → T010 → T011 → T012/T013 ; T014–T019 parallèles entre eux et avec le backend (T017 dépend de T014).
- **User Stories (Phases 3–8)** : toutes après la Phase 2. US2, US3 sont indépendantes de US1 (mais réutilisent ses gabarits de pages : les copier accélère). US6 dépend de US2 et US3 (modèles/services publics). US4 dépend de US1–US3 (compteurs) et de T005 (clé DDE). US5 dépend de T005 uniquement (peut se faire dès la Phase 1 terminée).
- **Polish (Phase 9)** : après les stories retenues.

### User Story Dependencies

- **US1 (P1)** : Phase 2 → aucune autre dépendance. MVP.
- **US2 (P2)** : Phase 2 → indépendante (partage `entrepreneurship_service.py` et le routeur admin : tâches séquentielles sur ces fichiers).
- **US3 (P2)** : Phase 2 → indépendante.
- **US6 (P2)** : US2 + US3 (US1 a déjà livré `/programs`).
- **US4 (P3)** : US1 + US2 + US3.
- **US5 (P3)** : Phase 1 (T005) ; indépendante du backend applicatif.

### Within Each User Story

Schémas → service → routeur admin (→ routeur public) → tests → composants → pages → validation quickstart.

### Parallel Opportunities

- Phase 1 : T002 ∥ T004 ∥ T006.
- Phase 2 : {T014, T015, T016, T018, T019} ∥ chaîne backend T008→T013 ; T017 après T014.
- US1 : T024 ∥ T025 (tests) ∥ T026 ∥ T027 (composants) ; T029 ∥ T030 après T027.
- US2 : T035 ∥ T036 ∥ T037 ; T039 ∥ T040. US3 : T045 ∥ T046 ∥ T047 ; T049 ∥ T050.
- US6 : T052 ∥ T053. US4 : T059 ∥ T060. US5 : T063 ∥ (T064 après T063).
- Polish : T066 ∥ T069.
- Fichiers partagés à ne **pas** paralléliser : `entrepreneurship_service.py`, `schemas/entrepreneurship.py`, `routers/admin/entrepreneurship.py`, `routers/public/entrepreneurship.py`, `test_admin_entrepreneurship_api.py`.

---

## Parallel Example: User Story 1

```bash
# Après T023 (backend US1 terminé), lancer ensemble :
Task: "T024 tests admin dispositifs — BE/tests/integration/test_admin_entrepreneurship_api.py"
Task: "T025 tests publics dispositifs — BE/tests/integration/test_public_entrepreneurship_api.py"
Task: "T026 ProgramList.vue — FE/components/entrepreneurship/admin/ProgramList.vue"
Task: "T027 ProgramForm.vue — FE/components/entrepreneurship/admin/ProgramForm.vue"

# Puis, après T027 :
Task: "T029 dispositifs/nouveau.vue"
Task: "T030 dispositifs/[id].vue"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1 (dont l'accord SQL T001) puis Phase 2.
2. Phase 3 (US1) → quickstart §3 → démo : un éditeur gère les dispositifs dans les trois langues, ordre et activation persistants, public filtré, audit complet.

### Incremental Delivery

1. Setup + Foundational → base rejouée, navigation visible.
2. US1 → MVP validé.
3. US2 puis US3 → cohortes et boîte à outils.
4. US6 → sources publiques complètes pour la feature 023.
5. US4 → tableau de bord + traduction des données initiales.
6. US5 → page éditoriale (peut être avancée juste après la Phase 1 si un second développeur est disponible).
7. Polish → tests complets, lint/build, CLAUDE.md, production.

### Parallel Team Strategy

- Dev A : chaîne backend (Phases 2 → US1 → US2 → US3 → US6 → US4 backend).
- Dev B : frontend transverse (T014–T019) puis US5 (T063–T065), puis composants/pages US1 dès que T022 est disponible, puis US2/US3/US4 frontend.

---

## Notes

- Toute permission utilisée dans un `PermissionChecker` est seedée par T004/T005 (`entrepreneurship.view|create|edit|delete`) — n'en introduire aucune autre.
- Routes statiques (`/reorder`, `/translate`, `/categories`, `/dashboard`, `/translate-missing`) déclarées avant `/{id}` et `/{code}`.
- Libellés admin en français accentué, codés en dur (research R11) ; bouton Traduire via `adminTranslate.*`.
- Noms de fichiers sans accents : `entrepreneuriat/`, `dispositifs/`, `cohortes/`, `ressources/`.
- Commit après chaque groupe logique ; s'arrêter à chaque checkpoint pour valider la story.
