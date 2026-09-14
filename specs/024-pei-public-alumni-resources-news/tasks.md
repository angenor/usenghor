---

description: "Tâches d'implémentation — mini-site public PEI : alumni, partenaires, ressources, actualités (024)"
---

# Tasks: Mini-site public « Entreprendre à Senghor » — alumni, partenaires, ressources, actualités

**Input**: Design documents from `/specs/024-pei-public-alumni-resources-news/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md)

**Tests**: Aucun test automatisé demandé (frontend sans infrastructure de test ; backend inchangé). Les tâches de validation renvoient aux blocs du quickstart. Les tests pytest existants sont rejoués en non-régression (Phase 8).

**Organization**: Tâches groupées par user story (US1 alumni P1, US2 partenaires P2, US3 ressources P2, US4 actualités P2, US5 i18n / RTL / mobile / sombre / SEO P3). Chaque story est livrable et testable seule après les phases 1–2.

## Format: `[ID] [P?] [Story] Description`

- **[P]** : parallélisable (fichiers différents, aucune dépendance sur une tâche inachevée)
- **[Story]** : US1…US5 (phases de user story uniquement)
- Chemins exacts dans chaque description. Racines : `usenghor_nuxt/` (frontend), `usenghor_backend/` (migration).

## Path Conventions

- Frontend : `usenghor_nuxt/app/{pages,components,composables,utils,types}`, `usenghor_nuxt/i18n/locales/{fr,en,ar}/`
- Migration : `usenghor_backend/documentation/modele_de_données/migrations/`
- Composants auto-importés par chemin : `components/entrepreneurship/PillTabs.vue` → `<EntrepreneurshipPillTabs>`
- Conventions transverses (toutes les tâches) : français accentué dans le code et les contenus ; noms de fichiers `[a-z0-9_-]` ; classes `dark:` et propriétés logiques Tailwind (`ps-`, `ms-`, `rtl:`) ; aucun texte visible codé en dur (i18n `pei.*` ou clés éditoriales) ; aucun appel à `/api/admin/*`

---

## Phase 1: Setup (porte d'accord et vérifications)

**Purpose**: Obtenir l'accord sur le SQL et confirmer les prérequis de réutilisation avant tout code.

- [X] T001 Présenter au responsable le SQL de la migration 048 (`specs/024-pei-public-alumni-resources-news/data-model.md` § 3 : 26 clés `entrepreneurship.{alumni,partners,resources,news}.*`, `ON CONFLICT (key) DO NOTHING`, catégorie `values`, `value_type = 'text'`, textes des heros partenaires / ressources / actualités proposés) et **attendre l'accord explicite** avant T015–T018 ; consigner la décision (et les textes retouchés) dans `specs/024-pei-public-alumni-resources-news/data-model.md` § 3
- [X] T002 [P] Vérifier par sous-agent (`usenghor_nuxt/app/components/**`) qu'aucun composant d'état vide (`*Empty*`, `*NoData*`, `*Placeholder*`), de sous-onglets à props (`*Pill*`, `*Tabs*` hors `section/about/TabsNav.vue`), de carte portrait / témoignage public ni de carte de ressource téléchargeable n'existe déjà ; si un équivalent réutilisable apparaît, l'utiliser à la place de T009 / T019 / T020 / T026 et noter l'écart dans `specs/024-pei-public-alumni-resources-news/research.md` (inventaire du 2026-09-14 : aucun trouvé)
- [X] T003 [P] Relire `usenghor_nuxt/app/plugins/fontawesome.ts` (analyse du 2026-09-14 : `library.add(fas, far, fab)`, packs complets) et confirmer qu'aucune modification n'est nécessaire pour `fa-brands fa-linkedin-in`, `fa-brands fa-instagram`, `fa-brands fa-facebook-f`, `fa-solid fa-star`, `fa-solid fa-file-arrow-down`, `fa-solid fa-circle-play`, `fa-solid fa-globe`, `fa-solid fa-arrow-up-right-from-square`, `fa-solid fa-user`, `fa-solid fa-images`, `fa-solid fa-toolbox` ; si le plugin a changé entre-temps, ajouter les imports nommés manquants

---

## Phase 2: Foundational (prérequis bloquants)

**Purpose**: Utilitaires, i18n, composable de page, extensions de composants et clés éditoriales partagés par toutes les stories.

**⚠️ CRITICAL**: T004–T014 doivent être terminées avant toute page ; T015–T018 (migration + config) avant la validation finale des heros (les pages tolèrent des clés absentes grâce aux replis).

- [X] T004 [P] Ajouter à `usenghor_nuxt/app/utils/pei-presentation.ts` (imports de types `PeiLaureateType`, `PeiCohortType`, `PeiLaureatePublic`, `PeiResourcePublic` depuis `~/types/api/entrepreneurship`) : `export const PEI_LAUREATE_TAB_QUERY = 'type'` ; `cohortTypeForLaureateType(type)` (`fse_laureate` → `fse`, `student_entrepreneur` → `see`) ; `laureateTypeFromQuery(value: unknown): PeiLaureateType` (`'student_entrepreneur'` → lui-même, toute autre valeur → `'fse_laureate'`) ; `sortLaureatesFeaturedFirst(list)` (copie triée stable : `Number(b.is_featured) - Number(a.is_featured) || a.display_order - b.display_order`) ; `groupResourcesByCategory(resources, label: (r) => string, otherLabel: string)` → `{ key, label, items }[]` (clé = `category` FR `trim().toLocaleLowerCase('fr').replace(/\s+/g, ' ')`, ordre de première apparition, intitulé = `label(première ressource)`, ressources sans catégorie regroupées **en dernier** sous `otherLabel`) ; `youTubeId(url)` (regex `/(?:youtube\.com\/watch\?v=|youtu\.be\/)([^&\s]+)/` de `components/projet/ProjetMediatheque.vue`) ; `isHttpUrl(value): value is string` (`/^https?:\/\//i` après `trim`)
- [X] T005 [P] Étendre `buildWebPage` dans `usenghor_nuxt/app/composables/usePeiJsonLd.ts` avec un paramètre optionnel `type?: 'WebPage' | 'CollectionPage'` (défaut `'WebPage'`, `'@type'` = valeur passée) ; aucun autre changement (023 inchangée)
- [X] T006 [P] Compléter `usenghor_nuxt/i18n/locales/fr/entrepreneurship.json` (namespace `pei`) avec les clés du contrat `contracts/frontend.md` § i18n : `common.{viewMore,backHome,openInNewTab}`, `alumni.{tabsLabel,tabs.fse,tabs.see,featured,cohortYear,mentorSubject,links.{website,linkedin,instagram,facebook,video},empty.title,empty.description}`, `partners.{visit,empty.title,empty.description}`, `resources.{mediaTitle,toolboxTitle,otherCategory,download,open,watch,empty.title,empty.description}`, `news.{newsTitle,eventsTitle,upcoming,past,empty.title,empty.description}`, `seo.{alumniTitle,alumniDescription,partnersTitle,partnersDescription,resourcesTitle,resourcesDescription,newsTitle,newsDescription}` (valeurs FR du contrat, descriptions SEO ≤ 160 caractères)
- [X] T007 [P] Ajouter les mêmes clés traduites en anglais dans `usenghor_nuxt/i18n/locales/en/entrepreneurship.json` (aucune valeur vide, terminologie de `pei.nav.*` existant : « Our alumni », « Our resources »)
- [X] T008 [P] Ajouter les mêmes clés traduites en arabe dans `usenghor_nuxt/i18n/locales/ar/entrepreneurship.json` (aucune valeur vide, terminologie existante : خريجونا, مواردنا)
- [X] T009 [P] Créer `usenghor_nuxt/app/components/entrepreneurship/EmptyState.vue` : props `icon?: string` (défaut `'fa-solid fa-folder-open'`), `title: string`, `description?: string`, `to?: string`, `linkLabel?: string` ; bloc centré `py-24 px-4 text-center`, icône `w-12 h-12 text-gray-300 dark:text-gray-600`, titre `text-xl font-semibold text-gray-900 dark:text-white`, description `text-gray-600 dark:text-gray-300`, lien `NuxtLink :to="localePath(to)"` avec flèche `rtl:rotate-180` si `to` fourni ; `role="status"`
- [X] T010 Créer `usenghor_nuxt/app/composables/usePeiPage.ts` selon `contracts/frontend.md` § usePeiPage : `usePeiPage({ heroPrefix, navKey })` asynchrone — `await useAsyncData('editorial-entrepreneurship', () => loadContent().then(() => true))` via `useEditorialContent('entrepreneurship')`, `text(key)` = `getRawContent('entrepreneurship.' + key)?.trim() || ''`, `ddeServiceId` (`isUuid`), `ddeService` via `useAsyncData('pei-' + heroPrefix + '-dde', …getServiceById().catch(() => null))`, `hero` (`badge`, `title = text(prefix + '.hero.title') || t('pei.seo.' + navKey + 'Title')`, `subtitle`, `images = heroImage ? [heroImage] : []` avec `useMediaApi().getMediaUrl(id, 'medium')`), `breadcrumb` à 6 niveaux copié de `pages/entrepreneuriat/activites.vue` (dernier = `t('pei.nav.' + navKey)`, DDE cliquable via `getServiceUrl` si résolu), `applySeo()` = `useSeoMeta` (title, description = sous-titre ou `pei.seo.<navKey>Description`, ogTitle, ogDescription, `ogUrl: siteUrl + route.fullPath`, ogImage si image, ogLocale / ogLocaleAlternate avec `localeMap { fr: 'fr_FR', en: 'en_US', ar: 'ar_SA' }`) + `useHead` avec 3 scripts JSON-LD (`buildPeiOrganization({ name: text('hero.title') || t('pei.seo.homeTitle'), email: text('contact.email') })`, `buildWebPage({ path: route.path, name, description, type: 'CollectionPage' })`, `buildBreadcrumbList(breadcrumb)`) ; commentaire explicite « appeler applySeo() après les useAsyncData de la page (gotcha TDZ unhead) »
- [X] T011 [P] Étendre `usenghor_nuxt/app/components/entrepreneurship/StatsPanel.vue` : prop `variant?: 'panel' | 'band'` (défaut `'panel'`), `title` devient optionnel (`title?: string`, `<p>` rendu seulement si fourni) ; variante `band` : conteneur `w-full bg-gradient-to-r from-brand-blue-900 via-brand-blue-800 to-brand-blue-900 py-12 sm:py-16`, `dl` `max-w-7xl mx-auto px-4 grid grid-cols-1 gap-8 sm:grid-cols-3 sm:gap-0 sm:divide-x divide-white/15 rtl:divide-x-reverse`, chaque tuile `text-center px-6`, `dd` `text-4xl sm:text-5xl font-bold tabular-nums text-white`, `dt` `mt-2 text-xs uppercase tracking-[0.2em] text-white/70` ; réutiliser `displayValue` / `animate` / `IntersectionObserver` / `prefers-reduced-motion` existants ; **le rendu `panel` reste identique** (vérifier `/entrepreneuriat` avant / après)
- [X] T012 [P] Étendre `usenghor_nuxt/app/components/entrepreneurship/CtaBanner.vue` : `to` devient optionnel, nouvelle prop `href?: string` ; si `href` → bouton `<a :href="href">` (mêmes classes que le `NuxtLink`), sinon `NuxtLink :to="localePath(to)"` inchangé ; garde de développement : si ni `to` ni `href`, ne pas rendre le bouton
- [X] T013 [P] Étendre `usenghor_nuxt/app/components/entrepreneurship/EventList.vue` : prop `title?: string` ; `<h3>` affiche `title ?? t('pei.activities.upcomingEvents')` ; aucun autre changement
- [X] T014 [P] Étendre `usenghor_nuxt/app/components/entrepreneurship/PartnerFamilies.vue` : prop `variant?: 'logos' | 'detailed'` (défaut `'logos'`, template actuel conservé tel quel dans une branche `v-if="variant === 'logos'"`) ; variante `detailed` : `<div class="space-y-16">` avec une `<section :aria-labelledby>` par famille de `visible` (ordre `PEI_FAMILY_ORDER`), en-tête = badge existant (`badgeClasses`) + `<h2 class="mt-3 text-2xl sm:text-3xl font-bold text-gray-900 dark:text-white">{{ t('pei.families.' + family) }}</h2>`, grille `grid gap-6 md:grid-cols-2 lg:grid-cols-3` de cartes `article rounded-2xl border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 p-6 flex flex-col gap-4` : zone logo `h-20 rounded-xl bg-white border border-gray-100 flex items-center justify-center p-3` (`<img :src="logo_url" :alt="name" class="max-h-16 max-w-full object-contain" loading="lazy">` ou nom en `font-bold text-gray-700 text-center`), `<h3 class="font-bold text-gray-900 dark:text-white">{{ partner.name }}</h3>`, description `useLocalizedField().localized(partner, 'description')` en `text-sm text-gray-600 dark:text-gray-300 line-clamp-4` si non vide, lien `<a v-if="partner.website" :href target="_blank" rel="noopener noreferrer" class="mt-auto inline-flex items-center gap-2 text-sm font-medium text-brand-blue-700 dark:text-brand-blue-300 hover:underline">{{ t('pei.partners.visit') }} <font-awesome-icon icon="fa-solid fa-arrow-up-right-from-square" class="w-3.5 h-3.5" aria-hidden="true" /></a>` ; aucun réseau social
- [X] T015 Créer `usenghor_backend/documentation/modele_de_données/migrations/048_pei_public_pages_keys.sql` **après l'accord T001**, en recopiant le SQL validé de `data-model.md` § 3 (en-tête de commentaire au format de `047_pei_activities_hero_keys.sql`, `BEGIN; INSERT … SELECT … FROM (VALUES …) AS v(key, value, value_type, description) ON CONFLICT (key) DO NOTHING; COMMIT; \echo`) — 26 lignes, apostrophes doublées (`''`)
- [X] T016 [P] Créer `usenghor_backend/documentation/modele_de_données/migrations/048_pei_public_pages_keys_rollback.sql` : `DELETE FROM editorial_contents WHERE key IN (…26 clés…)` entre `BEGIN;` / `COMMIT;` + `\echo`, en-tête précisant l'indépendance vis-à-vis de 046 / 047
- [X] T017 [P] Ajouter à `usenghor_nuxt/app/composables/editorial-pages-config.ts`, dans `entrepreneurshipPageSections` après la section `entrepreneurship-see` et avant `entrepreneurship-settings`, quatre sections selon `data-model.md` § 4 : `entrepreneurship-alumni` (name « Nos alumni », icon `user-graduate`, 14 clés : `alumni.hero.{badge,title,subtitle,image}` types text / text / textarea / image, `alumni.stats.{1,2,3}.{value,label}` text, `alumni.fse.{badge,title}` et `alumni.see.{badge,title}` text), `entrepreneurship-partners-page` (« Nos partenaires (page) », icon `handshake`, `partners.hero.*`), `entrepreneurship-resources` (« Nos ressources », icon `toolbox`, `resources.hero.*`), `entrepreneurship-news` (« Actualités du pôle », icon `newspaper`, `news.hero.*`) ; chaque `field` avec `key`, `label`, `description`, `type`, `editorialKey`, `editable: true`, `defaultValue` = valeur initiale du contrat `contracts/editorial-keys.md` ; couleurs de section distinctes des existantes
- [X] T018 Ajouter les 26 littéraux `'entrepreneurship.alumni.hero.badge'` … `'entrepreneurship.news.hero.image'` à l'union `ValueSectionKey` dans `usenghor_nuxt/app/types/api/editorial.ts` (après `'entrepreneurship.activities.hero.image'`, l. ~615), puis jouer la migration en local deux fois et vérifier le compte (quickstart § 1 : `docker exec -i usenghor_postgres psql -U usenghor -d usenghor < 048_pei_public_pages_keys.sql` × 2 → 0 erreur, `count(*)` sur `key LIKE 'entrepreneurship.%'` = 74) ; contrôler dans Admin → Valeurs → Entrepreneuriat que les quatre sections s'affichent avec leurs valeurs

**Checkpoint**: utilitaires, i18n, composable de page, extensions et clés éditoriales prêts — les stories peuvent démarrer en parallèle.

---

## Phase 3: User Story 1 — Découvrir les portraits d'alumni par cohorte (Priority: P1) 🎯 MVP

**Goal**: `/entrepreneuriat/alumni` : hero, sous-nav, sous-onglets pilule portés par `?type=`, bandeau de 3 chiffres éditoriaux, titre de section par onglet, une section par cohorte avec cartes portrait (vedettes en premier), encart « Devenir mentor » en `mailto:`.

**Independent Test**: quickstart § 3 (données) puis § 4 : SSR de l'onglet demandé, ordre des cohortes et des portraits, icônes de liens, bascule d'onglet sans rechargement, portrait dépublié disparu, états vides, bandeau et encart masqués quand vides.

### Implementation for User Story 1

- [X] T019 [P] [US1] Créer `usenghor_nuxt/app/components/entrepreneurship/PillTabs.vue` : props `tabs: { key: string; label: string; icon?: string; to: RouteLocationRaw }[]`, `activeKey: string`, `ariaLabel?: string` ; `<nav :aria-label>` `bg-white/30 dark:bg-gray-800/30 backdrop-blur-sm border-b border-gray-200/50 dark:border-gray-700/50`, conteneur `max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 flex items-center justify-center gap-1 py-2 overflow-x-auto scrollbar-hide`, `NuxtLink v-for` classes `group flex shrink-0 items-center gap-2 px-4 py-2 text-sm font-medium rounded-full whitespace-nowrap transition-all duration-200`, actif `bg-brand-blue-100 dark:bg-brand-blue-900/30 text-brand-blue-700 dark:text-brand-blue-400` + `aria-current="page"`, inactif `text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-700/50 hover:text-gray-900 dark:hover:text-gray-200`, icône `w-3.5 h-3.5` si fournie (classes recopiées de `components/section/about/TabsNav.vue` l. 120-140)
- [X] T020 [P] [US1] Créer `usenghor_nuxt/app/components/entrepreneurship/LaureateCard.vue` (`laureate: PeiLaureatePublic`) : `<article class="flex flex-col rounded-2xl border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 overflow-hidden">` ; photo `aspect-[4/3] w-full object-cover` (`photo_url`, `alt = full_name`, `loading="lazy"`) ou substitut `aspect-[4/3] bg-gray-100 dark:bg-gray-700 flex items-center justify-center` avec `fa-solid fa-user` `text-gray-400 w-10 h-10` ; si `is_featured`, badge discret en coin `absolute top-3 start-3 rounded-full bg-white/90 dark:bg-gray-900/80 p-1.5` avec `fa-solid fa-star text-amber-500` et `:title="t('pei.alumni.featured')"` ; corps `p-5 flex flex-col gap-2` : ligne nom (`h3 font-bold text-gray-900 dark:text-white`) + badge cohorte (`localized(laureate, 'cohort_label')`, `rounded-full bg-brand-blue-100 dark:bg-brand-blue-900/40 text-brand-blue-700 dark:text-brand-blue-300 text-[11px] font-semibold px-2 py-0.5 shrink-0`), projet `text-brand-blue-600 dark:text-brand-blue-300 font-medium`, département `localized(laureate, 'department_label')` `text-sm text-gray-500 dark:text-gray-400` si non vide, verbatim `localized(laureate, 'quote')` en `<blockquote class="mt-2 text-sm italic text-gray-600 dark:text-gray-300 border-s-2 border-brand-blue-200 dark:border-brand-blue-800 ps-3">` si non vide ; rangée `mt-auto pt-3 flex gap-2` d'icônes 32 px (`w-8 h-8 rounded-full border border-gray-200 dark:border-gray-600 flex items-center justify-center text-gray-600 dark:text-gray-300 hover:text-brand-blue-600`) pour chaque lien dont `isHttpUrl()` est vrai, dans l'ordre `website_url` (`fa-solid fa-globe`), `linkedin_url` (`fa-brands fa-linkedin-in`), `instagram_url` (`fa-brands fa-instagram`), `facebook_url` (`fa-brands fa-facebook-f`), `video_url` (`fa-solid fa-play`), `target="_blank" rel="noopener noreferrer"`, `:aria-label="t('pei.alumni.links.<clé>', { name: full_name })"` ; rangée omise si aucun lien
- [X] T021 [US1] Créer `usenghor_nuxt/app/components/entrepreneurship/CohortSection.vue` (`cohort: PeiCohortPublic`, `laureates: PeiLaureatePublic[]`, `anchorId?: string`) : `<section :id="anchorId" class="scroll-mt-40 py-12 border-t border-gray-200 dark:border-gray-700 first:border-t-0">` ; en-tête `flex flex-wrap items-start justify-between gap-4` : `<h3 class="text-2xl font-bold text-gray-900 dark:text-white">{{ localized(cohort, 'label') }}</h3>` + sous-titre `text-sm text-gray-500` = `t('pei.alumni.cohortYear', { year: cohort.year })` puis ` · ` + `localized(cohort, 'focus')` si non vide ; badge focus `rounded-full bg-amber-100 dark:bg-amber-900/40 text-amber-800 dark:text-amber-300 text-xs font-semibold uppercase tracking-wider px-3 py-1` si focus non vide ; `<RichTextRenderer>` sur `localized(cohort, 'summary_html')` dans `prose dark:prose-invert max-w-3xl mt-4` si non vide ; grille `mt-8 grid gap-6 sm:grid-cols-2 lg:grid-cols-4` de `<EntrepreneurshipLaureateCard v-for="l in sortLaureatesFeaturedFirst(laureates)" :key="l.id" :laureate="l">` (dépend de T020)
- [X] T022 [US1] Créer `usenghor_nuxt/app/pages/entrepreneuriat/alumni.vue` : `const page = await usePeiPage({ heroPrefix: 'alumni', navKey: 'alumni' })` ; `currentType = computed(() => laureateTypeFromQuery(route.query[PEI_LAUREATE_TAB_QUERY]))` ; `useAsyncData('pei-alumni-laureates', () => listLaureates().catch(() => ({ groups: [], stats: null })))` (un seul appel) ; `sections = groups.filter(g => g.cohort.type === cohortTypeForLaureateType(currentType))` ; `stats` = paires `alumni.stats.{1,2,3}.{value,label}` à `value` non vide ; `sectionBadge / sectionTitle` = `text('alumni.fse.badge' | 'alumni.see.badge')` etc. selon l'onglet ; `mentor` affiché si `text('see.mentor.title')` **et** `text('contact.email')` non vides, `href = 'mailto:' + email + '?subject=' + encodeURIComponent(t('pei.alumni.mentorSubject'))` ; `page.applySeo()` en dernier ; template : `<PageHero v-bind="page.hero" :breadcrumb="page.breadcrumb">`, `<EntrepreneurshipSubNav />`, `<EntrepreneurshipPillTabs :aria-label="t('pei.alumni.tabsLabel')" :active-key="currentType" :tabs="[{ key: 'fse_laureate', label: t('pei.alumni.tabs.fse'), icon: 'fa-solid fa-award', to: { path: route.path, query: {} } }, { key: 'student_entrepreneur', label: t('pei.alumni.tabs.see'), icon: 'fa-solid fa-user-graduate', to: { path: route.path, query: { type: 'student_entrepreneur' } } }]">`, `<EntrepreneurshipStatsPanel v-if="stats.length" variant="band" :stats="stats">`, conteneur `max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-16` avec badge + `h2` de section (`text-3xl sm:text-4xl font-bold` + soulignement `w-32 h-1 bg-brand-blue-500`) si `sectionTitle`, puis `<EntrepreneurshipCohortSection v-for="g in sections" :key="g.cohort.id" :cohort="g.cohort" :laureates="g.laureates" :anchor-id="'cohorte-' + g.cohort.code">` ou `<EntrepreneurshipEmptyState v-else icon="fa-solid fa-user-graduate" :title="t('pei.alumni.empty.title')" :description="t('pei.alumni.empty.description')" to="/entrepreneuriat" :link-label="t('pei.common.backHome')">` (onglets toujours affichés) ; `<EntrepreneurshipCtaBanner v-if="mentor" :title="text('see.mentor.title')" :description="text('see.mentor.description')" :button-label="text('see.mentor.button')" :href="mentorHref">` dans une section `bg-gray-50 dark:bg-gray-800/60 py-16` (dépend de T019, T021)
- [X] T023 [US1] Valider US1 selon `specs/024-pei-public-alumni-resources-news/quickstart.md` § 4 : `curl` SSR des deux onglets (`aria-current` présent dans le HTML de `?type=student_entrepreneur`), ordre des cohortes et des vedettes, icônes exactes, bascule sans rechargement + retour arrière, `?type=foo` → FSE, portrait dépublié disparu ≤ 60 s, section de cohorte vide disparue, état vide de l'onglet SEE, bandeau et encart masqués quand vides, `mailto:` correct ; corriger les écarts dans les fichiers de T019–T022

**Checkpoint**: la page alumni est complète et livrable seule (MVP).

---

## Phase 4: User Story 2 — Parcourir l'écosystème de partenaires du pôle (Priority: P2)

**Goal**: `/entrepreneuriat/partenaires` : hero, sous-nav, familles non vides en version détaillée (logo, nom, description, site web), état vide si aucun partenaire ; accueil et `/a-propos/partenaires` inchangés.

**Independent Test**: quickstart § 5 : deux familles seulement, cartes complètes, partenaire inactif absent, famille vide disparue, état vide, comparaison de l'accueil du pôle avant / après.

### Implementation for User Story 2

- [X] T024 [US2] Créer `usenghor_nuxt/app/pages/entrepreneuriat/partenaires.vue` : `const page = await usePeiPage({ heroPrefix: 'partners', navKey: 'partners' })` ; `useAsyncData('pei-partners-page', () => listPartners().catch(() => []))` ; `hasPartners = families.some(f => f.partners.length > 0)` ; `page.applySeo()` en dernier ; template : `<PageHero v-bind="page.hero" :breadcrumb="page.breadcrumb">`, `<EntrepreneurshipSubNav />`, conteneur `max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-16` avec `<EntrepreneurshipPartnerFamilies v-if="hasPartners" variant="detailed" :families="families">` sinon `<EntrepreneurshipEmptyState icon="fa-solid fa-handshake" :title="t('pei.partners.empty.title')" :description="t('pei.partners.empty.description')" to="/entrepreneuriat" :link-label="t('pei.common.backHome')">` (dépend de T014)
- [X] T025 [US2] Valider US2 selon `quickstart.md` § 5 (familles, cartes, inactif, état vide) et prendre les captures avant / après de `/entrepreneuriat` (section « Un écosystème d'appui », variante logos) et de `/a-propos/partenaires` à 1440 px et 390 px ; corriger les écarts dans `components/entrepreneurship/PartnerFamilies.vue` ou `pages/entrepreneuriat/partenaires.vue`

**Checkpoint**: la page partenaires est complète et livrable seule.

---

## Phase 5: User Story 3 — Consulter les ressources : médiathèque et boîte à outils (Priority: P2)

**Goal**: `/entrepreneuriat/ressources` : bloc « Médiathèque » (albums du service DDE via la galerie du site) et bloc « Boîte à outils » (ressources publiées groupées par catégorie, téléchargement / lien / vidéo), état vide si les deux blocs sont vides.

**Independent Test**: quickstart § 6 : cartes d'album et visionneuse (filtre vidéo, lecture), groupes de catégories avec « Autres ressources » en dernier, téléchargement d'un PDF, liens et vidéo en nouvel onglet, ressource dépubliée absente, bloc Médiathèque masqué sans DDE, état vide ; `/mediatheque` et fiche service inchangées.

### Implementation for User Story 3

- [X] T026 [P] [US3] Créer `usenghor_nuxt/app/components/entrepreneurship/ResourceCard.vue` (`resource: PeiResourcePublic`) : `<article class="flex flex-col gap-4 rounded-2xl border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 p-6 transition-shadow hover:shadow-md">` ; si `type === 'video'` et `youTubeId(resource.url)` → vignette `aspect-video rounded-xl overflow-hidden relative` avec `<img :src="'https://img.youtube.com/vi/' + id + '/hqdefault.jpg'" loading="lazy" :alt="title">` et bouton play superposé (`fa-solid fa-play` sur cercle `bg-white/90`) ; sinon icône de type `w-12 h-12 rounded-xl flex items-center justify-center` : `document` → `fa-solid fa-file-arrow-down` `bg-brand-blue-100 text-brand-blue-700 dark:bg-brand-blue-900/40 dark:text-brand-blue-300`, `link` → `fa-solid fa-link` `bg-teal-100 text-teal-800 dark:bg-teal-900/40 dark:text-teal-300`, `video` → `fa-solid fa-circle-play` `bg-brand-red-100 text-brand-red-700 dark:bg-brand-red-900/40 dark:text-brand-red-300` ; `<h3 class="font-bold text-gray-900 dark:text-white">{{ localized(resource, 'title') }}</h3>`, description `localized(resource, 'description')` `text-sm text-gray-600 dark:text-gray-300 line-clamp-3` si non vide ; action `mt-auto inline-flex items-center gap-2 text-sm font-semibold text-brand-blue-700 dark:text-brand-blue-300 hover:underline` : `document` → `<a :href="resource.media_url + '?download=1'" download>` `t('pei.resources.download')` (paramètre `download` vérifié dans `usenghor_backend/app/routers/public/media.py` : `Content-Disposition: attachment`) ; `link` → `<a :href="resource.url" target="_blank" rel="noopener noreferrer">` `t('pei.resources.open')` + `fa-solid fa-arrow-up-right-from-square` + `<span class="sr-only">{{ t('pei.common.openInNewTab') }}</span>` ; `video` → idem avec `t('pei.resources.watch')` ; le composant rend `null` (`v-if` racine) si `type === 'document' && !media_url` ou si (`link` / `video`) et `!isHttpUrl(url)`
- [X] T027 [US3] Créer `usenghor_nuxt/app/pages/entrepreneuriat/ressources.vue` : `const page = await usePeiPage({ heroPrefix: 'resources', navKey: 'resources' })` ; `Promise.all` de `useAsyncData('pei-resources-albums', …)` (si `page.ddeServiceId` : `getServiceById(id)` → `ids = service.album_ids?.length ? service.album_ids : (service.album_external_id ? [service.album_external_id] : [])` → `Promise.all(ids.map(id => getAlbumById(id).catch(() => null)))` → `filter(a => a && a.media_items.length > 0)` ; sinon `[]` ; tout `.catch(() => [])`) et `useAsyncData('pei-resources-toolbox', () => listResources().catch(() => []))` ; `groups = groupResourcesByCategory(resources, r => localized(r, 'category'), t('pei.resources.otherCategory'))` ; `page.applySeo()` en dernier ; template : hero, sous-nav, section `bg-white dark:bg-gray-900` avec `<section v-if="albums.length" aria-labelledby="pei-media-title">` (`h2` `t('pei.resources.mediaTitle')` avec icône `fa-solid fa-images`, `<MediaLibraryTab :albums="albums">`), `<section v-if="groups.length" aria-labelledby="pei-toolbox-title" class="border-t">` (`h2` `t('pei.resources.toolboxTitle')` avec `fa-solid fa-toolbox`, puis pour chaque groupe `h3 text-xl font-bold` + grille `grid gap-6 sm:grid-cols-2 lg:grid-cols-3` de `<EntrepreneurshipResourceCard>`), `<EntrepreneurshipEmptyState v-if="!albums.length && !groups.length" icon="fa-solid fa-toolbox" :title="t('pei.resources.empty.title')" :description="t('pei.resources.empty.description')" to="/entrepreneuriat" :link-label="t('pei.common.backHome')">` (dépend de T026 ; imports `usePublicOrganizationApi`, `usePublicAlbumsApi`, `usePublicEntrepreneurshipApi`, `useLocalizedField`)
- [X] T028 [US3] Valider US3 selon `quickstart.md` § 6 (albums et visionneuse, groupes, téléchargement `?download=1`, liens, vignette YouTube, dépubliée absente, DDE vide → bloc masqué, état vide) et vérifier `/mediatheque` et l'onglet médiathèque de la fiche du service DDE inchangés ; corriger les écarts dans les fichiers de T026–T027

**Checkpoint**: la page ressources est complète et livrable seule.

---

## Phase 6: User Story 4 — Suivre la vie du pôle : actualités et événements (Priority: P2)

**Goal**: `/entrepreneuriat/actualites` : actualités DDE par lots de 12 (premier lot SSR, « Voir plus » serveur) avec la carte de `/actualites`, événements à venir puis passés par lots de 10, état vide si tout est vide ; `/actualites` inchangée.

**Independent Test**: quickstart § 7 : 12 cartes SSR filtrées DDE, « Voir plus » puis disparition, carte identique à `/actualites`, listes d'événements ordonnées vers les fiches existantes, sous-bloc vide masqué, état vide, capture de `/actualites` avant / après.

### Implementation for User Story 4

- [X] T029 [US4] Créer `usenghor_nuxt/app/pages/entrepreneuriat/actualites.vue` : `const page = await usePeiPage({ heroPrefix: 'news', navKey: 'news' })` ; constantes `NEWS_PAGE_SIZE = 12`, `EVENTS_PAGE_SIZE = 10` ; si `page.ddeServiceId` : `Promise.all` de `useAsyncData('pei-news-list', () => listPublishedNews({ service_id, page: 1, limit: 12 }).catch(() => ({ items: [], total: 0, page: 1, limit: 12, pages: 0 })))`, `useAsyncData('pei-news-upcoming', () => listPublishedEvents({ service_id, upcoming: true, order: 'asc', page: 1, limit: 10 }).catch(() => vide))`, `useAsyncData('pei-news-past', () => listPublishedEvents({ service_id, to_date: new Date().toISOString(), order: 'desc', page: 1, limit: 10 }).catch(() => vide))` (filtre serveur `start_date ≤ now`, complément exact de `upcoming` ; **aucun filtre client**, chaque lot est complet) ; états `newsItems / newsPage / newsPages` (initialisés depuis la réponse), `upcomingItems / upcomingPage / upcomingPages`, `pastItems / pastPage / pastPages`, `loadingMore` ; fonctions `loadMoreNews()` / `loadMoreUpcoming()` / `loadMorePast()` (page + 1 avec les mêmes paramètres — `loadMorePast` réutilise la **même** valeur `to_date` que le premier lot, mémorisée dans une constante, pour une pagination stable — concaténation, `try/catch` silencieux) ; `hasContent = newsItems.length || upcomingItems.length || pastItems.length` ; `page.applySeo()` en dernier ; template : hero, sous-nav, `<section v-if="newsItems.length" aria-labelledby="pei-news-title">` (`h2` `t('pei.news.newsTitle')`, grille `grid gap-8 sm:grid-cols-2 lg:grid-cols-3` de `<ActualitesNewsCard v-for :item :show-associations="false" image-variant="medium">`, bouton `<button v-if="newsPage < newsPages" type="button" :disabled="loadingMore" @click="loadMoreNews">{{ t('pei.common.viewMore') }}</button>` style `rounded-full border-2 border-brand-blue-500 text-brand-blue-600 px-8 py-3 font-semibold hover:bg-brand-blue-50`), `<section v-if="upcomingItems.length || pastItems.length" aria-labelledby="pei-events-title" class="border-t">` (`h2` `t('pei.news.eventsTitle')`, `<EntrepreneurshipEventList v-if="upcomingItems.length" :title="t('pei.news.upcoming')" :events="upcomingItems">` + « Voir plus », puis `<EntrepreneurshipEventList v-if="pastItems.length" :title="t('pei.news.past')" :events="pastItems" class="mt-12">` + « Voir plus »), `<EntrepreneurshipEmptyState v-if="!hasContent" icon="fa-solid fa-newspaper" :title="t('pei.news.empty.title')" :description="t('pei.news.empty.description')" to="/entrepreneuriat" :link-label="t('pei.common.backHome')">` (dépend de T013)
- [X] T030 [US4] Valider US4 selon `quickstart.md` § 7 (`curl` → 12 liens `/actualites/…` distincts, filtre service, « Voir plus » jusqu'à disparition, carte identique côte à côte, ordre des événements, sous-bloc masqué, état vide) et prendre les captures avant / après de `/actualites` à 1440 px et 390 px ; corriger les écarts dans `pages/entrepreneuriat/actualites.vue`

**Checkpoint**: la page actualités est complète et livrable seule.

---

## Phase 7: User Story 5 — Lire les quatre rubriques en anglais et en arabe, sur mobile et en mode sombre (Priority: P3)

**Goal**: libellés traduits, RTL en miroir, repli FR silencieux, 390 px sans défilement horizontal, mode sombre, partage et données structurées valides sur les quatre pages.

**Independent Test**: quickstart § 8–10 sur les quatre pages, trois langues, 1440 px et 390 px, clair et sombre, sitemap et JSON-LD.

### Implementation for User Story 5

- [X] T031 [P] [US5] Vérifier `/en/entrepreneuriat/{alumni,partenaires,ressources,actualites}` et `/ar/…` (quickstart § 8) : aucune clé `pei.` visible, `aria-label` des icônes traduits, repli FR pour un portrait sans département EN et un partenaire sans description EN, copie éditoriale FR ; en arabe `dir="rtl"`, pilules / bandeau (`rtl:divide-x-reverse`) / cartes / flèches (`rtl:rotate-180`) en miroir ; corriger les traductions manquantes dans `usenghor_nuxt/i18n/locales/{en,ar}/entrepreneurship.json` et les classes non logiques dans les composants de `usenghor_nuxt/app/components/entrepreneurship/`
- [X] T032 [P] [US5] Vérifier à 390 px et en mode sombre (quickstart § 9) : grilles en une colonne, pilules et sous-nav défilantes, bandeau empilé, `document.documentElement.scrollWidth === window.innerWidth` sur les quatre pages, contraste des cartes / bandeau / encart / états vides ; corriger dans les fichiers de `usenghor_nuxt/app/components/entrepreneurship/` et `usenghor_nuxt/app/pages/entrepreneuriat/`
- [X] T033 [US5] Vérifier le SEO (quickstart § 10) : `curl -s http://localhost:3000/sitemap.xml | grep -c "entrepreneuriat/"` ≥ 18, balises `og:*` des quatre pages, `og:url` avec `?type=student_entrepreneur` sur l'onglet SEE, trois scripts JSON-LD (`Organization`, `CollectionPage`, `BreadcrumbList` à 6 éléments) validés sur validator.schema.org ; corriger dans `usenghor_nuxt/app/composables/usePeiPage.ts` / `usePeiJsonLd.ts`
- [ ] T034 [US5] Lancer Lighthouse mobile sur les quatre pages (performance ≥ 90, accessibilité ≥ 90) avec les données de test ; traiter les écarts (images `loading="lazy"`, contrastes, `aria-*`) dans les composants concernés de `usenghor_nuxt/app/components/entrepreneurship/`

**Checkpoint**: les quatre pages sont conformes trilingue / RTL / mobile / sombre / SEO.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: non-régression, build, documentation.

- [X] T035 [P] Rejouer les tests backend de non-régression : `cd usenghor_backend && source .venv/bin/activate && pytest tests/integration/test_public_entrepreneurship_api.py tests/integration/test_public_events_service_filter.py -v` (aucun fichier de test modifié ; ne pas lancer les tests FAQ, quota du traducteur)
- [X] T036 [P] Lancer le build de production `cd usenghor_nuxt && NODE_OPTIONS=--max-old-space-size=8192 pnpm build` et corriger toute erreur de type ou d'import dans les fichiers créés / modifiés par cette feature
- [X] T037 Comparer les captures avant / après (T025, T030) de `/actualites`, `/a-propos/partenaires` et `/entrepreneuriat` à 1440 px et 390 px ; vérifier l'inventaire des routes (`ls usenghor_nuxt/app/pages/entrepreneuriat/` = `index.vue`, `activites.vue` + exactement 4 nouveaux fichiers, aucune page d'article / événement / album / partenaire) ; consigner le résultat dans `specs/024-pei-public-alumni-resources-news/quickstart.md` § 11
- [X] T038 Mettre à jour `CLAUDE.md` : tableau « Composants clés » (routes `/entrepreneuriat/{alumni,partenaires,ressources,actualites}`, `usePeiPage()`, `EntrepreneurshipPillTabs` / `CohortSection` / `LaureateCard` / `ResourceCard` / `EmptyState`, variantes `StatsPanel variant="band"`, `PartnerFamilies variant="detailed"`, `CtaBanner href`, `EventList title`), entrée « Recent Changes » `024-pei-public-alumni-resources-news` (migration `048_pei_public_pages_keys.sql`, 26 clés, 73 clés `entrepreneurship.*` déclarées, aucun changement backend), et vérifier que la mention des rubriques « non encore livrées » de la 023 est retirée
- [ ] T039 Après le déploiement (`git push origin main` des deux sous-dépôts puis `./deploy.sh update`), jouer la migration en production : `docker exec -i usenghor_db psql -U usenghor -d usenghor < usenghor_backend/documentation/modele_de_données/migrations/048_pei_public_pages_keys.sql` (deux fois, 0 erreur), vérifier `SELECT count(*) FROM editorial_contents WHERE key LIKE 'entrepreneurship.%'` (+26 par rapport à l'état antérieur) et que les quatre pages publiques affichent leurs heros (SC-010) ; consigner le résultat dans `specs/024-pei-public-alumni-resources-news/quickstart.md` § 13

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)** : T001 est une porte humaine (accord SQL) ; T002 et T003 en parallèle, immédiatement.
- **Phase 2 (Foundational)** : T004–T009 en parallèle dès T002 / T003 ; T010 après T004 et T005 ; T011–T014 en parallèle (indépendantes de T010) ; T015 après l'accord T001 ; T016 et T017 en parallèle avec T015 ; T018 après T015 et T017.
- **Phases 3–6 (US1–US4)** : démarrent après T004–T014 ; indépendantes entre elles (fichiers distincts) ; les heros affichent leurs textes éditoriaux seulement après T018 (repli i18n sinon).
- **Phase 7 (US5)** : après les phases 3–6.
- **Phase 8 (Polish)** : après la phase 7 ; T035 et T036 en parallèle ; T039 (migration en production) est la dernière tâche, après commit, push et déploiement.

### User Story Dependencies

- **US1 (alumni)** : T019, T020 en parallèle → T021 → T022 → T023. Dépend de T009, T010, T011, T012, T004.
- **US2 (partenaires)** : T024 → T025. Dépend de T009, T010, T014.
- **US3 (ressources)** : T026 → T027 → T028. Dépend de T004, T009, T010.
- **US4 (actualités)** : T029 → T030. Dépend de T009, T010, T013.
- **US5 (transverse)** : T031, T032 en parallèle → T033 → T034. Dépend de US1–US4.

### Parallel Opportunities

- Phase 2 : `{T004, T005, T006, T007, T008, T009}` puis `{T011, T012, T013, T014}` en même temps que T010 ; `{T016, T017}` pendant T015.
- Stories : US1, US2, US3 et US4 peuvent être développées par quatre agents en parallèle après la phase 2 (fichiers disjoints : `alumni.vue` + `PillTabs` + `LaureateCard` + `CohortSection` ; `partenaires.vue` ; `ressources.vue` + `ResourceCard` ; `actualites.vue`).
- Phase 7 : T031 et T032 en parallèle ; Phase 8 : T035 et T036 en parallèle.

### Parallel Example: Phase 2

```text
Agent A : T004 (utils) → T010 (usePeiPage)
Agent B : T006 (fr) + T007 (en) + T008 (ar)
Agent C : T009 (EmptyState) + T011 (StatsPanel band) + T012 (CtaBanner href)
Agent D : T013 (EventList title) + T014 (PartnerFamilies detailed)
Après accord T001 : Agent E : T015 + T016 (migration + rollback) ; Agent F : T017 (config) → T018 (types + rejeu)
```

### Parallel Example: User Story 1

```text
T019 (PillTabs) ‖ T020 (LaureateCard)  →  T021 (CohortSection)  →  T022 (alumni.vue)  →  T023 (validation)
```

---

## Implementation Strategy

### MVP First (US1 seule)

1. Phase 1 (accord SQL lancé, vérifications) → Phase 2 complète.
2. Phase 3 : page alumni (T019–T023) → **STOP, valider** : la rubrique la plus attendue est en ligne, atteignable depuis la sous-nav.

### Incremental Delivery

1. Phase 2 → US1 (alumni) → validation → livrable.
2. US2 (partenaires) → validation → livrable.
3. US3 (ressources) → validation → livrable.
4. US4 (actualités) → validation → livrable (la sous-nav n'a plus aucune rubrique « introuvable »).
5. US5 (trilingue / RTL / mobile / sombre / SEO) → Phase 8 (non-régression, build, CLAUDE.md) → mise en production : commit + push origin/main des deux sous-dépôts, `./deploy.sh update`, puis T039 (migration 048 sur `usenghor_db`, quickstart § 13).

### Notes

- Les phases 3–6 ne modifient aucun fichier commun : quatre agents peuvent les mener de front.
- Toute nouvelle clé de texte passe par `pei.*` (i18n) ou `entrepreneurship.*` (éditorial) ; aucun libellé en dur.
- Ne pas toucher `pages/entrepreneuriat/{index,activites}.vue`, `components/entrepreneurship/SubNav.vue`, `components/page/Hero.vue`, `pages/actualites/**`, `pages/mediatheque/**`, `pages/a-propos/**`.
