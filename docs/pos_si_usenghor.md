# Plan d'Occupation des Sols (POS) — SI Université Senghor

> Document d'urbanisme SI — vue d'ensemble fonctionnelle à 3 niveaux.
> Référentiel projet : [`architechture_technique.md`](./architechture_technique.md).
> Version : 1.0 — 2026-05-18

---

## Préambule — Notion de POS

Le **Plan d'Occupation des Sols** est l'outil canonique de l'urbaniste SI. Il découpe le système d'information en :

- **Zones** — grands ensembles fonctionnels stratégiques (≈ 4 à 6 par SI).
- **Quartiers** — sous-domaines cohérents au sein d'une zone.
- **Îlots / blocs** — composants applicatifs concrets (services, modules, briques).

**Règles d'urbanisme appliquées** :

1. *Un îlot appartient à un seul quartier ; un quartier à une seule zone.*
2. *Les échanges inter-zones passent uniquement par des services exposés (pas de FK directe inter-domaines).*
3. *Chaque îlot porte une responsabilité unique (Single Responsibility).*
4. *Un référentiel partagé (Identité, Médias, Pays) est mutualisé entre toutes les zones consommatrices.*

---

## Vue d'ensemble — 5 zones d'urbanisme

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          SI UNIVERSITÉ SENGHOR                              │
├──────────────┬──────────────┬──────────────┬──────────────┬─────────────────┤
│  Z1          │  Z2          │  Z3          │  Z4          │  Z5             │
│  PRÉSENTATION│  PRODUCTION  │  ENGAGEMENT  │  PILOTAGE    │  SOCLE          │
│  INSTITUT.   │  ACADÉMIQUE  │  COMMUNAUTÉ  │  & GOUVER-   │  TECHNIQUE      │
│              │              │              │  NANCE       │                 │
└──────────────┴──────────────┴──────────────┴──────────────┴─────────────────┘
```

| Zone | Finalité métier | Public cible |
|------|-----------------|--------------|
| **Z1 — Présentation institutionnelle** | Communiquer l'identité, l'histoire, la stratégie | Grand public, partenaires, tutelles |
| **Z2 — Production académique** | Gérer formations, candidatures, dossiers étudiants | Candidats, étudiants, équipes pédagogiques |
| **Z3 — Engagement & communauté** | Animer la vie de l'université, mobiliser, lever des fonds | Alumni, donateurs, communauté élargie |
| **Z4 — Pilotage & gouvernance** | Gouverner les accès, tracer, configurer | Administrateurs, super-admins |
| **Z5 — Socle technique** | Servir la plateforme : sécurité, observabilité, exploitation | DSI, DevOps |

---

## Z1 — Présentation institutionnelle

> **Mission** : exposer publiquement l'identité et l'offre de l'université, en trois langues, avec SEO maîtrisé.

### Quartiers et îlots

| Quartier | Îlots / blocs | Couverture SQL / applicative |
|----------|---------------|------------------------------|
| **Q1.1 — Identité institutionnelle** | Accueil narratif, Histoire, Stratégie, Gouvernance, Valeurs, Chiffres-clés | `editorial_contents`, `12_editorial.sql` |
| **Q1.2 — Organisation** | Secteurs, Services, Objectifs de service, Équipes de service | `04_organization.sql` |
| **Q1.3 — Présence territoriale** | Campus, Équipes de campus, Cartographie Leaflet | `05_campus.sql` |
| **Q1.4 — Écosystème** | Partenaires, Demandes de partenariat | `06_partner.sql` |
| **Q1.5 — Visibilité & SEO** | Sitemap, hreflang, JSON-LD `CollegeOrUniversity`, Open Graph, dark mode | Module SEO Nuxt, `@nuxtjs/sitemap` |

---

## Z2 — Production académique

> **Mission** : porter le cœur métier — formations et candidatures internationales.

### Quartiers et îlots

| Quartier | Îlots / blocs | Couverture SQL / applicative |
|----------|---------------|------------------------------|
| **Q2.1 — Offre de formation** | Programmes (Masters / Doctorats / Certificats / CLOMs), Semestres, Cours, Compétences, Débouchés, Types | `07_academic.sql` |
| **Q2.2 — Appels à candidature** | Appels (calls), Calendrier d'appel, Critères d'éligibilité, Documents requis, Types d'appel | `08_application.sql` |
| **Q2.3 — Dossiers candidats** | Candidatures, Documents soumis, Statuts, Référence APP-YYYY-NNNNNN | `08_application.sql` + séquence `seq_application_reference` |
| **Q2.4 — Sondages académiques** | Campagnes de sondage trilingues, Réponses JSONB, Analytics | Service surveys, SurveyJS |

---

## Z3 — Engagement & communauté

> **Mission** : mobiliser la communauté élargie autour de l'université.

### Quartiers et îlots

| Quartier | Îlots / blocs | Couverture SQL / applicative |
|----------|---------------|------------------------------|
| **Q3.1 — Actualité éditoriale** | Actualités, Tags, Mise en avant, Catégories | `09_content.sql` |
| **Q3.2 — Événementiel** | Événements, Types, Inscriptions, Partenaires d'événement | `09_content.sql` |
| **Q3.3 — Projets** | Projets institutionnels, Catégories, Appels à projets, Statuts | `10_project.sql` |
| **Q3.4 — Médiathèque** | Médias, Albums, Album-média, Upload direct, Gouvernance albums (textes fondateurs) | `03_media.sql`, spec 015/016/018 |
| **Q3.5 — Newsletter** | Abonnés (token désinscription), Campagnes, Statuts d'envoi, Statistiques | `11_newsletter.sql` |
| **Q3.6 — Levées de fonds** | Campagnes fundraising, Sections éditoriales, Contributeurs, Manifestations d'intérêt | Service fundraising, spec 004/010 |
| **Q3.7 — FAQ** | Catégories trilingues, Entrées, Ordre, JSON-LD | Service FAQ, spec 019 |

---

## Z4 — Pilotage & gouvernance

> **Mission** : gouverner les identités, les accès, les traces et la configuration.

### Quartiers et îlots

| Quartier | Îlots / blocs | Couverture SQL / applicative |
|----------|---------------|------------------------------|
| **Q4.1 — Identités** | Utilisateurs, Profils, Tokens (email_verification / password_reset), Verrouillage sur changement mot de passe | `02_identity.sql` |
| **Q4.2 — Habilitations (RBAC)** | Rôles hiérarchisés (`hierarchy_level`), Permissions atomiques (`code`), User-Roles, Role-Permissions, Super-admin bypass | `02_identity.sql` |
| **Q4.3 — Audit & traçabilité** | `audit_logs` JSONB (old/new + IP + UA), Triggers, Index conformité | `02_identity.sql`, middleware FastAPI |
| **Q4.4 — Configuration éditoriale** | Contact, Réseaux sociaux, Mentions légales, Paramètres globaux | `12_editorial.sql` |
| **Q4.5 — Liens courts** | Réducteur URL, Validation domaines, Compteur base36 | Service short_links, spec 014 |
| **Q4.6 — Référentiels** | Pays, Tags, Catégories FAQ, Catégories projets, ENUMs partagés | `01_core.sql`, `00_extensions.sql` |

---

## Z5 — Socle technique

> **Mission** : assurer la plateforme — sécurité périmétrique, observabilité, exploitation, persistance.

### Quartiers et îlots

| Quartier | Îlots / blocs | Couverture |
|----------|---------------|------------|
| **Q5.1 — Frontal & sécurité périmétrique** | Nginx reverse-proxy, TLS Let's Encrypt + Certbot, HSTS, headers sécurité, rate-limiting (10 r/s API, 30 r/s frontend, 5 r/min login) | `nginx/nginx.conf` |
| **Q5.2 — Rendu & API** | Frontend Nuxt 4 SSR (port 3000), Backend FastAPI async (port 8000), JWT, OpenAPI | `usenghor_nuxt/`, `usenghor_backend/` |
| **Q5.3 — Persistance** | PostgreSQL 15/16, volumes `postgres_data`, `uploads_data`, healthcheck `pg_isready` | `docker-compose.prod.yml` |
| **Q5.4 — Communication sortante** | `EmailService` (aiosmtplib + TLS), templates Jinja2 (6 templates), SMTP Gmail | `app/services/email_service.py`, `app/templates/email/` |
| **Q5.5 — Stockage médias** | Filesystem local `/uploads` + abstraction `storage_type: local\|s3` (future-ready) | `app/services/storage.py` |
| **Q5.6 — Observabilité** | Prometheus (scrape 15 s, rétention 30 j), Grafana (provisioning), node-exporter, cAdvisor, sous-domaine `monitoring.*` | `docker-compose.monitoring.yml`, spec 020 |
| **Q5.7 — Exploitation** | `deploy.sh` (setup, deploy, update, ssl, backup, monitoring, connect), crontab Certbot 3 h, politique `restart: unless-stopped` | `deploy.sh` |

---

## Carte synthétique des flux inter-zones

```
              ┌──────────── Z5 — SOCLE TECHNIQUE ───────────┐
              │                                              │
              │   Nginx ── Frontend Nuxt ── Backend FastAPI ── PostgreSQL
              │                  │                │
              │                  │                ├──► EmailService ──► SMTP
              │                  │                └──► Storage médias
              │   Prometheus ◄── exporters                    │
              │   Grafana   ◄── Prometheus                    │
              └───────────────────────────────────────────────┘
                                  │
        ┌─────────────────────────┼─────────────────────────┐
        │                         │                         │
        ▼                         ▼                         ▼
   ┌─────────┐              ┌──────────┐              ┌──────────┐
   │   Z1    │              │   Z2     │              │   Z3     │
   │ Présent.│◄────────────►│ Académ.  │◄────────────►│ Engag.   │
   └────┬────┘              └────┬─────┘              └────┬─────┘
        │                        │                          │
        └────────────────────────┼──────────────────────────┘
                                 │
                                 ▼
                          ┌─────────────┐
                          │    Z4       │
                          │ Pilotage &  │
                          │ Gouvernance │  (RBAC, audit, identités)
                          └─────────────┘
                                 ▲
                                 │   transverse à toutes les zones
```

---

## Matrice d'adhérence zone × technologies

| Zone | Frontend Nuxt | Backend FastAPI | PostgreSQL | Nginx | Email | Monitoring |
|------|:-------------:|:---------------:|:----------:|:-----:|:-----:|:----------:|
| Z1 — Présentation | ●●● | ● | ●● | ● | — | — |
| Z2 — Académique | ●●● | ●●● | ●●● | ● | ●● | — |
| Z3 — Engagement | ●●● | ●●● | ●●● | ● | ●●● | — |
| Z4 — Gouvernance | ●●● | ●●● | ●●● | ●● | ● | — |
| Z5 — Socle | — | — | — | ●●● | ● | ●●● |

*●●● central · ●● fortement utilisé · ● ponctuellement utilisé*

---

## Règles d'urbanisme et points de contrôle

| Règle | Application sur Usenghor | Statut |
|-------|--------------------------|:------:|
| Couplage faible inter-zones | UUID externes au lieu de FK cross-service (AD-10) | ✅ |
| Référentiels mutualisés | `users`, `media`, `countries`, `tags` partagés | ✅ |
| Standardisation transverse | `*_fr/*_en/*_ar`, `*_html/*_md`, audit JSONB | ✅ |
| Pas d'exposition directe BDD | Seul le backend accède à PostgreSQL ; Nginx ne sert que HTTP(S) | ✅ |
| Sécurité périmétrique unique | Nginx centralise TLS, rate-limit, headers | ✅ |
| Observabilité isolée | Réseau Docker partagé, pas de ports publics | ✅ |
| CI/CD automatisée | **Absente** — déploiement manuel SSH | ⚠️ |
| Tâches planifiées | **Absente** — pas de Celery / APScheduler | ⚠️ |
| Haute disponibilité | **SPOF VPS unique** | ⚠️ |
| Monitoring applicatif (latence API, taux d'erreur) | **Absent** — seules métriques système et conteneurs | ⚠️ |

---

## Cibles d'urbanisation (gap analysis)

| Sujet | Existant | Cible 12-36 mois |
|-------|----------|------------------|
| CI/CD | Manuel | GitHub Actions (build + tests + déploiement webhook) |
| Tests automatisés | Vitest / Playwright / Pytest partiels | Couverture > 70 %, CI bloquant |
| HA / résilience | VPS unique | Réplique chaude + reverse-proxy frontal (Cloudflare / load-balancer) |
| Monitoring applicatif | Métriques système uniquement | Endpoint `/metrics` FastAPI + scrape Prometheus, alertmanager |
| Stockage médias | Filesystem local | Migration vers S3 / Backblaze + CDN |
| Tâches planifiées | Aucune | Celery + Redis (ou APScheduler) pour campagnes newsletter, exports, relances |
| Microservices | Monolithe modulaire (16 services SQL) | Extraction progressive des services à fort trafic (médiathèque, sondages) |
| Gouvernance données | Audit JSONB | Politique de rétention RGPD, anonymisation des logs anciens |

---

*Fin du document.*
