# Implementation Plan: Configuration VPS domaine et email SMTP

**Branch**: `005-vps-domain-smtp` | **Date**: 2026-03-18 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/005-vps-domain-smtp/spec.md`

## Summary

Configurer le VPS pour servir le site via `https://usenghor-francophonie.org` (SSL Let's Encrypt) et implémenter l'envoi d'emails transactionnels via SMTP Gmail (communication@usenghor.org, port 587 STARTTLS). L'infrastructure Docker et nginx existent déjà — il s'agit de mettre à jour les configurations et d'implémenter le service d'email manquant dans le backend FastAPI.

## Technical Context

**Language/Version**: Python 3.12 (backend FastAPI), TypeScript (frontend Nuxt 4)
**Primary Dependencies**: FastAPI, aiosmtplib 3.0.1+, Jinja2 3.1.3+ (déjà dans requirements.txt), Nginx, Certbot
**Storage**: PostgreSQL 15 (Docker), fichiers .env pour les secrets
**Testing**: Test SMTP manuel (envoi d'email de test), curl pour vérifier HTTPS
**Target Platform**: Linux server (Ubuntu, VPS OVH 137.74.117.231)
**Project Type**: Web application (monorepo frontend + backend + infra)
**Performance Goals**: N/A (configuration infra, pas de changement de performance)
**Constraints**: Mot de passe d'application Gmail (limite 500 emails/jour Google Workspace), certificat SSL via Let's Encrypt (renouvellement auto)
**Scale/Scope**: 1 VPS, 4 conteneurs Docker (nginx, frontend, backend, db)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Constitution non configurée pour ce projet (template vide). Aucune violation à vérifier. GATE PASSED.

## Project Structure

### Documentation (this feature)

```text
specs/005-vps-domain-smtp/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output (minimal — pas de nouvelles entités)
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
# Fichiers à modifier (existants)
deploy.sh                              # Mise à jour domaine dans la commande ssl
docker-compose.prod.yml                # Vérifier variables SMTP passées au backend
.env.production.example                # Mettre à jour avec le nouveau domaine et SMTP
nginx/nginx.conf                       # Décommenter SSL, ajouter server_name avec domaine

# Fichiers à créer (backend)
usenghor_backend/app/services/email.py # Service d'envoi d'email (aiosmtplib)
usenghor_backend/app/templates/email/  # Templates Jinja2 pour les emails

# Fichiers à modifier (backend)
usenghor_backend/app/config.py         # Ajouter smtp_from_email, smtp_use_tls
usenghor_backend/.env.example          # Mettre à jour SMTP defaults
```

**Structure Decision**: Pas de nouvelle structure — extension du backend existant avec un service email dans `app/services/` et des templates dans `app/templates/email/`.

## Complexity Tracking

Aucune violation de constitution à justifier.
