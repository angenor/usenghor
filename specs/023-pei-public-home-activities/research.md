# Research — Mini-site public PEI : accueil et « Nos activités » (023)

Phase 0 du plan. Chaque point : décision, justification, alternatives écartées. Sources : inventaire par sous-agents du 2026-09-13 (`app/components/page/Hero.vue`, `HeroSection.vue`, `section/about/TabsNav.vue`, `fundraising/AnchorNav.vue`, `section/Stats.vue`, `pages/actualites/index.vue`, `usePublicNewsApi`, `usePublicEventsApi`, `useEditorialContent`, `useMediaApi`, `usePublicOrganizationApi`, `editorial-pages-config.ts`, `routers/public/events.py`, `services/content_service.py`, migrations 045/046, `app.vue`, `nuxt.config.ts`, `tests/`), spec 023 (clarifications Q1–Q5), maquette `specs/maquettes-pei/accueil.{png,html}`.

## R1 — Extension de `PageHero` (slider + badge)

**Décision** : étendre `app/components/page/Hero.vue` avec quatre props optionnelles : `images?: string[]` (slider si ≥ 2 adresses ; 1 adresse = équivalent de `image`), `badge?: string`, `badgeIcon?: string`, `actions?: { label; to; variant?; icon? }[]` (les deux boutons de la maquette, rendus après le sous-titre uniquement si fournis — `PageHero` n'a pas de slot). Une image en erreur (`@error`, média supprimé) est retirée de la liste des slides. La prop `image` existante reste prioritaire pour la rétrocompatibilité (`images` ignorée si `image` fournie). Le slider est **rendu côté serveur pour la première image** (`<img>` natif, `fetchpriority="high"`, pas de `NuxtImg` — IPX échoue sur `/api/public/media/*/download`, cf. commentaire de `HeroSection.vue`), les suivantes en `loading="lazy"`. Mécanique : `currentSlide`, `<TransitionGroup>` fondu 1 s (copié de `HeroSection.vue`), intervalle **6 000 ms** démarré `onMounted`, nettoyé `onUnmounted`. Garanties nouvelles absentes du carrousel de la home : `window.matchMedia('(prefers-reduced-motion: reduce)')` → pas d'intervalle et transitions désactivées ; pause sur `mouseenter` / `focusin` du hero, reprise sur `mouseleave` / `focusout` ; pause quand `document.hidden`. Points : `<div role="tablist" :aria-label="t('hero.slider.slides')">` + `<button type="button" role="tab" :aria-selected :aria-label="t('hero.slider.slide', { n, total })">` (clés dans `hero.json`, composant transverse), gestion `@keydown` ← / → / Home / End sur le groupe, focus visible. Région live `aria-live="polite"` masquée annonçant le visuel courant. Les deux attributs orphelins existants sont retirés dans la même livraison (clarification Q3) : `:badge` + `badge-icon` dans `pages/a-propos/partenaires/index.vue` (l. 36-42) et le bloc `<template #badge>` dans `pages/a-propos/organisation/[type]/[slug].vue` (l. 451-465, balise refermée en auto-fermante).

**Justification** : la demande impose « pas de nouveau composant hero » ; `PageHero` n'a ni slot ni prop badge, donc l'ajout est additif et sans effet sur les 19 usages (aucun ne passe `images`). Le retrait des attributs orphelins garantit un DOM identique (l'attribut `badge` tombait en fall-through sur la `<section>`).

**Alternatives écartées** : slot `#badge` (les deux pages existantes l'utiliseraient d'un coup → régression visuelle) ; réutiliser `HeroSection.vue` (hero de la home, non paramétrable, sans accessibilité) ; bibliothèque de carrousel (aucune dépendance autorisée, `package.json` n'en contient pas).

## R2 — Sous-navigation du pôle

**Décision** : nouveau composant `app/components/entrepreneurship/SubNav.vue` (`<EntrepreneurshipSubNav>`), calqué sur `SectionAboutTabsNav` : racine `sticky top-20 z-40`, nav `bg-white dark:bg-gray-900 border-b shadow-sm`, conteneur `overflow-x-auto scrollbar-hide`, onglets `NuxtLink` avec `font-awesome-icon` `w-4 h-4`, actif `border-b-2 border-brand-blue-500 text-brand-blue-600 dark:text-brand-blue-400`, fonction `isActive(to, exact)` recopiée (`route.path` vs `localePath(to)`, `exact` pour `/entrepreneuriat`). Six onglets + bouton `bg-brand-red-500 text-white rounded-full` à droite (`ms-auto`), tous libellés via i18n `pei.nav.*`. Icônes : `fa-solid fa-circle-info` (Présentation), `fa-route` (Nos activités), `fa-user-graduate` (Nos alumni), `fa-handshake` (Nos partenaires), `fa-toolbox` (Nos ressources), `fa-newspaper` (Actualités), `fa-rocket` (bouton). Aucune prop : les rubriques sont fixes pour tout le mini-site (features 024 / 025 le réutilisent tel quel ; 025 pourra ajouter une prop `ctaVariant` si besoin). Utilitaire `.scrollbar-hide` ajouté **globalement** dans `app/assets/css/main.css` (aujourd'hui dupliqué en `<style scoped>` dans 7 fichiers, non touchés).

**Justification** : clarification Q5 ; `TabsNav` a ses onglets codés en dur et `FundraisingAnchorNav` est un scroll-spy par ancres (pas d'actif par route, pas de bouton).

**Alternatives écartées** : généraliser `TabsNav` (régression possible sur « Nous connaître ») ; étendre `AnchorNav` (mode actif par adresse à ajouter, régression Projets / Levées de fonds).

## R3 — Carte d'actualité partagée

**Décision** : extraire `app/components/actualites/NewsCard.vue` (`<ActualitesNewsCard>`) depuis la grille `latestNews` de `pages/actualites/index.vue` (l. 343-420), **markup identique** (image `h-48 object-cover` ou substitut `fa-newspaper`, titre `line-clamp-2`, badges d'association, résumé `line-clamp-2`, date). Props : `item: NewsDisplay`, `showAssociations?: boolean` (défaut `true`), `imageVariant?: 'low' | 'medium'` (défaut `'low'`). Helpers déplacés dans le composant (`getCoverImageUrl`, `localized`, `formatDate` avec `ar-EG` / `en-US` / `fr-FR`). La page Actualités remplace sa boucle par `<ActualitesNewsCard v-for … :item="item" />` et est comparée avant / après. L'accueil du pôle l'utilise avec `showAssociations=false` (le service DDE serait répété sur les trois cartes).

**Écart assumé avec la maquette** : la maquette dessine une ligne « Catégorie · date » au-dessus du titre et un visuel 16/10 ; la carte du site place la date en bas et le visuel en hauteur fixe. La consigne « cartes existantes de `/actualites` » et la clarification Q4 priment (cohérence du site).

**Alternatives écartées** : recopier le gabarit (doublon divergent) ; `CampusNews.vue` (mise en page éditoriale à la une, pas une grille).

## R4 — Événements de la DDE (filtre public par service)

**Décision** : ajouter au backend `service_id: str | None = Query(None)` et `order: Literal["asc", "desc"] = Query("desc")` sur `GET /api/public/events` (`routers/public/events.py`), propagés à `ContentService.get_events(service_id=…, order=…)` (`services/content_service.py` l. 328-366) : `where(Event.service_external_id == service_id)` après le bloc `campus_id`, `order_by(Event.start_date.asc() if order == "asc" else Event.start_date.desc())`. Défauts inchangés → comportement existant préservé (tri desc). Côté front, `usePublicEventsApi.listPublishedEvents` accepte `service_id?` et `order?` (mêmes lignes `if (params.x) query.x = …`). La page « Nos activités » appelle `listPublishedEvents({ service_id: dde, upcoming: true, order: 'asc', limit: 6 })`. Aucune modification de schéma : la colonne `events.service_external_id` existe (`models/content.py` l. 107). `EventPublic` n'a pas besoin d'exposer `service_external_id` (filtrage serveur).

**Justification** : sans `order=asc`, `upcoming + limit` renverrait les six événements les plus lointains. Nombre maximal affiché : **6** (point laissé ouvert par la clarification, tranché ici ; suffisant pour un bloc, la rubrique Actualités de 024 listera le reste).

**Alternatives écartées** : filtrer côté client (`getAllPublishedEvents` jusqu'à 100 puis filtre — `EventPublic` n'expose pas le service) ; inverser le tri quand `upcoming=true` (changerait le comportement de `/actualites`).

## R5 — Clés éditoriales du hero « Nos activités » (migration 047)

**Décision** : quatre clés `entrepreneurship.activities.hero.badge` (« Nos activités »), `.title` (« Un parcours, de l'idée à l'entreprise »), `.subtitle` (sous-titre du cahier des charges, même texte que `entrepreneurship.activities.subtitle`), `.image` (vide, id média), `value_type = 'text'`, catégorie `values`, insérées par `047_pei_activities_hero_keys.sql` (`ON CONFLICT (key) DO NOTHING`, même forme que 045 § 7) avec `047_pei_activities_hero_keys_rollback.sql` (`DELETE … WHERE key IN (…)`). Ajout dans `editorial-pages-config.ts` (section `entrepreneurship-activities`, `editorialKeys` + `fields` avec `type: 'image'` pour l'image) et dans l'union `ValueSectionKey` (`types/api/editorial.ts`). `99_data_init.sql` ne seed pas les clés éditoriales (seulement les permissions) : rien à y ajouter. Le SQL est soumis à accord avant le code (spec FR-029) — voir [data-model.md](data-model.md) § 3.

**Alternatives écartées** : réutiliser `entrepreneurship.activities.{badge,title,subtitle}` (clarification Q2 : clés dédiées) ; libellés i18n figés.

## R6 — Lecture des clés éditoriales (pas de clé brute, FR dans les trois langues)

**Décision** : les pages lisent la copie via `getRawContent(key)` (valeur base ou `null`) et non `getContent(key)` (dont le repli `t(key)` renverrait la clé brute faute d'entrée dans `EDITORIAL_TO_I18N_MAP`). Chaque bloc est conditionné (`v-if`) à la présence de sa valeur principale. `getHtmlContent('entrepreneurship.presentation.content')` pour le riche. Chargement SSR : `await useAsyncData('editorial-entrepreneurship', () => loadContent())` (pattern `organisation/index.vue`). Images : `getMediaUrl(getRawContent(key), 'medium')` (UUID validé, `null` sinon). Liste des chips : `getRawContent('entrepreneurship.activities.ecosystem.items')?.split('\n').map(trim).filter(Boolean)`. Conformément à la clarification Q1, la valeur FR s'affiche quelle que soit la langue.

## R7 — Panneau de chiffres clés

**Décision** : composant `app/components/entrepreneurship/StatsPanel.vue` (`<EntrepreneurshipStatsPanel>`), props `title: string`, `stats: { value: string, label: string }[]` (les entrées sans valeur sont filtrées par la page ; panneau masqué si 0). Rendu = maquette : conteneur `rounded-3xl p-10 bg-gradient-to-br from-brand-blue-900 via-brand-blue-800 to-brand-blue-700 overflow-hidden`, grille `grid-cols-2 gap-4`, tuile `rounded-2xl bg-white/10 border border-white/10 backdrop-blur-sm p-6 text-center`, nombre `text-4xl font-bold text-white tabular-nums`, libellé `text-sm text-white/70`. Animation de compteur reprise de `SectionStats` (IntersectionObserver seuil 0,3, easeOutQuart 1 500 ms, décalage 150 ms) **uniquement si** la valeur est de la forme `^\d+([^\d]*)$` ; sinon affichée telle quelle (« 3 ans », « ∞ ») ; désactivée sous `prefers-reduced-motion`.

**Justification** : `SectionStats` est une bande pleine largeur à fond parallax avec grille 4 colonnes et perd tout préfixe non numérique ; la maquette montre un panneau encastré 2 × 2. Le « style » est repris, pas le composant.

## R8 — Composable public `usePublicEntrepreneurshipApi`

**Décision** : `app/composables/usePublicEntrepreneurshipApi.ts` sur le modèle de `usePublicOrganizationApi` (`useApiBase()` + `$fetch`, préfixe `/api/public/entrepreneurship`) exposant les sept lectures existantes, typées avec `types/api/entrepreneurship.ts` : `listPrograms()`, `getProgram(code)`, `listCohorts(type?)`, `getCohort(code)`, `listLaureates(type?)`, `listPartners()`, `listResources(type?, category?)`. Cette feature n'utilise que `listPrograms` et `listPartners` ; les autres sont livrées pour 024 (coût nul, contrats déjà figés).

## R9 — Chargement SSR tolérant aux pannes

**Décision** : un `useAsyncData` par source avec `try/catch` renvoyant la valeur vide (`[]` / `null`) : `pei-home-programs`, `pei-home-partners`, `pei-home-news`, `pei-home-dde`, `pei-activities-events`… Aucune promesse rejetée ne remonte à la page (spec FR-023) ; chaque section est `v-if` sur sa donnée. Ordre : éditorial d'abord (pour obtenir `dde_service_id`), puis en parallèle programmes, partenaires, service DDE ; les actualités / événements dépendent de l'id DDE (second `useAsyncData` conditionnel). Clés `useAsyncData` suffixées par la locale pour les contenus localisés ? Non : les réponses contiennent les trois langues, la localisation se fait au rendu (`useLocalizedField`).

## R10 — Service DDE, fil d'Ariane et liens

**Décision** : `ddeServiceId = getRawContent('entrepreneurship.dde_service_id')` ; si UUID valide → `usePublicOrganizationApi().getServiceById(id)` (route `/api/public/services/{id}`) pour obtenir `name` → lien `/a-propos/organisation/service/${slugify(name)}` (`slugify` exporté par `usePublicOrganizationApi.ts`). Fil d'Ariane : `[{ nav.home, '/' }, { nav.about, '/a-propos' }, { about.tabs.organization, '/a-propos/organisation' }, { service.sigle ?? t('pei.breadcrumb.dde'), lien si résolu }, { pei.breadcrumb.pole }]` (le champ public s'appelle `sigle`) ; « Nos activités » ajoute un niveau (`pei.nav.activities`) et rend le pôle cliquable vers `/entrepreneuriat`. Le lien « Historique, vision et missions du pôle » (clé `entrepreneurship.presentation.link`) pointe vers la même fiche DDE ; masqué si non résolue. Actualités : `getAllPublishedNews({ service_id, limit: 3 })` (tri backend par date de publication desc).

## R11 — SEO et données structurées

**Décision** : `useSeoMeta` déclaré **après** `useRoute()` / `useAsyncData` (gotcha TDZ), pattern `organisation/index.vue` (`localeMap`, `ogUrl: siteUrl + route.fullPath`, `ogLocale`, `ogLocaleAlternate`) ; `title` = `hero.title` éditorial (accueil) / `activities.hero.title` (activités) avec repli `t('pei.seo.*')`, `description` = sous-titre ; `ogImage` = première image du slider en URL absolue (`siteUrl + url`) sinon l'image OG par défaut globale (héritée de `app.vue`). JSON-LD via `useHead({ script: [...] })` : `Organization` (`@id: ${siteUrl}/entrepreneuriat#organization`, `name` = titre éditorial, `parentOrganization: { '@id': ${siteUrl}/#organization }`, `email`, `url`), `WebPage` (`isPartOf: { '@id': ${siteUrl}/#website }`, `about`), `BreadcrumbList` construit depuis le même tableau que le fil d'Ariane (positions 1..n, `item` absolus). Le sitemap est automatique (`autoI18n: true`, découverte des fichiers de `app/pages/`) : vérification seulement. Pas de `htmlAttrs.dir` par page (`app.vue` le gère).

## R12 — i18n : namespace `pei`

**Décision** : nouveau fichier `i18n/locales/{fr,en,ar}/entrepreneurship.json` de racine **`pei`** (pas `entrepreneurship`), enregistré dans les trois `index.ts` (`import entrepreneurship from './entrepreneurship.json'` + spread). Clés : `pei.nav.{presentation,activities,alumni,partners,resources,news,cta}`, `pei.breadcrumb.{dde,pole}`, `pei.phases.{awareness,status,pre_incubation,incubation,funding,ecosystem}`, `pei.families.{academic,support,international}`, `pei.home.{allNews,seeActivities,ourNews,ourPartners}`, `pei.activities.{anchors,upcomingEvents,eventOn,online}`, `pei.seo.{homeTitle,homeDescription,activitiesTitle,activitiesDescription}`, `pei.contact.email`.

**Justification** : `getContent()` replie sur `t(key)` avec la clé éditoriale (`entrepreneurship.*`) ; un namespace i18n homonyme créerait des collisions silencieuses.

## R13 — Phases, couleurs et ancres

**Décision** : `app/utils/pei-presentation.ts` (auto-import Nuxt) exportant `PEI_PHASE_ORDER = ['awareness','status','pre_incubation','incubation','funding','ecosystem']`, `PEI_PHASE_ANCHORS` (`phase-awareness`…), `PEI_COLOR_CLASSES: Record<PeiColor, { border, numBg, numText, label }>` en Tailwind clair / sombre (bleu `border-brand-blue-500` / `bg-brand-blue-100 text-brand-blue-700` ; bleu foncé `border-brand-blue-700` / `bg-brand-blue-100 text-brand-blue-800` ; rouge `border-brand-red-500` / `bg-brand-red-100 text-brand-red-700` ; ambre `border-amber-500` / `bg-amber-100 text-amber-800` ; turquoise `border-teal-600` / `bg-teal-100 text-teal-800` ; variantes `dark:`). Les couleurs seedées en 021 (OSER turquoise, SEE bleu foncé, MTI bleu, Senghor'Innov rouge, FSE ambre) diffèrent de la maquette (ambre, bleu, rouge, bleu foncé, turquoise) : le rendu suit la base ; l'équipe peut réaligner dans le backoffice, aucune migration de données. Sur l'accueil, les cartes suivent `display_order` et sont numérotées par index ; sur « Nos activités », les blocs suivent `PEI_PHASE_ORDER` et les dispositifs d'une phase `display_order`. Le bloc `ecosystem` s'affiche si chips ou événements existent.

**Alternative écartée** : importer `colorOptions` de `useEntrepreneurshipApi.ts` (module admin ; ses classes sont des badges, pas des bordures de carte).

## R14 — Performance et images

**Décision** : slider `medium` (1 200 px) via `getMediaUrl(id, 'medium')`, première slide `fetchpriority="high"` + `decoding="async"`, suivantes `loading="lazy"` ; visuels des dispositifs `low` (480 px) sur l'accueil, `medium` sur « Nos activités » ; logos partenaires `loading="lazy"` avec `alt` = nom ; `width`/`height` ou `aspect-ratio` fixés pour éviter le CLS. Aucun script tiers. Objectif Lighthouse mobile ≥ 90 (SC-003) mesuré en build de production (`pnpm build` + `node .output/server/index.mjs`).

## R15 — Tests

**Décision** : backend `pytest` — `tests/integration/test_public_events_service_filter.py` (filtre `service_id`, `order=asc`, défauts inchangés) ; rejeu de la migration 047 (quickstart § 1). Frontend : aucune infrastructure de test (0 fichier, pas de script `test`) → validation manuelle par [quickstart.md](quickstart.md) + `pnpm lint` + `pnpm build` + Lighthouse ; captures avant / après des 19 usages de `PageHero` et de `/actualites` (SC-005).

## R16 — RTL et mode sombre

**Décision** : nouveaux composants écrits avec propriétés logiques Tailwind (`ms-`, `me-`, `ps-`, `pe-`, `start-`, `end-`, `text-start`) et `dark:` systématiques ; le chevron du fil d'Ariane et les flèches (`fa-arrow-right`) reçoivent `rtl:rotate-180`. Vérification à `/ar/entrepreneuriat` (dir RTL global).

## R17 — Page « Nos activités » : navigation par ancres

**Décision** : sous la sous-navigation du pôle, une barre secondaire non collante (pilules comme les sous-onglets de `TabsNav`) listant les phases présentes ; défilement `scrollIntoView({ block: 'start' })` avec `scroll-margin-top` (≈ 8 rem : en-tête 5 rem + sous-nav 3 rem) sur chaque `<section :id>` pour respecter l'ancre directe (`/entrepreneuriat/activites#phase-incubation`). Pas de scroll-spy (hors besoin, `FundraisingAnchorNav` non réutilisé).

## Points laissés ouverts par la clarification, tranchés ici

| Point | Décision |
|---|---|
| Nombre maximal d'événements à venir | 6 (R4) |
| Image de partage | première image du slider si renseignée, sinon OG par défaut du site (R11) |
| Écart carte d'actualité vs maquette | carte du site inchangée (R3) |
| Couleurs seedées ≠ maquette | rendu piloté par la base, réalignement en backoffice si souhaité (R13) |
