# Implementation Plan: Page « Entreprendre et étudier à Senghor » — Statut Étudiant-Entrepreneur

**Branch**: `025-pei-see-status-page` (travail sur `main`, convention des features PEI) | **Date**: 2026-09-14 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/025-pei-see-status-page/spec.md`

## Summary

Livrer la page SSR `/entrepreneuriat/statut-etudiant-entrepreneur` sur le cadre des rubriques PEI (`usePeiPage` étendu à la rubrique `see`) : hero à motif avec badge « Statut Étudiant-Entrepreneur · Appel {année} », sous-navigation dont le bouton rouge devient « page courante », intro + cartes SEE 1 / SEE 2, six leviers, « Suis-je le bon candidat ? » (conditions et pièces **de l'appel d'abord**, textes éditoriaux en secours ; critères du jury éditoriaux) avec un **panneau agenda collant** (nouveau composant `EntrepreneurshipSeeAgenda`) qui dérive l'état de l'appel désigné par `entrepreneurship.see.call_slug` (ouvert / à venir / clos / absent, jamais d'erreur) et la cible du bouton (externe > interne > e-mail), FAQ groupée alimentée par le backoffice FAQ via un **filtre additif `?category_prefix=see-`** et une variante de `FaqAccordion` (sans recherche, ouverture multiple), JSON-LD `FAQPage` extrait de `/faq` dans un utilitaire partagé, lien PÉPITE France et CTA final. Backend : filtre FAQ + extension de « Traduire les champs manquants » aux entrées FAQ SEE publiées. Données : migration 049 (65 clés éditoriales, 4 catégories `see-*` visibles aussi sur `/faq`, 8 questions dont 2 publiées), **soumise à accord** — SQL testé à blanc en local. Décisions : [research.md](research.md) (R1–R17).

## Technical Context

**Language/Version**: TypeScript 5.x / Vue 3 Composition API (Nuxt 4) ; Python 3.14 (FastAPI) pour le filtre FAQ et la traduction ; SQL PostgreSQL 16.

**Primary Dependencies**: Nuxt 4, Tailwind CSS 3, `@nuxtjs/i18n`, `@nuxtjs/sitemap`, Font Awesome (bibliothèques `fas/far/fab` complètes), FastAPI, SQLAlchemy async, Pydantic v2, `deep-translator` (existant). **Aucune nouvelle dépendance.**

**Storage**: PostgreSQL 16 (`usenghor_postgres` / `usenghor_db`) — lignes seedées dans `editorial_contents`, `faq_categories`, `faq_entries` ; aucune structure nouvelle.

**Testing**: pytest (`tests/integration/test_public_faq_api.py` étendu ; test de `translate_missing` avec traducteur simulé) ; frontend sans infrastructure de test → [quickstart.md](quickstart.md) (7 cas d'appel, `curl` SSR, validateur de données structurées, captures avant / après, Lighthouse), `pnpm build`.

**Target Platform**: Docker Linux (nginx + Nuxt SSR + FastAPI + PostgreSQL) ; navigateurs récents, 390 px, sombre, RTL.

**Project Type**: application web monorepo ; feature majoritairement frontend + 2 ajouts backend additifs + 1 migration de données.

**Performance Goals**: contenu principal dans la réponse SSR ; 3 lectures SSR (éditorial + DDE via `usePeiPage`, appel, FAQ filtrée) ; modification backoffice visible ≤ 60 s ; Lighthouse mobile accessibilité ≥ 90, performance comparable aux rubriques 024.

**Constraints**: aucune modification de schéma ; `/faq` et lecture FAQ sans filtre inchangées (hors apparition des catégories SEE, Q1) ; `/actualites/appels/[slug]`, `CTASection`, `ScheduleSection` non modifiés ; aucun texte en dur ; `useSeoMeta` après les `useAsyncData` ; aucune réponse provisoire visible publiquement ; page toujours 200 ; SQL 049 validé avant le code ; noms de fichiers `[a-z0-9_-]`.

**Scale/Scope**: 1 page, 1 composant nouveau (`SeeAgenda`), 3 composants étendus (`SubNav`, `FaqAccordion`, `CtaBanner`), 1 utilitaire nouveau (`faq-jsonld.ts`) + 6 fonctions dans `pei-presentation.ts`, 2 composables étendus (`usePeiPage`, `usePublicFaqApi`), `pages/faq.vue` (refactor JSON-LD à sortie identique), 2 fichiers backend modifiés (+ schéma, + service PEI, + page admin PEI pour le compteur), 3 fichiers i18n (~16 clés), config éditoriale (+65 champs) et types, migration + rollback, CLAUDE.md, roadmap. Données : 1 appel, ≤ 20 étapes / critères / pièces, ≤ 15 questions.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` est le gabarit non rempli. Portes = conventions `CLAUDE.md`, mémoire projet, feuille de route PEI, contraintes de la demande :

| Porte | Statut | Preuve |
|---|---|---|
| Réutiliser avant de créer (sous-agent) | ✅ | inventaire 2026-09-14 (FAQ, appels, mini-site, maquette) ; 1 seul composant créé (R6), justifié |
| `PageHero` motif + badge, layout par défaut, `EntrepreneurshipSubNav` mis en évidence | ✅ | R1–R3 |
| FAQ dans le backoffice existant, 4 catégories `see-*`, sans schéma, filtre rétrocompatible | ✅ | R9, contracts/public-api.md § 1 |
| Visibilité `/faq` clarifiée | ✅ | Q1 → visibles ; `/faq` inchangée |
| Appel via lecture publique existante, pas de nouveau formulaire, états sans erreur | ✅ | R4, R5, data-model § 2.1–2.2 |
| Composants d'appel réutilisés « ou leur style » | ✅ | style et `localized` repris ; composants non modifiés (R6, R8) |
| Aucun texte en dur (65 clés + i18n) | ✅ | contracts/editorial-keys.md, frontend.md § i18n |
| Structure BDD : accord → SQL → code | ✅ prévu | data-model § 4 (aucune structure ; seed seul), SQL testé en transaction annulée : `INSERT 0 65 / 4 / 8` |
| Migration rejouable + rollback, `ON CONFLICT DO NOTHING` | ✅ | R14 |
| Public sans auth, aucune lecture admin en public | ✅ | contracts/public-api.md |
| Routes statiques avant dynamiques | ✅ n/a | aucune route ajoutée |
| SEO : `useSeoMeta` après route, OG, sitemap, JSON-LD FAQPage + BreadcrumbList | ✅ | R1, R11, R15 |
| Lenis et ancres (`scrollToPageAnchor`) | ✅ | R10 |
| Collisions d'auto-import | ✅ prévu | vérification des noms `see*`, `faq*`, `buildFaqPageJsonLd` avant création (contracts/frontend.md) |
| Permissions seedées | ✅ n/a | aucune permission nouvelle (`entrepreneurship.edit` existante) |
| Tests FAQ et quota du traducteur | ✅ | traducteur simulé pour le nouveau test (R17) |
| Zéro régression `/faq`, `/actualites/appels/[slug]`, rubriques PEI | ✅ prévu | props additives à défaut identique ; diff JSON-LD ; captures (quickstart § 5, 10) |
| Hors périmètre (sélection, création de l'appel 2026, menu, organigramme) | ✅ | aucun fichier concerné |
| CLAUDE.md maintenu | ✅ prévu | quickstart § 11 |

**Re-check post-design (Phase 1)** : aucune violation. Deux écarts assumés et documentés : (1) `FaqAccordion` remplace `scrollIntoView` par `scrollToPageAnchor` — correction de comportement également bénéfique à `/faq`, vérifiée ; (2) « Traduire les champs manquants » du pôle touche des entrées FAQ, limitées aux catégories `see-*` publiées, sous la permission du pôle.

## Project Structure

### Documentation (this feature)

```text
specs/025-pei-see-status-page/
├── plan.md              # Ce fichier
├── research.md          # Phase 0 — R1–R17
├── data-model.md        # Phase 1 — entités lues, règles d'état, SQL 049 + rollback À VALIDER, config éditoriale
├── quickstart.md        # Phase 1 — 11 blocs de validation
├── contracts/
│   ├── public-api.md    # filtre FAQ category_prefix, lecture d'appel, translate-missing
│   ├── editorial-keys.md# 65 clés ajoutées, clés réutilisées, règles
│   └── frontend.md      # route, composables, utilitaires, composants, i18n, SEO
├── checklists/requirements.md
└── tasks.md             # Phase 2 (/speckit-tasks)
```

### Source Code (repository root)

```text
usenghor_backend/
├── app/routers/public/faq.py                        # + Query category_prefix
├── app/services/faq_service.py                      # get_public_tree(category_prefix) ; autofill_entry_translations public
├── app/services/entrepreneurship_service.py         # translate_missing : étape faq_see
├── app/schemas/entrepreneurship.py                  # PeiTranslateMissingResponse.faq_see = 0
├── tests/integration/test_public_faq_api.py         # + cas préfixe / 422 / non-régression
├── tests/integration/(test translate-missing PEI)    # + faq_see, traducteur simulé
└── documentation/modele_de_données/migrations/
    ├── 049_pei_see_page.sql                         # nouveau (après accord)
    └── 049_pei_see_page_rollback.sql                # nouveau

usenghor_nuxt/
├── app/pages/entrepreneuriat/statut-etudiant-entrepreneur.vue   # nouveau
├── app/pages/faq.vue                                # JSON-LD via utils/faq-jsonld.ts (sortie identique)
├── app/pages/admin/entrepreneuriat/index.vue        # cumul / message faq_see
├── app/components/entrepreneurship/SeeAgenda.vue    # nouveau
├── app/components/entrepreneurship/SubNav.vue       # bouton « page courante »
├── app/components/entrepreneurship/CtaBanner.vue    # + external, slot note
├── app/components/faq/FaqAccordion.vue              # + searchable, groupTitles, headingLevel, multiple ; scrollToPageAnchor
├── app/composables/usePeiPage.ts                    # rubrique 'see' ; applySeo({ type })
├── app/composables/usePublicFaqApi.ts               # getTree({ categoryPrefix })
├── app/composables/useEntrepreneurshipApi.ts        # type PeiTranslateMissingResponse.faq_see (si déclaré ici)
├── app/composables/editorial-pages-config.ts        # section entrepreneurship-see : +65 champs
├── app/types/api/editorial.ts                       # +65 ValueSectionKey
├── app/utils/pei-presentation.ts                    # + seeCallState, seeApplyTarget, seeCallYear, seeAgendaSteps, seeSlots, seeLeverIcon
├── app/utils/faq-jsonld.ts                          # nouveau
└── i18n/locales/{fr,en,ar}/entrepreneurship.json    # + pei.nav.see, pei.seo.see*, pei.see.*

CLAUDE.md, specs/roadmap-pei-entrepreneuriat.md      # documentation
```

**Structure Decision**: monorepo existant ; pages minces + composants par feature (`components/entrepreneurship/` public) ; backend modifié uniquement de façon additive ; migration de données seule.

## Phase 0 — Research (terminée)

[research.md](research.md) : cadre `usePeiPage` (R1), badge et année (R2), sous-navigation (R3), état de l'appel (R4), cible des boutons (R5), panneau agenda (R6), repère de date limite (R7), conditions et dossier appel → éditorial (R8), filtre FAQ (R9), variante d'accordéon (R10), JSON-LD partagé (R11), traduction des entrées seedées (R12), 65 clés (R13), migration 049 (R14), i18n / SEO / RTL (R15), CTA final (R16), tests (R17). Aucun `NEEDS CLARIFICATION`.

## Phase 1 — Design (terminée)

- [data-model.md](data-model.md) — **SQL 049 + rollback à valider** (§ 4, 5 points à confirmer : URL PÉPITE, texte « appel clos », libellés EN/AR, ordre sur `/faq`, portée du rollback).
- [contracts/public-api.md](contracts/public-api.md), [contracts/editorial-keys.md](contracts/editorial-keys.md), [contracts/frontend.md](contracts/frontend.md).
- [quickstart.md](quickstart.md).

## Ordre d'implémentation recommandé (pour /speckit-tasks)

1. **Porte d'accord SQL** : présenter data-model § 4 ; attendre l'accord. En parallèle, tout ce qui n'en dépend pas.
2. Captures et JSON-LD de référence (`/faq`, `/actualites/appels/<slug>`, `/entrepreneuriat/alumni`).
3. Backend : filtre `category_prefix` + tests ; `autofill_entry_translations` public ; étape `faq_see` + schéma + test (traducteur simulé).
4. Frontend transverse : vérification des collisions d'auto-import ; `utils/faq-jsonld.ts` + refactor `faq.vue` (diff JSON-LD) ; `usePublicFaqApi` ; utilitaires `see*` ; `usePeiPage` (`see`, `applySeo({ type })`) ; i18n ×3.
5. Composants : `FaqAccordion` (variantes + ancre Lenis ; vérifier `/faq`) ; `CtaBanner` (`external`, slot) ; `SubNav` (bouton courant) ; `SeeAgenda`.
6. Migration 049 (après accord) + config éditoriale + `ValueSectionKey` ; rejeu local (quickstart § 1).
7. Page : US1 (guide + agenda ouvert) → US3 (états) → US2 (FAQ + JSON-LD) → US4 (édition) ; compteur `faq_see` du tableau de bord PEI.
8. Validation quickstart § 2–10 ; `pnpm build` ; CLAUDE.md et roadmap (§ 11).

## Complexity Tracking

Aucune violation. Un composant nouveau (`SeeAgenda`) : aucun panneau d'appel à états, actions et frise de maquette n'existe ; étendre `ScheduleSection` ou `CTASection` ferait courir un risque aux cinq pages de détail d'appel. L'extraction `faq-jsonld.ts` modifie `/faq` sans changer sa sortie (diff exigé) pour éviter deux copies du même JSON-LD.
