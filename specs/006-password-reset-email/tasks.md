# Tasks: Réinitialisation de mot de passe par email

**Input**: Design documents from `/specs/006-password-reset-email/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Non demandés — pas de tâches de tests automatisés.

**Organization**: Tasks groupées par user story pour une implémentation et validation indépendantes.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut être exécuté en parallèle (fichiers différents, pas de dépendances)
- **[Story]**: User story associée (US1, US2, US3)
- Chemins exacts inclus dans les descriptions

---

## Phase 1: Setup (Infrastructure partagée)

**Purpose**: Migration BDD et configuration backend nécessaires à toutes les user stories

- [x] T001 Créer le fichier de migration SQL `usenghor_backend/documentation/modele_de_données/migrations/007_password_changed_at.sql` — `ALTER TABLE users ADD COLUMN password_changed_at TIMESTAMPTZ;`
- [x] T002 [P] Mettre à jour le schéma de référence dans `usenghor_backend/documentation/modele_de_données/services/02_identity.sql` — ajouter la colonne `password_changed_at` à la table `users`
- [x] T003 [P] Ajouter `frontend_url: str = "http://localhost:3000"` dans `usenghor_backend/app/config.py` et `FRONTEND_URL` dans `usenghor_backend/.env.example`
- [x] T004 Appliquer la migration sur la BDD locale : `docker exec -i usenghor_postgres psql -U usenghor -d usenghor < usenghor_backend/documentation/modele_de_données/migrations/007_password_changed_at.sql`

---

## Phase 2: Foundational (Prérequis bloquants)

**Purpose**: Modèle, schéma et service partagés par toutes les user stories — DOIT être terminé avant les phases suivantes

**⚠️ CRITICAL**: Aucun travail sur les user stories ne peut commencer avant la fin de cette phase

- [x] T005 Ajouter le champ `password_changed_at` au modèle SQLAlchemy `User` dans `usenghor_backend/app/models/identity.py` — `password_changed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)`
- [x] T006 [P] Ajouter le schéma `VerifyResetTokenResponse` dans `usenghor_backend/app/schemas/identity.py` — champs: `valid: bool`, `user_first_name: str | None = None`, `reason: str | None = None`
- [x] T007 Implémenter 3 méthodes dans `usenghor_backend/app/services/identity_service.py` : `create_reset_token(email)` (génère token via `secrets.token_urlsafe(32)`, invalide tokens précédents, vérifie rate limit 5/h, retourne token ou None), `validate_reset_token(token)` (vérifie existence, expiration, usage, retourne UserToken ou None avec raison), `reset_password_with_token(token, new_password)` (valide token, hash mot de passe, met à jour `password_hash` et `password_changed_at`, marque token `used=True`)
- [x] T008 Modifier `get_current_user()` dans `usenghor_backend/app/core/dependencies.py` pour vérifier `password_changed_at` : si `user.password_changed_at` existe et que le `iat` du JWT est antérieur, rejeter le token avec 401

**Checkpoint**: Fondation prête — l'implémentation des user stories peut commencer

---

## Phase 3: User Story 1 — Demander la réinitialisation de mot de passe (Priority: P1) 🎯 MVP

**Goal**: Un utilisateur peut saisir son email dans un formulaire « Mot de passe oublié » et recevoir un email contenant un lien de réinitialisation sécurisé.

**Independent Test**: Saisir une adresse email valide dans le formulaire, vérifier la réception de l'email avec lien fonctionnel. Saisir une adresse inexistante et vérifier que le même message est affiché.

### Implementation for User Story 1

- [x] T009 [US1] Implémenter l'endpoint `POST /api/auth/forgot-password` dans `usenghor_backend/app/routers/auth.py` — accepte `ForgotPasswordRequest`, appelle `identity_service.create_reset_token(email)`, envoie l'email si token créé, retourne toujours `MessageResponse` identique (FR-005). Placer la route AVANT les routes dynamiques existantes.
- [x] T010 [US1] Créer la page `usenghor_nuxt/app/pages/admin/forgot-password.vue` — formulaire avec champ email, bouton submit, message de confirmation après soumission. Réutiliser le style de `login.vue` (rounded-xl, brand-blue-500, bg-white/95, dark mode). Appel `$fetch('/api/auth/forgot-password', { method: 'POST', body: { email } })`.
- [x] T011 [US1] Ajouter le lien « Mot de passe oublié ? » dans `usenghor_nuxt/app/pages/admin/login.vue` — `<NuxtLink to="/admin/forgot-password">` positionné entre le champ mot de passe et le bouton de connexion, style `text-sm text-brand-blue-500 hover:text-brand-blue-600`.

**Checkpoint**: US1 fonctionnel — un utilisateur peut demander une réinitialisation et recevoir l'email

---

## Phase 4: User Story 2 — Définir un nouveau mot de passe via le lien reçu (Priority: P1)

**Goal**: L'utilisateur clique sur le lien reçu par email, saisit un nouveau mot de passe, et peut se reconnecter. Les sessions existantes sont invalidées.

**Independent Test**: Cliquer sur un lien de réinitialisation valide, saisir un nouveau mot de passe, vérifier la connexion avec le nouveau mot de passe. Tester avec un lien expiré et un lien déjà utilisé.

### Implementation for User Story 2

- [x] T012 [US2] Implémenter l'endpoint `GET /api/auth/verify-reset-token` dans `usenghor_backend/app/routers/auth.py` — accepte query param `token`, appelle `identity_service.validate_reset_token(token)`, retourne `VerifyResetTokenResponse` avec `valid`, `user_first_name`, `reason`
- [x] T013 [US2] Implémenter l'endpoint `POST /api/auth/reset-password` dans `usenghor_backend/app/routers/auth.py` — accepte `ResetPasswordRequest`, appelle `identity_service.reset_password_with_token(token, new_password)`, retourne `MessageResponse` en cas de succès ou 400 si token invalide
- [x] T014 [US2] Créer la page `usenghor_nuxt/app/pages/admin/reset-password.vue` — extraire le token depuis `useRoute().query.token`, appeler `verify-reset-token` au chargement pour afficher le bon état (formulaire / lien expiré / lien invalide). Formulaire: 2 champs mot de passe (nouveau + confirmation), validation côté client (min 8 chars, correspondance), appel `$fetch('/api/auth/reset-password')`. Après succès, rediriger vers `/admin/login` avec message flash. Style cohérent avec `login.vue` et `forgot-password.vue`.

**Checkpoint**: US1 + US2 fonctionnels — le flux complet de réinitialisation fonctionne de bout en bout

---

## Phase 5: User Story 3 — Email de réinitialisation clair et professionnel (Priority: P2)

**Goal**: L'email envoyé utilise l'identité visuelle de l'Université Senghor et contient toutes les informations nécessaires.

**Independent Test**: Déclencher l'envoi d'un email de réinitialisation et vérifier visuellement le rendu (sujet, nom utilisateur, lien, durée de validité, mention sécurité, header/footer Senghor).

### Implementation for User Story 3

- [x] T015 [US3] Créer le template email `usenghor_backend/app/templates/email/password_reset.html` — extends `base.html`, block `content` avec : salutation personnalisée (`Bonjour {{ user_first_name }}`), explication de la demande, bouton/lien de réinitialisation (`{{ reset_url }}`), durée de validité (1 heure), mention sécurité (« Si vous n'avez pas demandé... »). Style du bouton: inline CSS, couleur brand-blue (#1e3a5f), padding, border-radius.
- [x] T016 [US3] Brancher l'envoi d'email dans l'endpoint `forgot-password` (T009) si ce n'est pas déjà fait — appeler `EmailService.send_email(to=user.email, subject="Réinitialisation de votre mot de passe — Université Senghor", template_name="password_reset", context={"user_first_name": user.first_name, "reset_url": f"{settings.frontend_url}/admin/reset-password?token={token}"})` dans `usenghor_backend/app/routers/auth.py`

**Checkpoint**: Toutes les user stories sont fonctionnelles — email professionnel envoyé avec l'identité visuelle

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Améliorations transversales et validation finale

- [x] T017 [P] Mettre à jour `usenghor_backend/.env.example` avec `FRONTEND_URL=https://usenghor-francophonie.org` en commentaire pour la production
- [x] T018 Validation end-to-end complète selon `quickstart.md` : demande de réinitialisation → réception email → clic lien → nouveau mot de passe → connexion → vérification invalidation sessions
- [x] T019 [P] Mettre à jour le schéma SQL de référence `usenghor_backend/documentation/modele_de_données/services/02_identity.sql` si non fait en T002

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Pas de dépendances — peut commencer immédiatement
- **Foundational (Phase 2)**: Dépend de Phase 1 (migration appliquée) — BLOQUE toutes les user stories
- **US1 (Phase 3)**: Dépend de Phase 2 — peut commencer dès que le service est prêt
- **US2 (Phase 4)**: Dépend de Phase 2 — peut commencer en parallèle avec US1 (fichiers différents côté frontend)
- **US3 (Phase 5)**: Dépend de Phase 2 — peut commencer en parallèle (template email indépendant)
- **Polish (Phase 6)**: Dépend de toutes les user stories complétées

### User Story Dependencies

- **US1 (P1)**: Après Phase 2 — indépendant des autres stories
- **US2 (P1)**: Après Phase 2 — le frontend dépend de l'endpoint `reset-password` (T013) mais les endpoints backend peuvent être créés en parallèle avec US1
- **US3 (P2)**: Après Phase 2 — le template email est indépendant, mais le branchement (T016) dépend de T009

### Within Each User Story

- Endpoints backend avant pages frontend (le frontend appelle les API)
- Service avant endpoints (les endpoints appellent le service)
- Template email avant branchement de l'envoi

### Parallel Opportunities

- T002 et T003 peuvent être exécutés en parallèle (fichiers différents)
- T005 et T006 peuvent être exécutés en parallèle (modèle vs schéma)
- Les endpoints backend US1 (T009) et US2 (T012, T013) peuvent être créés en une seule passe dans le même fichier
- Les pages frontend US1 (T010) et US2 (T014) peuvent être créées en parallèle (fichiers différents)
- T015 (template email) peut être créé en parallèle avec les pages frontend

---

## Parallel Example: Phase 2

```bash
# Lancer en parallèle après T004 :
Task T005: "Ajouter password_changed_at au modèle User dans identity.py"
Task T006: "Ajouter VerifyResetTokenResponse dans schemas/identity.py"

# Puis séquentiellement :
Task T007: "Implémenter les 3 méthodes du service (dépend de T005, T006)"
Task T008: "Modifier get_current_user pour vérifier password_changed_at (dépend de T005)"
```

## Parallel Example: Frontend Pages

```bash
# Après les endpoints backend (T009, T012, T013) :
Task T010: "Créer forgot-password.vue"
Task T014: "Créer reset-password.vue"
Task T015: "Créer le template email password_reset.html"
# Ces 3 tâches sont parallélisables (fichiers différents)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Compléter Phase 1: Setup (migration + config)
2. Compléter Phase 2: Foundational (modèle, schéma, service, sécurité JWT)
3. Compléter Phase 3: US1 (endpoint forgot-password + page frontend + lien login)
4. **STOP et VALIDER** : tester la demande de réinitialisation et la réception de l'email
5. Démontrer si prêt

### Incremental Delivery

1. Setup + Foundational → Fondation prête
2. Ajouter US1 → Tester → Démontrer (MVP: demande + email)
3. Ajouter US2 → Tester → Démontrer (flux complet: reset + reconnexion)
4. Ajouter US3 → Tester → Démontrer (email professionnel)
5. Polish → Validation end-to-end finale

---

## Notes

- [P] = fichiers différents, pas de dépendances
- [Story] = traçabilité vers la user story
- Chaque user story est testable indépendamment
- Commit après chaque tâche ou groupe logique
- Le fichier `auth.py` est modifié par T009, T012, T013 — les exécuter séquentiellement ou en une seule passe
- Le service `identity_service.py` est modifié principalement par T007 — une seule tâche pour les 3 méthodes
