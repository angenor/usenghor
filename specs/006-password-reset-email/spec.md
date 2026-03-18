# Feature Specification: Réinitialisation de mot de passe par email

**Feature Branch**: `006-password-reset-email`
**Created**: 2026-03-18
**Status**: Draft
**Input**: User description: "branche l'envoie d'email pour Identité/Auth — réinitialisation de mot de passe"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Demander la réinitialisation de mot de passe (Priority: P1)

Un utilisateur ayant oublié son mot de passe accède à la page de connexion, clique sur « Mot de passe oublié ? », saisit son adresse email et reçoit un email contenant un lien sécurisé pour définir un nouveau mot de passe. Le lien expire après un délai défini.

**Why this priority**: C'est le flux principal de la fonctionnalité. Sans lui, aucun utilisateur ne peut récupérer l'accès à son compte de manière autonome. Aujourd'hui, seul un administrateur peut réinitialiser un mot de passe, ce qui crée un goulot d'étranglement.

**Independent Test**: Peut être testé en saisissant une adresse email valide dans le formulaire « Mot de passe oublié » et en vérifiant la réception de l'email avec un lien fonctionnel.

**Acceptance Scenarios**:

1. **Given** un utilisateur avec un compte existant et vérifié, **When** il saisit son email dans le formulaire de réinitialisation, **Then** un email contenant un lien de réinitialisation est envoyé à cette adresse dans un délai de 2 minutes.
2. **Given** un utilisateur saisit une adresse email inexistante, **When** il soumet le formulaire, **Then** le même message de confirmation est affiché (pas de divulgation d'existence de compte) et aucun email n'est envoyé.
3. **Given** un utilisateur dont le compte est désactivé, **When** il demande une réinitialisation, **Then** le même message de confirmation est affiché et aucun email n'est envoyé.

---

### User Story 2 - Définir un nouveau mot de passe via le lien reçu (Priority: P1)

L'utilisateur clique sur le lien reçu par email, accède à un formulaire de saisie de nouveau mot de passe (avec confirmation), et valide. Son mot de passe est mis à jour et il peut se connecter immédiatement.

**Why this priority**: Complète le flux de réinitialisation. Sans cette étape, le lien envoyé par email serait inutile.

**Independent Test**: Peut être testé en cliquant sur un lien de réinitialisation valide, en saisissant un nouveau mot de passe conforme aux règles, et en se connectant avec ce nouveau mot de passe.

**Acceptance Scenarios**:

1. **Given** un lien de réinitialisation valide et non expiré, **When** l'utilisateur saisit un nouveau mot de passe (minimum 8 caractères) et le confirme, **Then** le mot de passe est mis à jour et l'utilisateur est redirigé vers la page de connexion avec un message de succès.
2. **Given** un lien de réinitialisation expiré (plus de 1 heure), **When** l'utilisateur tente de l'utiliser, **Then** un message d'erreur indique que le lien a expiré avec un bouton pour recommencer la procédure.
3. **Given** un lien de réinitialisation déjà utilisé, **When** l'utilisateur tente de l'utiliser à nouveau, **Then** un message d'erreur indique que le lien n'est plus valide.
4. **Given** un utilisateur sur le formulaire de nouveau mot de passe, **When** les deux champs ne correspondent pas, **Then** un message d'erreur côté client empêche la soumission.
5. **Given** un utilisateur connecté sur d'autres appareils, **When** il réinitialise son mot de passe avec succès, **Then** toutes ses sessions existantes sont invalidées et il doit se reconnecter partout.

---

### User Story 3 - Email de réinitialisation clair et professionnel (Priority: P2)

L'email de réinitialisation reçu par l'utilisateur est présenté avec l'identité visuelle de l'Université Senghor, contient des instructions claires, le lien de réinitialisation, et une mention indiquant d'ignorer l'email si la demande n'a pas été initiée par l'utilisateur.

**Why this priority**: L'email est le vecteur principal de la fonctionnalité. Sa clarté et son aspect professionnel renforcent la confiance de l'utilisateur.

**Independent Test**: Peut être testé en déclenchant l'envoi et en vérifiant visuellement le rendu de l'email (sujet, contenu, liens, mise en page).

**Acceptance Scenarios**:

1. **Given** une demande de réinitialisation validée, **When** l'email est envoyé, **Then** il contient : le nom de l'utilisateur, un lien cliquable de réinitialisation, la durée de validité du lien, et une mention de sécurité invitant à ignorer l'email si non sollicité.
2. **Given** un email de réinitialisation, **When** il est affiché dans un client mail, **Then** il utilise le template de base de l'Université Senghor (header avec logo, footer avec coordonnées).

---

### Edge Cases

- Que se passe-t-il si l'utilisateur demande plusieurs réinitialisations consécutives ? Seul le dernier lien envoyé doit être valide ; les précédents sont invalidés.
- Que se passe-t-il si le serveur SMTP est indisponible ? L'utilisateur reçoit un message d'erreur générique l'invitant à réessayer plus tard.
- Que se passe-t-il si l'utilisateur tente de réinitialiser avec un token malformé ou inexistant ? Un message d'erreur clair est affiché sans divulguer d'information technique.
- Que se passe-t-il si l'utilisateur n'a pas de `password_hash` (compte non configuré) ? L'email de réinitialisation est quand même envoyé, permettant à l'utilisateur de définir un mot de passe.

## Clarifications

### Session 2026-03-18

- Q: Après réinitialisation du mot de passe, les sessions existantes (JWT) doivent-elles être invalidées ? → A: Oui, toutes les sessions existantes sont invalidées — l'utilisateur doit se reconnecter partout.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT fournir un formulaire public « Mot de passe oublié » accessible depuis la page de connexion, demandant uniquement l'adresse email.
- **FR-002**: Le système DOIT générer un jeton de réinitialisation unique, sécurisé (cryptographiquement aléatoire) et à usage unique pour chaque demande valide.
- **FR-003**: Le jeton de réinitialisation DOIT expirer après 1 heure.
- **FR-004**: Le système DOIT envoyer un email contenant un lien de réinitialisation à l'adresse email fournie, uniquement si un compte actif et vérifié existe.
- **FR-005**: Le système NE DOIT PAS révéler si une adresse email est associée à un compte existant (réponse identique dans tous les cas).
- **FR-006**: Le système DOIT fournir un formulaire public de saisie de nouveau mot de passe (mot de passe + confirmation), accessible via le lien contenu dans l'email.
- **FR-007**: Le nouveau mot de passe DOIT respecter les règles de validation existantes (minimum 8 caractères).
- **FR-008**: Le système DOIT invalider le jeton après utilisation (usage unique).
- **FR-009**: Le système DOIT invalider tous les jetons de réinitialisation précédents d'un utilisateur lorsqu'un nouveau jeton est généré.
- **FR-010**: L'email de réinitialisation DOIT utiliser le template email existant de l'Université Senghor et être rédigé en français.
- **FR-011**: Le système DOIT rediriger l'utilisateur vers la page de connexion après une réinitialisation réussie, avec un message de confirmation.
- **FR-012**: Le système DOIT limiter le nombre de demandes de réinitialisation à 5 par adresse email par heure pour prévenir les abus.
- **FR-013**: Le système DOIT invalider toutes les sessions existantes (access et refresh tokens) de l'utilisateur après une réinitialisation de mot de passe réussie, forçant une reconnexion sur tous les appareils.

### Key Entities

- **Jeton de réinitialisation (user_tokens)**: Représente un jeton temporaire lié à un utilisateur, avec un type (`password_reset`), une date d'expiration, et un indicateur d'utilisation. La table `user_tokens` existe déjà dans le schéma de la base de données.
- **Utilisateur (users)**: Compte utilisateur avec email, mot de passe hashé, statut actif et statut de vérification email. La table `users` existe déjà.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Un utilisateur peut compléter le processus complet de réinitialisation de mot de passe (demande → email → nouveau mot de passe → connexion) en moins de 5 minutes.
- **SC-002**: L'email de réinitialisation est reçu dans la boîte de réception de l'utilisateur dans un délai de 2 minutes après la demande.
- **SC-003**: 100% des liens de réinitialisation expirés ou déjà utilisés sont correctement rejetés par le système.
- **SC-004**: Aucune information sur l'existence d'un compte n'est divulguée via le formulaire de demande de réinitialisation.
- **SC-005**: Le nombre de demandes de support liées aux mots de passe oubliés diminue significativement après le déploiement.

## Assumptions

- L'infrastructure SMTP est fonctionnelle et configurée (service email existant avec `aiosmtplib` et templates Jinja2).
- La table `user_tokens` avec le type `password_reset` existe déjà en base de données.
- Les schémas Pydantic `ForgotPasswordRequest` et `ResetPasswordRequest` sont déjà définis dans le code backend.
- Le template email de base (`base.html`) est déjà en place et sera réutilisé.
- Le frontend de l'application est accessible via un domaine connu pour construire les liens de réinitialisation.
- La durée de validité du jeton est fixée à 1 heure (standard de l'industrie).
- La limite de fréquence est fixée à 5 demandes par email par heure.
