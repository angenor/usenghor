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

**PostgreSQL 16** via Docker (`docker-compose.yml` dans `usenghor_backend/`). Le schéma SQL complet est dans `usenghor_backend/documentation/modele_de_données/services/` avec un fichier orchestrateur [`main.sql`](usenghor_backend/documentation/modele_de_données/services/main.sql) qui inclut 16 fichiers via `\i` :

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

**Stockage du contenu riche :** Double colonne `*_html` (rendu public) + `*_md` (édition Markdown) pour chaque champ de contenu riche (11 tables, ~20 colonnes).

## Conventions

- **Français avec accents** (é, è, ê, à, ç, ù) obligatoires dans le code et les contenus
- **Nommage de fichiers/dossiers : PAS d'accents ni de caractères spéciaux** (problèmes d'encodage SSH/Docker en production). Utiliser uniquement `[a-z0-9_-]`.
- Champs trilingues : `*_fr`, `*_en`, `*_ar`
- Alias : `@bank` → `./bank`

## Parallel Sub-agents Strategy

Use multiple sub-agents in parallel for efficiency(10 max):
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
- call-type-candidature-masque: le type d'appel `application` (« Candidature ») est déprécié et fusionné dans `training` (« Formation ») — migration `044_call_type_application_vers_training.sql` (données `application_calls` + `project_calls`, table de sauvegarde pour rollback) ; option masquée dans les filtres publics et les formulaires admin, valeur conservée dans l'ENUM `call_type` pour compatibilité
- appels-sync-atomique: sauvegarde des listes d'un appel (critères, prises en charge, documents, calendrier) via `PUT /api/admin/application-calls/{id}/details` (une transaction, idempotent, diff par `id`) — remplace le cycle « tout supprimer / tout recréer » qui produisait des doublons ; migration `042_application_calls_dedup_sous_tables.sql` pour nettoyer l'existant
- 020-monitoring-stack: socle observabilité (Prometheus + Grafana + node-exporter + cAdvisor) — métriques système et conteneurs, sans instrumentation applicative ; rétention 30j, accès HTTPS via `monitoring.<DOMAINE>` derrière Nginx
- 019-faq-backoffice: page FAQ publique trilingue (`/faq`) + backoffice (entrées et catégories) avec audit complet, repli FR, réordonnancement, JSON-LD
- 016-mediatheque-direct-upload: upload direct de fichiers dans la médiathèque (composant + composable, sans album)
- 001-migrate-toastui-editor: Migré EditorJS → TOAST UI Editor (composants, composable, schémas Pydantic, 11 pages admin, 11 pages publiques, nettoyage complet)
