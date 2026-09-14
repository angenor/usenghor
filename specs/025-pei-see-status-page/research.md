# Research — 025 Page « Entreprendre et étudier à Senghor » (SEE)

Date : 2026-09-14. Inventaire réalisé par sous-agents (FAQ + appels, mini-site PEI, maquette) puis lecture ciblée du code. Chaque décision : **Décision / Justification / Alternatives**.

## R1 — Cadre de page : `usePeiPage` étendu à la rubrique `see`

- **Décision** : `pages/entrepreneuriat/statut-etudiant-entrepreneur.vue` suit le modèle des pages 024 : `const page = await usePeiPage({ heroPrefix: 'see', navKey: 'see' })`, puis `useAsyncData` de l'appel et de la FAQ, puis `page.applySeo({ type: 'WebPage' })` et un `useHead` complémentaire pour le JSON-LD `FAQPage`, **en dernier** (gotcha TDZ unhead). `PeiRubric` reçoit `'see'` ; `applySeo` reçoit un paramètre optionnel `type` (défaut `'CollectionPage'`, rendu 024 inchangé).
- **Justification** : hero (`entrepreneurship.see.hero.*` avec repli `pei.seo.seeTitle`), fil d'Ariane (« … › Pôle › `pei.nav.see` »), OG et JSON-LD Organization / BreadcrumbList sont déjà factorisés ; la page SEE n'est pas une page de collection.
- **Alternatives** : squelette écrit à la main comme `index.vue` / `activites.vue` (rejeté : duplication) ; nouveau composable dédié (rejeté : 95 % identique).

## R2 — Badge du hero avec l'année de l'appel

- **Décision** : `badge = t('pei.see.heroBadgeYear', { badge, year })` si l'année est connue, sinon le badge éditorial seul. Année = année de `opening_date`, sinon de `deadline` ; aucune année en état « absent ». `badgeIcon` : `fa-solid fa-rocket`. Aucune `actions` (maquette sans bouton).
- **Justification** : « · Appel » est un libellé fixe traduisible ; le libellé « Statut Étudiant-Entrepreneur » est éditorial.
- **Alternatives** : année saisie dans une clé éditoriale (rejeté : désynchronisation avec l'appel).

## R3 — Sous-navigation : mise en évidence automatique du bouton

- **Décision** : dans `SubNav.vue`, le bouton rouge calcule `isActive('/entrepreneuriat/statut-etudiant-entrepreneur')` ; actif → `aria-current="page"` + halo `ring-4 ring-brand-red-100 dark:ring-brand-red-900/40` (halo `#ffe3e3` de la maquette). Aucune prop, aucun onglet ajouté. **Libellé inchangé** (`pei.nav.cta` = « Devenir étudiant-entrepreneur ») : déjà en production sur six pages ; « Postuler au statut » reste le libellé éditorial du CTA de l'accueil (`entrepreneurship.cta.button`).
- **Justification** : la route suffit à déterminer l'état ; aucun onglet ne correspond (maquette : aucun onglet actif). Les six onglets ne sont jamais actifs sur cette route (préfixes distincts ; « Présentation » est `exact`).
- **Alternatives** : prop `highlightCta` passée par la page (rejeté : redondant) ; renommer `pei.nav.cta` (rejeté : changement visible sur les six rubriques, hors besoin).

## R4 — Lecture de l'appel et état dérivé

- **Décision** : `useAsyncData('pei-see-call', () => slug ? usePublicCallsApi().getCallBySlug(slug).catch(() => null) : null)` après l'éditorial. Nouvel utilitaire pur `seeCallState(call, now)` → `'open' | 'upcoming' | 'closed' | 'absent'` : `null` → `absent` ; `ongoing` et (`deadline` absente ou future) → `open` ; `upcoming` → `upcoming` ; sinon `closed`.
- **Justification** : la lecture isolée ne déclenche pas `auto_close_expired_calls` ; la règle reprend `isCallOpen` de `/candidatures/postuler/[slug]` (source d'autorité côté candidature). La 404 d'un appel non publié / introuvable est absorbée par `catch` : la page répond 200.
- **Alternatives** : appeler la clôture automatique depuis la lecture par slug (rejeté : effet de bord backend hors périmètre) ; `CTASection` (rejeté : ignore `use_internal_form`, bouton « à venir » non souhaité).
- **Note SSR** : l'état est calculé côté serveur et hydraté ; un écart d'horloge client-serveur au passage exact de la date limite est accepté (rechargement).

## R5 — Cible des boutons « Postuler »

- **Décision** : utilitaire `seeApplyTarget(call, state, email)` → `{ kind: 'external', href }` si état `open` et `external_form_url` HTTP(S) valide (`isHttpUrl`) ; `{ kind: 'internal', to: '/candidatures/postuler/{slug}' }` si état `open` et `use_internal_form` ; sinon `{ kind: 'contact', href: 'mailto:…?subject=…' }` si e-mail ; sinon `null`. Utilisé par le panneau agenda **et** par le CTA final.
- **Justification** : FR-018 à FR-020 ; corrige, pour cette page seulement, le défaut de `CTASection` (formulaire interne désactivé ignoré). La priorité externe > interne est celle de `CTASection`.
- **Alternatives** : corriger `CTASection` (rejeté : hors périmètre, non-régression de `/actualites/appels/[slug]` ; signalé).

## R6 — Panneau agenda : nouveau composant `EntrepreneurshipSeeAgenda`

- **Décision** : `components/entrepreneurship/SeeAgenda.vue` (props `call`, `state`, `target`, `ccNote`, `closedTitle`, `closedText`, `buttonLabel`, `email`) : en-tête « Agenda {année} » + badge d'état (rouge ouvert, ambre à venir, gris clos), frise verticale à pastilles cerclées (trait `brand-blue-100`), étape de date limite en pastille rouge, bouton pleine largeur (fusée), note « directeur en copie » (état ouvert), message et lien e-mail (autres états), « Ouverture le {date} » (à venir). Collant via la page : conteneur `lg:sticky lg:top-40 self-start` (en-tête 80 px + sous-nav ≈ 57 px), non collant sous `lg`.
- **Justification** : inventaire — `calls/ScheduleSection` est une frise numérotée sans état, sans actions ni style de maquette ; aucun composant « aside collant » (motif en ligne `sticky top-24` dans trois pages). `ScheduleSection` n'est pas modifié (non-régression) ; son usage de `useLocalizedField().localized(step, 'step' | 'description')` est repris.
- **Alternatives** : étendre `ScheduleSection` par variante (rejeté : rendu très différent, risque sur cinq pages d'appel) ; `CTASection` (rejeté, R5).
- **Vérification T002 (2026-09-14, sous-agent)** : aucun panneau d'appel à états ni agenda collant réutilisable (`calls/InfoCards.vue` n'affiche qu'un libellé de statut ; `campus/CampusCalls.vue` est une liste ; les éléments collants sont des barres d'onglets). Aucun export existant nommé `seeCallState`, `seeApplyTarget`, `seeCallYear`, `seeAgendaSteps`, `seeSlots`, `seeLeverIcon`, `faqQuestionFor`, `faqAnswerHtmlFor`, `buildFaqPageJsonLd`, `SeeCallState`, `SeeApplyTarget`, `AgendaStep`, `FaqLang` dans `app/**` : aucun renommage nécessaire.

## R7 — Repère « date limite » dans la frise

- **Décision** : utilitaire `seeAgendaSteps(schedule, deadline)` : trie par `display_order`, marque `isDeadline` l'étape dont `end_date ?? start_date` tombe le même jour calendaire que `deadline` (fuseau de l'université, `Africa/Cairo`) ; si aucune ne correspond et que `deadline` existe, insère une ligne synthétique `pei.see.deadline` datée (date + heure) à sa place chronologique. Appel sans calendrier → seule la ligne de date limite.
- **Justification** : aucun champ « étape = date limite » en base ; la maquette colore l'étape correspondante. Tri chronologique non imposé aux étapes (ordre du backoffice).
- **Alternatives** : détecter par l'intitulé (« limite ») (rejeté : fragile, trilingue).

## R8 — Conditions et dossier : appel d'abord, éditorial en secours (Q3)

- **Décision** : `conditions = call.eligibility_criteria` localisés (triés `display_order`, mention `pei.see.wished` si `is_mandatory = false`) ; à défaut (appel absent ou liste vide) `entrepreneurship.see.conditions.{1..3}`. `documents = call.required_documents` (nom + description, mention `pei.see.optional` si non obligatoire) ; à défaut `entrepreneurship.see.documents.{1..4}`. Jury : toujours `entrepreneurship.see.jury.{1..4}`. Rendu dans des cartes propres à la page (style maquette), pas via `EligibilitySection` / `DocumentsSection`.
- **Justification** : clarification Q3 ; les sections d'appel existantes ont titres i18n fixes et mise en page de détail d'appel, incompatibles avec les cartes côte à côte de la maquette ; les réutiliser imposerait des variantes sans gain.
- **Alternatives** : variantes de `EligibilitySection` / `DocumentsSection` (rejeté : trois props de présentation pour 20 lignes de gabarit).

## R9 — FAQ : filtre public `category_prefix`

- **Décision** : `GET /api/public/faq?category_prefix=see-` (optionnel, `^[a-z0-9_-]{1,60}$`, sinon 422). `FaqService.get_public_tree(category_prefix: str | None = None)` ajoute `FaqCategory.code.startswith(prefix, autoescape=True)`. Sans paramètre : requête et réponse identiques. Même `Cache-Control`. `usePublicFaqApi().getTree(options?: { categoryPrefix?: string })` additif. `/faq` inchangée (Q1 : les catégories `see-*` y restent visibles).
- **Justification** : un seul niveau de catégories ; le préfixe permet d'ajouter un sous-groupe sans code ; `autoescape` neutralise `_` et `%` de `LIKE`.
- **Alternatives** : `?categories=a,b,c` (rejeté : liste figée côté page) ; filtrage côté client sur l'arbre complet (rejeté : SSR plus lourd, contrat moins net) ; `description`/drapeau en base (rejeté : modification de schéma interdite).

## R10 — FAQ : variante de `FaqAccordion`

- **Décision** : props additives sur `components/faq/FaqAccordion.vue` : `searchable` (défaut `true` : barre + filtre), `groupTitles: 'auto' | 'always'` (défaut `'auto'` : titre si > 1 catégorie), `headingLevel: 'h2' | 'h3'` (défaut `'h2'`), `multiple` (défaut `false` : une seule entrée ouverte ; `true` : ensemble d'entrées ouvertes). La page SEE passe `:searchable="false" group-titles="always" heading-level="h3" multiple` et masque les catégories sans entrée. Le défilement vers l'ancre utilise `scrollToPageAnchor(hash, { lenis: $lenis })` (repli `scrollIntoView` intégré), en remplacement de l'appel direct à `scrollIntoView` ignoré par Lenis (gotcha connu) — changement vérifié sur `/faq` (ancre `#slug`).
- **Justification** : la maquette ouvre deux réponses à la fois et titre les groupes ; le composant actuel est à ouverture unique avec recherche. `FaqAccordionItem` est réutilisé tel quel (ancre, copie de lien).
- **Alternatives** : nouveau composant FAQ du pôle (rejeté : duplication, consigne de réutilisation) ; garder `scrollIntoView` (rejeté : US2-4 non satisfaite sous Lenis).

## R11 — JSON-LD `FAQPage` partagé

- **Décision** : nouvel utilitaire `utils/faq-jsonld.ts` : `faqQuestionFor(entry, lang)`, `faqAnswerHtmlFor(entry, lang)`, `buildFaqPageJsonLd(categories, lang)` (texte brut, 5 000 caractères max, `null` si aucune entrée) — logique extraite **à l'identique** de `pages/faq.vue`, qui l'utilise désormais ; la page SEE l'utilise sur l'arbre filtré (`key: 'jsonld-pei-faq'`). Vérification : JSON-LD de `/faq` identique octet pour octet avant / après (`curl` + `diff`).
- **Justification** : « même mécanisme que `/faq` » sans copier la fonction ; doublon `/faq` ↔ SEE accepté (Q1).
- **Alternatives** : copier la fonction dans la page (rejeté : divergence future).

## R12 — Traduction des entrées FAQ seedées

- **Décision** : étendre `EntrepreneurshipService.translate_missing` d'une étape `faq_see` : entrées **publiées** des catégories `see-%` ayant un champ EN/AR vide → méthode de traduction des entrées de `FaqService` rendue publique (`autofill_entry_translations`, alias de l'actuelle `_autofill_entry_translations`, champs vides seulement), sous le même budget de temps. `PeiTranslateMissingResponse.faq_see: int = 0` ; le tableau de bord PEI cumule et affiche « N question(s) FAQ ». Libellés de catégorie : fournis en EN/AR par la migration (aucune traduction automatique de catégorie n'existe).
- **Justification** : bouton déjà connu de l'équipe (« Traduire les champs manquants ») ; limiter aux entrées publiées évite de traduire les réponses provisoires des brouillons, qui seront traduites automatiquement à leur enregistrement (autofill à la mise à jour, champs vides).
- **Alternatives** : EN/AR saisis dans le SQL (rejeté : demande « traduction automatique ») ; « ouvrir et enregistrer chaque entrée » (conservé comme procédure de secours dans quickstart).
- **Permission** : `entrepreneurship.edit` (existante) — l'étape FAQ ne touche que des entrées `see-*`, cohérent avec la propriété de ces catégories par le pôle.

## R13 — Clés éditoriales : 65 clés à emplacements fixes

- **Décision** : 65 clés `entrepreneurship.see.*` (liste dans [contracts/editorial-keys.md](contracts/editorial-keys.md)) ajoutées à la section existante `entrepreneurship-see` (4 → 69 champs, description mise à jour) et à `ValueSectionKey`. Listes (leviers 6, conditions 3, jury 4, pièces 4) en emplacements numérotés ; emplacement vide → omis. Icônes des leviers : classe Font Awesome en texte (bibliothèque `fas/far/fab` complète déjà chargée) ; icône invalide → `fa-solid fa-circle-check`.
- **Justification** : convention 024 (`alumni.stats.{1,2,3}`) ; le système éditorial stocke des scalaires, la page « Valeurs » édite des champs simples.
- **Alternatives** : une clé JSON par liste (rejeté : édition JSON brute pour l'équipe) ; sections séparées (rejeté : la section `entrepreneurship-see` existe et est nommée pour cela) — sous-titres de groupes via le libellé des champs (« Levier 3 — titre »).
- **Lien PÉPITE France** : `see.pepite.url` seedée **vide** (aucune adresse officielle vérifiée dans le dépôt) → ligne masquée jusqu'à saisie ; adresse à confirmer lors de l'accord sur le SQL.

## R14 — Migration 049 et rollback

- **Décision** : `049_pei_see_page.sql` : `BEGIN` ; 65 clés (`ON CONFLICT (key) DO NOTHING`, catégorie `values`) ; 4 catégories (`ON CONFLICT (code) DO NOTHING`, `display_order` 10 à 13 pour apparaître après les catégories existantes sur `/faq`) ; 8 entrées (`ON CONFLICT (slug) DO NOTHING`, catégorie par sous-requête sur le code, 2 publiées avec `published_at = NOW()`, 6 brouillons avec réponse provisoire, EN/AR `NULL`) ; `COMMIT`. Rollback : entrées par slug, puis catégories `see-*` seedées **sans entrée restante** (FK `RESTRICT` : une question créée par l'équipe bloque la suppression de sa catégorie, avec avertissement), puis clés `entrepreneurship.see.%` hors des 4 clés de la 045. `services/15_faq.sql` et `12_editorial.sql` inchangés (aucune structure).
- **Justification** : modèle 047 / 048 ; rejouable ; ne jamais écraser une édition.
- **Alternatives** : `ON CONFLICT DO UPDATE` (rejeté : écraserait les éditions).

## R15 — i18n, SEO, sitemap, RTL

- **Décision** : `pei.nav.see`, `pei.seo.{seeTitle,seeDescription}`, bloc `pei.see.*` (≈ 15 libellés : badge année, agenda, états, date limite, ouverture, contact, sujet d'e-mail, souhaité, facultatif, repli d'icône a11y) en FR / EN / AR. Sitemap : découverte automatique des pages statiques (vérifié, aucune exclusion). Mise en page en propriétés logiques (`ms-`, `ps-`, `start-`), frise miroir en RTL, flèches `rtl:rotate-180`.
- **Alternatives** : aucune.

## R16 — Bandeau CTA final

- **Décision** : `EntrepreneurshipCtaBanner` avec prop additive `external?: boolean` (`target="_blank" rel="noopener noreferrer"` sur le lien `href`) et slot optionnel `note` (rappel « directeur en copie ») ; `to` pour le formulaire interne, `href` pour externe / mailto, `email` affiché. Libellé du bouton : `see.cta.button` si cible formulaire, sinon `pei.see.contactButton`.
- **Justification** : réutilisation (accueil, alumni) avec rendu par défaut inchangé.
- **Alternatives** : bandeau propre à la page (rejeté).

## R17 — Tests et validation

- **Décision** : backend — `tests/integration/test_public_faq_api.py` : filtre préfixe (seules `see-*`, entrées publiées, catégories inactives exclues), réponse sans filtre inchangée, préfixe invalide → 422 ; test de `translate_missing` étendu avec traducteur simulé (les tests FAQ appellent le vrai traducteur : gotcha quota connu, cinq tests FAQ échouent d'office). Utilitaires frontend (`seeCallState`, `seeApplyTarget`, `seeAgendaSteps`) : pas d'infrastructure de test → table de cas manuelle dans quickstart. `pnpm build` (heap 8 Go, port ≠ 3000), captures avant / après `/faq` et `/actualites/appels/[slug]`, `curl` SSR, validateur de données structurées, Lighthouse mobile.
