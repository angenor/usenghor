# Guide de Déploiement - USenghor

Ce guide décrit la procédure complète pour déployer le projet USenghor sur un serveur VPS Ubuntu via Git.

## Repositories GitHub

- **Backend**: https://github.com/angenor/usenghor_backend.git
- **Frontend**: https://github.com/angenor/usenghor_nuxt.git

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                    NGINX (port 80/443)              │
│                   Reverse Proxy + SSL               │
└─────────────────┬───────────────────┬───────────────┘
                  │                   │
         /api/*   │                   │  /*
                  ▼                   ▼
        ┌─────────────────┐  ┌─────────────────┐
        │    Backend      │  │    Frontend     │
        │  FastAPI:8000   │  │   Nuxt:3000     │
        └────────┬────────┘  └─────────────────┘
                 │
                 ▼
        ┌─────────────────┐
        │   PostgreSQL    │
        │     :5432       │
        └─────────────────┘
```

## Structure sur le serveur

```
/opt/usenghor/
├── usenghor_backend/       # Cloné depuis GitHub
├── usenghor_nuxt/          # Cloné depuis GitHub
├── docker-compose.prod.yml
├── nginx/
│   ├── nginx.conf
│   └── ssl/
└── .env
```

## Pré-requis

### Sur votre machine locale

- Git
- SSH configuré avec accès au serveur

### Sur le serveur VPS

- Ubuntu 20.04+ (ou Debian 11+)
- Accès SSH avec l'utilisateur `ubuntu`
- Ports ouverts : 80 (HTTP), 443 (HTTPS), 22 (SSH)
- Minimum 2 Go de RAM recommandé

---

## Déploiement initial (première fois)

### Étape 1 : Vérifier la connexion SSH

```bash
ssh ubuntu@137.74.117.231
```

Si la connexion échoue :

```bash
ssh-copy-id ubuntu@137.74.117.231
```

### Étape 2 : Setup initial du serveur

**Depuis votre machine locale** (pas sur le VPS), exécutez :

```bash
cd /Users/mac/Documents/projets/2025/usenghor
./deploy.sh setup
```

Le script va :

1. ✅ Installer Docker et Docker Compose
2. ✅ Installer Git
3. ✅ Créer `/opt/usenghor`
4. ✅ Cloner les deux repositories depuis GitHub
5. ✅ Uploader les fichiers de configuration
6. ✅ **Générer les secrets sécurisés** (APP_SECRET_KEY, JWT_SECRET_KEY, POSTGRES_PASSWORD)
7. ✅ Créer le fichier `.env` avec les secrets

⚠️ **Important** : Le script affichera les secrets générés. Sauvegardez-les !

### Étape 3 : (Optionnel) Personnaliser la configuration

Si vous devez modifier d'autres paramètres (SMTP, CORS, etc.) :

```bash
./deploy.sh connect
nano .env
```

Variables optionnelles à configurer :

| Variable | Description | Valeur par défaut |
|----------|-------------|-------------------|
| `CORS_ORIGINS` | Origines autorisées | `https://usenghor.org` |
| `SMTP_HOST` | Serveur email | (vide) |
| `SMTP_USER` | Utilisateur SMTP | (vide) |
| `SMTP_PASSWORD` | Mot de passe SMTP | (vide) |

### Étape 4 : Lancer le déploiement

**Depuis votre machine locale** :

```bash
./deploy.sh deploy
```

---

## Mises à jour (après modifications)

### Workflow de mise à jour

1. **Faire vos modifications** localement
2. **Pousser sur GitHub** :
   ```bash
   # Backend
   cd usenghor_backend
   git add . && git commit -m "description" && git push

   # Frontend
   cd usenghor_nuxt
   git add . && git commit -m "description" && git push
   ```
3. **Déployer** :
   ```bash
   ./deploy.sh deploy
   ```

Le script va automatiquement :
- Récupérer les dernières modifications depuis GitHub
- Reconstruire les images Docker
- Redémarrer les services

### Mise à jour rapide

Pour une mise à jour simple sans arrêter les services :

```bash
./deploy.sh update
```

---

## Commandes disponibles

> **Note** : Toutes ces commandes s'exécutent **depuis votre machine locale**. Elles se connectent automatiquement au VPS via SSH.

| Commande | Description |
|----------|-------------|
| `./deploy.sh setup` | Installation initiale du serveur |
| `./deploy.sh deploy` | Déploiement complet (pull + rebuild + restart) |
| `./deploy.sh update` | Mise à jour rapide (pull + rebuild) |
| `./deploy.sh status` | État des containers et infos Git |
| `./deploy.sh logs` | Voir tous les logs |
| `./deploy.sh logs backend` | Logs du backend uniquement |
| `./deploy.sh logs frontend` | Logs du frontend uniquement |
| `./deploy.sh restart` | Redémarrer tous les services |
| `./deploy.sh restart backend` | Redémarrer le backend |
| `./deploy.sh stop` | Arrêter tous les services |
| `./deploy.sh ssl` | Configurer SSL Let's Encrypt |
| `./deploy.sh backup` | Sauvegarder la base de données |
| `./deploy.sh connect` | SSH direct vers le serveur |

---

## Configuration SSL (HTTPS)

### Prérequis

- Le domaine doit pointer vers le serveur (DNS configuré)
- Les ports 80 et 443 doivent être ouverts

### Installation du certificat

```bash
./deploy.sh ssl usenghor.org
```

### Activer HTTPS dans nginx

1. Éditer la configuration nginx sur le serveur :

```bash
./deploy.sh connect
nano /opt/usenghor/nginx/nginx.conf
```

2. Décommenter les lignes SSL :

```nginx
# Décommenter cette section pour la redirection HTTP → HTTPS
server {
    listen 80;
    server_name usenghor.org www.usenghor.org;
    return 301 https://$server_name$request_uri;
}

# Dans le bloc server principal, décommenter :
listen 443 ssl http2;
ssl_certificate /etc/nginx/ssl/fullchain.pem;
ssl_certificate_key /etc/nginx/ssl/privkey.pem;
# ... autres lignes SSL
```

3. Redémarrer nginx :

```bash
./deploy.sh restart nginx
```

---

## Gestion de la base de données

### Accès via Adminer

```bash
# Démarrer Adminer
./deploy.sh connect
docker compose -f docker-compose.prod.yml --profile tools up -d adminer
```

Accéder à : `http://137.74.117.231:8080`

- Système : PostgreSQL
- Serveur : db
- Utilisateur : usenghor
- Mot de passe : (votre POSTGRES_PASSWORD)

### Sauvegardes

```bash
# Créer une sauvegarde (téléchargée localement)
./deploy.sh backup

# Restaurer depuis le serveur
cat backup_20250130.sql | ssh ubuntu@137.74.117.231 "docker exec -i usenghor_db psql -U usenghor -d usenghor"
```

---

## Dépannage

### Voir les logs

```bash
./deploy.sh logs              # Tous les services
./deploy.sh logs backend      # Backend uniquement
./deploy.sh logs frontend     # Frontend uniquement
./deploy.sh logs db           # Base de données
./deploy.sh logs nginx        # Nginx
```

### Vérifier l'état

```bash
./deploy.sh status
```

Affiche :
- État des containers Docker
- Derniers commits Git (backend + frontend)
- Utilisation disque et mémoire

### Les containers ne démarrent pas

```bash
./deploy.sh connect
cd /opt/usenghor

# Vérifier les erreurs
docker compose -f docker-compose.prod.yml logs

# Vérifier le fichier .env
cat .env

# Vérifier l'espace disque
df -h
```

### Erreur de connexion à la base de données

```bash
./deploy.sh connect
docker exec usenghor_db pg_isready -U usenghor
docker compose -f docker-compose.prod.yml logs db
```

### Forcer un rebuild complet

```bash
./deploy.sh connect
cd /opt/usenghor
docker compose -f docker-compose.prod.yml down
docker compose -f docker-compose.prod.yml build --no-cache
docker compose -f docker-compose.prod.yml up -d
```

### Réinitialiser les données (⚠️ destructif)

```bash
./deploy.sh connect
cd /opt/usenghor
docker compose -f docker-compose.prod.yml down -v  # Supprime les volumes
docker compose -f docker-compose.prod.yml up -d
```

---

## Résumé des étapes

```
┌─────────────────────────────────────────────────────────────┐
│                    DÉPLOIEMENT INITIAL                      │
├─────────────────────────────────────────────────────────────┤
│  1. ./deploy.sh setup     # Installe tout + génère secrets  │
│  2. ./deploy.sh deploy    # Lance l'application             │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    MISES À JOUR                             │
├─────────────────────────────────────────────────────────────┤
│  1. git push (backend et/ou frontend)                       │
│  2. ./deploy.sh deploy                                      │
└─────────────────────────────────────────────────────────────┘
```
