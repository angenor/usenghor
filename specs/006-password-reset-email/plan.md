# Implementation Plan: Réinitialisation de mot de passe par email

**Branch**: `006-password-reset-email` | **Date**: 2026-03-18 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/006-password-reset-email/spec.md`

## Summary

Implémenter le flux complet de réinitialisation de mot de passe en self-service : formulaire « Mot de passe oublié », génération de token sécurisé, envoi d'email avec lien, formulaire de nouveau mot de passe, et invalidation des sessions JWT existantes. S'appuie sur l'infrastructure existante (table `user_tokens`, schémas Pydantic, service email `aiosmtplib` + Jinja2).

## Technical Context

**Language/Version**: Python 3.14 (backend FastAPI), TypeScript (frontend Nuxt 4 / Vue 3)
**Primary Dependencies**: FastAPI, SQLAlchemy (async), Pydantic v2, aiosmtplib, Jinja2, Nuxt 4, Vue 3, Tailwind CSS
**Storage**: PostgreSQL 16 (Docker: `usenghor_postgres` local, `usenghor_db` prod)
**Testing**: Tests manuels end-to-end (curl + navigateur)
**Target Platform**: Web (serveur Linux, navigateurs modernes)
**Project Type**: Web application (monorepo frontend + backend)
**Performance Goals**: Email envoyé en < 2 secondes, pages frontend < 1 seconde de chargement
**Constraints**: Pas de divulgation d'existence de compte, token expire en 1h, max 5 demandes/email/heure
**Scale/Scope**: ~500 utilisateurs, volume faible de réinitialisations

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Constitution non configurée (template vierge). Aucun gate à vérifier.

## Project Structure

### Documentation (this feature)

```text
specs/006-password-reset-email/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/
│   └── api-endpoints.md # Phase 1 output
└── checklists/
    └── requirements.md  # Spec quality checklist
```

### Source Code (repository root)

```text
usenghor_backend/
├── app/
│   ├── config.py                          # + frontend_url
│   ├── core/
│   │   └── security.py                    # + vérification password_changed_at
│   ├── models/
│   │   └── identity.py                    # + password_changed_at sur User
│   ├── schemas/
│   │   └── identity.py                    # + VerifyResetTokenResponse
│   ├── services/
│   │   └── identity_service.py            # + create_reset_token, validate_reset_token, reset_password_with_token
│   ├── routers/
│   │   └── auth.py                        # + forgot-password, reset-password, verify-reset-token
│   └── templates/email/
│       └── password_reset.html            # Nouveau template email
└── documentation/modele_de_données/
    ├── services/02_identity.sql           # + password_changed_at
    └── migrations/007_password_changed_at.sql  # Migration

usenghor_nuxt/
└── app/
    └── pages/admin/
        ├── login.vue                      # + lien « Mot de passe oublié ? »
        ├── forgot-password.vue            # Nouvelle page
        └── reset-password.vue             # Nouvelle page
```

**Structure Decision**: Architecture web existante (monorepo backend/frontend). Les modifications s'intègrent dans les fichiers et patterns existants sans création de nouveaux modules ou répertoires (hormis les 3 fichiers de pages/templates).

## Complexity Tracking

Aucune violation de constitution à justifier (constitution non configurée).
