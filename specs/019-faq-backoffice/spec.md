# Feature Specification: Page FAQ managée dans le backoffice

**Feature Branch**: `019-faq-backoffice`
**Created**: 2026-05-02
**Status**: Draft
**Input**: User description: "Nous voulons un page FAQ managée dans le backoffice sur cette plateforme"

## Clarifications

### Session 2026-05-02

- Q: Qui peut gérer la FAQ en backoffice ? → A: Réutiliser la permission de gestion de contenu existante (mêmes éditeurs que news/events).
- Q: Recherche côté client ou côté serveur ? → A: Côté client sur la liste publiée chargée en une seule requête.
- Q: Balisage SEO structuré pour la FAQ ? → A: Oui, JSON-LD `schema.org/FAQPage` injecté côté serveur (SSR) pour toutes les langues publiées.
- Q: Lien profond vers une question précise ? → A: Ancres `#slug` sur la page unique `/faq` avec auto-scroll et ouverture de la question ciblée.
- Q: Traduction manquante : faut-il un indicateur visuel ? → A: Non, repli silencieux vers la version française sans mention.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Consultation publique de la FAQ trilingue (Priority: P1)

Un visiteur du site (étudiant, candidat, partenaire, journaliste) accède à la page FAQ publique pour trouver rapidement des réponses aux questions courantes sur l'Université Senghor (admissions, programmes, vie étudiante, partenariats, etc.). Il peut parcourir les questions par catégorie, chercher par mots-clés, et lire les questions/réponses dans la langue de son choix (français, anglais, arabe avec affichage RTL).

**Why this priority**: La FAQ publique est l'objectif principal de la fonctionnalité — elle réduit la charge de support et améliore l'expérience visiteur. Sans elle, la gestion en backoffice n'a aucune valeur.

**Independent Test**: Peupler une FAQ avec quelques entrées via les données initiales, naviguer sur `/faq`, vérifier que les questions/catégories s'affichent dans les trois langues et que la recherche/le filtre par catégorie fonctionnent.

**Acceptance Scenarios**:

1. **Given** une FAQ contenant au moins 5 questions publiées dans 2 catégories, **When** un visiteur ouvre la page FAQ publique, **Then** il voit la liste des catégories et peut déplier chaque question pour lire la réponse formatée (texte riche).
2. **Given** un visiteur sur la page FAQ, **When** il bascule la langue du site en arabe, **Then** les questions et réponses s'affichent en arabe avec une mise en page RTL ; si une traduction manque, un repli vers le français est effectué.
3. **Given** une FAQ avec 30 questions, **When** un visiteur saisit un mot-clé dans le champ de recherche, **Then** seules les entrées dont la question ou la réponse contient ce mot-clé (dans la langue active) restent affichées.
4. **Given** une question marquée "non publiée" en backoffice, **When** un visiteur consulte la page FAQ, **Then** cette question n'apparaît pas dans la liste publique.

---

### User Story 2 - Gestion des questions/réponses par un administrateur (Priority: P1)

Un administrateur connecté au backoffice doit pouvoir créer, modifier, supprimer et réordonner les questions/réponses de la FAQ, dans les trois langues du site, en utilisant l'éditeur de texte riche déjà en place sur la plateforme. Il contrôle la publication (brouillon vs publié) et l'ordre d'affichage.

**Why this priority**: Sans interface d'administration, la FAQ ne peut pas être maintenue à jour ; c'est l'autre moitié indissociable du P1.

**Independent Test**: Se connecter en admin, ouvrir la section FAQ du backoffice, créer une question avec réponse trilingue, la publier, vérifier qu'elle apparaît côté public ; la modifier, la dépublier, vérifier le retrait public.

**Acceptance Scenarios**:

1. **Given** un admin connecté, **When** il crée une nouvelle entrée FAQ avec question/réponse en FR/EN/AR et l'associe à une catégorie, **Then** l'entrée est sauvegardée et apparaît dans la liste d'administration.
2. **Given** une entrée existante, **When** l'admin modifie le contenu via l'éditeur riche et enregistre, **Then** les versions HTML (rendu public) et Markdown (édition) sont mises à jour de façon cohérente.
3. **Given** une liste de 10 questions dans une catégorie, **When** l'admin réordonne les questions par glisser-déposer, **Then** le nouvel ordre est persistant et reflété sur la page publique.
4. **Given** une question publiée, **When** l'admin la passe en brouillon, **Then** elle disparaît immédiatement (au prochain rafraîchissement) de la page publique mais reste éditable en backoffice.
5. **Given** un admin qui supprime une question, **When** la suppression est confirmée, **Then** l'action est tracée dans le journal d'audit existant (`audit_logs`).

---

### User Story 3 - Gestion des catégories de FAQ (Priority: P2)

Un administrateur peut créer, renommer, réordonner et supprimer les catégories qui regroupent les questions (par exemple : "Admissions", "Vie étudiante", "Partenariats", "Bourses"). Les libellés des catégories sont également trilingues.

**Why this priority**: Améliore la lisibilité côté public et le rangement éditorial. Une FAQ peut techniquement fonctionner avec une seule catégorie par défaut, donc P2.

**Independent Test**: Créer 3 catégories en admin, leur attribuer des questions, vérifier le regroupement et l'ordre côté public ; supprimer une catégorie vide.

**Acceptance Scenarios**:

1. **Given** un admin, **When** il crée une catégorie avec libellés FR/EN/AR, **Then** elle est disponible lors de la création/édition de questions.
2. **Given** une catégorie qui contient des questions, **When** l'admin tente de la supprimer, **Then** le système refuse (ou propose de réaffecter les questions à une autre catégorie) afin d'éviter les questions orphelines.
3. **Given** plusieurs catégories, **When** l'admin modifie leur ordre, **Then** la page publique reflète ce nouvel ordre.

---

### Edge Cases

- **Traduction manquante** : si une question n'a pas de version dans la langue active du visiteur, le système affiche silencieusement la version française par défaut, sans badge ni avertissement (le contenu reste néanmoins lisible et complet).
- **Recherche vide** : si la recherche ne renvoie aucun résultat, un message clair est affiché ("Aucune question ne correspond à votre recherche").
- **FAQ entièrement vide** : la page publique affiche un message neutre invitant à contacter le support, sans erreur.
- **Contenu riche complexe** : les réponses peuvent contenir des images, listes, tableaux, liens — le rendu public doit rester sûr (pas d'injection HTML/JS).
- **Concurrence d'édition** : si deux admins modifient la même question simultanément, la dernière sauvegarde l'emporte ; le journal d'audit conserve l'historique.
- **Question sans catégorie** : interdite à la création (au moins une catégorie par défaut existe toujours).
- **Suppression d'une catégorie non vide** : bloquée tant que des questions y sont rattachées.

## Requirements *(mandatory)*

### Functional Requirements

#### Affichage public

- **FR-001**: Le système DOIT exposer une page publique `/faq` accessible sans authentification, listant les questions/réponses publiées regroupées par catégorie.
- **FR-002**: La page FAQ publique DOIT afficher les contenus dans la langue active du site (FR/EN/AR) et appliquer la mise en page RTL pour l'arabe.
- **FR-003**: Le système DOIT permettre au visiteur de filtrer les questions par catégorie et de rechercher par mots-clés sur le contenu visible (question + réponse) dans la langue active. La recherche s'exécute côté client sur la liste publiée chargée en une seule requête initiale (pas d'appel serveur par frappe).
- **FR-004**: Les questions DOIVENT être affichées dans un format pliable (accordéon) où la réponse riche se déplie au clic.
- **FR-004a**: Chaque question publiée DOIT exposer une ancre HTML stable (`/faq#<slug>`). À l'ouverture de la page avec un fragment, la question correspondante DOIT être automatiquement ouverte et amenée à l'écran (auto-scroll). Chaque question DOIT proposer un bouton "copier le lien" pour faciliter le partage.
- **FR-005**: Si une traduction manque dans la langue active, le système DOIT effectuer un repli silencieux sur la version française, sans afficher de badge ni d'avertissement au visiteur.
- **FR-006**: Le rendu HTML des réponses DOIT être assaini pour éviter toute injection (XSS), en réutilisant le pipeline existant (colonnes `*_html` produites par l'éditeur).
- **FR-006a**: La page FAQ publique DOIT inclure un balisage structuré JSON-LD `schema.org/FAQPage` injecté en SSR, listant chaque question publiée et sa réponse dans la langue active de la page, afin de permettre l'affichage en rich results par les moteurs de recherche.

#### Gestion en backoffice

- **FR-007**: Le système DOIT fournir une section "FAQ" dans le backoffice accessible aux utilisateurs disposant de la permission existante de gestion de contenu (la même que pour les news et les événements). Aucune nouvelle permission dédiée n'est créée.
- **FR-008**: Les administrateurs DOIVENT pouvoir créer, lire, modifier et supprimer (CRUD complet) des entrées de FAQ et des catégories de FAQ.
- **FR-009**: Chaque entrée FAQ DOIT comporter une question et une réponse pour chacune des trois langues (FR obligatoire, EN/AR optionnels mais recommandés).
- **FR-010**: La saisie des réponses DOIT utiliser l'éditeur de texte riche déjà en place (TOAST UI Editor) et stocker à la fois le HTML rendu et le Markdown source pour chaque langue.
- **FR-011**: Chaque entrée FAQ DOIT être rattachée à exactement une catégorie.
- **FR-012**: Les administrateurs DOIVENT pouvoir réordonner les questions à l'intérieur d'une catégorie ainsi que les catégories entre elles.
- **FR-013**: Chaque entrée FAQ DOIT disposer d'un statut de publication (brouillon / publié) ; seules les entrées publiées sont visibles côté public.
- **FR-014**: Le système DOIT empêcher la suppression d'une catégorie tant qu'elle contient au moins une question.
- **FR-015**: Toutes les opérations de création, modification, suppression et changement de statut DOIVENT être tracées dans le journal d'audit existant (`audit_logs`).
- **FR-016**: L'interface d'administration DOIT permettre de prévisualiser le rendu d'une réponse avant publication.

#### Données et persistance

- **FR-017**: Les entrées FAQ et leurs catégories DOIVENT être persistées dans la base de données PostgreSQL existante, en suivant les conventions du projet (champs trilingues `*_fr`/`*_en`/`*_ar`, double colonne `*_html` + `*_md` pour le contenu riche).
- **FR-018**: Le système DOIT exposer des endpoints publics (lecture seule, sans authentification) et des endpoints admin (authentifiés JWT) pour la FAQ, suivant la séparation `/api/public/*` vs `/api/admin/*` du projet.

### Key Entities *(include if feature involves data)*

- **FAQ Category (Catégorie de FAQ)** : Regroupement thématique des questions. Attributs : libellé trilingue (FR/EN/AR), description optionnelle trilingue, ordre d'affichage, statut actif. Relations : possède plusieurs FAQ Entries.
- **FAQ Entry (Question/Réponse FAQ)** : Une question et sa réponse. Attributs : question trilingue (FR/EN/AR, texte court), réponse trilingue en double format (HTML + Markdown) pour chaque langue, slug stable unique (utilisé comme ancre URL `#<slug>`, dérivé automatiquement du libellé FR à la création et éditable manuellement), statut de publication, ordre dans la catégorie, dates de création/modification, auteur (référence au user qui a créé/modifié). Relations : appartient à une FAQ Category.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Un visiteur trouve la réponse à une question fréquente en moins de 30 secondes à partir de la page d'accueil (un clic vers la FAQ + recherche/filtre).
- **SC-002**: Un administrateur peut publier une nouvelle entrée FAQ trilingue (catégorie existante, contenu riche) en moins de 5 minutes.
- **SC-003**: 95 % des questions consultées s'affichent dans la langue active du visiteur (couverture des traductions FR/EN/AR pour les questions les plus consultées).
- **SC-004**: Les modifications publiées en backoffice sont visibles sur la page publique en moins de 60 secondes (sans nécessiter de redéploiement).
- **SC-005**: La page FAQ publique se charge et devient interactive en moins de 2 secondes sur une connexion 4G standard, même avec 100 questions présentes.
- **SC-006**: Réduction d'au moins 30 % des sollicitations de support sur les sujets couverts par la FAQ dans les 3 mois suivant la mise en ligne (mesurée par la baisse des demandes entrantes sur ces thèmes).

## Assumptions

- La FAQ s'intègre dans la plateforme trilingue existante (FR par défaut, EN, AR-RTL) et réutilise les conventions du projet : champs `*_fr/_en/_ar`, double colonne `*_html`/`*_md`, endpoints publics vs admin, journal d'audit.
- L'éditeur de contenu riche est TOAST UI Editor (déjà en production), aucune nouvelle dépendance d'édition n'est introduite.
- L'authentification admin utilise le système JWT et le modèle de rôles/permissions déjà en place ; la gestion de la FAQ réutilise la permission existante de gestion de contenu (mêmes éditeurs que news/events), sans nouvelle permission dédiée.
- Les commentaires/votes utilisateurs ("cette réponse vous a-t-elle aidé ?") ne font PAS partie de cette première version (peut être ajouté ultérieurement).
- La FAQ n'est pas indexée comme entité distincte dans un moteur de recherche externe ; la recherche est purement côté client (JavaScript) sur le jeu de questions publiées chargé en une seule requête au montage de la page.
- L'historique de versions des questions n'est pas conservé au-delà du journal d'audit standard.
- Une catégorie par défaut ("Général") est créée automatiquement à l'initialisation pour garantir qu'aucune question ne soit jamais orpheline.
