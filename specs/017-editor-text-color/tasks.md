# Tasks: Coloration de texte et surlignage dans l'éditeur

**Input**: Design documents from `/specs/017-editor-text-color/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md

**Tests**: Non demandés explicitement. Vérification manuelle via quickstart.md.

**Organization**: Tasks groupées par user story. US3 (catalogue prédéfini) est intégré à US1 car le catalogue est un prérequis du sélecteur de couleur.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut être exécuté en parallèle (fichiers différents, pas de dépendances)
- **[Story]**: User story associée (US1, US2, US3, US4, US5)
- Chemins relatifs depuis la racine du repo

## Path Conventions

- **Frontend**: `usenghor_nuxt/app/`

---

## Phase 1: Setup

**Purpose**: Aucune initialisation de projet nécessaire (projet existant). Création de la structure de fichiers.

- [x] T001 Créer le fichier composable `usenghor_nuxt/app/composables/useColorPicker.ts` avec le catalogue de couleurs prédéfinies (11 vives + 7 pastels) et les types TypeScript (`ColorPreset`, `ColorCategory`, `ColorPickerMode`)
- [x] T002 Créer le squelette du plugin `usenghor_nuxt/app/plugins/toastui-color-plugin.ts` avec la signature `colorPlugin(context, options) → PluginInfo` et les stubs vides pour `markdownCommands`, `wysiwygCommands`, `toolbarItems`, `toHTMLRenderers`

---

## Phase 2: Foundational (Bloquant)

**Purpose**: Infrastructure partagée entre toutes les user stories

**⚠️ CRITICAL**: US1-US5 ne peuvent pas commencer avant la fin de cette phase

- [x] T003 Implémenter dans `usenghor_nuxt/app/composables/useColorPicker.ts` : la fonction `validateHexColor(hex: string): boolean` avec le regex `/^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/`, la fonction `normalizeHexColor(hex: string): string` (convertit #RGB → #RRGGBB), et l'état `lastColor` par mode (text-color / highlight)
- [x] T004 Implémenter dans `usenghor_nuxt/app/plugins/toastui-color-plugin.ts` : le `toHTMLRenderers.htmlInline.span` qui transmet `node.attrs` pour le rendu des `<span>` inline (couleur et surlignage) dans le preview Markdown
- [x] T005 Intégrer le plugin dans `usenghor_nuxt/app/components/ToastUIEditor.client.vue` : importer `colorPlugin` depuis `~/plugins/toastui-color-plugin` et l'ajouter au tableau `plugins` de l'éditeur aux côtés de `tableMergedCell`

**Checkpoint**: Le plugin est chargé sans erreur, aucun bouton visible encore.

---

## Phase 3: User Story 1 + 3 - Couleur de texte avec catalogue prédéfini (Priority: P1) 🎯 MVP

**Goal**: L'administrateur peut sélectionner du texte et changer sa couleur via un bouton split avec popup contenant le catalogue de couleurs vives et pastels.

**Independent Test**: Sélectionner du texte → cliquer sur le chevron du bouton couleur → choisir une couleur du catalogue → le texte apparaît dans la couleur choisie dans l'éditeur. Sauvegarder → le rendu public affiche la couleur.

### Implementation

- [x] T006 [US1] Implémenter dans `usenghor_nuxt/app/composables/useColorPicker.ts` : la fonction `createColorPickerPopup(mode: 'text-color' | 'highlight', eventEmitter, commandName: string): HTMLElement` qui génère le DOM du popup avec la grille de pastilles (section "Couleurs vives" 11 pastilles + section "Couleurs pastels" 7 pastilles), info-bulle hex au survol, et bouton "Supprimer la couleur". Chaque pastille émet `eventEmitter.emit('command', commandName, { selectedColor })` puis `eventEmitter.emit('closePopup')`.
- [x] T007 [US1] Implémenter dans `usenghor_nuxt/app/plugins/toastui-color-plugin.ts` : la commande WYSIWYG `textColor` qui applique `schema.marks.span.create({ htmlAttrs: { style: 'color: {selectedColor}' } })` via `tr.addMark(from, to, mark)`, et la suppression via `tr.removeMark` quand `selectedColor` est vide
- [x] T008 [US1] Implémenter dans `usenghor_nuxt/app/plugins/toastui-color-plugin.ts` : la commande Markdown `textColor` qui encapsule le texte sélectionné dans `<span style="color: {selectedColor}">texte</span>` via `tr.replaceSelectionWith(schema.text(colored))`, et retire le `<span>` quand `selectedColor` est vide
- [x] T009 [US1] Implémenter dans `usenghor_nuxt/app/plugins/toastui-color-plugin.ts` : la création du bouton split "Couleur du texte" comme élément DOM custom avec icône "A" souligné de la dernière couleur, zone principale (clic → applique dernière couleur) et flèche/chevron (clic → ouvre popup). L'ajouter au tableau `toolbarItems` avec `groupIndex: 0, itemIndex: 3`.
- [x] T010 [US1] Ajouter les styles CSS dans `usenghor_nuxt/app/components/ToastUIEditor.client.vue` (section `<style>`) : `.color-split-btn` (layout flex du bouton split), `.color-picker-popup` (popup grid), `.color-swatch` (pastilles rondes 24x24px avec bordure), `.color-section label` (titres des sections), état hover et focus des pastilles, tooltip hex
- [x] T011 [US1] Ajouter les styles dark mode dans `usenghor_nuxt/app/components/ToastUIEditor.client.vue` : `.dark .color-picker-popup` (fond sombre, texte clair, bordures adaptées), `.dark .color-swatch` (bordure visible sur fond sombre)

**Checkpoint**: La couleur de texte fonctionne avec le catalogue prédéfini. Le bouton split retient la dernière couleur. MVP fonctionnel.

---

## Phase 4: User Story 2 - Surligner du texte avec une couleur de fond (Priority: P1)

**Goal**: L'administrateur peut surligner du texte avec une couleur de fond via un second bouton split identique.

**Independent Test**: Sélectionner du texte → cliquer sur le chevron du bouton surlignage → choisir une couleur pastel → le fond du texte apparaît dans la couleur choisie.

### Implementation

- [x] T012 [US2] Implémenter dans `usenghor_nuxt/app/plugins/toastui-color-plugin.ts` : la commande WYSIWYG `highlight` qui applique `schema.marks.span.create({ htmlAttrs: { style: 'background-color: {selectedColor}' } })` via `tr.addMark(from, to, mark)`, et la suppression via `tr.removeMark` quand `selectedColor` est vide
- [x] T013 [US2] Implémenter dans `usenghor_nuxt/app/plugins/toastui-color-plugin.ts` : la commande Markdown `highlight` qui encapsule le texte sélectionné dans `<span style="background-color: {selectedColor}">texte</span>`
- [x] T014 [US2] Implémenter dans `usenghor_nuxt/app/plugins/toastui-color-plugin.ts` : la création du second bouton split "Surlignage" avec icône marqueur/surligneur et la dernière couleur de surlignage en fond. L'ajouter au tableau `toolbarItems` avec `groupIndex: 0, itemIndex: 4` (après le bouton couleur). Réutiliser `createColorPickerPopup` avec mode `highlight`.

**Checkpoint**: Les deux boutons (couleur + surlignage) fonctionnent indépendamment avec le catalogue prédéfini.

---

## Phase 5: User Story 4 - Définir une couleur personnalisée (Priority: P2)

**Goal**: L'administrateur peut entrer un code hexadécimal ou utiliser un sélecteur visuel pour choisir une couleur custom.

**Independent Test**: Ouvrir le sélecteur → taper "#FF5733" dans le champ hex → valider → la couleur est appliquée. Utiliser le sélecteur visuel natif → la couleur choisie est appliquée.

### Implementation

- [x] T015 [US4] Étendre la fonction `createColorPickerPopup` dans `usenghor_nuxt/app/composables/useColorPicker.ts` : ajouter sous la grille un séparateur `<hr>` puis une section custom avec `<input type="color">` (sélecteur visuel natif), `<input type="text" placeholder="#RRGGBB">` (champ hexadécimal), et bouton "Appliquer". La saisie dans l'un met à jour l'autre en temps réel.
- [x] T016 [US4] Implémenter la validation dans `usenghor_nuxt/app/composables/useColorPicker.ts` : quand l'utilisateur tape dans le champ hex, valider avec `validateHexColor()`. Si invalide, afficher un message d'erreur inline (bordure rouge + texte "Format invalide") et désactiver le bouton "Appliquer". Si valide, activer le bouton et synchroniser avec `<input type="color">`.
- [x] T017 [US4] Ajouter les styles pour la section custom dans `usenghor_nuxt/app/components/ToastUIEditor.client.vue` : `.color-custom` (layout flex, alignement), `.color-custom input[type="color"]` (taille 32x32px, pas de bordure native), `.color-custom input[type="text"]` (champ mono, largeur fixe), état erreur `.color-custom .error`

**Checkpoint**: Le sélecteur de couleur complet est fonctionnel : catalogue prédéfini + saisie hex + sélecteur visuel natif.

---

## Phase 6: User Story 5 - Combiner couleur de texte et surlignage (Priority: P2)

**Goal**: L'administrateur peut appliquer couleur de texte ET surlignage sur le même passage.

**Independent Test**: Appliquer une couleur de texte rouge → puis un surlignage jaune sur le même mot → le texte est rouge sur fond jaune. Supprimer la couleur de texte → le surlignage reste.

### Implementation

- [x] T018 [US5] Vérifier et corriger dans `usenghor_nuxt/app/plugins/toastui-color-plugin.ts` : les commandes WYSIWYG `textColor` et `highlight` doivent préserver les marks `span` existants lors de l'ajout. Si un `<span>` a déjà un `style="color: ..."` et qu'on ajoute un `background-color`, le résultat doit être `<span style="color: ...; background-color: ...">`. Fusionner les attributs `style` plutôt que de remplacer le mark entier.
- [x] T019 [US5] Implémenter la suppression sélective dans `usenghor_nuxt/app/plugins/toastui-color-plugin.ts` : quand on supprime uniquement la couleur de texte (commande `textColor` avec `selectedColor` vide), ne retirer que l'attribut `color` du style, en préservant `background-color` s'il existe (et vice versa). Si plus aucun attribut style, supprimer le mark `span` entier.
- [x] T020 [US5] Vérifier et corriger dans `usenghor_nuxt/app/plugins/toastui-color-plugin.ts` : les commandes Markdown `textColor` et `highlight` doivent gérer le cas où le texte sélectionné contient déjà un `<span style="...">`. Parser le style existant, fusionner le nouvel attribut, et réécrire le `<span>` complet.

**Checkpoint**: La combinaison couleur + surlignage fonctionne. La suppression sélective préserve l'autre style.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Finitions et vérifications transversales

- [x] T021 [P] Vérifier la compatibilité RTL dans `usenghor_nuxt/app/components/ToastUIEditor.client.vue` : le popup doit s'aligner correctement en mode arabe (direction RTL), les pastilles de couleur doivent se lire de droite à gauche
- [x] T022 [P] Vérifier le comportement sans sélection dans `usenghor_nuxt/app/plugins/toastui-color-plugin.ts` : si aucun texte n'est sélectionné quand une couleur est choisie, ne rien appliquer (pas d'erreur, pas de span vide)
- [x] T023 [P] Vérifier la persistance dans `usenghor_nuxt/app/components/ToastUIEditor.client.vue` : sauvegarder du contenu coloré → recharger l'éditeur → les couleurs sont restituées dans l'éditeur WYSIWYG et dans le HTML émis
- [x] T024 [P] Vérifier le rendu public dans `usenghor_nuxt/app/components/RichTextRenderer.vue` : confirmer que les `<span style="color:...">` et `<span style="background-color:...">` sont rendus correctement sans modification du composant
- [x] T025 Exécuter la validation complète du quickstart.md : parcourir toutes les vérifications listées dans `specs/017-editor-text-color/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Pas de dépendances - démarrage immédiat
- **Foundational (Phase 2)**: Dépend de Phase 1 - BLOQUE toutes les user stories
- **US1+US3 (Phase 3)**: Dépend de Phase 2 - MVP
- **US2 (Phase 4)**: Dépend de Phase 2 (pas de Phase 3, mais réutilise `createColorPickerPopup` créé en Phase 3)
- **US4 (Phase 5)**: Dépend de Phase 3 (étend le popup créé en Phase 3)
- **US5 (Phase 6)**: Dépend de Phase 3 + Phase 4 (les deux commandes doivent exister)
- **Polish (Phase 7)**: Dépend de toutes les phases précédentes

### User Story Dependencies

- **US1+US3 (P1)**: Indépendant après Phase 2 - MVP complet
- **US2 (P1)**: Réutilise `createColorPickerPopup` de US1 mais commandes indépendantes
- **US4 (P2)**: Étend le popup de US1/US2
- **US5 (P2)**: Nécessite US1 ET US2 complétés

### Parallel Opportunities

- T001 et T002 (Phase 1) peuvent être parallèles
- T003 et T004 (Phase 2) peuvent être parallèles
- T007 et T008 (commandes WYSIWYG et Markdown) peuvent être parallèles
- T012 et T013 (commandes highlight) peuvent être parallèles
- T021, T022, T023, T024 (Phase 7) peuvent tous être parallèles

---

## Parallel Example: Phase 3 (US1+US3)

```text
# Séquentiel : le popup doit exister avant les boutons
Étape 1: T006 (createColorPickerPopup)
Étape 2 (parallèle): T007 + T008 (commandes WYSIWYG + Markdown)
Étape 3: T009 (bouton split toolbar - dépend de T006, T007, T008)
Étape 4 (parallèle): T010 + T011 (styles light + dark)
```

---

## Implementation Strategy

### MVP First (US1 + US3 uniquement)

1. Compléter Phase 1: Setup (T001-T002)
2. Compléter Phase 2: Foundational (T003-T005)
3. Compléter Phase 3: US1+US3 couleur de texte + catalogue (T006-T011)
4. **STOP et VALIDER**: Tester la couleur de texte avec le catalogue
5. Déployer si satisfaisant

### Incremental Delivery

1. Setup + Foundational → Infrastructure prête
2. US1+US3 → Couleur de texte avec catalogue → **MVP** 🎯
3. US2 → Surlignage avec catalogue → Feature enrichie
4. US4 → Couleurs personnalisées → Flexibilité complète
5. US5 → Combinaison → Richesse éditoriale
6. Polish → Production-ready

---

## Notes

- Feature purement frontend : 2 fichiers créés, 1-2 fichiers modifiés
- Aucune migration SQL, aucune modification backend
- Le `RichTextRenderer.vue` ne devrait pas nécessiter de modification (HTML inline rendu nativement)
- Le risque principal est la gestion des styles combinés (T018-T020) : tester tôt
- Zéro nouvelle dépendance npm
