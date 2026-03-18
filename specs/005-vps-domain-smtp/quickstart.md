# Quickstart: Configuration VPS domaine et email SMTP

**Feature**: `005-vps-domain-smtp` | **Date**: 2026-03-18

## Prérequis

- Accès SSH au VPS (`ssh ubuntu@137.74.117.231`)
- DNS configuré : `usenghor-francophonie.org` et `www.usenghor-francophonie.org` pointent vers 137.74.117.231
- SPF configuré côté DNS
- Mot de passe d'application Gmail pour communication@usenghor.org

## Étapes de déploiement

### 1. Mettre à jour les fichiers de configuration (local)

```bash
# Mettre à jour nginx.conf avec le domaine et SSL
# Mettre à jour .env.production.example avec le nouveau domaine
# Mettre à jour docker-compose.prod.yml si nécessaire
```

### 2. Déployer les modifications sur le VPS

```bash
./deploy.sh update
```

### 3. Générer le certificat SSL

```bash
./deploy.sh ssl usenghor-francophonie.org
```

### 4. Configurer le .env de production sur le VPS

```bash
ssh ubuntu@137.74.117.231
cd /opt/usenghor

# Éditer le .env avec les valeurs SMTP
nano .env
```

Variables à renseigner :
```
CORS_ORIGINS=https://usenghor-francophonie.org,https://www.usenghor-francophonie.org
NUXT_SITE_URL=https://usenghor-francophonie.org
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=communication@usenghor.org
SMTP_PASSWORD=<mot_de_passe_application_gmail>
SMTP_FROM_EMAIL=communication@usenghor.org
```

### 5. Redémarrer les conteneurs

```bash
./deploy.sh restart
```

### 6. Vérifier

```bash
# Vérifier HTTPS
curl -I https://usenghor-francophonie.org

# Vérifier redirection www
curl -I https://www.usenghor-francophonie.org

# Vérifier redirection HTTP
curl -I http://usenghor-francophonie.org

# Tester l'envoi d'email (via endpoint admin)
curl -X POST https://usenghor-francophonie.org/api/admin/email/test \
  -H "Authorization: Bearer <jwt>" \
  -H "Content-Type: application/json" \
  -d '{"to":"votre@email.com","subject":"Test","message":"Hello"}'
```

## Dépannage

- **Certificat SSL échoue** : Vérifier que le DNS a propagé (`dig usenghor-francophonie.org`)
- **Email en spam** : Vérifier le SPF (`dig TXT usenghor-francophonie.org`)
- **Email non envoyé** : Vérifier les logs backend (`./deploy.sh logs backend`)
- **Mot de passe SMTP refusé** : Vérifier que la 2FA est active et le mot de passe d'application valide
