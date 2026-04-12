# Implementation Plan: Coloration de texte et surlignage dans l'éditeur

**Branch**: `017-editor-text-color` | **Date**: 2026-04-12 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/017-editor-text-color/spec.md`

## Summary

Ajout de la coloration de texte et du surlignage dans l'éditeur TOAST UI via un plugin custom unifié. Deux boutons split dans la toolbar (couleur de texte + surlignage) avec catalogue de 18 couleurs prédéfinies (vives/pastels), saisie hexadécimale, et sélecteur visuel natif. Les couleurs sont encodées en HTML inline (`<span style="...">`) compatible avec le stockage et le rendu existants.

## Technical Context

**Language/Version**: TypeScript 5.x (Nuxt 4 / Vue 3 Composition API)
**Primary Dependencies**: `@toast-ui/editor@3.2.2`, `@toast-ui/editor-plugin-table-merged-cell@3.1.0` (existants)
**Storage**: N/A (HTML inline dans colonnes `*_html` existantes, aucune migration SQL)
**Testing**: Manuel (vérification visuelle dans l'éditeur + rendu public)
**Target Platform**: Navigateurs web modernes (Chrome, Firefox, Safari, Edge)
**Project Type**: Web application (frontend Nuxt 4)
**Performance Goals**: Ouverture du popup < 100ms, application de couleur instantanée
**Constraints**: Zéro nouvelle dépendance npm, compatible dark mode + RTL
**Scale/Scope**: ~11 pages admin utilisent l'éditeur, ~11 tables avec contenu riche

## Constitution Check

*GATE: Constitution non remplie (template par défaut). Aucun gate bloquant.*

## Project Structure

### Documentation (this feature)

```text
specs/017-editor-text-color/
├── plan.md              # Ce fichier
├── spec.md              # Spécification
├── research.md          # Recherche Phase 0
├── data-model.md        # Modèle de données Phase 1
├── quickstart.md        # Guide démarrage Phase 1
├── checklists/
│   └── requirements.md  # Checklist qualité
└── tasks.md             # Tâches (généré par /speckit.tasks)
```

### Source Code (repository root)

```text
usenghor_nuxt/app/
├── plugins/
│   └── toastui-color-plugin.ts          # NOUVEAU - Plugin TOAST UI unifié
├── composables/
│   └── useColorPicker.ts                # NOUVEAU - État et catalogue couleurs
├── components/
│   └── ToastUIEditor.client.vue         # MODIFIÉ - Import du plugin
└── assets/css/
    └── main.css                          # MODIFIÉ - Styles popup (si nécessaire)
```

**Structure Decision**: Feature purement frontend, 2 fichiers créés + 1-2 fichiers modifiés. Pas de backend, pas de migration SQL.

## Architecture détaillée

### Plugin TOAST UI (`toastui-color-plugin.ts`)

Responsabilités :
- Enregistrer 2 commandes Markdown (`textColor`, `highlight`) et 2 commandes WYSIWYG
- Créer 2 toolbar items custom (boutons split avec popup)
- Gérer le `toHTMLRenderers.htmlInline.span` pour le rendu preview
- Communiquer avec le popup via `eventEmitter`

Structure du plugin :
```
export default function colorPlugin(context, options) → PluginInfo {
  markdownCommands: { textColor, highlight }
  wysiwygCommands: { textColor, highlight }
  toolbarItems: [textColorButton, highlightButton]
  toHTMLRenderers: { htmlInline: { span } }
}
```

### Composable (`useColorPicker.ts`)

Responsabilités :
- Définir le catalogue de couleurs par défaut (vives + pastels)
- Exposer la configuration pour surcharge (FR-010)
- Gérer l'état "dernière couleur" par mode (text-color / highlight)
- Fournir la validation hexadécimale
- Créer le DOM du popup (grille de couleurs + champ hex + input type="color")

### Bouton split (DOM custom)

Structure HTML du bouton toolbar :
```
<span class="color-split-btn">
  <button class="color-apply" style="border-bottom: 3px solid {lastColor}">
    A (ou icône surlignage)
  </button>
  <button class="color-dropdown">▾</button>
</span>
```

- Clic sur `.color-apply` → `eventEmitter.emit('command', 'textColor', { selectedColor: lastColor })`
- Clic sur `.color-dropdown` → ouvre le popup

### Popup color picker (DOM)

Structure :
```
<div class="color-picker-popup">
  <div class="color-section">
    <label>Couleurs vives</label>
    <div class="color-grid"><!-- 11 pastilles --></div>
  </div>
  <div class="color-section">
    <label>Couleurs pastels</label>
    <div class="color-grid"><!-- 7 pastilles --></div>
  </div>
  <hr>
  <div class="color-custom">
    <input type="color" />
    <input type="text" placeholder="#RRGGBB" />
    <button>Appliquer</button>
  </div>
  <button class="color-remove">Supprimer la couleur</button>
</div>
```

## Risques et mitigations

| Risque | Impact | Mitigation |
|--------|--------|------------|
| Le mark `span` natif de TOAST UI ne supporte pas les styles combinés (color + background-color) | Haut | Tester en premier ; si nécessaire, utiliser deux `<span>` imbriqués |
| Le popup TOAST UI ne supporte pas le pattern split button nativement | Moyen | Créer le bouton comme élément DOM custom (pattern déjà utilisé pour le bouton file upload) |
| Conflit entre styles inline et dark mode | Bas | Les couleurs choisies explicitement par l'utilisateur priment sur le thème (comportement attendu) |
| `removeMark` supprime tous les marks `span` (couleur ET surlignage) | Haut | Vérifier si ProseMirror permet de cibler un mark `span` par ses attributs ; sinon, remplacer le mark avec seulement l'attribut restant |

## Complexity Tracking

Aucune violation de constitution à justifier (constitution non remplie).
