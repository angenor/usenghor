# Document d'Architecture Technique — Université Senghor (usenghor-francophonie.org)

> Version : 1.0 — Mise à jour : 2026-05-17
> Périmètre : site institutionnel trilingue (FR/EN/AR) + backoffice de gestion + stack monitoring
> Branche active : `020-monitoring-stack`

---

# 1. Contexte : Besoins fonctionnels

## 1.1 Contexte général

L'Université Senghor (Alexandrie, Égypte), opérateur direct de la Francophonie, dispose historiquement de plusieurs sites éparpillés (campus, départements, projets). Le présent projet **centralise** ces présences numériques au sein d'une plateforme unique, multilingue, gérée par un backoffice unifié, et capable d'absorber l'ensemble des activités institutionnelles, académiques, éditoriales et événementielles de l'université.

> *Note : la mention du « pavillon de la francophonie / CAOP / négociatrices francophones » présente dans la version initiale du document concerne un autre projet (epavillon) et a été retirée du périmètre.*

## 1.2 Objectifs métiers

1. **Centraliser et uniformiser** les contenus institutionnels (présentation, gouvernance, stratégie, organisation, campus, partenaires) en un site unique trilingue (FR/EN/AR, RTL inclus).
2. **Industrialiser la gestion** des contenus dynamiques : actualités, événements, appels à candidature, projets, FAQ, médiathèque, newsletter, levées de fonds.
3. **Numériser les processus de candidature** (formations, projets, partenariats) avec formulaires dynamiques, suivi de dossiers et reporting.
4. **Outiller la communication** : newsletter (abonnement + campagnes), envoi transactionnel (confirmations, réinitialisation mot de passe), réseaux sociaux, sondages.
5. **Gouverner finement les accès** via RBAC (utilisateurs / rôles / permissions) et un journal d'audit complet.
6. **Observer** la santé technique de la plateforme (système + conteneurs Docker) via une stack de monitoring dédiée.

## 1.3 Liste consolidée des besoins fonctionnels

### Site public (visiteurs anonymes ou authentifiés)

| # | Domaine | Besoin |
|---|---------|--------|
| F-01 | Trilinguisme | Navigation complète FR/EN/AR avec gestion RTL pour l'arabe, URLs préfixées sauf locale par défaut |
| F-02 | Accueil & narration | Page d'accueil animée (GSAP/Lenis/Scrollama), storytelling institutionnel |
| F-03 | À propos | Histoire, gouvernance, stratégie, organisation (secteurs/services), valeurs, chiffres-clés |
| F-04 | Équipes | Fiches membres rattachées aux services et campus, carte interactive (Leaflet) |
| F-05 | Campus & partenaires | Annuaire campus + partenaires, géolocalisation, fiches détaillées |
| F-06 | Formations | Catalogue (Masters, Doctorats, Certificats, CLOMs), pages programme, semestres, cours, compétences, débouchés |
| F-07 | Candidatures | Appels à candidature (programmes / projets / partenariats), formulaires dynamiques (SurveyJS), suivi de dossier candidat |
| F-08 | Actualités | Liste / détail / tags / recherche, mise en avant éditoriale |
| F-09 | Événements | Liste / détail / inscription, types d'événement, partenaires associés |
| F-10 | Projets | Vitrine projets institutionnels, catégories, appels à projets |
| F-11 | Médiathèque | Albums, galerie, lightbox, recherche, upload direct (admin) |
| F-12 | Levées de fonds | Pages campagnes éditoriales, contributeurs, manifestation d'intérêt, emails transactionnels |
| F-13 | FAQ | Catégories trilingues, entrées, JSON-LD SEO, repli FR |
| F-14 | Newsletter | Abonnement / désabonnement (token), confirmation par e-mail |
| F-15 | Compte utilisateur | Inscription, login, reset password par e-mail, profil, sessions JWT |
| F-16 | SEO | Sitemap dynamique, hreflang multilingue, balises Open Graph, Schema.org `CollegeOrUniversity` |
| F-17 | Liens courts | Réducteur d'URL interne avec validation de domaines |
| F-18 | Recherche & filtres | Filtrage par tag, catégorie, langue, type de contenu |

### Backoffice (utilisateurs authentifiés et autorisés)

| # | Domaine | Besoin |
|---|---------|--------|
| B-01 | Authentification | Login, refresh token, reset password, verrouillage sur changement mot de passe |
| B-02 | RBAC | Gestion utilisateurs, rôles hiérarchisés, permissions atomiques (`code`), super-admin |
| B-03 | Audit | Journal d'audit (action, table, ancien/nouveau JSONB, IP, user-agent) sur toutes les écritures critiques |
| B-04 | Contenus éditoriaux | CRUD actualités, événements, formations, projets, FAQ, partenaires, équipes, campus, secteurs/services |
| B-05 | Édition riche | Éditeur TOAST UI (WYSIWYG + Markdown), stockage double `*_html` + `*_md`, plein écran, couleurs de texte |
| B-06 | Médiathèque | Albums, upload direct sans album, organisation, tagging, gouvernance des textes fondateurs |
| B-07 | Formulaires dynamiques | Construction et publication de campagnes de sondages SurveyJS trilingues, collecte JSONB, analytics |
| B-08 | Candidatures | Configuration des appels, critères d'éligibilité, documents requis, gestion des dossiers, statuts |
| B-09 | Newsletter | Gestion abonnés (token de désinscription), création/édition campagnes, statistiques d'envoi |
| B-10 | Levées de fonds | Construction de pages, sections éditoriales, contributeurs, médias |
| B-11 | Editorial config | Contact, réseaux sociaux, mentions légales, valeurs, chiffres-clés, paramètres globaux |
| B-12 | E-mails transactionnels | Templates Jinja2 (reset, confirmation candidature, manifestation d'intérêt, etc.), envoi async aiosmtplib |
| B-13 | Référentiels | Pays, tags, catégories FAQ, catégories projets, liens courts |
| B-14 | Statistiques | Dashboards candidatures, newsletter, projets, contenus |

### Plate-forme & exploitation

| # | Domaine | Besoin |
|---|---------|--------|
| P-01 | Déploiement | Pilotage `./deploy.sh` (setup, deploy, update, status, logs, restart, ssl, backup, monitoring) |
| P-02 | TLS | Let's Encrypt + renouvellement automatique (crontab 3 h), HTTPS obligatoire sur tous les domaines |
| P-03 | Reverse-proxy | Nginx + rate limiting (`/api` 10 r/s, frontend 30 r/s, monitoring 30 r/min, login monitoring 5 r/min) |
| P-04 | Monitoring | Prometheus + Grafana + node-exporter + cAdvisor, rétention 30 j, sous-domaine `monitoring.<DOMAINE>` |
| P-05 | Backups | Dump PostgreSQL à la demande, snapshots volumes Prometheus / Grafana |
| P-06 | Résilience | Redémarrage automatique des conteneurs (`unless-stopped`), healthchecks Postgres |

---

# 2. Besoins non fonctionnels

## 2.1 Performance
- TTFB cible < 500 ms pour les pages publiques rendues SSR (Nuxt 4).
- API publiques (`/api/public/*`) : 95p < 300 ms en charge nominale.
- Pages riches (médiathèque, accueil animée) : LCP < 2,5 s sur connexion 4G.

## 2.2 Disponibilité
- Cible : 99,5 % (hors fenêtre de maintenance planifiée).
- Auto-restart de tous les conteneurs (`restart: unless-stopped`) ; healthcheck `pg_isready` sur PostgreSQL conditionnant le démarrage du backend.
- Page de maintenance statique servie par Nginx en cas d'erreur upstream 502/503/504.

## 2.3 Sécurité
- TLS 1.2 / 1.3 uniquement, HSTS 2 ans, headers `X-Frame-Options`, `X-Content-Type-Options`, CSP indirect.
- JWT (access 30 min, refresh 7 j), invalidation des sessions sur changement mot de passe.
- RBAC granulaire (permissions atomiques par `code`), super-admin bypass explicite et journalisé.
- Audit exhaustif (`audit_logs` JSONB + IP + user-agent) sur toutes mutations sensibles.
- Rate-limiting Nginx anti brute-force (login monitoring 5 r/min strict).
- Aucun port public exposé pour PostgreSQL, Prometheus, exporters, backend, frontend (tout passe par Nginx).
- Secrets cryptographiques (POSTGRES_PASSWORD, APP_SECRET_KEY, JWT_SECRET_KEY) générés via `openssl rand` au `setup`, jamais versionnés.

## 2.4 Conformité & vie privée
- Journal d'audit conservé en base avec horodatage TZ pour traçabilité.
- Stockage local des médias dans un volume Docker dédié (`uploads_data`).
- Désabonnement newsletter par token unique (RGPD-friendly).

## 2.5 Maintenabilité
- Code organisé par domaine métier (16 services SQL ; routers FastAPI publics vs admin ; composants Nuxt par feature).
- Trilinguisme systémique (`*_fr`, `*_en`, `*_ar`).
- Contenu riche stocké en double colonne `*_html` (rendu) + `*_md` (édition) — 11 tables concernées.
- Migrations SQL versionnées (`migrations/00X_*.sql`) + orchestrateur `main.sql`.

## 2.6 Observabilité
- Stack monitoring isolée (réseau Docker partagé `usenghor_network`, pas de port public).
- Rétention 30 jours / 4,5 GB côté Prometheus.
- Deux tableaux de bord prêts à l'emploi (Node Exporter Full, cAdvisor) provisionnés automatiquement.
- Logs conteneurs accessibles via `./deploy.sh logs` et `./deploy.sh monitoring logs`.

## 2.7 Portabilité
- Tout exécutable via Docker Compose (applicatif + monitoring séparés).
- Stack indépendante du fournisseur cloud (déployée sur VPS bare-metal 137.74.117.231, portable ailleurs).

## 2.8 Internationalisation & accessibilité
- FR (défaut), EN, AR avec RTL.
- Dark mode contrôlable manuellement (classe `dark` Tailwind).
- Police variable Inter, contrastes conformes WCAG AA pour les compositions standard.

---

# 3. Représentation fonctionnelle

## 3.1 Acteurs

- **Visiteur anonyme** : consulte contenu public, s'abonne newsletter, candidate via formulaires publics.
- **Utilisateur authentifié** : suit ses candidatures, gère son profil.
- **Éditeur** : rédige actualités, événements, FAQ ; gère médias.
- **Administrateur métier** : gère formations, campus, équipes, projets, levées de fonds, sondages.
- **Super-administrateur** : gère utilisateurs / rôles / permissions, consulte audit, paramètres globaux.
- **Exploitant DevOps** : pilote `./deploy.sh`, supervise via Grafana.

## 3.2 Cartographie fonctionnelle (à dessiner)

> **Schéma à produire (diagrams.net)** : carte des capacités regroupées en 6 grands domaines, chacun en boîte avec sous-boîtes.
>
> 1. **Présence & Contenu institutionnel** : Accueil, À propos, Stratégie, Gouvernance, Organisation, Valeurs.
> 2. **Académique & Candidatures** : Formations, Appels, Dossiers, Documents, Critères.
> 3. **Vie de l'université** : Actualités, Événements, Projets, Partenaires, Campus.
> 4. **Engagement & Communauté** : Newsletter, Levées de fonds, Sondages, FAQ, Médiathèque.
> 5. **Sécurité & Gouvernance** : Identités, Rôles, Permissions, Audit, Liens courts.
> 6. **Plateforme & Exploitation** : Déploiement, Reverse-proxy, Monitoring, Backups, TLS.
>
> Relier les domaines par les flux principaux (ex. : *Candidatures* → *Identité* pour la création de compte ; *Levées de fonds* → *E-mail transactionnel*).

## 3.3 Parcours utilisateurs majeurs

1. **Candidat international** : Découverte formations → consultation appel → création compte → soumission dossier SurveyJS → suivi via espace personnel → notifications e-mail.
2. **Donateur** : Page levée de fonds → lecture sections éditoriales → manifestation d'intérêt → confirmation par e-mail → suivi via newsletter.
3. **Éditeur** : Login → rédaction actualité (TOAST UI) → publication trilingue → trace dans `audit_logs`.
4. **Super-admin** : Gestion permissions → consultation audit → backup base → consultation Grafana.

---

# 4. Représentation applicative

## 4.1 Vue d'ensemble

Application **monolithe modulaire** organisée en deux briques :

```
┌─────────────────────────────────────────┐      ┌──────────────────────────────┐
│   Frontend Nuxt 4 (SSR)                 │      │   Backend FastAPI            │
│   Vue 3 + Pinia + i18n + Tailwind       │ ───► │   Async (SQLAlchemy 2.0)     │
│   GSAP / Lenis / Leaflet / TOAST UI /   │ HTTPS│   JWT / RBAC / Audit         │
│   SurveyJS / AmCharts                   │      │   aiosmtplib + Jinja2        │
└─────────────────────────────────────────┘      └──────────────┬───────────────┘
                                                                 │
                                                                 ▼
                                                       ┌──────────────────────┐
                                                       │  PostgreSQL 15-16    │
                                                       │  16 services SQL     │
                                                       │  Volumes durables    │
                                                       └──────────────────────┘
```

## 4.2 Frontend (Nuxt 4)

- **Rendu** : SSR par défaut + hydratation Vue 3 ; routing fichier-basé (`app/pages`).
- **State** : Pinia (`auth`, `editorialContent`, `footerData`, `keyFigures`).
- **i18n** : `@nuxtjs/i18n` (FR/EN/AR), stratégie `prefix_except_default`, RTL automatique.
- **Composants** : ~166 composants organisés par feature (`team/`, `faq/admin/`, `mediatheque/`, etc.) ; **81 composables** (`useApi`, `useApiBase`, `usePublicCampusTeamApi`, `useToastUIEditor`, `useFaqApi`, `useMediaApi`, …).
- **Auth API** : deux familles strictes — `useApi()` pour `/api/admin/*` et `/api/auth/*` (JWT) ; `useApiBase()` + `$fetch` pour `/api/public/*`.
- **Édition riche** : TOAST UI Editor 3.2.2 (patch `prosemirror-state` pour compat Nuxt 4) + plugin `table-merged-cell`, extension couleur de texte custom.
- **Formulaires dynamiques** : SurveyJS (`survey-vue3-ui`) avec i18n intégré.
- **Cartographie & visualisations** : Leaflet (campus, équipes), AmCharts 5 (data géospatiale), `@svg-maps/world`.
- **Animations** : GSAP + ScrollTrigger, smooth scroll Lenis, scroll-driven Scrollama.
- **SEO** : `@nuxtjs/sitemap`, `useSeoMeta`, JSON-LD `CollegeOrUniversity`, hreflang multilingue, Open Graph.
- **Tests** : Vitest, `@vue/test-utils`, Playwright pour E2E.

## 4.3 Backend (FastAPI)

- **Framework** : FastAPI 0.109+, Python 3.14.
- **Persistance** : SQLAlchemy 2.0 (Mapped types) + `asyncpg`. Mixins `UUIDMixin`, `TimestampMixin`.
- **Validation** : Pydantic v2 (DTOs séparés des modèles ORM).
- **Routers** : ~23 routers publics (`/api/public/*`, sans auth) + ~38 routers admin (`/api/admin/*`, JWT obligatoire) + `auth.py`.
- **Auth** : JWT (access 30 min / refresh 7 j) via `python-jose`, hash bcrypt, classe `CurrentUser` injectée comme dépendance.
- **Autorisation** : `PermissionChecker("permission.code")` + décorateur `@require_permission(...)`. Super-admin bypass explicite.
- **E-mails** : `EmailService` (aiosmtplib + TLS Gmail), templates Jinja2 dans `app/templates/email/` (reset password, manifestation d'intérêt, confirmation sondage, etc.). Champs sensibles automatiquement retirés des logs.
- **Modèles ORM** : 19 fichiers organisés par domaine (`identity.py`, `academic.py`, `content.py`, `application.py`, `fundraising.py`, …).
- **Stockage médias** : filesystem local par défaut (`/var/www/uploads`, exposé via `StaticFiles`), abstraction `storage_type: "local" | "s3"` prête.
- **Audit** : middleware automatique enregistrant `(user, action, table, record_id, old, new, ip, user-agent)` en JSONB.
- **Tâches planifiées** : absent (pas de Celery / APScheduler) — extensibilité prévue.

## 4.4 Vue logique (à dessiner)

> **Schéma à produire (diagrams.net)** : vue en couches.
>
> ```
> [Navigateurs]
>      │ HTTPS
> [Nginx reverse-proxy] ── (rate limit, TLS termination) ── [Page maintenance statique]
>      ├── /         ────────► [Nuxt SSR]
>      ├── /api/*    ────────► [FastAPI]
>      ├── /uploads/ ────────► [Volume uploads_data]
>      └── monitoring.<DOMAINE> ────► [Grafana]
> [FastAPI] ──► [PostgreSQL]
> [FastAPI] ──► [SMTP Gmail]
> [Prometheus] ◄── (scrape) ── [node-exporter] + [cAdvisor]
> [Grafana]    ◄── (datasource) ── [Prometheus]
> ```

---

# 5. Représentation des infrastructures

## 5.1 Vue de déploiement

**Cible** : VPS Linux unique (IP 137.74.117.231), Docker Engine + Docker Compose.

### Stack applicative — `docker-compose.prod.yml`

| Conteneur | Image | Port interne | Volumes | Healthcheck |
|-----------|-------|--------------|---------|-------------|
| `usenghor_db` | postgres:15-alpine | 5432 | `postgres_data` | `pg_isready` |
| `usenghor_backend` | build local (FastAPI) | 8000 | `uploads_data` | dépend de `db:healthy` |
| `usenghor_frontend` | build local (Nuxt 4) | 3000 | — | dépend de `backend` |
| `usenghor_nginx` | nginx:alpine | 80 / 443 (publics) | `nginx.conf`, `ssl/`, `uploads_data` (RO) | — |
| `adminer` (profil `tools`) | adminer:latest | 8080 | — | — |

Tous sur le réseau Docker `usenghor_network`. Politique `restart: unless-stopped` partout.

### Stack monitoring — `docker-compose.monitoring.yml`

| Conteneur | Image | Mémoire | Rôle |
|-----------|-------|---------|------|
| `prometheus` | prom/prometheus:v2.55.1 | 200-350 Mo | TSDB, scrape 15 s, rétention 30 j / 4,5 Go |
| `grafana` | grafana/grafana:11.4.0 | 100-200 Mo | UI, datasources + dashboards provisionnés |
| `node-exporter` | prom/node-exporter:v1.8.2 | 20-50 Mo | Métriques host (CPU, RAM, disque, réseau) |
| `cadvisor` | gcr.io/cadvisor/cadvisor:v0.49.1 | 100-200 Mo | Métriques par conteneur Docker |

Réseau partagé `usenghor_network` (déclaré `external: true`). Volumes durables `prometheus_data`, `grafana_data`. Aucun port publié publiquement pour Prometheus / exporters.

## 5.2 Reverse-proxy Nginx

- **Domaines** : `usenghor-francophonie.org` (principal, redirige `www.` → non-www), `monitoring.usenghor-francophonie.org` (Grafana).
- **TLS** : Let's Encrypt, certificats `/etc/letsencrypt/live/<DOMAINE>/{fullchain,privkey}.pem`, HSTS 2 ans, TLS 1.2/1.3, ciphers ECDHE.
- **Rate limiting** :
  - `/api/*` → 10 r/s, burst 20
  - `/` frontend → 30 r/s, burst 50
  - `monitoring.*` → 30 r/min global, burst 20
  - `monitoring.*/login`, `/api/login`, `/api/user/password/reset` → 5 r/min strict
- **Uploads** : `/uploads` servi en cache 30 j depuis volume.
- **WebSockets Grafana Live** : `/api/live/` avec `Upgrade` headers et `proxy_buffering off`.

## 5.3 Vue d'infrastructure (à dessiner)

> **Schéma à produire (diagrams.net)** :
>
> ```
> Internet
>    │
>    ▼
> [Cloudflare / DNS *.usenghor-francophonie.org]
>    │
>    ▼
> ┌──────────────────────────────────────────────┐
> │  VPS Linux (137.74.117.231)                  │
> │                                              │
> │  ┌──────────[ Docker network: usenghor_network ]──────────┐
> │  │                                                          │
> │  │   ┌──────────┐                                          │
> │  │   │  nginx   │ 80/443 publics                           │
> │  │   └────┬─────┘                                          │
> │  │        ├──► frontend (3000)                             │
> │  │        ├──► backend  (8000) ──► db (5432) ──┐           │
> │  │        ├──► /uploads (volume uploads_data)  │           │
> │  │        └──► grafana  (3000)                 │           │
> │  │                                                          │
> │  │   prometheus ◄── node-exporter (9100)                   │
> │  │              ◄── cadvisor    (8080)                     │
> │  │                                                          │
> │  └──────────────────────────────────────────────────────────┘
> │                                                              │
> │  Volumes durables : postgres_data, uploads_data,             │
> │                     prometheus_data, grafana_data            │
> └──────────────────────────────────────────────────────────────┘
> ```

## 5.4 Domaines et certificats

| Domaine | Rôle | Certificat |
|---------|------|------------|
| `usenghor-francophonie.org` | Site principal | Let's Encrypt (renouvellement cron 3 h) |
| `www.usenghor-francophonie.org` | Redirection 301 → non-www | SAN du certificat principal |
| `monitoring.usenghor-francophonie.org` | Grafana | SAN à ajouter (`certbot --expand`) |

Hook post-renouvellement : `docker restart usenghor_nginx`.

---

# 6. Représentation opérationnelle

## 6.1 Outillage unifié — `./deploy.sh`

| Commande | Effet |
|----------|-------|
| `setup` | Installation initiale (Docker, Git, clonage repos, génération secrets via `openssl rand`) |
| `deploy` | `git pull` + `docker compose build` + `up -d` (rebuild complet) |
| `update` | Mise à jour rapide sans arrêt (pull + rebuild incrémental) |
| `status` | État des conteneurs |
| `logs` | Tail des logs applicatifs |
| `restart` | Redémarrage des services applicatifs |
| `stop` | Arrêt propre |
| `ssl` | Provisioning / renouvellement Let's Encrypt + Certbot |
| `backup` | `pg_dump` → `backup_YYYYMMDD_HHMMSS.sql` |
| `monitoring {up\|down\|logs\|status}` | Pilotage isolé de la stack Prometheus/Grafana |
| `connect` | SSH interactif vers le VPS |

## 6.2 Cycle de vie du déploiement (à dessiner)

> **Schéma à produire (diagrams.net)** : séquence
>
> 1. Développeur → push GitHub
> 2. Exploitant → `./deploy.sh deploy` (SSH-based)
> 3. VPS → `git pull` (repos `usenghor_nuxt` & `usenghor_backend`)
> 4. Docker Compose → `build` + `up -d`
> 5. Healthchecks → backend attend `db:healthy`
> 6. Nginx → rechargement éventuel
> 7. Certbot cron 3 h → renouvellement TLS si nécessaire → hook redémarrage Nginx
> 8. Prometheus → collecte continue ; Grafana → restitution
> 9. Exploitant → vérification `./deploy.sh status` + Grafana dashboards

## 6.3 Sauvegardes

| Élément | Mécanisme | Fréquence cible |
|---------|-----------|-----------------|
| PostgreSQL | `./deploy.sh backup` (pg_dump SQL) | Quotidien (à automatiser cron) |
| Volume `uploads_data` | `tar` sur volume Docker | Hebdomadaire |
| `prometheus_data` | `tar` sur volume Docker | Mensuel (métriques sont rejouables sinon) |
| `grafana_data` | `tar` sur volume Docker (copie à chaud tolérée) | Mensuel |

## 6.4 Restauration

Procédure documentée dans `specs/020-monitoring-stack/quickstart.md` (appendice C) :
`docker compose stop` → `tar xzf` dans le volume → `docker compose start`.

## 6.5 CI/CD

**Aucune CI/CD automatisée** à date. Déploiement push-based manuel via SSH + `./deploy.sh`. Évolution recommandée : pipeline GitHub Actions (build + push image + déclenchement webhook deploy).

---

# 7. Décisions d'architecture (ADR)

| # | Sujet | Décision | Justification |
|---|-------|----------|---------------|
| AD-01 | Stack frontend | Nuxt 4 SSR + Vue 3 + Pinia | SEO multilingue critique, écosystème mature, i18n natif |
| AD-02 | Stack backend | FastAPI async + SQLAlchemy 2.0 + asyncpg | Performance I/O, typage Pydantic, OpenAPI auto |
| AD-03 | Base de données | PostgreSQL 15 (prod) / 16 (local) | JSONB pour audit & sondages, ENUMs, extensions `uuid-ossp` & `pgcrypto` |
| AD-04 | Trilinguisme | Colonnes `*_fr`/`*_en`/`*_ar` + repli FR | Simplicité requêtes, performance vs table de traduction normalisée |
| AD-05 | Contenu riche | Double colonne `*_html` (rendu) + `*_md` (édition) | Édition Markdown rapide + rendu cache-friendly côté public |
| AD-06 | Éditeur WYSIWYG | TOAST UI Editor 3.2.2 (patché) | Markdown natif, plugin tables fusionnées, plein écran |
| AD-07 | Formulaires dynamiques | SurveyJS (`survey-vue3-ui`) | Trilinguisme natif, JSON storable en BDD, analytics |
| AD-08 | Auth & RBAC | JWT + permissions atomiques par code | Granularité fine, super-admin bypass explicite, audit complet |
| AD-09 | Audit | `audit_logs` JSONB (old/new, IP, UA) | Conformité, debug, traçabilité sans table par domaine |
| AD-10 | Référencement inter-services | UUID `*_external_id` au lieu de FK cross-service | Découplage logique, migration future vers microservices facilitée |
| AD-11 | Stockage médias | Filesystem local + abstraction S3 | Simplicité initiale, portabilité future préservée |
| AD-12 | Reverse-proxy | Nginx unique avec rate limiting & TLS | Centralisation TLS, headers, anti-brute-force |
| AD-13 | Monitoring | Prometheus + Grafana + node-exporter + cAdvisor | Standard open-source, légère empreinte (<600 Mo RAM) |
| AD-14 | Isolation monitoring | Réseau Docker partagé, pas de ports publics | Surface d'attaque minimale, accès Grafana via Nginx + TLS uniquement |
| AD-15 | Déploiement | `deploy.sh` bash + Docker Compose, pas de CI | Démarrage simple ; CI/CD reportée |
| AD-16 | Secrets | Générés par `openssl rand` au setup, `.env` hors Git | Pas de fuite GitHub, rotation manuelle possible |
| AD-17 | Nommage fichiers | ASCII strict `[a-z0-9_-]` (pas d'accents) | Évite bugs encodage SSH/Docker en production |
| AD-18 | Pas de tâches planifiées | Pas de Celery / APScheduler à ce stade | YAGNI ; à introduire si volume e-mails ou rapports automatisés croît |

---

# 8. Calendrier et responsabilités

## 8.1 Macro-jalons (réalisés)

| Période | Spec | Périmètre |
|---------|------|-----------|
| ~2025 S1 | 001 | Migration EditorJS → TOAST UI Editor |
| ~2025 S2 | 002 | Plein écran modal TOAST UI |
| ~2025 S2 | 003 | Audit backend connect |
| ~2025 S2 | 004 | Fundraising page |
| ~2025 S2 | 005 | VPS, domaine, SMTP |
| ~2025 S2 | 006 | Password reset e-mail |
| ~2025 S2 | 007 | Décor `#` background |
| ~2025 S2 | 008 | Surveys campaigns |
| ~2025 S2 | 009 | OG meta tags |
| ~2026 S1 | 010 | Refonte fundraising |
| ~2026 S1 | 012 | Médias événements & actualités |
| ~2026 S1 | 014 | Link shortener |
| ~2026 S1 | 015 | Médiathèque |
| ~2026 S1 | 016 | Upload direct médiathèque |
| ~2026 S1 | 017 | Couleurs de texte éditeur |
| ~2026 S1 | 018 | Album médiathèque gouvernance |
| ~2026 S2 | 019 | FAQ backoffice |
| **En cours** | **020** | **Monitoring stack** (branche `020-monitoring-stack`) |

## 8.2 RACI projet (à valider)

| Activité | Responsable (R) | Approbateur (A) | Consultés (C) | Informés (I) |
|----------|-----------------|-----------------|---------------|--------------|
| Roadmap produit | PO / Direction comm. | Rectorat | Équipe dev, secteurs | Tous |
| Spec fonctionnelle | PO + Lead dev | PO | Métiers concernés | Équipe |
| Développement | Lead dev + devs | Lead dev | DevOps, designers | PO |
| Code review | Devs | Lead dev | — | — |
| Déploiement | DevOps / Lead dev | Lead dev | — | PO |
| Monitoring & exploitation | DevOps | Lead dev | Devs | PO |
| Sécurité | Lead dev + sécurité | RSSI université | DevOps | Direction |
| Sauvegardes | DevOps | Lead dev | — | PO |

---

# 9. Risques

| ID | Risque | Sévérité | Probabilité | Mitigation |
|----|--------|----------|-------------|------------|
| R-01 | Perte de données BDD (corruption volume) | Haute | Faible | `./deploy.sh backup` quotidien (à automatiser), volumes Docker isolés |
| R-02 | Fuite de secrets (`.env` versionné par erreur) | Haute | Moyenne | `.env` dans `.gitignore`, génération `openssl rand`, audit pre-commit |
| R-03 | Pas de CI/CD → régressions en production | Moyenne | Moyenne | Mise en place GitHub Actions (build + tests Vitest/Playwright/Pytest) |
| R-04 | Saturation disque (logs + Prometheus + uploads) | Moyenne | Moyenne | Rétention 30 j Prometheus, rotation logs Docker, supervision via Grafana |
| R-05 | Indisponibilité SMTP Gmail (quotas) | Moyenne | Faible | Abstraction `EmailService` permet de basculer SMTP/SES rapidement |
| R-06 | Brute-force authentification | Haute | Moyenne | Rate limiting Nginx, JWT court, audit IP + UA |
| R-07 | Renouvellement TLS échoue | Haute | Faible | Crontab quotidien Certbot, monitoring HTTP 5xx via Grafana |
| R-08 | Single VPS (SPOF) | Haute | Faible | Documenter procédure de réplication ; envisager hot-standby |
| R-09 | Surcharge Nginx en pic (rentrée universitaire) | Moyenne | Moyenne | Cache `/uploads` 30 j, rate limit ajusté, montée en gamme VPS |
| R-10 | Régression i18n (FR/EN/AR + RTL) | Moyenne | Moyenne | Repli FR, tests E2E sur les trois langues |
| R-11 | Encodage SSH/Docker sur accents | Moyenne | Faible | Convention nommage ASCII pour fichiers/dossiers (cf. CLAUDE.md) |
| R-12 | Patch `prosemirror-state` cassé par futur upgrade Nuxt | Faible | Moyenne | Versionnage strict TOAST UI, tests visuels avant montée de version |
| R-13 | Pas de monitoring applicatif (latence API, taux d'erreur) | Moyenne | Élevée | À adresser après spec 020 : ajouter `/metrics` FastAPI + scrape Prometheus |

---

# 10. RACI opérations

| Activité opérationnelle | Outils | R | A | C | I |
|-------------------------|--------|---|---|---|---|
| Déploiement (`deploy`) | `deploy.sh deploy` | DevOps | Lead dev | — | PO |
| Mise à jour rapide (`update`) | `deploy.sh update` | DevOps | Lead dev | — | PO |
| Redémarrage / Restart | `deploy.sh restart` | DevOps | Lead dev | — | — |
| Logs applicatifs | `deploy.sh logs` | DevOps | — | Devs | — |
| Pilotage monitoring | `deploy.sh monitoring ...` | DevOps | Lead dev | — | PO |
| Backups BDD | `deploy.sh backup` | DevOps | Lead dev | — | PO |
| Renouvellement TLS | Certbot cron + `deploy.sh ssl` | DevOps | Lead dev | — | — |
| Migrations SQL | `docker exec ... psql < migration.sql` | Lead dev | Lead dev | Devs | PO |
| Création de rôles / permissions | Backoffice admin | Super-admin | Lead dev | — | PO |
| Surveillance dashboards | Grafana | DevOps | Lead dev | Devs | PO |
| Réponse à incident | Logs + dashboards + audit | DevOps + Lead dev | Lead dev | RSSI | PO |
| Rotation secrets | Manuel (`openssl rand` + redeploy) | DevOps | Lead dev | RSSI | — |
| Mise à jour images Docker | `deploy.sh deploy` après bump | DevOps | Lead dev | Devs | — |

---

# 11. Coûts

> Estimations indicatives — à valider avec les contrats réels Université Senghor.

## 11.1 Infrastructure récurrente (annuelle)

| Poste | Détail | Estimation €/an |
|-------|--------|-----------------|
| VPS Linux (137.74.117.231) | ~4–8 vCPU / 8–16 Go RAM / 80–160 Go SSD | 400 – 1 200 |
| Nom de domaine `.org` | Renouvellement annuel | 15 – 25 |
| Certificats TLS | Let's Encrypt (gratuit) | 0 |
| SMTP transactionnel | Gmail Workspace (compte existant) ou SES | 0 – 100 |
| Sauvegardes externes (S3 / Backblaze) | ~50 Go | 30 – 80 |
| **Sous-total infra** | | **~450 – 1 400** |

## 11.2 Logiciel

| Composant | Licence | Coût |
|-----------|---------|------|
| Nuxt, Vue, Pinia, FastAPI, PostgreSQL, Nginx, Prometheus, Grafana OSS, TOAST UI Editor, SurveyJS (Community), Leaflet, GSAP (no commercial monetization), Lenis | OSS / gratuit | 0 |
| Firebase SDK (dans `package.json`) | Plan Spark gratuit suffisant si usage faible | 0 – ? |
| AmCharts 5 | Licence à vérifier (commercial vs OSS) | À cadrer |
| **Sous-total logiciel** | | **~0 – à confirmer** |

## 11.3 Coûts humains (indicatifs, à ajuster)

| Profil | Charge | Coût indicatif |
|--------|--------|----------------|
| Lead dev fullstack | Maintenance + features | À cadrer |
| Dev frontend Vue/Nuxt | Specs ponctuelles | À cadrer |
| Dev backend FastAPI | Specs ponctuelles | À cadrer |
| DevOps (partiel) | Déploiement, monitoring, backups | À cadrer |
| Designer / UX | Évolutions UI | À cadrer |
| PO / chef de projet | Pilotage | À cadrer |

## 11.4 Évolutions recommandées (coûts potentiels)

- CI/CD GitHub Actions : gratuit pour repos publics ou ~0–100 €/mois selon minutes consommées.
- Réplique chaude / failover : doublement coût VPS (≈ +500–1 200 €/an).
- CDN (Cloudflare gratuit ou Pro 20 $/mois).
- Stockage médias S3 + CloudFront si croissance forte.

---

# 12. Annexes

## 12.1 Référentiel SQL (16 services)

`00_extensions` · `01_core` · `02_identity` · `03_media` · `04_organization` · `05_campus` · `06_partner` · `07_academic` · `08_application` · `09_content` · `10_project` · `11_newsletter` · `12_editorial` · `99_functions` · `99_data_init` · `99_views`
Plus services additionnels : FAQ, fundraising, surveys, short_links, governance album.

## 12.2 Conventions de code

- **Français accentué obligatoire** dans contenus et commentaires (é, è, ê, à, ç, ù).
- **Noms de fichiers/dossiers ASCII** strict (`[a-z0-9_-]`) — voir AD-17.
- Champs trilingues : `*_fr`, `*_en`, `*_ar`.
- Contenu riche : `*_html` + `*_md`.
- Alias frontend : `@bank` → `./bank`.

## 12.3 Schémas à produire (diagrams.net)

1. **Cartographie fonctionnelle** (§3.2)
2. **Vue logique applicative en couches** (§4.4)
3. **Vue d'infrastructure** (§5.3)
4. **Séquence cycle de vie de déploiement** (§6.2)
5. *(optionnel)* Diagramme ER haut niveau par domaine SQL
6. *(optionnel)* Flux d'authentification JWT + RBAC

---

*Fin du document.*
