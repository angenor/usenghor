# Feature Specification: Campagnes de sondages et formulaires

**Feature Branch**: `008-survey-campaigns`
**Created**: 2026-03-20
**Status**: Draft
**Input**: User description: "Système de campagnes de sondages/formulaires intégré pour remplacer Google Forms, avec visualisation des données collectées, et possibilité d'associer les campagnes à d'autres éléments du site (événements, appels à candidature, recrutement, etc.). Utilisation de SurveyJS comme librairie de formulaires."

## Clarifications

### Session 2026-03-20

- Q: Construction de formulaires — SurveyJS Creator (licence commerciale, drag & drop) ou interface sur mesure ? → A: Interface de construction sur mesure côté admin. SurveyJS Form Library (gratuit, MIT) uniquement pour le rendu et la soumission côté public.
- Q: Protection anti-spam sur les formulaires publics anonymes ? → A: Double couche : rate limiting côté serveur + champ honeypot invisible. En complément, option configurable par campagne pour envoyer un email de confirmation au répondant après soumission (nécessite un champ email dans le formulaire).
- Q: Qui peut gérer les campagnes ? → A: Tout utilisateur (pas uniquement les admins) possédant la permission dédiée "survey_manage" peut créer et gérer les campagnes. Les super_admins ont accès total par défaut.
- Q: Associations campagne-élément du site : exclusives ou multiples ? → A: Associations multiples. Une même campagne peut être liée à plusieurs éléments simultanément (ex. : même formulaire d'évaluation sur 3 événements).
- Q: Visibilité des campagnes entre gestionnaires ? → A: Chaque gestionnaire ne voit et ne gère que ses propres campagnes. Les super_admins voient et gèrent toutes les campagnes.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Créer et publier un formulaire (Priority: P1)

Un utilisateur disposant de la permission "survey_manage" souhaite créer un formulaire pour collecter des informations auprès du public (ex. : inscription à un événement, enquête de satisfaction, collecte de candidatures). Il accède à l'interface de gestion des campagnes, crée une nouvelle campagne, conçoit le formulaire via une interface sur mesure permettant d'ajouter, réordonner et configurer les questions (texte, choix multiples, listes déroulantes, dates, fichiers, etc.), puis le publie pour le rendre accessible au public via un lien dédié. Le formulaire public est rendu via SurveyJS Form Library à partir du JSON généré par l'interface de gestion.

**Why this priority**: Sans la possibilité de créer et publier un formulaire, aucune autre fonctionnalité n'a de raison d'être. C'est le socle minimal de la feature.

**Independent Test**: Peut être testé en créant un formulaire complet, en le publiant, et en vérifiant qu'il est accessible via son lien public.

**Acceptance Scenarios**:

1. **Given** un utilisateur connecté avec la permission "survey_manage", **When** il clique sur "Nouvelle campagne" et conçoit un formulaire avec au moins 3 types de questions différents, **Then** le formulaire est sauvegardé en brouillon.
2. **Given** un formulaire en brouillon, **When** l'utilisateur le publie, **Then** un lien public unique est généré et le formulaire est accessible aux répondants.
3. **Given** un formulaire publié, **When** l'utilisateur le met en pause, **Then** le lien public affiche un message indiquant que le formulaire n'est plus disponible.
4. **Given** un utilisateur connecté sans la permission "survey_manage", **When** il tente d'accéder à la gestion des campagnes, **Then** l'accès est refusé.
5. **Given** un super_admin, **When** il accède à la gestion des campagnes, **Then** il a accès à toutes les fonctionnalités sans restriction.

---

### User Story 2 - Répondre à un formulaire (Priority: P1)

Un membre du public accède à un formulaire publié via un lien partagé (email, site web, réseaux sociaux). Il remplit les champs, soumet ses réponses, et reçoit une confirmation de soumission à l'écran. Si le gestionnaire a activé l'option d'email de confirmation et que le formulaire contient un champ email, le répondant reçoit également un email confirmant la bonne réception de sa soumission.

**Why this priority**: Sans répondants, la collecte de données est impossible. Cette story est indissociable de la première.

**Independent Test**: Peut être testé en accédant au lien public d'un formulaire, en remplissant toutes les questions, et en vérifiant la confirmation de soumission (écran + email si activé).

**Acceptance Scenarios**:

1. **Given** un formulaire publié, **When** un visiteur accède au lien public, **Then** le formulaire s'affiche avec toutes les questions dans l'ordre défini.
2. **Given** un formulaire affiché, **When** le visiteur remplit les champs obligatoires et soumet le formulaire, **Then** une confirmation de soumission s'affiche et les réponses sont enregistrées.
3. **Given** un formulaire avec des champs obligatoires, **When** le visiteur tente de soumettre sans remplir un champ obligatoire, **Then** un message d'erreur clair indique les champs manquants.
4. **Given** un formulaire soumis, **When** le visiteur tente de soumettre à nouveau, **Then** le système empêche le doublon (une seule soumission par session par défaut).
5. **Given** une campagne avec l'option "email de confirmation" activée et un champ email dans le formulaire, **When** le visiteur soumet le formulaire, **Then** un email de confirmation est envoyé à l'adresse saisie.

---

### User Story 3 - Consulter et analyser les réponses (Priority: P2)

Un utilisateur avec la permission "survey_manage" souhaite visualiser les réponses collectées par une campagne. Il accède au tableau de bord de la campagne et voit un résumé statistique (nombre de réponses, graphiques de répartition pour les questions à choix, moyennes, etc.) ainsi qu'un tableau détaillé des réponses individuelles.

**Why this priority**: La visualisation des données est le principal moteur de remplacement de Google Forms. Sans elle, le gestionnaire ne peut pas exploiter les réponses collectées.

**Independent Test**: Peut être testé en vérifiant qu'après plusieurs soumissions, les statistiques et graphiques reflètent fidèlement les données collectées.

**Acceptance Scenarios**:

1. **Given** une campagne avec au moins 10 réponses, **When** le gestionnaire accède au tableau de bord de la campagne, **Then** il voit le nombre total de réponses, la date de la dernière réponse et des graphiques de répartition pour les questions à choix.
2. **Given** le tableau de bord d'une campagne, **When** le gestionnaire bascule en vue "Réponses individuelles", **Then** il voit un tableau avec toutes les réponses, filtrable et triable par colonne.
3. **Given** le tableau de bord d'une campagne, **When** le gestionnaire clique sur "Exporter", **Then** les réponses sont téléchargées au format CSV.

---

### User Story 4 - Gérer le cycle de vie d'une campagne (Priority: P2)

Un utilisateur avec la permission "survey_manage" gère ses campagnes : il peut voir la liste de toutes les campagnes, les modifier, les clôturer, les dupliquer, ou les supprimer. Chaque campagne a un statut clair (brouillon, active, en pause, clôturée).

**Why this priority**: La gestion des campagnes est essentielle pour un usage récurrent dans le temps, mais n'est pas bloquante pour un premier usage.

**Independent Test**: Peut être testé en créant plusieurs campagnes et en vérifiant que les transitions de statut fonctionnent correctement.

**Acceptance Scenarios**:

1. **Given** un utilisateur avec la permission "survey_manage", **When** il accède à la liste des campagnes, **Then** il voit uniquement ses propres campagnes avec leur statut, nombre de réponses et date de création.
2. **Given** une campagne active, **When** le gestionnaire la clôture, **Then** le formulaire public affiche "Ce formulaire est clôturé" et aucune nouvelle réponse n'est acceptée.
3. **Given** une campagne existante, **When** le gestionnaire la duplique, **Then** une nouvelle campagne est créée en brouillon avec la même structure de formulaire mais sans réponses.

---

### User Story 5 - Associer une campagne à un élément du site (Priority: P3)

Un utilisateur avec la permission "survey_manage" souhaite lier une campagne à un événement, un appel à candidature ou un programme existant sur le site. Cette association permet d'afficher le formulaire directement sur la page concernée et de contextualiser les réponses.

**Why this priority**: Cette fonctionnalité enrichit considérablement l'usage mais n'est pas requise pour un MVP fonctionnel. Elle sera conçue de manière extensible pour accueillir de futurs types d'associations.

**Independent Test**: Peut être testé en associant une campagne à un événement, puis en vérifiant que le formulaire apparaît sur la page de l'événement.

**Acceptance Scenarios**:

1. **Given** une campagne active, **When** le gestionnaire l'associe à un événement existant, **Then** le formulaire est affiché dans la page publique de cet événement.
2. **Given** une campagne associée à un événement, **When** le gestionnaire retire l'association, **Then** le formulaire disparaît de la page de l'événement mais reste accessible via son lien direct.
3. **Given** une campagne, **When** le gestionnaire choisit le type d'élément à associer, **Then** il peut choisir parmi : événement, appel à candidature, programme.

---

### Edge Cases

- Que se passe-t-il si un formulaire est modifié alors que des réponses existent déjà ? Les réponses existantes sont conservées intactes ; les nouvelles soumissions utilisent la version mise à jour du formulaire.
- Que se passe-t-il si un gestionnaire supprime une campagne avec des réponses ? Une confirmation explicite est demandée, précisant que les réponses seront également supprimées.
- Comment le système gère-t-il un grand nombre de réponses (>1000) ? La visualisation des réponses individuelles utilise la pagination ; les statistiques restent performantes.
- Que se passe-t-il si un visiteur perd sa connexion en cours de remplissage ? Les réponses partielles ne sont pas enregistrées ; le visiteur peut reprendre depuis le début.
- Comment le formulaire gère-t-il le support multilingue (FR/EN/AR) ? Les libellés des questions et du formulaire sont configurables dans les trois langues. L'affichage public s'adapte à la langue active du site.
- Que se passe-t-il si un bot tente des soumissions massives ? Le rate limiting bloque les soumissions excessives par IP ; le champ honeypot rejette silencieusement les soumissions automatisées.
- Que se passe-t-il si l'email de confirmation est activé mais le formulaire ne contient pas de champ email ? L'option est ignorée ; aucun email n'est envoyé et la soumission est traitée normalement.
- Que se passe-t-il si la permission "survey_manage" est retirée à un utilisateur qui a des campagnes actives ? Les campagnes restent actives et continuent de collecter des réponses, mais l'utilisateur ne peut plus les gérer. Un super_admin peut reprendre la gestion.
- Un gestionnaire peut-il voir ou modifier les campagnes d'un autre gestionnaire ? Non. Chaque gestionnaire n'a accès qu'à ses propres campagnes. Seuls les super_admins ont une vue globale sur toutes les campagnes.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT permettre aux utilisateurs disposant de la permission "survey_manage" de créer des campagnes avec un titre, une description et un formulaire personnalisable. Les super_admins ont accès total par défaut.
- **FR-002**: Le constructeur de formulaires sur mesure DOIT proposer au minimum les types de questions suivants : texte court, texte long, choix unique, choix multiples, liste déroulante, date, échelle de notation, envoi de fichier. Le gestionnaire ajoute, réordonne et configure les questions via une interface dédiée ; le système génère le JSON compatible SurveyJS Form Library.
- **FR-003**: Le système DOIT générer un lien public unique pour chaque campagne publiée.
- **FR-004**: Le système DOIT enregistrer chaque soumission avec horodatage et métadonnées de session (à des fins de dédoublonnage).
- **FR-005**: Le système DOIT fournir un tableau de bord avec des statistiques agrégées (compteurs, répartition en pourcentage, graphiques) pour chaque campagne.
- **FR-006**: Le système DOIT permettre l'export des réponses au format CSV.
- **FR-007**: Chaque campagne DOIT avoir un cycle de vie avec les statuts : brouillon, active, en pause, clôturée.
- **FR-008**: Le système DOIT permettre de dupliquer une campagne existante (structure du formulaire uniquement, sans les réponses).
- **FR-009**: Le système DOIT supporter les champs trilingues (FR, EN, AR) pour les titres, descriptions et libellés des questions.
- **FR-010**: Le système DOIT permettre d'associer une campagne à un élément du site (événement, appel à candidature, programme) de manière générique et extensible.
- **FR-011**: Le système DOIT valider les champs obligatoires côté client et côté serveur avant d'enregistrer une soumission.
- **FR-012**: Le système DOIT empêcher les soumissions sur les campagnes en pause ou clôturées.
- **FR-013**: Le système DOIT supporter la pagination pour la liste des réponses individuelles.
- **FR-014**: Le système DOIT permettre de configurer une date de clôture automatique pour une campagne.
- **FR-015**: Le système DOIT protéger les formulaires publics contre le spam via un rate limiting côté serveur et un champ honeypot invisible.
- **FR-016**: Le système DOIT permettre au gestionnaire d'activer/désactiver l'envoi d'un email de confirmation au répondant pour chaque campagne. Si activé et qu'un champ email est présent dans le formulaire, un email de confirmation est envoyé après soumission.
- **FR-017**: L'accès à la gestion des campagnes DOIT être contrôlé par la permission "survey_manage". Tout utilisateur authentifié possédant cette permission peut créer, modifier, supprimer et consulter ses propres campagnes et leurs réponses. Les super_admins voient et gèrent toutes les campagnes.
- **FR-018**: Chaque gestionnaire DOIT ne voir que ses propres campagnes dans la liste. Les super_admins voient l'ensemble des campagnes de tous les gestionnaires.

### Key Entities

- **Campagne (Survey Campaign)** : Représente un formulaire avec son contexte (titre, description, statut, dates, options de configuration dont l'email de confirmation). Appartient à un utilisateur créateur. Peut être associée à zéro ou plusieurs éléments du site.
- **Définition du formulaire (Survey Definition)** : La structure du formulaire (questions, types, validations, traductions) au format JSON compatible SurveyJS. Générée par l'interface de gestion sur mesure, rendue par SurveyJS Form Library côté public.
- **Réponse (Survey Response)** : Une soumission individuelle liée à une campagne, contenant les données saisies par le répondant, un horodatage et des métadonnées.
- **Association (Survey Association)** : Le lien entre une campagne et un élément du site (type d'entité + identifiant de l'entité cible).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Un gestionnaire peut créer, configurer et publier un formulaire complet en moins de 10 minutes.
- **SC-002**: Un répondant peut remplir et soumettre un formulaire de 15 questions en moins de 5 minutes.
- **SC-003**: Les statistiques d'une campagne de 500 réponses s'affichent en moins de 3 secondes.
- **SC-004**: 100% des campagnes créées via la plateforme remplacent le besoin de créer un Google Forms équivalent.
- **SC-005**: L'export CSV d'une campagne de 1000 réponses se génère en moins de 10 secondes.
- **SC-006**: Le formulaire public s'affiche correctement dans les trois langues du site (FR, EN, AR) avec support RTL.
- **SC-007**: Les soumissions automatisées (bots) sont bloquées sans impact sur l'expérience des répondants légitimes.

## Assumptions

- SurveyJS Form Library (MIT, gratuit) sera utilisée uniquement pour le rendu et la soumission des formulaires côté public. Le constructeur de formulaires côté gestion sera une interface sur mesure développée en interne.
- Les formulaires sont anonymes par défaut (pas d'authentification requise pour répondre).
- Une campagne peut exister indépendamment de toute association avec un élément du site.
- La structure du formulaire est stockée au format JSON compatible SurveyJS, ce qui permet une évolution future sans migration de schéma.
- L'envoi de fichiers dans les réponses est limité en taille (ex. : 10 Mo par fichier) pour des raisons de stockage.
- Le dédoublonnage se fait par session/navigateur, pas par authentification (les formulaires étant anonymes).
- L'envoi d'emails de confirmation utilise l'infrastructure SMTP déjà en place dans le projet (feature 006-password-reset-email).
- La permission "survey_manage" s'intègre dans le système de rôles/permissions existant (tables `roles`, `permissions`).
