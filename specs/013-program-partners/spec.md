# Feature Specification: Association Partenaires-Formations

**Feature Branch**: `013-program-partners`
**Created**: 2026-03-25
**Status**: Draft
**Input**: User description: "On veut pouvoir associer des partenaires à une formation donnée dans les pages admin (edit et nouveau). Les logos et noms de ces partenaires s'afficheront ensuite sur la page publique de la formation, en dessous du bloc de l'appel."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Associer des partenaires à une formation existante (Priority: P1)

Un administrateur édite une formation existante. Dans la page d'édition, il voit une section "Partenaires" qui lui permet de rechercher et sélectionner des partenaires existants dans le système. Il peut en ajouter plusieurs, préciser le type de partenariat si nécessaire, et les retirer. Les modifications sont sauvegardées avec le reste de la formation.

**Why this priority**: C'est le cas d'usage principal - la majorité des formations existent déjà et ont besoin d'être enrichies avec leurs partenaires.

**Independent Test**: Peut être testé en ouvrant une formation existante, en ajoutant un ou plusieurs partenaires, en sauvegardant, puis en vérifiant que l'association persiste après rechargement.

**Acceptance Scenarios**:

1. **Given** un administrateur est sur la page d'édition d'une formation, **When** il ouvre la section "Partenaires" et recherche un partenaire par nom, **Then** les partenaires correspondants apparaissent dans une liste de suggestions.
2. **Given** un administrateur a sélectionné un partenaire, **When** il sauvegarde la formation, **Then** l'association partenaire-formation est enregistrée et visible au rechargement.
3. **Given** une formation a 3 partenaires associés, **When** l'administrateur supprime un partenaire de la liste, **Then** seuls les 2 partenaires restants sont affichés et sauvegardés.

---

### User Story 2 - Afficher les partenaires sur la page publique d'une formation (Priority: P1)

Un visiteur consulte la page publique d'une formation. En dessous du bloc d'appel à candidatures, il voit une section présentant les partenaires de la formation avec leurs logos et noms. Chaque partenaire est cliquable et redirige vers le site web du partenaire (si renseigné).

**Why this priority**: C'est l'objectif final de la fonctionnalité - rendre visible les partenariats aux visiteurs du site. Priorité égale à P1 car sans affichage public, l'association admin n'a pas de valeur.

**Independent Test**: Peut être testé en visitant la page publique d'une formation ayant des partenaires associés et en vérifiant l'affichage des logos et noms.

**Acceptance Scenarios**:

1. **Given** une formation a 3 partenaires associés avec logos, **When** un visiteur accède à la page publique de cette formation, **Then** les 3 logos et noms des partenaires sont affichés dans une section dédiée sous le bloc d'appel.
2. **Given** un partenaire associé a un site web renseigné, **When** le visiteur clique sur le logo ou le nom, **Then** il est redirigé vers le site web du partenaire dans un nouvel onglet.
3. **Given** une formation n'a aucun partenaire associé, **When** un visiteur accède à la page publique, **Then** la section partenaires n'est pas affichée du tout.

---

### User Story 3 - Associer des partenaires lors de la création d'une formation (Priority: P2)

Un administrateur crée une nouvelle formation. Pendant le processus de création, il peut déjà associer des partenaires. Les associations sont créées après la sauvegarde initiale de la formation.

**Why this priority**: Moins fréquent que l'édition, mais permet de configurer complètement une formation dès sa création.

**Independent Test**: Peut être testé en créant une nouvelle formation avec des partenaires pré-sélectionnés, puis en vérifiant que les associations existent après la création.

**Acceptance Scenarios**:

1. **Given** un administrateur remplit le formulaire de nouvelle formation, **When** il sélectionne des partenaires et soumet le formulaire, **Then** la formation est créée avec les partenaires associés.
2. **Given** un administrateur crée une formation sans sélectionner de partenaires, **When** il soumet le formulaire, **Then** la formation est créée normalement sans associations partenaires.

---

### Edge Cases

- Que se passe-t-il si un partenaire associé est désactivé dans le système ? Il ne doit pas apparaître sur la page publique mais reste visible dans l'admin avec indication de son statut inactif.
- Que se passe-t-il si un partenaire n'a pas de logo ? Son nom est affiché sans image, avec un placeholder visuel.
- Que se passe-t-il si on tente d'associer deux fois le même partenaire ? Le système empêche le doublon et affiche un message d'avertissement.
- Que se passe-t-il si tous les partenaires associés sont inactifs ? La section partenaires n'est pas affichée sur la page publique.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT permettre de rechercher et sélectionner des partenaires existants depuis la page d'édition d'une formation.
- **FR-002**: Le système DOIT permettre de rechercher et sélectionner des partenaires existants depuis la page de création d'une formation.
- **FR-003**: Le système DOIT permettre de retirer un partenaire associé à une formation.
- **FR-004**: Le système DOIT afficher les logos et noms des partenaires actifs sur la page publique de la formation, dans une section dédiée positionnée sous le bloc d'appel à candidatures.
- **FR-005**: Le système DOIT masquer la section partenaires si aucun partenaire actif n'est associé à la formation.
- **FR-006**: Le système DOIT rediriger vers le site web du partenaire (nouvel onglet) lorsqu'un visiteur clique sur un logo ou un nom de partenaire.
- **FR-007**: Le système DOIT empêcher l'association en doublon d'un même partenaire à une formation.
- **FR-008**: Le système DOIT filtrer les partenaires inactifs de l'affichage public tout en les gardant visibles dans l'interface admin.
- **FR-009**: Le système DOIT afficher un placeholder visuel pour les partenaires sans logo.
- **FR-010**: Le système DOIT permettre de spécifier optionnellement un type de partenariat lors de l'association.

### Key Entities

- **Formation (Programme)** : Entité principale représentant un programme de formation. Possède un identifiant unique, un slug pour l'URL publique, et un ensemble d'attributs descriptifs.
- **Partenaire** : Organisation externe associée à l'université. Possède un nom, un logo, un site web, un type, et un statut actif/inactif.
- **Association Formation-Partenaire** : Relation entre une formation et un partenaire, avec un type de partenariat optionnel. Un partenaire peut être associé à plusieurs formations et une formation peut avoir plusieurs partenaires.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Un administrateur peut associer un partenaire à une formation en moins de 30 secondes (recherche + sélection).
- **SC-002**: Les partenaires associés sont visibles sur la page publique de la formation immédiatement après sauvegarde (sans délai perceptible au rechargement).
- **SC-003**: La section partenaires sur la page publique est visuellement cohérente avec le reste de la page (logos alignés, responsive sur mobile et desktop).
- **SC-004**: 100% des partenaires inactifs sont exclus de l'affichage public.
- **SC-005**: La fonctionnalité d'association/désassociation est opérationnelle pour l'intégralité des formations existantes.

## Assumptions

- Les partenaires sont déjà gérés dans le système via une interface admin dédiée (CRUD complet). Cette fonctionnalité ne couvre pas la création de nouveaux partenaires, uniquement l'association avec les formations.
- La table de jonction `program_partners` existe déjà en base de données avec les champs nécessaires.
- Les endpoints admin pour la gestion des associations partenaires-formations existent déjà côté backend.
- Le bloc "appel à candidatures" existe déjà sur la page publique de la formation et sert de point de référence pour le positionnement de la section partenaires.
- Seuls les partenaires ayant le statut "actif" sont affichés publiquement.
- L'interface de sélection des partenaires dans l'admin utilise un mécanisme de recherche/autocomplétion cohérent avec les patterns existants dans le projet.
