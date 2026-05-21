# Contrat — `usenghor_backend/monitoring/prometheus/prometheus.yml`

## Format attendu (squelette)

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    cluster: usenghor
    env: ${PROMETHEUS_ENV:-local}   # via container env

scrape_configs:
  - job_name: node-exporter
    static_configs:
      - targets: ['node-exporter:9100']
        labels:
          service: vps-host

  - job_name: cadvisor
    static_configs:
      - targets: ['cadvisor:8080']
        labels:
          service: docker-containers
```

## Champs obligatoires

| Champ | Valeur exigée | Origine |
|---|---|---|
| `global.scrape_interval` | `15s` | D-02 |
| `global.evaluation_interval` | `15s` | Aligné sur le scrape ; pas de règle d'alerte dans cette itération |
| `scrape_configs[*].job_name` | `node-exporter`, `cadvisor` (exactement ces deux jobs, dans cet ordre) | FR-002, FR-003 |
| `scrape_configs[*].static_configs[*].targets` | `node-exporter:9100` / `cadvisor:8080` | D-13 (résolution DNS Docker via `usenghor_network`) |
| `scrape_configs[*].static_configs[*].labels` | `service` rajouté pour faciliter le filtrage dans Grafana | — |

## Champs interdits dans cette itération

- Aucun `remote_write` (pas d'envoi vers un backend distant)
- Aucun `alerting` ni `rule_files` (out-of-scope — spec 4)
- Aucun job autre que `node-exporter` et `cadvisor` (out-of-scope — specs 2 et 3)

## Arguments de lancement Prometheus (à passer dans `docker-compose.monitoring.yml`)

```
--config.file=/etc/prometheus/prometheus.yml
--storage.tsdb.path=/prometheus
--storage.tsdb.retention.time=30d
--storage.tsdb.retention.size=4500MB
--web.console.libraries=/usr/share/prometheus/console_libraries
--web.console.templates=/usr/share/prometheus/consoles
--web.enable-lifecycle
```

## Validation

| Test | Procédure | Résultat attendu |
|---|---|---|
| T-PROM-1 | `curl http://127.0.0.1:9090/-/ready` (local) | HTTP 200 |
| T-PROM-2 | `curl http://127.0.0.1:9090/api/v1/targets` (local) | Les 2 targets affichées en `health: up` |
| T-PROM-3 | `promtool check config /etc/prometheus/prometheus.yml` dans le conteneur | exit 0 |
| T-PROM-4 | `curl 'http://127.0.0.1:9090/api/v1/query?query=up'` | Résultat avec 2 séries `up{job="node-exporter"}=1` et `up{job="cadvisor"}=1` |
| T-PROM-5 | Au bout de 31 jours simulés, vérifier la purge | Plus de samples > 30 j |

## Sécurité

- Pas de `--web.enable-admin-api` (D-07)
- Aucun `--web.listen-address` modifié (défaut `:9090`)
- Authentification de Prometheus : non activée (FR-010 impose isolation réseau ; l'accès web n'est jamais public)
