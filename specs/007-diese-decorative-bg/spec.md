# Feature Specification: Dièses décoratifs en arrière-plan

**Feature Branch**: `007-diese-decorative-bg`
**Created**: 2026-03-19
**Status**: Draft
**Input**: Utiliser les dièses (symbole de l'Université Senghor) comme éléments décoratifs subtils dans le background du footer, de certaines sections et de certaines cartes. Adapter selon le mode clair/sombre.

## Clarifications

### Session 2026-03-19

- Q: Quelles sections du site (hors footer) doivent recevoir un motif dièse décoratif ? → A: Section hero (accueil) + section "Découvrir l'Université" (À propos)
- Q: Comment les motifs décoratifs doivent-ils être intégrés dans le code ? → A: Composant Vue réutilisable wrappant les zones cibles
- Q: Comment le dièse doit-il être positionné dans chaque zone ? → A: Un seul grand dièse, partiellement visible dans un coin (rogné par overflow hidden)
- Q: Comment les images décoratives doivent-elles être traitées pour les technologies d'assistance ? → A: Masquées des lecteurs d'écran (aria-hidden, rôle décoratif)
- Q: Quel type de carte doit recevoir le motif dièse en priorité ? → A: Cartes "preview" (aperçus de sections, grandes cartes avec fond coloré)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Identité visuelle renforcée dans le footer (Priority: P1)

Un visiteur du site navigue sur n'importe quelle page. En atteignant le footer, il perçoit subtilement le motif dièse de l'Université en arrière-plan, ce qui renforce l'identité de marque sans gêner la lisibilité du contenu.

**Why this priority**: Le footer est visible sur toutes les pages, c'est la zone à plus fort impact pour cette fonctionnalité décorative.

**Independent Test**: Vérifier visuellement que le dièse apparaît en arrière-plan du footer en mode clair et en mode sombre, sans nuire à la lisibilité du texte et des liens.

**Acceptance Scenarios**:

1. **Given** le site est affiché en mode clair, **When** le visiteur fait défiler jusqu'au footer, **Then** le motif dièse coloré est visible en arrière-plan avec une opacité très basse (effet subtil de tache/ombre).
2. **Given** le site est affiché en mode sombre, **When** le visiteur fait défiler jusqu'au footer, **Then** le motif dièse en dégradé gris est visible en arrière-plan avec une opacité adaptée au fond sombre.
3. **Given** le footer est affiché sur mobile, **When** le visiteur consulte la page, **Then** le motif décoratif reste subtil et ne crée pas de surcharge visuelle sur petit écran.

---

### User Story 2 - Motifs décoratifs dans les sections de contenu (Priority: P2)

Un visiteur parcourt la page d'accueil ou la page "À propos". La section hero de l'accueil et la section "Découvrir l'Université" de la page À propos affichent un motif dièse en filigrane, créant une signature visuelle distinctive sans distraire de la lecture.

**Why this priority**: Ces deux sections sont parmi les plus visitées du site et disposent de fonds qui se prêtent bien à l'effet décoratif.

**Independent Test**: Vérifier que le motif dièse apparaît dans la section hero (accueil) et dans la section "Découvrir l'Université" (À propos) en mode clair et sombre.

**Acceptance Scenarios**:

1. **Given** une section de contenu disposant d'un fond coloré ou neutre, **When** le visiteur la consulte, **Then** un motif dièse est visible en filigrane (positionnement dans un coin, opacité réduite, pas de gêne à la lecture).
2. **Given** le site change de mode clair à sombre, **When** une section décorative est affichée, **Then** la variante de dièse s'adapte automatiquement (coloré en clair, dégradé gris en sombre).

---

### User Story 3 - Touche décorative sur les cartes "preview" (Priority: P3)

Un visiteur consulte une grille de cartes "preview" (aperçus de sections, ex: sur la page "À propos"). Ces cartes présentent un léger motif dièse partiellement visible dans un coin, ajoutant une touche de personnalité sans surcharger le design.

**Why this priority**: Les cartes "preview" sont des éléments plus petits avec fond coloré ; l'effet doit être encore plus discret que dans le footer ou les sections.

**Independent Test**: Vérifier que les cartes "preview" (`section/Preview.vue`) affichent un motif dièse subtil dans un coin en mode clair et sombre.

**Acceptance Scenarios**:

1. **Given** une carte de type "preview", **When** le visiteur la voit, **Then** un grand motif dièse partiellement rogné est visible dans un coin avec une opacité très faible (≤5%).
2. **Given** le visiteur survole la carte, **When** l'animation de hover se déclenche, **Then** le motif dièse ne gêne pas la lisibilité ni les interactions.

---

### Edge Cases

- Que se passe-t-il sur des écrans très larges (>1920px) ? Le motif doit rester proportionné et ne pas se répéter de manière indésirable.
- Comment le motif se comporte-t-il quand le contenu du footer est très long (beaucoup de liens) ? Il ne doit pas se superposer au texte de manière gênante.
- Sur les navigateurs ne supportant pas certaines propriétés visuelles avancées, le rendu doit rester acceptable (dégradation gracieuse).
- En impression, les motifs décoratifs ne doivent pas consommer d'encre inutilement.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le footer DOIT afficher un seul grand motif dièse partiellement visible dans un coin (rogné par le conteneur), en arrière-plan, avec une opacité réduite.
- **FR-002**: Le motif dièse DOIT s'adapter au mode d'affichage : version colorée en mode clair, version dégradé gris en mode sombre.
- **FR-003**: La section hero de la page d'accueil et la section "Découvrir l'Université" de la page "À propos" DOIVENT intégrer un motif dièse décoratif en filigrane.
- **FR-004**: Les cartes "preview" (`section/Preview.vue`) DOIVENT intégrer un grand motif dièse partiellement rogné dans un coin, avec une opacité très faible (≤5%).
- **FR-005**: Les motifs décoratifs NE DOIVENT PAS nuire à la lisibilité du texte, des liens ou des boutons qui les surplombent.
- **FR-006**: Les motifs décoratifs DOIVENT être responsifs et s'adapter aux différentes tailles d'écran (mobile, tablette, desktop).
- **FR-007**: L'effet décoratif DOIT rester subtil — pas de répétition en mosaïque, pas de motif trop grand ou trop opaque.
- **FR-008**: Les motifs NE DOIVENT PAS apparaître à l'impression de la page.
- **FR-009**: Les images décoratives DOIVENT être masquées des technologies d'assistance (lecteurs d'écran) via `aria-hidden` et un rôle purement décoratif — elles n'apportent aucune information sémantique.

### Assumptions

- Les deux images dièse existantes (`Dieese_couleur.png` pour le mode clair, `diese-usenghor_degrade.png` pour le mode sombre) sont les seules variantes nécessaires.
- Le positionnement consiste en un seul grand dièse placé en absolu dans un coin du conteneur (overflow hidden), en couche derrière le contenu.
- L'opacité cible se situe entre 3% et 10% selon la zone (plus faible sur les cartes, un peu plus visible dans le footer).
- Aucune animation n'est requise sur les motifs (pas de parallaxe, pas de rotation au scroll).
- Les images existantes sont suffisamment légères pour ne pas impacter les performances de chargement.
- Un composant Vue réutilisable unique gère l'affichage du dièse décoratif ; les zones cibles (footer, hero, sections, cartes) l'intègrent comme enfant ou overlay.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Le motif dièse est visible dans le footer sur 100% des pages du site, en mode clair et en mode sombre.
- **SC-002**: La lisibilité du contenu (texte, liens, boutons) dans les zones décorées reste identique à celle sans décoration — aucun élément textuel n'est rendu difficile à lire.
- **SC-003**: Le chargement des pages comportant les motifs décoratifs ne dépasse pas +100ms par rapport à la version sans motifs.
- **SC-004**: L'effet visuel est perçu comme subtil — le motif n'est pas la première chose que l'on remarque en arrivant sur la page.
- **SC-005**: Les motifs s'affichent correctement sur les 3 principaux navigateurs (Chrome, Firefox, Safari) et sur mobile.
