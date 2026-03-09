# Feature Specification: Éditeur TOAST UI en modale plein écran

**Feature Branch**: `002-toastui-fullscreen-modal`
**Created**: 2026-03-09
**Status**: Draft
**Input**: User description: "j'ai fait les tests et TOAST UI a bien été migré, tout fonctionne mais je veux que là où il est utilisé ca soit un bouton et lorsqu'on clique il s'ouvre dans un modale sur tout l'écran, recouvrant navBar et footer"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Ouvrir l'éditeur en modale plein écran (Priority: P1)

Un administrateur remplit un formulaire contenant un champ de contenu riche (description, biographie, contenu d'actualité, etc.). Au lieu de voir l'éditeur TOAST UI intégré directement dans le formulaire, il voit un bouton d'action. En cliquant sur ce bouton, une modale s'ouvre en plein écran, recouvrant entièrement la page (navbar, footer, sidebar inclus). L'éditeur TOAST UI occupe tout l'espace disponible dans cette modale, offrant une expérience d'édition immersive et sans distraction.

**Why this priority**: C'est le coeur de la fonctionnalité demandée. Sans cela, rien d'autre n'a de sens.

**Independent Test**: Peut être testé en se rendant sur n'importe quelle page admin contenant un champ riche, en cliquant sur le bouton d'édition, et en vérifiant que la modale plein écran s'ouvre avec l'éditeur fonctionnel.

**Acceptance Scenarios**:

1. **Given** un formulaire admin avec un champ de contenu riche, **When** la page se charge, **Then** l'éditeur TOAST UI n'est pas visible inline ; un bouton d'ouverture est affiché à la place avec une indication du champ concerné.
2. **Given** le bouton d'édition est visible, **When** l'utilisateur clique dessus, **Then** une modale plein écran s'ouvre, recouvrant navbar, footer et tout autre élément de la page.
3. **Given** la modale plein écran est ouverte, **When** l'utilisateur regarde l'écran, **Then** l'éditeur TOAST UI occupe la totalité de l'espace disponible dans la modale (hauteur et largeur).

---

### User Story 2 - Sauvegarder et fermer la modale (Priority: P1)

L'administrateur rédige du contenu dans l'éditeur plein écran. Il peut valider son contenu et fermer la modale. Le contenu saisi (Markdown + HTML) est reporté dans le formulaire parent. L'administrateur peut aussi annuler et fermer sans sauvegarder.

**Why this priority**: Indissociable de l'ouverture — l'utilisateur doit pouvoir fermer et conserver son travail.

**Independent Test**: Ouvrir la modale, saisir du texte, cliquer sur "Valider", vérifier que la modale se ferme et que le contenu est bien présent dans le formulaire.

**Acceptance Scenarios**:

1. **Given** la modale est ouverte avec du contenu saisi, **When** l'utilisateur clique sur le bouton de validation, **Then** la modale se ferme et le contenu (Markdown et HTML) est synchronisé avec le formulaire parent.
2. **Given** la modale est ouverte avec du contenu modifié, **When** l'utilisateur clique sur le bouton de fermeture/annulation, **Then** une confirmation est demandée si du contenu a été modifié, puis la modale se ferme sans modifier le formulaire si l'annulation est confirmée.
3. **Given** la modale est ouverte, **When** l'utilisateur appuie sur la touche Échap, **Then** le même comportement de fermeture/annulation est déclenché.

---

### User Story 3 - Prévisualisation du contenu sur le bouton (Priority: P2)

Avant d'ouvrir la modale, l'administrateur peut voir un aperçu du contenu existant à côté du bouton (extrait de texte ou indication "contenu vide"). Cela lui permet de savoir si le champ contient déjà du contenu sans ouvrir l'éditeur.

**Why this priority**: Améliore l'ergonomie mais n'est pas bloquant pour le fonctionnement de base.

**Independent Test**: Charger un formulaire avec un champ riche pré-rempli, vérifier qu'un aperçu du contenu est visible à côté du bouton.

**Acceptance Scenarios**:

1. **Given** un champ riche contenant du contenu existant, **When** la page se charge, **Then** un extrait du contenu (premières lignes en texte brut) est affiché à côté du bouton.
2. **Given** un champ riche vide, **When** la page se charge, **Then** une indication "Aucun contenu" ou similaire est affichée à côté du bouton.

---

### User Story 4 - Compatibilité avec le wrapper multilingue RichTextEditor (Priority: P1)

Le composant wrapper RichTextEditor (qui gère les onglets FR/EN/AR) doit intégrer le même comportement : un bouton unique ouvrant la modale avec les onglets de langue à l'intérieur. Le support RTL pour l'arabe doit rester fonctionnel.

**Why this priority**: La majorité des pages admin (~11) utilisent ce wrapper multilingue. Sans cette compatibilité, la fonctionnalité ne couvre qu'une minorité de cas.

**Independent Test**: Ouvrir un formulaire multilingue (ex. nouveau programme), cliquer sur le bouton d'édition, vérifier que la modale s'ouvre avec les onglets FR/EN/AR fonctionnels et que l'arabe est en RTL.

**Acceptance Scenarios**:

1. **Given** un formulaire utilisant RichTextEditor avec 3 langues, **When** l'utilisateur clique sur le bouton d'édition, **Then** la modale plein écran s'ouvre avec les onglets de langue (FR, EN, AR) accessibles.
2. **Given** la modale multilingue est ouverte sur l'onglet arabe, **When** l'utilisateur saisit du texte, **Then** l'éditeur est en mode RTL et le texte s'affiche correctement de droite à gauche.
3. **Given** la modale multilingue est ouverte, **When** l'utilisateur saisit du contenu dans chaque onglet puis valide, **Then** les contenus des 3 langues sont correctement reportés dans le formulaire parent.

---

### Edge Cases

- Que se passe-t-il si l'utilisateur redimensionne la fenêtre pendant que la modale est ouverte ? La modale doit rester en plein écran et l'éditeur doit s'adapter.
- Que se passe-t-il si l'utilisateur navigue via le navigateur (bouton retour) pendant que la modale est ouverte ? La modale doit se fermer proprement sans perte de données du formulaire parent.
- Que se passe-t-il si plusieurs champs riches existent sur la même page ? Chaque bouton doit ouvrir sa propre instance de modale pour son champ spécifique.
- Que se passe-t-il si l'éditeur est déjà utilisé à l'intérieur d'une modale existante (ex. : biographie dans UserFormModal, description dans la modale secteurs) ? L'éditeur reste inline dans ces cas, sans bouton ni modale plein écran, pour éviter l'imbrication de modales.
- Que se passe-t-il en mode sombre (dark mode) ? La modale et l'éditeur doivent respecter le thème actif.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT remplacer chaque instance inline de l'éditeur TOAST UI par un bouton d'action déclenchant l'ouverture d'une modale, **sauf** lorsque l'éditeur est déjà utilisé à l'intérieur d'une modale existante (ex. : UserFormModal, modale secteurs) — dans ce cas, l'éditeur reste inline.
- **FR-002**: La modale DOIT couvrir 100% du viewport (largeur et hauteur), au-dessus de tous les éléments de la page (navbar, footer, sidebar).
- **FR-003**: L'éditeur TOAST UI dans la modale DOIT occuper tout l'espace disponible, en conservant toutes ses fonctionnalités (barre d'outils, modes WYSIWYG/Markdown, insertion d'images, tableaux).
- **FR-004**: La modale DOIT disposer d'un bouton de validation qui ferme la modale et synchronise le contenu (Markdown + HTML) avec le formulaire parent.
- **FR-005**: La modale DOIT disposer d'un bouton de fermeture/annulation avec confirmation si du contenu a été modifié.
- **FR-006**: La touche Échap DOIT déclencher le même comportement que le bouton de fermeture.
- **FR-007**: Le bouton d'ouverture DOIT afficher le titre/label du champ concerné et un aperçu du contenu existant (ou une indication de champ vide).
- **FR-008**: Le composant RichTextEditor (wrapper multilingue) DOIT intégrer le même comportement avec les onglets de langue dans la modale.
- **FR-009**: Le support RTL pour l'arabe DOIT être préservé dans la modale.
- **FR-010**: La modale DOIT supporter le mode sombre conformément au thème actif.
- **FR-011**: Le contenu existant du champ DOIT être chargé dans l'éditeur à l'ouverture de la modale.
- **FR-012**: Le scroll de la page sous la modale DOIT être désactivé pendant que la modale est ouverte.
- **FR-013**: Le clic sur le backdrop (fond sombre) de la modale NE DOIT PAS fermer la modale. La fermeture se fait uniquement via les boutons d'action ou la touche Échap.

### Key Entities

- **Bouton d'édition riche** : Élément de formulaire remplaçant l'éditeur inline, affichant le label du champ, un aperçu du contenu, et un appel à l'action pour ouvrir l'éditeur.
- **Modale plein écran** : Overlay couvrant tout le viewport, contenant l'éditeur TOAST UI, un en-tête avec le titre du champ et les boutons d'action (valider, annuler).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur peut ouvrir l'éditeur plein écran en un seul clic depuis n'importe quel champ de contenu riche dans l'interface d'administration.
- **SC-002**: La modale couvre 100% du viewport visible, sans élément de navigation visible en arrière-plan.
- **SC-003**: Le contenu saisi dans la modale est correctement reporté dans le formulaire dans 100% des cas (aucune perte de données).
- **SC-004**: Toutes les pages admin existantes utilisant l'éditeur (usage direct et via RichTextEditor) fonctionnent avec le nouveau comportement sans régression.
- **SC-005**: L'expérience d'édition en modale est fluide : ouverture et fermeture perçues comme instantanées par l'utilisateur.

## Clarifications

### Session 2026-03-09

- Q: Que faire lorsque l'éditeur est déjà utilisé à l'intérieur d'une modale existante (modales imbriquées) ? → A: Ces cas spécifiques gardent l'éditeur inline, sans bouton ni modale plein écran.
- Q: Le clic sur le backdrop (fond sombre) de la modale doit-il fermer la modale ? → A: Non, le backdrop est ignoré. Fermeture uniquement via les boutons (valider/annuler) ou la touche Échap.

## Assumptions

- Le bouton d'ouverture de la modale sera un composant réutilisable intégré dans les composants existants (ToastUIEditor.client.vue et/ou RichTextEditor.vue), minimisant les changements dans les ~15 pages consommatrices.
- Le wrapper RichTextEditor ouvrira une seule modale contenant les onglets de langue, plutôt qu'un bouton par langue.
- La confirmation d'annulation (si contenu modifié) sera un simple dialogue natif du navigateur pour rester simple.

## Scope & Boundaries

**Inclus** :
- Transformation de l'intégration inline en bouton + modale plein écran
- Adaptation des deux composants (ToastUIEditor et RichTextEditor)
- Compatibilité avec toutes les pages admin existantes

**Exclus** :
- Modification des fonctionnalités de l'éditeur TOAST UI lui-même
- Modifications du backend ou du schéma de base de données
- Ajout de nouvelles pages ou de nouveaux champs riches
