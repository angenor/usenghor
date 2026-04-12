# Research: 017-editor-text-color

**Date**: 2026-04-12

## Décision 1 : Approche plugin

**Decision**: Créer un plugin custom unifié (couleur de texte + surlignage) plutôt qu'utiliser le plugin officiel `@toast-ui/editor-plugin-color-syntax`.

**Rationale**:
- Le plugin officiel ne gère que la couleur de texte (`color`), pas le surlignage (`background-color`)
- Le plugin officiel utilise `tui-color-picker` qui offre un color picker HSV complet mais pas le pattern bouton split demandé
- Un plugin unifié évite le conflit sur `toHTMLRenderers.htmlInline.span` (le dernier plugin écrase le premier)
- Un plugin custom permet d'implémenter exactement le catalogue prédéfini (vives + pastels) et le bouton split

**Alternatives considérées**:
- Plugin officiel `@toast-ui/editor-plugin-color-syntax@3.1.0` + plugin custom highlight : conflit `toHTMLRenderers`, UX incohérente entre les deux sélecteurs
- Plugin officiel seul : ne couvre pas le surlignage
- Dépendance `tui-color-picker@2.2.6` pour le sélecteur visuel : ajoute ~50KB, UX non adaptée au pattern split button

## Décision 2 : Sélecteur visuel de couleur personnalisée

**Decision**: Utiliser l'élément natif `<input type="color">` du navigateur pour le sélecteur visuel personnalisé, combiné avec un champ de saisie hexadécimal.

**Rationale**:
- Zéro dépendance supplémentaire
- Supporté par tous les navigateurs modernes
- UX native et familière pour l'utilisateur
- Suffit pour le cas d'usage "couleur custom" (FR-004, FR-005) qui est P2

**Alternatives considérées**:
- `tui-color-picker@2.2.6` : dépendance lourde (~50KB), ne justifie pas pour un usage secondaire
- Composant Vue color picker custom : surcoût de développement pour un besoin secondaire
- Bibliothèque `vue-color` ou similaire : dépendance supplémentaire non justifiée

## Décision 3 : Mécanisme HTML de coloration

**Decision**: Utiliser des `<span>` avec attributs `style` inline via le mark ProseMirror `schema.marks.span` natif de TOAST UI Editor v3.

**Rationale**:
- Le mark `span` est natif dans TOAST UI v3, pas besoin de l'enregistrer
- Compatible avec le stockage `*_html` existant
- `RichTextRenderer.vue` affiche déjà du HTML brut via `v-html`, les styles inline sont rendus nativement
- Format : `<span style="color: #hex">` pour la couleur, `<span style="background-color: #hex">` pour le surlignage
- Combinaison : `<span style="color: #hex; background-color: #hex">` pour les deux

**Alternatives considérées**:
- Classes CSS prédéfinies (`.text-red`, `.bg-yellow`) : moins flexible, nécessite des CSS globaux, pas de couleurs custom
- Balises `<font color="">` : obsolète, non standard

## Décision 4 : Pattern bouton split dans la toolbar

**Decision**: Créer un élément toolbar custom (DOM element) avec deux zones cliquables : zone principale (applique dernière couleur) et flèche (ouvre popup).

**Rationale**:
- Le pattern toolbar item custom existe déjà dans le projet (bouton file upload dans `ToastUIEditor.client.vue`)
- TOAST UI v3 supporte les éléments DOM custom dans `toolbarItems` avec propriété `el`
- Le popup est géré via `eventEmitter.emit('command', ...)` et `eventEmitter.emit('closePopup')`

**Alternatives considérées**:
- Toolbar item standard avec popup uniquement : pas de bouton split, toujours 2+ clics
- Deux boutons séparés (appliquer + ouvrir picker) : consomme trop d'espace toolbar

## Décision 5 : Architecture des fichiers

**Decision**: Un composable `useColorPicker.ts` pour la logique + un plugin TOAST UI dans `plugins/toastui-color-plugin.ts`.

**Rationale**:
- Séparation claire : le plugin gère l'intégration TOAST UI (commands, toolbar), le composable gère l'état (dernière couleur, catalogue)
- Pattern cohérent avec le projet (composables existants : `useToastUIEditor.ts`, `useMediaApi.ts`)
- Le catalogue de couleurs est configurable via le composable (FR-010)

**Alternatives considérées**:
- Tout dans le plugin : mélange état applicatif et intégration éditeur
- Tout dans le composant `ToastUIEditor.client.vue` : fichier déjà à ~244 lignes, ajouterait trop de complexité
