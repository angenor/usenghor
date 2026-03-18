# Research: Configuration VPS domaine et email SMTP

**Feature**: `005-vps-domain-smtp` | **Date**: 2026-03-18

## R1 — Configuration SSL/HTTPS avec Let's Encrypt sur le VPS

**Decision**: Utiliser le script `deploy.sh ssl` existant avec certbot standalone, puis décommenter les blocs SSL dans `nginx.conf`.

**Rationale**: L'infrastructure SSL est déjà prête dans le projet — le script `deploy.sh` contient une commande `ssl` qui utilise certbot en mode standalone (arrête nginx temporairement, obtient le certificat, redémarre nginx). Le fichier nginx.conf contient déjà les blocs HTTPS commentés avec les bons chemins de certificats (`/etc/nginx/ssl/`). Il suffit de :
1. Mettre à jour le `server_name` dans nginx.conf avec `usenghor-francophonie.org`
2. Exécuter `./deploy.sh ssl usenghor-francophonie.org` sur le VPS
3. Décommenter les blocs SSL dans nginx.conf
4. Ajouter la redirection www → non-www

**Alternatives considered**:
- Traefik comme reverse proxy : trop de changement d'architecture pour un besoin simple
- Caddy avec HTTPS automatique : même raison, nginx est déjà en place
- Certificat SSL payant : inutile, Let's Encrypt est gratuit et suffisant

## R2 — Envoi d'email via Gmail SMTP (aiosmtplib)

**Decision**: Implémenter un service email async avec `aiosmtplib` (déjà dans requirements.txt) utilisant le port 587 STARTTLS.

**Rationale**: `aiosmtplib` est déjà listé dans les dépendances du projet (requirements.txt) et est la librairie SMTP async standard pour FastAPI/asyncio. Le port 587 avec STARTTLS est recommandé par Google pour les mots de passe d'application. Jinja2 (aussi déjà dans requirements.txt) sera utilisé pour les templates d'email.

**Configuration SMTP fournie par le technicien** :
- Host: smtp.gmail.com
- Port: 587 (STARTTLS)
- User: communication@usenghor.org
- Password: mot de passe d'application (2FA activé)
- From: communication@usenghor.org

**Limites Gmail** :
- Google Workspace : ~2000 emails/jour (suffisant pour un site institutionnel)
- Mot de passe d'application : doit être régénéré si 2FA est désactivé/réactivé

**Alternatives considered**:
- fastapi-mail : wrapper autour d'aiosmtplib, ajoute une dépendance inutile
- smtplib synchrone : bloque l'event loop, mauvaise pratique avec FastAPI
- Service tiers (SendGrid, Brevo) : complexifie inutilement pour un usage modéré

## R3 — Mise à jour des variables d'environnement de production

**Decision**: Mettre à jour `.env.production.example` et le `.env` de production sur le VPS avec le nouveau domaine et les credentials SMTP.

**Rationale**: Le fichier `.env.production.example` référence encore `usenghor.org` dans CORS_ORIGINS et utilise des placeholders SMTP. Il faut :
1. Remplacer `usenghor.org` par `usenghor-francophonie.org` dans CORS_ORIGINS
2. Mettre à jour NUXT_SITE_URL avec `https://usenghor-francophonie.org`
3. Renseigner les vraies valeurs SMTP dans le .env de production (PAS dans le repo)

**Alternatives considered**:
- Docker secrets : plus sécurisé mais sur-ingénierie pour un seul VPS
- Vault/KMS : même raison, disproportionné pour l'usage

## R4 — Structure du service email backend

**Decision**: Créer `app/services/email.py` avec une classe `EmailService` asynchrone et des templates Jinja2 dans `app/templates/email/`.

**Rationale**: Le pattern service est cohérent avec l'architecture existante du backend (`app/services/`). Un service centralisé permet de :
- Gérer la connexion SMTP en un point unique
- Réutiliser le service pour newsletters, notifications, contact
- Journaliser les erreurs d'envoi sans crasher l'application

**Alternatives considered**:
- Fonction utilitaire simple : moins structuré, plus difficile à tester
- Worker/queue (Celery) : sur-ingénierie pour le volume attendu
