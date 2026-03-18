# Research: 006-password-reset-email

**Date**: 2026-03-18

## Decision 1: Mécanisme d'invalidation des sessions JWT

**Decision**: Ajouter une colonne `password_changed_at` (TIMESTAMPTZ) à la table `users`. Lors de la validation du JWT, comparer le `iat` (issued at) du token avec `password_changed_at` : si le token a été émis avant le changement de mot de passe, le rejeter.

**Rationale**: Le système utilise des JWT stateless (pas de table de sessions). Un mécanisme de blacklist serait complexe et contraire au design stateless. Le champ `password_changed_at` est simple, ne nécessite aucune table supplémentaire, et n'impacte pas les performances (une seule comparaison de timestamp lors du décodage).

**Alternatives considered**:
- Table de blacklist de tokens : complexe, nécessite un nettoyage périodique, contre le design stateless
- Version de session dans le JWT : nécessite un compteur en BDD, similaire en complexité mais moins explicite
- Réduire la durée de vie des access tokens : ne résout pas le problème immédiatement

## Decision 2: Construction de l'URL de réinitialisation

**Decision**: Ajouter une variable `FRONTEND_URL` dans la configuration backend (`config.py`), avec valeur par défaut `http://localhost:3000`. L'URL du lien sera `{FRONTEND_URL}/admin/reset-password?token={token}`.

**Rationale**: Le backend doit construire l'URL complète pour l'email. Il ne peut pas utiliser de chemin relatif. La variable d'environnement permet de différencier local et production sans modifier le code.

**Alternatives considered**:
- URL relative dans l'email : impossible, les clients email ne résolvent pas les chemins relatifs
- URL codée en dur : non maintenable entre environnements

## Decision 3: Génération du token de réinitialisation

**Decision**: Utiliser `secrets.token_urlsafe(32)` pour générer un token de 43 caractères URL-safe. Le token est stocké en clair dans `user_tokens` (pas de hash).

**Rationale**: `secrets.token_urlsafe(32)` produit 256 bits d'entropie, suffisant pour un token à usage unique avec expiration de 1 heure. Le stockage en clair est acceptable car le token expire rapidement et est à usage unique (contrairement à un mot de passe qui persiste).

**Alternatives considered**:
- Hasher le token en BDD (comme un mot de passe) : overhead inutile pour un token éphémère
- UUID v4 : 122 bits d'entropie seulement, moins sécurisé
- JWT signé comme token : over-engineering, le token n'a pas besoin de contenir de données

## Decision 4: Rate limiting des demandes

**Decision**: Implémenter un rate limiting simple côté service en comptant les tokens `password_reset` non expirés créés dans la dernière heure pour un email donné. Si >= 5, rejeter silencieusement (même réponse que le succès pour ne pas divulguer d'information).

**Rationale**: Pas besoin d'un middleware de rate limiting global (comme slowapi) pour cette seule fonctionnalité. Le comptage en BDD est simple et suffisant pour le volume attendu.

**Alternatives considered**:
- Middleware slowapi/ratelimit : over-engineering pour un seul endpoint
- Rate limiting par IP : contournable et peut bloquer des utilisateurs légitimes derrière un NAT
- Redis-based rate limiting : ajoute une dépendance, non justifié pour le volume

## Decision 5: Positionnement des pages frontend

**Decision**: Créer les pages dans `app/pages/admin/` :
- `forgot-password.vue` — formulaire de demande
- `reset-password.vue` — formulaire de nouveau mot de passe (token en query param `?token=xxx`)

**Rationale**: Le flux de réinitialisation est lié à l'authentification admin. Les pages restent dans le même répertoire que `login.vue` pour la cohérence. Le token est passé en query param plutôt qu'en paramètre de route pour simplifier le routage (pas besoin d'un dossier `reset-password/[token].vue`).

**Alternatives considered**:
- Pages dans `app/pages/auth/` : ce répertoire n'existe pas, ajouterait de la fragmentation
- Token dans le path (`/reset-password/[token]`) : fonctionne mais les query params sont plus standards pour les liens email

## Decision 6: Envoi d'email asynchrone vs synchrone

**Decision**: Envoyer l'email de manière synchrone dans le handler de la requête (await). Si l'envoi échoue, logger l'erreur et retourner quand même un message de succès (pour ne pas divulguer d'information).

**Rationale**: Le service email existant (`EmailService.send_email`) est déjà asynchrone avec `aiosmtplib`. L'envoi prend typiquement < 2 secondes. Un système de queue (Celery, etc.) serait over-engineering pour le volume attendu.

**Alternatives considered**:
- Background task FastAPI : pourrait fonctionner mais complique la gestion d'erreur
- File d'attente (Celery/Redis) : infrastructure supplémentaire non justifiée
