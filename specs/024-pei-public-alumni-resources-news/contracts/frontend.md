# Contrat — Frontend public (024)

Conventions (023) : composants auto-importés par chemin (`components/entrepreneurship/PillTabs.vue` → `<EntrepreneurshipPillTabs>`), pages minces, libellés fixes i18n `pei.*`, copie via `useEditorialContent('entrepreneurship')` (`getRawContent`), données via composables publics, repli FR `useLocalizedField().localized()`, propriétés logiques Tailwind (RTL), classes `dark:`. Aucune modification de `pages/entrepreneuriat/{index,activites}.vue`, de `SubNav.vue`, de `PageHero`, de `/actualites`, de `/mediatheque`, de `/a-propos/partenaires`.

## Routes publiques (nouvelles)

| Route (`/en/…`, `/ar/…`) | Fichier | Contenu |
|---|---|---|
| `/entrepreneuriat/alumni[?type=student_entrepreneur]` | `app/pages/entrepreneuriat/alumni.vue` | hero, sous-nav, sous-onglets pilule, bandeau de chiffres, titre de section, sections par cohorte, encart mentor |
| `/entrepreneuriat/partenaires` | `app/pages/entrepreneuriat/partenaires.vue` | hero, sous-nav, familles détaillées |
| `/entrepreneuriat/ressources` | `app/pages/entrepreneuriat/ressources.vue` | hero, sous-nav, bloc Médiathèque, bloc Boîte à outils |
| `/entrepreneuriat/actualites` | `app/pages/entrepreneuriat/actualites.vue` | hero, sous-nav, bloc Actualités (lots de 12), bloc Événements (à venir / passés, lots de 10) |

Sitemap : découverte automatique (`autoI18n`). Pas de `definePageMeta` (layout par défaut).

## Composable `usePeiPage` (`app/composables/usePeiPage.ts`) — nouveau

```ts
interface PeiPageOptions {
  heroPrefix: 'alumni' | 'partners' | 'resources' | 'news'   // clés entrepreneurship.<prefix>.hero.*
  navKey: 'alumni' | 'partners' | 'resources' | 'news'        // pei.nav.<key> (fil d'Ariane) + pei.seo.<key>Title/Description
}
interface PeiPage {
  text: (key: string) => string                 // getRawContent('entrepreneurship.' + key) trim, '' si vide
  ddeServiceId: ComputedRef<string | null>      // isUuid(text('dde_service_id'))
  ddeService: Ref<ServicePublicWithDetails | null>   // useAsyncData('pei-<prefix>-dde')
  hero: ComputedRef<{ badge?: string; title: string; subtitle?: string; images: string[] }>
  breadcrumb: ComputedRef<PeiBreadcrumbItem[]>  // 6 niveaux, dernier = t('pei.nav.<navKey>')
  applySeo: () => void                          // useSeoMeta + useHead(JSON-LD Organization, CollectionPage, BreadcrumbList) — à appeler après les useAsyncData de la page
}
export function usePeiPage(options: PeiPageOptions): Promise<PeiPage>   // await : charge l'éditorial (useAsyncData('editorial-entrepreneurship')) et le service DDE
```

Contrainte : la page appelle `await usePeiPage(...)` en tête (comme `loadContent` en 023), lance ses `useAsyncData` de données, puis `applySeo()` en dernier (gotcha TDZ unhead : `useSeoMeta` après `useRoute()` et les `useAsyncData`).

## Composants du pôle (`components/entrepreneurship/`, hors `admin/`)

| Composant | Statut | Props | Rendu |
|---|---|---|---|
| `PillTabs.vue` | **nouveau** | `tabs: { key; label; icon?; to: RouteLocationRaw }[]`, `activeKey: string`, `ariaLabel?: string` | barre `bg-white/30 dark:bg-gray-800/30 backdrop-blur-sm border-b`, `NuxtLink rounded-full px-4 py-2 text-sm font-medium`, actif `bg-brand-blue-100 dark:bg-brand-blue-900/30 text-brand-blue-700 dark:text-brand-blue-400` + `aria-current="page"`, `overflow-x-auto scrollbar-hide` |
| `StatsPanel.vue` | **étendu** | + `variant?: 'panel' \| 'band'` (défaut `'panel'`), `title` devient optionnel | `band` : pleine largeur dégradé bleu foncé, `grid sm:grid-cols-3 sm:divide-x divide-white/15 rtl:divide-x-reverse`, valeur `text-5xl`, libellé `uppercase tracking-[0.2em] text-white/70` ; compteur animé existant réutilisé ; rendu `panel` inchangé |
| `CohortSection.vue` | **nouveau** | `cohort: PeiCohortPublic`, `laureates: PeiLaureatePublic[]`, `anchorId?: string` | h3 `localized(cohort,'label')`, sous-titre `year · focus`, badge focus ambre, `RichTextRenderer` (`summary_html` localisé) si non vide, grille `sm:grid-cols-2 lg:grid-cols-4` de `LaureateCard` |
| `LaureateCard.vue` | **nouveau** | `laureate: PeiLaureatePublic` | photo 4:3 ou substitut, étoile « mis en avant » discrète, nom, badge cohorte, projet, département, verbatim italique, icônes de liens (site, LinkedIn, Instagram, Facebook, vidéo) `target="_blank" rel="noopener noreferrer"` + `aria-label` i18n |
| `CtaBanner.vue` | **étendu** | `to` devient optionnel ; + `href?: string` | `href` → `<a :href>` (mailto), sinon `NuxtLink` inchangé |
| `PartnerFamilies.vue` | **étendu** | + `variant?: 'logos' \| 'detailed'` (défaut `'logos'`) | `detailed` : une section par famille non vide (badge + h2), grille `md:grid-cols-2 lg:grid-cols-3` de cartes (logo / nom, nom, description localisée `line-clamp-4`, lien « Visiter le site ») ; rendu `logos` inchangé |
| `ResourceCard.vue` | **nouveau** | `resource: PeiResourcePublic` | icône par type, titre, description localisée, action : `document` → `<a :href="media_url + '?download=1'" download>` ; `link` → nouvel onglet ; `video` → nouvel onglet + vignette YouTube si `youTubeId(url)` |
| `EventList.vue` | **étendu** | + `title?: string` (défaut `t('pei.activities.upcomingEvents')`) | inchangé sinon |
| `EmptyState.vue` | **nouveau** (après vérification `components/**/*Empty*`) | `icon?: string`, `title: string`, `description?: string`, `to?: string`, `linkLabel?: string` | bloc centré `py-24`, icône grise, texte, lien vers `/entrepreneuriat` |

Réutilisés tels quels : `PageHero`, `EntrepreneurshipSubNav`, `RichTextRenderer`, `MediaLibraryTab` (+ `MediaAlbumCard`, `MediaAlbumModal`), `ActualitesNewsCard` (`show-associations="false"`, `image-variant="medium"`).

## Utilitaires (`app/utils/pei-presentation.ts`, ajouts)

```ts
export const PEI_LAUREATE_TAB_QUERY = 'type'
export function cohortTypeForLaureateType(type: PeiLaureateType): PeiCohortType          // fse_laureate → fse, student_entrepreneur → see
export function laureateTypeFromQuery(value: unknown): PeiLaureateType                   // 'student_entrepreneur' → lui-même, sinon 'fse_laureate'
export function sortLaureatesFeaturedFirst(list: PeiLaureatePublic[]): PeiLaureatePublic[]   // tri stable is_featured desc, display_order asc
export function groupResourcesByCategory(resources: PeiResourcePublic[], label: (r: PeiResourcePublic) => string, otherLabel: string): { key: string; label: string; items: PeiResourcePublic[] }[]
export function youTubeId(url: string | null | undefined): string | null                 // regex de ProjetMediatheque.vue
export function isHttpUrl(value: string | null | undefined): value is string             // /^https?:\/\//i
```

`usePeiJsonLd.buildWebPage(params: { path; name; description?; type?: 'WebPage' | 'CollectionPage' })` — défaut `'WebPage'` (023 inchangée).

## Configuration éditoriale et types

- `editorial-pages-config.ts` : 4 sections (`entrepreneurship-alumni`, `entrepreneurship-partners-page`, `entrepreneurship-resources`, `entrepreneurship-news`) — voir [editorial-keys.md](editorial-keys.md).
- `types/api/editorial.ts` : 26 littéraux `ValueSectionKey`.

## i18n (`i18n/locales/{fr,en,ar}/entrepreneurship.json`, namespace `pei`)

```jsonc
"common": { "viewMore": "Voir plus", "backHome": "Retour à l'accueil du pôle", "openInNewTab": "(nouvel onglet)" },
"alumni": {
  "tabsLabel": "Type de portraits", "tabs": { "fse": "Lauréats FSE", "see": "Étudiants entrepreneurs" },
  "featured": "Portrait mis en avant", "cohortYear": "Promotion {year}",
  "mentorSubject": "Devenir mentor du Pôle Entrepreneuriat et Innovation",
  "links": { "website": "Site web de {name}", "linkedin": "LinkedIn de {name}", "instagram": "Instagram de {name}", "facebook": "Facebook de {name}", "video": "Vidéo de {name}" },
  "empty": { "title": "Aucun portrait publié pour le moment", "description": "Les portraits de cette catégorie seront publiés prochainement." }
},
"partners": { "visit": "Visiter le site", "empty": { "title": "Aucun partenaire référencé pour le moment", "description": "…" } },
"resources": { "mediaTitle": "Médiathèque", "toolboxTitle": "Boîte à outils", "otherCategory": "Autres ressources",
               "download": "Télécharger", "open": "Ouvrir", "watch": "Voir la vidéo",
               "empty": { "title": "Aucune ressource disponible pour le moment", "description": "…" } },
"news": { "newsTitle": "Actualités", "eventsTitle": "Événements", "upcoming": "Événements à venir", "past": "Événements passés",
          "empty": { "title": "Aucune actualité pour le moment", "description": "…" } },
"seo": { "alumniTitle": "Nos alumni", "alumniDescription": "…", "partnersTitle": "Nos partenaires", "partnersDescription": "…",
         "resourcesTitle": "Nos ressources", "resourcesDescription": "…", "newsTitle": "Actualités du pôle", "newsDescription": "…" }
```

EN et AR : mêmes clés, traductions complètes (aucune valeur vide).

## SEO / données structurées (par page)

`useSeoMeta` : `title`, `description` (sous-titre du hero ou `pei.seo.<key>Description`), `ogTitle`, `ogDescription`, `ogUrl = siteUrl + route.fullPath`, `ogImage` (image du hero si renseignée), `ogLocale`, `ogLocaleAlternate`. `useHead` : trois scripts JSON-LD `Organization` (pôle), `CollectionPage`, `BreadcrumbList` (6 éléments, cohérents avec le fil affiché).

## Comportements clés

- **Alumni** : `laureateTypeFromQuery(route.query.type)` → onglet ; liens des onglets `{ path: route.path, query: {} }` (FSE) et `{ path: route.path, query: { type: 'student_entrepreneur' } }` (SEE) ; un seul `listLaureates()` ; sections = groupes du type courant ; état vide si 0 section ; bandeau si ≥ 1 chiffre ; encart mentor si titre + e-mail.
- **Partenaires** : `listPartners()` → `<EntrepreneurshipPartnerFamilies variant="detailed">` ; état vide si les trois familles sont vides.
- **Ressources** : albums (R8) → `<MediaLibraryTab>` sous `h2` `pei.resources.mediaTitle` ; `listResources()` → groupes → `<EntrepreneurshipResourceCard>` sous `h2` `pei.resources.toolboxTitle` ; état vide si les deux blocs sont vides.
- **Actualités** : lot 1 SSR ; « Voir plus » client ; événements à venir / passés ; état vide si tout est vide ou DDE non identifiée.
- Toutes : sources en erreur → valeur vide, jamais de message d'erreur ; aucun libellé codé en dur.
