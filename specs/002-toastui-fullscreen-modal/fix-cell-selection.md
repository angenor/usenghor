# Fix : Sélection de cellules TOAST UI Editor

## Problème

Impossible de sélectionner des cellules de tableau par glisser-déposer dans l'éditeur TOAST UI. La fonctionnalité "Fusionner les cellules" du plugin `table-merged-cell` était donc inutilisable.

## Cause racine

**Incompatibilité ES5/ES6 entre TOAST UI Editor et ProseMirror.**

TOAST UI Editor 3.2.2 est transpilé en **ES5**. Il utilise un pattern d'héritage classique :

```javascript
var CellSelection = (function (_super) {
  __extends$1(CellSelection, _super);
  function CellSelection(ranges) {
    return _super.call(this, ranges[0].$from, ranges[0].$to, ranges) || this;
  }
  // ...
})(Selection);
```

Or, les packages ProseMirror modernes (>= 1.4.0) exportent des **classes ES6 natives** :

```javascript
class Selection { constructor(...) { ... } }
```

En JavaScript, il est **impossible** d'appeler le constructeur d'une classe ES6 avec `.call()` ou `.apply()`. L'appel `_super.call(this, ...)` échoue avec :

```
TypeError: Class constructor Selection cannot be invoked without 'new'
```

### Deux problèmes distincts

1. **`CellSelection` extends `Selection`** (prosemirror-state) — La classe responsable de la sélection multi-cellules hérite de `Selection` via ES5, ce qui échoue silencieusement.

2. **`Transaction` extends `Transform`** (prosemirror-state@1.3.4 → prosemirror-transform@1.11.0) — pnpm résolvait `prosemirror-state@1.3.4` (ES5, requis par TOAST UI `^1.3.4`) en parallèle de `prosemirror-transform@1.11.0` (ES6). La classe ES5 `Transaction` tentait d'étendre la classe ES6 `Transform`.

## Solution

Deux modifications dans `package.json`, section `pnpm` :

```json
"pnpm": {
  "overrides": {
    "prosemirror-state": "^1.4.4"
  },
  "patchedDependencies": {
    "@toast-ui/editor@3.2.2": "patches/@toast-ui__editor@3.2.2.patch"
  }
}
```

### 1. Override de prosemirror-state (`pnpm.overrides`)

Force **toutes** les dépendances (y compris TOAST UI) à utiliser `prosemirror-state@^1.4.4` (ES6 natif). Cela élimine la version 1.3.4 (ES5) qui causait le crash `Transaction extends Transform`.

### 2. Patch de TOAST UI Editor (`pnpm.patchedDependencies`)

Le fichier `patches/@toast-ui__editor@3.2.2.patch` convertit la classe `CellSelection` de la syntaxe ES5 vers ES6 natif dans le bundle ESM (`dist/esm/index.js`).

**Avant (ES5)** :
```javascript
var CellSelection = (function (_super) {
  __extends$1(CellSelection, _super);
  function CellSelection(ranges) {
    return _super.call(this, ranges[0].$from, ranges[0].$to, ranges) || this;
  }
  CellSelection.prototype.map = function (doc, mapping) { ... };
  CellSelection.prototype.content = function () { ... };
  // ...
})(Selection);
```

**Après (ES6)** :
```javascript
var CellSelection = class extends Selection {
  constructor(ranges) {
    super(ranges[0].$from, ranges[0].$to, ranges);
    // ...
  }
  map(doc, mapping) { ... }
  content() { ... }
  // ...
};
```

### Application du patch

```bash
cd usenghor_nuxt/
pnpm install   # Applique automatiquement l'override et le patch
```

## Fichiers modifiés

| Fichier | Modification |
|---------|-------------|
| `usenghor_nuxt/package.json` | Ajout `pnpm.overrides` et `pnpm.patchedDependencies` |
| `usenghor_nuxt/patches/@toast-ui__editor@3.2.2.patch` | Nouveau fichier — patch ESM convertissant `CellSelection` en ES6 |

## Pourquoi ça marchait ailleurs

Dans d'autres projets ou dans la démo officielle de TOAST UI, les versions de ProseMirror résolues sont plus anciennes (toutes en ES5), donc l'héritage `__extends$1` fonctionne sans problème. Le conflit n'apparaît que lorsque pnpm résout des versions modernes (ES6) de ProseMirror.
