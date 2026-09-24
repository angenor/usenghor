# CLAUDE.md

## Projet

Monorepo pour le site de l'Université Senghor (Alexandrie, Égypte). Trilingue : français (défaut), anglais, arabe (RTL).

| Dossier | Stack |
|---------|-------|
| `usenghor_nuxt/` | Nuxt 4, Vue 3, Tailwind CSS |
| `usenghor_backend/` | FastAPI, Python 3.14, PostgreSQL |

## Accès admin (local)

Les identifiants admin se trouvent dans `usenghor_backend/.env` (variables `ADMIN_EMAIL` et `ADMIN_PASSWORD`).

## Commandes

```bash
# Frontend (usenghor_nuxt/)
pnpm install && pnpm dev     # http://localhost:3000
pnpm build                   # Production build
pnpm lint                    # ESLint

# Backend (usenghor_backend/)
docker compose up -d         # PostgreSQL + Adminer (http://localhost:8080)
source .venv/bin/activate
uvicorn app.main:app --reload  # http://localhost:8000 (Swagger: /api/docs)

# Migrations SQL (local)
docker exec -i usenghor_postgres psql -U usenghor -d usenghor < fichier.sql

# Déploiement
./deploy.sh deploy|update|status|logs|restart|stop|ssl|backup|connect
```

## Docker

| Environnement | Conteneur PostgreSQL |
|---------------|---------------------|
| Local | `usenghor_postgres` |
| Production | `usenghor_db` |

Conteneurs en production : `usenghor_nginx`, `usenghor_frontend`, `usenghor_backend`, `usenghor_db`

```bash
# Migration SQL en production
docker exec -i usenghor_db psql -U usenghor -d usenghor < fichier.sql
```

## Architecture Frontend

```
app/
├── components/    # Auto-importés, organisés par feature
├── composables/   # useDarkMode, useScrollAnimation, useMockData, useToastUIEditor...
├── pages/         # Routing basé fichiers
├── stores/        # Pinia
└── assets/css/    # main.css, timeline.css
i18n/locales/      # fr/, en/, ar/ (JSON fusionnés via index.ts)
bank/mock-data/    # Données de dev (miroir du schéma PostgreSQL)
```

**Modules clés :** `@nuxtjs/tailwindcss`, `@pinia/nuxt`, `@nuxtjs/i18n` (prefix_except_default), `@nuxt/image`

**Styling :** Tailwind + dark mode (`class`), couleurs `brand-blue-*`/`brand-red-*`, GSAP + Lenis, Leaflet

## Base de données

**PostgreSQL 16** via Docker (`docker-compose.yml` dans `usenghor_backend/`). Le schéma SQL complet est dans `usenghor_backend/documentation/modele_de_données/services/` avec un fichier orchestrateur [`main.sql`](usenghor_backend/documentation/modele_de_données/services/main.sql) qui inclut 17 fichiers via `\i` :

| Fichier | Service | Tables principales |
|---------|---------|-------------------|
| `00_extensions.sql` | Extensions | uuid-ossp, pgcrypto, types ENUM |
| `01_core.sql` | Core | countries |
| `02_identity.sql` | Identity | users, roles, permissions, audit_logs |
| `03_media.sql` | Media | media, albums |
| `04_organization.sql` | Organization | sectors, services, service_team |
| `05_campus.sql` | Campus | campuses, campus_team |
| `06_partner.sql` | Partner | partners |
| `07_academic.sql` | Academic | programs, program_courses, program_semesters |
| `08_application.sql` | Application | application_calls, applications |
| `09_content.sql` | Content | events, news, tags |
| `10_project.sql` | Project | projects, project_categories |
| `11_newsletter.sql` | Newsletter | newsletter_subscribers, newsletter_campaigns |
| `12_editorial.sql` | Editorial | editorial_categories, editorial_contents |
| `16_entrepreneurship.sql` | Entrepreneurship | pei_programs, pei_cohorts, pei_resources, pei_laureates, pei_partners |
| `99_functions.sql` | Utilitaires | Fonctions et triggers |
| `99_data_init.sql` | Seed | Données initiales |
| `99_views.sql` | Vues | Vues agrégées |

**Migrations :** `usenghor_backend/documentation/modele_de_données/migrations/` (fichiers `00X_*.sql`)

**Source de vérité :** Toute modification de structure → **demander accord → mettre à jour le SQL → puis le code**

## Composants clés

| Composant | Usage |
|-----------|-------|
| `ToastUIEditor.client.vue` | Édition rich text WYSIWYG/Markdown (admin, client-only) |
| `RichTextRenderer.vue` | Affichage HTML rich text (public) |
| `useToastUIEditor.ts` | Composable de gestion de l'éditeur TOAST UI |
| `useMockData()` | Données de dev sans BDD |
| `components/faq/admin/*` | Backoffice FAQ (entrées + catégories trilingues, audit) |
| `useFaqApi()` | Composable admin FAQ (`/api/admin/faq/*`) |
| `useEntrepreneurshipApi()` | Composable admin pôle PEI (`/api/admin/entrepreneurship/*`) : dispositifs, cohortes, ressources, lauréats, partenaires du pôle |
| `components/entrepreneurship/admin/*` | Backoffice PEI (dispositifs, cohortes, ressources, lauréats, partenaires du pôle — `PartnerPicker`, `PartnerFamilyBoard` —, tableau de bord) |
| `AdminMediaPicker` | Sélecteur de médiathèque transverse (modale, recherche, téléversement) |
| `AppNavBar` / `NavItemsField` | Menu éditorial (`navbar.*.children`) : libellés facultatifs `label_en` / `label_ar` par entrée (repli `label`, puis `t('nav.dropdowns.…')`, via `navChildLabel`) ; saisis dans l'éditeur `admin/editorial/NavItemsField.vue` (clés inconnues conservées) |
| `PageHero` | Hero des pages internes ; props optionnelles `images[]` (slider accessible si ≥ 2, pause survol / focus, `prefers-reduced-motion`), `badge` / `badgeIcon`, `actions[]` (ancre `#…` ou route) — `image` reste prioritaire, rendu inchangé sans ces props |
| `EntrepreneurshipSubNav` | Sous-navigation collante du mini-site PEI (`components/entrepreneurship/SubNav.vue`, rubriques fixes + bouton « Devenir étudiant-entrepreneur ») ; blocs publics du pôle dans `components/entrepreneurship/*` (hors `admin/`) |
| `ActualitesNewsCard` | Carte d'actualité partagée (grille de `/actualites`, accueil du pôle) — props `item`, `showAssociations`, `imageVariant` |
| `usePublicEntrepreneurshipApi()` | Lectures publiques du pôle (`/api/public/entrepreneurship/*`) : dispositifs, cohortes, portraits, partenaires, ressources |
| `OrganigrammeSection` | Organigramme public (`components/organization/`) : services de premier niveau par secteur, **pôles** (`children`) listés en retrait sous leur parent (liseré `border-s`, miroir RTL) ; destination d'une carte = `getServiceLink()` (`landing_path` sinon fiche) ; carte partagée via `createReusableTemplate({ inheritAttrs: false })` pour un DOM identique sans pôle. Fiche service `[type]/[slug].vue` : lien « Pôle de … », « Voir la page dédiée », section « Pôles », onglets conditionnels « Formations » (`programs.service_external_id`) et « Appels » (`application_calls.service_external_id`, en cours / à venir puis clos) |
| `usePeiPage()` / `usePeiBreadcrumb(current, ddeServiceId)` | Cadre commun des rubriques PEI `/entrepreneuriat/{alumni,partenaires,ressources,actualites,statut-etudiant-entrepreneur}` (rubrique `see`) : éditorial, service DDE, hero, fil d'Ariane partagé (`usePeiBreadcrumb`, aussi utilisé par l'accueil et « Nos activités » : DDE = parent du service de `landing_path` `/entrepreneuriat`, sinon clé `entrepreneurship.dde_service_id`, sinon omis ; expose `dde` / `ddeId`, **seule source** du service DDE pour actualités, événements et albums — même règle côté backend `_resolve_dde_service()`), `applySeo({ type? })` (JSON-LD `CollectionPage` par défaut, `WebPage` pour la page SEE) — `await` en tête de page, `applySeo()` en dernier |
| `EntrepreneurshipSeeAgenda` | Panneau agenda de l'appel SEE (`components/entrepreneurship/SeeAgenda.vue`) : badge d'état ouvert / à venir / clos / absent, frise du calendrier (étape de date limite en rouge, ligne ajoutée si aucune ne correspond), bouton externe > formulaire interne > e-mail ; état et cible calculés par `seeCallState` / `seeApplyTarget` / `seeAgendaSteps` (`utils/pei-presentation.ts`) |
| `FaqAccordion` | Accordéon FAQ de `/faq` ; variantes additives `searchable` (défaut `true`), `groupTitles: 'auto' \| 'always'`, `headingLevel: 'h2' \| 'h3'`, `multiple` (ouverture multiple) ; ancres via `scrollToPageAnchor` (Lenis). JSON-LD `FAQPage` partagé : `buildFaqPageJsonLd()` (`utils/faq-jsonld.ts`) ; `usePublicFaqApi().getTree({ categoryPrefix })` |
| `EntrepreneurshipHomeHero` / `JourneyRing` / `StepFeature` / `PhaseCard` | Refonte visuelle de l'accueil PEI et de « Nos activités » : hero plein écran dont chaque image « allume » le mot de même rang du slogan (`hero.slogan`, mots terminés par un point ; tous allumés si le nombre diffère), anneau SVG des dispositifs (segments = liens `#phase-*`), étape en grand format éditorial, cartes « trois phases » en escalier. **Couleur fixe par phase** (`PEI_PHASE_TONES` / `peiStepTone(phase)` dans `utils/pei-presentation.ts` : OSER orange, SEE violet, MTI rouge, Senghor'Innov vert, FSE turquoise, écosystème bleu) — `pei_programs.color` n'est plus lu côté public ni éditable (pastille en lecture seule dans `ProgramForm`). Variantes additives : `EventList variant="agenda"`, `NewsCard variant="featured"\|"compact"`, `PartnerFamilies variant="columns"` + prop `descriptions`, `QuoteBlock impactStats` |
| `EntrepreneurshipPillTabs` / `CohortSection` / `LaureateCard` / `ResourceCard` / `EmptyState` | Blocs publics des rubriques PEI : sous-onglets pilule portés par l'adresse (`?type=`), section de cohorte + carte portrait (vedettes en premier), carte de ressource (téléchargement `?download=1`, lien, vidéo avec vignette YouTube), état vide ; variantes additives `StatsPanel variant="band"`, `PartnerFamilies` (grille unique logo + nom au style de `/a-propos/partenaires`, filtres par famille avec `variant="detailed"`), `CtaBanner href` (mailto, `external` pour un nouvel onglet, slot `note`), `EventList title` |

**Stockage du contenu riche :** Double colonne `*_html` (rendu public) + `*_md` (édition Markdown) pour chaque champ de contenu riche (11 tables, ~20 colonnes).

## Conventions

- **Français avec accents** (é, è, ê, à, ç, ù) obligatoires dans le code et les contenus
- **Nommage de fichiers/dossiers : PAS d'accents ni de caractères spéciaux** (problèmes d'encodage SSH/Docker en production). Utiliser uniquement `[a-z0-9_-]`.
- Champs trilingues : convention additive (`title`, `title_en`, `title_ar` ; `content_html`, `content_en_html`…) pour les domaines à traduction automatique (`autofill_translations` / `useLocalizedField`) ; `*_fr`, `*_en`, `*_ar` pour la FAQ
- Alias : `@bank` → `./bank`
- **Dates limites des appels en GMT** : saisie admin et affichage public en UTC suffixé « GMT », jamais dans le fuseau du navigateur — utiliser `utils/gmt-datetime.ts` (`formatGmtDate`, `formatGmtDateTime`, `toGmtInputValue` / `fromGmtInputValue` pour les `datetime-local`)

## Parallel Sub-agents Strategy

Use multiple sub-agents in parallel for efficiency(10+):
- Search frontend + backend simultaneously
- Explore multiple files/folders at the same time
- Run tests + verifications in parallel after modifications
- **Avant de créer un nouveau composant** : Toujours lancer un sous-agent pour vérifier si un composant similaire existe déjà dans `usenghor_nuxt/app/components/` (rechercher par nom et par fonctionnalité). Évite les redondances et favorise la réutilisation.


## Auto-maintenance de ce fichier

Après chaque modification significative du projet, vérifier si CLAUDE.md reflète toujours l'état actuel et le mettre à jour si nécessaire.

## Active Technologies
- TypeScript (Nuxt 4 / Vue 3), Python 3.14 (FastAPI), Tailwind CSS
- `@toast-ui/editor@3.2.2`, `@toast-ui/editor-plugin-table-merged-cell` (éditeur rich text)
- PostgreSQL 16 (contenu riche en double colonne `*_html` + `*_md`)
- TypeScript (Vue 3 / Nuxt 4) + `@toast-ui/editor@3.2.2`, `@toast-ui/editor-plugin-table-merged-cell`, Tailwind CSS, `@nuxtjs/i18n` (002-toastui-fullscreen-modal)
- N/A (fonctionnalité purement frontend, aucune modification backend/BDD) (002-toastui-fullscreen-modal)
- TypeScript (Nuxt 4 / Vue 3) + Python 3.14 (FastAPI) + Nuxt 4, Vue 3, Tailwind CSS, FastAPI, SQLAlchemy (async) (003-audit-backend-connect)
- PostgreSQL 16 (table `audit_logs` existante) (003-audit-backend-connect)
- Python 3.14 (backend), TypeScript (frontend Nuxt 4 / Vue 3) + FastAPI, SQLAlchemy (async), Pydantic v2, Nuxt 4, Vue 3, Tailwind CSS, TOAST UI Editor (004-fundraising-page)
- PostgreSQL 16 (Docker: `usenghor_postgres` local, `usenghor_db` prod) (004-fundraising-page)
- Python 3.12 (backend FastAPI), TypeScript (frontend Nuxt 4) + FastAPI, aiosmtplib 3.0.1+, Jinja2 3.1.3+ (déjà dans requirements.txt), Nginx, Certbo (005-vps-domain-smtp)
- PostgreSQL 15 (Docker), fichiers .env pour les secrets (005-vps-domain-smtp)
- Python 3.14 (backend FastAPI), TypeScript (frontend Nuxt 4 / Vue 3) + FastAPI, SQLAlchemy (async), Pydantic v2, aiosmtplib, Jinja2, Nuxt 4, Vue 3, Tailwind CSS (006-password-reset-email)
- TypeScript, Vue 3 (Nuxt 4) + Tailwind CSS, `useDarkMode()` composable (existant) (007-diese-decorative-bg)
- N/A — feature purement frontend/visuelle (007-diese-decorative-bg)
- Python 3.14 (backend FastAPI) + TypeScript (frontend Nuxt 4 / Vue 3) + FastAPI, SQLAlchemy (async), Pydantic v2, SurveyJS Form Library (`survey-vue3-ui`), aiosmtplib, Jinja2 (008-survey-campaigns)
- PostgreSQL 16 (Docker: `usenghor_postgres` local, `usenghor_db` prod) — JSONB pour survey_json et response_data (008-survey-campaigns)
- TypeScript (Nuxt 4 / Vue 3) + `@nuxtjs/i18n` (prefix_except_default), `@nuxtjs/sitemap`, `useSeoMeta()` (Nuxt built-in) (009-og-meta-tags)
- N/A — feature purement frontend, lecture seule des donnees existantes (009-og-meta-tags)
- Python 3.14 (FastAPI backend), TypeScript (Nuxt 4 / Vue 3 frontend) + FastAPI, SQLAlchemy (async), Pydantic v2, aiosmtplib, Jinja2, Nuxt 4, Vue 3, Tailwind CSS, @nuxtjs/i18n (010-fundraising-revamp)
- Python 3.14 (backend FastAPI), TypeScript (frontend Nuxt 4 / Vue 3) + FastAPI, SQLAlchemy (async), Pydantic v2, Nuxt 4, Vue 3, Tailwind CSS (012-media-events-news)
- Python 3.14 (FastAPI backend), TypeScript (Nuxt 4 / Vue 3 frontend) + FastAPI, SQLAlchemy (async), Pydantic v2, Nuxt 4, Vue 3, Tailwind CSS (014-link-shortener)
- Python 3.14 (FastAPI backend), TypeScript (Nuxt 4 / Vue 3 frontend) + FastAPI, SQLAlchemy (async), Pydantic v2, Nuxt 4, Vue 3, Tailwind CSS, @nuxtjs/i18n (015-mediatheque)
- TypeScript 5.x (Nuxt 4 / Vue 3 Composition API) — aucune partie Python touchée + Vue 3, Nuxt 4, Tailwind CSS, `@nuxtjs/i18n`, `useMediaApi` composable existant, Font Awesome (icônes). Aucune nouvelle dépendance. (016-mediatheque-direct-upload)
- N/A (backend inchangé). PostgreSQL `media` + `album_media` tables existantes utilisées tel quel. (016-mediatheque-direct-upload)
- TypeScript 5.x (Nuxt 4 / Vue 3 Composition API) + `@toast-ui/editor@3.2.2`, `@toast-ui/editor-plugin-table-merged-cell@3.1.0` (existants) (017-editor-text-color)
- N/A (HTML inline dans colonnes `*_html` existantes, aucune migration SQL) (017-editor-text-color)
- TypeScript 5.x (Nuxt 4 / Vue 3 Composition API) côté frontend, Python 3.14 (FastAPI) côté backend. + Nuxt 4, Vue 3, Tailwind CSS, `@nuxtjs/i18n` ; FastAPI, SQLAlchemy (async), Pydantic v2, `asyncpg`. Pas de nouvelle dépendance ajoutée. (018-governance-media-album)
- PostgreSQL 16 via Docker (`usenghor_postgres` local, `usenghor_db` prod). Tables impactées : `media`, `albums`, `album_media`. Lecture seule de `editorial_contents` au moment de la migration. (018-governance-media-album)
- TypeScript 5.x (Nuxt 4 / Vue 3 Composition API) côté frontend, Python 3.14 (FastAPI) côté backend. + Nuxt 4, Vue 3, Tailwind CSS, `@nuxtjs/i18n`, TOAST UI Editor 3.2.2 ; FastAPI, SQLAlchemy (async), Pydantic v2, `asyncpg`. Pas de nouvelle dépendance ajoutée. (019-faq-backoffice)
- PostgreSQL 16 via Docker (`usenghor_postgres` local, `usenghor_db` prod). Nouvelles tables : `faq_categories`, `faq_entries`. Réutilisation : `users` (FK auteur), `audit_logs` (traces), permissions/rôles existants. (019-faq-backoffice)
- Infrastructure / DevOps : Docker Compose v3.8 (`docker-compose.monitoring.yml`), Prometheus 2.55.1 (TSDB, rétention 30j / 4.5 GB), Grafana 11.4.0 (provisioning par fichier, auth admin via env, sign-up & anonyme OFF), node-exporter 1.8.2, cAdvisor 0.49.1. Nginx reverse-proxy `monitoring.<DOMAINE>` + rate limiting + TLS Let's Encrypt. Réseau Docker `usenghor_network` partagé. Aucun port public pour Prometheus/exporters. Pilotage via `./deploy.sh monitoring {up|down|logs|status}`. (020-monitoring-stack)

## Recent Changes
- appels-service-ecole-doctorale: rattachement d'un appel à un service — colonne `application_calls.service_external_id` (UUID sans FK, index), filtre `service_id` sur `GET /api/public/application-calls` et `/api/admin/application-calls` (422 si UUID invalide), sélecteur « Service associé » (groupé par secteur, `groupServicesBySector` dans `useReferenceData.ts`) dans `admin/candidatures/appels/{nouveau,[id]/edit}.vue` ; onglet public « Appels » de la fiche service (i18n `organizationDetail.calls`) ; `CardCall` pointe vers `/actualites/appels/{slug}` (l'ancien `/candidatures/{slug}` était en 404) ; migration `052_application_calls_service_ecole_doctorale.sql` + rollback : présentation de l'École doctorale = texte du programme « Cohorte 5 » (FR/EN/AR), programmes doctoraux détachés du service (restent au catalogue), menu « Se former › Doctorat » → `/a-propos/organisation/service/ecole-doctorale` (table `migration_052_backup` pour le rollback)
- pei-refonte-accueil-activites: refonte visuelle de `/entrepreneuriat` et `/entrepreneuriat/activites` (maquette canvas « Mini-site PEI — refonte »), barre de navigation et pied de page inchangés ; couleur des dispositifs imposée par la phase ; résolution unique de la DDE (parent du pôle puis clé éditoriale) côté front (`usePeiBreadcrumb`) et tableau de bord admin ; textes d'aide de la page éditoriale « Entrepreneuriat » réécrits (`hero.badge` de l'accueil retiré de l'admin, non affiché) ; migration `051_pei_impact_family_keys.sql` + rollback (3 chiffres d'impact `entrepreneurship.impact.stats.{1..3}.{value,label}`, descriptions `entrepreneurship.partners.family.{academic,support,international}.description`, texte d'impact remplacé seulement s'il vaut encore la valeur seedée ; 138 → 147 clés `entrepreneurship.*`) ; correctif du lien « Historique, vision et missions du pôle » (`ddeLink` supprimé par 026)
- 026-pei-org-navigation-launch: niveau « pôle » des services — colonnes `services.parent_id` (FK `SET NULL`) et `services.landing_path` (chemin interne sans préfixe de langue), trigger `services_check_hierarchy` (un seul niveau, même secteur, pas de changement de secteur d'un parent) doublé par `OrganizationService._validate_hierarchy` (422 / 409, messages français) ; pôle PEI seedé (identifiant fixe `5e1c0050-0000-4000-8000-00000000e1ab`, `/entrepreneuriat`) sous la DDE ; `with-services` et `/sectors/{code}` imbriquent les pôles dans `children`, fiche publique `parent` / `children` ; backoffice : « Service parent », « Page dédiée », liste hiérarchique, avertissement de suppression ; entrée « Entreprendre à Senghor » (menu « Plus » › Nous connaître, trilingue, `fa-solid fa-rocket`) et lien du pied de page ; lien court `/r/pei`, génération des codes qui saute les codes pris ; plan du site corrigé (`secteur/{code}`, `service/{slug}`, pôles inclus, trois langues via `_i18nTransform`) ; **correctif** : les lectures publiques des secteurs supprimaient les services inactifs (réaffectation d'une relation `delete-orphan`) → réponse construite par `build_public_sector` ; migration `050_services_parent_landing.sql` + rollback (**050 avant les rollbacks 049 → 045**, pôle conservé s'il a du contenu)
- 025-pei-see-status-page: page `/entrepreneuriat/statut-etudiant-entrepreneur` (guide SEE éditorial, six leviers, conditions et pièces **de l'appel d'abord, éditorial en secours**, panneau agenda collant `EntrepreneurshipSeeAgenda`, FAQ, lien PÉPITE France, CTA) ; appel désigné par `entrepreneurship.see.call_slug`, état dérivé ouvert / à venir / clos / absent (page toujours 200, aucun lien vers un formulaire fermé) ; filtre additif `GET /api/public/faq?category_prefix=` (préfixe littéral, 422 hors `^[a-z0-9_-]{1,60}$`) ; catégories FAQ au code réservé `see-*` (visibles aussi sur `/faq`) ; migration `049_pei_see_page.sql` + rollback (65 clés `entrepreneurship.see.*` → 138 clés `entrepreneurship.*`, 4 catégories, 8 questions dont 6 brouillons à compléter) ; « Traduire les champs manquants » du pôle traduit aussi les entrées FAQ `see-*` publiées (compteur `faq_see`) ; bouton rouge de `EntrepreneurshipSubNav` en `aria-current="page"` sur la page ; i18n `pei.see.*`
- 024-pei-public-alumni-resources-news: quatre rubriques publiques du mini-site PEI — `/entrepreneuriat/alumni` (onglets `?type=student_entrepreneur`, bandeau de 3 chiffres éditoriaux, sections par cohorte, encart mentor `mailto:`), `/entrepreneuriat/partenaires` (familles détaillées), `/entrepreneuriat/ressources` (albums de la médiathèque du service DDE via `MediaLibraryTab` + boîte à outils groupée par catégorie FR normalisée), `/entrepreneuriat/actualites` (actualités DDE par lots de 12, événements à venir / passés par lots de 10, filtres serveur) ; composable `usePeiPage` ; migration `048_pei_public_pages_keys.sql` (26 clés, 73 clés `entrepreneurship.*` déclarées) ; i18n `pei.{common,alumni,partners,resources,news}` ; aucun changement backend ; table `cohortTypeForLaureateType` partagée (déjà auto-importée depuis `useEntrepreneurshipApi`, ne pas la redéclarer)
- 023-pei-public-home-activities: mini-site public PEI — pages SSR `/entrepreneuriat` (hero slider, sous-nav, présentation + chiffres, parcours, citation, actualités DDE, partenaires, CTA) et `/entrepreneuriat/activites` (bloc par phase, ancres `#phase-*`, événements à venir de la DDE) ; `PageHero` étendu (`images`, `badge`, `actions`) ; carte `ActualitesNewsCard` extraite de `/actualites` ; filtre `service_id` + `order=asc|desc` sur `GET /api/public/events` ; migration `047_pei_activities_hero_keys.sql` (4 clés du hero de « Nos activités », 47 clés `entrepreneurship.*` au total) ; namespace i18n `pei` ; copie éditoriale FR dans les trois langues ; ancres via `scrollToPageAnchor` (Lenis) ; JSON-LD `usePeiJsonLd()`
- 022-pei-laureates-partners: portraits (lauréats FSE / étudiants-entrepreneurs) et partenaires du pôle PEI — SQL `16_entrepreneurship.sql` + migration `046_pei_laureates_partners.sql` (tables `pei_laureates` avec FK `cohort_id` RESTRICT, `pei_partners` avec PK/FK `partner_id` CASCADE vers `partners`, rattachement initial par motifs sans création) ; rollback 046 **avant** le rollback 045 ; ordre des portraits par cohorte et des partenaires par famille (`_reorder` scopé) ; 409 « Cohorte utilisée par N lauréats » ; admin `/admin/entrepreneuriat/{laureats,partenaires}` ; endpoints publics `/api/public/entrepreneurship/{laureates,partners}` ; verbatim ≤ 600 caractères par langue ; aucune nouvelle permission
- 021-pei-entrepreneurship-core: socle du Pôle Entrepreneuriat et Innovation — SQL `16_entrepreneurship.sql` + migration `045_entrepreneurship.sql` (tables `pei_programs`, `pei_cohorts`, `pei_resources`, seeds FR, 43 clés éditoriales), API `/api/admin/entrepreneurship/*` et `/api/public/entrepreneurship/*`, section admin « Entrepreneuriat (PEI) » (`/admin/entrepreneuriat`), page éditoriale `entrepreneurship`, permissions `entrepreneurship.*` ; lancer « Traduire les champs manquants » après la migration
- call-type-candidature-masque: le type d'appel `application` (« Candidature ») est déprécié et fusionné dans `training` (« Formation ») — migration `044_call_type_application_vers_training.sql` (données `application_calls` + `project_calls`, table de sauvegarde pour rollback) ; option masquée dans les filtres publics et les formulaires admin, valeur conservée dans l'ENUM `call_type` pour compatibilité
- appels-sync-atomique: sauvegarde des listes d'un appel (critères, prises en charge, documents, calendrier) via `PUT /api/admin/application-calls/{id}/details` (une transaction, idempotent, diff par `id`) — remplace le cycle « tout supprimer / tout recréer » qui produisait des doublons ; migration `042_application_calls_dedup_sous_tables.sql` pour nettoyer l'existant
- 020-monitoring-stack: socle observabilité (Prometheus + Grafana + node-exporter + cAdvisor) — métriques système et conteneurs, sans instrumentation applicative ; rétention 30j, accès HTTPS via `monitoring.<DOMAINE>` derrière Nginx
- 019-faq-backoffice: page FAQ publique trilingue (`/faq`) + backoffice (entrées et catégories) avec audit complet, repli FR, réordonnancement, JSON-LD
- 016-mediatheque-direct-upload: upload direct de fichiers dans la médiathèque (composant + composable, sans album)
- 001-migrate-toastui-editor: Migré EditorJS → TOAST UI Editor (composants, composable, schémas Pydantic, 11 pages admin, 11 pages publiques, nettoyage complet)
