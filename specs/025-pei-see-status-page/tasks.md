---

description: "Tâches d'implémentation — page « Entreprendre et étudier à Senghor » (Statut Étudiant-Entrepreneur, 025)"
---

# Tasks: Page « Entreprendre et étudier à Senghor » — Statut Étudiant-Entrepreneur

**Input**: Design documents from `/specs/025-pei-see-status-page/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md)

**Tests**: Tests pytest ajoutés pour les deux changements backend (filtre FAQ public, étape `faq_see` de « Traduire les champs manquants »), conformément à research R17. Frontend sans infrastructure de test : validation par les blocs du quickstart.

**Organization**: US1 guide + appel ouvert (P1), US2 FAQ (P1), US3 états de l'appel hors ouverture (P2), US4 édition du guide (P2), US5 langues / RTL / mobile / sombre / SEO (P3). Chaque story est testable seule après les phases 1–2.

## Format: `[ID] [P?] [Story] Description`

- **[P]** : parallélisable (fichiers différents, aucune dépendance sur une tâche inachevée)
- **[Story]** : US1…US5 (phases de user story uniquement)

## Path Conventions

- Frontend : `usenghor_nuxt/app/{pages,components,composables,utils,types}`, `usenghor_nuxt/i18n/locales/{fr,en,ar}/entrepreneurship.json`
- Backend : `usenghor_backend/app/{routers,services,schemas}`, `usenghor_backend/tests/integration/`
- Migrations : `usenghor_backend/documentation/modele_de_données/migrations/`
- Auto-import par chemin : `components/entrepreneurship/SeeAgenda.vue` → `<EntrepreneurshipSeeAgenda>`
- Conventions transverses : français accentué ; noms de fichiers `[a-z0-9_-]` ; classes `dark:` et propriétés logiques (`ms-`, `ps-`, `start-`, `rtl:`) ; aucun texte visible en dur (clés `entrepreneurship.see.*` via `page.text()` ou i18n `pei.*`) ; aucun appel `/api/admin/*` depuis la page publique ; `useSeoMeta` après les `useAsyncData`

---

## Phase 1: Setup (porte d'accord, inventaire, références)

**Purpose**: Accord sur le SQL, vérification de réutilisation et captures de référence avant tout code.

- [X] T001 Présenter au responsable le SQL de `specs/025-pei-see-status-page/data-model.md` § 4 (65 clés `entrepreneurship.see.*`, 4 catégories `see-general` / `see-avantages` / `see-engagement` / `see-confidentialite` avec `display_order` 10–13, 8 entrées dont `see-statut-payant` et `see-amenagements-academiques` publiées, rollback) et les 5 points à confirmer (URL PÉPITE France, texte `see.closed.*`, libellés EN/AR des catégories, ordre sur `/faq`, portée du rollback) ; **attendre l'accord explicite** avant T016–T017 ; reporter les textes retouchés dans `data-model.md` § 4 et `contracts/editorial-keys.md`
- [X] T002 [P] Vérifier par sous-agent dans `usenghor_nuxt/app/{components,composables,utils}/**` : (a) aucun composant de panneau d'appel à états / agenda collant réutilisable (inventaire du 2026-09-14 : aucun ; `calls/ScheduleSection.vue` et `calls/CTASection.vue` exclus, research R5–R6) ; (b) aucun export existant nommé `seeCallState`, `seeApplyTarget`, `seeCallYear`, `seeAgendaSteps`, `seeSlots`, `seeLeverIcon`, `faqQuestionFor`, `faqAnswerHtmlFor`, `buildFaqPageJsonLd` (gotcha collisions d'auto-import) ; consigner le résultat dans `specs/025-pei-see-status-page/research.md` (fin de R6) et renommer si collision
- [X] T003 [P] Capturer les références avant changement (dev local, `git stash` si nécessaire) : captures 1440 px et 390 px de `/faq`, `/actualites/appels/<slug d'un appel existant>`, `/entrepreneuriat/alumni` ; JSON-LD de `/faq` : `curl -s http://localhost:3000/faq | grep -o '<script type="application/ld+json"[^>]*>[^<]*FAQPage[^<]*</script>' > <scratchpad>/faq-jsonld-avant.txt` ; réponse `curl -s localhost:8000/api/public/faq | jq -S . > <scratchpad>/faq-api-avant.json`

---

## Phase 2: Foundational (prérequis bloquants)

**Purpose**: Utilitaires, cadre de page, i18n, sous-navigation et migration partagés par toutes les stories.

**⚠️ CRITICAL**: T004–T012 avant la page (T018) ; T016–T017 dès l'accord T001 (la page tolère des clés absentes : blocs masqués, titre de repli).

- [X] T004 [P] Ajouter à `usenghor_nuxt/app/utils/pei-presentation.ts` (section « Page SEE (feature 025) », types importés depuis `~/types/api` : `ApplicationCallPublicWithDetails`, `CallScheduleRead`) : `export type SeeCallState = 'open' | 'upcoming' | 'closed' | 'absent'` ; `seeCallState(call, now = new Date())` — `null`/`undefined` → `'absent'` ; `status === 'ongoing'` et (`!deadline` ou `new Date(deadline) > now`) → `'open'` ; `status === 'upcoming'` → `'upcoming'` ; sinon `'closed'` ; `export type SeeApplyTarget = { kind: 'external', href: string } | { kind: 'internal', to: string } | { kind: 'contact', href: string }` ; `seeApplyTarget(call, state, email, subject)` — `state === 'open' && isHttpUrl(call.external_form_url)` → external ; `state === 'open' && call.use_internal_form` → internal `to = '/candidatures/postuler/' + call.slug` (non localisé, la vue localise) ; sinon si `email.trim()` → contact `href = 'mailto:' + email + '?subject=' + encodeURIComponent(subject)` ; sinon `null` ; `seeCallYear(call)` — année de `opening_date`, sinon de `deadline`, sinon `null` ; `export interface AgendaStep { id: string, label: string, description: string, start: string | null, end: string | null, isDeadline: boolean, synthetic: boolean }` ; `seeAgendaSteps(schedule, deadline, localize: (step, field) => string, deadlineLabel: string, timeZone = 'Africa/Cairo')` — tri par `display_order`, `isDeadline` sur la **première** étape dont le jour calendaire (`Intl.DateTimeFormat('en-CA', { timeZone })`) de `end_date ?? start_date` égale celui de `deadline` ; si aucune et `deadline` non nulle, insérer `{ id: 'deadline', label: deadlineLabel, start: deadline, end: null, isDeadline: true, synthetic: true }` avant la première étape dont `start_date` est postérieure, sinon en fin ; `seeSlots(text: (k) => string, prefix: string, count: number): string[]` — valeurs non vides de `see.<prefix>.<1..count>` dans l'ordre ; `seeLeverIcon(value)` — valeur `trim` commençant par `fa-` sinon `'fa-solid fa-circle-check'`
- [X] T005 [P] Étendre `usenghor_nuxt/app/composables/usePeiPage.ts` : `type PeiRubric = 'alumni' | 'partners' | 'resources' | 'news' | 'see'` ; `applySeo(options: { type?: 'WebPage' | 'CollectionPage' } = {})` passant `type: options.type ?? 'CollectionPage'` à `buildWebPage` (les quatre pages 024 inchangées) ; mettre à jour le commentaire d'en-tête (spec 025)
- [X] T006 [P] Compléter `usenghor_nuxt/i18n/locales/fr/entrepreneurship.json` selon `contracts/frontend.md` § i18n : `pei.nav.see` « Entreprendre et étudier », `pei.seo.seeTitle`, `pei.seo.seeDescription` (≤ 160 caractères), bloc `pei.see` : `heroBadgeYear` « {badge} · Appel {year} », `agendaTitle` « Agenda », `agendaTitleYear` « Agenda {year} », `agendaLabel`, `state.{open,upcoming,closed}`, `deadline`, `opensOn` « Ouverture des candidatures le {date} », `contactButton` « Écrire au pôle », `contactSubject` « Statut Étudiant-Entrepreneur », `wished` « souhaité », `optional` « facultatif »
- [X] T007 [P] Ajouter les mêmes clés en anglais dans `usenghor_nuxt/i18n/locales/en/entrepreneurship.json` (aucune valeur vide ; « Study and start a business », « {badge} · {year} call », « Call open / Upcoming call / Call closed », « Submission deadline », « Applications open on {date} », « Email the hub »)
- [X] T008 [P] Ajouter les mêmes clés en arabe dans `usenghor_nuxt/i18n/locales/ar/entrepreneurship.json` (aucune valeur vide, terminologie existante de `pei.nav.*`)
- [X] T009 [P] Étendre `usenghor_nuxt/app/components/entrepreneurship/SubNav.vue` : `const ctaPath = '/entrepreneuriat/statut-etudiant-entrepreneur'`, `const ctaActive = computed(() => isActive(ctaPath))` ; sur le `NuxtLink` rouge : `:aria-current="ctaActive ? 'page' : undefined"` et classe conditionnelle `ring-4 ring-brand-red-100 dark:ring-brand-red-900/40` si actif ; libellé `pei.nav.cta` et rendu inchangés sur les autres rubriques (vérifier qu'aucun onglet n'est actif sur la route SEE)
- [X] T010 [P] Étendre `usenghor_nuxt/app/components/entrepreneurship/CtaBanner.vue` : prop `external?: boolean` → sur le bouton `<a :href>` : `:target="external ? '_blank' : undefined"` et `:rel="external ? 'noopener noreferrer' : undefined"` ; slot optionnel `note` rendu sous la rangée de boutons dans `<p class="mt-4 text-sm text-gray-500 dark:text-gray-400">` seulement si le slot est fourni ; rendu strictement identique sans prop ni slot (accueil, alumni)
- [X] T011 [P] Ajouter `category_prefix` à la lecture publique FAQ : `usenghor_backend/app/services/faq_service.py` `get_public_tree(self, category_prefix: str | None = None)` ajoutant `.where(FaqCategory.code.startswith(category_prefix, autoescape=True))` si fourni (requête inchangée sinon) ; `usenghor_backend/app/routers/public/faq.py` : paramètre `category_prefix: str | None = Query(None, pattern=r"^[a-z0-9_-]{1,60}$", description="Préfixe de code de catégorie (ex. see-)")` transmis au service, `Cache-Control` inchangé ; docstring mise à jour
- [X] T012 [P] Étendre `usenghor_nuxt/app/composables/usePublicFaqApi.ts` : `getTree(options: { categoryPrefix?: string } = {})` → `$fetch(url, { query: options.categoryPrefix ? { category_prefix: options.categoryPrefix } : undefined })` (URL identique sans option, `/faq` inchangée)
- [X] T013 [P] Ajouter à `usenghor_backend/tests/integration/test_public_faq_api.py` (modèle des tests existants, sans traducteur) : catégories `see-a` (active, 1 entrée publiée + 1 non publiée), `see-b` (inactive), `seex` (active), `general` ; `GET /api/public/faq?category_prefix=see-` → codes `['see-a']`, 1 entrée ; `category_prefix=see_` ne renvoie pas `seex` (échappement) ; sans paramètre → `see-a`, `seex`, `general` présents (non-régression) ; `category_prefix=SEE%25` → 422
- [X] T014 Exécuter `cd usenghor_backend && source .venv/bin/activate && pytest tests/integration/test_public_faq_api.py -v` ; tous les nouveaux cas passent ; noter tout échec préexistant lié au quota du traducteur (gotcha connu) sans le masquer
- [X] T015 [P] Vérifier la réponse FAQ sans filtre : `curl -s localhost:8000/api/public/faq | jq -S . | diff - <scratchpad>/faq-api-avant.json` → aucune différence (avant migration 049)
- [X] T016 Créer `usenghor_backend/documentation/modele_de_données/migrations/049_pei_see_page.sql` **après l'accord T001**, en recopiant le SQL validé de `data-model.md` § 4 (en-tête, `BEGIN` ; 65 clés `ON CONFLICT (key) DO NOTHING` catégorie `values` ; 4 catégories `ON CONFLICT (code) DO NOTHING` ; 8 entrées `ON CONFLICT (slug) DO NOTHING`, `published_at = NOW()` pour les 2 publiées, réponse provisoire « Réponse à rédiger par le Pôle Entrepreneuriat et Innovation. » pour les 6 brouillons, EN/AR `NULL` ; `COMMIT` ; `\echo`), apostrophes doublées
- [X] T017 [P] Créer `usenghor_backend/documentation/modele_de_données/migrations/049_pei_see_page_rollback.sql` selon `data-model.md` § 4 (suppression des 8 slugs ; catégories `see-*` seedées sans entrée restante ; clés `entrepreneurship.see.%` hors `call_slug` et `mentor.{title,description,button}`), puis jouer quickstart § 1 en local : migration ×2 → `138|4|8|2`, rollback → `73|0|0|0`, rejeu → `138|4|8|2`

**Checkpoint**: cadre, utilitaires, i18n, filtre FAQ et données initiales prêts.

---

## Phase 3: User Story 1 — Comprendre le statut et postuler à l'appel ouvert (Priority: P1) 🎯 MVP

**Goal**: Page complète (hors FAQ) avec guide éditorial, conditions / critères / dossier et panneau agenda collant en état ouvert, boutons vers le formulaire.

**Independent Test**: quickstart § 3 lignes 1–2 et § 6–7 : appel `training` publié, en cours, 6 étapes, critères et pièces ; page 200 ; sections dans l'ordre ; agenda collant ; bouton interne puis externe ; date modifiée visible au rechargement.

- [X] T018 [P] [US1] Créer `usenghor_nuxt/app/components/entrepreneurship/SeeAgenda.vue` selon `contracts/frontend.md` : props `state: SeeCallState`, `year: number | null`, `steps: AgendaStep[]`, `openingDate: string | null`, `target: SeeApplyTarget | null`, `buttonLabel: string`, `ccNote?: string`, `closedTitle?: string`, `closedText?: string` ; `<aside :aria-label="t('pei.see.agendaLabel')" class="rounded-2xl border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 p-6 sm:p-8 shadow-lg">` ; en-tête flex : `<h3 class="text-2xl font-bold text-gray-900 dark:text-white">` (`agendaTitleYear` si `year`, sinon `agendaTitle`) + badge `rounded-full px-3 py-1 text-xs font-semibold uppercase` (`open` → `bg-brand-red-100 text-brand-red-700 dark:bg-brand-red-900/30 dark:text-brand-red-300`, `upcoming` → `bg-amber-100 text-amber-800 dark:bg-amber-900/30 dark:text-amber-300`, `closed`/`absent` → `bg-gray-100 text-gray-700 dark:bg-gray-700 dark:text-gray-300`, libellé `pei.see.state.{open|upcoming|closed}`, `absent` → `closed`) ; frise `<ol class="relative mt-6 space-y-6 border-s-2 border-brand-blue-100 dark:border-brand-blue-900/50 ms-2">` si `steps.length` : `<li class="relative ps-6">` avec pastille absolue `-start-[9px] top-1 w-4 h-4 rounded-full border-2 bg-white dark:bg-gray-800` (`border-brand-blue-500`, ou `border-brand-red-500 bg-brand-red-500` si `isDeadline`), `<time :datetime>` date formatée `Intl.DateTimeFormat(locale, { day: 'numeric', month: 'long', year: 'numeric', timeZone: 'Africa/Cairo' })` (période « début – fin » si `end` ≠ `start`, heure ajoutée si `synthetic`) en `text-sm font-semibold` (rouge si `isDeadline`), `label` en `text-gray-900 dark:text-white`, `description` en `text-sm text-gray-500` ; zone d'action (US1 : état `open`) : bouton pleine largeur `mt-8 inline-flex w-full justify-center items-center gap-2 rounded-full bg-brand-red-500 hover:bg-brand-red-600 px-6 py-3 font-semibold text-white` avec icône `fa-solid fa-rocket` — `NuxtLink :to="localePath(target.to)"` si `internal`, `<a :href target="_blank" rel="noopener noreferrer">` + texte a11y `pei.common.openInNewTab` si `external`, `<a :href>` libellé `pei.see.contactButton` si `contact` ; `ccNote` en `<p class="mt-3 text-center text-[13px] text-gray-500 dark:text-gray-400">` en état `open`
- [X] T019 [US1] Créer `usenghor_nuxt/app/pages/entrepreneuriat/statut-etudiant-entrepreneur.vue` — script : `const page = await usePeiPage({ heroPrefix: 'see', navKey: 'see' })` ; `const { data: call } = await useAsyncData('pei-see-call', () => { const slug = page.text('see.call_slug'); return slug ? usePublicCallsApi().getCallBySlug(slug).catch(() => null) : Promise.resolve(null) })` ; computed `state = seeCallState(call.value)`, `year = state === 'absent' ? null : seeCallYear(call.value)`, `heroBadge` (`page.hero.value.badge` + `year` → `t('pei.see.heroBadgeYear', { badge, year })`), `email = page.text('contact.email')`, `target = seeApplyTarget(call.value, state, email, t('pei.see.contactSubject'))`, `steps = call.value ? seeAgendaSteps(call.value.schedule ?? [], call.value.deadline, (s, f) => localized(s, f), t('pei.see.deadline')) : []`, `levers` (1..6 : `{ icon: seeLeverIcon(text('see.levers.N.icon')), title, text }` filtrés sur `title`), `jury = seeSlots(page.text, 'jury', 4)` ; en dernier `page.applySeo({ type: 'WebPage' })`
- [X] T020 [US1] Dans `statut-etudiant-entrepreneur.vue`, calculer les listes « appel d'abord, éditorial en secours » (research R8) : `conditions` = `call.eligibility_criteria` triés `display_order` → `{ label: localized(c, 'criterion'), note: c.is_mandatory ? '' : t('pei.see.wished') }`, sinon `seeSlots(page.text, 'conditions', 3)` ; `documents` = `call.required_documents` triés → `{ label: localized(d, 'document_name'), description: localized(d, 'description'), note: d.is_mandatory ? '' : t('pei.see.optional') }`, sinon `seeSlots(page.text, 'documents', 4)` sans description ; chaque liste indépendante (bloc par bloc)
- [X] T021 [US1] Gabarit de `statut-etudiant-entrepreneur.vue`, dans l'ordre (valeurs de `specs/maquettes-pei/statut-etudiant-entrepreneur.html`) : `<PageHero v-bind="page.hero.value" :badge="heroBadge" badge-icon="fa-solid fa-rocket" :breadcrumb="page.breadcrumb.value" />` ; `<EntrepreneurshipSubNav />` ; **Intro** `<section class="py-16 lg:py-24 bg-white dark:bg-gray-950">` `max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 grid gap-10 lg:grid-cols-12 lg:gap-16` : colonne `lg:col-span-7` (surtitre `text-sm font-semibold uppercase tracking-wider text-brand-blue-600`, `<h2 class="text-3xl sm:text-4xl font-bold">` + trait `h-1 w-1/3 bg-gradient-to-r from-brand-blue-500 to-brand-blue-300`, accroche `text-lg`, paragraphe) ; colonne `lg:col-span-5 space-y-4` : encadré `rounded-2xl bg-gradient-to-br from-brand-blue-900 to-brand-blue-800 p-6 text-white` (libellé `uppercase text-brand-blue-300`, texte), cartes SEE 1 (`border-brand-blue-200`, badge `bg-brand-blue-500 text-white`) et SEE 2 (`border-brand-red-200`, badge `bg-brand-red-500`) avec `see.tracks.N.{badge,title,text}` ; **Leviers** `<section class="py-16 lg:py-24 bg-gray-50 dark:bg-gray-900">` surtitre + titre, grille `mt-10 grid gap-5 sm:grid-cols-2 lg:grid-cols-3` de cartes `rounded-2xl bg-white dark:bg-gray-800 p-6 border` : ligne icône (carré `w-12 h-12 rounded-xl bg-brand-blue-100 dark:bg-brand-blue-900/40 text-brand-blue-600` + `<font-awesome-icon :icon>` `aria-hidden`) + `<h3 class="text-[17px] font-bold">`, texte `mt-3 text-sm text-gray-600 dark:text-gray-300` ; **Candidature** `<section id="candidater" class="scroll-mt-40 py-16 lg:py-24">` grille 12 : colonne 7 (surtitre, titre, intro ; `grid gap-5 sm:grid-cols-2` : carte Conditions `<ul>` coches `fa-solid fa-check text-teal-600` + note en `text-xs text-gray-500`, carte Jury `<ol>` pastilles numérotées `bg-brand-blue-100 text-brand-blue-700` ; carte Dossier pleine largeur `mt-5 rounded-2xl bg-brand-blue-50 dark:bg-brand-blue-900/20 border border-brand-blue-100 p-6`, `<ul class="grid gap-3 sm:grid-cols-2">` icône `fa-regular fa-file-lines`, nom, description, note) ; colonne 5 `<div class="lg:sticky lg:top-40 lg:self-start">` avec `<EntrepreneurshipSeeAgenda>` (props depuis T019, `button-label = page.text('see.agenda.button')`, `cc-note = page.text('see.agenda.cc_note')`, `closed-title`, `closed-text`, `opening-date = call?.opening_date ?? null`) ; emplacement FAQ réservé (T030) ; **PÉPITE** `<p class="mt-8 text-center text-sm">` `see.pepite.intro` + `<a :href target="_blank" rel="noopener noreferrer" class="font-semibold text-brand-blue-600 hover:underline">` icône `fa-solid fa-link` + `see.pepite.label`, rendu seulement si `isHttpUrl(page.text('see.pepite.url'))` et libellé non vide ; **CTA** `<section class="py-16 lg:py-24"><div class="max-w-4xl mx-auto px-4">` `<EntrepreneurshipCtaBanner :title="see.cta.title" :description="see.cta.text" :button-label="target?.kind === 'contact' ? t('pei.see.contactButton') : page.text('see.cta.button')" :to="target?.kind === 'internal' ? target.to : undefined" :href="target && target.kind !== 'internal' ? target.href : undefined" :external="target?.kind === 'external'" :email="email || null">` avec `<template #note>` = `see.agenda.cc_note` ; CTA masqué si titre vide ; chaque bloc masqué selon `data-model.md` § 2.6
- [X] T022 [US1] Valider quickstart § 3 lignes 1–2, § 6 (liens depuis `/entrepreneuriat`, bouton rouge `aria-current="page"` et halo sur la page, aucun sur `/entrepreneuriat/alumni`, fil d'Ariane à 6 niveaux) et § 7 (panneau collant à 1440 px sans chevauchement de la sous-navigation, non collant à 1023 px et 390 px) ; corriger `lg:top-40` si le panneau passe sous la sous-navigation

**Checkpoint**: la page est utilisable pour postuler (MVP).

---

## Phase 4: User Story 2 — FAQ du statut (Priority: P1)

**Goal**: FAQ groupée alimentée par le backoffice FAQ, ancres, JSON-LD `FAQPage`, `/faq` sans régression, traduction des entrées seedées.

**Independent Test**: quickstart § 2 (API, traduction) et § 5 (groupes, ouverture multiple, ancre, publication d'un brouillon visible ≤ 60 s, JSON-LD, `/faq`).

- [X] T023 [P] [US2] Créer `usenghor_nuxt/app/utils/faq-jsonld.ts` en extrayant **à l'identique** la logique de `usenghor_nuxt/app/pages/faq.vue` : `type FaqLang = 'fr' | 'en' | 'ar'` ; `faqQuestionFor(entry: FaqEntryPublic, lang)` ; `faqAnswerHtmlFor(entry, lang)` ; `buildFaqPageJsonLd(categories: FaqCategoryPublic[], lang)` → `null` si aucune entrée, sinon `{ '@context': 'https://schema.org', '@type': 'FAQPage', mainEntity: [...] }` avec `acceptedAnswer.text` = HTML dépouillé (`/<[^>]*>/g` → espace, espaces réduits, `trim`), tronqué à 5 000 caractères avec « … » (même règle que `stripHtml(html, 5000)` de `faq.vue`)
- [X] T024 [US2] Refactorer `usenghor_nuxt/app/pages/faq.vue` pour utiliser `buildFaqPageJsonLd(tree.value.categories, lang.value)` (conserver `useSeoMeta`, `htmlAttrs`, rendu) ; vérifier `curl -s http://localhost:3000/faq | grep -o '<script type="application/ld+json"[^>]*>[^<]*FAQPage[^<]*</script>' | diff - <scratchpad>/faq-jsonld-avant.txt` → aucune différence **avant** la migration 049 (ou après dépublication temporaire des entrées SEE)
- [X] T025 [P] [US2] Étendre `usenghor_nuxt/app/components/faq/FaqAccordion.vue` : props avec défauts `searchable: true`, `groupTitles: 'auto' | 'always' = 'auto'`, `headingLevel: 'h2' | 'h3' = 'h2'`, `multiple: false` (`withDefaults`) ; barre de recherche et `FaqCategoryFilter` rendues seulement si `searchable` ; titre de groupe si `groupTitles === 'always' || filteredCategories.length > 1`, balise `<component :is="headingLevel">` (classes `text-xl font-bold` en `h2`, `text-sm font-semibold uppercase tracking-wider text-gray-500 dark:text-gray-400` en `h3`) ; ouverture : `openSlugs = ref(new Set<string>())`, `toggle(slug)` → si `multiple` bascule dans l'ensemble, sinon ensemble réduit à `slug` ou vide ; `:open="openSlugs.has(entry.slug)"` ; ancre : remplacer `el.scrollIntoView(...)` par `scrollToPageAnchor('#' + hash, { lenis: useNuxtApp().$lenis })` (gotcha Lenis) ; si `multiple` et `searchable === false`, masquer les catégories sans entrée ; rendu `/faq` inchangé par défaut
- [X] T026 [P] [US2] Rendre publique la traduction d'entrée : dans `usenghor_backend/app/services/faq_service.py`, ajouter `async def autofill_entry_translations(self, entry: FaqEntry) -> None` qui délègue à `_autofill_entry_translations(entry)` (champs vides seulement, sans `force`)
- [X] T027 [US2] Étendre `usenghor_backend/app/services/entrepreneurship_service.py` `translate_missing` : après `laureates`, étape `faq_see` (si `complete`) — sélectionner les `FaqEntry` **publiées** jointes à `FaqCategory` avec `FaqCategory.code.startswith('see-', autoescape=True)` et au moins un de `question_en`, `question_ar`, `answer_en_html`, `answer_ar_html`, `answer_en_md`, `answer_ar_md` vide ou `NULL` ; pour chacune, tant que `time.monotonic() < deadline`, `await FaqService(self.db).autofill_entry_translations(entry)` et compter les entrées dont un champ a été rempli ; budget épuisé → `complete = False` ; ajouter `faq_see: int = 0` à `PeiTranslateMissingResponse` dans `usenghor_backend/app/schemas/entrepreneurship.py` et à `counts`
- [X] T028 [US2] Ajouter à `usenghor_backend/tests/integration/test_admin_entrepreneurship_api.py` un test de `POST /api/admin/entrepreneurship/translate-missing` avec traducteur simulé (`monkeypatch` de `translate_text` / `translate_html` utilisés par `app.services.faq_service`, retour `"[en] …"`) : catégorie `see-t` avec 1 entrée publiée sans EN/AR et 1 entrée non publiée, catégorie `general` avec 1 entrée publiée sans EN/AR → `faq_see == 1`, seule l'entrée publiée `see-t` est traduite, les autres restent vides ; lancer `pytest tests/integration/test_admin_entrepreneurship_api.py -v -k translate`
- [X] T029 [US2] Dans `usenghor_nuxt/app/pages/admin/entrepreneuriat/index.vue`, cumuler `result.faq_see ?? 0` dans `total`, l'inclure dans le test « passe incomplète sans progrès » et ajouter `plural(total.faq_see, 'question FAQ', 'questions FAQ')` aux `parts` ; ajouter `faq_see?: number` au type `PeiTranslateMissingResponse` (fichier où il est déclaré, `usenghor_nuxt/app/types/api/entrepreneurship.ts` ou `useEntrepreneurshipApi.ts`)
- [X] T030 [US2] Dans `statut-etudiant-entrepreneur.vue` : `const { data: faqTree } = await useAsyncData('pei-see-faq', () => usePublicFaqApi().getTree({ categoryPrefix: 'see-' }).catch(() => ({ categories: [] })))` (avant `applySeo`) ; `faqCategories = computed(() => (faqTree.value?.categories ?? []).filter(c => c.entries.length > 0))` ; `faqJsonLd = computed(() => buildFaqPageJsonLd(faqCategories.value, lang))` ; après `page.applySeo`, `useHead(() => ({ script: faqJsonLd.value ? [{ key: 'jsonld-pei-faq', type: 'application/ld+json', innerHTML: JSON.stringify(faqJsonLd.value) }] : [] }))` ; section `<section v-if="faqCategories.length" id="faq" class="scroll-mt-40 py-16 lg:py-24 bg-gray-50 dark:bg-gray-900"><div class="max-w-4xl mx-auto px-4">` surtitre + titre centrés (`see.faq.{eyebrow,title}`), `<FaqAccordion :tree="{ categories: faqCategories }" :searchable="false" group-titles="always" heading-level="h3" multiple class="mt-10" />`, puis la ligne PÉPITE (déplacée ici depuis T021, sous la FAQ ; affichée même si la FAQ est vide, dans ce cas dans un conteneur sans fond)
- [X] T031 [US2] Valider quickstart § 2 et § 5 : 2 groupes / 2 questions, deux réponses ouvertes simultanément, ancre `#see-statut-payant` visible sous la sous-navigation, publication d'un brouillon complété visible au rechargement, un seul `"FAQPage"` dans le HTML SSR, validateur schema.org OK ; `/faq` : groupes SEE après les catégories existantes, recherche / filtre / ancre OK, aucune « Réponse à rédiger… » visible ; « Traduire les champs manquants » → « 2 questions FAQ »

**Checkpoint**: US1 + US2 = page de conversion complète pour un appel ouvert.

---

## Phase 5: User Story 3 — Appel à venir, clos ou absent (Priority: P2)

**Goal**: Aucun bouton vers un formulaire fermé ou inexistant ; message et contact ; page toujours 200.

**Independent Test**: quickstart § 3 lignes 3–7.

- [X] T032 [US3] Compléter `usenghor_nuxt/app/components/entrepreneurship/SeeAgenda.vue` pour les états hors ouverture : `upcoming` → sous la frise `<p class="mt-6 text-sm font-medium">` `t('pei.see.opensOn', { date })` si `openingDate` (date formatée comme la frise), puis `closedText` en `text-sm text-gray-600` si fourni, puis bouton contact ; `closed` → frise conservée, bloc `mt-6 rounded-xl bg-gray-50 dark:bg-gray-900/40 p-4` avec `closedTitle` (`font-semibold`) et `closedText`, puis bouton contact ; `absent` → même bloc sans frise ; bouton contact = `<a :href="target.href">` icône `fa-regular fa-envelope`, style secondaire `border border-brand-blue-500 text-brand-blue-600 dark:text-brand-blue-300 rounded-full w-full` ; aucun bouton si `target` nul ; jamais de `NuxtLink` vers `/candidatures/postuler/*` hors état `open` ; `ccNote` affichée uniquement en `open`
- [X] T033 [US3] Dans `statut-etudiant-entrepreneur.vue`, vérifier et ajuster les dérivations : badge du hero sans année en état `absent` ; CTA final en `contact` (libellé `pei.see.contactButton`, `mailto`) hors `open` et pour un appel ouvert sans formulaire (`seeApplyTarget` → `contact`) ; conditions et pièces éditoriales en `absent` ; aucune exception si `call.schedule`, `eligibility_criteria` ou `required_documents` sont absents (`?? []`)
- [X] T034 [US3] Valider quickstart § 3 lignes 3 à 7 (ouvert sans formulaire, à venir, clos, en cours date passée, dépublié / slug inexistant / clé vide) et une erreur backend simulée (arrêt temporaire de l'API appels ou slug provoquant une erreur) : `curl -s -o /dev/null -w '%{http_code}'` → 200 partout, états et boutons conformes, aucune erreur console

**Checkpoint**: la page est « permanente » quel que soit l'appel.

---

## Phase 6: User Story 4 — Mettre à jour le guide sans développeur (Priority: P2)

**Goal**: Les 65 textes sont éditables dans Valeurs et reflétés à la page.

**Independent Test**: quickstart § 1 (rejeu conserve les éditions) et § 4.

- [X] T035 [P] [US4] Ajouter à la section `entrepreneurship-see` de `usenghor_nuxt/app/composables/editorial-pages-config.ts` les 65 clés de `contracts/editorial-keys.md` après les 4 existantes (ordre : hero, intro, what, tracks, levers, apply, conditions, jury, documents, agenda, closed, faq, pepite, cta) dans `editorialKeys` **et** `fields` : `label` lisible (« Hero — badge », « Parcours SEE 1 — titre », « Levier 3 — icône (classe Font Awesome) »…), `description` = description SQL, `type` = `image` pour `see.hero.image`, `textarea` pour `hero.subtitle`, `intro.lead`, `intro.body`, `what.text`, `tracks.{1,2}.text`, `levers.{1..6}.text`, `apply.intro`, `closed.text`, `cta.text`, sinon `text` ; `editable: true` ; `defaultValue` = valeur seedée validée en T001 ; mettre à jour `description` de la section : « Textes de la page « Entreprendre et étudier », appel SEE en cours et encart « devenir mentor » »
- [X] T036 [P] [US4] Ajouter les 65 littéraux `'entrepreneurship.see.…'` à l'union `ValueSectionKey` de `usenghor_nuxt/app/types/api/editorial.ts` (après `entrepreneurship.see.mentor.button`)
- [X] T037 [US4] Valider quickstart § 4 : 69 champs visibles dans Admin → Valeurs → Entrepreneuriat → « Statut Étudiant-Entrepreneur » ; modification du titre et de l'icône du levier 4, icône invalide → icône neutre, condition vidée (appel sans critères) → omise, `see.pepite.url` vide → ligne masquée puis renseignée → lien ; `see.call_slug` changé → agenda, badge et boutons du nouvel appel ; rejeu de la 049 → éditions conservées

---

## Phase 7: User Story 5 — Langues, RTL, mobile, sombre, SEO (Priority: P3)

**Goal**: Exigences transversales vérifiées et corrigées.

**Independent Test**: quickstart § 8–9.

- [X] T038 [US5] Valider quickstart § 8 sur `/entrepreneuriat/statut-etudiant-entrepreneur`, `/en/…`, `/ar/…` à 1440 px et 390 px, clair et sombre : libellés `pei.see.*` traduits, `dir="rtl"` et frise / grilles / flèches en miroir en arabe, `document.documentElement.scrollWidth <= window.innerWidth` à 390 px, contraste des cartes, encadré, agenda, FAQ et CTA en sombre ; corriger dans `statut-etudiant-entrepreneur.vue` ou `SeeAgenda.vue` (propriétés logiques, classes `dark:`)
- [X] T039 [US5] Valider quickstart § 9 : page présente dans le sitemap en 3 langues, balises `og:*` et `twitter:*` dans le HTML SSR, JSON-LD `Organization`, `WebPage`, `BreadcrumbList` et `FAQPage` valides ; contenu principal présent dans `curl` sans JavaScript ; Lighthouse mobile FR : accessibilité ≥ 90, performance comparée à `/entrepreneuriat/alumni` (écart documenté si inférieur)

---

## Phase 8: Polish & Cross-Cutting Concerns

- [X] T040 [P] Non-régression (quickstart § 10) : captures après de `/faq` (différences limitées aux groupes SEE publiés), `/actualites/appels/<slug>`, `/candidatures/postuler/<slug>`, `/entrepreneuriat/alumni` (bandeau mentor identique), `/entrepreneuriat` (bouton rouge sans halo) comparées aux captures de T003
- [X] T041 [P] `cd usenghor_nuxt && NODE_OPTIONS=--max-old-space-size=8192 pnpm build` : aucune erreur, aucun WARN de collision d'auto-import (`seeCallState`, `buildFaqPageJsonLd`…)
- [X] T042 [P] `cd usenghor_backend && source .venv/bin/activate && pytest tests/integration/test_public_faq_api.py tests/integration/test_admin_entrepreneurship_api.py tests/integration/test_public_entrepreneurship_api.py -v` ; consigner les éventuels échecs préexistants dus au quota du traducteur
- [X] T043 Mettre à jour `CLAUDE.md` : tableau « Composants clés » (`EntrepreneurshipSeeAgenda` ; variantes `FaqAccordion` `searchable` / `groupTitles` / `headingLevel` / `multiple` ; `CtaBanner external` + slot `note` ; `usePeiPage` rubrique `see` et `applySeo({ type })` ; `usePublicFaqApi().getTree({ categoryPrefix })`) ; « Recent Changes » : entrée `025-pei-see-status-page` (route, filtre `GET /api/public/faq?category_prefix=`, catégories FAQ réservées `see-*` visibles sur `/faq`, migration `049_pei_see_page.sql` : 65 clés, 4 catégories, 8 entrées dont 6 brouillons, rollback, étape `faq_see` de « Traduire les champs manquants », état d'appel dérivé ouvert / à venir / clos / absent)
- [X] T044 [P] Marquer la feature 025 livrée dans `specs/roadmap-pei-entrepreneuriat.md` (encart « ✅ Livrée » sous le titre de la feature 025, portée retenue : catégories `see-*`, appel d'abord / éditorial en secours, 8 questions dont 2 publiées, 9ᵉ question à créer par l'équipe)
- [X] T045 Informer le responsable des actions de contenu restantes : compléter et publier les 6 brouillons FAQ, créer la 9ᵉ question, renseigner `see.pepite.url` si vide, désigner l'appel SEE dans `see.call_slug`, lancer « Traduire les champs manquants » ; puis, en production (après commit + push, `deploy.sh` avec `--force-recreate`) : `docker exec -i usenghor_db psql -U usenghor -d usenghor < 049_pei_see_page.sql` (vérifier au préalable en lecture seule l'absence de catégories `see-*` existantes)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1** : T001 bloque T016–T017 et T035 (valeurs par défaut) ; T002–T003 immédiats.
- **Phase 2** : T004–T013 en parallèle ; T014–T015 après T011 / T013 ; T016–T017 après T001.
- **US1 (Phase 3)** : après T004–T010 ; T018 [P] avec T019–T020 ; T021 après T018–T020 ; T022 en fin.
- **US2 (Phase 4)** : après T011–T012 (et T016 pour les données) ; T023, T025, T026 en parallèle ; T024 après T023 ; T027 après T026 ; T028 après T027 ; T029 après T027 ; T030 après T019, T023, T025 ; T031 en fin.
- **US3 (Phase 5)** : après T018–T021.
- **US4 (Phase 6)** : T035–T036 après T001 ; T037 après T016 et T021.
- **US5 (Phase 7)** : après US1–US3.
- **Polish** : après toutes les stories visées.

### User Story Dependencies

- US1 : autonome (page, agenda ouvert). US2 : réutilise la page de US1 (T030 ajoute une section) mais son backend (T023–T029) est indépendant. US3 : étend le composant et la page de US1. US4 : indépendant côté configuration ; validation après US1. US5 : transversal.

### Parallel Opportunities

- Phase 2 : T004, T005, T006, T007, T008, T009, T010, T011, T012, T013 simultanément (fichiers distincts).
- US2 : T023 (utilitaire JSON-LD), T025 (accordéon), T026 (service FAQ) en parallèle ; T028 et T029 en parallèle après T027.
- US4 : T035 et T036 en parallèle, et en parallèle de US1 / US2.
- Polish : T040, T041, T042, T044 en parallèle.

## Parallel Example: Phase 2

```text
Sous-agent A : T004 utilitaires see* (pei-presentation.ts)
Sous-agent B : T006 + T007 + T008 i18n FR / EN / AR
Sous-agent C : T009 SubNav + T010 CtaBanner
Sous-agent D : T011 filtre backend + T013 tests FAQ
Sous-agent E : T005 usePeiPage + T012 usePublicFaqApi
```

## Parallel Example: User Story 2

```text
Sous-agent A : T023 utils/faq-jsonld.ts puis T024 refactor faq.vue (diff JSON-LD)
Sous-agent B : T025 FaqAccordion (variantes + ancre Lenis)
Sous-agent C : T026 → T027 → T028 traduction faq_see + test
```

## Implementation Strategy

### MVP First (US1)

1. Phase 1 (accord SQL) + Phase 2.
2. US1 → valider (T022) : la page convertit vers le formulaire de l'appel ouvert.
3. Démontrer / déployer si utile (les trois liens existants cessent de mener à « introuvable »).

### Incremental Delivery

1. + US2 : FAQ et données structurées.
2. + US3 : page permanente hors période d'appel (**à livrer avant toute mise en production**, la plupart du temps aucun appel n'est ouvert).
3. + US4 : autonomie éditoriale complète.
4. + US5 et Polish : conformité transverse, documentation, déploiement (T045).

### Notes

- Aucun commit sans demande explicite ; déploiement : commit + push des sous-dépôts avant `deploy.sh` (mémoire projet).
- Ne jamais afficher de réponse provisoire FAQ : seules les entrées publiées sont lues par le public.
