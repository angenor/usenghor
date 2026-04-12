# Runbook — Nettoyage disque Docker en production

**Serveur** : `ubuntu@137.74.117.231` (`/opt/usenghor`)
**Dernière intervention** : 2026-04-12
**Contexte** : Après le déploiement de la feature `016-mediatheque-direct-upload`, le disque `/` était à 80 % d'utilisation (77 GB / 96 GB) alors que l'application elle-même ne pèse presque rien.

---

## 1. Diagnostic — trouver qui mange le disque

### 1.1 Vue globale

```bash
ssh ubuntu@137.74.117.231 'df -h /'
```

Si `Use%` dépasse 70 %, investiguer.

### 1.2 Piège classique : Docker + containerd

Le daemon Docker sur ce serveur utilise le **containerd image store** (défaut depuis Docker 23+). Les images et le build cache ne vivent donc **pas** dans `/var/lib/docker/` mais dans `/var/lib/containerd/`.

Un premier `du -sh /var/lib/docker` donne une valeur faussement rassurante (quelques GB) alors que le vrai consommateur est ailleurs.

**Commandes pour ne pas tomber dans le piège** :

```bash
# Vue Docker officielle (reflète la réalité, quelle que soit la storage backend)
ssh ubuntu@137.74.117.231 'docker system df'

# Vue système, en restant sur un seul filesystem
ssh ubuntu@137.74.117.231 'sudo du -shx /var/lib/* 2>/dev/null | sort -rh | head -10'
```

Typiquement, on voit :

```
67G  /var/lib/containerd   ← le vrai coupable
3.1G /var/lib/docker
140M /var/lib/apt
...
```

Et côté Docker :

| Type | Taille | Reclaimable |
|---|---|---|
| Images (4 actives) | 61.2 GB | 61.2 GB (100 %) |
| **Build Cache** (1049 entrées) | **70.16 GB** | **69.72 GB** |
| Containers | 4 MB | 0 |
| Local Volumes | 353 MB | 0 |

Le build cache BuildKit est très gros parce qu'il garde les layers intermédiaires (notamment le stage `builder` multi-stage de Nuxt qui produit ~500 MB de `.output/` + `node_modules` à chaque build).

### 1.3 Sanity check

```bash
# Les conteneurs actifs et leurs volumes doivent rester intacts avant tout nettoyage
ssh ubuntu@137.74.117.231 'docker ps && docker volume ls'
```

Conteneurs attendus : `usenghor_backend`, `usenghor_frontend`, `usenghor_db`, `usenghor_nginx`.
Volume Postgres : `usenghor_postgres_data` (ou équivalent).

---

## 2. Nettoyage — 3 niveaux de risque

### Option A — Sûre (recommandée en premier recours)

```bash
ssh ubuntu@137.74.117.231 'docker builder prune -af'
```

- **Effet** : supprime tout le build cache BuildKit (layers intermédiaires de `docker build`).
- **Impact runtime** : ❌ aucun. Les conteneurs actifs continuent de tourner sans interruption.
- **Coût** : le prochain `./deploy.sh update` sera ~2-3 minutes plus lent parce qu'il re-télécharge les images de base (node, python, alpine…) et re-cache les étapes initiales.
- **Gain typique** : 50-70 GB après plusieurs semaines de déploiements.

### Option B — Plus agressive (si A ne suffit pas)

```bash
ssh ubuntu@137.74.117.231 'docker builder prune -af && docker image prune -af'
```

- Ajoute la suppression des images non taggées (`<none>:<none>`, orphelines d'un ancien build).
- Impact runtime : aucun — seules les images **non utilisées** par un conteneur actif sont supprimées.
- À utiliser si Option A laisse encore trop d'images dangling.

### Option C — NUCLÉAIRE ⚠️ À ÉVITER

```bash
docker system prune -af --volumes
```

- **NE JAMAIS LANCER** sans vérification préalable : supprime aussi les **volumes non référencés**, ce qui peut effacer la base de données Postgres si le volume n'est pas vu comme « utilisé » à ce moment-là (typiquement lors d'un `docker compose down` préalable).
- À réserver à un serveur en cours de décommissionnement.

---

## 3. Vérification post-nettoyage

```bash
ssh ubuntu@137.74.117.231 'df -h / && docker system df && docker ps'
```

Contrôles :

- `Use%` du disque a baissé (cible : < 30 %).
- `Build Cache` est à 0 B ou quelques KB.
- Les 4 conteneurs `usenghor_*` sont toujours `Up` et `healthy`.
- Tester un parcours utilisateur critique (page d'accueil, login admin).

---

## 4. Prévention — cron hebdomadaire (installée 2026-04-12)

Une crontab a été installée sur `ubuntu@137.74.117.231` :

```cron
# Purge hebdomadaire du build cache Docker (évite l accumulation multi-GB)
0 3 * * 0 /usr/bin/docker builder prune -af 2>&1 | logger -t docker-prune
```

- **Horaire** : tous les dimanches à 03:00 UTC (trafic minimal).
- **Action** : purge totale du build cache BuildKit (Option A).
- **Logs** : envoyés dans `syslog` sous le tag `docker-prune`. Pour consulter :

  ```bash
  ssh ubuntu@137.74.117.231 'sudo journalctl -t docker-prune --since "7 days ago"'
  # ou
  ssh ubuntu@137.74.117.231 'sudo grep docker-prune /var/log/syslog'
  ```

### Vérifier que la cron est bien en place

```bash
ssh ubuntu@137.74.117.231 'crontab -l'
```

Doit afficher la ligne ci-dessus. Si elle a disparu, la réinstaller :

```bash
ssh ubuntu@137.74.117.231 '(echo "# Purge hebdomadaire du build cache Docker"; echo "0 3 * * 0 /usr/bin/docker builder prune -af 2>&1 | logger -t docker-prune") | crontab -'
```

### Impact attendu

- Si tu déploies **plusieurs fois par semaine**, la cron est quasi sans effet — c'est bon signe, ça veut dire que le cache n'a pas eu le temps d'exploser.
- Si tu ne déploies pas d'une semaine sur l'autre, le cache est nettoyé à zéro chaque dimanche. Le prochain déploiement sera un peu plus lent (~2-3 min), c'est le prix à payer.
- Le seuil d'alerte à surveiller manuellement reste **50 %** d'utilisation disque. Au-delà, relancer manuellement l'Option A sans attendre dimanche.

---

## 5. Quand envisager une vraie solution permanente

La cron hebdo suffit tant que :

- On reste sur un seul serveur de 96 GB.
- Le nombre de déploiements reste < 20 / semaine.
- Aucun volume ne grossit de manière pathologique (logs, uploads persistés).

Si un de ces seuils est dépassé, options plus structurelles :

1. **Configurer les limites BuildKit** dans `/etc/docker/daemon.json` :

   ```json
   {
     "builder": {
       "gc": {
         "enabled": true,
         "defaultKeepStorage": "5GB",
         "policy": [
           { "keepStorage": "5GB", "filter": ["unused-for=168h"] }
         ]
       }
     }
   }
   ```

   Puis `sudo systemctl restart docker`. BuildKit fait alors sa propre GC en continu, sans cron externe.

2. **Monter `/var/lib/containerd` sur un volume dédié** plus gros (ex. 100 GB supplémentaires). Ne règle pas le problème, juste le repousse.

3. **Déporter les builds** sur un runner externe (GitHub Actions, GitLab Runner) qui pousse des images pré-buildées sur un registry privé, et la prod ne fait que `docker pull`. Plus propre mais demande une refonte du `deploy.sh` actuel.

---

## 6. Historique

| Date | Action | Avant | Après | Notes |
|---|---|---|---|---|
| 2026-04-12 | `docker builder prune -af` + installation cron | 77 GB / 96 GB (80 %) | 12 GB / 96 GB (13 %) | Déclencheur : déploiement feature `016-mediatheque-direct-upload` |

---

## Références croisées

- Script de déploiement : [`deploy.sh`](../../deploy.sh) à la racine du monorepo
- Docs projet : [`CLAUDE.md`](../../CLAUDE.md) section « Docker » et « Déploiement »
- Doc officielle BuildKit GC : https://docs.docker.com/build/cache/garbage-collection/
