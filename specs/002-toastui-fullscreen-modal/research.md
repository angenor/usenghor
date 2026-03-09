# Research: Éditeur TOAST UI en modale plein écran

**Feature**: `002-toastui-fullscreen-modal`
**Date**: 2026-03-09

## R1: Architecture d'encapsulation — modifier les composants existants vs nouveau wrapper

**Decision**: Ajouter une prop `mode` au composant `ToastUIEditor.client.vue` (`mode: 'inline' | 'modal'`, défaut `'modal'`) et créer un composant interne `RichTextEditorModal.vue` pour la modale plein écran. Le composant `RichTextEditor.vue` (wrapper multilingue) sera mis à jour pour utiliser le nouveau mode.

**Rationale**: En ajoutant une prop au composant existant, les 3 cas d'usage dans des modales existantes passent simplement `mode="inline"` et aucune autre page consommatrice ne change (le défaut étant `'modal'`). Le nouveau composant modale est un sous-composant interne, pas un remplacement.

**Alternatives considered**:
- Créer un composant wrapper séparé `ToastUIEditorModal.vue` — rejeté car il faudrait modifier toutes les ~15 pages consommatrices
- Modifier uniquement `RichTextEditor.vue` — rejeté car certaines pages utilisent `ToastUIEditor` directement sans le wrapper multilingue

## R2: Gestion du scroll body quand la modale est ouverte

**Decision**: Ajouter `overflow: hidden` sur `document.body` à l'ouverture et le restaurer à la fermeture. Utiliser un composable `useBodyScrollLock()` ou une simple paire de fonctions dans le composant modale.

**Rationale**: Approche standard et légère. Le projet utilise Lenis pour le smooth scroll, mais `overflow: hidden` sur body suffit à empêcher le scroll natif. Lenis est déjà géré par `data-lenis-prevent` dans les modales existantes.

**Alternatives considered**:
- Utiliser une librairie dédiée (body-scroll-lock) — rejeté, trop lourd pour un cas simple
- Désactiver Lenis programmatiquement — plus complexe et fragile

## R3: Détection de contenu modifié pour la confirmation d'annulation

**Decision**: Comparer le markdown initial (snapshot au moment de l'ouverture) avec le markdown actuel au moment de la fermeture. Utiliser `window.confirm()` natif si différent.

**Rationale**: Simple et fiable. Le markdown est la source de vérité pour l'édition. Le `confirm()` natif est cohérent avec l'assumption de la spec et évite un composant dialogue supplémentaire.

**Alternatives considered**:
- Comparer le HTML — plus fragile car le HTML peut varier pour un même contenu markdown
- Composant dialogue custom — rejeté par la spec (assumption : dialogue natif)

## R4: Z-index de la modale plein écran

**Decision**: Utiliser `z-[9999]` (Tailwind arbitrary value) pour la modale plein écran. Les modales existantes du projet utilisent `z-50`. La navbar et le footer utilisent des z-index inférieurs.

**Rationale**: Garantit que la modale plein écran est au-dessus de tout, y compris des modales existantes (dans le cas improbable d'un appel depuis une modale, le mode inline est censé être utilisé, mais c'est une sécurité).

**Alternatives considered**:
- `z-[100]` — suffisant dans la plupart des cas mais pas garanti si d'autres overlays sont ajoutés plus tard

## R5: Initialisation de l'éditeur TOAST UI dans la modale

**Decision**: Créer l'instance de l'éditeur TOAST UI à l'ouverture de la modale (`v-if` sur la modale), passer le contenu markdown initial via la prop `modelValue`. Détruire l'instance à la fermeture.

**Rationale**: L'éditeur TOAST UI nécessite un élément DOM monté. Le `v-if` garantit un cycle de vie propre. Le contenu existant est passé via les props standards. Cela évite les problèmes de redimensionnement d'un éditeur caché.

**Alternatives considered**:
- Garder l'éditeur monté en permanence et le déplacer dans la modale via Teleport — fragile, TOAST UI n'aime pas le déplacement DOM
- `v-show` au lieu de `v-if` — gaspille des ressources et pose des problèmes de hauteur

## R6: Hauteur de l'éditeur dans la modale plein écran

**Decision**: L'éditeur dans la modale utilise `height: calc(100vh - <header-height>)` où `<header-height>` est la hauteur de l'en-tête de la modale (titre + boutons). Estimer ~64px pour le header.

**Rationale**: L'éditeur TOAST UI accepte une prop `height` en CSS. Le `calc()` permet de remplir tout l'espace restant sous le header de la modale.

**Alternatives considered**:
- Flexbox avec `flex-1` — nécessiterait de modifier le composant TOAST UI pour qu'il accepte `height: 100%` et que son conteneur soit flex, ce qui est plus complexe

## R7: Pages concernées et stratégie de migration

**Decision**: Classer les pages en 3 catégories :

### Catégorie A — Éditeur dans une modale existante (garder inline, ajouter `mode="inline"`)
1. `app/pages/admin/organisation/secteurs/index.vue` (2 éditeurs)
2. `app/pages/admin/organisation/services/index.vue` (2 éditeurs)
3. `app/pages/admin/administration/utilisateurs/components/UserFormModal.vue` (1 éditeur)

### Catégorie B — Utilisation directe de ToastUIEditor (comportement modal automatique)
4. `app/pages/admin/campus/liste/nouveau.vue` (1 éditeur)
5. `app/pages/admin/campus/liste/[id]/edit.vue` (1 éditeur)

### Catégorie C — Utilisation via RichTextEditor wrapper (comportement modal automatique)
6. `app/pages/admin/formations/programmes/nouveau.vue`
7. `app/pages/admin/formations/programmes/[id]/edit.vue`
8. `app/pages/admin/candidatures/appels/nouveau.vue`
9. `app/pages/admin/candidatures/appels/[id]/edit.vue`
10. `app/pages/admin/projets/appels/nouveau.vue`
11. `app/pages/admin/projets/appels/[id]/edit.vue`
12. `app/pages/admin/projets/liste/nouveau.vue`
13. `app/pages/admin/projets/liste/[id]/edit.vue`
14. `app/pages/admin/contenus/evenements/nouveau.vue`
15. `app/pages/admin/contenus/evenements/[id]/edit.vue`
16. `app/pages/admin/contenus/actualites/nouveau.vue`
17. `app/pages/admin/contenus/actualites/[id]/edit.vue`
18. `app/pages/profil/index.vue`
19. `app/pages/admin/register.vue`

**Rationale**: En changeant le défaut à `mode="modal"`, seules les 3 pages de catégorie A nécessitent une modification (ajout de `mode="inline"`). Les catégories B et C obtiennent le nouveau comportement automatiquement.
