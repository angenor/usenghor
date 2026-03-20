# Research: 008-survey-campaigns

**Date**: 2026-03-20 | **Branch**: `008-survey-campaigns`

## R1 — SurveyJS Form Library (rendu public)

**Decision**: Utiliser `survey-vue3-ui` (MIT) pour le rendu et la soumission des formulaires côté public.

**Rationale**:
- Package unique : `pnpm add survey-vue3-ui` (inclut `survey-core` en dépendance)
- 21+ types de questions intégrés couvrant tous les besoins FR-002
- Support natif multilingue : titres/textes par locale dans le JSON (`{ "default": "...", "fr": "...", "ar": "..." }`)
- RTL automatique quand `survey.locale = 'ar'`
- Thèmes personnalisables via CSS variables (adaptable brand-blue/brand-red)
- Composant `.client.vue` requis (pas de SSR) — cohérent avec le pattern `ToastUIEditor.client.vue` existant
- `survey.onComplete.add()` retourne un objet JSON plat `{ name: value, ... }`
- Upload fichiers : handler custom via `survey.onUploadFiles.add()` → backend MediaService

**Alternatives considered**:
- Google Forms (rejeté — dépendance externe, pas d'intégration site)
- FormKit / VeeValidate (rejeté — pas de rendu dynamique depuis JSON, pas de builder intégré)
- SurveyJS Creator (rejeté — licence commerciale, l'utilisateur préfère un constructeur sur mesure)

## R2 — Constructeur de formulaires admin (sur mesure)

**Decision**: Interface admin sur mesure qui génère du JSON compatible SurveyJS.

**Rationale**:
- L'admin ajoute/réordonne/configure les questions via une interface Vue dédiée
- Chaque question est un objet avec : `type`, `name`, `title` (trilingue), `isRequired`, `choices` (si applicable), `validators`
- L'interface stocke un tableau d'objets questions, transformé en JSON SurveyJS au moment de la sauvegarde
- Le JSON SurveyJS est stocké tel quel en base (colonne JSONB) et envoyé directement au composant `SurveyComponent`
- Réordonnement via drag & drop (sortable.js ou implémentation manuelle)

**Alternatives considered**:
- SurveyJS Creator (rejeté — coût de licence, dépendance lourde)
- Édition JSON brut (rejeté — pas ergonomique pour les gestionnaires non-techniques)

## R3 — Modèle de permissions

**Decision**: Permission dédiée `survey.manage` dans le système existant (tables `permissions`, `role_permissions`).

**Rationale**:
- Suit le pattern existant : `{resource}.{action}` (ex. `media.view`, `organization.edit`)
- `PermissionChecker("survey.manage")` en dépendance FastAPI sur tous les endpoints admin survey
- `User.has_permission("survey.manage")` retourne `True` pour tout rôle ayant cette permission + super_admin (bypass intégré)
- Filtrage par `created_by` dans les requêtes : chaque gestionnaire ne voit que ses campagnes
- Super_admin : pas de filtre `created_by`, voit tout

**Alternatives considered**:
- Permissions multiples survey.create/survey.view/survey.delete (rejeté — surcharge pour un premier MVP, une seule permission suffit)

## R4 — Anti-spam

**Decision**: Rate limiting côté serveur + champ honeypot.

**Rationale**:
- Rate limiting : middleware ou décorateur sur l'endpoint de soumission (max 5/IP/heure configurable)
- Honeypot : champ caché ajouté au formulaire public, rejet silencieux si rempli
- Pas de dépendance externe (pas de CAPTCHA)
- Transparent pour l'utilisateur légitime

**Alternatives considered**:
- reCAPTCHA/hCaptcha (rejeté — friction UX, dépendance Google/externe)
- CAPTCHA seul sans rate limiting (rejeté — insuffisant contre bots sophistiqués)

## R5 — Email de confirmation

**Decision**: Réutiliser `EmailService` existant avec un nouveau template Jinja2 `survey_confirmation.html`.

**Rationale**:
- Infrastructure SMTP déjà en place (feature 006-password-reset-email)
- `EmailService.send_email(to=email, template_name="survey_confirmation", context={...})`
- Template hérite de `base.html` existant
- Activé/désactivé par campagne (champ `confirmation_email_enabled` sur `survey_campaigns`)
- Le champ email du formulaire est identifié par convention : question avec `name = "email"` ou `inputType = "email"`

**Alternatives considered**:
- Service email externe (rejeté — infrastructure SMTP déjà opérationnelle)

## R6 — Stockage des réponses

**Decision**: Colonne JSONB pour les données de réponse, avec métadonnées en colonnes classiques.

**Rationale**:
- Les réponses SurveyJS sont un objet JSON plat `{ questionName: value, ... }`
- Stocker dans une colonne `response_data JSONB` permet de gérer des formulaires de structures variables
- Métadonnées en colonnes dédiées : `submitted_at`, `ip_address`, `session_id`, `campaign_id`
- JSONB supporte les index GIN pour les requêtes agrégées (statistiques)
- Export CSV : extraction des clés du JSON + aplatissement en colonnes

**Alternatives considered**:
- EAV (Entity-Attribute-Value) avec une ligne par réponse par question (rejeté — complexité, performances)
- Colonnes dynamiques (rejeté — impossible avec des formulaires de structure variable)

## R7 — Visualisation des statistiques

**Decision**: Calcul des statistiques côté backend, rendu des graphiques côté frontend.

**Rationale**:
- Backend : endpoint dédié qui agrège les réponses JSONB (compteurs, pourcentages par question à choix)
- Frontend : librairie de graphiques légère (Chart.js ou ApexCharts) pour les camemberts/barres
- Pas besoin d'une solution BI complète — les statistiques sont simples (comptage, répartition)
- Tableau des réponses individuelles : pagination serveur standard (pattern `paginate()` existant)

**Alternatives considered**:
- Calcul côté frontend (rejeté — pas scalable avec >1000 réponses)
- Google Charts (rejeté — dépendance externe, objectif = indépendance Google)
