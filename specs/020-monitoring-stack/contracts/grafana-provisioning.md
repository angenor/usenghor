# Contrat — Provisioning Grafana

## Structure de fichiers

```
usenghor_backend/monitoring/grafana/provisioning/
├── datasources/
│   └── prometheus.yml
└── dashboards/
    ├── dashboards.yml
    ├── node-exporter-full.json
    └── docker-cadvisor.json
```

Ces fichiers sont montés en lecture seule dans Grafana via :
```yaml
volumes:
  - ./monitoring/grafana/provisioning:/etc/grafana/provisioning:ro
```

---

## `datasources/prometheus.yml`

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
    jsonData:
      httpMethod: POST
      manageAlerts: false
      prometheusType: Prometheus
      prometheusVersion: 2.55.x
      timeInterval: 15s
```

### Champs obligatoires

| Champ | Valeur | Origine |
|---|---|---|
| `apiVersion` | `1` | Convention Grafana |
| `name` | `Prometheus` | — |
| `uid` | `prometheus` | D-14 (référencé par les dashboards JSON) |
| `type` | `prometheus` | — |
| `access` | `proxy` | Évite d'exposer l'URL Prometheus au navigateur |
| `url` | `http://prometheus:9090` | DNS Docker interne (D-13) |
| `isDefault` | `true` | Une seule datasource dans cette itération |
| `editable` | `false` | Empêche la modification via UI (D-14) |

---

## `dashboards/dashboards.yml`

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

### Champs obligatoires

| Champ | Valeur | Origine |
|---|---|---|
| `disableDeletion` | `true` | D-14 (protection contre suppression accidentelle) |
| `allowUiUpdates` | `false` | D-14 (la source de vérité reste Git) |
| `options.path` | `/etc/grafana/provisioning/dashboards` | Convention Grafana |

---

## `dashboards/node-exporter-full.json`

- **Source initiale** : `curl https://grafana.com/api/dashboards/1860/revisions/<latest>/download > node-exporter-full.json`
- **Adaptation requise** : remplacer la propriété `__inputs` (référence dynamique à une datasource saisie à l'import) par une référence statique vers la datasource UID `prometheus` :
  ```jsonc
  // Avant
  "__inputs": [
    { "name": "DS_PROMETHEUS", "label": "Prometheus", "type": "datasource", "pluginId": "prometheus" }
  ],
  // Après : supprimer __inputs et __requires, remplacer toutes les références "${DS_PROMETHEUS}" par "prometheus"
  ```
- **UID figé** : forcer `"uid": "node-exporter-full"` au niveau racine du JSON
- **Refresh** : `"refresh": "30s"`

### Métriques minimales attendues sur ce dashboard (mappées à FR-002)

| Panneau | Métrique source |
|---|---|
| CPU usage | `node_cpu_seconds_total` |
| Memory usage | `node_memory_*` |
| Disk space | `node_filesystem_*` |
| Network traffic | `node_network_*` |
| Load average | `node_load1`, `node_load5`, `node_load15` |

---

## `dashboards/docker-cadvisor.json`

- **Source initiale** : `curl https://grafana.com/api/dashboards/14282/revisions/<latest>/download > docker-cadvisor.json` (D-10 : préférer ID 14282 plus moderne, fallback ID 193 si 14282 a un défaut bloquant)
- **Adaptations identiques** : `__inputs` remplacé, UID figé `"uid": "docker-cadvisor"`
- **Refresh** : `"refresh": "30s"`

### Métriques minimales attendues (mappées à FR-003)

| Panneau | Métrique source |
|---|---|
| CPU par conteneur | `container_cpu_usage_seconds_total` |
| RAM par conteneur | `container_memory_usage_bytes` |
| I/O par conteneur | `container_fs_reads_bytes_total`, `container_fs_writes_bytes_total` |
| Trafic réseau par conteneur | `container_network_receive_bytes_total`, `container_network_transmit_bytes_total` |

---

## Validation

| Test | Procédure | Résultat attendu |
|---|---|---|
| T-GRAF-1 | Login Grafana, vérifier la datasource Prometheus | « Save & test » répond `Data source is working` |
| T-GRAF-2 | Naviguer sur les dashboards | Les 2 dashboards apparaissent dans la liste, avec données réelles |
| T-GRAF-3 | Essayer d'éditer la datasource via UI | Bouton « Save » désactivé (`editable: false`) |
| T-GRAF-4 | Essayer de supprimer un dashboard via UI | Bouton désactivé (`disableDeletion: true`) |
| T-GRAF-5 | Vérifier l'UID `prometheus` dans la JSON datasource | `curl /api/datasources/uid/prometheus` (avec auth) retourne 200 |
