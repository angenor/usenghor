# Phase 0 — Recherche et décisions techniques

**Feature** : 020-monitoring-stack
**Date** : 2026-05-15

Objectif de cette phase : transformer chaque **NEEDS CLARIFICATION** restant après `/speckit.clarify` en décision motivée et tracée. Toutes les décisions ci-dessous sont contraignantes pour `/speckit.tasks` et l'implémentation. Si un point est révisé en cours de réalisation, mettre à jour ce fichier et `plan.md` en miroir.

---

## D-01 — Versions d'images Docker à figer

**Décision** : aligner sur les dernières releases stables compatibles entre elles au 2026-05-15 (à reconfirmer juste avant l'implémentation) :

| Service | Image | Version visée |
|---|---|---|
| Prometheus | `prom/prometheus` | `v2.55.1` |
| Grafana | `grafana/grafana` | `11.4.0` |
| node-exporter | `prom/node-exporter` | `v1.8.2` |
| cAdvisor | `gcr.io/cadvisor/cadvisor` | `v0.49.1` |

**Rationale** : versions stables LTS-friendly, datant de moins de 6 mois à la date de spec, sans CVE majeure connue. Toutes compatibles avec Docker Compose v3.8 et le format de provisioning Grafana utilisé.

**Alternatives rejetées** :
- `latest` : rejeté par FR-026 (reproductibilité)
- Tag majeur seul (`:v2`, `:11`) : rejeté par FR-026
- Pinned digests (`@sha256:...`) : pratique plus stricte mais maintenance lourde pour 4 images sur un projet à équipe restreinte ; pourra être adopté lors de la spec 4 si le besoin émerge

**Action** : à l'implémentation, vérifier sur Docker Hub / Grafana Labs / GitHub releases que ces versions sont toujours les plus récentes stables. Si une version supérieure existe et corrige un bug connu, l'adopter et mettre à jour ce fichier + la PR. Conserver la précision « tag explicite » dans tous les cas.

---

## D-02 — Intervalle de scraping Prometheus

**Décision** : `scrape_interval: 15s` globalement, sans `scrape_interval` override par job dans cette itération.

**Rationale** : 15 s est le défaut Prometheus, équilibre la fraîcheur (cf. SC-003 : métrique visible < 30 s) avec le coût (CPU/disque) pour un VPS unique. Sur 30 jours avec ~5 000 séries actives, ~5 GB de stockage prévus → confortablement sous le budget FR-025.

**Alternatives rejetées** :
- `5s` : trop agressif, multiplie la charge sans bénéfice opérationnel pour un site web institutionnel
- `30s` : risque de manquer le seuil SC-003 sur la chaîne complète (scrape → ingestion → render)

---

## D-03 — Limites mémoire par conteneur (mem_limit)

**Décision** : appliquer `mem_limit` Docker à chaque service de la stack pour faire respecter le budget RAM (FR-015 : ≤ 600 MB total) :

| Service | `mem_limit` | `mem_reservation` |
|---|---|---|
| Prometheus | `350m` | `200m` |
| Grafana | `200m` | `100m` |
| node-exporter | `50m` | `20m` |
| cAdvisor | `200m` | `100m` |
| **Total** | **800m** | **420m** |

**Rationale** : on autorise un plafond légèrement supérieur au budget (~600 MB visé) pour absorber les pics ponctuels sans OOM. La somme des réservations (~420 MB) reste sous le budget visé, ce qui correspond au régime nominal mesuré sur ce type de stack. cAdvisor a tendance à monter plus haut sur des hôtes avec beaucoup de conteneurs ; on lui laisse 200 MB.

**Alternatives rejetées** :
- Pas de `mem_limit` (laisser l'OOM killer arbitrer) : rejeté car compromet la stabilité des services applicatifs prioritaires (frontend Nuxt, backend FastAPI, DB) en cas de fuite mémoire dans Prometheus
- `mem_limit` strict au budget annoncé (600 MB total) : trop serré, provoquerait des redémarrages intempestifs lors des compactions Prometheus

**Vérification** : SC-007 (mesurer en local et VPS pendant 24 h ; consigner l'observation dans le PR de la spec 1).

---

## D-04 — Rétention 30 jours et budget disque effectif

**Décision** : Prometheus lancé avec `--storage.tsdb.retention.time=30d` ET `--storage.tsdb.retention.size=4500MB` (marge de sécurité sous le budget de 5 GB FR-025).

**Rationale** : Prometheus purge dès qu'**une** des deux conditions est atteinte. Le double bornage protège contre une explosion inattendue du nombre de séries (par exemple, lors de l'ajout d'exporters dans les specs suivantes) en gardant le disque toujours sous contrôle, même si cela signifie réduire la fenêtre temporelle.

**Alternatives rejetées** :
- Seul `retention.time` : risque de dépasser 5 GB lors de l'ajout futur de cibles (spec 2 FastAPI, spec 3 PG/Nginx)
- Seul `retention.size` : perd la garantie « historique 30 jours minimum garanti » que la spec FR-004 affirme

**Impact sur la spec** : compatible avec FR-004 et FR-025 ; la garantie « 30 jours » devient « jusqu'à 30 jours, plafonnée par le budget disque ». À documenter dans `acces-dashboards.md`.

---

## D-05 — Exposition du port Prometheus en local

**Décision** : en environnement local, Prometheus expose son port `9090` uniquement sur l'interface de loopback : `ports: ["127.0.0.1:9090:9090"]`. En production, **aucun** mapping `ports:` pour Prometheus.

**Rationale** :
- En local : utile pour ouvrir manuellement `http://localhost:9090/targets` (critère d'acceptation 6.5 de la spec) et pour debug PromQL
- En prod : strict respect de FR-010 (aucun composant interne joignable depuis l'extérieur)

**Alternatives rejetées** :
- Pas de mapping `ports:` même en local : casse le scénario d'acceptation explicite « la page `localhost:9090/targets` affiche les targets en UP »
- Mapping `9090:9090` (toutes interfaces) même en local : expose Prometheus sur le LAN du développeur, surface d'attaque inutile

**Mise en œuvre** : utiliser une variable d'environnement `PROMETHEUS_HOST_BIND=127.0.0.1` (avec défaut `127.0.0.1`) ; en prod, soit cette variable vaut `""` et le mapping est omis via syntaxe Compose conditionnelle, soit on utilise deux fichiers `.override`. **Décision** : pour rester simple, on adopte la **convention deux fichiers** : `docker-compose.monitoring.yml` (base, sans exposition) + `docker-compose.monitoring.override.yml` (local uniquement, qui ajoute le `ports: ["127.0.0.1:9090:9090"]`). Docker Compose charge automatiquement le `.override.yml` en local et `deploy.sh monitoring up` ne le copie pas vers le VPS.

---

## D-06 — Healthchecks Docker

**Décision** : ajouter un `healthcheck` Docker à Prometheus et Grafana ; rien pour node-exporter et cAdvisor (services minimalistes, dont l'état est lisible via leur target Prometheus).

| Service | `healthcheck.test` | `interval` | `timeout` | `retries` |
|---|---|---|---|---|
| Prometheus | `["CMD", "wget", "--quiet", "--spider", "http://localhost:9090/-/ready"]` | `30s` | `5s` | `3` |
| Grafana | `["CMD", "wget", "--quiet", "--spider", "http://localhost:3000/api/health"]` | `30s` | `5s` | `3` |

**Rationale** : permet à `./deploy.sh monitoring status` (FR-014, SC-011) de remonter un état « healthy » plus précis que « running ». L'usage de `wget` plutôt que `curl` est aligné avec les images upstream (BusyBox dans Alpine).

**Alternatives rejetées** :
- Healthchecks sur tous les services : pas de valeur ajoutée pour node-exporter / cAdvisor (binaire unique, exit code suffisant)
- Healthchecks externes (script séparé) : surcomplique pour zéro gain

---

## D-07 — Format de sauvegarde des volumes (procédure manuelle documentée)

**Décision** : utiliser la commande standard `docker run --rm -v <volume>:/data -v $(pwd):/backup busybox tar czf /backup/<volume>_$(date).tar.gz -C /data .` pour chacun des deux volumes (`prometheus_data`, `grafana_data`). Procédure documentée dans `sauvegarde-restauration.md`. Pour Prometheus, recommander de **stopper le conteneur** avant snapshot pour éviter une copie WAL incohérente (ou, en alternative, utiliser l'endpoint API `POST /api/v1/admin/tsdb/snapshot` si la fonctionnalité admin est activée — coût : redémarrage avec `--web.enable-admin-api`).

**Recommandation par défaut** : `docker compose stop prometheus && tar … && docker compose start prometheus`. Acceptable pour un projet à audience institutionnelle (downtime < 30 s sur la collecte de métriques, sans impact applicatif).

**Rationale** : approche `tar.gz` universelle, sans dépendance externe, restaurable sur n'importe quelle machine Docker. La fenêtre d'indisponibilité de la collecte (~30 s) est acceptable et documentée. L'alternative `--web.enable-admin-api` est rejetée par défaut car elle élargit la surface d'attaque (endpoint admin exposé sur le port interne) et donne un faux sentiment de sécurité si Grafana ou Nginx fuite plus tard ce port.

**Alternatives rejetées** :
- `pg_dump`-like tool spécifique : n'existe pas pour Prometheus TSDB
- Snapshot Docker volume natif (BTRFS/ZFS) : dépend du filesystem hôte, non portable
- Sauvegarde automatique (cron) : explicitement out-of-scope (cf. spec, Out of Scope)

**Cadence recommandée** : hebdomadaire en production (mention dans `sauvegarde-restauration.md`), à exécuter manuellement par l'administrateur. Stockage des archives sur le poste de l'administrateur ou un bucket externe — choix laissé à l'opérateur.

---

## D-08 — Rate limiting Nginx pour `monitoring.<DOMAINE>`

**Décision** : ajouter dans le bloc `http {}` de `nginx/nginx.conf` :

```
limit_req_zone $binary_remote_addr zone=monitoring:10m rate=30r/m;
limit_req_zone $binary_remote_addr zone=monitoring_login:10m rate=5r/m;
```

Dans le server-block du sous-domaine monitoring :
- Toutes les routes : `limit_req zone=monitoring burst=20 nodelay;`
- `location /login`, `/api/login`, `/api/user/password/reset` (routes Grafana sensibles) : `limit_req zone=monitoring_login burst=5 nodelay;`

**Rationale** : 30 req/min/IP est largement suffisant pour un usage administratif normal (consultation de dashboards à la main). 5 req/min/IP sur les endpoints d'authentification freine sérieusement le brute-force tout en autorisant les fautes de frappe légitimes. `burst` absorbe les rechargements de page (chaque dashboard charge ~10 ressources).

**Alternatives rejetées** :
- Pas de burst : provoque des HTTP 503 lors d'un rechargement normal de dashboard (page Grafana + assets)
- Allowlist IP : rejetée à l'étape clarify (équipe distribuée)
- fail2ban : surcomplique pour un gain marginal vu le ciblage limité

---

## D-09 — Server-block Nginx et terminaison TLS

**Décision** :
- Réutiliser les certificats Let's Encrypt déjà émis par `deploy.sh ssl` (étendre la commande pour accepter `--monitoring-only` ou refaire un `certbot certonly` pour le SAN `monitoring.<DOMAINE>`)
- Server-block dédié écoutant sur 80 (redirect 301 vers HTTPS) et 443 (TLS terminé puis `proxy_pass http://grafana:3000`)
- Headers : `X-Forwarded-Proto`, `X-Forwarded-Host`, `X-Forwarded-For` ; `Host $host` (Grafana lit ces headers pour générer les URLs absolues)
- `proxy_buffering off` sur les routes streaming Grafana (`/api/live/ws`, `/api/datasources/proxy/*`)
- Cookies Grafana : forcer `cookie_secure = true` et `cookie_samesite = strict` via variables d'environnement Grafana (`GF_SECURITY_COOKIE_SECURE=true`, `GF_SECURITY_COOKIE_SAMESITE=strict`)
- Header `Strict-Transport-Security` (HSTS) hérité du bloc TLS global existant

**Rationale** : Grafana sait fonctionner derrière un reverse-proxy à condition de connaître son URL publique. Variables d'env à positionner : `GF_SERVER_ROOT_URL=https://monitoring.<DOMAINE>` et `GF_SERVER_DOMAIN=monitoring.<DOMAINE>`.

**Alternatives rejetées** :
- TLS direct sur Grafana (sans Nginx devant) : casse l'architecture du projet, oblige à exposer un second port HTTPS
- Server-block dans un fichier `conf.d/monitoring.conf` séparé : le projet utilise un `nginx.conf` monolithique, on respecte la convention

---

## D-10 — Sourcing des dashboards JSON

**Décision** : commiter directement dans le dépôt les fichiers JSON (`node-exporter-full.json` ID 1860 et `docker-cadvisor.json` ID 193 ou son équivalent récent maintenu — voir aussi le dashboard ID 14282 « cAdvisor exporter » plus moderne). Téléchargement initial via `curl https://grafana.com/api/dashboards/<ID>/revisions/<REV>/download > <file>.json`, **éditer** la propriété `__inputs` pour fixer la datasource à `Prometheus` (UID = `prometheus`, alignée avec le datasource provisionné).

**Rationale** :
- Reproductibilité : pas de dépendance réseau au démarrage du conteneur Grafana
- Versionnabilité : toute évolution des dashboards passe par un diff Git revu
- Offline-friendly : déploiement possible sur VPS à la connectivité douteuse

**Alternatives rejetées** :
- Variable `GF_INSTALL_PLUGINS` + dashboards téléchargés au boot : ajoute une dépendance réseau au démarrage, fragile
- Provisionning via API Grafana au runtime : plus complexe, perd la simplicité du provisioning par fichier

**Action** : pour cAdvisor, comparer ID 193 (historique) vs ID 14282 (plus récent, maintenu par Grafana Labs). Décider à l'implémentation et documenter le choix dans `acces-dashboards.md`. **Recommandation préliminaire** : ID 14282 (plus à jour, panneaux mieux découpés, compatible cAdvisor v0.40+).

---

## D-11 — Localisation de l'interface Grafana

**Décision** : conserver l'interface Grafana en **anglais** (langue par défaut). Ne pas activer le pack i18n français de Grafana dans cette itération.

**Rationale** : l'interface Grafana est utilisée uniquement par l'équipe technique (administrateurs), à l'aise avec la terminologie anglaise standard (CPU, RAM, disk, load average). La traduction française des dashboards préfaits est partielle et risquerait d'introduire des incohérences avec la documentation officielle (StackOverflow, GitHub issues). En revanche, **toute la documentation opérationnelle interne** (`monitoring-trafic/*.md`) est en français comme exigé par FR-018.

**Alternatives rejetées** :
- `GF_USERS_DEFAULT_LANGUAGE=fr-FR` : feature beta dans Grafana 11.x, traduction partielle, risque de régression UI

---

## D-12 — Intégration au `deploy.sh` existant

**Décision** : ajouter une fonction shell `monitoring()` dans `deploy.sh` (au repo root) qui dispatche selon le second argument (`up`, `down`, `logs`, `status`). Réutiliser exactement le pattern SSH-vers-VPS des autres commandes (`deploy()`, `logs()`, `status()`). Le `case "$1"` à la fin du script ajoute une branche `monitoring) monitoring "$@" ;;`.

Pseudocode de la fonction :

```
monitoring() {
    SUBCOMMAND=${2:-}
    case "$SUBCOMMAND" in
        up)     ssh ... "cd ${REMOTE_DIR} && docker compose -f usenghor_backend/docker-compose.monitoring.yml --env-file .env up -d" ;;
        down)   ssh ... "cd ${REMOTE_DIR} && docker compose -f usenghor_backend/docker-compose.monitoring.yml down" ;;
        logs)   ssh ... "cd ${REMOTE_DIR} && docker compose -f usenghor_backend/docker-compose.monitoring.yml logs -f" ;;
        status) ssh ... "cd ${REMOTE_DIR} && docker compose -f usenghor_backend/docker-compose.monitoring.yml ps" ;;
        *)      echo "Usage: $0 monitoring {up|down|logs|status}" ; exit 1 ;;
    esac
}
```

**Rationale** : cohérence stylistique avec les autres commandes ; les volumes nommés survivent à `down` sans flag `-v` (FR-005). Les logs sont en mode `-f` (follow) comme le reste du script.

**Alternatives rejetées** :
- Script séparé `deploy-monitoring.sh` : casse la promesse de point d'entrée unique
- Profil Docker Compose dans `docker-compose.prod.yml` : couple inutilement les deux cycles de vie (un `deploy` applicatif ne doit pas relancer Prometheus)

---

## D-13 — Réseau Docker partagé

**Décision** : déclarer dans `docker-compose.monitoring.yml` :

```yaml
networks:
  usenghor_network:
    external: true
```

Tous les services de la stack monitoring s'attachent à `usenghor_network`. cAdvisor doit aussi avoir accès au socket Docker (`/var/run/docker.sock:/var/run/docker.sock:ro`) et à `/sys`, `/var/lib/docker/` (read-only) pour collecter les métriques par conteneur.

**Rationale** : permet le scraping ultérieur des services applicatifs par leur nom DNS Docker (`backend:8000`, `frontend:3000`, etc.) sans reconfiguration (FR-017). L'isolation reste assurée par l'absence de mapping `ports:` côté Prometheus en prod.

**Risque résiduel** : si `usenghor_network` n'existe pas (compose principal jamais lancé), `docker compose up` échoue. La documentation `installation-locale.md` rappellera l'ordre : lancer le compose principal d'abord, puis le compose monitoring. `deploy.sh monitoring up` peut afficher un message d'aide explicite en cas d'erreur.

---

## D-14 — Provisioning Grafana : datasource et dashboards

**Décision** :

`/etc/grafana/provisioning/datasources/prometheus.yml` :
```yaml
apiVersion: 1
datasources:
  - name: Prometheus
    uid: prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: false
```

`/etc/grafana/provisioning/dashboards/dashboards.yml` :
```yaml
apiVersion: 1
providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: true
    updateIntervalSeconds: 30
    allowUiUpdates: false
    options:
      path: /etc/grafana/provisioning/dashboards
```

`disableDeletion: true` et `allowUiUpdates: false` empêchent qu'un opérateur supprime/modifie accidentellement un dashboard préfait depuis l'UI Grafana ; les modifications passent par Git.

**Rationale** : provisioning purement par fichier → reproductibilité ; UID fixe `prometheus` → les dashboards référencent toujours la même datasource ; `editable: false` sur la datasource → protection supplémentaire.

---

## D-15 — Variables d'environnement Grafana hardening

**Décision** : positionner dans `docker-compose.monitoring.yml` les variables Grafana suivantes pour appliquer FR-006, FR-009, FR-027 :

```yaml
environment:
  GF_SECURITY_ADMIN_USER: ${GRAFANA_ADMIN_USER}
  GF_SECURITY_ADMIN_PASSWORD: ${GRAFANA_ADMIN_PASSWORD}
  GF_USERS_ALLOW_SIGN_UP: "false"
  GF_AUTH_ANONYMOUS_ENABLED: "false"
  GF_AUTH_DISABLE_LOGIN_FORM: "false"
  GF_AUTH_BASIC_ENABLED: "false"        # Désactive Basic Auth, force l'usage du login web
  GF_SECURITY_COOKIE_SECURE: "true"      # Cookies uniquement sur HTTPS
  GF_SECURITY_COOKIE_SAMESITE: "strict"
  GF_SERVER_ROOT_URL: "https://${MONITORING_DOMAIN}"
  GF_SERVER_DOMAIN: "${MONITORING_DOMAIN}"
  GF_ANALYTICS_REPORTING_ENABLED: "false"
  GF_ANALYTICS_CHECK_FOR_UPDATES: "false"
```

**Rationale** : durcit la posture par défaut (FR-027) ; désactive le télémétrie d'usage (`GF_ANALYTICS_*`) pour ne pas exfiltrer les noms de dashboards et d'hôtes vers Grafana Labs.

**Note d'environnement local** : en local, `GF_SECURITY_COOKIE_SECURE: "true"` empêche le login via `http://localhost:3001`. **Décision** : en local uniquement, `docker-compose.monitoring.override.yml` surcharge à `"false"`. En prod : reste à `"true"`.

---

## D-16 — Validation au démarrage que les secrets sont définis

**Décision** : faire en sorte que `docker compose up` échoue si `GRAFANA_ADMIN_USER` ou `GRAFANA_ADMIN_PASSWORD` est absent ou vide (FR-008). Approche : référencer ces variables avec la syntaxe Compose `:?error` :

```yaml
environment:
  GF_SECURITY_ADMIN_USER: ${GRAFANA_ADMIN_USER:?GRAFANA_ADMIN_USER doit être defini dans .env}
  GF_SECURITY_ADMIN_PASSWORD: ${GRAFANA_ADMIN_PASSWORD:?GRAFANA_ADMIN_PASSWORD doit être defini dans .env}
```

**Rationale** : Compose refuse de générer la commande Docker si la variable n'est pas définie, avec un message d'erreur explicite. Pas besoin d'un script wrapper.

**Alternative rejetée** : script bash de pré-vérification → ajoute un point de défaillance et est contournable.

---

## D-17 — Documentation opérationnelle (chemin et fichiers)

**Décision** : créer 4 fichiers dans `usenghor_nuxt/bank/documentations/monitoring-trafic/` à côté des fichiers `spec-N-*.md` existants :

1. `installation-locale.md` — étapes pour `pnpm install` n'est pas requis ; seul Docker l'est. Inclure : `cp .env.example .env`, choisir un `GRAFANA_ADMIN_PASSWORD`, lancer le compose principal puis monitoring, ouvrir `http://localhost:3001`.
2. `installation-vps.md` — étapes côté admin : configurer le DNS `monitoring.<DOMAINE>`, créer le certificat Let's Encrypt étendu, déployer via `./deploy.sh monitoring up`, valider l'accès HTTPS.
3. `acces-dashboards.md` — guide utilisateur : login, navigation entre les 2 dashboards, lecture des panneaux clés, signification des couleurs.
4. `sauvegarde-restauration.md` — procédure tar.gz pour chaque volume, restauration, vérification.

**Rationale** : 4 fichiers ciblés évitent un seul long README ; chacun couvre un rôle distinct (dev local, ops VPS, utilisateur de l'interface, ops backup). Aligné FR-018.

---

## Résumé des décisions

| ID | Sujet | Décision résumée |
|---|---|---|
| D-01 | Versions images | Prometheus 2.55.1 / Grafana 11.4.0 / node-exporter 1.8.2 / cAdvisor 0.49.1 |
| D-02 | Scrape interval | 15 s global |
| D-03 | mem_limit | 350m / 200m / 50m / 200m |
| D-04 | Rétention | 30 d ET 4500 MB |
| D-05 | Port 9090 local | Loopback uniquement, prod sans mapping |
| D-06 | Healthchecks | Prometheus + Grafana uniquement |
| D-07 | Backup | tar.gz manuel sur volumes Docker, doc hebdomadaire |
| D-08 | Rate limit Nginx | zones `monitoring` (30 r/m) + `monitoring_login` (5 r/m) |
| D-09 | Server-block | Reverse-proxy, GF_SERVER_ROOT_URL, HSTS hérité |
| D-10 | Dashboards | JSON commités, ID 1860 + 14282 (cAdvisor moderne) |
| D-11 | Locale Grafana | Anglais (UI), français (docs internes) |
| D-12 | deploy.sh | Fonction `monitoring()` ajoutée, pattern SSH existant |
| D-13 | Réseau | `usenghor_network` external: true |
| D-14 | Provisioning | datasource UID `prometheus`, dashboards read-only |
| D-15 | Grafana env | Sign-up off, anonymous off, cookies secure |
| D-16 | Validation env | Compose `${VAR:?message}` |
| D-17 | Docs | 4 fichiers dédiés dans monitoring-trafic/ |

**Aucun NEEDS CLARIFICATION résiduel.** Prêt pour Phase 1.
