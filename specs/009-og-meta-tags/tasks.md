# Tasks: Balises Open Graph pour le partage de liens

**Input**: Design documents from `/specs/009-og-meta-tags/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/og-meta-contract.md

**Tests**: Non demandes dans la spec — pas de taches de test generees.

**Organization**: Taches groupees par user story pour permettre une implementation et un test independants de chaque story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut s'executer en parallele (fichiers differents, pas de dependances)
- **[Story]**: User story concernee (US1, US2, US3)
- Chemins exacts inclus dans les descriptions

## Phase 1: Setup (Infrastructure partagee)

**Purpose**: Configuration de base et ressources communes a toutes les stories

- [x] T001 Ajouter `runtimeConfig.public.siteUrl` dans `usenghor_nuxt/nuxt.config.ts` avec defaut `http://localhost:3000` et variable d'env `NUXT_PUBLIC_SITE_URL`
- [x] T002 [P] Creer l'image OG par defaut `usenghor_nuxt/public/images/og/og-default.png` (1200x630px) — logo Dieese centre sur fond blanc ou couleur brand
- [x] T003 [P] Ajouter les cles i18n `og.siteName` et `og.defaultDescription` dans `usenghor_nuxt/i18n/locales/fr/index.ts` (FR: "Universite Senghor - Operateur direct de la Francophonie a Alexandrie, Egypte")
- [x] T004 [P] Ajouter les cles i18n `og.siteName` et `og.defaultDescription` dans `usenghor_nuxt/i18n/locales/en/index.ts` (EN: traduction anglaise)
- [x] T005 [P] Ajouter les cles i18n `og.siteName` et `og.defaultDescription` dans `usenghor_nuxt/i18n/locales/ar/index.ts` (AR: traduction arabe)

---

## Phase 2: Foundational (Prerequis bloquants)

**Purpose**: Meta OG globales dans nuxt.config.ts — socle pour toutes les pages

**CRITICAL**: Doit etre complete avant toute modification de page

- [x] T006 Configurer `app.head` dans `usenghor_nuxt/nuxt.config.ts` avec les meta OG globales par defaut : `og:site_name` ("Universite Senghor"), `og:type` ("website"), `og:image` (URL absolue vers `/images/og/og-default.png` via siteUrl), `og:image:width` (1200), `og:image:height` (630). Inclure aussi `twitter:card` ("summary_large_image") et `twitter:image` (meme URL). Ajouter un `titleTemplate` : `%s | Universite Senghor`

**Checkpoint**: Toutes les pages du site ont maintenant des meta OG par defaut dans le HTML source.

---

## Phase 3: User Story 1 - Partage d'un lien sur les reseaux sociaux (Priority: P1) MVP

**Goal**: Chaque page publique affiche une carte de previsualisation complete (titre + description + image) lors du partage. Les pages de contenu avec image utilisent leur image en variante medium.

**Independent Test**: Inspecter le HTML source de n'importe quelle page publique et verifier la presence de `og:title`, `og:description`, `og:image` (URL absolue), `og:url`, `og:type`, `og:site_name`.

### Pages sans meta — Ajouter useSeoMeta complet

- [x] T007 [US1] Ajouter `useSeoMeta()` dans `usenghor_nuxt/app/pages/index.vue` — homepage avec titre, description i18n, ogTitle, ogDescription. Utiliser `useRuntimeConfig().public.siteUrl` + `useRoute().fullPath` pour ogUrl. Image par defaut (globale).
- [x] T008 [P] [US1] Ajouter `useSeoMeta()` dans `usenghor_nuxt/app/pages/formations/index.vue` — titre et description i18n formations, ogTitle, ogDescription, ogUrl
- [x] T009 [P] [US1] Ajouter `useSeoMeta()` dans `usenghor_nuxt/app/pages/about.vue` — titre et description i18n about, ogTitle, ogDescription, ogUrl
- [x] T010 [P] [US1] Ajouter `useSeoMeta()` dans `usenghor_nuxt/app/pages/formulaires/[slug].vue` — titre dynamique du formulaire, description, ogTitle, ogDescription, ogUrl

### Pages levees-de-fonds — Migrer useHead vers useSeoMeta reactif

- [x] T011 [P] [US1] Migrer `useHead()` vers `useSeoMeta()` reactif dans `usenghor_nuxt/app/pages/levees-de-fonds/index.vue` — utiliser des arrow functions pour titre/description, ajouter ogTitle, ogDescription, ogUrl
- [x] T012 [P] [US1] Migrer `useHead()` vers `useSeoMeta()` reactif dans `usenghor_nuxt/app/pages/levees-de-fonds/[slug].vue` — ajouter ogTitle, ogDescription, ogUrl, ogImage (cover_image_external_id avec `?variant=medium` et URL absolue via siteUrl)

### Pages dynamiques avec image — Corriger ogImage vers variante medium + URL absolue

- [x] T013 [P] [US1] Modifier `useSeoMeta()` dans `usenghor_nuxt/app/pages/actualites/[slug].vue` — prefixer ogImage avec `siteUrl`, ajouter `?variant=medium`, ajouter ogUrl. Ajouter `ogType: 'article'`
- [x] T014 [P] [US1] Modifier `useSeoMeta()` dans `usenghor_nuxt/app/pages/actualites/evenements/[id].vue` — prefixer ogImage avec `siteUrl`, ajouter `?variant=medium`, ajouter ogUrl. Ajouter `ogType: 'article'`
- [x] T015 [P] [US1] Modifier `useSeoMeta()` dans `usenghor_nuxt/app/pages/actualites/appels/[slug].vue` — prefixer ogImage avec `siteUrl`, ajouter `?variant=medium`, ajouter ogUrl
- [x] T016 [P] [US1] Modifier `useSeoMeta()` dans `usenghor_nuxt/app/pages/formations/[type]/[slug].vue` — prefixer ogImage avec `siteUrl`, ajouter `?variant=medium`, ajouter ogUrl
- [x] T017 [P] [US1] Modifier `useSeoMeta()` dans `usenghor_nuxt/app/pages/projets/[slug]/index.vue` — prefixer ogImage avec `siteUrl`, ajouter `?variant=medium`, ajouter ogUrl
- [x] T018 [P] [US1] Modifier `useSeoMeta()` dans `usenghor_nuxt/app/pages/a-propos/partenaires/campus/[slug].vue` — prefixer ogImage avec `siteUrl`, ajouter `?variant=medium` si URL relative, ajouter ogUrl
- [x] T019 [P] [US1] Modifier `useSeoMeta()` dans `usenghor_nuxt/app/pages/a-propos/equipe/[id].vue` — prefixer ogImage avec `siteUrl`, ajouter `?variant=medium` si URL relative, ajouter ogUrl

### Pages statiques avec meta existantes — Ajouter ogUrl et completer les meta manquantes

- [x] T020 [P] [US1] Completer `useSeoMeta()` dans `usenghor_nuxt/app/pages/a-propos/index.vue` — remplacer `ogImage: undefined` par suppression (fallback global), ajouter ogUrl
- [x] T021 [P] [US1] Completer `useSeoMeta()` dans `usenghor_nuxt/app/pages/a-propos/histoire.vue` — remplacer `ogImage: undefined` par suppression, ajouter ogUrl
- [x] T022 [P] [US1] Completer `useSeoMeta()` dans `usenghor_nuxt/app/pages/a-propos/partenaires/index.vue` — remplacer `ogImage: undefined` par suppression, ajouter ogUrl
- [x] T023 [P] [US1] Completer `useSeoMeta()` dans `usenghor_nuxt/app/pages/a-propos/strategie.vue` — ajouter ogUrl
- [x] T024 [P] [US1] Completer `useSeoMeta()` dans `usenghor_nuxt/app/pages/a-propos/gouvernance.vue` — ajouter ogUrl
- [x] T025 [P] [US1] Completer `useSeoMeta()` dans `usenghor_nuxt/app/pages/a-propos/equipe/index.vue` — ajouter ogUrl
- [x] T026 [P] [US1] Completer `useSeoMeta()` dans `usenghor_nuxt/app/pages/a-propos/organisation/index.vue` — ajouter ogUrl
- [x] T027 [P] [US1] Completer `useSeoMeta()` dans `usenghor_nuxt/app/pages/a-propos/organisation/[type]/[slug].vue` — ajouter ogUrl
- [x] T028 [P] [US1] Completer `useSeoMeta()` dans `usenghor_nuxt/app/pages/actualites/index.vue` — ajouter ogTitle, ogDescription, ogUrl
- [x] T029 [P] [US1] Completer `useSeoMeta()` dans `usenghor_nuxt/app/pages/actualites/evenements/index.vue` — ajouter ogTitle, ogDescription, ogUrl
- [x] T030 [P] [US1] Completer `useSeoMeta()` dans `usenghor_nuxt/app/pages/actualites/appels/index.vue` — ajouter ogTitle, ogDescription, ogUrl
- [x] T031 [P] [US1] Completer `useSeoMeta()` dans `usenghor_nuxt/app/pages/formations/[type]/index.vue` — ajouter ogTitle, ogDescription, ogUrl
- [x] T032 [P] [US1] Completer `useSeoMeta()` dans `usenghor_nuxt/app/pages/projets/index.vue` — ajouter ogTitle, ogDescription, ogUrl
- [x] T033 [P] [US1] Completer `useSeoMeta()` dans `usenghor_nuxt/app/pages/projets/[slug]/appels/[appelSlug]/index.vue` — ajouter ogTitle, ogDescription, ogUrl
- [x] T034 [P] [US1] Completer `useSeoMeta()` dans `usenghor_nuxt/app/pages/projets/[slug]/appels/[appelSlug]/postuler.vue` — ajouter ogTitle, ogDescription, ogUrl
- [x] T035 [P] [US1] Completer `useSeoMeta()` dans `usenghor_nuxt/app/pages/nousrejoindre/index.vue` — ajouter ogUrl
- [x] T036 [P] [US1] Completer `useSeoMeta()` dans `usenghor_nuxt/app/pages/nousrejoindre/candidature-enseignant.vue` — ajouter ogTitle, ogDescription, ogUrl
- [x] T037 [P] [US1] Completer `useSeoMeta()` dans `usenghor_nuxt/app/pages/candidatures/index.vue` — ajouter ogTitle, ogDescription, ogUrl
- [x] T038 [P] [US1] Completer `useSeoMeta()` dans `usenghor_nuxt/app/pages/candidatures/postuler/[slug].vue` — ajouter ogTitle, ogDescription, ogUrl
- [x] T039 [P] [US1] Completer `useSeoMeta()` dans `usenghor_nuxt/app/pages/alumni/index.vue` — ajouter ogTitle, ogDescription, ogUrl
- [x] T040 [P] [US1] Completer `useSeoMeta()` dans `usenghor_nuxt/app/pages/siege/index.vue` — ajouter ogTitle, ogDescription, ogUrl

**Checkpoint**: Toutes les pages publiques ont des meta OG completes. Les images de contenu utilisent la variante medium. Verifiable via View Source sur chaque page.

---

## Phase 4: User Story 2 - Coherence multilingue des meta OG (Priority: P2)

**Goal**: Les meta OG refletent la langue de la page (titre/description localises, og:locale correct, locales alternatives declarees).

**Independent Test**: Acceder a la meme page en `/`, `/en/` et `/ar/` et verifier que `og:locale` change et que `og:locale:alternate` liste les 2 autres locales.

### Implementation

- [x] T040 [US2] Ajouter `ogLocale` et `ogLocaleAlternate` dans le bloc `app.head` global de `usenghor_nuxt/nuxt.config.ts` — valeur par defaut `fr_FR` et alternates `['en_US', 'ar_SA']`. Note : cette valeur statique sera surchargee par les pages individuelles.
- [x] T040 [US2] Ajouter `ogLocale` reactif (mapping `fr`→`fr_FR`, `en`→`en_US`, `ar`→`ar_SA`) et `ogLocaleAlternate` (les 2 autres) dans chaque appel `useSeoMeta()` des pages suivantes (modifier en batch) : `usenghor_nuxt/app/pages/index.vue`, `about.vue`, `formations/index.vue`, `formulaires/[slug].vue`, `levees-de-fonds/index.vue`, `levees-de-fonds/[slug].vue`
- [x] T040 [P] [US2] Ajouter `ogLocale` et `ogLocaleAlternate` reactifs dans chaque `useSeoMeta()` des pages a-propos : `a-propos/index.vue`, `histoire.vue`, `strategie.vue`, `gouvernance.vue`, `equipe/index.vue`, `equipe/[id].vue`, `organisation/index.vue`, `organisation/[type]/[slug].vue`, `partenaires/index.vue`, `partenaires/campus/[slug].vue`
- [x] T040 [P] [US2] Ajouter `ogLocale` et `ogLocaleAlternate` reactifs dans chaque `useSeoMeta()` des pages actualites : `actualites/index.vue`, `[slug].vue`, `evenements/index.vue`, `evenements/[id].vue`, `appels/index.vue`, `appels/[slug].vue`
- [x] T040 [P] [US2] Ajouter `ogLocale` et `ogLocaleAlternate` reactifs dans chaque `useSeoMeta()` des pages formations, projets, candidatures, nousrejoindre, alumni, siege : `formations/[type]/index.vue`, `formations/[type]/[slug].vue`, `projets/index.vue`, `projets/[slug]/index.vue`, `projets/[slug]/appels/[appelSlug]/index.vue`, `projets/[slug]/appels/[appelSlug]/postuler.vue`, `candidatures/index.vue`, `candidatures/postuler/[slug].vue`, `nousrejoindre/index.vue`, `nousrejoindre/candidature-enseignant.vue`, `alumni/index.vue`, `siege/index.vue`

**Checkpoint**: Chaque page publique affiche `og:locale` correspondant a la langue active et `og:locale:alternate` pour les 2 autres langues.

---

## Phase 5: User Story 3 - Optimisation Twitter/X Cards (Priority: P3)

**Goal**: Chaque page affiche une Twitter Card `summary_large_image` avec titre, description et image coherents avec les balises OG.

**Independent Test**: Inspecter le HTML source et verifier la presence de `twitter:card`, `twitter:title`, `twitter:description`, `twitter:image` sur chaque page publique.

### Implementation

- [x] T040 [US3] Verifier que les balises globales `twitter:card` et `twitter:image` definies dans `nuxt.config.ts` (T006) sont bien presentes dans le HTML — si non, corriger.
- [x] T040 [US3] Ajouter `twitterTitle` et `twitterDescription` dans les `useSeoMeta()` des pages dynamiques avec image (actualites, evenements, appels, formations, projets, campus, equipe, levees-de-fonds) pour surcharger les valeurs globales — valeurs identiques a `ogTitle`/`ogDescription`. Ajouter `twitterImage` pour les pages avec image specifique (meme URL absolue que ogImage). Fichiers : `usenghor_nuxt/app/pages/actualites/[slug].vue`, `actualites/evenements/[id].vue`, `actualites/appels/[slug].vue`, `formations/[type]/[slug].vue`, `projets/[slug]/index.vue`, `a-propos/partenaires/campus/[slug].vue`, `a-propos/equipe/[id].vue`, `levees-de-fonds/[slug].vue`

**Checkpoint**: Twitter Card Validator affiche une carte `summary_large_image` complete pour toute page publique.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Validation finale et nettoyage

- [x] T048 Inspecter le HTML source (View Source) de 5 pages representatives (homepage, une actualite, une formation, a-propos, un projet) et verifier que toutes les balises OG et Twitter sont presentes avec des URLs absolues
- [x] T049 Verifier qu'aucune page admin (`/admin/*`) n'a de balises `og:title` ou `og:description` specifiques (seuls les defaults globaux sont acceptables)
- [x] T050 Ajouter `NUXT_PUBLIC_SITE_URL` dans le fichier `.env.example` ou la documentation de deploiement si existant, et dans les variables d'environnement Docker de production (`usenghor_nuxt` container)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Aucune dependance — peut demarrer immediatement
- **Foundational (Phase 2)**: Depend de T001 (siteUrl) et T002 (image OG) de la Phase 1
- **US1 (Phase 3)**: Depend de Phase 2 complete (meta globales en place)
- **US2 (Phase 4)**: Depend de Phase 3 (les appels useSeoMeta doivent exister avant d'y ajouter ogLocale)
- **US3 (Phase 5)**: Depend de Phase 2 (twitter:card global) + peut se faire en parallele de Phase 4
- **Polish (Phase 6)**: Depend de toutes les phases precedentes

### User Story Dependencies

- **US1 (P1)**: Depend de Phase 2 — aucune dependance sur d'autres stories
- **US2 (P2)**: Depend de US1 (les appels useSeoMeta doivent etre en place)
- **US3 (P3)**: Depend de Phase 2 — peut se faire en parallele de US2

### Parallel Opportunities

- T002, T003, T004, T005 (image + i18n) en parallele
- T007-T040 (toutes les modifications de pages US1) en parallele (fichiers differents)
- T043, T044, T045 (locale par groupe de pages US2) en parallele
- US3 (Phase 5) en parallele avec US2 (Phase 4)

---

## Parallel Example: User Story 1

```bash
# Apres Phase 2 complete, lancer TOUTES les modifications de pages en parallele :
# Groupe 1 — Pages sans meta (T007-T010)
Task: "Ajouter useSeoMeta() dans index.vue"
Task: "Ajouter useSeoMeta() dans formations/index.vue"
Task: "Ajouter useSeoMeta() dans about.vue"
Task: "Ajouter useSeoMeta() dans formulaires/[slug].vue"

# Groupe 2 — Migrations levees-de-fonds (T011-T012)
Task: "Migrer useHead vers useSeoMeta dans levees-de-fonds/index.vue"
Task: "Migrer useHead vers useSeoMeta dans levees-de-fonds/[slug].vue"

# Groupe 3 — Pages dynamiques avec image (T013-T019)
Task: "Modifier ogImage dans actualites/[slug].vue"
Task: "Modifier ogImage dans actualites/evenements/[id].vue"
# ... (tous en parallele, fichiers differents)

# Groupe 4 — Pages statiques existantes (T020-T040)
Task: "Completer useSeoMeta dans a-propos/index.vue"
# ... (tous en parallele, fichiers differents)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Completer Phase 1: Setup (T001-T005)
2. Completer Phase 2: Foundational (T006)
3. Completer Phase 3: User Story 1 (T007-T040)
4. **STOP et VALIDER**: Verifier le HTML source de quelques pages, tester avec Facebook Sharing Debugger
5. Deployer si pret — les liens partages afficheront deja titre + description + image

### Incremental Delivery

1. Setup + Foundational → Socle OG global en place
2. US1 → Cartes de partage completes sur toutes les pages (MVP!)
3. US2 → Coherence multilingue
4. US3 → Twitter Cards optimisees
5. Polish → Validation finale

---

## Notes

- Toutes les taches [P] dans US1 modifient des fichiers differents → parallelisation maximale
- Le pattern commun pour chaque page : `const { public: { siteUrl } } = useRuntimeConfig()` + `ogUrl: () => siteUrl + useRoute().fullPath`
- Pour ogImage avec variante medium : `ogImage: () => entity.value?.cover_image_external_id ? \`${siteUrl}/api/public/media/${entity.value.cover_image_external_id}/download?variant=medium\` : undefined`
- Ne pas definir `ogImage` dans useSeoMeta si la page n'a pas d'image specifique — le fallback global de nuxt.config.ts s'appliquera automatiquement
- Commit apres chaque phase ou groupe logique de taches
