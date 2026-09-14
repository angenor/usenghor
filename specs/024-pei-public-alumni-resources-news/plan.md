# Implementation Plan: Mini-site public « Entreprendre à Senghor » — alumni, partenaires, ressources, actualités

**Branch**: `024-pei-public-alumni-resources-news` | **Date**: 2026-09-14 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/024-pei-public-alumni-resources-news/spec.md`

## Summary

Livrer les quatre rubriques restantes du mini-site PEI en quatre pages Nuxt SSR — `/entrepreneuriat/alumni` (sous-onglets pilule portés par `?type=`, bandeau de trois chiffres éditoriaux, une section par cohorte avec cartes portrait, encart « Devenir mentor » en `mailto:`), `/entrepreneuriat/partenaires` (variante détaillée du composant de familles), `/entrepreneuriat/ressources` (albums de la médiathèque du service DDE via `MediaLibraryTab` + boîte à outils groupée par catégorie avec téléchargement `?download=1`, liens et vidéos externes) et `/entrepreneuriat/actualites` (actualités DDE paginées serveur par lots de 12 avec la carte `ActualitesNewsCard`, événements à venir / passés via `EntrepreneurshipEventList`). Le cadre commun (hero, sous-nav, fil d'Ariane, SEO, JSON-LD `CollectionPage`) est factorisé dans un composable `usePeiPage` réservé aux nouvelles pages. **Zéro changement backend** : aucune API ni structure nouvelle ; une seule migration 048 seed 26 clés éditoriales (heros, chiffres alumni, titres de section), soumise à accord avant le code. Décisions détaillées dans [research.md](research.md) (R1–R16).

## Technical Context

**Language/Version**: TypeScript 5.x / Vue 3 Composition API (Nuxt 4) ; SQL PostgreSQL 16 pour la migration. Aucun code Python touché.

**Primary Dependencies**: Nuxt 4, Tailwind CSS 3 (`@tailwindcss/typography`), `@nuxtjs/i18n`, `@nuxtjs/sitemap`, Font Awesome (icônes `fa-brands` à vérifier dans le plugin). **Aucune nouvelle dépendance** (pas de lecteur vidéo tiers, pas de bibliothèque de pagination).

**Storage**: PostgreSQL 16 (`usenghor_postgres` local / `usenghor_db` prod) — 26 lignes dans `editorial_contents` (migration 048), rien d'autre.

**Testing**: backend : tests pytest existants rejoués en non-régression (`test_public_entrepreneurship_api.py`, `test_public_events_service_filter.py`) ; frontend sans infrastructure de test → [quickstart.md](quickstart.md) (validation manuelle, `curl` SSR, sitemap, JSON-LD), `pnpm build` (heap 8 Go), Lighthouse mobile, captures avant / après (`/actualites`, `/a-propos/partenaires`, `/entrepreneuriat`).

**Target Platform**: serveur Linux Docker (nginx + Nuxt SSR + FastAPI + PostgreSQL) ; navigateurs récents, mobile 390 px, mode sombre, RTL.

**Project Type**: application web (monorepo backend + frontend), feature **exclusivement frontend + 1 migration de données**.

**Performance Goals**: Lighthouse mobile ≥ 90 (performance, accessibilité) sur les quatre pages (SC-008) ; contenu principal dans la réponse SSR, onglet alumni actif dès le HTML (SC-002) ; modification backoffice visible ≤ 60 s.

**Constraints**: réutiliser sans recréer (hero, sous-nav, carte d'actualité, liste d'événements, galerie d'albums, bandeau CTA, panneau de chiffres, familles de partenaires — étendus par props additives à rendu par défaut inchangé) ; zéro régression sur `/actualites`, `/mediatheque`, `/a-propos/partenaires`, `/entrepreneuriat`, fiche service (SC-006) ; aucun texte en dur (éditorial FR + i18n `pei.*`) ; `useSeoMeta` après la route (TDZ) ; aucune lecture admin en public ; noms de fichiers `[a-z0-9_-]` ; SQL 048 validé avant le code ; sections sans données masquées, page vide → état vide propre ; copie éditoriale monolingue FR.

**Scale/Scope**: 4 pages, 1 composable (`usePeiPage`), 5 composants publics nouveaux (`PillTabs`, `CohortSection`, `LaureateCard`, `ResourceCard`, `EmptyState`), 4 composants étendus (`StatsPanel`, `PartnerFamilies`, `CtaBanner`, `EventList`), 6 fonctions utilitaires, 1 paramètre sur `usePeiJsonLd.buildWebPage`, 3 fichiers i18n (~45 clés chacun), 4 sections de configuration éditoriale + 26 littéraux de type, 1 migration + rollback, CLAUDE.md. Données : ≤ 50 portraits, ≤ 30 partenaires, ≤ 10 albums, ≤ 40 ressources, actualités et événements paginés.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` est le gabarit non rempli : aucun principe formel. Portes appliquées = conventions de `CLAUDE.md`, feuille de route PEI § 1, contraintes de réutilisation de la demande :

| Porte | Statut | Preuve |
|---|---|---|
| Réutiliser avant de créer (vérification par sous-agent) | ✅ fait | inventaire du 2026-09-14 (API publiques, composables, `components/entrepreneurship/*`, `media/*`, `actualites/NewsCard`, `cards/CardPartner`, `partners/*`, `section/about/TabsNav`, `section/Stats`, `projet/ProjetMediatheque`, pages alumni / actualités / fiche service, sitemap) → R1–R11 ; 9 briques réutilisées, 4 étendues, 5 créées faute d'équivalent public |
| Layout par défaut, `PageHero`, `EntrepreneurshipSubNav`, `RichTextRenderer`, `useEditorialContent`, `useLocalizedField` | ✅ | R1, R5 ; pages sans `definePageMeta` |
| Partenaires : étendre `PartnerFamilies`, ne pas dupliquer | ✅ | R7 (`variant="detailed"`) |
| Médiathèque : `MediaLibraryTab` / `MediaAlbumCard` / `MediaAlbumModal` | ✅ | R8 |
| Actualités / événements : cartes et lots de `/actualites`, filtre `service_id` | ✅ | R10 (`ActualitesNewsCard`, `EventList`, pagination serveur) |
| Sous-onglets pilule : style de `SectionAboutTabsNav` | ✅ | R2 (classes recopiées, composant dédié à props) |
| Aucun texte codé en dur | ✅ | éditorial `getRawContent` + i18n `pei.*` (R12) |
| Trilingue + repli FR + RTL | ✅ | `localized()`, propriétés logiques (R16), copie FR par convention |
| Structure BDD : accord → SQL → code | ✅ prévu | data-model.md § 3 (migration 048 seule, aucune table) |
| Migration rejouable + rollback, nom sans accent | ✅ | `048_pei_public_pages_keys{,_rollback}.sql` |
| API publique sans auth ; aucune lecture admin en public | ✅ | contracts/public-api.md ; catégories de ressources dérivées côté client (R9) |
| Routes statiques avant dynamiques | ✅ n/a | aucune route backend ajoutée |
| SEO : `useSeoMeta` après la route, sitemap, OG, JSON-LD | ✅ | R13 (`CollectionPage`, `BreadcrumbList`) |
| Zéro régression pages existantes | ✅ prévu | props additives à défaut inchangé ; captures (quickstart § 5, 7, 11) |
| Hors périmètre respecté (SEE, menu, organigramme, backoffices) | ✅ | aucun fichier admin ni navigation principale touché |
| Pas de nouvelle dépendance | ✅ | R9 (vignette + lien), R10 (lots maison) |
| CLAUDE.md maintenu | ✅ prévu | quickstart § 12 |

**Re-check post-design (Phase 1)** : aucune violation. Les cinq composants nouveaux répondent à des absences vérifiées (carte portrait, section de cohorte, carte ressource, sous-onglets à props, état vide) ; les quatre extensions sont additives (`variant`, `href`, `title`, `type`) avec rendu par défaut strictement identique. Le composable `usePeiPage` ne touche pas aux pages 023.

## Project Structure

### Documentation (this feature)

```text
specs/024-pei-public-alumni-resources-news/
├── plan.md              # Ce fichier
├── research.md          # Phase 0 — 16 décisions (R1–R16)
├── data-model.md        # Phase 1 — entités lues, règles de présentation, SQL 048 à valider, config éditoriale, utilitaires
├── quickstart.md        # Phase 1 — 12 blocs de validation (SC-001 à SC-011)
├── contracts/
│   ├── public-api.md    # lectures consommées (aucune évolution d'API)
│   ├── editorial-keys.md# 26 clés ajoutées, clés réutilisées, clés lues par page
│   └── frontend.md      # routes, usePeiPage, composants nouveaux / étendus, utilitaires, i18n, SEO
├── checklists/requirements.md
└── tasks.md             # Phase 2 (/speckit-tasks)
```

### Source Code (repository root)

```text
usenghor_backend/
└── documentation/modele_de_données/migrations/
    ├── 048_pei_public_pages_keys.sql               # nouveau — 26 clés éditoriales (après accord)
    └── 048_pei_public_pages_keys_rollback.sql      # nouveau

usenghor_nuxt/
├── app/pages/entrepreneuriat/
│   ├── alumni.vue                                   # nouveau — /entrepreneuriat/alumni[?type=]
│   ├── partenaires.vue                              # nouveau — /entrepreneuriat/partenaires
│   ├── ressources.vue                               # nouveau — /entrepreneuriat/ressources
│   └── actualites.vue                               # nouveau — /entrepreneuriat/actualites
├── app/components/entrepreneurship/                 # public (hors admin/)
│   ├── PillTabs.vue, CohortSection.vue, LaureateCard.vue, ResourceCard.vue, EmptyState.vue   # nouveaux
│   ├── StatsPanel.vue                               # + variant 'band', title optionnel
│   ├── PartnerFamilies.vue                          # + variant 'detailed'
│   ├── CtaBanner.vue                                # + href (mailto), to optionnel
│   └── EventList.vue                                # + title
├── app/composables/usePeiPage.ts                    # nouveau — éditorial, DDE, hero, fil d'Ariane, SEO + JSON-LD
├── app/composables/usePeiJsonLd.ts                  # buildWebPage(+ type 'CollectionPage')
├── app/composables/editorial-pages-config.ts        # + 4 sections (26 clés)
├── app/types/api/editorial.ts                       # + 26 ValueSectionKey
├── app/utils/pei-presentation.ts                    # + tri vedettes, type d'onglet, regroupement, youTubeId, isHttpUrl
├── app/plugins/fontawesome.ts (ou équivalent)       # vérifier / ajouter fa-brands linkedin-in, instagram, facebook-f, fa-star, fa-file-arrow-down, fa-circle-play
└── i18n/locales/{fr,en,ar}/entrepreneurship.json    # + pei.common, pei.alumni, pei.partners, pei.resources, pei.news, pei.seo.*

CLAUDE.md                                            # routes, composable, composants, migration 048, Recent Changes
```

**Structure Decision**: application web monorepo existante ; le frontend suit « pages minces + composants par feature » (`components/entrepreneurship/` public à côté de `admin/`) ; le backend n'est touché que par une migration de données. Aucun nouveau dossier.

## Phase 0 — Research (terminée)

Voir [research.md](research.md) : structure commune et `usePeiPage` (R1), sous-onglets par adresse (R2), chargement unique et tri des vedettes (R3), bandeau de chiffres en variante (R4), carte portrait et section de cohorte (R5), encart mentor en `mailto:` (R6), familles de partenaires détaillées (R7), médiathèque de la DDE via la fiche service (R8), boîte à outils : regroupement, téléchargement, vidéos (R9), actualités et événements par lots serveur (R10), état vide (R11), i18n (R12), SEO / JSON-LD (R13), migration 048 (R14), tests (R15), RTL / sombre / 390 px (R16). Aucun `NEEDS CLARIFICATION` restant.

## Phase 1 — Design (terminée)

- [data-model.md](data-model.md) : entités lues, règles de présentation, **SQL 048 à valider (FR-024)**, configuration éditoriale, ajouts d'utilitaires.
- [contracts/public-api.md](contracts/public-api.md), [contracts/editorial-keys.md](contracts/editorial-keys.md), [contracts/frontend.md](contracts/frontend.md).
- [quickstart.md](quickstart.md) : 12 blocs couvrant SC-001 à SC-011.

## Ordre d'implémentation recommandé (pour /speckit-tasks)

1. **Porte FR-024** : présenter data-model.md § 3 (SQL 048) au responsable ; attendre l'accord. Tout ce qui n'en dépend pas démarre en parallèle.
2. Transverse : `utils/pei-presentation.ts` (6 fonctions) ; `usePeiJsonLd.buildWebPage` (+ `type`) ; i18n `entrepreneurship.json` × 3 ; vérification des icônes Font Awesome ; sous-agent « composant état vide existant ? » puis `EmptyState.vue`.
3. `usePeiPage.ts` (éditorial, DDE, hero, fil d'Ariane, `applySeo`).
4. Extensions à défaut inchangé : `StatsPanel` (`band`), `CtaBanner` (`href`), `EventList` (`title`), `PartnerFamilies` (`detailed`) ; capture de `/entrepreneuriat` avant / après.
5. Migration 048 (après accord) + `editorial-pages-config.ts` + `ValueSectionKey` ; jouer deux fois en local (quickstart § 1).
6. Page **alumni** (US1) : `PillTabs`, `LaureateCard`, `CohortSection` → `alumni.vue`.
7. Page **partenaires** (US2) : `partenaires.vue`.
8. Page **ressources** (US3) : `ResourceCard` → `ressources.vue` (albums + boîte à outils).
9. Page **actualités** (US4) : `actualites.vue` (lots, événements).
10. Validation : quickstart § 4–11 (trilingue, RTL, 390 px, sombre, SEO, Lighthouse, captures), `pnpm build`, pytest de non-régression ; CLAUDE.md (§ 12).

## Complexity Tracking

Aucune violation de porte à justifier. Cinq composants publics nouveaux : besoin confirmé par inventaire (aucun équivalent public branché sur l'API du pôle) ; alternative « tout dans les pages » rejetée car la feature 025 réutilisera `PillTabs`, `EmptyState` et l'encart mentor. Le composable `usePeiPage` est justifié par quatre pages au squelette identique ; son application aux pages 023 est volontairement différée (zéro régression).
