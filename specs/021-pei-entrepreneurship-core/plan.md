# Implementation Plan: Socle du Pôle Entrepreneuriat et Innovation (PEI)

**Branch**: `021-pei-entrepreneurship-core` | **Date**: 2026-09-13 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/021-pei-entrepreneurship-core/spec.md`

## Summary

Créer le socle données + API + backoffice du pôle PEI (dispositifs, cohortes, ressources), sans page publique : un fichier de schéma `16_entrepreneurship.sql` et une migration 045 rejouable (tables, ENUM, permissions, données initiales FR, clés éditoriales), un domaine FastAPI `entrepreneurship` copié du gabarit FAQ (service avec audit explicite, traduction automatique via `autofill_translations`, routeurs admin et public), une section admin Nuxt « Entrepreneuriat (PEI) » (tableau de bord + 3 CRUD en pages dédiées, glisser-déposer `vue-draggable-plus`, éditeur riche modal, nouveau sélecteur de médiathèque transverse) et une page éditoriale « Entrepreneuriat » (43 clés) éditable dans « Valeurs ». Décision structurante : convention de colonnes **additive** (`title`, `title_en`, `title_ar` ; `content_html`, `content_en_html`…), seule compatible avec `autofill_translations` et `useLocalizedField` ([research.md](research.md) R1).

## Technical Context

**Language/Version**: Python 3.14 (backend), TypeScript 5.x / Vue 3 Composition API (frontend)

**Primary Dependencies**: FastAPI, SQLAlchemy 2 async (asyncpg), Pydantic v2, deep-translator (existant) ; Nuxt 4, Tailwind CSS, `@nuxtjs/i18n`, `vue-draggable-plus` ^0.6.1 (déjà installé), TOAST UI Editor via `AdminRichTextEditor`. **Aucune nouvelle dépendance.**

**Storage**: PostgreSQL 16 (Docker `usenghor_postgres` local / `usenghor_db` prod) — 3 nouvelles tables `pei_*`, 3 types ENUM, lignes dans `permissions`, `role_permissions`, `editorial_contents`, `audit_logs`

**Testing**: backend `pytest` (base `usenghor_test`, fixtures `authenticated_client` / `admin_role`) ; frontend : pas d'infrastructure de test (validation manuelle [quickstart.md](quickstart.md) + `pnpm lint` + `pnpm build`)

**Target Platform**: serveur Linux Docker (nginx + Nuxt SSR + FastAPI + PostgreSQL)

**Project Type**: application web (monorepo backend + frontend)

**Performance Goals**: listes publiques < 1 s pour 100 éléments (SC-007) — trivial avec index `(active, display_order)` et cache HTTP 60 s

**Constraints**: routes statiques avant dynamiques ; toute permission `PermissionChecker` seedée en base ; noms de fichiers `[a-z0-9_-]` ; français accentué dans le code et les contenus ; migration idempotente + rollback ; SQL validé avant le code (FR-005) ; aucune page publique, aucune table lauréats/partenaires, aucun changement d'organigramme

**Scale/Scope**: ~5–20 dispositifs, ~10 cohortes, ~50 ressources ; 10 pages admin, 8 composants, 1 composable, 1 domaine backend (~6 fichiers Python), 3 fichiers de test, 3 fichiers SQL

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` est le gabarit non rempli : aucun principe formel. Les portes appliquées sont les conventions de `CLAUDE.md` et de la feuille de route PEI § 1 :

| Porte | Statut | Preuve |
|---|---|---|
| Structure BDD : accord → SQL de référence → migration → code | ✅ prévu | data-model.md §4 = proposition à valider (FR-005) ; `16_entrepreneurship.sql` + `045_*.sql` + rollback avant tout code Python |
| Réutiliser avant de créer (sous-agent sur `components/`) | ✅ fait | 4 sous-agents : aucun picker média ni liste triable réutilisables → R4, R5 ; `AdminRichTextEditor`, `RichTextRenderer`, `useMediaApi`, `useApi`, `usePermissions` réutilisés |
| Trilingue avec traduction auto + repli FR | ✅ | R1 (convention additive), R8 |
| Contenu riche double colonne `_html` + `_md` | ✅ | `content_*`, `summary_*` |
| Permissions seedées pour tout `PermissionChecker` | ✅ | 4 codes, migration + `99_data_init.sql` (R10) |
| Routes statiques avant dynamiques | ✅ | contracts/admin-api.md, public-api.md |
| Audit de chaque écriture | ✅ | R3 (explicite, comme FAQ) |
| Noms de fichiers sans accents | ✅ | `entrepreneuriat/`, `16_entrepreneurship.sql`, `045_entrepreneurship.sql` |
| Pas de nouvelle dépendance | ✅ | `vue-draggable-plus` déjà présent |
| CLAUDE.md maintenu | ✅ prévu | quickstart §8 |

**Écart à signaler** : la convention additive (R1) diffère de la ligne « Champs trilingues : `*_fr`, `*_en`, `*_ar` » de CLAUDE.md, qui décrit la FAQ ; elle est justifiée par la réutilisation imposée de `autofill_translations` / `useLocalizedField` et correspond à 7 domaines existants. CLAUDE.md sera précisé (« convention additive pour les domaines à traduction automatique »).

**Re-check post-design (Phase 1)** : aucune violation ; un composant transverse nouveau (`AdminMediaPicker`) est justifié par l'absence totale d'équivalent (R5) et bénéficie aux features 022+.

## Project Structure

### Documentation (this feature)

```text
specs/021-pei-entrepreneurship-core/
├── plan.md              # Ce fichier
├── research.md          # Phase 0 — 14 décisions (R1–R14)
├── data-model.md        # Phase 1 — entités, SQL proposé (à valider), migration, rollback
├── quickstart.md        # Phase 1 — scénarios de validation
├── contracts/
│   ├── admin-api.md     # /api/admin/entrepreneurship/*
│   ├── public-api.md    # /api/public/entrepreneurship/*
│   ├── editorial-keys.md# 43 clés de la page « Entrepreneuriat »
│   └── frontend.md      # routes admin, sidebar, composable, composants
├── checklists/requirements.md
└── tasks.md             # Phase 2 (/speckit-tasks)
```

### Source Code (repository root)

```text
usenghor_backend/
├── documentation/modele_de_données/
│   ├── services/16_entrepreneurship.sql            # nouveau (schéma de référence)
│   ├── services/main.sql                            # + \i 16_entrepreneurship.sql (avant 99_*)
│   ├── services/99_data_init.sql                    # + permissions entrepreneurship.* (base neuve)
│   └── migrations/045_entrepreneurship.sql          # nouveau, + 045_entrepreneurship_rollback.sql
├── app/models/entrepreneurship.py                   # PeiProgram, PeiCohort, PeiResource + enums
├── app/models/__init__.py                           # export
├── app/schemas/entrepreneurship.py                  # Create/Update/Admin/Public/Reorder/Translate/Dashboard
├── app/services/entrepreneurship_service.py         # CRUD, reorder, toggle, translate, dashboard, audit
├── app/routers/admin/entrepreneurship.py            # prefix /entrepreneurship
├── app/routers/admin/__init__.py                    # include_router
├── app/routers/public/entrepreneurship.py
├── app/routers/public/__init__.py
└── tests/
    ├── integration/test_admin_entrepreneurship_api.py
    ├── integration/test_public_entrepreneurship_api.py
    └── unit/test_entrepreneurship_service.py

usenghor_nuxt/app/
├── types/api/entrepreneurship.ts                    # types admin + public
├── types/api/editorial.ts                           # + 43 ValueSectionKey
├── composables/useEntrepreneurshipApi.ts            # nouveau
├── composables/useAdminSidebar.ts                   # + section « Entrepreneuriat (PEI) »
├── composables/usePermissions.ts                    # + ROUTE_PERMISSIONS['/admin/entrepreneuriat']
├── composables/editorial-pages-config.ts            # + entrepreneurshipPageSections + frontOfficePages entry
├── components/admin/MediaPicker.vue                 # nouveau, transverse (<AdminMediaPicker>)
├── components/entrepreneurship/admin/
│   ├── LangTabs.vue, DashboardCards.vue
│   ├── ProgramList.vue, ProgramForm.vue
│   ├── CohortList.vue, CohortForm.vue
│   └── ResourceList.vue, ResourceForm.vue
└── pages/admin/entrepreneuriat/
    ├── index.vue                                    # tableau de bord
    ├── dispositifs/{index,nouveau,[id]}.vue
    ├── cohortes/{index,nouveau,[id]}.vue
    └── ressources/{index,nouveau,[id]}.vue

CLAUDE.md                                            # tableau SQL, composants clés, Recent Changes
```

**Structure Decision**: application web monorepo existante ; le backend suit le découpage par domaine (`models/schemas/services/routers`) et le frontend le gabarit FAQ « pages minces + composants par feature ». Aucun nouveau dossier de premier niveau.

## Phase 0 — Research (terminée)

Voir [research.md](research.md). Points résolus : convention de colonnes (R1), gabarit backend (R2), audit (R3), glisser-déposer (R4), sélecteur média (R5), identification DDE par UUID — **la spec est corrigée : clé `entrepreneurship.dde_service_id`** (R6), page éditoriale et chiffres clés (R7), traduction et action en lot (R8), lecture publique (R9), permissions et protection de route (R10), libellés FR (R11), structure des pages (R12), tests (R13), rejeu/rollback (R14). Aucun `NEEDS CLARIFICATION` restant.

## Phase 1 — Design (terminée)

- [data-model.md](data-model.md) : 3 entités, règles, transitions, **SQL complet à valider (FR-005)**, structure de la migration 045 et du rollback, seeds.
- [contracts/admin-api.md](contracts/admin-api.md), [contracts/public-api.md](contracts/public-api.md), [contracts/editorial-keys.md](contracts/editorial-keys.md), [contracts/frontend.md](contracts/frontend.md).
- [quickstart.md](quickstart.md) : 9 blocs de validation couvrant SC-001 à SC-008.

## Ordre d'implémentation recommandé (pour /speckit-tasks)

1. **Porte FR-005** : présenter data-model.md §4–6 au responsable ; attendre l'accord explicite.
2. SQL : `16_entrepreneurship.sql`, `main.sql`, `99_data_init.sql`, `045_entrepreneurship.sql` + rollback ; jouer deux fois en local (quickstart §1).
3. Backend : modèles → schémas → service (+ audit, traduction, reorder, toggle, dashboard, translate-missing) → routeurs admin/public → enregistrement → tests pytest.
4. Frontend transverse : types, `ValueSectionKey`, `editorial-pages-config.ts`, `usePermissions.ts`, `useAdminSidebar.ts`, `AdminMediaPicker`.
5. Frontend PEI : composable → composants (LangTabs, listes, formulaires) → pages dispositifs (US1) → cohortes (US2) → ressources (US3) → tableau de bord (US4).
6. `pnpm lint`, `pnpm build`, quickstart §3–7, CLAUDE.md.

## Complexity Tracking

Aucune violation de porte à justifier. Un composant transverse nouveau (`AdminMediaPicker`) : besoin réel confirmé par exploration (aucun équivalent), alternative « saisie d'UUID » rejetée car inutilisable par un éditeur.
