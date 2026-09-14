# Research — Mini-site public PEI : alumni, partenaires, ressources, actualités (024)

Phase 0 du plan. Chaque point : décision, justification, alternatives écartées. Sources : inventaire par sous-agent du 2026-09-14 (`routers/public/entrepreneurship.py`, `schemas/entrepreneurship.py`, `services/entrepreneurship_service.py`, `routers/public/{services,news,events}.py`, `usePublicEntrepreneurshipApi`, `usePublicNewsApi`, `usePublicEventsApi`, `usePublicAlbumsApi`, `usePublicOrganizationApi`, `components/entrepreneurship/*`, `components/media/*`, `components/actualites/NewsCard.vue`, `components/section/about/TabsNav.vue`, `components/section/Stats.vue`, `components/projet/ProjetMediatheque.vue`, `pages/entrepreneuriat/{index,activites}.vue`, `pages/actualites/index.vue`, `pages/a-propos/organisation/[type]/[slug].vue`, `editorial-pages-config.ts`, `usePeiJsonLd.ts`, `utils/pei-presentation.ts`, migrations 045–047, `nuxt.config.ts`), spec 024, maquettes `alumni.{png,html}` et `accueil.{png,html}`.

## R1 — Structure commune des quatre pages

**Décision** : chaque page est un fichier `app/pages/entrepreneuriat/{alumni,partenaires,ressources,actualites}.vue` copié sur le squelette de `activites.vue` : `useEditorialContent('entrepreneurship')` chargé en premier (`useAsyncData('editorial-entrepreneurship')`), helper `text(key)` sans repli i18n, `ddeServiceId` validé par `isUuid`, sources indépendantes en `Promise.all` de `useAsyncData` avec `.catch(() => valeur vide)`, hero `PageHero` (`badge`, `title`, `subtitle`, `images` 0/1), `EntrepreneurshipSubNav`, fil d'Ariane à six niveaux, `useSeoMeta` **après** `useRoute()` et les `useAsyncData`, JSON-LD via `usePeiJsonLd`. Le code partagé du fil d'Ariane, du hero et du SEO est factorisé dans un **nouveau composable** `app/composables/usePeiPage.ts` (`usePeiPage({ heroPrefix, navKey, collection })`) utilisé par les quatre nouvelles pages seulement ; `index.vue` et `activites.vue` (023) ne sont pas modifiées (aucun risque de régression, refactor éventuel hors périmètre).

**Justification** : cohérence visuelle et fonctionnelle exigée (FR-001) ; quatre copies de 40 lignes de fil d'Ariane / SEO seraient une source de divergence.

**Alternatives écartées** : layout Nuxt dédié `entrepreneuriat` (le hero dépend des données de page, et le layout par défaut est imposé) ; refactorer les pages 023 vers le composable (hors périmètre, comparaison de captures supplémentaire).

## R2 — Sous-onglets alumni portés par l'adresse

**Décision** : nouveau composant `app/components/entrepreneurship/PillTabs.vue` (`<EntrepreneurshipPillTabs>`), props `tabs: { key: string; label: string; icon?: string; to: RouteLocationRaw }[]`, `activeKey: string` ; rendu = barre `bg-white/30 dark:bg-gray-800/30 backdrop-blur-sm border-b border-gray-200/50` avec `NuxtLink rounded-full px-4 py-2 text-sm font-medium` (actif `bg-brand-blue-100 dark:bg-brand-blue-900/30 text-brand-blue-700 dark:text-brand-blue-400`), classes copiées du niveau 2 de `SectionAboutTabsNav` (l. 120-140), `aria-current="page"` sur l'actif, `overflow-x-auto scrollbar-hide` à 390 px. La page alumni lit `route.query.type` (SSR) : `student_entrepreneur` → onglet SEE, toute autre valeur → onglet FSE ; les liens des onglets sont `{ path: route.path, query: { type } }` (sans `type` pour FSE = adresse canonique) ; la navigation par `NuxtLink` met à jour l'adresse et l'historique sans rechargement, `ogUrl` suit `route.fullPath`.

**Justification** : `SectionAboutTabsNav` n'a ni props ni gestion de paramètre d'adresse (onglets codés en dur) ; le style pilule est le seul élément à reprendre. Des liens réels (plutôt que des boutons + `router.replace`) donnent un HTML partageable et indexable dès le rendu serveur.

**Alternatives écartées** : généraliser `TabsNav` (régression « Nous connaître ») ; onglets en boutons avec état local (adresse non partageable, SSR impossible) ; deux routes `/alumni/laureats` et `/alumni/etudiants` (la description impose une query).

## R3 — Chargement des portraits et tri « mis en avant »

**Décision** : un seul appel `listLaureates()` **sans filtre `type`** en `useAsyncData('pei-alumni-laureates')` ; le filtrage par onglet se fait à l'affichage sur `group.cohort.type` (`fse` ↔ `fse_laureate`, `see` ↔ `student_entrepreneur`, cohérence garantie par la 022 Q1). Dans chaque groupe, tri stable `[...laureates].sort((a, b) => Number(b.is_featured) - Number(a.is_featured) || a.display_order - b.display_order)`. Fonctions pures `cohortTypeForLaureateType()` et `sortLaureatesFeaturedFirst()` ajoutées à `utils/pei-presentation.ts`. Sections = groupes du type courant ayant ≥ 1 portrait (l'API omet déjà les cohortes sans portrait publié).

**Justification** : volume faible (≤ 50 portraits), bascule d'onglet instantanée sans nouvel appel, une seule clé de cache SSR ; l'API ne trie pas les vedettes (vérifié `entrepreneurship_service.py` ~l. 1388).

**Alternatives écartées** : appel par onglet avec `watch` sur la query (deux allers-retours, clignotement) ; ajouter un tri serveur (changement d'API non nécessaire, spec FR-025).

## R4 — Bandeau de chiffres alumni

**Décision** : étendre `EntrepreneurshipStatsPanel` avec une prop `variant?: 'panel' | 'band'` (défaut `'panel'`, rendu actuel inchangé) et `title` rendu optionnel. Variante `band` : conteneur pleine largeur `bg-gradient-to-r from-brand-blue-900 via-brand-blue-800 to-brand-blue-900` (valeurs `#0e1840` / `#2b4bbf` de `alumni.html`), grille `grid-cols-1 sm:grid-cols-3` avec séparateurs `sm:divide-x divide-white/15` (`rtl:divide-x-reverse`), valeur `text-5xl font-bold text-white tabular-nums`, libellé `text-xs uppercase tracking-[0.2em] text-white/70`. Le compteur animé existant (`isNumericStat`, `prefers-reduced-motion`) est réutilisé tel quel. La page construit `stats` depuis `alumni.stats.{1,2,3}.{value,label}` (paires à valeur non vide) et masque le bandeau si vide.

**Justification** : la logique de compteur et l'accessibilité sont déjà écrites ; `SectionStats` impose une image de fond et des liens, `StatsPanel` un panneau 2 × 2 encastré. Une prop de variante évite un troisième composant de chiffres.

**Alternatives écartées** : nouveau composant `StatsBand` (duplication du compteur) ; `SectionStats` avec `backgroundImage` vide (mise en page différente de la maquette).

## R5 — Carte portrait et section de cohorte

**Décision** : deux nouveaux composants. `EntrepreneurshipLaureateCard.vue` (`laureate: PeiLaureatePublic`) : `article` `rounded-2xl border bg-white dark:bg-gray-800`, photo `aspect-[4/3] object-cover` (`photo_url`, `loading="lazy"`) ou substitut `bg-gray-100 dark:bg-gray-700` avec icône `fa-user`, nom `font-bold`, badge cohorte `rounded-full bg-brand-blue-100 text-brand-blue-700 text-[11px] font-semibold` (`cohort_label` localisé), projet `text-brand-blue-600 font-medium`, département `text-sm text-gray-500`, verbatim `italic text-sm border-s-2 border-brand-blue-200 ps-3` (`quote` localisé, affiché si non vide), rangée d'icônes 32 px (`fa-globe`, `fa-brands fa-linkedin-in`, `fa-brands fa-instagram`, `fa-brands fa-facebook-f`, `fa-solid fa-play`) uniquement pour les URL non vides et valides (`isHttpUrl()`), `target="_blank" rel="noopener noreferrer"`, `aria-label` i18n `pei.alumni.links.{website,linkedin,instagram,facebook,video}` + nom. Marqueur discret « mis en avant » : petite étoile `fa-star text-amber-500` dans le coin de la photo (`title` i18n). `EntrepreneurshipCohortSection.vue` (`cohort: PeiCohortPublic`, `laureates: PeiLaureatePublic[]`) : en-tête (h3 `label` localisé, sous-titre `year · focus`, badge focus `bg-amber-100 text-amber-800 uppercase text-xs`), `RichTextRenderer` sur `summary_html` localisé si non vide, grille `grid gap-6 sm:grid-cols-2 lg:grid-cols-4`.

**Justification** : aucun composant public de portrait n'existe (`pages/alumni/index.vue` est en markup inline sur données fictives ; `TestimonialModal` est admin) — inventaire § 9. Les icônes de marques `fa-brands` sont déjà utilisées dans le site (pied de page) : vérifier leur enregistrement dans le plugin Font Awesome avant usage, sinon les ajouter à la bibliothèque du plugin.

**Alternatives écartées** : réutiliser la carte alumni de `pages/alumni/index.vue` (données fictives, pas de composant) ; carte d'équipe `components/team/*` (champs différents, pas de verbatim ni de liens multiples).

## R6 — Encart « Devenir mentor »

**Décision** : étendre `EntrepreneurshipCtaBanner` : prop `to` rendue optionnelle, nouvelle prop `href?: string` ; si `href` est fourni, le bouton est un `<a :href>` (ici `mailto:` + `contact.email`), sinon `NuxtLink` comme aujourd'hui. Le lien e-mail secondaire (`email`) n'est pas répété sur la page alumni (le bouton est déjà le mailto). Sujet d'e-mail pré-rempli via i18n `pei.alumni.mentorSubject` (`?subject=` encodé).

**Justification** : réutilisation du bandeau de l'accueil (même style que la maquette : fond `brand-blue-50`, bouton bleu). Pas de composant nouveau.

**Alternatives écartées** : nouveau composant `MentorCta` ; formulaire de candidature mentor (hors périmètre, feature 025 ou ultérieure).

## R7 — Page partenaires : variante détaillée de `PartnerFamilies`

**Décision** : étendre `EntrepreneurshipPartnerFamilies` avec `variant?: 'logos' | 'detailed'` (défaut `'logos'`, DOM actuel inchangé). Variante `detailed` : une `section` par famille non vide (ordre `PEI_FAMILY_ORDER`), badge de famille existant (`badgeClasses`) + h2 i18n `pei.families.*`, grille `grid gap-6 md:grid-cols-2 lg:grid-cols-3` de cartes : logo `h-16 object-contain` sur fond blanc (ou nom en texte), nom `font-bold`, description localisée (`localized(partner, 'description')`, `line-clamp-4`, masquée si vide), lien « Visiter le site » (`fa-arrow-up-right-from-square`, i18n `pei.partners.visit`, `target="_blank" rel="noopener noreferrer"`) si `website`. Aucun réseau social (022 Q2). Aucune page de détail.

**Justification** : spec FR-015 (étendre, ne pas dupliquer) ; `CardPartner` et `components/partners/*` sont liés aux données fictives ou à l'API partenaires générale (sans familles) — inventaire § 5.

**Alternatives écartées** : nouveau composant `PartnerDetailCard` (doublon des badges et de l'ordre des familles) ; `UnifiedPartnersSection` (grille par type de partenaire, pas par famille du pôle).

## R8 — Médiathèque de la DDE

**Décision** : dans la page ressources, `useAsyncData('pei-resources-albums')` : `getServiceById(dde)` → `album_ids` (repli `album_external_id` comme la fiche service) → `Promise.all(ids.map(getAlbumById))` → filtre `a !== null && a.media_items.length > 0` → `<MediaLibraryTab :albums>` (cartes `MediaAlbumCard` + `MediaAlbumModal` : grille, vue unique, filtre par type, `<video>` natif, `?download=1`). `AlbumWithMedia` est structurellement compatible avec `PublicAlbumWithMedia` (mêmes champs `id`, `title`, `description`, `display_order`, `media_items: MediaRead[]`). Bloc masqué si `ddeServiceId` nul, service en erreur ou 0 album.

**Justification** : aucun endpoint `…/media-library` pour les services (les albums sont dans la fiche `GET /api/public/services/{id}`) ; `MediaLibraryTab` est le composant réutilisé par les pages actualité et événement — inventaire § 3. Chargement en `useAsyncData` (et non `onMounted` comme la fiche service) pour le rendu serveur (SC-002).

**Alternatives écartées** : nouvel endpoint `GET /api/public/services/{id}/media-library` (changement d'API inutile) ; grille inline de la fiche service (markup non réutilisable).

## R9 — Boîte à outils : regroupement, téléchargement, vidéos

**Décision** : `listResources()` sans filtre, puis regroupement à l'affichage par `groupResourcesByCategory(resources)` (nouvelle fonction pure dans `utils/pei-presentation.ts`) : clé = `category` FR normalisée (`trim().toLocaleLowerCase('fr')`, espaces multiples réduits), ordre des groupes = ordre de première apparition (ressources déjà triées `display_order`), intitulé = `localized(première ressource, 'category')`, groupe sans catégorie en dernier (intitulé i18n `pei.resources.otherCategory`). Nouveau composant `EntrepreneurshipResourceCard.vue` (`resource: PeiResourcePublic`) dans le style des cartes de `accueil.html` (`rounded-2xl border p-6`, icône colorée par type : `fa-file-arrow-down` bleu / `fa-link` teal / `fa-circle-play` rouge) : titre, description localisée, action selon `type` — `document` : `<a :href="media_url + '?download=1'" download>` « Télécharger » (paramètre reconnu par le backend, même construction que `MediaAlbumModal` l. 207-211), carte masquée si `media_url` nul ; `link` : `<a :href="url" target="_blank" rel="noopener noreferrer">` « Ouvrir » ; `video` : même lien externe « Voir la vidéo » + vignette `https://img.youtube.com/vi/{id}/hqdefault.jpg` si `youTubeId(url)` (regex de `ProjetMediatheque.vue` l. 44-47 recopiée dans `pei-presentation.ts` sous `youTubeId()`), sinon icône. Aucun `<iframe>` tiers.

**Justification** : `category` est un texte libre trilingue sans endpoint public de liste (inventaire § 1) ; le site n'a aucun lecteur intégré pour les fournisseurs externes et traite YouTube par vignette + lien (§ 3, § 9) ; la spec impose l'adresse publique de téléchargement.

**Alternatives écartées** : filtre `category=` par appel (n appels, catégorie FR exacte requise) ; `<iframe>` YouTube (pas de gestion du consentement sur le site, écart avec la pratique existante) ; appeler `/api/admin/entrepreneurship/resources/categories` (interdit en public).

## R10 — Page actualités : lots et événements

**Décision** : actualités via `listPublishedNews({ service_id: dde, page: 1, limit: 12 })` en `useAsyncData` (SSR, premier lot), état `items` + `page` + `pages` (réponse paginée `{ items, total, page, limit, pages }`) ; bouton « Voir plus » (i18n `pei.common.viewMore`) appelle la page suivante côté client et concatène ; masqué quand `page >= pages`. Cartes `<ActualitesNewsCard :item :show-associations="false" image-variant="medium">` en grille `sm:grid-cols-2 lg:grid-cols-3` (même carte que `/actualites`, spec FR-021). Événements : deux `useAsyncData` — à venir `listPublishedEvents({ service_id, upcoming: true, order: 'asc', page: 1, limit: 10 })` (API : `start_date ≥ now`), passés `listPublishedEvents({ service_id, to_date: new Date().toISOString(), order: 'desc', page: 1, limit: 10 })` (API : `start_date ≤ to_date`, même construction que `getPastEvents()` du composable) — chacun avec son « Voir plus », **sans filtre client** : les deux filtres serveur sont complémentaires sur `start_date`, chaque événement apparaît dans exactement une liste et chaque lot est plein. Un événement déjà commencé (même non terminé) est donc classé « Passés », comme sur la page Événements du site. `EntrepreneurshipEventList` reçoit une nouvelle prop `title?: string` (défaut = libellé actuel « Prochains événements ») pour afficher « Événements passés ». Bloc « Événements » masqué si les deux listes sont vides ; état vide de page si actualités **et** événements vides.

**Justification** : le filtre serveur `service_id` existe sur les deux lectures (news : jointure `news_services`), la pagination serveur évite de charger 100 actualités comme `/actualites` ; la carte extraite en 023 garantit l'identité visuelle (Q4 de la 023). Vérifié dans `routers/public/events.py` et `services/content_service.py` (l. 358-362) : `upcoming` pose `from_date = now`, `to_date` filtre `start_date <= to_date`.

**Alternatives écartées** : `getAllPublishedNews` + tranche locale (modèle `/actualites`, 100 éléments max, inutile pour un SSR paginé) ; onglets « Actualités / Événements » (la maquette de l'accueil ne les sépare pas ; deux blocs suffisent) ; paramètre `?page=` dans l'adresse (non exigé, complexifie le SSR) ; passés = `upcoming=false` + filtre client `isPast()` (**rejeté après analyse** : sans `to_date`, l'API renvoie aussi les futurs, en tête du tri desc — avec plus de dix événements à venir, la première page ne contient aucun passé et la liste reste vide).

## R11 — État vide de page

**Décision** : nouveau composant `EntrepreneurshipEmptyState.vue` (`icon?: string`, `title: string`, `description?: string`, `to?: string`, `linkLabel?: string`) : bloc centré `py-24`, icône `fa-*` en `text-gray-300 dark:text-gray-600`, texte i18n `pei.{alumni,partners,resources,news}.empty*`, lien vers `/entrepreneuriat` (`pei.common.backHome`). Avant de le créer, vérifier `components/**/*Empty*` (aucun trouvé lors de l'inventaire ciblé ; la vérification par sous-agent reste une tâche). Les blocs partiels restent masqués (`v-if`), conformément à la 023 (FR-005).

**Alternatives écartées** : réutiliser l'état vide inline de `/actualites` (markup non extrait) ; message d'erreur générique (spec : « état vide propre », jamais d'erreur).

## R12 — Libellés i18n

**Décision** : compléter `i18n/locales/{fr,en,ar}/entrepreneurship.json` (namespace `pei`) : `pei.common.{viewMore,backHome,openInNewTab}`, `pei.alumni.{tabs.fse,tabs.see,tabsLabel,featured,mentorSubject,empty.title,empty.description,links.website,links.linkedin,links.instagram,links.facebook,links.video,cohortYear}`, `pei.partners.{visit,empty.title,empty.description}`, `pei.resources.{mediaTitle,toolboxTitle,otherCategory,download,open,watch,empty.title,empty.description}`, `pei.news.{newsTitle,eventsTitle,upcoming,past,empty.title,empty.description}`, `pei.seo.{alumniTitle,alumniDescription,partnersTitle,partnersDescription,resourcesTitle,resourcesDescription,newsTitle,newsDescription}`. Les intitulés de familles (`pei.families.*`) et de navigation (`pei.nav.*`) existent déjà. Arabe : traductions rédigées avec la même terminologie que les fichiers existants (خريجونا, مواردنا).

## R13 — SEO et données structurées

**Décision** : `useSeoMeta` (title, description, OG, `ogUrl = siteUrl + route.fullPath`, `ogImage` = image du hero si renseignée, locales) après la route, dans `usePeiPage` appelé depuis la page **après** les `useAsyncData`. `usePeiJsonLd.buildWebPage` reçoit un paramètre optionnel `type?: 'WebPage' | 'CollectionPage'` (défaut `'WebPage'`, 023 inchangée) ; les quatre pages passent `'CollectionPage'`. `buildBreadcrumbList` réutilisé. Sitemap : découverte automatique des pages statiques avec `autoI18n` (vérifié dans `nuxt.config.ts`) ; simple vérification des 12 entrées dans `/sitemap.xml`. Pour alumni, le `fullPath` inclut `?type=` ; l'adresse canonique reste sans query (pas de balise canonical explicite ajoutée, cohérent avec le site).

## R14 — Migration 048 (26 clés) et configuration éditoriale

**Décision** : `048_pei_public_pages_keys.sql` + `048_pei_public_pages_keys_rollback.sql`, même forme que 047 (`INSERT … SELECT … FROM (VALUES …) ON CONFLICT (key) DO NOTHING`, catégorie `values`, `value_type = 'text'`). Côté frontend : quatre nouvelles sections dans `entrepreneurshipPageSections` (`entrepreneurship-alumni`, `entrepreneurship-partners-page`, `entrepreneurship-resources`, `entrepreneurship-news`) avec `fields` (`text` / `textarea` / `image`), et 26 entrées dans l'union `ValueSectionKey` (`types/api/editorial.ts`, à côté des clés 047 l. 612-615). Le SQL est soumis à accord (spec FR-024) — voir [data-model.md](data-model.md) § 3. Compte attendu après migration : 47 + 26 = **73** clés déclarées côté config ; en base, 48 + 26 = 74 lignes `entrepreneurship.%` (la base compte une clé de plus que la config depuis 045, écart préexistant documenté par la 047).

## R15 — Tests et validation

**Décision** : aucun changement backend → aucun test pytest nouveau ; les tests existants `tests/integration/test_public_entrepreneurship_api.py` et `test_public_events_service_filter.py` servent de non-régression (à lancer). Frontend : pas d'infrastructure de test (mémoire projet : pas de `pnpm lint`) → validation manuelle par [quickstart.md](quickstart.md), `pnpm build` (heap 8 Go), `curl` des pages SSR, Lighthouse mobile, captures avant / après (`/actualites`, `/a-propos/partenaires`, `/entrepreneuriat`, 1440 px et 390 px).

## R16 — RTL, sombre, 390 px

**Décision** : propriétés logiques Tailwind (`ps-`, `ms-`, `rtl:divide-x-reverse`, `rtl:rotate-180` sur les flèches), classes `dark:` systématiques ; grilles `grid-cols-1` par défaut avec `sm:` / `lg:` ; sous-onglets et bandeau en `overflow-x-auto` / `grid-cols-1` à 390 px ; images de portraits `loading="lazy"` sauf le premier rang (`fetchpriority` non nécessaire) ; `line-clamp` sur descriptions de partenaires et de ressources.

Aucun `NEEDS CLARIFICATION` restant.
