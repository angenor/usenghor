# Feature Specification: Coloration de texte et surlignage dans l'éditeur

**Feature Branch**: `017-editor-text-color`  
**Created**: 2026-04-12  
**Status**: Draft  
**Input**: User description: "On veut pouvoir changer la couleur du texte sélectionné et aussi surligner dans une couleur. Avec un color picker proposant des couleurs prédéfinies (vives et pastels) et la possibilité de définir des couleurs personnalisées par code hexadécimal ou sélection visuelle."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Changer la couleur du texte sélectionné (Priority: P1)

En tant qu'administrateur éditant du contenu dans l'éditeur rich text, je veux pouvoir sélectionner un mot ou un passage de texte et changer sa couleur d'affichage, afin de mettre en valeur certains éléments dans mes articles, événements ou pages.

**Why this priority**: C'est la fonctionnalité principale demandée. Sans elle, aucune mise en forme colorée n'est possible. Elle apporte une valeur éditoriale immédiate.

**Independent Test**: Peut être testé en sélectionnant du texte dans l'éditeur, en cliquant sur le bouton couleur de texte, en choisissant une couleur, et en vérifiant que le texte apparaît dans la couleur choisie tant dans l'éditeur que dans le rendu public.

**Acceptance Scenarios**:

1. **Given** l'éditeur est ouvert avec du contenu textuel, **When** l'utilisateur sélectionne un mot et choisit une couleur vive (#fdbc00) depuis le sélecteur, **Then** le mot sélectionné s'affiche dans cette couleur dans l'éditeur et dans le rendu HTML public.
2. **Given** un texte déjà coloré en rouge, **When** l'utilisateur sélectionne ce texte et choisit une autre couleur, **Then** la couleur est remplacée par la nouvelle.
3. **Given** un texte coloré, **When** l'utilisateur sélectionne ce texte et clique sur l'option "supprimer la couleur" (ou couleur par défaut), **Then** le texte revient à la couleur par défaut du thème.

---

### User Story 2 - Surligner du texte avec une couleur de fond (Priority: P1)

En tant qu'administrateur, je veux pouvoir surligner un passage de texte avec une couleur de fond, afin de créer un effet de surbrillance visuelle similaire à un marqueur fluorescent.

**Why this priority**: Demandée en même temps que la coloration de texte, cette fonctionnalité est complémentaire et de même importance. Les deux forment le coeur de la feature.

**Independent Test**: Peut être testé en sélectionnant du texte, en cliquant sur le bouton surlignage, en choisissant une couleur pastel, et en vérifiant que le fond du texte apparaît dans la couleur choisie.

**Acceptance Scenarios**:

1. **Given** l'éditeur est ouvert avec du contenu, **When** l'utilisateur sélectionne un passage et choisit une couleur de surlignage pastel (#ffd966), **Then** le fond du texte sélectionné s'affiche dans cette couleur.
2. **Given** un texte déjà surligné en jaune, **When** l'utilisateur sélectionne ce texte et choisit une couleur de surlignage différente, **Then** la couleur de fond est remplacée.
3. **Given** un texte surligné, **When** l'utilisateur sélectionne ce texte et supprime le surlignage, **Then** le fond du texte redevient transparent.

---

### User Story 3 - Choisir une couleur depuis le catalogue prédéfini (Priority: P1)

En tant qu'administrateur, je veux disposer d'un catalogue de couleurs prédéfinies organisé en catégories (vives et pastels) pour choisir rapidement une couleur cohérente avec la charte graphique.

**Why this priority**: Le catalogue prédéfini est essentiel pour garantir une cohérence visuelle et une expérience utilisateur fluide. Sans catalogue, l'utilisateur devrait systématiquement entrer un code hexadécimal.

**Independent Test**: Peut être testé en ouvrant le sélecteur de couleur et en vérifiant que les deux catégories (vives, pastels) sont affichées avec les couleurs correctes.

**Acceptance Scenarios**:

1. **Given** le sélecteur de couleur est ouvert, **When** l'utilisateur consulte le catalogue, **Then** il voit deux sections : "Couleurs vives" (12 couleurs) et "Couleurs pastels" (7 couleurs).
2. **Given** le catalogue est affiché, **When** l'utilisateur clique sur une pastille de couleur, **Then** cette couleur est appliquée au texte sélectionné (couleur ou surlignage selon le mode actif).
3. **Given** le catalogue est affiché, **When** l'utilisateur survole une pastille, **Then** le code hexadécimal de la couleur est affiché en info-bulle.

---

### User Story 4 - Définir une couleur personnalisée (Priority: P2)

En tant qu'administrateur, je veux pouvoir entrer un code hexadécimal ou utiliser un sélecteur visuel (color picker) pour choisir une couleur qui n'est pas dans le catalogue prédéfini.

**Why this priority**: Fonctionnalité complémentaire qui étend la flexibilité. Le catalogue prédéfini couvre la majorité des besoins, mais certains cas nécessitent des couleurs spécifiques.

**Independent Test**: Peut être testé en ouvrant le sélecteur, en tapant un code hexadécimal valide dans le champ dédié, et en vérifiant que la couleur est appliquée.

**Acceptance Scenarios**:

1. **Given** le sélecteur de couleur est ouvert, **When** l'utilisateur tape "#FF5733" dans le champ hexadécimal et valide, **Then** cette couleur est appliquée au texte sélectionné.
2. **Given** le sélecteur de couleur est ouvert, **When** l'utilisateur utilise le sélecteur visuel (plage de couleurs), **Then** la couleur sélectionnée visuellement est appliquée et son code hexadécimal est affiché.
3. **Given** l'utilisateur entre un code hexadécimal invalide (ex: "#ZZZZZZ"), **When** il tente de valider, **Then** un message d'erreur indique que le format est incorrect et la couleur n'est pas appliquée.

---

### User Story 5 - Combiner couleur de texte et surlignage (Priority: P2)

En tant qu'administrateur, je veux pouvoir appliquer à la fois une couleur de texte ET un surlignage sur le même passage, afin de créer des mises en forme riches.

**Why this priority**: Fonctionnalité d'enrichissement qui ajoute de la valeur mais n'est pas bloquante pour les cas d'usage de base.

**Independent Test**: Peut être testé en appliquant une couleur de texte rouge puis un surlignage jaune sur le même mot, et en vérifiant que les deux styles coexistent.

**Acceptance Scenarios**:

1. **Given** un texte avec une couleur de texte rouge, **When** l'utilisateur applique un surlignage jaune sur ce même texte, **Then** le texte est rouge sur fond jaune.
2. **Given** un texte avec couleur et surlignage, **When** l'utilisateur supprime uniquement la couleur de texte, **Then** le surlignage reste et le texte revient à la couleur par défaut.

---

### Edge Cases

- Que se passe-t-il quand l'utilisateur essaie d'appliquer une couleur sans avoir sélectionné de texte ? Le sélecteur s'ouvre mais aucune couleur n'est appliquée ; un indicateur visuel montre qu'il faut sélectionner du texte.
- Que se passe-t-il quand le contenu coloré est copié-collé dans l'éditeur ? Les couleurs sont préservées.
- Que se passe-t-il quand on bascule entre mode WYSIWYG et mode Markdown ? Les balises `<span style="...">` restent en HTML brut dans le Markdown (comportement natif de TOAST UI). Pas de syntaxe Markdown spéciale.
- Que se passe-t-il quand on applique une couleur de texte identique à la couleur de fond (texte invisible) ? Aucune restriction n'est imposée, mais le texte reste sélectionnable.
- Comment les couleurs s'affichent-elles en mode sombre (dark mode) ? Les couleurs appliquées restent telles quelles ; le rendu public respecte la couleur choisie indépendamment du thème.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT proposer deux boutons split distincts dans la barre d'outils de l'éditeur : "Couleur du texte" et "Surlignage". Chaque bouton affiche visuellement la dernière couleur utilisée.
- **FR-002**: Un clic sur la zone principale du bouton DOIT appliquer directement la dernière couleur utilisée au texte sélectionné. Un clic sur la flèche/chevron DOIT ouvrir le sélecteur de couleur complet.
- **FR-003**: Le sélecteur DOIT afficher un catalogue de couleurs prédéfinies organisé en deux sections :
  - **Couleurs vives** : #fdbc00, #8bbc0a, #049ddf, #e06666, #c27ba0, #a935c6, #1ca2bd, #0a5261, #e95853, #2b4bbf, #f32525
  - **Couleurs pastels** : #ffd966, #93c47d, #a4c2f4, #ea9999, #d5a6bd, #b4a7d6, #a2c4c9
- **FR-004**: Le sélecteur DOIT permettre la saisie d'un code hexadécimal personnalisé (formats #RGB, #RRGGBB, #RRGGBBAA acceptés).
- **FR-005**: Le sélecteur DOIT inclure un sélecteur visuel (plage de couleurs interactive) pour choisir une couleur personnalisée.
- **FR-006**: Le système DOIT permettre de supprimer la couleur de texte ou le surlignage pour revenir à l'état par défaut.
- **FR-007**: Le système DOIT conserver les couleurs appliquées lors de la sauvegarde et les restituer correctement dans le rendu public (HTML).
- **FR-008**: Le système DOIT stocker les informations de couleur dans le contenu HTML (colonne `*_html`) de manière standard (attribut `style` inline ou balise `<span>`).
- **FR-009**: Le composant de rendu public (`RichTextRenderer.vue`) DOIT afficher correctement les couleurs de texte et les surlignages sans nécessiter de modification si le HTML est standard.
- **FR-010**: Le catalogue de couleurs prédéfinies DOIT être configurable (ajout/suppression de couleurs) via la configuration du composant.
- **FR-013**: Le sélecteur de couleur DOIT être un composant unique partagé entre les deux fonctions (couleur de texte et surlignage), affichant le même catalogue complet (vives + pastels). Chaque bouton DOIT maintenir indépendamment sa propre dernière couleur utilisée.
- **FR-011**: Le système DOIT valider le format du code hexadécimal saisi et afficher un message d'erreur si le format est invalide.
- **FR-012**: Les couleurs DOIVENT pouvoir être combinées : couleur de texte et surlignage sur le même passage simultanément.

### Key Entities

- **Couleur prédéfinie** : Une couleur du catalogue, caractérisée par son code hexadécimal, sa catégorie (vive ou pastel) et un label optionnel.
- **Style de texte coloré** : Application d'une couleur de texte (foreground) ou de surlignage (background) à une sélection de texte, stockée comme attribut de style inline dans le HTML.

## Clarifications

### Session 2026-04-12

- Q: Comportement en mode Markdown ? → A: WYSIWYG uniquement. Les couleurs sont du HTML inline (`<span style="...">`), visible tel quel en mode Markdown. Pas de syntaxe Markdown spéciale ni de conversion.
- Q: Mémoire de la dernière couleur utilisée ? → A: Bouton split (pattern Word/Google Docs). Clic direct = applique la dernière couleur, flèche/chevron = ouvre le sélecteur complet.
- Q: Sélecteur partagé ou séparé pour couleur de texte et surlignage ? → A: Composant partagé, état indépendant. Même UI et catalogue pour les deux, mais chaque bouton retient sa propre dernière couleur utilisée.

## Assumptions

- Le TOAST UI Editor est déjà intégré dans le projet (composant `ToastUIEditor.client.vue`, composable `useToastUIEditor.ts`).
- Le contenu est stocké en double colonne `*_html` et `*_md`. Les couleurs seront encodées en HTML inline (`<span style="color:...">` / `<span style="background-color:...">`).
- Le composant `RichTextRenderer.vue` affiche déjà du HTML brut, donc les styles inline de couleur seront rendus nativement sans modification.
- Les couleurs sont purement visuelles et n'ont pas de signification sémantique particulière (pas d'accessibilité WCAG requise au-delà du standard existant).
- Le catalogue prédéfini est le même pour tous les administrateurs (pas de personnalisation par utilisateur).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Un administrateur peut changer la couleur d'un texte sélectionné en moins de 3 clics (ouvrir le sélecteur, choisir la couleur).
- **SC-002**: Un administrateur peut surligner du texte en moins de 3 clics.
- **SC-003**: 100% des 18 couleurs prédéfinies sont visibles et cliquables dans le sélecteur sans défilement.
- **SC-004**: Les couleurs appliquées dans l'éditeur sont fidèlement restituées dans le rendu public sur toutes les pages utilisant le `RichTextRenderer`.
- **SC-005**: La saisie d'un code hexadécimal personnalisé et son application au texte se font en moins de 10 secondes.
- **SC-006**: Les couleurs persistent après sauvegarde, rechargement de la page et réouverture de l'éditeur.
