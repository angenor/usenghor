# Rapport de réalisation — Site web de l'Université Senghor

## 1. Présentation du projet

Le projet consiste en la conception et le développement du site web institutionnel de l'**Université Senghor** (Alexandrie, Égypte). Le site est **trilingue** (français, anglais, arabe avec support RTL) et couvre l'ensemble des besoins de communication, de gestion académique et d'administration de l'université.

## 2. Architecture technique

Le projet est organisé en **monorepo** avec deux composantes principales :

| Composante | Technologies |
|------------|-------------|
| **Frontend** | Nuxt 4, Vue 3, Tailwind CSS, TypeScript |
| **Backend** | FastAPI, Python 3.14, PostgreSQL 16 |
| **Infrastructure** | Docker, Nginx, SSL/TLS |

### Schéma d'architecture

```
┌─────────────────────────────────────────────────┐
│                    Nginx                         │
│           (reverse proxy + SSL)                  │
├────────────────────┬────────────────────────────┤
│                    │                            │
│  ┌─────────────┐   │   ┌──────────────────┐     │
│  │   Nuxt SSR  │   │   │  FastAPI Backend  │     │
│  │  (port 3000)│   │   │   (port 8000)     │     │
│  └─────────────┘   │   └───────┬──────────┘     │
│                    │           │                 │
│                    │   ┌───────┴──────────┐     │
│                    │   │   PostgreSQL 16   │     │
│                    │   └──────────────────┘     │
└─────────────────────────────────────────────────┘
```

## 3. Fonctionnalités développées

### 3.1 Site public

- **Page d'accueil** avec sections dynamiques (héros, actualités, formations, partenaires)
- **Formations** : catalogue de programmes, détails par formation, semestres et cours
- **Actualités et événements** : système de publication avec catégories et tags
- **Organisation** : présentation des secteurs, services et équipes
- **Campus** : informations sur les campus avec géolocalisation (Leaflet)
- **Partenaires** : répertoire des partenariats institutionnels
- **Projets** : vitrine des projets de recherche et institutionnels
- **Candidatures** : appels à candidatures et formulaires en ligne
- **Carrières** : offres d'emploi et opportunités
- **Éditorial** : contenu rédactionnel riche (EditorJS)
- **Newsletter** : inscription et gestion des abonnés

### 3.2 Espace d'administration

- **Tableau de bord** avec statistiques
- **Gestion CRUD complète** pour toutes les entités (formations, actualités, événements, partenaires, projets, campus, etc.)
- **Éditeur de contenu riche** (EditorJS avec support images, tableaux, listes, citations, etc.)
- **Gestion des médias** : upload, albums, galeries
- **Gestion des utilisateurs** : rôles, permissions, journal d'audit (RBAC)
- **Export** : génération de fichiers Excel et PDF

### 3.3 Internationalisation

- **3 langues** : français (par défaut), anglais, arabe
- **~1 800 clés de traduction** réparties en 24 fichiers par langue
- **Support RTL** complet pour l'arabe
- **Stratégie d'URL** : préfixe sauf pour le français (`/en/`, `/ar/`)

## 4. Base de données

Le schéma PostgreSQL est organisé en **12 services fonctionnels** couvrant **~65 tables** :

| Service | Fonction | Tables principales |
|---------|----------|-------------------|
| Core | Référentiel | countries |
| Identity | Authentification | users, roles, permissions, audit_logs |
| Media | Gestion de fichiers | media, albums |
| Organization | Structure | sectors, services, service_team |
| Campus | Campus | campuses, campus_team |
| Partner | Partenariats | partners |
| Academic | Formations | programs, program_courses, program_semesters |
| Application | Candidatures | application_calls, applications |
| Content | Contenu | events, news, tags |
| Project | Projets | projects, project_categories |
| Newsletter | Communication | newsletter_subscribers, newsletter_campaigns |
| Editorial | Éditorial | editorial_categories, editorial_contents |

Un fichier orchestrateur `main.sql` assure la création ordonnée de l'ensemble du schéma avec gestion des dépendances.

## 5. Métriques du projet

| Indicateur | Valeur |
|------------|--------|
| Composants Vue | 135 |
| Pages | 108 |
| Composables (logique réutilisable) | 67 |
| Stores Pinia | 5 |
| Endpoints API (fichiers routeurs) | 51 |
| Modèles de données (backend) | 15 |
| Services métier (backend) | 15 |
| Tables en base de données | ~65 |
| Dépendances frontend | 57 |
| Dépendances backend | 37 |
| Langues supportées | 3 |
| Clés de traduction | ~1 800 |

## 6. Arborescence du site

[Consulter le sitemap visuel interactif](https://share.octopus.do/embed/g8jxkzw7ooe)

## 7. Infrastructure et déploiement

### Environnement de production

Le déploiement repose sur **Docker Compose** avec 5 conteneurs :

1. **Nginx** — Reverse proxy, SSL, compression gzip, rate limiting
2. **Nuxt (SSR)** — Rendu côté serveur pour le SEO
3. **FastAPI** — API REST avec documentation Swagger
4. **PostgreSQL 16** — Base de données avec persistance par volume
5. **Adminer** — Interface d'administration BDD (optionnel)

### Sécurité

- Authentification JWT avec tokens de rafraîchissement
- Contrôle d'accès basé sur les rôles (RBAC)
- En-têtes de sécurité HTTP (X-Frame-Options, X-Content-Type-Options, etc.)
- Rate limiting sur les endpoints API (10 req/s) et général (30 req/s)
- Séparation stricte des routes publiques et administratives

### Déploiement automatisé

Un script `deploy.sh` gère l'intégralité du cycle de vie :
- Installation et configuration initiale du serveur
- Déploiement et mises à jour via Git
- Gestion SSL (Let's Encrypt)
- Sauvegardes de la base de données
- Monitoring (status, logs)

## 8. Bibliothèques et outils principaux

### Frontend

| Catégorie | Outils |
|-----------|--------|
| Framework | Nuxt 4, Vue 3, TypeScript |
| Styles | Tailwind CSS, dark mode |
| Icônes | FontAwesome (solid, regular, brands) |
| Éditeur | EditorJS + plugins |
| Animations | GSAP, Lenis (smooth scroll) |
| Cartes | Leaflet, amCharts 5 |
| État | Pinia |
| Tests | Playwright, Vitest |

### Backend

| Catégorie | Outils |
|-----------|--------|
| Framework | FastAPI |
| ORM | SQLAlchemy 2 (async) |
| Auth | JWT (python-jose), bcrypt |
| Validation | Pydantic 2 |
| Images | Pillow |
| Export | Openpyxl (Excel), ReportLab (PDF) |
| Email | Aiosmtplib, Jinja2 (templates) |
| Tests | Pytest, Httpx |

## 9. Conventions et bonnes pratiques

- **Code et contenus en français** avec accents
- **Nommage de fichiers** : ASCII uniquement (`[a-z0-9_-]`) pour la compatibilité SSH/Docker
- **Champs trilingues** : suffixes `*_fr`, `*_en`, `*_ar`
- **Auto-import** des composants et composables (convention Nuxt)
- **Routing basé sur les fichiers** (convention Nuxt)
- **Architecture en couches** côté backend : routeurs → services → modèles
- **Source de vérité** : le schéma SQL pilote les modifications de structure
