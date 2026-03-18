# Data Model: Configuration VPS domaine et email SMTP

**Feature**: `005-vps-domain-smtp` | **Date**: 2026-03-18

## Entités impactées

Cette feature n'introduit aucune nouvelle table en base de données. Elle concerne uniquement la configuration d'infrastructure (nginx, Docker, variables d'environnement) et l'implémentation d'un service d'envoi d'email.

## Configuration SMTP (variables d'environnement)

Ces valeurs sont stockées dans le fichier `.env` de production, jamais en base de données :

| Variable | Type | Description |
|----------|------|-------------|
| SMTP_HOST | string | Serveur SMTP (smtp.gmail.com) |
| SMTP_PORT | int | Port SMTP (587) |
| SMTP_USER | string | Adresse email d'envoi (communication@usenghor.org) |
| SMTP_PASSWORD | string | Mot de passe d'application Gmail |
| SMTP_FROM_EMAIL | string | Adresse expéditeur (communication@usenghor.org) |

## Tables existantes potentiellement consommatrices du service email

Les tables suivantes pourront utiliser le service email une fois implémenté (pas de modification de schéma requise) :

- **newsletter_subscribers** : envoi de newsletters
- **newsletter_campaigns** : suivi des campagnes email
- **applications** : notifications de candidature
- **users** : réinitialisation de mot de passe, notifications admin
