# Contrat — Sous-commande CLI `./deploy.sh monitoring`

## Signature

```
./deploy.sh monitoring <subcommand>
```

| `<subcommand>` | Description | Effet attendu | Code de sortie nominal |
|---|---|---|---|
| `up` | Démarre les 4 conteneurs de monitoring | Crée et démarre `usenghor_monitoring_prometheus`, `usenghor_monitoring_grafana`, `usenghor_monitoring_node_exporter`, `usenghor_monitoring_cadvisor` ; volumes nommés créés si absents | `0` |
| `down` | Arrête les 4 conteneurs | Arrêt propre, volumes préservés (pas de `-v`) | `0` |
| `logs` | Suit les logs agrégés des 4 conteneurs | `docker compose ... logs -f` (sortie continue, Ctrl+C pour quitter) | `130` après Ctrl+C |
| `status` | Affiche l'état des 4 conteneurs | Sortie `docker compose ... ps` indiquant pour chaque service : `STATUS`, `HEALTH`, `PORTS` | `0` |
| _(absent ou inconnu)_ | Affiche l'aide | Imprime sur stderr `Usage: ./deploy.sh monitoring {up|down|logs|status}` | `1` |

## Pré-conditions

- Le compose principal (`docker-compose.yml` ou `docker-compose.prod.yml`) a été lancé au moins une fois (sinon `usenghor_network` n'existe pas → exit 1 avec message d'erreur explicite).
- `.env` contient `GRAFANA_ADMIN_USER` et `GRAFANA_ADMIN_PASSWORD` non vides (sinon `up` échoue via Compose `${VAR:?...}` — D-16).
- Pour les opérations VPS : connexion SSH au serveur fonctionnelle (la commande SSH dans `deploy.sh` doit aboutir).

## Comportement attendu (verbose)

### `up`
- Local : exécute `cd usenghor_backend && docker compose -f docker-compose.monitoring.yml --env-file ../.env up -d`
- Prod : exécute le même via SSH dans `/opt/usenghor/` après synchronisation des fichiers de configuration (cf. ci-dessous)
- Synchronisation prod (à la première mise en place ou quand des fichiers monitoring ont changé) : `scp` de `usenghor_backend/docker-compose.monitoring.yml` et de l'arborescence `usenghor_backend/monitoring/` vers le VPS
- Sortie stdout : la sortie native de `docker compose up` (création des conteneurs, healthchecks)
- Sortie stderr : silencieuse en cas de succès

### `down`
- Arrête `docker compose -f docker-compose.monitoring.yml down` (sans `-v`)
- Les volumes `prometheus_data` et `grafana_data` restent intacts (cf. FR-005)

### `logs`
- Suit en continu via `docker compose ... logs -f` jusqu'à interruption utilisateur

### `status`
- Affiche un tableau type :
  ```
  NAME                                IMAGE                          STATUS                    PORTS
  usenghor_monitoring_prometheus      prom/prometheus:v2.55.1        Up 12 minutes (healthy)
  usenghor_monitoring_grafana         grafana/grafana:11.4.0         Up 12 minutes (healthy)
  usenghor_monitoring_node_exporter   prom/node-exporter:v1.8.2      Up 12 minutes
  usenghor_monitoring_cadvisor        gcr.io/cadvisor/cadvisor:v0.49.1 Up 12 minutes
  ```

## Post-conditions de `up`

| Condition | Vérification | Lié à |
|---|---|---|
| Les 4 conteneurs sont à l'état `running` | `docker compose ps` | SC-001 |
| Prometheus + Grafana sont `healthy` (après ~90 s max) | Colonne `STATUS` | D-06 |
| Volumes `prometheus_data` et `grafana_data` existent | `docker volume ls` | FR-005 |
| En local : `curl http://127.0.0.1:9090/-/ready` répond 200 | Test manuel | Critère acceptation |
| En local : `curl http://127.0.0.1:3001/api/health` répond 200 | Test manuel | Critère acceptation |
| En prod : aucun port `9090`/`3000` exposé publiquement | `ss -tlnp` ou test externe | FR-010, SC-006 |

## Gestion d'erreurs

| Cas d'erreur | Détection | Message attendu | Exit |
|---|---|---|---|
| Variables Grafana absentes | Compose error `${VAR:?...}` | `error: GRAFANA_ADMIN_USER doit être defini dans .env` | non-zéro |
| Réseau `usenghor_network` inexistant | Compose error | `network usenghor_network declared as external, but could not be found` | non-zéro |
| Port hôte déjà occupé (local) | Compose error | `bind: address already in use` | non-zéro |
| SSH indisponible (prod) | Le script SSH retourne != 0 | Message Bash standard | propagé |

Le script doit, en cas d'erreur, **ne pas masquer** la sortie de Docker Compose (pas de redirection vers `/dev/null`).

## Tests d'acceptation

| Test | Procédure | Résultat attendu | Lien spec |
|---|---|---|---|
| T-CLI-1 | `./deploy.sh monitoring up` à froid | 4 conteneurs démarrés, sortie 0 | SC-001, AC US5-1 |
| T-CLI-2 | `./deploy.sh monitoring status` après `up` | Tableau affichant l'état de 4 services | SC-011, AC US5-2 |
| T-CLI-3 | `./deploy.sh monitoring logs` après `up` | Stream continu de logs des 4 services | AC US5-3 |
| T-CLI-4 | `./deploy.sh monitoring down` après `up` | 4 conteneurs arrêtés, volumes préservés | AC US5-4 |
| T-CLI-5 | Cycle `up` → kill container manuel → vérifier que le conteneur redémarre | `restart_count` incrémenté, conteneur à nouveau running | SC-014, FR-023 |
| T-CLI-6 | `up` sans `GRAFANA_ADMIN_PASSWORD` dans `.env` | Échec immédiat, message explicite | FR-008, D-16 |
| T-CLI-7 | `./deploy.sh monitoring foo` (sous-commande inconnue) | Message d'usage sur stderr, exit 1 | — |
