# Contrat — Frontend public (023)

Conventions : composants auto-importés par chemin (`components/entrepreneurship/SubNav.vue` → `<EntrepreneurshipSubNav>`), pages minces, libellés fixes via i18n `pei.*`, copie via `useEditorialContent('entrepreneurship')` (`getRawContent`), données via composables publics, repli FR `useLocalizedField().localized()`, propriétés logiques Tailwind (RTL) et classes `dark:`.

## Routes publiques

| Route | Fichier | Contenu |
|---|---|---|
| `/entrepreneuriat` (`/en/…`, `/ar/…`) | `app/pages/entrepreneuriat/index.vue` | hero slider, sous-nav, présentation + chiffres, parcours, citation / impact, actualités, partenaires, CTA |
| `/entrepreneuriat/activites` | `app/pages/entrepreneuriat/activites.vue` | hero image / motif, sous-nav, ancres, un bloc par phase, événements à venir |

Sitemap : découverte automatique (`autoI18n`), aucune entrée manuelle. Pas de `definePageMeta` (layout par défaut = `AppNavBar` + `AppFooter`).

## `PageHero` (`components/page/Hero.vue`) — extension

```ts
interface Props {
  title: string
  subtitle?: string
  image?: string          // inchangé, prioritaire sur images
  breadcrumb?: BreadcrumbItem[]
  images?: string[]       // NOUVEAU — ≥ 2 adresses = slider ; 1 = image simple ; [] / absent = motif (si pas d'image)
  badge?: string          // NOUVEAU — pilule au-dessus du h1 (style badge-red-dark de la maquette : bg-brand-red-500/20 text-brand-red-300 border-brand-red-400/30, uppercase tracking-wider text-xs font-semibold)
  badgeIcon?: string      // NOUVEAU — icône Font Awesome facultative dans la pilule
  actions?: { label: string; to: string; variant?: 'red' | 'ghost'; icon?: string }[]
                          // NOUVEAU — boutons rendus après le sous-titre, uniquement si fournis ;
                          // rouge = bg-brand-red-500 hover:bg-brand-red-600 ; fantôme = border-white/30 bg-white/15 ;
                          // `to` commençant par # → <a href> (défilement doux), sinon NuxtLink localePath
}
```

Comportement du slider (uniquement si `!image && images.length >= 2`) : première image SSR (`fetchpriority="high"`), autres `loading="lazy"` ; `<TransitionGroup name="slide">` (fondu 1 s) ; intervalle 6 000 ms démarré `onMounted`, arrêté `onUnmounted` ; **pas d'intervalle ni de transition** si `matchMedia('(prefers-reduced-motion: reduce)')` ; pause sur `mouseenter` / `focusin` / `document.hidden`, reprise sur `mouseleave` / `focusout` / visible ; points `role="tablist"` + `button[role=tab][type=button][aria-selected][aria-label]`, clavier ← → Home End ; `aria-live="polite"` (`sr-only`) « Visuel n sur N » ; libellés d'accessibilité sous `hero.slider.{slides,slide,current}` dans `i18n/locales/*/hero.json` (composant transverse) ; `@error` sur une image retire la slide (repli image simple, puis motif). Points en `absolute bottom-8 inset-x-0 flex justify-center gap-3`, actif `w-12 bg-brand-blue-500`, inactif `w-3 bg-white/40`.

Zéro régression : DOM identique pour tout usage sans `images` / `badge` / `actions` ; attributs orphelins retirés dans `pages/a-propos/partenaires/index.vue` (`:badge`, `badge-icon`) et `pages/a-propos/organisation/[type]/[slug].vue` (`<template #badge>`).

## `EntrepreneurshipSubNav` (`components/entrepreneurship/SubNav.vue`) — nouveau

Aucune prop. Racine `sticky top-20 z-40` ; onglets (i18n `pei.nav.*`, icônes FA) : Présentation `/entrepreneuriat` (exact), Nos activités `/entrepreneuriat/activites`, Nos alumni `/entrepreneuriat/alumni`, Nos partenaires `/entrepreneuriat/partenaires`, Nos ressources `/entrepreneuriat/ressources`, Actualités `/entrepreneuriat/actualites` ; bouton `pei.nav.cta` → `/entrepreneuriat/statut-etudiant-entrepreneur` (`bg-brand-red-500 hover:bg-brand-red-600 text-white rounded-full px-4 py-2 text-sm font-semibold`, `ms-auto`, `shrink-0`). Actif par route (`isActive` de `TabsNav`). Mobile : `overflow-x-auto scrollbar-hide` (utilitaire ajouté à `main.css`), `whitespace-nowrap`, `aria-label` sur la `<nav>`.

## Composants du pôle (`components/entrepreneurship/`, hors `admin/`)

| Composant | Props | Rendu (valeurs maquette) |
|---|---|---|
| `StatsPanel.vue` | `title: string`, `stats: { value: string; label: string }[]` | panneau `rounded-3xl p-10 bg-gradient-to-br from-brand-blue-900 via-brand-blue-800 to-brand-blue-700`, eyebrow `text-xs uppercase tracking-widest text-white/60`, grille `grid-cols-2 gap-4`, tuile `rounded-2xl bg-white/10 border border-white/10 p-6 text-center`, valeur `text-4xl font-bold tabular-nums text-white`, libellé `text-sm text-white/70` ; compteur animé (IntersectionObserver) si valeur numérique, désactivé sous reduced-motion |
| `ProgramCard.vue` | `program: PeiProgramPublic`, `index: number`, `to?: string` | carte du parcours : `rounded-xl border-2 border-gray-200 dark:border-gray-700 border-t-4 {color.border} bg-white dark:bg-gray-800 p-6 flex flex-col gap-3` ; ligne haute = pastille `w-10 h-10 rounded-xl font-bold {color.numBg color.numText}` (index) + libellé de phase `text-xs font-semibold uppercase tracking-wider {color.label}` (`pei.phases.*`) ; titre `text-[17px] font-bold` (+ sigle entre parenthèses si présent et absent du titre) ; accroche `text-sm text-gray-600 dark:text-gray-300` ; chiffre mis en avant `text-sm font-semibold {color.label}` ; tout le bloc est un `NuxtLink` vers `to` si fourni (ancre de phase sur « Nos activités ») |
| `ProgramSection.vue` | `phase: PeiProgramPhase`, `programs: PeiProgramPublic[]`, `index: number` | bloc de « Nos activités » : `<section :id="PEI_PHASE_ANCHORS[phase]" class="scroll-mt-32">`, en-tête (pastille numéro + libellé de phase), puis par dispositif : visuel `cover_image_url` (`medium`, `aspect-[16/10] rounded-2xl object-cover`, masqué si nul) à côté du texte (grille 5/7 desktop, colonne mobile), titre `h3`, sigle, accroche, chiffre mis en avant, `<RichTextRenderer :html="localized(program, 'content_html')" />` |
| `EcosystemChips.vue` | `title: string`, `items: string[]` | titre `text-xs uppercase tracking-widest text-gray-500 text-center`, chips `rounded-full border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 px-4 py-2 text-sm` avec icône `fa-solid fa-bolt` (`text-brand-blue-700`) |
| `QuoteBlock.vue` | `quote: string`, `author?: string`, `role?: string`, `authorImage?: string \| null`, `impactText?: string`, `impactImage?: string \| null` | section `bg-gradient-to-br from-brand-blue-900 via-brand-blue-800 to-brand-blue-950 py-24`, grille `lg:grid-cols-12` (7 / 5), guillemet `fa-solid fa-quote-left text-brand-red-500`, citation `text-2xl font-semibold text-white leading-snug`, auteur (avatar `w-12 h-12 rounded-full` ou initiale), rôle `text-white/70 text-sm`, texte d'impact `text-white/80`, visuel `rounded-2xl aspect-[4/3] object-cover` (masqué si nul) |
| `PartnerFamilies.vue` | `families: PeiPartnerFamilyPublic[]` | grille `md:grid-cols-3 gap-6`, carte par famille non vide `rounded-xl border-2 border-gray-200 dark:border-gray-700 p-6`, badge famille (`pei.families.*` ; academic `bg-brand-blue-100 text-brand-blue-700`, support `bg-brand-red-100 text-brand-red-700`, international `bg-teal-100 text-teal-800`, + `dark:`), logos `h-[72px] rounded-xl border border-gray-200 bg-white flex items-center justify-center p-3` (`<img loading="lazy" :alt="name" class="max-h-12 object-contain">` ou nom en `text-sm font-bold`), enveloppés d'un `<a target="_blank" rel="noopener">` si `website` |
| `EventList.vue` | `events: EventPublic[]` | liste `divide-y` : date (`toLocaleDateString` locale, `fa-regular fa-calendar`), titre `NuxtLink` vers `/actualites/evenements/{slug}`, lieu (`venue`, `city`) ou `pei.activities.online` |
| `CtaBanner.vue` | `title: string`, `description?: string`, `buttonLabel: string`, `to: string`, `email?: string` | bandeau `rounded-3xl bg-brand-blue-50 dark:bg-brand-blue-900/30 p-12 text-center`, bouton `bg-brand-blue-500 text-white rounded-full px-8 py-4 font-semibold` + `fa-arrow-right rtl:rotate-180`, lien `mailto:` avec `fa-regular fa-envelope` |

Avant création, chaque composant a été confronté à l'inventaire (`research.md` R1–R7) : aucun équivalent public existant (les seuls voisins sont admin ou spécifiques à une autre page).

## `ActualitesNewsCard` (`components/actualites/NewsCard.vue`) — extraction

Props `item: NewsDisplay`, `showAssociations = true`, `imageVariant = 'low'`. Markup identique à la grille `latestNews` de `pages/actualites/index.vue` (image `h-48 object-cover` / substitut, titre, badges d'association, résumé, date) ; helpers `getCoverImageUrl`, `localized`, `formatDate` internes. La page Actualités consomme le composant ; capture avant / après identique.

## Composable `usePublicEntrepreneurshipApi` (`composables/usePublicEntrepreneurshipApi.ts`) — nouveau

```ts
const BASE = '/api/public/entrepreneurship'
listPrograms(): Promise<PeiProgramPublic[]>
getProgram(code: string): Promise<PeiProgramPublic>
listCohorts(type?: PeiCohortType): Promise<PeiCohortPublic[]>
getCohort(code: string): Promise<PeiCohortPublic>
listLaureates(type?: PeiLaureateType): Promise<PeiLaureatesPublic>
listPartners(): Promise<PeiPartnerFamilyPublic[]>
listResources(params?: { type?: PeiResourceType; category?: string }): Promise<PeiResourcePublic[]>
```
`useApiBase()` + `$fetch`, aucun en-tête d'authentification ; erreurs propagées (les pages les absorbent).

## Modifications de composables existants

- `usePublicEventsApi.listPublishedEvents(params)` : `+ service_id?: string`, `+ order?: 'asc' | 'desc'`.
- `useEditorialContent` : inchangé (utilisation de `getRawContent`, `getHtmlContent`, `loadContent`).

## `utils/pei-presentation.ts` — nouveau

`PEI_PHASE_ORDER`, `PEI_PHASE_ANCHORS` (`phase-awareness`, `phase-status`, `phase-pre-incubation`, `phase-incubation`, `phase-funding`, `phase-ecosystem`), `PEI_FAMILY_ORDER`, `PEI_COLOR_CLASSES` (voir research R13), `isNumericStat(value)`.

## Chargement des pages (SSR)

`index.vue` :
1. `await useAsyncData('editorial-entrepreneurship', loadContent)`.
2. En parallèle (`useAsyncData` séparés, `try/catch` → vide) : `pei-home-programs` (`listPrograms`), `pei-home-partners` (`listPartners`), `pei-home-dde` (`getServiceById(ddeId)` si UUID valide).
3. `pei-home-news` (`getAllPublishedNews({ service_id, limit: 3 })`) si `ddeId`.
4. `useSeoMeta` + `useHead` (JSON-LD) **après** `useRoute()` et les `useAsyncData`.

`activites.vue` : idem avec `pei-activities-programs`, `pei-activities-dde`, `pei-activities-events` (`listPublishedEvents({ service_id, upcoming: true, order: 'asc', limit: 6 })`).

## SEO (par page)

`useSeoMeta({ title, description, ogTitle, ogDescription, ogUrl: siteUrl + route.fullPath, ogImage, ogLocale, ogLocaleAlternate })` ; `ogImage` = `siteUrl + images[0]` si slider, sinon hérité. `useHead({ script: [ { type: 'application/ld+json', key: 'jsonld-pei-organization', innerHTML }, { key: 'jsonld-pei-webpage' }, { key: 'jsonld-pei-breadcrumb' } ] })` :

- `Organization` : `@id ${siteUrl}/entrepreneuriat#organization`, `name` (hero.title), `url`, `email` (contact.email), `parentOrganization { @id ${siteUrl}/#organization }`, `logo` hérité.
- `WebPage` : `@id ${siteUrl}${path}#webpage`, `name`, `description`, `inLanguage` (fr / en / ar), `isPartOf { @id ${siteUrl}/#website }`, `about { @id …#organization }`.
- `BreadcrumbList` : `itemListElement[{ position, name, item }]` depuis le tableau du fil d'Ariane (URL absolues localisées ; dernier élément sans `item`).

## i18n — `i18n/locales/{fr,en,ar}/entrepreneurship.json` (racine `pei`)

```json
{ "pei": {
  "nav": { "presentation": "Présentation", "activities": "Nos activités", "alumni": "Nos alumni", "partners": "Nos partenaires", "resources": "Nos ressources", "news": "Actualités", "cta": "Devenir étudiant-entrepreneur", "label": "Rubriques du pôle" },
  "breadcrumb": { "dde": "DDE", "pole": "Pôle Entrepreneuriat et Innovation" },
  "phases": { "awareness": "Sensibilisation", "status": "Cadre", "pre_incubation": "Pré-incubation", "incubation": "Incubation", "funding": "Amorçage", "ecosystem": "Animation de l'écosystème" },
  "families": { "academic": "Académiques et institutionnels", "support": "Organisations d'appui", "international": "Organisations internationales" },
  "home": { "ourNews": "La vie du pôle", "allNews": "Toutes les actualités du PEI", "ourPartners": "Un écosystème d'appui", "partnersBadge": "Nos partenaires", "newsBadge": "Actualités" },
  "activities": { "anchorsLabel": "Aller à une phase", "upcomingEvents": "Prochains événements", "online": "En ligne", "eventLink": "Voir l'événement" },
  "seo": { "homeTitle": "Entreprendre à Senghor", "homeDescription": "…", "activitiesTitle": "Nos activités", "activitiesDescription": "…" }
} }
```
Enregistré dans `i18n/locales/{fr,en,ar}/index.ts` (`import entrepreneurship from './entrepreneurship.json'` + spread). Traductions EN / AR fournies dans la même livraison. Les libellés d'accessibilité du slider vont dans `hero.json` (`hero.slider.*`), pas ici.

## Fichiers touchés hors PEI

| Fichier | Changement |
|---|---|
| `components/page/Hero.vue` | 4 props (`images`, `badge`, `badgeIcon`, `actions`) + slider + badge |
| `pages/a-propos/partenaires/index.vue`, `pages/a-propos/organisation/[type]/[slug].vue` | retrait des attributs / slot orphelins |
| `pages/actualites/index.vue` | boucle → `<ActualitesNewsCard>` |
| `composables/usePublicEventsApi.ts` | 2 paramètres |
| `composables/editorial-pages-config.ts`, `types/api/editorial.ts` | 4 clés |
| `assets/css/main.css` | `.scrollbar-hide` |
| `i18n/locales/*/index.ts`, `i18n/locales/*/hero.json` | enregistrement du JSON ; clés `hero.slider.*` |
| `CLAUDE.md` | routes publiques, composable, hero, sous-nav, carte d'actualité, migration 047 |

## Écarts d'implémentation (2026-09-13)

| Élément | Contrat initial | Implémenté | Raison |
|---|---|---|---|
| `PageHero` hauteur en mode `images` | non précisée | `min-h-[560px] lg:min-h-[640px] flex flex-col justify-center pt-16 pb-28` (mode `image` et motif inchangés) | badge + titre + sous-titre + 2 boutons débordaient de `max-h-[500px]` |
| Points du slider | `bottom-8` | `bottom-16 md:bottom-20` | `bottom-8` tombait sur le séparateur oblique blanc (points invisibles) |
| Région `aria-live` | annonce du visuel courant | mise à jour uniquement sur action du visiteur | éviter une annonce toutes les 6 s |
| Boutons d'ancre du hero, barre d'ancres, ancre directe | `<a href>` + `scroll-behavior: smooth` | `scrollToPageAnchor(hash, { lenis })` (`utils/pei-presentation.ts`) : Lenis avec décalage = `scroll-margin-top` de la cible ; ancre directe repositionnée 900 ms après montage | Lenis intercepte le défilement natif et `app.vue` ne décale que de l'en-tête (80 px), la section passait sous la sous-navigation |
| Repli sans slide (accueil) | `:image` | `:images="['/images/bg/backgroud_senghor2.jpg']"` | conserver la hauteur du mode `images` |
| Hero de « Nos activités » | `:image` | `:images="heroImage ? [heroImage] : []"` | idem, avec retrait de l'image en erreur |
| `ProgramSection` | 3 props | + `standalone?: boolean` (défaut `true`) | dispositifs de phase `ecosystem` intégrés au bloc écosystème sans doublon d'ancre ni de titre |
| Contenu de présentation | `getHtmlContent` | `getRawContent` | `getHtmlContent` replie sur `t(clé)` (clé brute) |
| `utils/pei-presentation.ts` | 5 exports | + `isUuid`, `scrollToPageAnchor` | validation de `dde_service_id`, ancres |
| `tailwind.config.ts` | — | `content` + `./app/utils/**/*.ts` | classes de `PEI_COLOR_CLASSES` sinon purgées |
| Composable JSON-LD | `buildPeiOrganization`, `buildWebPage`, `buildBreadcrumbList` | conforme (`usePeiJsonLd()`) | — |
