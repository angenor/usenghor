# Feature Specification: Page Levée de Fonds

**Feature Branch**: `004-fundraising-page`
**Created**: 2026-03-16
**Status**: Draft
**Input**: User description: "Page spéciale levée de fond avec hero section, image de couverture, 3 onglets (présentation avec texte enrichi et somme totale, contributeurs par catégorie avec montants, actualités associées)"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Consulter une levée de fonds (Priority: P1)

Un visiteur du site accède à la page de détail d'une levée de fonds. Il découvre un hero section avec l'image de couverture, le titre et les informations essentielles. Par défaut, l'onglet « Présentation » est affiché avec le texte enrichi décrivant la campagne et la somme totale levée.

**Why this priority**: C'est la fonctionnalité centrale — sans elle, la page n'a pas de raison d'exister. Elle délivre immédiatement de la valeur au visiteur.

**Independent Test**: Peut être testé en accédant à l'URL d'une levée de fonds et en vérifiant que le hero, l'image de couverture, la présentation et le montant total s'affichent correctement.

**Acceptance Scenarios**:

1. **Given** une levée de fonds publiée existe, **When** le visiteur accède à sa page, **Then** il voit le hero section avec le titre, l'image de couverture, et l'onglet Présentation actif par défaut
2. **Given** le visiteur est sur l'onglet Présentation, **When** il consulte le contenu, **Then** il voit le texte enrichi de description, l'objectif financier, la somme totale levée et un indicateur de progression (barre/pourcentage)
3. **Given** le visiteur est sur la page, **When** il navigue entre les onglets, **Then** le contenu correspondant s'affiche sans rechargement de page

---

### User Story 2 - Consulter les contributeurs d'une levée de fonds (Priority: P1)

Un visiteur clique sur l'onglet « Contributeurs » pour voir qui a contribué à la levée de fonds. Les contributeurs sont organisés par catégorie : États et organisations internationales, Fondations et philanthropes, Entreprises. Chaque contributeur est affiché avec le montant de sa contribution.

**Why this priority**: Les contributeurs sont un élément clé de transparence et de crédibilité pour une campagne de levée de fonds.

**Independent Test**: Peut être testé en navigant vers l'onglet Contributeurs et en vérifiant l'affichage par catégorie avec les montants.

**Acceptance Scenarios**:

1. **Given** le visiteur est sur la page d'une levée de fonds, **When** il clique sur l'onglet Contributeurs, **Then** il voit les contributeurs regroupés en 3 catégories : « États et organisations internationales », « Fondations et philanthropes », « Entreprises »
2. **Given** l'onglet Contributeurs est affiché, **When** le visiteur consulte une catégorie, **Then** chaque contributeur affiche son logo (si disponible), son nom et le montant de sa contribution
3. **Given** une catégorie n'a aucun contributeur, **When** le visiteur consulte l'onglet, **Then** la catégorie est masquée ou affiche un message indiquant qu'il n'y a pas encore de contributeur

---

### User Story 3 - Consulter les actualités liées à une levée de fonds (Priority: P2)

Un visiteur clique sur l'onglet « Actualités » pour voir les articles d'actualité associés à la levée de fonds. Ces actualités proviennent du module d'actualités existant et sont liées à la campagne.

**Why this priority**: Les actualités enrichissent la page mais ne sont pas essentielles au fonctionnement de base. Elles apportent du contexte et maintiennent l'engagement.

**Independent Test**: Peut être testé en associant des actualités à une levée de fonds puis en vérifiant leur affichage dans l'onglet dédié.

**Acceptance Scenarios**:

1. **Given** le visiteur est sur la page d'une levée de fonds, **When** il clique sur l'onglet Actualités, **Then** il voit la liste des actualités associées à cette levée de fonds
2. **Given** des actualités sont associées, **When** le visiteur clique sur une actualité, **Then** il est redirigé vers la page de détail de l'actualité
3. **Given** aucune actualité n'est associée, **When** le visiteur consulte l'onglet, **Then** un message indique qu'aucune actualité n'est disponible pour le moment

---

### User Story 4 - Parcourir la liste des levées de fonds (Priority: P1)

Un visiteur accède à la page listant toutes les levées de fonds publiées. Il peut voir un aperçu de chaque campagne (titre, image, somme levée, statut) et cliquer pour accéder au détail.

**Why this priority**: La page de liste est le point d'entrée principal vers les levées de fonds. Sans elle, les visiteurs n'ont pas de moyen de découvrir les campagnes.

**Independent Test**: Peut être testé en accédant à la page de liste et en vérifiant que toutes les levées de fonds publiées apparaissent avec leurs informations de base.

**Acceptance Scenarios**:

1. **Given** plusieurs levées de fonds publiées existent, **When** le visiteur accède à la page de liste, **Then** il voit toutes les campagnes avec titre, image de couverture, somme levée et statut
2. **Given** le visiteur est sur la page de liste, **When** il clique sur une levée de fonds, **Then** il est redirigé vers la page de détail correspondante
3. **Given** aucune levée de fonds n'est publiée, **When** le visiteur accède à la page de liste, **Then** un message indique qu'aucune campagne n'est en cours

---

### User Story 5 - Gérer les levées de fonds (admin) (Priority: P2)

Un administrateur peut créer, modifier et publier des levées de fonds depuis l'interface d'administration. Il renseigne le titre, l'image de couverture, la description en texte enrichi, l'objectif financier et la somme levée.

**Why this priority**: Nécessaire pour alimenter le contenu, mais la consultation publique est prioritaire pour valider le concept.

**Independent Test**: Peut être testé en créant une levée de fonds dans l'admin et en vérifiant qu'elle apparaît correctement côté public.

**Acceptance Scenarios**:

1. **Given** un administrateur connecté, **When** il crée une nouvelle levée de fonds avec tous les champs requis, **Then** la levée de fonds est enregistrée et peut être publiée
2. **Given** une levée de fonds existante, **When** l'administrateur la modifie, **Then** les changements sont visibles côté public après publication
3. **Given** une levée de fonds existante, **When** l'administrateur modifie le texte enrichi, **Then** le contenu est sauvegardé en double format (HTML pour l'affichage, Markdown pour l'édition)

---

### User Story 6 - Gérer les contributeurs (admin) (Priority: P2)

Un administrateur peut ajouter, modifier et supprimer des contributeurs pour chaque levée de fonds. Il spécifie le nom, la catégorie (État/organisation internationale, Fondation/philanthrope, Entreprise) et le montant de la contribution.

**Why this priority**: Complémentaire à la gestion des levées de fonds, nécessaire pour alimenter l'onglet Contributeurs.

**Independent Test**: Peut être testé en ajoutant des contributeurs à une levée de fonds puis en vérifiant leur affichage dans l'onglet Contributeurs côté public.

**Acceptance Scenarios**:

1. **Given** un administrateur sur la page d'une levée de fonds, **When** il ajoute un contributeur avec nom, catégorie et montant, **Then** le contributeur est enregistré et visible dans l'onglet Contributeurs
2. **Given** un contributeur existant, **When** l'administrateur modifie le montant, **Then** le montant mis à jour est reflété côté public et le total est recalculé
3. **Given** un contributeur existant, **When** l'administrateur le supprime, **Then** il disparaît de la liste et le total est recalculé

---

### User Story 7 - Associer des actualités à une levée de fonds (admin) (Priority: P3)

Un administrateur peut associer des actualités existantes à une levée de fonds, et les dissocier si nécessaire.

**Why this priority**: Fonctionnalité enrichissante mais non bloquante pour le lancement.

**Independent Test**: Peut être testé en associant une actualité existante à une levée de fonds et en vérifiant son apparition dans l'onglet Actualités.

**Acceptance Scenarios**:

1. **Given** un administrateur sur la page d'une levée de fonds, **When** il recherche et sélectionne une actualité existante, **Then** l'actualité est associée et apparaît dans l'onglet Actualités côté public
2. **Given** une actualité déjà associée, **When** l'administrateur la dissocie, **Then** elle disparaît de l'onglet Actualités

---

### Edge Cases

- Que se passe-t-il si un contributeur est ajouté avec un montant de 0 ? Le système accepte la contribution mais affiche « Contribution non monétaire » ou le montant 0.
- Que se passe-t-il si la somme des contributions dépasse la somme totale affichée ? La somme totale levée est calculée automatiquement à partir des contributions individuelles.
- Que se passe-t-il si une actualité associée est supprimée ou dépubliée ? L'association reste mais l'actualité n'est plus affichée côté public.
- Que se passe-t-il si la page est consultée en arabe ? Le layout passe en RTL, les onglets et contenus s'adaptent, conformément au support trilingue du site.
- Que se passe-t-il si l'image de couverture n'est pas définie ? Une image par défaut ou un placeholder est affiché.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT afficher une page de liste des levées de fonds publiées avec titre, image de couverture, somme levée et statut
- **FR-002**: Le système DOIT afficher une page de détail avec un hero section contenant le titre et l'image de couverture
- **FR-003**: Le système DOIT proposer 3 onglets sur la page de détail : Présentation, Contributeurs, Actualités
- **FR-004**: L'onglet Présentation DOIT afficher le texte enrichi de description, l'objectif financier, la somme totale levée et un indicateur de progression (barre/pourcentage)
- **FR-005**: L'onglet Contributeurs DOIT afficher les contributeurs regroupés par catégorie (États et organisations internationales, Fondations et philanthropes, Entreprises) avec le logo (si disponible), le nom et le montant de chaque contribution, triés par montant décroissant au sein de chaque catégorie
- **FR-006**: L'onglet Actualités DOIT afficher les actualités associées à la levée de fonds
- **FR-007**: Le système DOIT permettre aux administrateurs de créer, modifier et publier des levées de fonds
- **FR-008**: Le système DOIT stocker le contenu enrichi en double format : HTML (affichage) et Markdown (édition), conformément au pattern existant du projet
- **FR-009**: Le système DOIT permettre aux administrateurs d'ajouter, modifier et supprimer des contributeurs pour chaque levée de fonds
- **FR-010**: Le système DOIT permettre aux administrateurs d'associer et dissocier des actualités existantes à une levée de fonds
- **FR-011**: La somme totale levée DOIT être calculée automatiquement à partir de la somme des contributions individuelles (tous montants en EUR)
- **FR-012**: Le système DOIT supporter les 3 langues du site (français, anglais, arabe) avec support RTL pour l'arabe
- **FR-013**: Seules les levées de fonds avec statut « en cours » ou « terminée » DOIVENT être visibles côté public (les brouillons restent invisibles)
- **FR-014**: Seules les actualités publiées et associées DOIVENT être affichées dans l'onglet Actualités

### Key Entities

- **Levée de fonds (Fundraiser)** : Représente une campagne de levée de fonds. Attributs principaux : titre (trilingue), description enrichie (trilingue, HTML + Markdown), image de couverture, objectif financier (montant cible en EUR), somme totale levée (calculée), statut (brouillon / en cours / terminée), dates de création/modification.
- **Contributeur (Contributor)** : Représente un contributeur à une levée de fonds. Attributs principaux : nom (trilingue), catégorie (État/organisation internationale, Fondation/philanthrope, Entreprise), montant de la contribution en EUR, logo (optionnel, via module média), levée de fonds associée.
- **Association Actualité-Levée de fonds** : Table de liaison entre une actualité existante (module news) et une levée de fonds. Permet d'afficher les actualités pertinentes dans l'onglet dédié.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Les visiteurs peuvent consulter une levée de fonds complète (hero, présentation, contributeurs, actualités) en moins de 3 clics depuis la page d'accueil
- **SC-002**: Les administrateurs peuvent créer une levée de fonds complète (avec contributeurs et actualités associées) en moins de 10 minutes
- **SC-003**: La somme totale levée est toujours cohérente avec la somme des contributions individuelles (écart de 0)
- **SC-004**: 100% des contenus sont disponibles dans les 3 langues supportées (français, anglais, arabe) avec un affichage RTL correct pour l'arabe
- **SC-005**: La navigation entre les 3 onglets est instantanée (sans rechargement de page)
- **SC-006**: Les catégories de contributeurs vides sont gérées gracieusement (masquées ou avec message informatif)

## Clarifications

### Session 2026-03-17

- Q: Faut-il afficher un objectif de collecte avec indicateur de progression ? → A: Oui, objectif cible + somme levée + barre/pourcentage de progression.
- Q: Quelle devise pour les montants de contribution ? → A: Devise unique (EUR).
- Q: Quel cycle de vie pour une levée de fonds ? → A: 3 statuts : brouillon / en cours / terminée.
- Q: Les contributeurs affichent-ils un logo ? → A: Nom + montant + logo optionnel (module média existant).
- Q: Tri des contributeurs dans chaque catégorie ? → A: Par montant décroissant (plus gros contributeurs en premier).

## Assumptions

- La somme totale levée est **calculée automatiquement** à partir des contributions individuelles (pas saisie manuellement). Cela garantit la cohérence des données.
- Les catégories de contributeurs sont **fixes** (3 catégories prédéfinies) et non configurables par l'administrateur.
- Les actualités associées proviennent du **module d'actualités existant** (table `news` / `events`). Il ne s'agit pas de créer de nouvelles actualités depuis la page de levée de fonds.
- Le **texte enrichi** utilise le composant TOAST UI Editor existant du projet, avec le pattern double colonne HTML + Markdown.
- Le **statut** suit un cycle de vie à 3 états : **brouillon** (non visible), **en cours** (publié et actif), **terminée** (publié mais clôturé). La publication rend la campagne « en cours », l'admin la clôture manuellement en « terminée ».
- L'**image de couverture** utilise le module média existant du projet.
