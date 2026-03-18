# Data Model: 006-password-reset-email

**Date**: 2026-03-18

## Entités existantes (modifications)

### users (modification)

Ajout d'une colonne pour l'invalidation des sessions JWT après changement de mot de passe.

| Colonne | Type | Contraintes | Description |
|---------|------|-------------|-------------|
| `password_changed_at` | TIMESTAMPTZ | NULL | Timestamp du dernier changement de mot de passe. Comparé au `iat` du JWT pour invalider les sessions antérieures. |

**Migration SQL** :
```sql
ALTER TABLE users ADD COLUMN password_changed_at TIMESTAMPTZ;
```

**Impact** : La fonction de validation JWT doit comparer `token.iat` < `user.password_changed_at` pour rejeter les tokens émis avant le changement de mot de passe.

---

### user_tokens (existante, aucune modification)

Table déjà en place, utilisée avec `type = 'password_reset'`.

| Colonne | Type | Contraintes | Description |
|---------|------|-------------|-------------|
| `id` | UUID | PK, auto-generated | Identifiant unique |
| `user_id` | UUID | FK → users.id, CASCADE | Utilisateur associé |
| `token` | VARCHAR(255) | UNIQUE, NOT NULL, INDEX | Token de réinitialisation (secrets.token_urlsafe(32)) |
| `type` | VARCHAR(50) | NOT NULL | `'password_reset'` ou `'email_verification'` |
| `expires_at` | TIMESTAMPTZ | NOT NULL | Date d'expiration (création + 1 heure) |
| `used` | BOOLEAN | DEFAULT FALSE | Indicateur d'utilisation (usage unique) |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Date de création |

## Relations

```
users 1 ──── N user_tokens
  │                │
  │                ├── type = 'password_reset'
  │                └── type = 'email_verification'
  │
  └── password_changed_at (nouveau)
       → comparé au iat du JWT pour invalidation
```

## Transitions d'état du token

```
[Créé]
  │ (token généré, expires_at = now + 1h, used = false)
  │
  ├──→ [Utilisé] (used = true, mot de passe changé)
  │      → Terminal, ne peut plus être réutilisé
  │
  ├──→ [Expiré] (now > expires_at)
  │      → Terminal, rejeté à la validation
  │
  └──→ [Invalidé] (nouveau token généré pour le même utilisateur)
         → Les anciens tokens sont marqués used = true
```

## Validation rules

- **Token** : doit être non-expiré (`expires_at > NOW()`) ET non-utilisé (`used = FALSE`)
- **Rate limit** : max 5 tokens `password_reset` non-expirés par `user_id` par heure (comptage en BDD)
- **Nouveau mot de passe** : minimum 8 caractères (cohérent avec `ResetPasswordRequest.new_password`)
- **Email lookup** : insensible à la casse (`.lower()` sur l'email, cohérent avec le login existant)

## Configuration (nouvelle)

| Variable | Type | Défaut | Description |
|----------|------|--------|-------------|
| `FRONTEND_URL` | str | `http://localhost:3000` | URL de base du frontend pour construire les liens de réinitialisation |
