# Phase 1 — Modèle de données / Entités

**Feature** : 020-monitoring-stack
**Date** : 2026-05-15

Cette feature n'introduit **aucune table SQL ni schéma applicatif** (FR-020). Le « modèle de données » décrit ici concerne uniquement les artefacts d'infrastructure : ressources Docker, fichiers de configuration, séries temporelles Prometheus et données Grafana. Ces entités servent de référentiel partagé entre `plan.md`, les contracts et `tasks.md`.

---

## Diagramme logique

```text
                ┌──────────────────────────────────────┐
                │       Hôte VPS / poste local         │
                │                                      │
                │  ┌────────────────────────────────┐  │
                │  │     usenghor_network (bridge)  │  │
                │  │                                │  │
                │  │  ┌──────────┐    ┌─────────┐   │  │
                │  │  │Prometheus│◄───┤node-exp.│   │  │
                │  │  │   :9090  │    └─────────┘   │  │
                │  │  │   TSDB───┼──► [prometheus_data]
                │  │  └──┬───────┘    ┌─────────┐   │  │
                │  │     ▲            │cAdvisor │   │  │
                │  │     └────────────┤  :8080  │   │  │
                │  │                  └────┬────┘   │  │
                │  │                       │        │  │
                │  │                       ▼        │  │
                │  │              [/var/run/docker.sock]
                │  │                                │  │
                │  │  ┌──────────┐                  │  │
                │  │  │ Grafana  │── lit ─►  Prometheus
                │  │  │  :3000   │── ecrit ─► [grafana_data]
                │  │  └─────▲────┘                  │  │
                │  └────────┼───────────────────────┘  │
                │           │                          │
                └───────────┼──────────────────────────┘
                            │                  ▲
        Local: 127.0.0.1:3001                  │ HTTPS (TLS)
        Prod : Nginx reverse-proxy ────────────┘
                via monitoring.<DOMAINE>
                + rate-limit zones
```

---

## Entité 1 — Conteneur de monitoring

Représente une unité d'exécution Docker dans la stack.

| Attribut | Description | Contraintes |
|---|---|---|
| `name` | Nom du conteneur Docker | Unique, kebab-case, préfixe `usenghor_monitoring_` ; valeurs : `usenghor_monitoring_prometheus`, `usenghor_monitoring_grafana`, `usenghor_monitoring_node_exporter`, `usenghor_monitoring_cadvisor` |
| `image` | Tag d'image | `<repository>:<semver>` figé (FR-026) — ex. `prom/prometheus:v2.55.1` |
| `restart_policy` | Politique de redémarrage | Toujours `unless-stopped` (FR-023) |
| `mem_limit` | Plafond mémoire Docker | Conforme à D-03 du research.md |
| `mem_reservation` | Réservation mémoire | Conforme à D-03 |
| `network` | Réseau Docker | `usenghor_network` (externe, D-13) |
| `ports_exposed_host` | Ports mappés sur l'hôte | Voir tableau ci-dessous |
| `volumes` | Volumes montés | Voir Entité 4 |
| `healthcheck` | Test de santé | Présent pour Prometheus + Grafana (D-06), absent pour les exporters |

### Mapping de ports par environnement

| Service | Local (override) | Production |
|---|---|---|
| Prometheus | `127.0.0.1:9090 → 9090` | _(aucun)_ |
| Grafana | `127.0.0.1:3001 → 3000` | _(aucun, Nginx assure le proxy)_ |
| node-exporter | _(aucun)_ | _(aucun)_ |
| cAdvisor | _(aucun)_ | _(aucun)_ |

### Transitions d'état (cycle de vie)

```
[non créé] ──(docker compose up)──► [created]
                                       │
                                       ▼
                                   [starting]
                                       │
                                       ▼
                            [running, unhealthy*]
                                       │
                                       ▼
                              [running, healthy]
                                       │
                          ┌────────────┼─────────────┐
                 (deploy.sh down)   (crash)    (docker stop)
                          │            │             │
                          ▼            ▼             ▼
                       [exited]   [restarting]   [exited]
                                       │
                                       ▼
                             [running, healthy]
                            (auto via unless-stopped)
```

*« unhealthy » : transition temporaire pendant le démarrage (durée maximale ~90 s : 3 retries × 30 s interval).

---

## Entité 2 — Cible de scraping Prometheus (`target`)

Représente une endpoint HTTP `/metrics` que Prometheus interroge périodiquement.

| Attribut | Description | Valeur dans cette itération |
|---|---|---|
| `job` | Nom logique du groupe de cibles | `node-exporter` ou `cadvisor` |
| `instance` | Adresse `<host>:<port>` | `node-exporter:9100` ou `cadvisor:8080` (résolution DNS Docker) |
| `scrape_interval` | Période de collecte | 15 s (D-02) |
| `metrics_path` | Chemin HTTP | `/metrics` (défaut) |
| `scheme` | Protocole | `http` (réseau interne uniquement) |
| `state` | État courant | `UP` / `DOWN` (lu via `http://localhost:9090/targets` en local) |

**Invariant** : exactement 2 cibles dans cette itération (FR-002 + FR-003). Aucune autre cible n'est ajoutée par cette feature (les jobs FastAPI/PG/Nginx viendront en spec 2-3).

---

## Entité 3 — Série temporelle (`time series`)

Représente une métrique nommée, étiquetée, capturée à intervalles réguliers.

| Attribut | Description |
|---|---|
| `name` | Nom métrique (ex. `node_cpu_seconds_total`, `container_memory_usage_bytes`) |
| `labels` | Paire(s) clé-valeur (`cpu="0"`, `mode="idle"`, `container_label_com_docker_compose_service="frontend"`, ...) |
| `samples` | Suite `(timestamp, valeur)` ; ingestion = 1 sample / scrape interval |

**Volumétrie estimée** : ~5 000 séries actives sur l'hôte Usenghor → ~3 GB sur 30 jours, sous le budget FR-025 (4500 MB plafond effectif via D-04).

**Identité** : la combinaison `(name, labels)` est unique au sein du TSDB Prometheus.

**Cycle de vie d'un sample** :
1. Collecté par l'exporter (source : `/proc`, `/sys`, socket Docker)
2. Récupéré par Prometheus au scrape suivant
3. Ingéré dans le WAL puis compacté dans un bloc TSDB
4. Visible dans Grafana dans un délai ≤ 30 s (SC-003)
5. Purgé automatiquement après 30 jours OU lorsque la taille du TSDB dépasse 4500 MB (D-04)

---

## Entité 4 — Volume de persistance Docker

| Volume | Service propriétaire | Contenu | Taille cible | Sauvegarde |
|---|---|---|---|---|
| `prometheus_data` | Prometheus | TSDB (blocs + WAL), métadonnées TSDB | ≤ 4500 MB (D-04) | tar.gz hebdo manuel (D-07) |
| `grafana_data` | Grafana | SQLite Grafana (utilisateurs, dashboards UI, datasources, sessions, alerts), plugins, logs internes | < 100 MB | tar.gz manuel à la demande (avant changement majeur) |

Driver : `local` (par défaut Docker). Pas de driver remote (NFS, EFS) dans cette itération.

**Invariant** : ces volumes survivent à `docker compose down` (FR-005, SC-013). Ils ne sont supprimés que par un `docker volume rm` explicite ou un `docker compose down -v` que `deploy.sh monitoring down` n'utilise PAS (D-12).

---

## Entité 5 — Compte administrateur Grafana

| Attribut | Description | Contrainte |
|---|---|---|
| `username` | Identifiant de connexion | Provenant de `GRAFANA_ADMIN_USER` (env) ; **jamais** en clair dans le repo (FR-007, FR-027) |
| `password` | Mot de passe | Provenant de `GRAFANA_ADMIN_PASSWORD` (env) ; validé au démarrage via syntaxe `${VAR:?...}` (D-16) |
| `role` | Rôle Grafana | `Admin` (default) |
| `auth_source` | Source d'authentification | Bootstrap au premier lancement par Grafana lui-même via variables `GF_SECURITY_ADMIN_*` |

**Invariants découlant des décisions de clarification** :
- Un seul compte admin (FR-027 + D-15)
- Sign-up public désactivé (`GF_USERS_ALLOW_SIGN_UP=false`)
- Mode anonyme désactivé (`GF_AUTH_ANONYMOUS_ENABLED=false`)
- Basic Auth désactivée (`GF_AUTH_BASIC_ENABLED=false`)
- Cookies sécurisés en prod (`GF_SECURITY_COOKIE_SECURE=true`)

---

## Entité 6 — Tableau de bord (`dashboard`)

| Attribut | Description |
|---|---|
| `id` | Identifiant interne Grafana |
| `uid` | UID stable (ex. `node-exporter-full`, `docker-cadvisor`) |
| `title` | Titre affiché (anglais — D-11) |
| `source` | Fichier JSON sous `provisioning/dashboards/` |
| `provisioning_mode` | `file`, `disableDeletion: true`, `allowUiUpdates: false` (D-14) |
| `datasource_ref` | Référence à la datasource Prometheus (UID `prometheus`) |

**Catalogue dans cette itération** :

| UID | Titre | Source | Couvre |
|---|---|---|---|
| `node-exporter-full` | Node Exporter Full | Grafana.com ID 1860 | CPU / RAM / disque / réseau / load (FR-002) |
| `docker-cadvisor` | Docker / cAdvisor | Grafana.com ID 14282 (préféré) ou 193 | CPU / RAM / I/O / réseau par conteneur (FR-003) |

---

## Entité 7 — Variables d'environnement (`.env`)

Variables **ajoutées** par cette feature au fichier `.env` (et déclarées dans `.env.example` + `.env.production.example`) :

| Variable | Type | Usage | Versionnée ? | Valeur en clair ? |
|---|---|---|---|---|
| `GRAFANA_ADMIN_USER` | string | Identifiant admin Grafana (D-15) | `.env.example` oui (placeholder), `.env` non | Non |
| `GRAFANA_ADMIN_PASSWORD` | string | Mot de passe admin Grafana | `.env.example` oui (placeholder), `.env` non | Non |
| `MONITORING_DOMAIN` | hostname | FQDN du sous-domaine prod (ex. `monitoring.usenghor-francophonie.org`) | `.env.example` oui, `.env` oui | Oui (FQDN public, pas un secret) |

`.gitignore` actuel (`usenghor_backend/.gitignore`) ignore déjà `.env` → conforme à FR-007.

---

## Invariants transverses

1. **Réseau** : tous les conteneurs monitoring partagent `usenghor_network`. Cassé ⇒ Prometheus ne peut plus scraper.
2. **Versions figées** : aucun tag `:latest` ni majeur seul. Vérifiable par `grep -E ':v?[0-9]' docker-compose.monitoring.yml` (SC-017).
3. **Aucun port public** en production. Vérifiable par `ss -tlnp` sur le VPS (SC-006).
4. **Auth obligatoire**. Vérifiable par requête anonyme sur `/api/dashboards` (HTTP 401 attendu) (SC-018).
5. **Volumes persistants**. Vérifiable par redémarrage Docker et présence d'historique > 1h (SC-013).
6. **Restart unless-stopped**. Vérifiable par `docker inspect --format '{{.HostConfig.RestartPolicy.Name}}' ...` (SC-014).
