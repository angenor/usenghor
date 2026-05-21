# Vue ArchiMate — SI Université Senghor

> Modélisation ArchiMate 3.x du SI Usenghor, à compléter / dessiner avec Archi (open-source) ou diagrams.net (gabarit ArchiMate).
> Référentiel projet : [`architechture_technique.md`](./architechture_technique.md), [`pos_si_usenghor.md`](./pos_si_usenghor.md).
> Version : 1.0 — 2026-05-18

---

## Rappel notation ArchiMate (synthèse)

ArchiMate distingue **3 couches** + 2 transverses :

| Couche | Couleur conventionnelle | Concepts clés |
|--------|------------------------|---------------|
| **Business** (Métier) | Jaune | Actor, Role, Business Process, Business Service, Business Object |
| **Application** | Bleu | Application Component, Application Service, Application Function, Data Object, Interface |
| **Technology** | Vert | Node, Device, System Software, Technology Service, Artifact, Communication Network |
| **Motivation** (transverse) | Violet | Stakeholder, Driver, Goal, Requirement, Constraint, Principle |
| **Strategy & Implementation** (transverse) | Rose / Orange | Capability, Work Package, Deliverable, Plateau |

**Relations principales** : `realizes`, `serves`, `assigned-to`, `used-by`, `triggers`, `flows`, `composition`, `aggregation`.

---

## 1. Couche Motivation

### 1.1 Stakeholders (acteurs stratégiques)

- **Rectorat / Direction** (`Stakeholder`) — sponsor stratégique
- **Direction Communication** (`Stakeholder`) — pilote éditorial
- **Direction Académique** (`Stakeholder`) — pilote formations & candidatures
- **DSI / Lead dev** (`Stakeholder`) — porte la cible architecturale
- **OIF / Tutelles francophones** (`Stakeholder`) — partenaires institutionnels

### 1.2 Drivers (moteurs)

- Rayonnement international (FR/EN/AR)
- Industrialisation des candidatures internationales
- Conformité (audit, RGPD)
- Sobriété budgétaire (OSS, mutualisation)

### 1.3 Goals & Requirements

| Goal | Realized by Requirement |
|------|-------------------------|
| Centraliser la présence numérique | Plateforme unique trilingue |
| Sécuriser les accès | RBAC granulaire + audit JSONB |
| Maîtriser le SEO multilingue | SSR + hreflang + JSON-LD |
| Garantir la résilience | Healthchecks, restart unless-stopped, monitoring |

### 1.4 Principles (règles d'urbanisme)

- P1 — Couplage faible inter-domaines (UUID externes, pas de FK transverses)
- P2 — Trilinguisme systémique (`*_fr/*_en/*_ar`)
- P3 — Contenu riche double colonne (`*_html` + `*_md`)
- P4 — Audit exhaustif des mutations critiques
- P5 — Aucun port public hors Nginx
- P6 — Secrets jamais versionnés

---

## 2. Couche Business

### 2.1 Business Actors & Roles

| Actor | Roles assignés |
|-------|----------------|
| Visiteur anonyme | Lecteur public, Abonné newsletter, Candidat potentiel |
| Candidat | Soumetteur de dossier, Suivi de candidature |
| Donateur | Manifesteur d'intérêt, Contributeur |
| Éditeur | Rédacteur contenu, Gestionnaire médiathèque |
| Administrateur métier | Gestionnaire formations / campus / projets / sondages |
| Super-administrateur | Gestionnaire RBAC, Auditeur |
| DevOps | Exploitant plateforme |

### 2.2 Business Processes (haut niveau)

```
[Candidat] ──► (Découverte formations) ──► (Création compte) ──► (Soumission dossier)
                                                                       │
                                                                       ▼
                                                              (Évaluation par admin)
                                                                       │
                                                                       ▼
                                                          (Notification décision)
```

| Processus métier | Description |
|------------------|-------------|
| **BP-01 Communication institutionnelle** | Publication actualités, événements, contenus éditoriaux |
| **BP-02 Recrutement étudiants** | Appel → candidature → instruction → décision |
| **BP-03 Animation communauté** | Newsletter, événements, sondages |
| **BP-04 Mobilisation philanthropique** | Levée de fonds → manifestation d'intérêt → suivi donateur |
| **BP-05 Gouvernance** | Habilitation, audit, configuration |
| **BP-06 Exploitation SI** | Déploiement, supervision, sauvegardes |

### 2.3 Business Services (exposés au métier)

- BS-01 — Service de publication multilingue
- BS-02 — Service de candidature en ligne
- BS-03 — Service d'inscription événementielle
- BS-04 — Service d'abonnement newsletter
- BS-05 — Service de manifestation d'intérêt fundraising
- BS-06 — Service de gestion FAQ
- BS-07 — Service de gouvernance des identités

### 2.4 Business Objects

`Programme`, `Candidature`, `Actualité`, `Événement`, `Projet`, `Campagne fundraising`, `Sondage`, `Média`, `Utilisateur`, `Rôle`, `Permission`, `Audit log`.

---

## 3. Couche Application

### 3.1 Application Components

| Composant | Rôle | Technologies |
|-----------|------|--------------|
| **AC-01 Frontend public Nuxt SSR** | Sert pages publiques trilingues | Nuxt 4, Vue 3, Pinia, i18n |
| **AC-02 Frontend admin Nuxt** | Backoffice (pages admin protégées) | Même runtime + middleware auth |
| **AC-03 Backend API publique** | `/api/public/*` sans auth | FastAPI routers publics (~23) |
| **AC-04 Backend API admin** | `/api/admin/*` JWT obligatoire | FastAPI routers admin (~38) |
| **AC-05 Service d'authentification** | Login, JWT, reset password | `app/routers/auth.py` |
| **AC-06 Service e-mail transactionnel** | Envois async, templates | `EmailService`, Jinja2, aiosmtplib |
| **AC-07 Service de stockage médias** | Abstraction local/S3 | `app/services/storage.py` |
| **AC-08 Service de sondages** | Construction + collecte SurveyJS | Service surveys + SurveyJS |
| **AC-09 Service d'audit** | Middleware enregistrant les mutations | Middleware FastAPI |
| **AC-10 Éditeur de contenu riche** | WYSIWYG + Markdown | TOAST UI Editor 3.2.2 |
| **AC-11 Réducteur de liens** | Génération + validation domaines | Service short_links |

### 3.2 Application Services (exposés)

- AS-01 Lecture des contenus publics (`realizes` BS-01)
- AS-02 Soumission de candidature (`realizes` BS-02)
- AS-03 Inscription événement (`realizes` BS-03)
- AS-04 Abonnement / désabonnement newsletter (`realizes` BS-04)
- AS-05 Manifestation d'intérêt fundraising (`realizes` BS-05)
- AS-06 Gestion FAQ trilingue (`realizes` BS-06)
- AS-07 Authentification et habilitation (`realizes` BS-07)
- AS-08 Audit (transverse)
- AS-09 Envoi de notification e-mail (utilisé par AS-02, AS-04, AS-05, AS-07)
- AS-10 Gestion médias (utilisé par AS-01, AS-02, AS-08…)

### 3.3 Application Interfaces

- `REST/JSON` exposé via FastAPI (OpenAPI auto)
- `HTTP/HTML SSR` exposé par Nuxt
- `SMTP/TLS` consommé pour e-mails
- `SQL` interne entre AC-03/04 et PostgreSQL

### 3.4 Data Objects (vue logique)

Carte synthétique alignée sur les 16 services SQL :

| Data Object | Service SQL |
|-------------|-------------|
| Identité (User, Role, Permission, AuditLog, Token) | `02_identity.sql` |
| Média (Media, Album, AlbumMedia) | `03_media.sql` |
| Organisation (Sector, Service, ServiceTeam) | `04_organization.sql` |
| Campus (Campus, CampusTeam) | `05_campus.sql` |
| Partenariat (Partner, PartnershipRequest) | `06_partner.sql` |
| Académique (Program, Semester, Course, Skill, CareerOpportunity) | `07_academic.sql` |
| Candidature (ApplicationCall, Application, Document) | `08_application.sql` |
| Contenu (News, Event, Tag, Registration) | `09_content.sql` |
| Projet (Project, ProjectCategory, ProjectCall) | `10_project.sql` |
| Newsletter (Subscriber, Campaign) | `11_newsletter.sql` |
| Éditorial (EditorialContent, ContactInfo, SocialLink, KeyFigure) | `12_editorial.sql` |
| Fundraising (Fundraiser, Contributor, Section, Media) | service fundraising |
| Sondage (SurveyCampaign, Response) | service surveys |
| FAQ (FaqCategory, FaqEntry) | service FAQ |
| Lien court (ShortLink) | service short_links |
| Référentiel (Country, Tag, ENUMs) | `01_core.sql`, `00_extensions.sql` |

### 3.5 Relations principales (couche Application)

```
AC-01 Frontend public ─uses──► AC-03 API publique ─uses──► AC-07 Storage
AC-01 ─uses──► AC-03 ─uses──► PostgreSQL (Data Objects)
AC-02 Frontend admin ─uses──► AC-04 API admin ─uses──► AC-05 Auth + AC-09 Audit
AC-04 ─triggers──► AC-06 Email (notifications)
AC-08 Sondages ─uses──► AC-06 Email (confirmations)
AC-10 Éditeur ─embedded-in──► AC-02
AC-11 Réducteur ─composes──► AC-01 (CTA, partage)
```

---

## 4. Couche Technology

### 4.1 Nodes (infrastructure)

| Node | Rôle | System Software |
|------|------|-----------------|
| **TN-01 VPS Linux** (137.74.117.231) | Hôte unique | Docker Engine + Docker Compose |
| **TN-02 Container Nginx** | Reverse-proxy frontal | nginx:alpine |
| **TN-03 Container Frontend** | Nuxt 4 SSR | Node.js runtime |
| **TN-04 Container Backend** | FastAPI async | Python 3.14 + uvicorn |
| **TN-05 Container PostgreSQL** | Persistance | postgres:15-alpine |
| **TN-06 Container Adminer** (profil tools) | Console BDD | adminer:latest |
| **TN-07 Container Prometheus** | TSDB | prom/prometheus:v2.55.1 |
| **TN-08 Container Grafana** | UI métriques | grafana/grafana:11.4.0 |
| **TN-09 Container node-exporter** | Métriques hôte | prom/node-exporter:v1.8.2 |
| **TN-10 Container cAdvisor** | Métriques conteneurs | cadvisor:v0.49.1 |

### 4.2 Technology Services

- TS-01 Reverse-proxy & TLS termination (réalisé par TN-02)
- TS-02 Rendu SSR (TN-03)
- TS-03 API REST async (TN-04)
- TS-04 Persistance SQL (TN-05)
- TS-05 SMTP sortant (externe — Gmail Workspace)
- TS-06 Stockage fichiers (volume `uploads_data`)
- TS-07 Collecte métriques (TN-07/09/10)
- TS-08 Visualisation métriques (TN-08)
- TS-09 Renouvellement TLS (Certbot + crontab 3 h)
- TS-10 Exploitation unifiée (`deploy.sh`)

### 4.3 Artifacts (livrables techniques)

`Image Docker frontend`, `Image Docker backend`, `nginx.conf`, `docker-compose.prod.yml`, `docker-compose.monitoring.yml`, `.env.production`, `deploy.sh`, `volume postgres_data`, `volume uploads_data`, `volume prometheus_data`, `volume grafana_data`, `certificats Let's Encrypt`.

### 4.4 Communication Networks

- **CN-01 Internet** (public, HTTPS uniquement vers TN-02)
- **CN-02 Réseau Docker `usenghor_network`** (interne, isole tous les conteneurs)
- **CN-03 SSH d'exploitation** (DevOps → TN-01)

---

## 5. Couche Strategy & Implementation

### 5.1 Capabilities (capacités SI)

- C-01 Présenter l'université (Z1)
- C-02 Recruter des étudiants (Z2)
- C-03 Animer la communauté (Z3)
- C-04 Gouverner les accès (Z4)
- C-05 Exploiter et superviser la plateforme (Z5)

### 5.2 Work Packages (incréments — Plateaus)

Chaque spec `specs/00X` = un Work Package, regroupés en 3 plateaus :

| Plateau | Période | Capabilities renforcées | Work Packages |
|---------|---------|--------------------------|----------------|
| **P0 — Socle initial** | 2025 S1 | C-01, C-02, C-05 | 001 (TOAST UI), 002 (modal), 003 (audit), 005 (VPS+SMTP), 006 (reset) |
| **P1 — Engagement & contenu** | 2025 S2 – 2026 S1 | C-03 | 004/010 (fundraising), 007 (décor), 008 (surveys), 009 (OG), 012 (médias news), 014 (links), 015/016/018 (médiathèque), 017 (couleurs), 019 (FAQ) |
| **P2 — Observabilité** | 2026 S2 (en cours) | C-05 | 020 (monitoring stack) |
| **P3 — Cible 12-36 mois** (future) | 2026-2028 | C-02, C-03, C-05 | CI/CD, HA, monitoring applicatif, S3, microservices, tâches planifiées |

---

## 6. Vues ArchiMate à produire (livrables visuels)

À dessiner sous Archi (`https://www.archimatetool.com/`) ou diagrams.net (gabarit ArchiMate) :

| # | Vue | Concepts à représenter |
|---|-----|------------------------|
| V1 | **Vue stratégique (Motivation)** | Stakeholders → Drivers → Goals → Principles |
| V2 | **Vue Business haut niveau** | Actors, Roles, Business Services, Business Processes (BP-01 à BP-06) |
| V3 | **Vue cooperation Business / Application** | Comment AS-01 à AS-10 réalisent BS-01 à BS-07 |
| V4 | **Vue structure applicative** | AC-01 à AC-11 + Data Objects, relations `uses`/`triggers`/`flows` |
| V5 | **Vue Application / Technology** | Mapping AC → TN (déploiement), interfaces réseau |
| V6 | **Vue Technology (infrastructure)** | TN-01 à TN-10, CN-01 à CN-03, volumes |
| V7 | **Vue Implementation & Migration** | Plateaus P0 → P1 → P2 → P3, work packages, deliverables |

---

## 7. Mapping rapide DAT → ArchiMate

| Section DAT | Équivalent ArchiMate |
|-------------|----------------------|
| §1 Besoins fonctionnels | Couche Business (Services, Processus) |
| §2 Besoins non fonctionnels | Couche Motivation (Goals, Requirements, Principles) |
| §3 Représentation fonctionnelle | Couche Business (V2) |
| §4 Représentation applicative | Couche Application (V4) |
| §5 Représentation infrastructure | Couche Technology (V6) |
| §6 Représentation opérationnelle | Couche Technology + Implementation (V5, V7) |
| §7 Décisions d'architecture (ADR) | Motivation (Principles) + Implementation (Constraints) |
| §8 Calendrier | Implementation & Migration (Plateaus) |
| §9 Risques | Motivation (Assessment) |
| §10 RACI opérations | Business Actors / Roles |
| §11 Coûts | Implementation (Work Packages avec coûts) |

---

## 8. Pourquoi cette modélisation ArchiMate fait la différence en candidature

- **Vocabulaire officiel** reconnu par tout urbaniste / enterprise architect senior.
- **Cohérence avec TOGAF ADM** (phases B/C/D notamment).
- **Outillage standard** : Archi (open-source, gratuit) génère exports XML, exchange format ArchiMate 3.1.
- **Communicabilité** : permet de présenter un même SI à des publics différents (stratégique, fonctionnel, technique) sans rejouer l'analyse.

> *« Le DAT Usenghor est intégralement modélisable en ArchiMate 3.1 — couches Motivation, Business, Application, Technology et Implementation & Migration — avec 7 vues prêtes à dessiner sous Archi. »*

---

*Fin du document.*
