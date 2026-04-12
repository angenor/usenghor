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

## Recent Changes
- 016-mediatheque-direct-upload: upload direct de fichiers dans la médiathèque (composant + composable, sans album)
- 001-migrate-toastui-editor: Migré EditorJS → TOAST UI Editor (composants, composable, schémas Pydantic, 11 pages admin, 11 pages publiques, nettoyage complet)
