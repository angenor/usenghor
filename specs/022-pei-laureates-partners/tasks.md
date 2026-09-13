---

description: "Liste des tâches d'implémentation — 022 Lauréats et partenaires du pôle PEI"
---

# Tasks: Lauréats, étudiants-entrepreneurs et partenaires du pôle PEI (backoffice)

**Input**: Design documents from `/specs/022-pei-laureates-partners/`

**Prerequisites**: plan.md, spec.md (Clarifications Q1–Q5), research.md (R1–R16), data-model.md (SQL §4–6), contracts/ (admin-api, public-api, frontend), quickstart.md

**Tests**: Les tests backend `pytest` sont inclus (plan.md « Testing », research R16) et écrits dans la foulée de chaque story, sans approche TDD stricte. Aucun test frontend (pas d'infrastructure) : validation manuelle par quickstart.md + `pnpm build`.

**Organization**: Tâches groupées par user story (spec.md) dans l'ordre de priorité : US1 portraits admin (P1) → US2 lecture publique des portraits (P1) → US3 partenaires du pôle admin (P2) → US4 lecture publique des partenaires (P2) → US5 tableau de bord, barre latérale, traduction (P3) → US6 rattachement initial des partenaires (P3, validation de la migration).

## Format: `[ID] [P?] [Story] Description`

- **[P]** : parallélisable (fichiers différents, aucune dépendance sur une tâche inachevée)
- **[Story]** : US1…US6 (spec.md)
- Chemins exacts depuis la racine du dépôt ; `BE` = `usenghor_backend/`, `FE` = `usenghor_nuxt/app/`, `SQL` = `usenghor_backend/documentation/modele_de_données/`

## Path Conventions

Monorepo : backend `usenghor_backend/app/{models,schemas,services,routers/admin,routers/public}` + `tests/{integration,unit}` ; frontend `usenghor_nuxt/app/{types/api,composables,components/entrepreneurship/admin,pages/admin/entrepreneuriat}`. **Extension in situ** des fichiers de la feature 021 (research R1) : aucun fichier parallèle au domaine `entrepreneurship`. Convention trilingue additive : `department_label`, `department_label_en`, `department_label_ar` ; `quote`, `quote_en`, `quote_ar`.

---

## Phase 1: Setup (SQL de référence et migration 046)

**Purpose**: Poser le schéma validé, rejouable, avant tout code applicatif (CLAUDE.md : accord → SQL → code).

- [X] T001 **Porte FR-005** — Présenter au responsable du projet le SQL de `specs/022-pei-laureates-partners/data-model.md` §4 (2 ENUM, `pei_laureates`, `pei_partners`, contraintes `chk_pei_laureates_*`, FK `cohort_id ON DELETE RESTRICT`, PK `partner_id … ON DELETE CASCADE`), §5 (migration 046 dont rattachement initial R13) et §6 (rollback 046 + annotation du rollback 045), ainsi que l'écart « FK réelle vers partners » (plan.md, Constitution Check) ; ne commencer T002 qu'après accord explicite, et reporter dans data-model.md toute modification demandée.
- [X] T002 [P] Compléter `SQL/services/16_entrepreneurship.sql` en recopiant data-model.md §4 après le bloc `pei_resources` : `CREATE TYPE pei_laureate_type AS ENUM ('fse_laureate','student_entrepreneur')`, `CREATE TYPE pei_partner_family AS ENUM ('academic','support','international')` ; table `pei_laureates` (`cohort_id UUID NOT NULL REFERENCES pei_cohorts(id) ON DELETE RESTRICT`, `type pei_laureate_type NOT NULL`, `full_name VARCHAR(200) NOT NULL` CHECK `char_length >= 2`, `project_name VARCHAR(200) NOT NULL` CHECK `char_length >= 2`, `department_label`/`_en`/`_ar VARCHAR(200)`, `quote`/`quote_en`/`quote_ar TEXT` CHECK `char_length <= 600` chacun (`chk_pei_laureates_quote_len`), `photo_external_id UUID` sans FK, `website_url`/`linkedin_url`/`instagram_url`/`facebook_url`/`video_url VARCHAR(500)`, `grant_amount NUMERIC(10,2)` CHECK `>= 0`, `is_featured BOOLEAN NOT NULL DEFAULT FALSE`, `is_published BOOLEAN NOT NULL DEFAULT FALSE`, `published_at TIMESTAMPTZ`, `display_order INTEGER NOT NULL DEFAULT 0` (relatif à la cohorte), `created_by`/`updated_by` FK users SET NULL) ; table `pei_partners` (`partner_id UUID PRIMARY KEY REFERENCES partners(id) ON DELETE CASCADE`, `family pei_partner_family NOT NULL`, `display_order INTEGER NOT NULL DEFAULT 0`, timestamps, `created_by`/`updated_by`) ; index `idx_pei_laureates_cohort_order (cohort_id, display_order)`, `idx_pei_laureates_published_type (is_published, type)`, `idx_pei_partners_family_order (family, display_order)` ; `COMMENT ON TABLE` ×2 ; mettre à jour l'en-tête du fichier (tables, dépendance `PARTNER (partners)`, spec 022).
- [X] T003 Créer `SQL/migrations/046_pei_laureates_partners.sql` selon data-model.md §5 : en-tête commenté (contexte, dépendances 045 + `partners`, rejouable, rollback), `BEGIN;`, 2 blocs `DO $$ BEGIN CREATE TYPE … EXCEPTION WHEN duplicate_object THEN NULL; END $$;`, tables et index de T002 en `IF NOT EXISTS`, 2 triggers `update_pei_laureates_updated_at` / `update_pei_partners_updated_at` → `update_updated_at_column()` gardés par `IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = …)` (boucle `FOREACH` comme 045), bloc `DO $$` de rattachement initial (R13 : `VALUES ('academic',0,'r.seau senghor'), ('academic',1,'campus france'), ('support',0,'\mCEF\M'), ('support',1,'\mCCI\M|chambre de commerce'), ('international',0,'\mAUF\M|agence universitaire de la francophonie'), ('international',1,'\mAFD\M|agence fran.aise de d.veloppement'), ('international',2,'\mOIF\M|organisation internationale de la francophonie')`, `INSERT … SELECT p.id, family::pei_partner_family, rank FROM partners p WHERE p.name ~* pattern ON CONFLICT (partner_id) DO NOTHING`, `RAISE NOTICE` quand `ROW_COUNT = 0`), bloc de renumérotation contiguë par famille (`ROW_NUMBER() OVER (PARTITION BY family ORDER BY display_order, created_at) - 1`, `UPDATE … WHERE display_order <> rn`), `COMMIT;`, `\echo 'Migration 046_pei_laureates_partners terminée'`.
- [X] T004 [P] Créer `SQL/migrations/046_pei_laureates_partners_rollback.sql` : en-tête « À jouer AVANT 045_entrepreneurship_rollback.sql », `BEGIN; DROP TABLE IF EXISTS pei_laureates; DROP TABLE IF EXISTS pei_partners; DROP TYPE IF EXISTS pei_laureate_type; DROP TYPE IF EXISTS pei_partner_family; COMMIT;`, `\echo 'Rollback 046_pei_laureates_partners terminé'`.
- [X] T005 [P] Ajouter dans l'en-tête commenté de `SQL/migrations/045_entrepreneurship_rollback.sql` la ligne « Prérequis : jouer d'abord 046_pei_laureates_partners_rollback.sql (pei_laureates référence pei_cohorts, ON DELETE RESTRICT) ».
- [X] T006 Jouer la migration deux fois en local (`docker exec -i usenghor_postgres psql -U usenghor -d usenghor < 046_pei_laureates_partners.sql`), vérifier la requête de comptage de quickstart.md §1 (valeurs identiques après chaque passage, `count(partners)` inchangé), jouer le rollback 046 puis rejouer ; vérifier qu'un `DELETE FROM pei_cohorts` sur une cohorte référencée est refusé par la FK ; corriger T003/T004 jusqu'à zéro erreur.

---

## Phase 2: Foundational (modèles, schémas transverses, helpers, types)

**Purpose**: Extensions des fichiers 021 dont dépendent toutes les stories : modèles, helper de reorder scopé, types et options frontend.

**⚠️ CRITICAL**: aucune story ne commence avant la fin de cette phase.

- [X] T007 Étendre `BE/app/models/entrepreneurship.py` : enums `PeiLaureateType` (`fse_laureate`, `student_entrepreneur`) et `PeiPartnerFamily` (`academic`, `support`, `international`) (`str, enum.Enum`) ; classe `PeiLaureate(Base, UUIDMixin, TimestampMixin)` (`__tablename__ = "pei_laureates"`, toutes les colonnes de data-model.md §2.1, `cohort_id` `ForeignKey("pei_cohorts.id", ondelete="RESTRICT")` + `relationship("PeiCohort")`, `grant_amount` `Numeric(10, 2)`, ENUM via `sqlalchemy.Enum(PeiLaureateType, name="pei_laureate_type", create_type=False, values_callable=…)`, `__table_args__` répliquant `chk_pei_laureates_full_name`, `chk_pei_laureates_project_name`, `chk_pei_laureates_quote_len`, `chk_pei_laureates_grant`) ; classe `PeiPartner(Base, TimestampMixin)` (`__tablename__ = "pei_partners"`, `partner_id` `mapped_column(UUID(as_uuid=False), ForeignKey("partners.id", ondelete="CASCADE"), primary_key=True)`, `family`, `display_order`, `created_by`/`updated_by`, `relationship("Partner")`) ; exporter les 2 classes et 2 enums dans `BE/app/models/__init__.py`.
- [X] T008 Étendre `BE/app/schemas/entrepreneurship.py` (bloc transversal) : `PeiLaureateReorderRequest { cohort_id: str, ids: list[str] = Field(min_length=1) }`, `PeiPartnerReorderRequest { family: PeiPartnerFamily, ids: list[str] = Field(min_length=1) }`, `FeaturedRequest { is_featured: bool }`, `FeaturedStatus { id, is_featured, updated_at }` (`from_attributes=True`) ; `PeiDashboardStats` + `laureates: PeiPublishedCount`, `partners: PeiActiveCount` ; `PeiTranslateMissingResponse` + `laureates: int`.
- [X] T009 Étendre `BE/app/services/entrepreneurship_service.py` (helpers, research R2/R3/R11) : constante `_LAUREATE_TRANSLATABLE = [("department_label","text"),("quote","text")]`, `QUOTE_MAX_LEN = 600` ; généraliser `_reorder(model, ids, table_name, action, user_id, ip, ua, *, scope: dict | None = None)` : quand `scope` est fourni (`{"cohort_id": …}` ou `{"family": …}`), la liste doit couvrir exactement les identifiants **de cette portée** (422 « liste incomplète » / « identifiant inconnu ou hors portée » / « identifiant en double »), `display_order = index` dans la portée, audit unique `new_values={**scope, "ids": ids}` ; `_next_display_order(model, **scope)` = `MAX(display_order)+1` filtré par la portée ; `_renumber(model, **scope)` : renumérote 0..n-1 une portée (utilisé après suppression, changement de cohorte / famille, retrait) ; `_clamp_quote(obj)` : tronque `quote`, `quote_en`, `quote_ar` à 600 caractères (coupure au dernier espace + « … ») ; `_assert_laureate_cohort(type, cohort)` : 422 « Un lauréat FSE doit appartenir à une cohorte FSE » / « Un étudiant-entrepreneur doit appartenir à une cohorte SEE » (`fse_laureate ⇔ fse`, `student_entrepreneur ⇔ see`) ; conserver le comportement actuel de `_reorder` sans `scope` pour programs / cohorts / resources.
- [X] T010 [P] Étendre `FE/types/api/entrepreneurship.ts` (contracts/frontend.md) : `PeiLaureateType`, `PeiPartnerFamily` ; `PeiLaureateAdmin` (table + `photo_url`, `cohort: { id, code, label, type, year, active }`, `grant_amount: string | null`, audit cols), `PeiLaureateCreatePayload`, `PeiLaureateUpdatePayload` (Partial), `PeiLaureateListParams { q?, cohort_id?, type?, is_published?, page?, page_size? }`, `PeiLaureateTranslateRequest/Response`, `FeaturedStatus` ; `PeiPartnerLinkAdmin { partner_id, family, display_order, created_at, updated_at, partner: { id, name, type, active, website, logo_url, description } }`, `PeiPartnerAvailable { id, name, type, active, logo_url }` ; `PeiLaureatePublic`, `PeiLaureatesPublic { groups: { cohort: PeiCohortPublic, laureates: PeiLaureatePublic[] }[], stats: { laureates, cohorts, max_grant_amount: string | null } }`, `PeiPartnerPublic`, `PeiPartnerFamilyPublic { family, partners }` ; `PeiDashboardStats` + `laureates: { published, total }`, `partners: { active, total }` ; `PeiTranslateMissingResponse` + `laureates`.
- [X] T011 [P] Étendre `FE/composables/useEntrepreneurshipApi.ts` (exports de module) : `laureateTypeOptions` (`fse_laureate` « Lauréat FSE », `student_entrepreneur` « Étudiant-entrepreneur »), `laureateTypeLabels`, `cohortTypeForLaureateType` (`fse_laureate → 'fse'`, `student_entrepreneur → 'see'`), `partnerFamilyOptions` dans l'ordre fixe (`academic` « Académiques et institutionnels », `support` « Organisations d'appui », `international` « Organisations internationales »), `partnerFamilyLabels` ; interface `PeiLaureateListParams` importée de T010.

**Checkpoint**: modèles importables (`python -c "import app.models"`), `pnpm build` inchangé.

---

## Phase 3: User Story 1 - Gérer les lauréats et étudiants-entrepreneurs (Priority: P1) 🎯 MVP

**Goal**: CRUD complet des portraits en backoffice : liste filtrable, formulaire trilingue avec photo et liens, publication, mise en avant, réordonnancement par cohorte, cohérence type / cohorte, refus de suppression d'une cohorte utilisée, audit.

**Independent Test**: quickstart.md §3 — créer un lauréat FSE complet, vérifier EN/AR remplis, publier, filtrer sur sa cohorte, le réordonner et retrouver l'ordre après rechargement ; supprimer la cohorte → 409.

### Backend US1

- [X] T012 [US1] Ajouter dans `BE/app/schemas/entrepreneurship.py` le bloc Laureates (contracts/admin-api.md) : `PeiLaureateCreate` (`cohort_id: str`, `type: PeiLaureateType`, `full_name: str = Field(min_length=2, max_length=200)`, `project_name` idem, `department_label?/_en?/_ar?` ≤ 200, `quote?/_en?/_ar?` ≤ 600 avec message « Le verbatim ne doit pas dépasser 600 caractères », `photo_external_id: str | None`, `website_url`/`linkedin_url`/`instagram_url`/`facebook_url`/`video_url: str | None` validés par `HttpUrl` → `str` ≤ 500 avec `field_validator` normalisant `""` en `None` et message « Adresse web invalide : <champ> », `grant_amount: Decimal | None = Field(ge=0, decimal_places=2)`, `is_featured: bool = False`, `is_published: bool = False`), `PeiLaureateUpdate` (tous optionnels), `PeiLaureateCohortRef { id, code, label, type, year, active }`, `PeiLaureateAdmin` (table + `photo_url` + `cohort` + `grant_amount` sérialisé en chaîne + `created_at/updated_at/created_by/updated_by`, `from_attributes=True`), `PeiLaureateAdminPage`, `PeiLaureateTranslateRequest { department_label?, quote? }`, `PeiLaureateTranslateResponse { department_label_en, department_label_ar, quote_en, quote_ar }`.
- [X] T013 [US1] Implémenter dans `BE/app/services/entrepreneurship_service.py` le bloc Laureates : `list_laureates(q, cohort_id, type, is_published, page, page_size)` (ILIKE sur `full_name` et `project_name`, `selectinload(cohort)`, tri `PeiCohort.display_order, PeiLaureate.display_order`, photos chargées par lot via `_load_media`) ; `get_laureate(id)` (404) ; `create_laureate(data, user_id, ip, ua)` : cohorte 404, `_assert_laureate_cohort`, `display_order = _next_display_order(PeiLaureate, cohort_id=…)`, `autofill_translations(obj, _LAUREATE_TRANSLATABLE)`, `_clamp_quote`, `published_at = now` si créé publié, audit `entrepreneurship.laureate.create` ; `update_laureate(id, data, …)` via `_apply_update` + si `cohort_id` change : `_next_display_order` dans la nouvelle cohorte puis `_renumber` de l'ancienne ; si `type` ou `cohort_id` change : `_assert_laureate_cohort` ; audit `update` (old/new) ; `delete_laureate` (204, `_renumber` de la cohorte, audit `delete`) ; `set_laureate_published(id, bool)` (`published_at` fixé à la première publication seulement, audit `publish` / `unpublish`) ; `set_laureate_featured(id, bool)` (audit `feature` / `unfeature`) ; `reorder_laureates(cohort_id, ids, …)` → `_reorder(..., scope={"cohort_id": cohort_id})` ; `translate_laureate_fields(data)` via `_translate_request` ; `_to_laureate_admin(obj, media_map)` construisant `PeiLaureateAdmin` (photo résolue, `cohort` embarqué).
- [X] T014 [US1] Activer `_assert_cohort_deletable(cohort_id)` dans `BE/app/services/entrepreneurship_service.py` : `SELECT count(*) FROM pei_laureates WHERE cohort_id = :id` → `ConflictException(f"Cohorte utilisée par {n} lauréats")` quand `n > 0` (409, contrat 021).
- [X] T015 [US1] Ajouter dans `BE/app/routers/admin/entrepreneurship.py` le groupe `/laureates` dans cet ordre : `GET /laureates` (view ; query `q`, `cohort_id`, `type`, `is_published`, `page`, `page_size` ≤ 100), `POST /laureates` (create, 201), `PATCH /laureates/reorder` (edit, `PeiLaureateReorderRequest`), `POST /laureates/translate` (view), `GET /laureates/{laureate_id}` (view), `PATCH /laureates/{laureate_id}` (edit), `DELETE /laureates/{laureate_id}` (delete, 204), `PATCH /laureates/{laureate_id}/publish` (edit, `PublishRequest` → `PublishStatus`), `PATCH /laureates/{laureate_id}/featured` (edit, `FeaturedRequest` → `FeaturedStatus`) ; chaque écriture passe `_client_meta(request)`.
- [X] T016 [US1] Créer `BE/tests/integration/test_admin_pei_laureates_api.py` (fixtures `authenticated_client`, `admin_role`, fixture `entrepreneurship_permissions` copiée de `test_admin_entrepreneurship_api.py`, cohortes `fse-1` / `see-2026` créées en fixture, mock `translation_service.autofill_translations`) : 403 sans permission ; 201 création avec traduction (mock appelé) ; 422 `student_entrepreneur` + cohorte `fse` ; 422 verbatim de 601 caractères ; 422 `linkedin_url = "linkedin"` ; 422 `grant_amount = -1` ; `publish` fixe `published_at` puis `unpublish` le conserve ; `featured` ; `reorder` avec liste incomplète → 422, liste complète → `display_order` 0..n-1 dans la cohorte seulement ; changement de cohorte → dernière position + renumérotation de l'ancienne ; `DELETE /cohorts/{id}` → 409 « Cohorte utilisée par 1 lauréats » puis 204 après suppression du portrait ; une entrée `AuditLog` par écriture (actions `entrepreneurship.laureate.*`).
- [X] T017 [P] [US1] Étendre `BE/tests/unit/test_entrepreneurship_service.py` : `_clamp_quote` (601 → ≤ 600, coupure au dernier espace), `_assert_laureate_cohort` (4 combinaisons), `_reorder` scopé (ids d'une autre cohorte → 422).

### Frontend US1

- [X] T018 [US1] Ajouter dans `FE/composables/useEntrepreneurshipApi.ts` les fonctions `listLaureates(params)` (`GET /laureates`), `getLaureate(id)`, `createLaureate(p)`, `updateLaureate(id, p)`, `deleteLaureate(id)`, `reorderLaureates(cohortId, ids)` (`PATCH /laureates/reorder` body `{ cohort_id, ids }`), `setLaureatePublished(id, bool)` (`PATCH /laureates/{id}/publish`), `setLaureateFeatured(id, bool)` (`PATCH /laureates/{id}/featured`), `translateLaureate(p)` (`POST /laureates/translate`) ; les retourner depuis le composable.
- [X] T019 [P] [US1] Créer `FE/components/entrepreneurship/admin/LaureateList.vue` (copie de `CohortList.vue`) : props `{ items: PeiLaureateAdmin[], loading?, canEdit?, canDelete?, dragDisabled? }`, emits `edit(id)`, `delete(id)`, `togglePublish(item)`, `toggleFeatured(item)`, `reorder(ids)` ; `VueDraggable tag="tbody" handle=".drag-handle" :disabled="isDragDisabled"` avec `localItems` resynchronisé par `watch` et `onDragEnd` après `nextTick()` ; colonnes : poignée, vignette photo (`photo_url` ou initiale), nom + projet, cohorte (badge `cohort.label`), type (badge `laureateTypeLabels`, classes `fse_laureate` bleu / `student_entrepreneur` teal), étoile « Mis en avant » (bouton, permission edit), badge Publié / Brouillon (bouton bascule), actions modifier / supprimer ; message sous le tableau quand le tri est gelé : « Filtrez sur une seule cohorte, sans autre filtre, pour réordonner ».
- [X] T020 [P] [US1] Créer `FE/components/entrepreneurship/admin/LaureateForm.vue` (copie de `CohortForm.vue`) : props `{ laureate?: PeiLaureateAdmin | null, cohorts: PeiCohortAdmin[], saving: boolean }`, emits `submit(payload: PeiLaureateCreatePayload)`, `cancel` ; champs : `<select>` type (`laureateTypeOptions`) → `<select>` cohorte filtré par `cohortTypeForLaureateType` (réinitialisé si la cohorte courante n'est plus compatible), nom, projet ; `EntrepreneurshipAdminLangTabs v-model="lang"` englobant département (`input`) et verbatim (`textarea maxlength="600"` + compteur `n/600`) pour FR / EN / AR ; section « Photo » : aperçu (`useMediaApi().getMediaUrl(id)`), boutons « Choisir dans la médiathèque » (`<AdminMediaPicker :open type="image" @select="form.photo_external_id = media.id">`) et « Retirer » (pattern `ProgramForm` « Visuel ») ; cinq champs `type="url"` (Site web, LinkedIn, Instagram, Facebook, Vidéo) ; « Montant de la subvention (€) » `type="number" min="0" step="0.01"` ; cases « Mis en avant » et « Publié » ; bouton « Traduire FR → EN/AR » (`translateLaureate`, remplit uniquement les champs vides, libellés `adminTranslate.*`) ; validation locale : nom, projet, cohorte requis, chaînes vides envoyées en `null`.
- [X] T021 [US1] Créer `FE/pages/admin/entrepreneuriat/laureats/index.vue` (copie de `cohortes/index.vue`) : `definePageMeta({ layout: 'admin' })`, filtres recherche (debounce 300 ms), `<select>` cohorte (`listCohorts({ page_size: 100 })`), type, publication (Tous / Publiés / Brouillons), bouton « Réinitialiser » ; `dragDisabled = !cohortId || !!debouncedQ || type !== '' || published !== ''` passé à `LaureateList` avec `|| !canEdit` ; handlers : `reorder` → `reorderLaureates(cohortId, ids)`, `togglePublish` → `setLaureatePublished`, `toggleFeatured` → `setLaureateFeatured`, `delete` (confirmation, permission delete) ; bouton « Nouveau portrait » (permission create) ; messages d'erreur via `extractError`.
- [X] T022 [P] [US1] Créer `FE/pages/admin/entrepreneuriat/laureats/nouveau.vue` (copie de `cohortes/nouveau.vue`) : charge les cohortes, rend `LaureateForm`, `createLaureate` puis `router.push('/admin/entrepreneuriat/laureats/' + id)` ; refus si `!canCreate`.
- [X] T023 [P] [US1] Créer `FE/pages/admin/entrepreneuriat/laureats/[id].vue` (copie de `cohortes/[id].vue`) : chargement (`getLaureate`, 404 → état « introuvable »), en-tête avec badges cohorte / type / publié / mis en avant, boutons « Publier / Dépublier » et « Mettre en avant / Retirer la mise en avant » (permission edit), « Supprimer » (permission delete, confirmation, retour à la liste), `LaureateForm` avec `updateLaureate` et message de succès temporisé.

**Checkpoint**: US1 validée par quickstart §3 (étapes 1–8) ; tests T016–T017 verts ; tests 021 toujours verts.

---

## Phase 4: User Story 2 - Lecture publique des portraits groupés par cohorte (Priority: P1)

**Goal**: `GET /api/public/entrepreneurship/laureates` : portraits publiés, cohortes actives, groupés et triés, filtre `type`, photos résolues, chiffres du bandeau calculés.

**Independent Test**: quickstart.md §4 — deux portraits publiés dans FSE 1, un brouillon dans FSE 2, FSE 3 désactivée → un seul groupe FSE 1 avec deux portraits ; stats cohérentes.

- [X] T024 [US2] Ajouter dans `BE/app/schemas/entrepreneurship.py` : `PeiLaureatePublic` (`id`, `type`, `full_name`, `project_name`, `department_label`/`_en`/`_ar`, `quote`/`_en`/`_ar`, `photo_url`, cinq `*_url`, `is_featured`, `cohort_label`/`_en`/`_ar`, `display_order` — **sans** `grant_amount`, `published_at`, auteurs), `PeiLaureateGroupPublic { cohort: PeiCohortPublic, laureates: list[PeiLaureatePublic] }`, `PeiLaureateStatsPublic { laureates: int, cohorts: int, max_grant_amount: str | None }`, `PeiLaureatesPublic { groups, stats }`.
- [X] T025 [US2] Implémenter `list_public_laureates(type: PeiLaureateType | None)` dans `BE/app/services/entrepreneurship_service.py` : requête `PeiLaureate` joint `PeiCohort` avec `is_published IS TRUE AND PeiCohort.active IS TRUE` (+ filtre type), tri `PeiCohort.display_order, PeiLaureate.display_order, PeiLaureate.created_at`, groupement en mémoire par cohorte (cohortes sans portrait omises), photos par lot via `_load_media` + `_media_url`, `stats` = nombre de portraits, nombre de groupes, `max(grant_amount)` formaté `f"{value:.2f}"` ou `None`.
- [X] T026 [US2] Ajouter `GET /laureates` (query `type` optionnel, `response_model=PeiLaureatesPublic`, `_cache(response)`) dans `BE/app/routers/public/entrepreneurship.py`, **déclaré avant** les routes `/programs/{code}` et `/cohorts/{code}` existantes (placer le bloc en tête du fichier après `/programs` et `/cohorts` statiques, ou avant tout `/{code}`).
- [X] T027 [US2] Créer `BE/tests/integration/test_public_pei_api.py` (partie portraits) : groupes triés par `display_order` de cohorte puis de portrait ; portrait dépublié absent ; cohorte inactive absente avec ses portraits ; cohorte active sans portrait publié absente ; filtre `?type=student_entrepreneur` ; `stats` (`laureates`, `cohorts`, `max_grant_amount == "5000.00"`, `None` sans montant) ; `photo_url` résolue, absence de `photo_external_id` et `grant_amount` dans la réponse ; en-tête `Cache-Control` ; `quote_en` vide renvoyé tel quel.

**Checkpoint**: US2 validée par quickstart §4 ; T027 vert.

---

## Phase 5: User Story 3 - Composer les partenaires du pôle (Priority: P2)

**Goal**: page unique `/admin/entrepreneuriat/partenaires` : trois familles, sélecteur de partenaires existants, changement de famille, réordonnancement par famille, retrait ; aucun partenaire créé ici.

**Independent Test**: quickstart.md §5 (étapes 1–5, 7) — rattacher Campus France et AUF, déplacer, changer de famille, retirer ; le backoffice Partenaires reste intact ; audit `entrepreneurship.partner.*`.

### Backend US3

- [X] T028 [US3] Ajouter dans `BE/app/schemas/entrepreneurship.py` le bloc Partners admin : `PeiPartnerLinkCreate { partner_id: str, family: PeiPartnerFamily }`, `PeiPartnerLinkUpdate { family: PeiPartnerFamily }`, `PeiPartnerEmbedded { id, name, type, active, website, logo_url, description }`, `PeiPartnerLinkAdmin { partner_id, family, display_order, created_at, updated_at, partner: PeiPartnerEmbedded }`, `PeiPartnerAvailable { id, name, type, active, logo_url }`.
- [X] T029 [US3] Implémenter dans `BE/app/services/entrepreneurship_service.py` le bloc Partners : constante `PARTNER_FAMILY_ORDER = ["academic","support","international"]` ; `list_partner_links(family=None)` (`PeiPartner` + `selectinload(partner)`, tri rang de famille puis `display_order`, logos par lot) ; `list_available_partners(q, limit=20)` (recherche `Partner.name ILIKE %q%` ou `description`, `WHERE Partner.id NOT IN (SELECT partner_id FROM pei_partners)`, tri `active DESC, name`, limite ≤ 50) ; `link_partner(data, user_id, ip, ua)` : partenaire 404, 409 « Ce partenaire est déjà rattaché au pôle », `display_order = _next_display_order(PeiPartner, family=…)`, audit `entrepreneurship.partner.link` (`record_id = partner_id`, `table_name = "pei_partners"`) ; `update_partner_family(partner_id, family, …)` : dernière position de la nouvelle famille + `_renumber` de l'ancienne, audit `update` (old/new family) ; `unlink_partner(partner_id, …)` : suppression + `_renumber` de la famille, audit `unlink` ; `reorder_partner_links(family, ids, …)` → `_reorder(PeiPartner, …, scope={"family": family})` (clé primaire `partner_id` : adapter `_reorder` pour utiliser `model.__mapper__.primary_key[0]` au lieu de `model.id`) ; `_to_partner_link_admin(link, media_map)`.
- [X] T030 [US3] Ajouter dans `BE/app/routers/admin/entrepreneurship.py` le groupe `/partners` dans cet ordre : `GET /partners` (view, query `family` optionnel → `list[PeiPartnerLinkAdmin]`), `POST /partners` (create, 201), `PATCH /partners/reorder` (edit, `PeiPartnerReorderRequest`), `GET /partners/available` (view, query `q`, `limit` ≤ 50), `PATCH /partners/{partner_id}` (edit, `PeiPartnerLinkUpdate`), `DELETE /partners/{partner_id}` (delete, 204) ; `_client_meta` sur chaque écriture.
- [X] T031 [US3] Créer `BE/tests/integration/test_admin_pei_partners_api.py` (fixtures : 3 `Partner` dont un inactif) : 403 sans permission ; `GET /partners/available?q=` exclut les partenaires déjà rattachés et renvoie `logo_url` ; 201 rattachement → `display_order = 0` ; 409 doublon ; 404 partenaire inconnu ; 422 famille inconnue ; `PATCH /partners/{id}` changement de famille → dernière position, ancienne famille renumérotée ; `PATCH /partners/reorder` liste incomplète → 422, complète → 0..n-1 dans la famille seulement ; `DELETE /partners/{id}` → 204, partenaire toujours présent dans `partners` ; suppression du `Partner` en base → rattachement disparu (cascade) ; partenaire inactif rattaché → `partner.active == False` dans la liste admin ; audit `entrepreneurship.partner.link|update|unlink|reorder`.

### Frontend US3

- [X] T032 [US3] Ajouter dans `FE/composables/useEntrepreneurshipApi.ts` : `listPeiPartners(family?)` (`GET /partners`), `searchAvailablePartners(q, limit = 20)` (`GET /partners/available`), `linkPeiPartner(partnerId, family)` (`POST /partners`), `updatePeiPartnerFamily(partnerId, family)` (`PATCH /partners/{id}`), `unlinkPeiPartner(partnerId)` (`DELETE /partners/{id}`), `reorderPeiPartners(family, ids)` (`PATCH /partners/reorder` body `{ family, ids }`).
- [X] T033 [P] [US3] Créer `FE/components/entrepreneurship/admin/PartnerPicker.vue` (calqué sur `FE/components/admin/AlbumSelector.vue`, partie modale) : props `{ open: boolean, defaultFamily?: PeiPartnerFamily }`, emits `select(partnerId: string, family: PeiPartnerFamily)`, `close` ; `<Teleport to="body">`, overlay `@click.self`, Esc ; champ de recherche debouncé 300 ms → `searchAvailablePartners(q)` (chargement initial sans `q`), liste (logo `logo_url` ou initiale, nom, badge type via `partnerTypeLabels` / `partnerTypeColors` de `usePartnersApi`, badge « Inactif »), sélection unique (radio / surbrillance), `<select>` famille (`partnerFamilyOptions`, prérempli), bouton « Rattacher » désactivé sans sélection ; pied de modale : « Le partenaire n'existe pas ? Créez-le dans le backoffice Partenaires » → `<NuxtLink to="/admin/partenaires">` ; état vide « Aucun partenaire disponible ».
- [X] T034 [P] [US3] Créer `FE/components/entrepreneurship/admin/PartnerFamilyBoard.vue` : props `{ links: PeiPartnerLinkAdmin[], loading?, canEdit?, canDelete? }`, emits `changeFamily(partnerId, family)`, `unlink(partnerId)`, `reorder(family, ids)` ; trois sections dans l'ordre `partnerFamilyOptions` (titre, compteur), chacune un `VueDraggable` indépendant sur une copie locale filtrée par famille (`handle=".drag-handle"`, `:disabled="!canEdit"`, `onDragEnd` après `nextTick()` → `emit('reorder', family, ids)`) ; ligne : poignée, logo (`partner.logo_url` ou initiale), nom + type (badge), badge « Inactif » avec `title="Non visible publiquement"`, `<select>` famille (permission edit → `changeFamily`), lien « Ouvrir dans Partenaires » (`/admin/partenaires`, `target="_blank"`), bouton retirer (permission delete, `confirm('Retirer ce partenaire du pôle ? Il reste dans le backoffice Partenaires.')`) ; état vide par famille « Aucun partenaire rattaché ».
- [X] T035 [US3] Créer `FE/pages/admin/entrepreneuriat/partenaires/index.vue` : `definePageMeta({ layout: 'admin' })`, en-tête « Partenaires du pôle » avec bouton « Rattacher un partenaire » (permission create) et lien « Ouvrir le backoffice Partenaires » (`/admin/partenaires`), rappel « Les partenaires se créent et se modifient dans le backoffice Partenaires ; ici on les classe dans les trois familles du pôle » ; `listPeiPartners()` au montage ; `PartnerFamilyBoard` avec handlers `changeFamily` → `updatePeiPartnerFamily` puis rechargement, `unlink` → `unlinkPeiPartner`, `reorder` → `reorderPeiPartners(family, ids)` ; `PartnerPicker` avec `select` → `linkPeiPartner` puis rechargement ; messages d'erreur (`extractError`, 409 affiché tel quel) et succès temporisé.

**Checkpoint**: US3 validée par quickstart §5 (1–5, 7) ; T031 vert.

---

## Phase 6: User Story 4 - Lecture publique des partenaires du pôle enrichis (Priority: P2)

**Goal**: `GET /api/public/entrepreneurship/partners` : trois familles toujours présentes, partenaires actifs enrichis (nom, logo résolu, description trilingue, site), supprimés et inactifs absents.

**Independent Test**: quickstart.md §5 étapes 4 et 6 — après désactivation et suppression de deux partenaires rattachés, un seul reste dans la réponse, dans sa famille.

- [X] T036 [US4] Ajouter dans `BE/app/schemas/entrepreneurship.py` : `PeiPartnerPublic { id, name, description, description_en, description_ar, website, logo_url, type, display_order }` (aucun `logo_external_id`, aucun réseau social), `PeiPartnerFamilyPublic { family: PeiPartnerFamily, partners: list[PeiPartnerPublic] }`.
- [X] T037 [US4] Implémenter `list_public_partners()` dans `BE/app/services/entrepreneurship_service.py` : `PeiPartner` joint `Partner` avec `Partner.active IS TRUE`, tri rang de famille puis `display_order`, logos par lot, construction des **trois** groupes dans `PARTNER_FAMILY_ORDER` (listes vides incluses).
- [X] T038 [US4] Ajouter `GET /partners` (`response_model=list[PeiPartnerFamilyPublic]`, `_cache`) dans `BE/app/routers/public/entrepreneurship.py`, déclaré avant toute route `/{code}`.
- [X] T039 [US4] Compléter `BE/tests/integration/test_public_pei_api.py` (partie partenaires) : trois familles toujours renvoyées dans l'ordre fixe, famille vide = `[]` ; partenaire inactif absent ; suppression du `Partner` → absent sans erreur (200) ; `logo_url` résolue et `None` sans logo ; `description_en` présente ; aucune clé `logo_external_id` ; tri par `display_order`.

**Checkpoint**: US4 validée par quickstart §5 (4, 6) ; T039 vert.

---

## Phase 7: User Story 5 - Tableau de bord, barre latérale et traduction des champs manquants (Priority: P3)

**Goal**: deux compteurs et un raccourci de plus au tableau de bord, deux entrées de barre latérale, action « Traduire les champs manquants » étendue aux portraits.

**Independent Test**: quickstart.md §6 et §3 étape 1 — compteurs exacts, entrées visibles avec `entrepreneurship.view` seulement, traduction des verbatims vides.

- [X] T040 [US5] Étendre `get_dashboard_stats()` dans `BE/app/services/entrepreneurship_service.py` : `laureates = PeiPublishedCount(total, published)` (`count(id)`, `count(id) FILTER (WHERE is_published)`), `partners = PeiActiveCount(total, active)` (`count(PeiPartner.partner_id)`, `count(...) FILTER (WHERE Partner.active)` via jointure) ; renseigner les deux nouveaux champs de `PeiDashboardStats`.
- [X] T041 [US5] Étendre `translate_missing()` dans `BE/app/services/entrepreneurship_service.py` : ajouter `("laureates", PeiLaureate, _LAUREATE_TRANSLATABLE)` à la boucle (tri `cohort_id, display_order`), appliquer `_clamp_quote` après `autofill_translations` dans `_translate_missing_for` quand le modèle est `PeiLaureate` ; renseigner `laureates` dans `PeiTranslateMissingResponse`.
- [X] T042 [US5] Compléter `BE/tests/integration/test_admin_pei_laureates_api.py` : `GET /dashboard` renvoie `laureates.published/total` et `partners.active/total` corrects ; `POST /translate-missing` remplit `quote_en` vide sans toucher `quote_ar` renseigné, `laureates == 1` puis `0` au second appel.
- [X] T043 [P] [US5] Ajouter dans `FE/composables/useAdminSidebar.ts`, dans `children` de la section `entrepreneurship`, après `entrepreneurship-cohorts` et avant `entrepreneurship-resources` : `{ id: 'entrepreneurship-laureates', label: 'Lauréats et étudiants-entrepreneurs', icon: 'fa-solid fa-award', route: '/admin/entrepreneuriat/laureats', permissions: ['entrepreneurship.view'] }` et `{ id: 'entrepreneurship-partners', label: 'Partenaires du pôle', icon: 'fa-solid fa-handshake', route: '/admin/entrepreneuriat/partenaires', permissions: ['entrepreneurship.view'] }`.
- [X] T044 [P] [US5] Étendre `FE/components/entrepreneurship/admin/DashboardCards.vue` : ajouter `amber` et `red` au map `colorClasses` ; cartes « Lauréats et étudiants-entrepreneurs » (`fa-solid fa-award`, `amber`, `to: '/admin/entrepreneuriat/laureats'`, `count: stats.laureates.published`, `total: stats.laureates.total`, badge « Publiés ») et « Partenaires du pôle » (`fa-solid fa-handshake`, `red`, `to: '/admin/entrepreneuriat/partenaires'`, `count: stats.partners.active`, `total: stats.partners.total`, badge « Actifs ») ; grille passée à 5 colonnes responsive (`sm:grid-cols-2 xl:grid-cols-5`).
- [X] T045 [US5] Étendre `FE/pages/admin/entrepreneuriat/index.vue` : message de fin de « Traduire les champs manquants » incluant `laureates` (« … , N lauréats complétés ») et cumul sur les relances ; ajouter au bloc « Géré ailleurs » le raccourci `{ id: 'partners', label: 'Partenaires (fiches)', icon: 'fa-solid fa-handshake', to: '/admin/partenaires', convention: 'Créer ou modifier un partenaire ici, puis le rattacher dans « Partenaires du pôle »' }`.

**Checkpoint**: US5 validée par quickstart §6 ; T042 vert ; `pnpm build` sans erreur.

---

## Phase 8: User Story 6 - Rattachement initial des partenaires du cahier des charges (Priority: P3)

**Goal**: vérifier que le bloc de rattachement initial de la migration 046 (T003) rattache sans créer, ignore les absents, et reste idempotent, en local puis en production.

**Independent Test**: quickstart.md §1 (partie rattachement) et §9 — sur une base contenant « Campus France » et « AUF », deux passages rattachent une seule fois chacun ; un partenaire déplacé par un éditeur n'est pas remis dans sa famille initiale.

- [X] T046 [US6] Vérifier localement le bloc de rattachement de `SQL/migrations/046_pei_laureates_partners.sql` : créer en base locale un partenaire « Campus France » et un « Agence universitaire de la Francophonie (AUF) » (via le backoffice Partenaires), rejouer la migration → rattachés dans `academic` et `international` ; déplacer AUF en `support` depuis la page « Partenaires du pôle », rejouer → AUF reste en `support` ; `count(partners)` inchangé ; `NOTICE` pour les motifs sans correspondance ; documenter le résultat dans `specs/022-pei-laureates-partners/quickstart.md` (section « Écarts constatés »).
- [X] T047 [US6] Exécuter en **lecture seule** sur la production la requête de quickstart.md §9 (`SELECT id, name, active FROM partners WHERE name ~* '…'` sur `usenghor_db`) ; comparer les correspondances aux sept partenaires attendus, ajuster les motifs de T003 (apostrophe typographique ’, casse, sigles entre parenthèses) si un partenaire attendu manque ou si un motif attrape un partenaire étranger ; consigner les noms réels dans `specs/022-pei-laureates-partners/research.md` R13.

**Checkpoint**: migration prête pour la production (quickstart §9).

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: qualité, documentation, validation de bout en bout.

- [X] T048 Exécuter la suite backend complète (`cd usenghor_backend && pytest tests/integration/test_admin_entrepreneurship_api.py tests/integration/test_public_entrepreneurship_api.py tests/integration/test_admin_pei_laureates_api.py tests/integration/test_admin_pei_partners_api.py tests/integration/test_public_pei_api.py tests/unit/test_entrepreneurship_service.py -v`) : tous verts ; les tests 021 ne régressent pas (`DELETE /cohorts/{id}` sans portrait → 204, `reorder` sans portée inchangé).
- [X] T049 [P] Exécuter `cd usenghor_nuxt && pnpm build` sans erreur TypeScript ; corriger les types (`PeiDashboardStats` étendu consommé par `DashboardCards`, `FeaturedStatus`, payloads).
- [X] T050 Dérouler `specs/022-pei-laureates-partners/quickstart.md` §3 à §6 avec un compte `editor` et un compte sans permission ; consigner les écarts dans quickstart.md (section « Écarts constatés lors de la validation »).
- [X] T051 [P] Mettre à jour `CLAUDE.md` : ligne `16_entrepreneurship.sql` du tableau SQL complétée (`pei_laureates`, `pei_partners`), tableau « Composants clés » (`components/entrepreneurship/admin/*` : lauréats, partenaires ; `useEntrepreneurshipApi()` : lauréats, partenaires), entrée « Recent Changes » 022 (migration 046 + rattachement initial, rollback 046 avant 045, ordre par cohorte / famille, endpoints publics `/laureates` et `/partners`).
- [X] T052 [P] Mettre à jour `specs/roadmap-pei-entrepreneuriat.md` § 2.4 (`pei_partners` : colonne `partner_id` avec FK cascade au lieu de `partner_external_id`) et mentionner la feature 022 comme livrée (portée : ordre par cohorte, verbatim texte simple, chiffres calculés).
- [ ] T053 Production (après merge et `./deploy.sh`) : `./deploy.sh backup`, jouer `046_pei_laureates_partners.sql` deux fois sur `usenghor_db` (quickstart §9), vérifier les rattachements initiaux dans le backoffice « Partenaires du pôle » et corriger à la main tout rattachement inattendu.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)** : T001 (accord SQL) bloque T002–T006 ; T002, T004, T005 parallèles ; T003 après T002 ; T006 après T003–T004.
- **Foundational (Phase 2)** : après Phase 1 ; T007 → T008 → T009 (même fichiers backend en chaîne) ; T010, T011 parallèles côté frontend.
- **US1 (Phase 3)** : après Phase 2 ; backend T012 → T013 → T014 → T015 → T016 (T017 parallèle à T016) ; frontend T018 → {T019, T020} → T021 → {T022, T023}. Frontend US1 peut démarrer dès T015 terminé.
- **US2 (Phase 4)** : après T013 (service lauréats) ; T024 → T025 → T026 → T027. Indépendante du frontend US1.
- **US3 (Phase 5)** : après Phase 2 (indépendante de US1/US2) ; backend T028 → T029 → T030 → T031 ; frontend T032 → {T033, T034} → T035.
- **US4 (Phase 6)** : après T029 ; T036 → T037 → T038 → T039.
- **US5 (Phase 7)** : après T013 et T029 (compteurs) ; T040, T041 en chaîne (même fichier), T042 après ; T043, T044 parallèles ; T045 après T044.
- **US6 (Phase 8)** : après T006 et T035 (page partenaires pour déplacer un rattachement) ; T047 après T046.
- **Polish (Phase 9)** : après toutes les stories retenues ; T053 après merge.

### Within Each User Story

- Schémas → service → routeur → tests (backend) ; composable → composants → pages (frontend).
- Les tâches touchant le même fichier (`entrepreneurship_service.py`, `schemas/entrepreneurship.py`, routeurs, composable) sont séquentielles ; les composants et pages distincts sont parallèles.

### Parallel Opportunities

- Phase 1 : T002 ∥ T004 ∥ T005 (après T001).
- Phase 2 : T010 ∥ T011 ∥ (T007 → T008 → T009).
- US1 : T019 ∥ T020 ; T022 ∥ T023 ; T017 ∥ T016.
- US3 : T033 ∥ T034.
- US1 backend ∥ US3 backend impossible (même service et routeur) : enchaîner US1 puis US3 pour le backend ; le frontend US3 (T032–T035) peut avancer pendant les tests backend de US1.
- US2 ∥ US3 frontend ; US4 ∥ US5 frontend.
- Polish : T049 ∥ T051 ∥ T052.

---

## Parallel Example: User Story 1

```bash
# Après T018 (composable), composants en parallèle :
Task: "T019 Créer FE/components/entrepreneurship/admin/LaureateList.vue"
Task: "T020 Créer FE/components/entrepreneurship/admin/LaureateForm.vue"

# Après T021 (liste), pages en parallèle :
Task: "T022 Créer FE/pages/admin/entrepreneuriat/laureats/nouveau.vue"
Task: "T023 Créer FE/pages/admin/entrepreneuriat/laureats/[id].vue"

# Tests backend en parallèle :
Task: "T016 tests/integration/test_admin_pei_laureates_api.py"
Task: "T017 tests/unit/test_entrepreneurship_service.py"
```

---

## Implementation Strategy

### MVP First (User Story 1 + User Story 2)

1. Phase 1 : accord SQL (T001) puis migration jouée deux fois (T006).
2. Phase 2 : modèles, helpers scopés, types.
3. Phase 3 : portraits en backoffice (US1) → quickstart §3.
4. Phase 4 : lecture publique des portraits (US2) → quickstart §4 : le critère d'acceptation principal (« retrouver le lauréat dans l'endpoint public sous sa cohorte ») est démontrable.
5. **STOP et valider** avant les partenaires.

### Incremental Delivery

1. Setup + Foundational → schéma et socle prêts.
2. US1 → US2 → démo « portraits » (MVP).
3. US3 → US4 → démo « partenaires du pôle » (critère « disparaît sans erreur »).
4. US5 → tableau de bord et navigation complets.
5. US6 → migration validée sur les noms réels de production.
6. Polish → tests complets, build, CLAUDE.md, production.

### Parallel Team Strategy

- Développeur A : backend (Phase 2 → US1 → US3 → US2 → US4 → US5 backend) — un seul service et un seul routeur, donc en série.
- Développeur B : frontend (Phase 2 types/composable → US1 pages → US3 pages → US5) dès que les routes correspondantes existent.
- Développeur C : US6 (motifs de production) et Polish (CLAUDE.md, roadmap) en fin de cycle.

---

## Notes

- [P] = fichiers différents, aucune dépendance sur une tâche inachevée.
- Aucune nouvelle permission : tout `PermissionChecker` utilise `entrepreneurship.view|create|edit|delete` déjà seedées (045).
- Ordre de déclaration des routes : `/reorder`, `/translate`, `/available` **avant** `/{id}` ; routes publiques `/laureates` et `/partners` **avant** `/{code}`.
- Verbatim : 600 caractères par langue (SQL `CHECK` + Pydantic + clamp des traductions automatiques).
- Rollback : 046 avant 045.
- Ne jamais créer ni modifier un partenaire depuis le pôle ; tester les motifs de rattachement en lecture seule sur la production avant de migrer (mémoire projet : apostrophe typographique ’ dans les noms).
- Valider chaque story à son checkpoint avant de passer à la suivante ; committer par groupe logique.
