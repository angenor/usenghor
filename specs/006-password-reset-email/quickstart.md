# Quickstart: 006-password-reset-email

**Date**: 2026-03-18

## Prérequis

- Backend FastAPI en cours d'exécution (`uvicorn app.main:app --reload`)
- PostgreSQL via Docker (`docker compose up -d`)
- Frontend Nuxt en cours d'exécution (`pnpm dev`)
- SMTP configuré dans `usenghor_backend/.env` (variable `SMTP_PASSWORD`)

## Fichiers à créer

### Backend

| Fichier | Description |
|---------|-------------|
| `app/templates/email/password_reset.html` | Template Jinja2 pour l'email de réinitialisation |

### Frontend

| Fichier | Description |
|---------|-------------|
| `app/pages/admin/forgot-password.vue` | Page formulaire « Mot de passe oublié » |
| `app/pages/admin/reset-password.vue` | Page formulaire nouveau mot de passe |

## Fichiers à modifier

### Backend

| Fichier | Modification |
|---------|-------------|
| `app/config.py` | Ajouter `frontend_url: str` |
| `app/models/identity.py` | Ajouter `password_changed_at` au modèle User |
| `app/schemas/identity.py` | Ajouter `VerifyResetTokenResponse` |
| `app/routers/auth.py` | Ajouter 3 endpoints : forgot-password, reset-password, verify-reset-token |
| `app/services/identity_service.py` | Ajouter méthodes : create_reset_token, validate_reset_token, reset_password_with_token |
| `app/core/security.py` | Modifier `decode_token` pour vérifier `password_changed_at` |

### Frontend

| Fichier | Modification |
|---------|-------------|
| `app/pages/admin/login.vue` | Ajouter lien « Mot de passe oublié ? » |

### Base de données

| Fichier | Modification |
|---------|-------------|
| `documentation/modele_de_données/services/02_identity.sql` | Ajouter colonne `password_changed_at` à la table users |
| `documentation/modele_de_données/migrations/` | Nouveau fichier de migration |

## Ordre d'implémentation recommandé

1. Migration BDD (`password_changed_at`)
2. Modèle + config backend
3. Service identity (logique token + reset)
4. Modification sécurité JWT (vérification `password_changed_at`)
5. Template email
6. Endpoints API
7. Pages frontend (forgot-password, reset-password)
8. Lien dans login.vue
9. Tests manuels end-to-end

## Test rapide

```bash
# 1. Appliquer la migration
docker exec -i usenghor_postgres psql -U usenghor -d usenghor < usenghor_backend/documentation/modele_de_données/migrations/007_password_changed_at.sql

# 2. Tester l'endpoint forgot-password
curl -X POST http://localhost:8000/api/auth/forgot-password \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@usenghor.org"}'

# 3. Vérifier le token en BDD
docker exec -i usenghor_postgres psql -U usenghor -d usenghor \
  -c "SELECT token, expires_at, used FROM user_tokens WHERE type='password_reset' ORDER BY created_at DESC LIMIT 1;"

# 4. Tester l'endpoint reset-password avec le token récupéré
curl -X POST http://localhost:8000/api/auth/reset-password \
  -H "Content-Type: application/json" \
  -d '{"token": "TOKEN_ICI", "new_password": "NouveauMdp123"}'
```
