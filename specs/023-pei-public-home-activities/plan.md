# Implementation Plan: Mini-site public « Entreprendre à Senghor » — accueil et « Nos activités »

**Branch**: `023-pei-public-home-activities` | **Date**: 2026-09-13 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/023-pei-public-home-activities/spec.md`

## Summary

Ouvrir le mini-site public du Pôle Entrepreneuriat et Innovation avec deux pages Nuxt SSR, `/entrepreneuriat` (accueil : hero slider, sous-navigation collante, présentation + chiffres clés, parcours en cartes, citation / impact, actualités DDE, partenaires par famille, appel à l'action) et `/entrepreneuriat/activites` (un bloc par phase avec contenu riche, événements à venir de la DDE), en réutilisant les briques du site : `PageHero` étendu de props optionnelles `images[]` / `badge` (slider accessible, `prefers-reduced-motion`, pause au survol / focus, première image SSR), layout par défaut, `RichTextRenderer`, carte d'actualité **extraite** de `/actualites`, lectures publiques des features 021 / 022 via un nouveau composable `usePublicEntrepreneurshipApi`, copie via `useEditorialContent('entrepreneurship')`. Côté backend, un seul ajout additif : filtre `service_id` + `order` sur `GET /api/public/events` (aucun changement de schéma). Une migration 047 seed les 4 clés éditoriales du hero de « Nos activités » (accord sur le SQL avant le code). Décisions détaillées dans [research.md](research.md) (R1–R17).

## Technical Context

**Language/Version**: TypeScript 5.x / Vue 3 Composition API (Nuxt 4) côté frontend ; Python 3.14 (FastAPI) côté backend, limité à deux paramètres de requête.

**Primary Dependencies**: Nuxt 4, Tailwind CSS 3 (`tailwindcss-hero-patterns`, `@tailwindcss/typography`), `@nuxtjs/i18n`, `@nuxtjs/sitemap`, Font Awesome ; FastAPI, SQLAlchemy 2 async, Pydantic v2. **Aucune nouvelle dépendance** (slider maison, pas de bibliothèque de carrousel).

**Storage**: PostgreSQL 16 (`usenghor_postgres` local / `usenghor_db` prod) — 4 lignes dans `editorial_contents` (migration 047), rien d'autre.

**Testing**: backend `pytest` (base `usenghor_test`, fixtures `client` / `db_session`) pour le filtre événements ; frontend sans infrastructure de test → [quickstart.md](quickstart.md) (validation manuelle), `pnpm lint`, `pnpm build`, Lighthouse mobile, captures avant / après (19 usages de `PageHero`, `/actualites`).

**Target Platform**: serveur Linux Docker (nginx + Nuxt SSR + FastAPI + PostgreSQL) ; navigateurs récents, mobile 390 px, mode sombre, RTL.

**Project Type**: application web (monorepo backend + frontend), feature majoritairement frontend.

**Performance Goals**: Lighthouse mobile ≥ 90 (performance, accessibilité) sur les deux pages (SC-003) ; contenu principal dans la réponse SSR (SC-002) ; modification backoffice visible ≤ 60 s (cache public).

**Constraints**: réutiliser sans recréer (hero, layout, riche, carte d'actualité) ; zéro régression sur `PageHero` et `/actualites` (SC-005) ; aucun texte en dur (éditorial FR + i18n `pei.*`) ; `useSeoMeta` après la route (TDZ) ; routes statiques avant dynamiques (backend inchangé sur ce point) ; noms de fichiers `[a-z0-9_-]` ; SQL 047 validé avant le code ; sections sans données masquées sans erreur ; copie éditoriale monolingue FR (clarification Q1).

**Scale/Scope**: 2 pages, 1 composable public + 1 composable JSON-LD, 9 composants publics (1 sous-nav, 8 blocs), 1 carte d'actualité extraite, 1 extension de `PageHero`, 1 utilitaire de présentation, 3 fichiers i18n, 1 migration + rollback, 2 paramètres backend + 1 fichier de test, CLAUDE.md. Données : 5–20 dispositifs, ≤ 30 partenaires, 3 actualités, ≤ 6 événements.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` est le gabarit non rempli : aucun principe formel. Portes appliquées = conventions de `CLAUDE.md`, feuille de route PEI § 1 et contraintes explicites de la demande :

| Porte | Statut | Preuve |
|---|---|---|
| Réutiliser avant de créer (vérification par sous-agent) | ✅ fait | 3 sous-agents (inventaire `PageHero`, navs, stats, cartes, composables, SEO, i18n, tests) → R1–R7 ; hero étendu, carte extraite, `RichTextRenderer`, `useEditorialContent`, `usePublicNewsApi`, `usePublicEventsApi`, `usePublicOrganizationApi` réutilisés |
| Pas de nouveau composant hero | ✅ | R1 : props additives sur `PageHero` |
| Layout par défaut (`AppNavBar`, `AppFooter`) | ✅ | pages sans `definePageMeta` |
| Aucun texte codé en dur | ✅ | éditorial `getRawContent` (R6) + i18n `pei.*` (R12) |
| Trilingue + repli FR + RTL | ✅ | `useLocalizedField`, Q1 pour la copie, propriétés logiques (R16) |
| Structure BDD : accord → SQL → code | ✅ prévu | data-model.md § 3 (migration 047 seule, aucune table) |
| Migration rejouable + rollback, nom sans accent | ✅ | `047_pei_activities_hero_keys{,_rollback}.sql` |
| API publique sans auth, `useApiBase()` + `$fetch` | ✅ | R8 |
| Routes statiques avant dynamiques | ✅ n/a | aucune route ajoutée ; paramètres seulement |
| SEO : `useSeoMeta` après la route, sitemap, OG | ✅ | R11 |
| Zéro régression `PageHero` | ✅ prévu | Q3 + captures (quickstart § 7) |
| Pas de nouvelle dépendance | ✅ | slider et compteur maison |
| CLAUDE.md maintenu | ✅ prévu | quickstart § 12 |

**Re-check post-design (Phase 1)** : aucune violation. Sept composants publics nouveaux sont justifiés par l'absence d'équivalent public (les voisins sont admin ou spécifiques) ; deux nouveautés transverses (`ActualitesNewsCard`, utilitaire `.scrollbar-hide` global) réduisent la duplication existante.

## Project Structure

### Documentation (this feature)

```text
specs/023-pei-public-home-activities/
├── plan.md              # Ce fichier
├── research.md          # Phase 0 — 17 décisions (R1–R17)
├── data-model.md        # Phase 1 — entités lues, règles de présentation, SQL 047 à valider, filtre événements
├── quickstart.md        # Phase 1 — 12 blocs de validation (SC-001 à SC-011)
├── contracts/
│   ├── public-api.md    # lectures consommées + évolution de GET /api/public/events
│   ├── editorial-keys.md# 4 clés ajoutées (47 au total) et clés lues par page
│   └── frontend.md      # routes, PageHero étendu, sous-nav, composants, composable, i18n, SEO
├── checklists/requirements.md
└── tasks.md             # Phase 2 (/speckit-tasks)
```

### Source Code (repository root)

```text
usenghor_backend/
├── documentation/modele_de_données/migrations/
│   ├── 047_pei_activities_hero_keys.sql            # nouveau (4 clés éditoriales)
│   └── 047_pei_activities_hero_keys_rollback.sql   # nouveau
├── app/routers/public/events.py                     # + service_id, order
├── app/services/content_service.py                  # get_events(+ service_id, + order)
└── tests/integration/test_public_events_service_filter.py   # nouveau

usenghor_nuxt/
├── app/pages/entrepreneuriat/
│   ├── index.vue                                    # nouveau — /entrepreneuriat
│   └── activites.vue                                # nouveau — /entrepreneuriat/activites
├── app/components/page/Hero.vue                     # + images[], badge, badgeIcon, actions (slider accessible)
├── app/components/entrepreneurship/                 # nouveaux (hors admin/)
│   ├── SubNav.vue, StatsPanel.vue, ProgramCard.vue, ProgramSection.vue,
│   ├── EcosystemChips.vue, QuoteBlock.vue, PartnerFamilies.vue, EventList.vue, CtaBanner.vue
├── app/components/actualites/NewsCard.vue           # nouveau — extrait de pages/actualites/index.vue
├── app/pages/actualites/index.vue                   # boucle → <ActualitesNewsCard>
├── app/pages/a-propos/partenaires/index.vue         # retrait :badge / badge-icon orphelins
├── app/pages/a-propos/organisation/[type]/[slug].vue# retrait <template #badge> orphelin
├── app/composables/usePublicEntrepreneurshipApi.ts  # nouveau
├── app/composables/usePeiJsonLd.ts                  # nouveau — JSON-LD Organization / WebPage / BreadcrumbList
├── app/composables/usePublicEventsApi.ts            # + service_id, order
├── app/composables/editorial-pages-config.ts        # + 4 clés (section entrepreneurship-activities)
├── app/types/api/editorial.ts                       # + 4 ValueSectionKey
├── app/utils/pei-presentation.ts                    # nouveau — phases, ancres, couleurs, familles
├── app/assets/css/main.css                          # + .scrollbar-hide
├── i18n/locales/{fr,en,ar}/entrepreneurship.json    # nouveaux (racine pei) + index.ts
└── i18n/locales/{fr,en,ar}/hero.json                # + hero.slider.* (accessibilité du slider)

CLAUDE.md                                            # routes publiques, composable, hero, sous-nav, carte, 047
```

**Structure Decision**: application web monorepo existante ; le frontend suit « pages minces + composants par feature » (`components/entrepreneurship/` public à côté de `admin/`), le backend n'est touché que sur un routeur et un service existants. Aucun nouveau dossier de premier niveau.

## Phase 0 — Research (terminée)

Voir [research.md](research.md) : extension `PageHero` (R1), sous-nav dédiée (R2), carte d'actualité extraite (R3), filtre public des événements avec `order` (R4), migration 047 (R5), lecture éditoriale sans clé brute (R6), panneau de chiffres (R7), composable public (R8), SSR tolérant aux pannes (R9), service DDE et fil d'Ariane (R10), SEO / JSON-LD (R11), namespace i18n `pei` (R12), phases / couleurs / ancres (R13), images et performance (R14), tests (R15), RTL / sombre (R16), ancres de « Nos activités » (R17). Points ouverts de la clarification tranchés : 6 événements maximum, image OG = première slide, carte du site inchangée, couleurs pilotées par la base. Aucun `NEEDS CLARIFICATION` restant.

## Phase 1 — Design (terminée)

- [data-model.md](data-model.md) : entités lues, règles de présentation, **SQL 047 à valider (FR-029)**, évolution du filtre événements, ajouts de types.
- [contracts/public-api.md](contracts/public-api.md), [contracts/editorial-keys.md](contracts/editorial-keys.md), [contracts/frontend.md](contracts/frontend.md).
- [quickstart.md](quickstart.md) : 12 blocs couvrant SC-001 à SC-011.

## Ordre d'implémentation recommandé (pour /speckit-tasks)

1. **Porte FR-029** : présenter data-model.md § 3 (SQL 047) au responsable ; attendre l'accord. En parallèle, tout ce qui n'en dépend pas peut démarrer.
2. Backend : `content_service.get_events` (+ `service_id`, `order`) → `routers/public/events.py` → test pytest.
3. Transverse frontend : `.scrollbar-hide` global ; `utils/pei-presentation.ts` ; i18n `entrepreneurship.json` × 3 + `index.ts` ; `usePublicEventsApi` (2 paramètres) ; `usePublicEntrepreneurshipApi`.
4. `PageHero` : props `badge` / `badgeIcon` / `images` + slider accessible ; retrait des attributs orphelins ; captures des 19 usages.
5. `ActualitesNewsCard` : extraction ; `/actualites` basculée ; capture avant / après.
6. Migration 047 (après accord) + `editorial-pages-config.ts` + `ValueSectionKey` ; jouer deux fois en local.
7. Composants du pôle : `SubNav`, `StatsPanel`, `ProgramCard`, `EcosystemChips`, `QuoteBlock`, `PartnerFamilies`, `CtaBanner` → page `index.vue` (US1, US3) ; puis `ProgramSection`, `EventList` → page `activites.vue` (US2).
8. SEO / JSON-LD des deux pages ; vérification sitemap.
9. Validation : quickstart § 4–11 (trilingue, RTL, 390 px, sombre, Lighthouse), `pnpm lint`, `pnpm build` ; CLAUDE.md.

## Complexity Tracking

Aucune violation de porte à justifier. Composants publics nouveaux (9 fichiers) : besoin confirmé par inventaire (aucun équivalent public) ; alternative « tout dans les pages » rejetée car les features 024 / 025 réutilisent la sous-nav, le hero étendu et plusieurs blocs.
