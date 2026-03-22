# Feature Specification: Refonte Page Levée de Fonds

**Feature Branch**: `010-fundraising-revamp`
**Created**: 2026-03-22
**Status**: Draft
**Input**: Refonte complète de la page principale de levée de fonds et des pages individuelles de campagne, avec sections génériques, contributeurs, bouton de manifestation d'intérêt anti-spam, et médiathèques.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Consultation de la page principale Levée de Fonds (Priority: P1)

Un visiteur arrive sur la page principale `/levees-de-fonds` et découvre une vue d'ensemble de l'engagement philanthropique de l'Université Senghor. Il voit une hero section immersive, les raisons pour lesquelles contribuer, des exemples d'engagement concrets, les bénéfices liés aux contributions, le montant total collecté toutes campagnes confondues, et la liste de tous les contributeurs. La campagne en cours est mise en évidence, tandis que les campagnes passées sont accessibles de manière plus discrète (onglet ou section secondaire). Un onglet actualités regroupe les dernières nouvelles liées aux levées de fonds.

**Why this priority**: C'est la page d'entrée principale qui doit convaincre les visiteurs de l'impact de leurs contributions et les orienter vers la campagne active.

**Independent Test**: Peut être testée en naviguant vers `/levees-de-fonds` et en vérifiant la présence de toutes les sections, le montant total, la liste des contributeurs, et la distinction campagne active / campagnes passées.

**Acceptance Scenarios**:

1. **Given** un visiteur accède à `/levees-de-fonds`, **When** la page se charge, **Then** il voit une hero section avec titre, sous-titre et visuel de fond, suivie des sections "Votre contribution sert à", "Exemples d'engagement", "Bénéfices liés à votre contribution", le montant total collecté, et la liste de tous les contributeurs.
2. **Given** une campagne est en cours (statut "active"), **When** le visiteur consulte la page, **Then** cette campagne est mise en évidence dans une section dédiée avec lien vers sa page détaillée.
3. **Given** des campagnes passées existent (statut "completed"), **When** le visiteur consulte la page, **Then** elles apparaissent dans un onglet ou une section secondaire, de façon plus discrète.
4. **Given** des actualités sont associées aux levées de fonds, **When** le visiteur clique sur l'onglet "Actualités", **Then** il voit la liste des dernières actualités liées.

---

### User Story 2 - Consultation d'une page de campagne individuelle (Priority: P1)

Un visiteur clique sur une campagne depuis la page principale et accède à la page détaillée de cette campagne. Il y trouve la présentation de la campagne, la raison de la levée de fonds, un indicateur visuel de progression (objectif cible vs montant atteint), un onglet listant les contributeurs avec leurs montants, et une médiathèque (photos, vidéos, documents).

**Why this priority**: C'est la page qui concrétise l'engagement du visiteur en lui donnant tous les détails sur une campagne spécifique.

**Independent Test**: Peut être testée en naviguant vers `/levees-de-fonds/[slug]` et en vérifiant la présence de toutes les sections, l'indicateur de progression, l'onglet contributeurs, et la médiathèque.

**Acceptance Scenarios**:

1. **Given** un visiteur accède à `/levees-de-fonds/[slug]`, **When** la page se charge, **Then** il voit la présentation de la campagne, la raison de la levée, l'objectif chiffré avec le montant atteint, et un indicateur de progression visuel.
2. **Given** la campagne a des contributeurs, **When** le visiteur clique sur l'onglet "Contributeurs", **Then** il voit la liste des contributeurs avec le montant de chaque contribution.
3. **Given** la campagne a des médias associés, **When** le visiteur clique sur l'onglet "Médiathèque", **Then** il voit les photos, vidéos et documents de la campagne.
4. **Given** la campagne a le statut "clôturée", **When** le visiteur consulte la page, **Then** un indicateur visuel clair montre que la campagne est terminée.

---

### User Story 3 - Manifestation d'intérêt pour contribuer (Priority: P2)

Un visiteur intéressé par une campagne active clique sur le bouton "Manifester son intérêt" et remplit un formulaire court (nom, email, message optionnel). Avant l'envoi, un mécanisme anti-spam vérifie qu'il s'agit d'un vrai utilisateur. Après validation, sa manifestation est enregistrée en base de données et un email de confirmation est envoyé au visiteur ainsi qu'une notification à l'administration.

**Why this priority**: C'est l'action de conversion principale mais elle nécessite les pages de base (P1) pour avoir du contexte.

**Independent Test**: Peut être testée en remplissant le formulaire sur une campagne active, en vérifiant l'enregistrement en base, la réception de l'email de confirmation et la notification admin.

**Acceptance Scenarios**:

1. **Given** un visiteur est sur la page d'une campagne active, **When** il clique sur "Manifester son intérêt", **Then** un formulaire apparaît avec les champs nom, email, et message optionnel.
2. **Given** le visiteur remplit le formulaire et soumet, **When** la vérification anti-spam passe, **Then** sa manifestation est enregistrée en base de données, un email de confirmation lui est envoyé, et l'administration reçoit une notification.
3. **Given** un robot tente de soumettre le formulaire, **When** la vérification anti-spam échoue, **Then** la soumission est rejetée et aucune donnée n'est enregistrée.
4. **Given** la campagne est clôturée, **When** le visiteur consulte la page, **Then** le bouton "Manifester son intérêt" n'est pas affiché.

---

### User Story 4 - Sections éditoriales génériques de la page principale (Priority: P2)

Un administrateur peut gérer le contenu des sections éditoriales de la page principale : "Votre contribution sert à", "Exemples d'engagement", et "Bénéfices liés à votre contribution". Ces contenus sont trilingues (français, anglais, arabe) et éditables via l'interface d'administration.

**Why this priority**: Ces sections enrichissent la page mais ne bloquent pas la consultation des campagnes.

**Independent Test**: Peut être testée en modifiant le contenu d'une section dans l'admin et en vérifiant que le changement est visible sur la page publique dans les trois langues.

**Acceptance Scenarios**:

1. **Given** un administrateur accède au panneau de gestion des contenus de la page levée de fonds, **When** il modifie la section "Votre contribution sert à" en français, **Then** le contenu mis à jour apparaît sur la page publique.
2. **Given** un visiteur consulte la page en arabe, **When** la page se charge, **Then** les sections éditoriales s'affichent en arabe avec une mise en page RTL.

---

### User Story 5 - Médiathèque de campagne (Priority: P3)

Un administrateur peut associer des médias (photos, vidéos, documents) à chaque campagne. Ces médias sont visibles sur la page publique de la campagne dans un onglet "Médiathèque" avec un affichage en galerie.

**Why this priority**: La médiathèque enrichit la présentation mais n'est pas essentielle pour la fonctionnalité de base.

**Independent Test**: Peut être testée en ajoutant des médias à une campagne dans l'admin et en vérifiant qu'ils s'affichent correctement dans l'onglet Médiathèque de la page publique.

**Acceptance Scenarios**:

1. **Given** un administrateur associe des médias à une campagne, **When** un visiteur consulte l'onglet Médiathèque, **Then** les médias s'affichent en galerie avec vignettes et possibilité d'agrandissement.
2. **Given** une campagne n'a aucun média, **When** un visiteur consulte la page, **Then** l'onglet Médiathèque n'apparaît pas ou affiche un message indiquant qu'il n'y a pas de média.

---

### Edge Cases

- Que se passe-t-il quand aucune campagne n'est active ? La page principale affiche les sections génériques et les campagnes passées sans la section "Campagne en cours".
- Que se passe-t-il quand un contributeur est associé à plusieurs campagnes ? Il apparaît dans la liste globale une seule fois (avec le total cumulé) et dans chaque campagne individuellement.
- Que se passe-t-il quand le montant objectif est atteint ou dépassé ? L'indicateur de progression montre 100% ou plus avec un message de succès.
- Que se passe-t-il si un visiteur soumet le formulaire d'intérêt plusieurs fois avec le même email pour la même campagne ? Une seule manifestation est enregistrée, les suivantes mettent à jour la date.
- Que se passe-t-il si le service email est indisponible ? La manifestation est enregistrée en base, l'email sera envoyé ultérieurement ou un message informe que la confirmation arrivera sous peu.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT afficher une page principale `/levees-de-fonds` avec une hero section comprenant titre, sous-titre et image de fond, suivie d'une barre d'ancres sticky permettant la navigation rapide vers chaque section de la page (scroll vertical continu).
- **FR-002**: Le système DOIT afficher les sections éditoriales trilingues : "Votre contribution sert à", "Exemples d'engagement", "Bénéfices liés à votre contribution". Chaque section est composée d'une liste d'items structurés (icône, titre court, description), affichés en grille/cards.
- **FR-003**: Le système DOIT afficher le montant total collecté toutes campagnes confondues, calculé dynamiquement.
- **FR-004**: Le système DOIT afficher la liste de tous les contributeurs de toutes les campagnes (passées et en cours). Le montant cumulé par contributeur n'est affiché que si le contributeur y a consenti (attribut géré par l'admin). Sinon, seuls le nom et la catégorie sont visibles.
- **FR-005**: Le système DOIT mettre en évidence la ou les campagnes actives dans une section dédiée de la page principale.
- **FR-006**: Le système DOIT afficher les campagnes clôturées dans un onglet ou une section secondaire, distincte des campagnes actives.
- **FR-007**: Le système DOIT afficher un onglet "Actualités" sur la page principale regroupant les actualités liées aux levées de fonds.
- **FR-008**: Le système DOIT afficher une page individuelle par campagne (`/levees-de-fonds/[slug]`) avec présentation, raison, objectif, montant atteint, et indicateur de progression.
- **FR-009**: Le système DOIT afficher un onglet "Contributeurs" sur la page de campagne listant chaque contributeur. Le montant individuel n'est affiché que si le contributeur y a consenti.
- **FR-010**: Le système DOIT afficher un onglet "Médiathèque" sur la page de campagne avec les médias associés (photos, vidéos, documents).
- **FR-011**: Le système DOIT fournir un bouton "Manifester son intérêt" sur les pages de campagnes actives, ouvrant un formulaire (nom, email, message optionnel).
- **FR-012**: Le système DOIT intégrer un mécanisme anti-spam basé sur la vérification du navigateur (challenge JavaScript côté client, honeypot, délai minimum) pour le formulaire de manifestation d'intérêt.
- **FR-013**: Le système DOIT enregistrer chaque manifestation d'intérêt en base de données (nom, email, message, date, campagne associée).
- **FR-014**: Le système DOIT envoyer un email de confirmation au visiteur après une manifestation d'intérêt valide.
- **FR-015**: Le système DOIT envoyer une notification par email à l'administration lors d'une nouvelle manifestation d'intérêt.
- **FR-016**: Le système DOIT supporter deux statuts de campagne : "En cours" (active) et "Clôturée" (completed).
- **FR-017**: Le système DOIT supporter le trilingue (français, anglais, arabe avec RTL) pour tous les contenus affichés.
- **FR-018**: Le système DOIT empêcher les doublons de manifestation d'intérêt (même email + même campagne) en mettant à jour l'entrée existante.
- **FR-019**: Le système DOIT fournir une interface admin dédiée listant toutes les manifestations d'intérêt, avec filtrage par campagne et par statut (nouveau/contacté).
- **FR-020**: Le système DOIT permettre à l'admin de marquer une manifestation d'intérêt comme "contacté".
- **FR-021**: Le système DOIT permettre l'export CSV des manifestations d'intérêt (filtrable par campagne).

### Key Entities

- **Campagne (Fundraiser)** : Représente une levée de fonds avec titre, description, raison, objectif financier, montant atteint (calculé), statut (active/clôturée), médias associés, slug unique. Contenu trilingue.
- **Contributeur (Contributor)** : Personne ou organisation ayant participé à une campagne, avec nom, catégorie, montant, logo optionnel, et consentement à l'affichage public du montant (booléen, défaut : non). Un contributeur peut apparaître dans plusieurs campagnes.
- **Manifestation d'intérêt (Interest Expression)** : Enregistrement d'un visiteur souhaitant contribuer, avec nom, email, message optionnel, date, campagne associée, statut de suivi (nouveau/contacté). Anti-doublon par email+campagne.
- **Section éditoriale** : Contenu trilingue géré par l'admin pour les sections génériques de la page principale (raisons, exemples d'engagement, bénéfices). Chaque section contient une liste d'items structurés avec icône, titre court trilingue, et description trilingue.
- **Média de campagne** : Fichiers associés à une campagne (photos, vidéos, documents) affichés dans la médiathèque.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Un visiteur peut consulter la page principale et identifier la campagne en cours en moins de 5 secondes.
- **SC-002**: Un visiteur peut naviguer de la page principale vers une campagne et manifester son intérêt en moins de 2 minutes.
- **SC-003**: 100% des soumissions automatisées (bots) sont rejetées par le mécanisme anti-spam.
- **SC-004**: Le montant total et la liste des contributeurs sont à jour en temps réel lors de chaque chargement de page.
- **SC-005**: Les trois langues (FR, EN, AR) affichent correctement tous les contenus, y compris la mise en page RTL pour l'arabe.
- **SC-006**: Les pages se chargent entièrement en moins de 3 secondes sur une connexion standard.
- **SC-007**: Les emails de confirmation et de notification sont envoyés dans les 30 secondes suivant une manifestation d'intérêt valide.

## Clarifications

### Session 2026-03-22

- Q: Les montants individuels des contributeurs sont-ils visibles publiquement ? → A: Montants visibles uniquement si le contributeur y consent (case à cocher gérée par l'admin). Sinon, seuls le nom et la catégorie sont affichés.
- Q: Comment l'admin consulte-t-il les manifestations d'intérêt reçues ? → A: Liste admin dédiée avec filtrage par campagne, statut (nouveau/contacté), et export CSV.
- Q: Quel format pour les sections éditoriales de la page principale ? → A: Liste structurée — chaque item a une icône, un titre court et une description, rendu en grille/cards.
- Q: Relation avec l'implémentation existante (004-fundraising-page) ? → A: Repartir de zéro — supprimer l'implémentation 004 et tout recréer.
- Q: Structure de navigation de la page principale ? → A: Scroll vertical avec barre d'ancres sticky en haut (liens rapides vers chaque section).

## Assumptions

- L'implémentation existante de 004-fundraising-page sera entièrement supprimée et recréée depuis zéro (pages, composants, endpoints, types).
- Le système de médias existant (table `media`, upload via l'admin) sera réutilisé pour la médiathèque de campagne.
- Le mécanisme anti-spam sera un challenge JavaScript côté client (vérification que le navigateur exécute du JS, honeypot, et/ou délai minimum de remplissage) plutôt qu'un CAPTCHA externe, conformément à la demande de "vérificateur de navigateur".
- Les sections éditoriales génériques de la page principale seront stockées dans le système de contenu éditorial existant (table `editorial_contents`).
- Les emails utilisent le système SMTP déjà en place (aiosmtplib + Jinja2 templates).
- Le formulaire de manifestation d'intérêt ne nécessite pas de création de compte utilisateur.
- Un contributeur apparaissant dans plusieurs campagnes est affiché une seule fois sur la page principale avec son montant cumulé.
