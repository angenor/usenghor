# Contrat — Frontend public (025)

Conventions 023 / 024 : composants auto-importés par chemin, pages minces, libellés fixes `pei.*`, copie éditoriale via `usePeiPage().text`, repli FR `useLocalizedField().localized()`, propriétés logiques Tailwind (RTL), classes `dark:`, `useSeoMeta` après la route et les `useAsyncData`.

## Route (nouvelle)

| Route (`/en/…`, `/ar/…`) | Fichier |
|---|---|
| `/entrepreneuriat/statut-etudiant-entrepreneur` | `app/pages/entrepreneuriat/statut-etudiant-entrepreneur.vue` |

Ordre du gabarit : `PageHero` → `EntrepreneurshipSubNav` → section Intro (`bg` quadrillé, grille `lg:grid-cols-12` 7/5) → section Leviers (`bg-gray-50 dark:bg-gray-900`, `sm:grid-cols-2 lg:grid-cols-3`) → section Candidature (`id="candidater"`, grille 7/5 ; aside `lg:sticky lg:top-40 lg:self-start`) → section FAQ (`id="faq"`, `max-w-4xl`, titre centré) + ligne PÉPITE → CTA final (`max-w-4xl`). Aucune `definePageMeta`. Sections : `scroll-mt-40`.

Squelette de script :

```ts
const page = await usePeiPage({ heroPrefix: 'see', navKey: 'see' })
const { data: call } = await useAsyncData('pei-see-call', () => { const s = page.text('see.call_slug'); return s ? usePublicCallsApi().getCallBySlug(s).catch(() => null) : Promise.resolve(null) })
const { data: faqTree } = await useAsyncData('pei-see-faq', () => usePublicFaqApi().getTree({ categoryPrefix: 'see-' }).catch(() => ({ categories: [] })))
// computed : state, year, target, agendaSteps, conditions, documents, jury, levers, faqCategories (entrées > 0)
page.applySeo({ type: 'WebPage' })
useHead(() => ({ script: faqJsonLd.value ? [{ key: 'jsonld-pei-faq', type: 'application/ld+json', innerHTML: JSON.stringify(faqJsonLd.value) }] : [] }))
```

## Composables et utilitaires

| Élément | Changement |
|---|---|
| `usePeiPage.ts` | `PeiRubric` + `'see'` ; `applySeo(options?: { type?: 'WebPage' \| 'CollectionPage' })`, défaut `'CollectionPage'` (024 inchangées) |
| `usePublicFaqApi.ts` | `getTree(options?: { categoryPrefix?: string })` — `?category_prefix=` seulement si fourni |
| `utils/pei-presentation.ts` | + `seeCallState`, `seeApplyTarget`, `seeCallYear`, `seeAgendaSteps`, `seeSlots`, `seeLeverIcon` ([data-model § 2](../data-model.md)) |
| `utils/faq-jsonld.ts` (nouveau) | `faqQuestionFor(entry, lang)`, `faqAnswerHtmlFor(entry, lang)`, `buildFaqPageJsonLd(categories, lang)` — extraits à l'identique de `pages/faq.vue` |
| `pages/faq.vue` | utilise `utils/faq-jsonld.ts` ; JSON-LD identique (diff) |

Vérifier par sous-agent, avant création, qu'aucun export homonyme n'existe dans `utils/` ou `composables/` (gotcha collisions d'auto-import).

## Composants

| Composant | Statut | Props / changement | Rendu par défaut |
|---|---|---|---|
| `entrepreneurship/SubNav.vue` | étendu | aucun ; bouton rouge : `aria-current="page"` + `ring-4 ring-brand-red-100 dark:ring-brand-red-900/40` si route SEE | inchangé ailleurs |
| `entrepreneurship/SeeAgenda.vue` | **nouveau** | `state: SeeCallState`, `year: number \| null`, `steps: AgendaStep[]`, `openingDate: string \| null`, `target: SeeApplyTarget \| null`, `buttonLabel`, `ccNote?`, `closedTitle?`, `closedText?` | carte blanche `rounded-2xl p-8 border shadow` ; en-tête « `pei.see.agendaTitle` » + badge (`open` rouge, `upcoming` ambre, `closed`/`absent` gris) ; frise `ol` (pastille cerclée `brand-blue-500`, trait `brand-blue-100`, pastille `brand-red-500` si `isDeadline`, `<time datetime>`) ; bouton pleine largeur (fusée ; `NuxtLink` interne, `<a target=_blank rel="noopener noreferrer">` externe, `<a href=mailto>` contact) ; note centrée 13 px |
| `faq/FaqAccordion.vue` | étendu | `searchable = true`, `groupTitles: 'auto' \| 'always' = 'auto'`, `headingLevel: 'h2' \| 'h3' = 'h2'`, `multiple = false` ; ancre → `scrollToPageAnchor(hash, { lenis })` | `/faq` : identique (sauf défilement d'ancre fiable sous Lenis) |
| `faq/FaqAccordionItem.vue` | réutilisé | — | — |
| `entrepreneurship/CtaBanner.vue` | étendu | `external?: boolean` (`target`/`rel` sur `href`), slot `note` sous les boutons | identique sans prop ni slot |
| `PageHero` | réutilisé | `v-bind="page.hero"` + `:badge="badgeWithYear"` + `badge-icon="fa-solid fa-rocket"` | — |
| Cartes intro, parcours, leviers, conditions, jury, dossier | gabarit de page | — | valeurs de la maquette HTML (encadré `bg-gradient-to-br from-brand-blue-900 to-brand-blue-800`, cartes SEE bordure `brand-blue-200` / `brand-red-200`, icône levier carré 48 px `bg-brand-blue-100 text-brand-blue-600`, coches `teal-600`, pastilles numérotées `brand-blue-100`, carte dossier `bg-brand-blue-50 border-brand-blue-100`) |

Justification des créations : [research.md R6, R8](../research.md) ; un seul composant nouveau (`SeeAgenda`).

## i18n (`i18n/locales/{fr,en,ar}/entrepreneurship.json`)

| Clé | FR |
|---|---|
| `pei.nav.see` | Entreprendre et étudier |
| `pei.seo.seeTitle` | Entreprendre et étudier à Senghor |
| `pei.seo.seeDescription` | Le Statut Étudiant-Entrepreneur de l'Université Senghor : parcours SEE 1 et SEE 2, avantages, conditions, calendrier de l'appel et questions fréquentes. |
| `pei.see.heroBadgeYear` | {badge} · Appel {year} |
| `pei.see.agendaTitle` / `agendaTitleYear` | Agenda / Agenda {year} |
| `pei.see.state.{open,upcoming,closed}` | Appel ouvert / Appel à venir / Appel clos |
| `pei.see.deadline` | Date limite de soumission |
| `pei.see.opensOn` | Ouverture des candidatures le {date} |
| `pei.see.contactButton` | Écrire au pôle |
| `pei.see.contactSubject` | Statut Étudiant-Entrepreneur |
| `pei.see.wished` | souhaité |
| `pei.see.optional` | facultatif |
| `pei.see.agendaLabel` | Calendrier de l'appel à candidatures |

EN et AR traduits (pas de clé brute, pas de FR résiduel). Dates : `Intl.DateTimeFormat(locale, { day: 'numeric', month: 'long', year: 'numeric', timeZone: 'Africa/Cairo' })`, heure ajoutée pour la ligne synthétique de date limite.

## SEO

- `useSeoMeta` (via `applySeo`) : titre / description = hero, OG complet, `ogLocaleAlternate`.
- JSON-LD : `Organization` (pôle), `WebPage`, `BreadcrumbList` (6 niveaux, dernier `pei.nav.see`), `FAQPage` si ≥ 1 entrée.
- Sitemap : découverte automatique, trois langues.
