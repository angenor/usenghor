# Quickstart — Socle de monitoring technique

**Feature** : 020-monitoring-stack
**Audience** : développeur découvrant la stack pour la première fois (cf. FR-019, SC-009).
**Objectif** : démarrer la stack en local et atteindre les tableaux de bord en **moins de 15 minutes**.

> Ce fichier sert de référence pendant l'implémentation et de squelette pour la documentation utilisateur finale (`usenghor_nuxt/bank/documentations/monitoring-trafic/installation-locale.md` et `installation-vps.md`). Si vous êtes utilisateur final, lisez plutôt ces fichiers livrés par la spec.

---

## Pré-requis

- Docker ≥ 24 et Docker Compose plugin ≥ 2.20 installés
- Le compose principal du projet (`usenghor_backend/docker-compose.yml`) a déjà été lancé au moins une fois (cela crée le réseau `usenghor_network` utilisé par la stack monitoring)
- Ports 3001 et 9090 disponibles sur `127.0.0.1` (en local)
- Pour la prod : accès SSH au VPS, DNS `monitoring.<DOMAINE>` configuré, certificat Let's Encrypt incluant ce sous-domaine

---

## A. Mise en route en local (10 minutes)

### A1. Vérifier le réseau Docker partagé
```bash
docker network ls | grep usenghor_network
# Si rien, lancer le compose principal d'abord :
cd usenghor_backend && docker compose up -d
```

### A2. Configurer les variables d'environnement Grafana
Ajouter à `usenghor_backend/.env` :
```dotenv
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=<choisir-un-mot-de-passe-fort>
MONITORING_DOMAIN=localhost
```
Le fichier `usenghor_backend/.env.example` contient ces variables avec valeurs vides à remplir.

### A3. Démarrer la stack monitoring
```bash
cd usenghor_backend
docker compose -f docker-compose.monitoring.yml up -d
```
Docker Compose charge automatiquement `docker-compose.monitoring.override.yml` qui ajoute les ports loopback (D-05).

### A4. Vérifier que les 4 conteneurs sont healthy
```bash
docker compose -f docker-compose.monitoring.yml ps
```
Attendu (après ~90 s pour les healthchecks) :
```
NAME                                IMAGE                              STATUS
usenghor_monitoring_prometheus      prom/prometheus:v2.55.1            Up (healthy)
usenghor_monitoring_grafana         grafana/grafana:11.4.0             Up (healthy)
usenghor_monitoring_node_exporter   prom/node-exporter:v1.8.2          Up
usenghor_monitoring_cadvisor        gcr.io/cadvisor/cadvisor:v0.49.1   Up
```

### A5. Vérifier les targets Prometheus
Ouvrir : <http://localhost:9090/targets>
Les 2 cibles `node-exporter` et `cadvisor` doivent être à l'état **UP**.

### A6. Se connecter à Grafana
Ouvrir : <http://localhost:3001>
Identifiants : ceux de `GRAFANA_ADMIN_USER` et `GRAFANA_ADMIN_PASSWORD` ci-dessus.

### A7. Vérifier les dashboards préfaits
Dashboards → Browse → ouvrir successivement :
- **Node Exporter Full** (UID `node-exporter-full`) : doit afficher CPU/RAM/disque/réseau de la machine hôte
- **Docker / cAdvisor** (UID `docker-cadvisor`) : doit lister les conteneurs en cours d'exécution avec leurs métriques

Si l'un des dashboards est vide :
- Attendre 30 s (le scrape interval) puis recharger
- Vérifier <http://localhost:9090/targets> ; si une cible est DOWN, lire les logs : `docker logs usenghor_monitoring_prometheus`

---

## B. Mise en route en production (VPS) — 5 minutes après les pré-requis

### B1. Configurer le DNS
Créer un enregistrement DNS A : `monitoring.<DOMAINE>` → IP du VPS. Attendre la propagation (généralement 5–60 min).

### B2. Étendre le certificat Let's Encrypt
```bash
./deploy.sh connect
# Sur le VPS :
sudo certbot certonly --webroot -w /var/www/html \
  -d usenghor-francophonie.org \
  -d www.usenghor-francophonie.org \
  -d monitoring.usenghor-francophonie.org \
  --expand
```
Le hook post-cert de `deploy.sh ssl` (cron) renouvelle automatiquement.

### B3. Configurer les variables d'environnement en prod
Sur le VPS, ajouter à `/opt/usenghor/.env` :
```dotenv
GRAFANA_ADMIN_USER=<admin>
GRAFANA_ADMIN_PASSWORD=<mot-de-passe-fort-different-du-local>
MONITORING_DOMAIN=monitoring.usenghor-francophonie.org
```

### B4. Mettre à jour la configuration Nginx
Tirer la nouvelle conf depuis le dépôt :
```bash
./deploy.sh deploy   # tire le nouveau nginx.conf
# Si nécessaire, recharger Nginx manuellement :
./deploy.sh restart nginx
```

### B5. Lancer la stack monitoring
Depuis votre poste de développeur (le script SSH dans le VPS) :
```bash
./deploy.sh monitoring up
```

### B6. Vérifier l'accès HTTPS
Ouvrir : <https://monitoring.usenghor-francophonie.org>
- Certificat valide attendu (badge cadenas)
- Page de connexion Grafana
- Aucune option d'inscription publique
- Login avec les identifiants de l'étape B3

### B7. Vérifier l'isolation
Depuis votre poste (extérieur au VPS) :
```bash
curl -m 5 http://<IP-VPS>:9090   # doit timeout ou être refusé
curl -m 5 http://<IP-VPS>:3000   # doit timeout ou être refusé
```

---

## C. Sauvegarder les volumes

### C1. Snapshot du volume Prometheus (arrêt momentané ~30 s)
```bash
docker compose -f docker-compose.monitoring.yml stop prometheus
docker run --rm \
  -v usenghor_monitoring_prometheus_data:/data \
  -v $(pwd):/backup \
  busybox tar czf /backup/prometheus_$(date +%Y%m%d).tar.gz -C /data .
docker compose -f docker-compose.monitoring.yml start prometheus
```

### C2. Snapshot du volume Grafana (sans arrêt)
Grafana tolère bien la copie à chaud (SQLite WAL).
```bash
docker run --rm \
  -v usenghor_monitoring_grafana_data:/data \
  -v $(pwd):/backup \
  busybox tar czf /backup/grafana_$(date +%Y%m%d).tar.gz -C /data .
```

### C3. Restauration
Inverser l'opération :
```bash
docker compose -f docker-compose.monitoring.yml stop prometheus grafana
docker run --rm \
  -v usenghor_monitoring_prometheus_data:/data \
  -v $(pwd):/backup \
  busybox sh -c "cd /data && rm -rf * && tar xzf /backup/prometheus_20260515.tar.gz"
docker run --rm \
  -v usenghor_monitoring_grafana_data:/data \
  -v $(pwd):/backup \
  busybox sh -c "cd /data && rm -rf * && tar xzf /backup/grafana_20260515.tar.gz"
docker compose -f docker-compose.monitoring.yml start prometheus grafana
```

---

## D. Opérations courantes via `deploy.sh`

```bash
./deploy.sh monitoring up       # Démarrer la stack
./deploy.sh monitoring status   # État des 4 conteneurs
./deploy.sh monitoring logs     # Suivre les logs (Ctrl+C pour quitter)
./deploy.sh monitoring down     # Arrêter (volumes conservés)
```

---

## E. Dépannage rapide

| Symptôme | Cause probable | Action |
|---|---|---|
| `network usenghor_network not found` | Compose principal jamais lancé | `cd usenghor_backend && docker compose up -d` puis relancer monitoring |
| Grafana retourne `502 Bad Gateway` derrière Nginx | Grafana n'est pas dans le même réseau Docker que Nginx | Vérifier `docker inspect usenghor_nginx | grep usenghor_network` |
| Le dashboard est vide | Pas encore de samples (< 30 s après démarrage) ou cible DOWN | Attendre, puis vérifier `/targets` |
| Login Grafana refuse les identifiants | Variables `.env` modifiées après le premier démarrage — Grafana n'écrase pas le compte existant | Pour réinitialiser : `docker compose -f docker-compose.monitoring.yml exec grafana grafana-cli admin reset-admin-password <new>` |
| Le mot de passe n'est pas demandé en local | `GF_SECURITY_COOKIE_SECURE=true` empêche le cookie sur HTTP | Vérifier que l'override local met bien `false` |
| Disque proche de saturation | Volume `prometheus_data` au-delà de 4.5 GB | La rétention `size` purge automatiquement ; si problème persistant, réduire la rétention temporairement |

---

## F. Critères de validation (lien direct avec la spec)

| Critère | Vérification rapide | Spec |
|---|---|---|
| 4 conteneurs UP | `docker compose ... ps` | SC-001 |
| 2 targets Prometheus UP | <http://localhost:9090/targets> | Critère acceptation |
| Dashboards préfaits avec données | <http://localhost:3001> → Dashboards | SC-002 |
| Pas d'accès anonyme | `curl http://localhost:3001/api/dashboards` sans auth → 401 | SC-018, FR-006 |
| HTTPS production | <https://monitoring.<DOMAINE>> → badge valide | SC-005 |
| Pas de port 9090/3000 public | `nmap <IP-VPS>` depuis l'extérieur | SC-006 |
| Restart automatique | `docker kill usenghor_monitoring_prometheus` → revient en UP | SC-014 |
| Volumes préservés à `down` | `down` puis `up` → historique antérieur intact | SC-013 |
| Aucun `:latest` | `grep -E ':v?[0-9]' docker-compose.monitoring.yml \| wc -l` ≥ 4 | SC-017 |
| ≤ 15 min total | Chronométrer A1 → A7 | SC-009 |
