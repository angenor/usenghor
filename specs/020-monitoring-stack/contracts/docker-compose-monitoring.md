# Contrat — `usenghor_backend/docker-compose.monitoring.yml`

## Squelette attendu

```yaml
version: "3.8"

services:
  prometheus:
    image: prom/prometheus:v2.55.1
    container_name: usenghor_monitoring_prometheus
    restart: unless-stopped
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=30d'
      - '--storage.tsdb.retention.size=4500MB'
      - '--web.console.libraries=/usr/share/prometheus/console_libraries'
      - '--web.console.templates=/usr/share/prometheus/consoles'
      - '--web.enable-lifecycle'
    volumes:
      - ./monitoring/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus_data:/prometheus
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--spider", "http://localhost:9090/-/ready"]
      interval: 30s
      timeout: 5s
      retries: 3
    mem_limit: 350m
    mem_reservation: 200m
    networks:
      - usenghor_network

  grafana:
    image: grafana/grafana:11.4.0
    container_name: usenghor_monitoring_grafana
    restart: unless-stopped
    depends_on:
      prometheus:
        condition: service_healthy
    environment:
      GF_SECURITY_ADMIN_USER: ${GRAFANA_ADMIN_USER:?GRAFANA_ADMIN_USER doit être defini dans .env}
      GF_SECURITY_ADMIN_PASSWORD: ${GRAFANA_ADMIN_PASSWORD:?GRAFANA_ADMIN_PASSWORD doit être defini dans .env}
      GF_USERS_ALLOW_SIGN_UP: "false"
      GF_AUTH_ANONYMOUS_ENABLED: "false"
      GF_AUTH_BASIC_ENABLED: "false"
      GF_AUTH_DISABLE_LOGIN_FORM: "false"
      GF_SECURITY_COOKIE_SECURE: "true"
      GF_SECURITY_COOKIE_SAMESITE: "strict"
      GF_SERVER_ROOT_URL: "https://${MONITORING_DOMAIN:?MONITORING_DOMAIN doit être defini dans .env}"
      GF_SERVER_DOMAIN: "${MONITORING_DOMAIN}"
      GF_ANALYTICS_REPORTING_ENABLED: "false"
      GF_ANALYTICS_CHECK_FOR_UPDATES: "false"
      GF_LOG_LEVEL: "info"
    volumes:
      - grafana_data:/var/lib/grafana
      - ./monitoring/grafana/provisioning:/etc/grafana/provisioning:ro
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--spider", "http://localhost:3000/api/health"]
      interval: 30s
      timeout: 5s
      retries: 3
    mem_limit: 200m
    mem_reservation: 100m
    networks:
      - usenghor_network

  node-exporter:
    image: prom/node-exporter:v1.8.2
    container_name: usenghor_monitoring_node_exporter
    restart: unless-stopped
    command:
      - '--path.procfs=/host/proc'
      - '--path.sysfs=/host/sys'
      - '--path.rootfs=/rootfs'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    pid: host
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro,rslave
    mem_limit: 50m
    mem_reservation: 20m
    networks:
      - usenghor_network

  cadvisor:
    image: gcr.io/cadvisor/cadvisor:v0.49.1
    container_name: usenghor_monitoring_cadvisor
    restart: unless-stopped
    privileged: true        # Requis pour lire les cgroups
    devices:
      - /dev/kmsg
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
      - /dev/disk/:/dev/disk:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
    mem_limit: 200m
    mem_reservation: 100m
    networks:
      - usenghor_network

volumes:
  prometheus_data:
    name: usenghor_monitoring_prometheus_data
  grafana_data:
    name: usenghor_monitoring_grafana_data

networks:
  usenghor_network:
    external: true
    name: usenghor_network
```

## Fichier d'override local — `usenghor_backend/docker-compose.monitoring.override.yml`

Chargé automatiquement par Docker Compose en local. **Pas synchronisé** sur le VPS par `deploy.sh`.

```yaml
version: "3.8"

services:
  prometheus:
    ports:
      - "127.0.0.1:9090:9090"     # Debug local uniquement (D-05)

  grafana:
    ports:
      - "127.0.0.1:3001:3000"     # http://localhost:3001 (FR-011)
    environment:
      GF_SECURITY_COOKIE_SECURE: "false"   # Dev en HTTP (D-15)
      GF_SERVER_ROOT_URL: "http://localhost:3001"
      GF_SERVER_DOMAIN: "localhost"
```

## Invariants à respecter

| Invariant | Vérification | Spec |
|---|---|---|
| Images figées en semver | `grep -E 'image: .+:v?[0-9]' docker-compose.monitoring.yml` doit matcher 4 lignes ; aucun `:latest` | FR-026, SC-017 |
| `restart: unless-stopped` partout | `grep -c 'unless-stopped' docker-compose.monitoring.yml` ≥ 4 | FR-023, SC-014 |
| Pas de `ports:` sur prod | Aucune section `ports:` dans le fichier base | FR-010, SC-006 |
| Volumes nommés persistants | Section `volumes:` déclare `prometheus_data` et `grafana_data` | FR-005 |
| Réseau externe | `networks.usenghor_network.external: true` | D-13, FR-017 |
| `mem_limit` partout | 4 services ont chacun un `mem_limit` | FR-015, D-03 |
| Healthchecks Prom + Grafana | 2 healthchecks définis | D-06 |
| Variables `:?` sur secrets | `GRAFANA_ADMIN_USER`, `GRAFANA_ADMIN_PASSWORD`, `MONITORING_DOMAIN` ont la syntaxe d'erreur | FR-008, D-16 |

## Tests d'acceptation

| Test | Procédure | Résultat attendu |
|---|---|---|
| T-CMP-1 | `docker compose -f docker-compose.monitoring.yml config` | Sortie sans erreur, image versions affichées |
| T-CMP-2 | Sans `.env` : `docker compose -f docker-compose.monitoring.yml up` | Échec avec message `GRAFANA_ADMIN_USER doit être defini dans .env` |
| T-CMP-3 | Lancer la stack, `docker compose -f docker-compose.monitoring.yml ps` | 4 services UP, 2 healthy |
| T-CMP-4 | `docker inspect usenghor_monitoring_prometheus --format '{{.HostConfig.Memory}}'` | `367001600` (350 MiB) |
| T-CMP-5 | `docker inspect usenghor_monitoring_prometheus --format '{{.HostConfig.RestartPolicy.Name}}'` | `unless-stopped` |
| T-CMP-6 | Tuer `prometheus` : `docker kill usenghor_monitoring_prometheus` | Conteneur redémarre automatiquement |
| T-CMP-7 | Redémarrer Docker daemon (test local) | Tous les conteneurs reviennent à `running` |
