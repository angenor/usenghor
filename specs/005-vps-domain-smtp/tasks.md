# Tasks: Configuration VPS domaine et email SMTP

**Input**: Design documents from `/specs/005-vps-domain-smtp/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/

**Tests**: Non demandés explicitement — pas de tâches de test automatisé. Vérifications manuelles uniquement (curl, envoi d'email).

**Organization**: Tasks groupées par user story. US1 et US2 sont toutes deux P1 mais US1 (domaine/SSL) est un prérequis technique pour US2 (email).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Configuration partagée)

**Purpose**: Mise à jour des fichiers de configuration avec le nouveau domaine

- [x] T001 [P] Mettre à jour CORS_ORIGINS et NUXT_SITE_URL avec `usenghor-francophonie.org` dans `.env.production.example`
- [x] T002 [P] Mettre à jour les valeurs SMTP par défaut dans `usenghor_backend/.env.example`
- [x] T003 [P] Ajouter `smtp_from_email` dans la classe Settings de `usenghor_backend/app/config.py`

---

## Phase 2: Foundational (Prérequis bloquants)

**Purpose**: Infrastructure partagée entre US1 (domaine) et US2 (email)

**⚠️ CRITICAL**: US1 et US2 ne peuvent pas commencer sans cette phase

- [x] T004 Vérifier que les variables SMTP sont correctement passées au backend dans `docker-compose.prod.yml`
- [x] T005 Mettre à jour le domaine dans la commande `ssl` de `deploy.sh` (remplacer les références à l'ancien domaine s'il y en a)

**Checkpoint**: Configuration de base prête — les user stories peuvent commencer

---

## Phase 3: User Story 1 - Accès au site via le nom de domaine (Priority: P1) 🎯 MVP

**Goal**: Le site est accessible à https://usenghor-francophonie.org avec SSL valide et redirections (HTTP→HTTPS, www→non-www)

**Independent Test**: `curl -I https://usenghor-francophonie.org` retourne 200 avec certificat valide

### Implementation for User Story 1

- [x] T006 [US1] Mettre à jour `server_name` avec `usenghor-francophonie.org` dans le bloc HTTP de `nginx/nginx.conf`
- [x] T007 [US1] Décommenter et configurer le bloc HTTPS (port 443) avec `server_name usenghor-francophonie.org` dans `nginx/nginx.conf`
- [x] T008 [US1] Ajouter le bloc de redirection HTTP→HTTPS (port 80 → 301 vers https) dans `nginx/nginx.conf`
- [x] T009 [US1] Ajouter le bloc de redirection www→non-www (443 www → 301 vers non-www) dans `nginx/nginx.conf`
- [x] T010 [US1] Déployer la config nginx mise à jour sur le VPS via `./deploy.sh update`
- [x] T011 [US1] Générer le certificat SSL sur le VPS via `./deploy.sh ssl usenghor-francophonie.org`
- [x] T012 [US1] Vérifier : `curl -I https://usenghor-francophonie.org` (200), `curl -I http://usenghor-francophonie.org` (301→https), `curl -I https://www.usenghor-francophonie.org` (301→non-www)

**Checkpoint**: Le site est accessible en HTTPS avec toutes les redirections fonctionnelles

---

## Phase 4: User Story 2 - Envoi d'emails depuis l'application (Priority: P1)

**Goal**: Le backend peut envoyer des emails via SMTP Gmail (communication@usenghor.org)

**Independent Test**: Appeler l'endpoint POST `/api/admin/email/test` et vérifier la réception de l'email

### Implementation for User Story 2

- [x] T013 [US2] Créer le service email async avec aiosmtplib dans `usenghor_backend/app/services/email_service.py` (classe EmailService avec méthode send_email selon le contrat)
- [x] T014 [US2] Créer le dossier `usenghor_backend/app/templates/email/` et un template de base `base.html` (layout Jinja2 avec logo et footer USenghor)
- [x] T015 [P] [US2] Créer le template d'email de test `usenghor_backend/app/templates/email/test.html`
- [x] T016 [US2] Créer le schéma Pydantic pour la requête de test email dans `usenghor_backend/app/schemas/email.py`
- [x] T017 [US2] Créer le router admin email avec endpoint POST `/api/admin/email/test` dans `usenghor_backend/app/routers/admin/email.py`
- [x] T018 [US2] Enregistrer le router email dans `usenghor_backend/app/routers/admin/__init__.py`
- [x] T019 [US2] Vérifier l'envoi d'email de test depuis le VPS via l'endpoint admin

**Checkpoint**: Les emails sont envoyés et reçus correctement via Gmail SMTP

---

## Phase 5: User Story 3 - Configuration pérenne et sécurisée (Priority: P2)

**Goal**: La configuration de production est sécurisée et persiste au redémarrage

**Independent Test**: Redémarrer les conteneurs Docker et vérifier que le site et l'email fonctionnent

### Implementation for User Story 3

- [x] T020 [US3] Configurer le .env de production sur le VPS avec les credentials SMTP réels (SSH → `/opt/usenghor/.env`)
- [x] T021 [US3] Vérifier que `.env` et les credentials SMTP ne sont pas dans le code source (présence dans `.gitignore`, absence dans le repo)
- [x] T022 [US3] Vérifier la persistance : `./deploy.sh restart` puis `curl -I https://usenghor-francophonie.org` et test email

**Checkpoint**: La configuration est sécurisée et persistante

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Vérifications finales et nettoyage

- [x] T023 Vérifier le renouvellement automatique du certificat SSL (cron certbot présent sur le VPS)
- [x] T024 Valider le parcours complet du quickstart.md (toutes les étapes de vérification)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Pas de dépendance — peut démarrer immédiatement
- **Foundational (Phase 2)**: Dépend de Phase 1
- **US1 - Domaine/SSL (Phase 3)**: Dépend de Phase 2 — doit être terminée avant US2
- **US2 - Email SMTP (Phase 4)**: Dépend de Phase 2 (code) mais le déploiement/test nécessite US1 (HTTPS actif)
- **US3 - Sécurité/Persistance (Phase 5)**: Dépend de US1 + US2
- **Polish (Phase 6)**: Dépend de toutes les US

### User Story Dependencies

- **US1 (P1 - Domaine)**: Après Phase 2 — aucune dépendance sur les autres US
- **US2 (P1 - Email)**: Le code peut être développé en parallèle de US1, mais le test sur le VPS nécessite que US1 soit déployée
- **US3 (P2 - Persistance)**: Après US1 + US2

### Parallel Opportunities

- T001, T002, T003 peuvent être exécutées en parallèle (Phase 1 — fichiers différents)
- T013-T016 (code email) peuvent être développées en parallèle de T006-T009 (config nginx) — fichiers différents
- T015 (template test) peut être fait en parallèle de T013 (service email)

---

## Parallel Example: Phase 1

```bash
# Lancer en parallèle (fichiers différents) :
Task: "Mettre à jour .env.production.example"
Task: "Mettre à jour usenghor_backend/.env.example"
Task: "Ajouter smtp_from_email dans usenghor_backend/app/config.py"
```

## Parallel Example: US1 config + US2 code

```bash
# En parallèle (fichiers différents) :
Task: "Configurer nginx/nginx.conf (US1 T006-T009)"
Task: "Créer usenghor_backend/app/services/email.py (US2 T013)"
Task: "Créer usenghor_backend/app/schemas/email.py (US2 T016)"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Compléter Phase 1: Setup (T001-T003)
2. Compléter Phase 2: Foundational (T004-T005)
3. Compléter Phase 3: US1 - Domaine/SSL (T006-T012)
4. **STOP et VALIDER**: Le site est accessible en HTTPS
5. Déployer/démontrer si prêt

### Incremental Delivery

1. Setup + Foundational → Configuration de base prête
2. US1 → Site HTTPS fonctionnel → **MVP déployable**
3. US2 → Email opérationnel → Fonctionnalité complète
4. US3 → Sécurité et persistance validées → Production-ready
5. Polish → Vérifications finales

---

## Notes

- Les tâches de déploiement VPS (T010, T011, T019, T020, T022) nécessitent un accès SSH
- Le mot de passe SMTP Gmail ne doit JAMAIS être commité dans le repo
- Gmail limite l'envoi à ~2000 emails/jour (Google Workspace) — suffisant pour un site institutionnel
- Le certificat SSL Let's Encrypt se renouvelle automatiquement via le cron configuré par `deploy.sh ssl`
