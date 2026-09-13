# Implementation Plan: Lauréats, étudiants-entrepreneurs et partenaires du pôle PEI (backoffice)

**Branch**: `022-pei-laureates-partners` | **Date**: 2026-09-13 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/022-pei-laureates-partners/spec.md`

## Summary

Étendre le socle PEI (feature 021) avec deux entités et leur backoffice, sans page publique : une table `pei_laureates` (portraits de lauréats FSE et d'étudiants-entrepreneurs, cohorte obligatoire et cohérente avec le type, département et verbatim trilingues en texte simple, photo médiathèque, cinq liens, montant, mis en avant, publié, ordre **par cohorte**) et une table de liaison `pei_partners` (clé primaire = `partners.id` avec suppression en cascade, famille fixe `academic | support | international`, ordre **par famille**), livrées dans `16_entrepreneurship.sql` + migration 046 rejouable (avec rattachement initial des partenaires du cahier des charges, sans création) + rollback. Le domaine backend `entrepreneurship` existant reçoit deux blocs CRUD (reorder scopé, publication, mise en avant, traduction automatique, audit explicite, activation du 409 « cohorte utilisée par N lauréats »), deux lectures publiques (portraits groupés par cohorte active avec chiffres calculés ; partenaires enrichis groupés en trois familles, inactifs exclus). Le frontend ajoute trois pages « laureats », une page « partenaires », cinq composants (listes, formulaire, tableau par famille, sélecteur de partenaires calqué sur `AlbumSelector`), deux entrées de barre latérale et deux compteurs au tableau de bord. Aucune nouvelle permission, aucune nouvelle dépendance. Décisions : [research.md](research.md) R1–R16.

## Technical Context

**Language/Version**: Python 3.14 (backend), TypeScript 5.x / Vue 3 Composition API (frontend)

**Primary Dependencies**: FastAPI, SQLAlchemy 2 async (asyncpg), Pydantic v2, deep-translator via `autofill_translations` ; Nuxt 4, Tailwind CSS, `vue-draggable-plus` (déjà installé), `AdminMediaPicker`, `EntrepreneurshipAdminLangTabs`. **Aucune nouvelle dépendance.**

**Storage**: PostgreSQL 16 (Docker `usenghor_postgres` local / `usenghor_db` prod) — 2 nouvelles tables `pei_laureates`, `pei_partners`, 2 types ENUM, lignes dans `audit_logs` ; FK réelles vers `pei_cohorts` (RESTRICT) et `partners` (CASCADE)

**Testing**: backend `pytest` (fixtures `authenticated_client`, `admin_role`, fixture locale `entrepreneurship_permissions` de 021) ; 3 nouveaux fichiers d'intégration + extension du test unitaire ; frontend : validation manuelle ([quickstart.md](quickstart.md)) + `pnpm build` (pas de `pnpm lint` dans le projet)

**Target Platform**: serveur Linux Docker (nginx + Nuxt SSR + FastAPI + PostgreSQL)

**Project Type**: application web (monorepo backend + frontend)

**Performance Goals**: lectures publiques < 1 s pour 100 portraits et 50 partenaires (SC-010) — une requête jointe + chargement des médias par lot + cache HTTP 60 s

**Constraints**: SQL validé avant le code (FR-005) ; routes statiques avant dynamiques ; aucune nouvelle permission (`entrepreneurship.*` réutilisées) ; noms de fichiers `[a-z0-9_-]` ; français accentué ; migration idempotente + rollback (046 avant 045) ; verbatim ≤ 600 caractères ; aucun UUID de média en public ; aucune création de partenaire depuis le pôle ; aucune page publique

**Scale/Scope**: ~15–60 portraits, ~10 partenaires rattachés ; 4 pages admin, 4 nouveaux composants + 1 modifié, 1 composable et 1 fichier de types étendus, 5 fichiers backend étendus, 3 fichiers de test nouveaux + 1 étendu, 3 fichiers SQL (1 étendu, 2 nouveaux) + 1 en-tête annoté

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` est le gabarit non rempli : les portes sont les conventions de `CLAUDE.md`, de la feuille de route PEI § 1 et de la description de la feature.

| Porte | Statut | Preuve |
|---|---|---|
| Structure BDD : accord → SQL de référence → migration → code | ✅ prévu | data-model.md §4–6 = proposition à valider (quickstart §0) ; aucun code avant l'accord |
| Étendre les fichiers 021, pas de domaine parallèle | ✅ | R1 : mêmes modèles / schémas / service / routeurs / composable / types |
| Réutiliser avant de créer (sous-agent sur `components/`) | ✅ fait | 2 sous-agents : `AdminMediaPicker`, `LangTabs`, listes `VueDraggable`, `AlbumSelector` (gabarit du picker) réutilisés ; aucun sélecteur de partenaires ni carte lauréat existants → R7, R15 |
| Trilingue additif + traduction auto + repli FR | ✅ | `department_label*`, `quote*` ; `autofill_translations` ; `useLocalizedField` côté 024 |
| `AdminRichTextEditor` en `mode="modal"` | ✅ sans objet | aucun contenu riche (clarification Q4) |
| Permissions seedées pour tout `PermissionChecker` | ✅ | aucune nouvelle permission ; codes `entrepreneurship.*` déjà en base (045) |
| Routes statiques avant dynamiques | ✅ | contracts/admin-api.md (`/reorder`, `/translate`, `/available` avant `/{id}`), public-api.md |
| Audit de chaque écriture | ✅ | data-model.md §2.5 (12 actions) |
| Noms de fichiers sans accents | ✅ | `laureats/`, `partenaires/`, `046_pei_laureates_partners*.sql` |
| Pas de nouvelle dépendance | ✅ | R15 |
| CLAUDE.md maintenu | ✅ prévu | quickstart §8 |

**Écart à signaler** : `pei_partners.partner_id` porte une vraie FK avec cascade, alors que la convention projet référence les autres services « sans FK » (`*_external_id`). Justifié par l'exigence explicite de la feature (suppression en cascade) et le critère « disparaît sans erreur » (R5) ; nommage `partner_id` pour ne pas usurper la convention `*_external_id`.

**Re-check post-design (Phase 1)** : aucune violation. Quatre nouveaux composants PEI (liste, formulaire, tableau par famille, sélecteur) sont chacun justifiés par l'absence d'équivalent ; le sélecteur reprend le gabarit `AlbumSelector`.

## Project Structure

### Documentation (this feature)

```text
specs/022-pei-laureates-partners/
├── plan.md              # Ce fichier
├── research.md          # Phase 0 — 16 décisions (R1–R16)
├── data-model.md        # Phase 1 — entités, SQL proposé (à valider), migration 046, rollback
├── quickstart.md        # Phase 1 — scénarios de validation (§0 porte SQL → §9 production)
├── contracts/
│   ├── admin-api.md     # /api/admin/entrepreneurship/{laureates,partners,dashboard,translate-missing}
│   ├── public-api.md    # /api/public/entrepreneurship/{laureates,partners}
│   └── frontend.md      # routes admin, sidebar, composable, composants, tableau de bord
├── checklists/requirements.md
└── tasks.md             # Phase 2 (/speckit-tasks)
```

### Source Code (repository root)

```text
usenghor_backend/
├── documentation/modele_de_données/
│   ├── services/16_entrepreneurship.sql                       # + 2 ENUM, pei_laureates, pei_partners, index
│   └── migrations/046_pei_laureates_partners.sql              # nouveau (tables, triggers, rattachement initial)
│   └── migrations/046_pei_laureates_partners_rollback.sql     # nouveau
│   └── migrations/045_entrepreneurship_rollback.sql           # en-tête : « jouer 046 rollback d'abord »
├── app/models/entrepreneurship.py                             # + PeiLaureateType, PeiPartnerFamily, PeiLaureate, PeiPartner
├── app/models/__init__.py                                     # export
├── app/schemas/entrepreneurship.py                            # + schémas lauréats / partenaires, dashboard et translate étendus
├── app/services/entrepreneurship_service.py                   # + blocs Laureates / Partners, _reorder scopé, _assert_cohort_deletable activé,
│                                                              #   _assert_laureate_cohort, _clamp_quote, dashboard + translate_missing étendus
├── app/routers/admin/entrepreneurship.py                      # + routes /laureates/*, /partners/*
├── app/routers/public/entrepreneurship.py                     # + GET /laureates, GET /partners
└── tests/
    ├── integration/test_admin_pei_laureates_api.py            # nouveau
    ├── integration/test_admin_pei_partners_api.py             # nouveau
    ├── integration/test_public_pei_api.py                     # nouveau
    └── unit/test_entrepreneurship_service.py                  # étendu

usenghor_nuxt/app/
├── types/api/entrepreneurship.ts                              # + types lauréats / partenaires, dashboard étendu
├── composables/useEntrepreneurshipApi.ts                      # + options, labels, 15 fonctions
├── composables/useAdminSidebar.ts                             # + 2 enfants (laureats, partenaires)
├── components/entrepreneurship/admin/
│   ├── LaureateList.vue, LaureateForm.vue                     # nouveaux (copies de CohortList / CohortForm)
│   ├── PartnerFamilyBoard.vue, PartnerPicker.vue              # nouveaux (picker calqué sur admin/AlbumSelector.vue)
│   └── DashboardCards.vue                                     # + 2 cartes
└── pages/admin/entrepreneuriat/
    ├── index.vue                                              # compteurs, message translate-missing, raccourci Partenaires
    ├── laureats/{index,nouveau,[id]}.vue                      # nouveaux
    └── partenaires/index.vue                                  # nouveau

CLAUDE.md                                                      # tableau SQL, composants clés, Recent Changes
```

**Structure Decision**: extension in situ du domaine `entrepreneurship` (backend par domaine, frontend « pages minces + composants par feature »), aucun nouveau dossier de premier niveau, aucun fichier parallèle au socle 021.

## Phase 0 — Research (terminée)

Voir [research.md](research.md) : extension du domaine (R1), reorder scopé par cohorte / famille (R2), cohérence type ↔ cohorte (R3), 409 suppression de cohorte (R4), FK cascade et nommage `partner_id` (R5), jointure partenaires et exclusion des inactifs (R6), recherche `/partners/available` et picker (R7), réponse publique groupée + stats (R8), montant (R9), liens (R10), verbatim 600 + clamp (R11), mise en avant (R12), rattachement initial par motifs (R13), migration 046 et rollbacks (R14), composants et pages (R15), tests (R16). Aucun `NEEDS CLARIFICATION` restant.

## Phase 1 — Design (terminée)

- [data-model.md](data-model.md) : 2 entités, règles, transitions, **SQL complet à valider (FR-005)**, structure de la migration 046 (dont rattachement initial et renumérotation) et du rollback, annotation du rollback 045.
- [contracts/admin-api.md](contracts/admin-api.md), [contracts/public-api.md](contracts/public-api.md), [contracts/frontend.md](contracts/frontend.md).
- [quickstart.md](quickstart.md) : 10 blocs (§0 porte SQL → §9 production) couvrant SC-001 à SC-011, avec la vérification en lecture seule des motifs de rattachement sur la base de production.

## Ordre d'implémentation recommandé (pour /speckit-tasks)

1. **Porte FR-005** : présenter data-model.md §4–6 ; attendre l'accord explicite.
2. SQL : `16_entrepreneurship.sql` (ajouts + en-tête), `046_pei_laureates_partners.sql`, rollback 046, en-tête du rollback 045 ; jouer deux fois en local (quickstart §1) ; vérifier le rattachement initial sur une base contenant au moins un partenaire cité.
3. Backend : modèles + export → schémas → service (helper `_reorder` scopé, `_assert_laureate_cohort`, `_clamp_quote`, bloc Laureates, bloc Partners, `_assert_cohort_deletable`, dashboard, translate-missing) → routeurs admin (ordre des routes) et public → tests pytest (021 + 022 verts).
4. Frontend transverse : types, composable, `useAdminSidebar.ts`, `DashboardCards.vue`, `index.vue`.
5. Frontend PEI : `LaureateList` / `LaureateForm` → pages `laureats/*` (US1) → `PartnerPicker` / `PartnerFamilyBoard` → page `partenaires/index.vue` (US3).
6. `pnpm build`, quickstart §3–7, CLAUDE.md (§8).

## Complexity Tracking

Aucune violation de porte à justifier. La FK avec cascade vers `partners` (écart à la convention « sans FK inter-service ») est imposée par la description de la feature et justifiée en R5 ; l'alternative « référence nue + nettoyage à la lecture » laisserait des rattachements orphelins et des compteurs faux.
