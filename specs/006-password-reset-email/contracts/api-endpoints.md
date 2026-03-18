# API Contracts: Password Reset Endpoints

**Date**: 2026-03-18

## POST /api/auth/forgot-password

Demande de réinitialisation de mot de passe. Réponse identique que l'email existe ou non.

**Request**:
```json
{
  "email": "utilisateur@example.com"
}
```

**Response 200** (toujours, même si email inexistant):
```json
{
  "message": "Si un compte existe avec cette adresse email, un lien de réinitialisation a été envoyé."
}
```

**Response 422** (validation Pydantic):
```json
{
  "detail": [
    {
      "loc": ["body", "email"],
      "msg": "value is not a valid email address",
      "type": "value_error"
    }
  ]
}
```

**Comportement interne** (non visible dans la réponse):
- Si email inexistant → 200, aucun email envoyé
- Si compte désactivé (`active = false`) → 200, aucun email envoyé
- Si compte non vérifié (`email_verified = false`) → 200, aucun email envoyé
- Si rate limit atteint (>= 5 demandes/heure) → 200, aucun email envoyé
- Si compte valide → génère token, invalide tokens précédents, envoie email, 200

---

## POST /api/auth/reset-password

Réinitialisation effective du mot de passe avec un token valide.

**Request**:
```json
{
  "token": "abc123...urlsafe_token",
  "new_password": "NouveauMotDePasse123"
}
```

**Response 200** (succès):
```json
{
  "message": "Votre mot de passe a été réinitialisé avec succès. Vous pouvez maintenant vous connecter."
}
```

**Response 400** (token invalide, expiré ou déjà utilisé):
```json
{
  "detail": "Ce lien de réinitialisation est invalide ou a expiré."
}
```

**Response 422** (validation Pydantic — mot de passe trop court):
```json
{
  "detail": [
    {
      "loc": ["body", "new_password"],
      "msg": "String should have at least 8 characters",
      "type": "string_too_short"
    }
  ]
}
```

**Comportement interne**:
- Valide le token : existe, non-expiré, non-utilisé
- Hash le nouveau mot de passe
- Met à jour `users.password_hash` et `users.password_changed_at`
- Marque le token `used = true`
- Toutes les sessions JWT existantes sont automatiquement invalidées (via `password_changed_at`)

---

## GET /api/auth/verify-reset-token

Vérifie la validité d'un token de réinitialisation (utilisé par le frontend pour afficher le bon état de la page).

**Query Parameters**:
- `token` (string, required)

**Response 200** (token valide):
```json
{
  "valid": true,
  "user_first_name": "Jean"
}
```

**Response 200** (token invalide/expiré):
```json
{
  "valid": false,
  "reason": "expired" | "used" | "invalid"
}
```

---

## Schémas Pydantic existants utilisés

```python
# Déjà définis dans app/schemas/identity.py
class ForgotPasswordRequest(BaseModel):
    email: EmailStr

class ResetPasswordRequest(BaseModel):
    token: str
    new_password: str = Field(min_length=8)

# Réponse générique existante
class MessageResponse(BaseModel):
    message: str
```

## Nouveau schéma à créer

```python
class VerifyResetTokenResponse(BaseModel):
    valid: bool
    user_first_name: str | None = None
    reason: str | None = None  # "expired", "used", "invalid"
```
