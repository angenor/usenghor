# Feature Specification: Configuration VPS domaine et email SMTP

**Feature Branch**: `005-vps-domain-smtp`
**Created**: 2026-03-18
**Status**: Draft
**Input**: Configuration du VPS avec le domaine https://usenghor-francophonie.org/ et mise en place de l'envoi d'email via SMTP Gmail (communication@usenghor.org).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Accès au site via le nom de domaine (Priority: P1)

Un visiteur saisit `https://usenghor-francophonie.org` dans son navigateur et accède au site de l'Université Senghor avec un certificat SSL valide (cadenas vert).

**Why this priority**: Sans HTTPS et le domaine correctement configuré, le site est inaccessible au public. C'est le prérequis fondamental.

**Independent Test**: Ouvrir un navigateur et accéder à https://usenghor-francophonie.org — le site s'affiche correctement avec un certificat SSL valide.

**Acceptance Scenarios**:

1. **Given** le DNS pointe vers le VPS (137.74.117.231), **When** un visiteur accède à https://usenghor-francophonie.org, **Then** le site Nuxt s'affiche correctement avec HTTPS
2. **Given** un visiteur accède à http://usenghor-francophonie.org, **Then** il est automatiquement redirigé vers la version HTTPS
3. **Given** un visiteur accède à https://www.usenghor-francophonie.org, **Then** il est redirigé vers https://usenghor-francophonie.org (domaine canonique sans www)

---

### User Story 2 - Envoi d'emails depuis l'application (Priority: P1)

L'application backend peut envoyer des emails transactionnels (notifications, confirmations, newsletters) depuis l'adresse communication@usenghor.org via le serveur SMTP Gmail.

**Why this priority**: L'envoi d'email est essentiel pour les fonctionnalités de contact, newsletter et notifications de l'application.

**Independent Test**: Déclencher un envoi d'email depuis l'application (ex: formulaire de contact ou test SMTP) et vérifier la réception dans une boîte email externe.

**Acceptance Scenarios**:

1. **Given** les credentials SMTP sont configurés sur le VPS, **When** l'application envoie un email, **Then** l'email est reçu par le destinataire avec l'expéditeur communication@usenghor.org
2. **Given** le SPF est configuré côté DNS, **When** un email est envoyé, **Then** l'email n'arrive pas en spam (délivrabilité correcte)
3. **Given** un envoi d'email échoue (serveur SMTP indisponible), **When** l'erreur se produit, **Then** l'application journalise l'erreur sans crasher

---

### User Story 3 - Configuration pérenne et sécurisée (Priority: P2)

Les credentials SMTP et les variables d'environnement de production sont configurées de manière sécurisée sur le VPS, persistantes au redémarrage des conteneurs Docker.

**Why this priority**: La configuration doit être fiable et sécurisée pour la production.

**Independent Test**: Redémarrer les conteneurs Docker et vérifier que le site reste accessible et que l'envoi d'email fonctionne toujours.

**Acceptance Scenarios**:

1. **Given** les variables SMTP sont dans le fichier .env de production, **When** les conteneurs Docker redémarrent, **Then** la configuration SMTP est préservée
2. **Given** les credentials SMTP sont stockés, **When** un accès non autorisé au VPS est tenté, **Then** les mots de passe ne sont pas exposés dans les logs ou le code source

---

### Edge Cases

- Que se passe-t-il si le certificat SSL expire ? (renouvellement automatique via Let's Encrypt/Certbot)
- Que se passe-t-il si Gmail bloque l'envoi (limite quotidienne atteinte ou mot de passe d'application révoqué) ?
- Que se passe-t-il si le DNS n'a pas encore propagé lors de la génération du certificat SSL ?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le serveur Nginx DOIT être configuré avec `usenghor-francophonie.org` comme domaine canonique et rediriger `www.usenghor-francophonie.org` vers celui-ci
- **FR-002**: Le site DOIT être accessible en HTTPS avec un certificat SSL valide (Let's Encrypt)
- **FR-003**: Les requêtes HTTP DOIVENT être redirigées automatiquement vers HTTPS
- **FR-004**: Les variables d'environnement de production DOIVENT inclure le domaine correct dans CORS_ORIGINS, NUXT_SITE_URL et toute autre référence au domaine
- **FR-005**: Le backend DOIT être configuré avec les credentials SMTP (smtp.gmail.com, port 587 STARTTLS, communication@usenghor.org)
- **FR-006**: L'application DOIT pouvoir envoyer des emails via le service SMTP configuré
- **FR-007**: Les variables SMTP DOIVENT être stockées exclusivement dans le fichier .env de production (jamais dans le code source)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Le site est accessible à https://usenghor-francophonie.org avec un certificat SSL valide
- **SC-002**: La redirection HTTP vers HTTPS fonctionne correctement
- **SC-003**: Un email de test envoyé depuis l'application est reçu par le destinataire en moins de 2 minutes
- **SC-004**: Les emails envoyés ne sont pas classés comme spam (vérification SPF passante)
- **SC-005**: Après un redémarrage des conteneurs Docker, le site et l'envoi d'email fonctionnent sans intervention manuelle

## Clarifications

### Session 2026-03-18

- Q: Convention de domaine canonique (www vs non-www) ? → A: `usenghor-francophonie.org` sans www est canonique, `www` redirige vers non-www
- Q: Port SMTP à utiliser (465 SSL vs 587 STARTTLS) ? → A: Port 587 avec STARTTLS (standard recommandé par Gmail)

## Assumptions

- Le DNS est déjà configuré et pointe vers 137.74.117.231 (confirmé par le technicien)
- Le SPF a été ajouté côté DNS pour autoriser l'IP du serveur (confirmé par le technicien)
- Le mot de passe d'application Gmail a été généré pour communication@usenghor.org (confirmé par le technicien)
- L'infrastructure Docker existante (nginx, frontend, backend, db) est déjà déployée sur le VPS
- Le script deploy.sh existant gère déjà la commande SSL (`./deploy.sh ssl`)
