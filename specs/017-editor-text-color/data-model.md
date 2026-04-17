# Data Model: 017-editor-text-color

**Date**: 2026-04-12

## Entités

### ColorPreset (configuration statique)

Représente une couleur du catalogue prédéfini.

| Champ    | Type   | Description                          |
|----------|--------|--------------------------------------|
| hex      | string | Code hexadécimal (#RRGGBB ou #RRGGBBAA) |
| category | enum   | `vivid` ou `pastel`                  |
| label    | string | Label optionnel pour l'info-bulle    |

**Catalogue par défaut :**

Couleurs vives (11) :
`#fdbc00`, `#8bbc0a`, `#049ddf`, `#e06666`, `#c27ba0`, `#a935c6`, `#1ca2bd`, `#0a5261`, `#e95853`, `#2b4bbf`, `#f32525`

Couleurs pastels (7) :
`#ffd966`, `#93c47d`, `#a4c2f4`, `#ea9999`, `#d5a6bd`, `#b4a7d6`, `#a2c4c9`

### ColorPickerState (état runtime par bouton)

État maintenu indépendamment pour chaque bouton (couleur de texte, surlignage).

| Champ         | Type            | Description                              |
|---------------|-----------------|------------------------------------------|
| lastColor     | string \| null  | Dernière couleur utilisée (#RRGGBB)      |
| isOpen        | boolean         | Popup ouvert                             |
| mode          | enum            | `text-color` ou `highlight`              |

### Sortie HTML (stockage existant)

Pas de nouvelle table en base de données. Les couleurs sont encodées dans le HTML existant :

```html
<!-- Couleur de texte -->
<span style="color: #e06666">texte coloré</span>

<!-- Surlignage -->
<span style="background-color: #ffd966">texte surligné</span>

<!-- Combiné -->
<span style="color: #e06666; background-color: #ffd966">texte coloré et surligné</span>
```

## Relations

- **ColorPreset** → utilisé par le composant popup du sélecteur (lecture seule, configurable via props)
- **ColorPickerState** → un par bouton toolbar, persisté en mémoire uniquement (pas en base)
- **HTML output** → stocké dans les colonnes `*_html` existantes des 11 tables avec contenu riche

## Règles de validation

- Le code hexadécimal DOIT correspondre au pattern : `/^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/`
- La suppression de couleur supprime l'attribut `style` correspondant du `<span>` (ou le `<span>` entier si plus aucun style)
- Aucune migration SQL nécessaire (les colonnes `*_html` stockent déjà du HTML libre)
