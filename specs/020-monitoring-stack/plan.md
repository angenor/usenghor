# Implementation Plan: Socle de monitoring technique (système + conteneurs)

**Branch**: `020-monitoring-stack` | **Date**: 2026-05-15 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/020-monitoring-stack/spec.md`

## Summary

Première itération d'une stack d'observabilité technique pour Usenghor. Elle ajoute, **sans toucher au code applicatif**, quatre conteneurs Docker (Prometheus, Grafana, node-exporter, cAdvisor) qui collectent les métriques de la machine hôte et de chaque conteneur Docker, et les exposent via deux tableaux de bord pré-provisionnés. La stack vit dans un fichier de composition dédié activable à part (`docker-compose.monitoring.yml` côté backend), partage le réseau Docker existant (`usenghor_network`) pour préparer le scraping applicatif des itérations suivantes, et se pilote via une nouvelle sous-commande `./deploy.sh monitoring {up|down|logs|status}` au niveau du dépôt racine.

En production, Grafana est exposé via le reverse-proxy Nginx existant sous `https://monitoring.<DOMAINE>` (TLS Let's Encrypt + rate limiting Nginx). Prometheus, node-exporter et cAdvisor ne publient **aucun port** vers l'hôte ou Internet. Versions semver figées (FR-026), politique `restart: unless-stopped` (FR-023), `mem_limit` Docker pour faire respecter le budget RAM ~600 MB (FR-015) et le budget disque ~5 GB (FR-025). Toute la documentation opérationnelle est écrite en français dans `usenghor_nuxt/bank/documentations/monitoring-trafic/`.

## Technical Context

**Language/Version** : Bash 5+ (scripts shell), YAML (Docker Compose v3.8, Prometheus 2.x, Grafana provisioning), JSON (dashboards Grafana). Aucune modification de code Python/TypeScript dans cette itération (FR-020).
**Primary Dependencies** :
- Docker Engine ≥ 24, Docker Compose plugin ≥ 2.20 (déjà installés par `deploy.sh setup`)
- Images figées : `prom/prometheus:v2.55.1`, `grafana/grafana:11.4.0`, `prom/node-exporter:v1.8.2`, `gcr.io/cadvisor/cadvisor:v0.49.1` (FR-026 — versions à confirmer en research.md selon disponibilité au moment de l'implémentation)
- Nginx 1.27+ (déjà déployé en production via `usenghor_nginx`) + Certbot/Let's Encrypt (déjà géré par `deploy.sh ssl`)

**Storage** :
- Volume Docker nommé `prometheus_data` (TSDB Prometheus, rétention 30 j, budget ~5 GB — FR-004, FR-025)
- Volume Docker nommé `grafana_data` (DB SQLite Grafana, préférences utilisateur, plugins — FR-005)

**Testing** :
- Tests d'intégration manuels via `quickstart.md` (Phase 1)
- Vérifications automatisées par `./deploy.sh monitoring status` (FR-014)
- Tests de l'isolation réseau via `curl http://<host>:9090` depuis l'extérieur du VPS (doit échouer en prod — SC-006)
- Tests de rate limiting via outil de charge léger (`ab`, `hey`, `wrk`) ciblant `https://monitoring.<DOMAINE>` (SC-015)
- Aucune brique unit-test/CI nouvelle requise (feature infra ; pas de code applicatif modifié).

**Target Platform** : Linux Ubuntu LTS (VPS production, OVH) + macOS/Linux développeurs (local). Docker Compose obligatoire ; pas de support Docker Desktop spécifique requis.

**Project Type** : Infrastructure / DevOps (monorepo existant avec un sous-projet backend + un sous-projet frontend). Aucun nouveau service applicatif ; ajout d'une stack Docker satellite et adaptation de la couche réseau (Nginx) et du script de déploiement.

**Performance Goals** :
- Délai entre capture et visibilité d'une métrique : < 30 s (SC-003 ; correspond à un scrape interval Prometheus de 15 s + délai d'agrégation Grafana)
- Empreinte mémoire totale : ≤ 600 MB en régime nominal (FR-015, SC-007)
- Empreinte disque (volume Prometheus) : ≤ 5 GB après 30 j avec le périmètre actuel (FR-025, SC-016)

**Constraints** :
- Aucun port de Prometheus / node-exporter / cAdvisor exposé en production (FR-010, SC-006)
- En local uniquement, Prometheus écoute sur `127.0.0.1:9090` (pratique courante pour debug), Grafana sur `127.0.0.1:3001` (FR-011) — à confirmer si `9090` est aussi bindé en loopback local ou interne seulement
- Identifiants Grafana **jamais en clair** dans le repo (FR-007, FR-008) ; chargés via `.env` (non versionné) et `.env.example` (versionné, valeurs vides)
- Stack jointe au réseau `usenghor_network` existant pour permettre le scraping futur (FR-017)
- Le `deploy.sh` actuel SSH dans le VPS pour piloter `docker compose -f docker-compose.prod.yml ...` ; la sous-commande `monitoring` doit suivre la même mécanique (local + remote) sans casser les commandes existantes

**Scale/Scope** :
- 1 VPS unique, ~5 conteneurs applicatifs à scraper (nginx, frontend, backend, db, adminer/cron) + 1 hôte
- Volume métriques estimé : ~5 000 séries actives → ~1–3 GB sur 30 jours (confortable sous le budget 5 GB)
- 1 unique compte administrateur Grafana (FR-027)
- ~7 nouveaux fichiers de configuration sous `usenghor_backend/monitoring/` + 1 server-block Nginx + extension de `deploy.sh` + 4 documents Markdown opérationnels

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**État de la constitution du projet** : le fichier `.specify/memory/constitution.md` est encore un **template non rempli** (placeholders `[PRINCIPLE_*_NAME]`, `[PRINCIPLE_*_DESCRIPTION]`, etc.). Aucun principe formel n'est défini à l'échelle du dépôt à la date de cette itération.

**Conséquence** : il n'y a pas de gate constitutionnelle bloquante à vérifier formellement. Néanmoins, je consigne ci-dessous les principes implicites lisibles dans `CLAUDE.md` et `~/.claude/rules/` qui s'appliquent à cette feature, et je vérifie l'alignement :

| Principe implicite (source) | Application à cette feature | Statut |
|---|---|---|
| Pas d'accents / caractères spéciaux dans les **noms de fichiers/dossiers** (CLAUDE.md) | Tous les chemins ajoutés (`usenghor_backend/monitoring/...`, `docker-compose.monitoring.yml`, `monitoring-trafic/...`) utilisent `[a-z0-9_-]` uniquement. | ✅ Aligned |
| Français avec accents **dans les contenus** (CLAUDE.md) | Toute la documentation en français accentué ; commentaires des fichiers de config en français. | ✅ Aligned |
| Source de vérité = SQL ; toute modif de schéma → demander accord → mettre à jour SQL → puis code (CLAUDE.md) | Cette feature **ne touche pas le schéma SQL**. | ✅ N/A |
| Auto-maintenance de CLAUDE.md (CLAUDE.md) | Le plan prévoit l'ajout d'une ligne dans `## Active Technologies` et `## Recent Changes` via `update-agent-context.sh`. | ✅ Aligned |
| Pas de secrets en clair (rules/common/security.md) | FR-007 / FR-008 / FR-027 imposent variables d'env uniquement ; `.env.example` ne contient que des placeholders ; `.env` est `.gitignored` (vérifié dans `usenghor_backend/.gitignore`). | ✅ Aligned |
| Plus de petits fichiers que peu de gros (rules/common/coding-style.md) | Découpage : 1 compose, 1 prometheus.yml, 2 fichiers Grafana provisioning + 2 dashboards JSON, 1 server-block Nginx, 1 patch deploy.sh, 4 fichiers de doc — aucun fichier > 400 lignes. | ✅ Aligned |
| Modèles bien dimensionnés (rules/common/performance.md) | Pas de delegation LLM dans cette feature (infra). | ✅ N/A |

**Verdict** : aucune violation détectée. Aucun item à reporter dans **Complexity Tracking**.

## Project Structure

### Documentation (this feature)

```text
specs/020-monitoring-stack/
├── plan.md              # Ce fichier
├── spec.md              # Feature spec (validée par /speckit.clarify)
├── research.md          # Phase 0 — décisions techniques motivées
├── data-model.md        # Phase 1 — entités logiques (séries, volumes, comptes)
├── quickstart.md        # Phase 1 — procédure pas-à-pas locale et VPS
├── contracts/           # Phase 1 — contrats d'interface (CLI deploy.sh, schémas YAML, server-block Nginx)
│   ├── deploy-sh-monitoring.md      # Sous-commande CLI : signature, sorties attendues
│   ├── prometheus-config.md         # Schéma attendu de prometheus.yml (jobs, scrape interval)
│   ├── grafana-provisioning.md      # Schéma attendu des fichiers de provisioning Grafana
│   ├── docker-compose-monitoring.md # Services, ports, volumes, réseaux, restart, mem_limit
│   └── nginx-monitoring-vhost.md    # Server-block, TLS, rate limiting, headers
├── checklists/
│   └── requirements.md  # Checklist qualité (déjà validée)
└── tasks.md             # /speckit.tasks (à venir, hors de ce plan)
```

### Source Code (repository root)

Cette feature ne touche **aucun code applicatif** (FR-020). Elle ajoute des artefacts d'infrastructure et de configuration. Layout final dans le dépôt :

```text
.                                          # repo root
├── deploy.sh                              # MODIFIÉ : nouvelle sous-commande "monitoring {up|down|logs|status}"
├── docker-compose.prod.yml                # INCHANGÉ ici (la stack monitoring vit dans un fichier séparé)
├── .env.production.example                # MODIFIÉ : ajout GRAFANA_ADMIN_USER / GRAFANA_ADMIN_PASSWORD / MONITORING_DOMAIN
├── nginx/
│   ├── nginx.conf                         # MODIFIÉ : ajout d'un server-block pour monitoring.<DOMAINE> + zone rate-limit dédiée
│   ├── maintenance.html                   # INCHANGÉ
│   ├── maintenance_logo.png               # INCHANGÉ
│   └── ssl/                               # INCHANGÉ (certificats Let's Encrypt déjà gérés)
│
├── usenghor_backend/
│   ├── docker-compose.yml                 # INCHANGÉ
│   ├── docker-compose.monitoring.yml      # CRÉÉ : Prometheus, Grafana, node-exporter, cAdvisor
│   ├── .env.example                       # MODIFIÉ : ajout des 3 variables monitoring
│   └── monitoring/                        # CRÉÉ : ensemble des configurations
│       ├── prometheus/
│       │   └── prometheus.yml             # Jobs node-exporter + cadvisor (15s scrape, 30j retention)
│       └── grafana/
│           └── provisioning/
│               ├── datasources/
│               │   └── prometheus.yml     # Source de données automatique
│               └── dashboards/
│                   ├── dashboards.yml     # Loader (chemin /etc/grafana/provisioning/dashboards)
│                   ├── node-exporter-full.json   # Dashboard Grafana ID 1860
│                   └── docker-cadvisor.json      # Dashboard Grafana ID 193 (ou équivalent récent)
│
└── usenghor_nuxt/
    └── bank/
        └── documentations/
            └── monitoring-trafic/         # Documentation opérationnelle (4 fichiers à créer en plus des spec-N.md existants)
                ├── installation-locale.md
                ├── installation-vps.md
                ├── acces-dashboards.md
                └── sauvegarde-restauration.md
```

**Structure Decision** :

1. **Fichier de composition séparé plutôt que profil Compose** dans `usenghor_backend/docker-compose.yml`. Raison : le compose principal sert au dev local et l'orchestration prod passe par un `docker-compose.prod.yml` au repo root — il est plus propre d'isoler la stack monitoring dans son propre fichier réutilisable indifféremment en local et en prod (via un `-f` explicite dans `deploy.sh monitoring`).
2. **Réseau partagé** : `docker-compose.monitoring.yml` déclare `usenghor_network` comme `external: true` pour rejoindre celui déjà créé par le compose principal. Cela rend cAdvisor capable de découvrir les conteneurs Docker du même hôte (via le socket monté), et prépare le scraping de services applicatifs ultérieurs sans reconfiguration réseau (FR-017).
3. **Localisation des configurations dans `usenghor_backend/monitoring/`** plutôt qu'au repo root : aligné avec le fait que les compose Docker du projet vivent côté backend (le frontend est buildé statiquement à part). Cela centralise tout ce qui touche au runtime serveur dans `usenghor_backend/`.
4. **`deploy.sh` au repo root** : la sous-commande `monitoring` réutilise la même mécanique SSH-vers-VPS que les commandes existantes, mais opère sur `docker-compose.monitoring.yml` (chemin relatif `usenghor_backend/docker-compose.monitoring.yml`). En local, l'utilisateur peut aussi exécuter directement `cd usenghor_backend && docker compose -f docker-compose.monitoring.yml up -d`.
5. **Server-block Nginx unique** ajouté dans `nginx/nginx.conf` (pas de nouveau fichier dans `conf.d/` parce que la conf actuelle est un fichier monolithique). On crée une nouvelle `limit_req_zone monitoring:10m rate=30r/m` distincte des zones `api` et `general` existantes.

## Constitution Re-check (post-design)

Vérifications effectuées après la rédaction de `research.md`, `data-model.md`, des 5 contrats et de `quickstart.md` :

| Principe implicite | Vérification post-design | Statut |
|---|---|---|
| Noms de fichiers sans accents (`[a-z0-9_-]`) | Tous les chemins ajoutés (`docker-compose.monitoring.yml`, `monitoring/prometheus/`, `monitoring/grafana/provisioning/datasources/`, `monitoring/grafana/provisioning/dashboards/`, `monitoring-trafic/installation-locale.md`, etc.) sont conformes | ✅ |
| Français accentué dans les contenus | Tous les .md générés (spec, plan, research, data-model, contracts, quickstart) utilisent les accents | ✅ |
| Source de vérité SQL | Aucune modification de schéma (FR-020) | ✅ N/A |
| Auto-maintenance CLAUDE.md | Section `## Active Technologies` et `## Recent Changes` mises à jour | ✅ |
| Pas de secrets en clair | Variables `GRAFANA_ADMIN_*` accédées via `${VAR:?...}` ; `.env.example` versionné avec placeholders vides ; `.env` reste `.gitignored` | ✅ |
| Many small files | 10 artefacts spec créés (plan, spec, research, data-model, 5 contracts, quickstart, checklist) ; aucun > 400 lignes | ✅ |
| Modèles bien dimensionnés | Pas de delegation LLM nécessaire ; tasks (à venir) exécutables par un seul agent infra | ✅ |

**Verdict post-design** : aucune régression. Aucune violation à ajouter au Complexity Tracking.

## Complexity Tracking

Aucune violation à justifier. Constitution Check passe avant et après design.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|--------------------------------------|
| _(aucune)_ | _(n/a)_ | _(n/a)_ |
