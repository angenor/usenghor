---

description: "Task list for 020-monitoring-stack — Socle de monitoring technique"
---

# Tasks: Socle de monitoring technique (système + conteneurs)

**Input**: Design documents from `/specs/020-monitoring-stack/`
**Prerequisites** : plan.md ✓, spec.md ✓, research.md ✓, data-model.md ✓, contracts/ ✓, quickstart.md ✓

**Tests** : pas de tests de code (feature infrastructure pure). Chaque phase comporte une **étape de validation manuelle** qui exécute les tests d'acceptation listés dans les contrats (`contracts/*.md`).

**Organization** : tâches groupées par User Story (US1–US5) pour permettre une livraison MVP incrémentale.

## Format : `[ID] [P?] [Story] Description`

- **[P]** : parallélisable (fichier différent, aucune dépendance sur une tâche incomplète)
- **[Story]** : phase US1–US5 uniquement ; pas de label en Setup, Foundational et Polish
- Tous les chemins sont **absolus** depuis la racine du dépôt `/Users/mac/Documents/projets/2025/usenghor/`

## Path conventions

- Backend / monitoring : `usenghor_backend/monitoring/...`
- Compose monitoring : `usenghor_backend/docker-compose.monitoring.yml`
- Nginx prod : `nginx/nginx.conf` (repo root)
- Script CLI : `deploy.sh` (repo root)
- Variables d'env : `usenghor_backend/.env.example`, `.env.production.example` (repo root)
- Documentation finale : `usenghor_nuxt/bank/documentations/monitoring-trafic/`

---

## Phase 1 : Setup (arborescence et variables)

**Purpose** : créer l'arborescence cible et préparer les variables d'environnement avant toute configuration runtime.

- [X] T001 Créer l'arborescence `usenghor_backend/monitoring/` avec sous-dossiers `prometheus/`, `grafana/provisioning/datasources/`, `grafana/provisioning/dashboards/` (commande `mkdir -p ...`) — voir `plan.md` § Project Structure
- [X] T002 [P] Ajouter les variables `GRAFANA_ADMIN_USER`, `GRAFANA_ADMIN_PASSWORD`, `MONITORING_DOMAIN` (placeholders vides) en bas de `usenghor_backend/.env.example` sous une section commentée `# Monitoring (spec 020)` — conforme à FR-021 et data-model.md § Entité 7
- [X] T003 [P] Ajouter les mêmes 3 variables (avec placeholder `CHANGE_ME`) à `.env.production.example` (repo root) en bas, section `# Monitoring (spec 020)` — conforme à FR-007 (pas de secret en clair) et au pattern existant du fichier
- [X] T004 [P] Confirmer dans `usenghor_backend/.gitignore` que `.env` est bien ignoré (lecture seule, ne pas modifier si déjà présent ; sinon ajouter `.env`) — conforme à FR-007

**Checkpoint Setup** : arborescence créée, variables référencées, aucun secret commité. Phase 2 peut commencer.

---

## Phase 2 : Foundational (squelette Compose + Prometheus + Grafana)

**Purpose** : poser la **plomberie commune** dont toutes les user stories dépendent : compose skeleton, services Prometheus + Grafana, provisioning Grafana automatique. Les **exporters** (node-exporter, cAdvisor) et les **dashboards** sont ajoutés dans les phases user-story (Phase 3, Phase 4).

**⚠️ CRITICAL** : aucune user story ne peut commencer tant que cette phase n'est pas terminée. Les fichiers créés ici sont étendus (et non remplacés) par les phases ultérieures.

- [X] T005 Créer `usenghor_backend/docker-compose.monitoring.yml` avec : `version: "3.8"`, services `prometheus` (image `prom/prometheus:v2.55.1`, command incluant `--storage.tsdb.retention.time=30d` et `--storage.tsdb.retention.size=4500MB`, volume `prometheus_data`, healthcheck `/-/ready`, `mem_limit: 350m`, `mem_reservation: 200m`, `restart: unless-stopped`, network `usenghor_network`) et `grafana` (image `grafana/grafana:11.4.0`, env vars de hardening D-15 avec syntaxe `${VAR:?...}` pour `GRAFANA_ADMIN_USER`/`GRAFANA_ADMIN_PASSWORD`/`MONITORING_DOMAIN`, volume `grafana_data` + montage `./monitoring/grafana/provisioning:/etc/grafana/provisioning:ro`, healthcheck `/api/health`, `mem_limit: 200m`, `mem_reservation: 100m`, `restart: unless-stopped`, `depends_on prometheus service_healthy`, network `usenghor_network`) ; déclarer `volumes: prometheus_data, grafana_data` (avec `name: usenghor_monitoring_*_data`) et `networks: usenghor_network: external: true, name: usenghor_network` — conforme au contrat `contracts/docker-compose-monitoring.md`
- [X] T006 [P] Créer `usenghor_backend/docker-compose.monitoring.override.yml` (override local uniquement) avec mappings `127.0.0.1:9090:9090` pour Prometheus et `127.0.0.1:3001:3000` pour Grafana, override `GF_SECURITY_COOKIE_SECURE=false`, `GF_SERVER_ROOT_URL=http://localhost:3001`, `GF_SERVER_DOMAIN=localhost` — conforme à D-05 et D-15 § Note environnement local
- [X] T007 [P] Créer `usenghor_backend/monitoring/prometheus/prometheus.yml` avec section `global` (scrape_interval 15s, evaluation_interval 15s, external_labels `cluster: usenghor`, `env: ${PROMETHEUS_ENV:-local}`) et une section `scrape_configs: []` vide à ce stade (les jobs sont ajoutés par US1 et US2) — conforme à `contracts/prometheus-config.md`
- [X] T008 [P] Créer `usenghor_backend/monitoring/grafana/provisioning/datasources/prometheus.yml` avec `apiVersion: 1` et un datasource Prometheus (uid `prometheus`, url `http://prometheus:9090`, `access: proxy`, `isDefault: true`, `editable: false`, `jsonData.timeInterval: 15s`) — conforme à `contracts/grafana-provisioning.md`
- [X] T009 [P] Créer `usenghor_backend/monitoring/grafana/provisioning/dashboards/dashboards.yml` avec un provider `default` (`type: file`, `disableDeletion: true`, `allowUiUpdates: false`, `updateIntervalSeconds: 30`, `options.path: /etc/grafana/provisioning/dashboards`) — conforme à `contracts/grafana-provisioning.md`
- [X] T010 Valider la fondation : exécuter `cd usenghor_backend && docker compose -f docker-compose.monitoring.yml --env-file .env config` (sortie sans erreur) puis `docker compose -f docker-compose.monitoring.yml up -d` (en pré-requis : `usenghor_network` existe ; si non, lancer `docker compose up -d` du compose principal d'abord) ; vérifier que `prometheus` et `grafana` atteignent l'état `healthy` (~90 s) ; ouvrir `http://localhost:3001` et confirmer la page de login Grafana ; vérifier `http://localhost:9090/-/ready` répond 200. Lancer aussi sans `GRAFANA_ADMIN_PASSWORD` dans `.env` pour confirmer que Compose échoue avec le message d'erreur explicite (T-CMP-2) — conforme aux tests T-CMP-1, T-CMP-2, T-CMP-3 et au critère SC-018

**Checkpoint Foundational** : Prometheus + Grafana healthy, login Grafana visible, 0 target (normal — exporters arrivent en US1/US2). Les phases US1, US2, US3, US4, US5 peuvent maintenant être démarrées (avec contraintes de fichier partagé documentées dans Dependencies plus bas).

---

## Phase 3 : User Story 1 — Surveiller la santé du VPS (Priority : P1) 🎯 MVP

**Goal** : ajouter l'exporter système (node-exporter) et le dashboard Node Exporter Full pour rendre visibles CPU, RAM, disque, réseau et load average de la machine hôte.

**Independent Test** : après l'exécution des tâches ci-dessous, démarrer la stack puis ouvrir Grafana en local — le dashboard « Node Exporter Full » s'affiche automatiquement avec des chiffres non nuls et mis à jour. Critères d'acceptation US1-1, US1-2, US1-3 de la spec.

### Implementation for User Story 1

- [X] T011 [US1] Ajouter le service `node-exporter` à `usenghor_backend/docker-compose.monitoring.yml` (image `prom/node-exporter:v1.8.2`, container_name `usenghor_monitoring_node_exporter`, `restart: unless-stopped`, command avec `--path.procfs=/host/proc --path.sysfs=/host/sys --path.rootfs=/rootfs --collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)`, `pid: host`, volumes ro `/proc:/host/proc`, `/sys:/host/sys`, `/:/rootfs:ro,rslave`, `mem_limit: 50m`, `mem_reservation: 20m`, network `usenghor_network`) — voir `contracts/docker-compose-monitoring.md`
- [X] T012 [P] [US1] Ajouter un job de scrape `node-exporter` à `usenghor_backend/monitoring/prometheus/prometheus.yml` sous `scrape_configs` (target `node-exporter:9100`, label `service: vps-host`) — voir `contracts/prometheus-config.md` § Champs obligatoires
- [X] T013 [P] [US1] Télécharger le JSON du dashboard Grafana ID 1860 depuis `https://grafana.com/api/dashboards/1860/revisions/latest/download`, sauvegarder sous `usenghor_backend/monitoring/grafana/provisioning/dashboards/node-exporter-full.json`, puis **adapter** : supprimer les blocs `__inputs` et `__requires`, remplacer toutes les références `${DS_PROMETHEUS}` par `prometheus`, forcer la propriété racine `"uid": "node-exporter-full"`, fixer `"refresh": "30s"` — conforme à `contracts/grafana-provisioning.md` § `dashboards/node-exporter-full.json`
- [X] T014 [US1] Validation US1 : redémarrer la stack (`docker compose -f docker-compose.monitoring.yml up -d --force-recreate`), ouvrir `http://localhost:9090/targets` et confirmer la cible `node-exporter` à l'état `UP`, ouvrir `http://localhost:3001`, se connecter, naviguer vers Dashboards → « Node Exporter Full » et confirmer que les panneaux CPU/RAM/disque/réseau/load affichent des valeurs réelles et se mettent à jour. Mesurer le délai capture → visibilité (doit être < 30 s, SC-003). Exécuter aussi un test de purge simulée pour vérifier que la rétention `4500MB` arbitre correctement si déclenchée — couvre US1-1, US1-2, US1-3, SC-003 et partiellement FR-002

**Checkpoint US1** : MVP atteint — un administrateur peut voir l'état du VPS en local. Démo possible.

---

## Phase 4 : User Story 2 — Identifier le conteneur Docker qui consomme (Priority : P2)

**Goal** : ajouter l'exporter par conteneur (cAdvisor) et le dashboard Docker / cAdvisor pour rendre visible la consommation CPU/RAM/I/O/réseau de chaque conteneur Docker.

**Independent Test** : avec les services applicatifs (frontend, backend, db) actifs, ouvrir Grafana et constater que le dashboard « Docker / cAdvisor » liste chaque conteneur avec ses métriques propres mises à jour automatiquement. Critères d'acceptation US2-1 et US2-2.

### Implementation for User Story 2

- [X] T015 [US2] Ajouter le service `cadvisor` à `usenghor_backend/docker-compose.monitoring.yml` (image `gcr.io/cadvisor/cadvisor:v0.49.1`, container_name `usenghor_monitoring_cadvisor`, `restart: unless-stopped`, `privileged: true`, `devices: [/dev/kmsg]`, volumes ro `/:/rootfs`, `/var/run:/var/run`, `/sys:/sys`, `/var/lib/docker/:/var/lib/docker`, `/dev/disk/:/dev/disk`, `/var/run/docker.sock:/var/run/docker.sock`, `mem_limit: 200m`, `mem_reservation: 100m`, network `usenghor_network`) — voir `contracts/docker-compose-monitoring.md`
- [X] T016 [P] [US2] Ajouter un job de scrape `cadvisor` à `usenghor_backend/monitoring/prometheus/prometheus.yml` sous `scrape_configs` (target `cadvisor:8080`, label `service: docker-containers`) — voir `contracts/prometheus-config.md`
- [X] T017 [P] [US2] Télécharger le JSON du dashboard Grafana ID 14282 depuis `https://grafana.com/api/dashboards/14282/revisions/latest/download` (fallback ID 193 si 14282 inutilisable), sauvegarder sous `usenghor_backend/monitoring/grafana/provisioning/dashboards/docker-cadvisor.json`, appliquer les mêmes adaptations qu'au T013 : suppression `__inputs`/`__requires`, références datasource → `prometheus`, `"uid": "docker-cadvisor"`, `"refresh": "30s"` — voir `contracts/grafana-provisioning.md`
- [ ] T018 [US2] Validation US2 : redémarrer la stack, vérifier que la cible `cadvisor` est `UP` sur `http://localhost:9090/targets`, ouvrir le dashboard « Docker / cAdvisor » dans Grafana et confirmer qu'il liste les conteneurs applicatifs (`usenghor_frontend`, `usenghor_backend`, `usenghor_postgres`, `usenghor_adminer` plus les 4 du monitoring) avec leurs métriques CPU/RAM/I/O/réseau. Stopper un conteneur applicatif et observer la chute dans l'historique du dashboard — couvre US2-1, US2-2, FR-003

**Checkpoint US2** : visibilité par conteneur disponible. Démo possible (US1 + US2).

---

## Phase 5 : User Story 3 — Sécuriser l'accès aux dashboards en production (Priority : P2)

**Goal** : exposer Grafana en HTTPS via `monitoring.<DOMAINE>` derrière Nginx existant, avec rate limiting et certificat Let's Encrypt, sans exposer Prometheus/exporters publiquement.

**Independent Test** : depuis Internet, `https://monitoring.<DOMAINE>` retourne un certificat valide et exige une authentification ; les ports 9090/3000 du VPS ne sont pas joignables. Critères d'acceptation US3-1, US3-2, US3-3.

> **Note de dépendance** : techniquement, cette story exige que la stack soit déployée sur le VPS, ce qui passe par US5 (deploy.sh). Pour rester pragmatique, on accepte de tester cette story manuellement (sans `./deploy.sh monitoring up`) via un déploiement initial manuel sur le VPS. US5 viendra automatiser le pilotage.

### Implementation for User Story 3

- [X] T019 [US3] Ajouter les deux zones de rate limiting à `nginx/nginx.conf`, dans le bloc `http {}`, juste après les zones existantes `api` et `general` : `limit_req_zone $binary_remote_addr zone=monitoring:10m rate=30r/m;` puis `limit_req_zone $binary_remote_addr zone=monitoring_login:10m rate=5r/m;` — voir `contracts/nginx-monitoring-vhost.md`
- [X] T020 [US3] Ajouter dans `nginx/nginx.conf` (bloc `http {}`, après les autres `upstream`) un `upstream grafana { server grafana:3000; keepalive 16; }`
- [X] T021 [US3] Ajouter dans `nginx/nginx.conf` un `server { listen 80; server_name monitoring.usenghor-francophonie.org; return 301 https://$host$request_uri; }` pour la redirection HTTP→HTTPS du sous-domaine
- [X] T022 [US3] Ajouter dans `nginx/nginx.conf` le server-block HTTPS complet pour `monitoring.usenghor-francophonie.org` (listen 443 ssl http2, certificats `/etc/nginx/ssl/fullchain.pem` et `/etc/nginx/ssl/privkey.pem`, TLSv1.2/1.3, ciphers ECDHE-*, HSTS 2 ans, X-Frame-Options SAMEORIGIN, X-Content-Type-Options nosniff, Referrer-Policy, `client_max_body_size 32M`, `limit_req zone=monitoring burst=20 nodelay`, location `~ ^/(login|api/login|api/user/password/reset)` avec `limit_req zone=monitoring_login burst=5 nodelay`, location `/api/live/` avec WebSocket Upgrade et `proxy_buffering off`, location `/` standard avec proxy_pass `http://grafana` + headers `X-Forwarded-Proto/-Host/-For`, `Host $host`) — copier strictement la conf de `contracts/nginx-monitoring-vhost.md` § Server-block dédié
- [X] T023 [US3] Vérifier le bon fonctionnement local du fichier Nginx via `docker run --rm -v $(pwd)/nginx/nginx.conf:/etc/nginx/nginx.conf:ro nginx:alpine nginx -t` (test de syntaxe ; doit retourner `syntax is ok` et `test is successful`)
- [ ] T024 [US3] Étendre le certificat Let's Encrypt côté VPS pour inclure le SAN `monitoring.usenghor-francophonie.org` : SSH dans le VPS via `./deploy.sh connect` puis exécuter `sudo certbot certonly --webroot -w /var/www/html -d usenghor-francophonie.org -d www.usenghor-francophonie.org -d monitoring.usenghor-francophonie.org --expand` ; vérifier que les fichiers `/opt/usenghor/nginx/ssl/fullchain.pem` et `privkey.pem` couvrent bien le nouveau SAN (`openssl x509 -in /etc/letsencrypt/live/usenghor-francophonie.org/cert.pem -text | grep DNS:`)
- [ ] T025 [US3] Validation US3 : déployer la nouvelle `nginx.conf` (via `./deploy.sh deploy` ou `scp` manuel + `./deploy.sh restart nginx`), démarrer la stack monitoring sur le VPS, puis depuis un poste externe : `curl -I https://monitoring.usenghor-francophonie.org` retourne 200/302 avec HSTS ; `curl -I http://monitoring.usenghor-francophonie.org` retourne 301 vers HTTPS ; navigateur charge la page de connexion Grafana sans avertissement de certificat ; `curl -m 5 http://<IP-VPS>:9090` et `curl -m 5 http://<IP-VPS>:3000` échouent (timeout / connection refused) ; envoyer 35 requêtes en 1 min sur `monitoring.usenghor-francophonie.org` et observer au moins 5 réponses `429 Too Many Requests` — couvre T-NGX-1, T-NGX-3, T-NGX-4, T-NGX-7, T-NGX-8 et SC-005, SC-006, SC-015, SC-018

**Checkpoint US3** : production sécurisée — accès HTTPS authentifié pour les administrateurs, exporters isolés.

---

## Phase 6 : User Story 4 — Conserver et restaurer l'historique (Priority : P3)

**Goal** : documenter la procédure de sauvegarde et restauration des volumes `prometheus_data` et `grafana_data` (la persistance et la rétention 30 j / 4.5 GB sont déjà acquises via T005). Vérifier le bon comportement de la rétention et du restart auto.

**Independent Test** : suivre la procédure documentée, sauvegarder les deux volumes, supprimer les volumes, restaurer, vérifier que l'historique et la configuration Grafana sont retrouvés. Redémarrer le démon Docker et vérifier la persistance + le restart auto.

### Implementation for User Story 4

- [X] T026 [US4] Créer `usenghor_nuxt/bank/documentations/monitoring-trafic/sauvegarde-restauration.md` (français accentué, 200–400 lignes) contenant : section « Quels volumes sauvegarder » (deux : `usenghor_monitoring_prometheus_data` et `usenghor_monitoring_grafana_data`, rôles différents, taille typique), procédure de sauvegarde Prometheus avec `docker compose stop prometheus` + `docker run --rm -v ... busybox tar czf ... -C /data .` + `docker compose start prometheus`, procédure de sauvegarde Grafana à chaud (tolère SQLite WAL), procédure de restauration (stop des deux conteneurs, vidage du volume cible, extraction du tar.gz, start), section « Cadence recommandée » (hebdomadaire en prod, à la demande en local), section « Vérification après restauration » (rouvrir les dashboards et chercher des samples > 24h), section « Que sauvegarder en plus du volume » (rappel : `docker-compose.monitoring.yml`, `monitoring/`, `.env` chiffré séparément) — couvre FR-016, FR-018 et conforme à D-07
- [ ] T027 [US4] Validation US4 — Roundtrip backup/restore : démarrer la stack, laisser collecter ≥ 1 h, sauvegarder selon la procédure de T026, exécuter `docker compose down` puis `docker volume rm usenghor_monitoring_prometheus_data usenghor_monitoring_grafana_data`, suivre la procédure de restauration, redémarrer la stack et confirmer que l'historique des métriques pré-suppression est intact dans Grafana et que les préférences Grafana sont retrouvées — couvre SC-010
- [ ] T028 [US4] Validation US4 — Restart auto : pendant que la stack tourne, exécuter `docker kill usenghor_monitoring_prometheus` et observer le redémarrage automatique (état `Up` à nouveau dans `docker compose ps` < 60 s). Ensuite, redémarrer le démon Docker (`sudo systemctl restart docker` sur Linux, ou redémarrer Docker Desktop sur macOS) et vérifier que les 4 conteneurs reviennent à `Up` sans intervention, avec leur historique de métriques antérieur intact dans Grafana — couvre SC-013, SC-014, FR-023

**Checkpoint US4** : procédure backup/restore opérationnelle, persistance et restart auto validés.

---

## Phase 7 : User Story 5 — Pilotage via `deploy.sh` (Priority : P3)

**Goal** : ajouter une sous-commande `monitoring {up|down|logs|status}` au script `deploy.sh` existant pour piloter la stack uniformément, en local et sur le VPS.

**Independent Test** : exécuter chaque sous-commande et vérifier l'effet sur les conteneurs.

### Implementation for User Story 5

- [X] T029 [US5] Ajouter à `deploy.sh` (repo root) une fonction shell `monitoring()` placée après la fonction `backup()` existante (avant le `case "$1"` final), conforme au pseudocode de `research.md` § D-12 et au contrat `contracts/deploy-sh-monitoring.md` : `SUBCOMMAND=${2:-}`, switch sur `up|down|logs|status`, opérations via SSH dans `${REMOTE_DIR}` ciblant `usenghor_backend/docker-compose.monitoring.yml`, `up` synchronise au préalable `docker-compose.monitoring.yml` + l'arborescence `monitoring/` via `scp`, cas par défaut affiche l'usage et `exit 1`
- [X] T030 [US5] Ajouter dans le `case "$1"` final de `deploy.sh` la branche `monitoring) monitoring "$@" ;;` (entre `connect)` et le `*)` par défaut) et mettre à jour le bloc d'aide imprimé dans le `*)` (lignes `echo "Commands:"` et `echo "  monitoring     - Stack monitoring: ./deploy.sh monitoring {up|down|logs|status}"` + exemple correspondant en bas du `*)`)
- [X] T031 [US5] Vérifier que `deploy.sh` reste exécutable (`chmod +x deploy.sh` si nécessaire, puis `./deploy.sh` sans argument doit lister la nouvelle commande `monitoring` dans son aide)
- [ ] T032 [US5] Validation US5 — Cycle complet : avec la stack initialement arrêtée, exécuter `./deploy.sh monitoring up` (les 4 conteneurs démarrent), puis `./deploy.sh monitoring status` (tableau listant les 4 services + état), puis `./deploy.sh monitoring logs` (stream actif, Ctrl+C pour quitter), puis `./deploy.sh monitoring down` (4 conteneurs arrêtés, `docker volume ls` montre que `prometheus_data` et `grafana_data` sont préservés), enfin `./deploy.sh monitoring foo` (sous-commande inconnue, message d'usage sur stderr, exit 1) — couvre T-CLI-1 à T-CLI-7 et SC-011

**Checkpoint US5** : opérabilité unifiée via `deploy.sh`. Toutes les user stories sont indépendamment fonctionnelles.

---

## Phase 8 : Polish & Cross-Cutting Concerns

**Purpose** : finaliser la documentation utilisateur, exécuter la procédure quickstart de bout en bout, vérifier l'ensemble des critères d'acceptation, mettre à jour les fichiers transverses.

- [X] T033 [P] Créer `usenghor_nuxt/bank/documentations/monitoring-trafic/installation-locale.md` (français accentué, 150–250 lignes) : pré-requis Docker, configuration `.env`, lancement compose, vérification healthchecks, accès Grafana en local, dépannage. Reprendre la section A de `quickstart.md` en l'enrichissant pour un public développeur — couvre FR-018, SC-009
- [X] T034 [P] Créer `usenghor_nuxt/bank/documentations/monitoring-trafic/installation-vps.md` (français accentué, 150–250 lignes) : configuration DNS, extension certificat Let's Encrypt, configuration `.env` prod, déploiement Nginx, lancement via `./deploy.sh monitoring up`, vérification HTTPS et isolation des ports. Reprendre la section B de `quickstart.md` — couvre FR-018, SC-009
- [X] T035 [P] Créer `usenghor_nuxt/bank/documentations/monitoring-trafic/acces-dashboards.md` (français accentué, 100–200 lignes) : URL locale et production, login, navigation entre les deux dashboards, lecture des panneaux clés (interprétation des couleurs, seuils), changement de période d'observation, raccourcis clavier utiles. Décrire les unités (bytes vs. percent), à quoi sert chaque panneau, comment poser un filtre par conteneur — couvre FR-018
- [ ] T036 Exécuter de bout en bout le `quickstart.md` (sections A1 → A7) avec un chronomètre, à partir d'un dépôt fraîchement cloné (ou un poste qui n'a pas encore lancé la stack) ; valider que la durée totale est < 15 minutes (SC-009)
- [ ] T037 Audit final des critères d'acceptation : passer en revue chacun des 18 SC de `spec.md` (SC-001 à SC-018) et cocher la validation correspondante dans une note de PR (ou directement dans `checklists/requirements.md`). Vérifier en particulier : SC-006 (test d'isolation depuis l'extérieur du VPS), SC-007 (consommation RAM cumulée sur 24h via `docker stats`), SC-017 (`grep -E ':v?[0-9]' usenghor_backend/docker-compose.monitoring.yml | wc -l` ≥ 4), SC-018 (tentative d'inscription publique refusée)
- [X] T038 [P] Vérifier que `CLAUDE.md` (déjà mis à jour par `/speckit.plan`) contient la ligne `(020-monitoring-stack)` dans `## Active Technologies` et dans `## Recent Changes` ; corriger si nécessaire (auto-maintenance demandée par `CLAUDE.md` § Auto-maintenance)
- [ ] T039 Commit final : commit Git unique (ou regroupé par phase si l'équipe préfère). Message conventionnel : `feat(monitoring): socle Prometheus + Grafana + node-exporter + cAdvisor (spec 020)`. Vérifier que `.env` n'est pas inclus dans le commit (`git status`), que les fichiers `.env.example` et `.env.production.example` le sont, que les dashboards JSON adaptés sont inclus

**Checkpoint Polish** : feature livrable. Documentation complète, validation chronométrée, critères vérifiés, commit propre.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 — Setup** : aucune dépendance ; peut commencer immédiatement.
- **Phase 2 — Foundational** : dépend de Phase 1. **BLOQUE toutes les User Stories.**
- **Phase 3 — US1 (MVP)** : dépend de Phase 2.
- **Phase 4 — US2** : dépend de Phase 2. Peut se faire **après** US1 ou en parallèle (mais conflit de fichier sur compose et prometheus.yml — voir contraintes ci-dessous).
- **Phase 5 — US3** : dépend de Phase 2. Peut se faire en parallèle de US1/US2/US4/US5 (modifie uniquement `nginx/nginx.conf` + côté VPS).
- **Phase 6 — US4** : dépend de Phase 2 et idéalement de US1 ou US2 (pour avoir des données à sauvegarder). N'a pas de conflit de fichier avec les autres.
- **Phase 7 — US5** : dépend de Phase 2. Modifie uniquement `deploy.sh`, sans conflit avec les autres.
- **Phase 8 — Polish** : dépend de toutes les phases user-story souhaitées pour la livraison. La doc finale (T033/T034/T035) peut commencer dès que US1 est terminée pour ce qui concerne la partie système.

### Conflits de fichiers entre User Stories (lecture impérative)

| Fichier | US qui le modifient | Stratégie |
|---|---|---|
| `usenghor_backend/docker-compose.monitoring.yml` | US1 (T011 ajout node-exporter), US2 (T015 ajout cadvisor) | **Séquentiel** : exécuter T011 puis T015 sur le même développeur, ou coordonner via rebase si parallélisé |
| `usenghor_backend/monitoring/prometheus/prometheus.yml` | US1 (T012 ajout job node-exporter), US2 (T016 ajout job cadvisor) | **Séquentiel** : ajouter les deux jobs sous `scrape_configs:` ; rebase facile si parallèle (chaque job est un bloc indépendant) |
| `nginx/nginx.conf` | US3 uniquement (T019–T022) | Pas de conflit avec autres US |
| `deploy.sh` | US5 uniquement (T029–T031) | Pas de conflit avec autres US |
| Dashboards JSON et fichiers .env.example | Story spécifique chacun | Pas de conflit |

### Within Each User Story

- Pas de tests de code à écrire en premier (feature infra).
- Ordre interne : ajouter le **service Docker** (T011/T015) → ajouter le **job Prometheus** (T012/T016) → ajouter le **dashboard JSON** (T013/T017) → **valider** (T014/T018). Les deux premiers ont une dépendance de cohérence (le job référence un service DNS) ; T013/T017 ne dépendent que des décisions de design (D-10), pas du runtime.

### Parallel Opportunities

| Étape | Tâches parallélisables |
|---|---|
| Phase 1 | T002, T003, T004 (fichiers différents) |
| Phase 2 | T006, T007, T008, T009 (fichiers différents) après T005 (ordre conceptuel : compose d'abord). En réalité, T005, T007, T008, T009 sont tous indépendants : ils peuvent être parallélisés à 4 mains. T006 peut suivre T005 |
| Phase 3 US1 | T012 et T013 en parallèle après T011 |
| Phase 4 US2 | T016 et T017 en parallèle après T015 |
| Phase 5 US3 | T019–T022 séquentiels (même fichier), puis T023 et T024 en parallèle |
| Phase 8 Polish | T033, T034, T035, T038 en parallèle (fichiers différents) |

### Cross-Story Parallelism

Avec une équipe de 3 développeurs après Foundational :
- Dev A : US1 (T011 → T014)
- Dev B : US3 (T019 → T025) — fichier complètement disjoint
- Dev C : US5 (T029 → T032) — fichier complètement disjoint
- Une fois US1 terminée, Dev A enchaîne sur US2 (T015 → T018), puis US4 (T026 → T028).

---

## Parallel Example : Foundational Phase

```bash
# Après T005 (docker-compose.monitoring.yml), lancer en parallèle :
Task: "Créer docker-compose.monitoring.override.yml" (T006)
Task: "Créer prometheus.yml skeleton" (T007)
Task: "Créer datasources/prometheus.yml" (T008)
Task: "Créer dashboards/dashboards.yml" (T009)
# Puis T010 (validation) une fois tous les fichiers prêts.
```

## Parallel Example : User Story 1

```bash
# Après T011 (service node-exporter dans compose), lancer en parallèle :
Task: "Ajouter job node-exporter à prometheus.yml" (T012)
Task: "Télécharger et adapter node-exporter-full.json" (T013)
# Puis T014 (validation US1).
```

---

## Implementation Strategy

### MVP First (User Story 1 seulement)

1. Phase 1 — Setup
2. Phase 2 — Foundational
3. Phase 3 — US1
4. **STOP & VALIDATE** : ouvrir Grafana en local, vérifier les métriques système
5. Démo / utilisable comme premier outil d'observabilité local

### Incremental Delivery

1. Setup + Foundational → fondation prête
2. + US1 → MVP local utilisable
3. + US2 → vision complète locale (système + conteneurs)
4. + US3 → mise en prod sécurisée
5. + US4 → confiance dans la persistance et procédure de récupération
6. + US5 → ergonomie opérationnelle finale
7. + Polish → documentation complète, validation chronométrée, commit unique

### Recommended Sequencing

Bien que techniquement US3/US4/US5 puissent commencer après Foundational, l'ordre **opérationnellement le plus sûr** est :

```
Setup → Foundational → US1 (MVP local) → US2 (vision complète locale)
       → US5 (pilotage CLI ; rend US3 testable plus confortablement)
       → US3 (mise en prod sécurisée)
       → US4 (backup/restore validés en prod)
       → Polish
```

US5 avant US3 ? Oui : `./deploy.sh monitoring up` rend les tests d'isolation et de rate limiting en prod plus rapides à itérer. Mais ce n'est pas une dépendance dure : on peut faire US3 d'abord et exécuter les commandes Docker Compose manuellement via SSH.

---

## Notes

- `[P]` = parallélisable (fichier différent, aucune dépendance sur tâche incomplète)
- `[Story]` = trace la tâche à une user story pour pilotage MVP
- Aucune tâche de code applicatif (Nuxt, FastAPI) — feature 100 % infra, conforme à FR-020
- Pas de tests de code à écrire (feature infra) ; toute validation est une procédure manuelle en fin de phase
- Commit conseillé à chaque checkpoint de phase, pas à chaque tâche, pour garder un historique lisible
- Si une tâche échoue, **lire d'abord** `research.md` (décision motivée) et le `contracts/*.md` correspondant (test attendu) avant de débugger
- Toutes les décisions techniques motivées sont tracées dans `research.md` ; les modifications de décision DOIVENT mettre à jour `research.md` ET `plan.md` ET `tasks.md` en miroir
