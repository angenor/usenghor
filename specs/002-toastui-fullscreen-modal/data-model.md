# Data Model: Éditeur TOAST UI en modale plein écran

**Feature**: `002-toastui-fullscreen-modal`
**Date**: 2026-03-09

## Aucune modification de données

Cette fonctionnalité est purement UI/frontend. Aucune modification du schéma de base de données, des modèles Pydantic, ou des endpoints API n'est nécessaire.

Le pattern existant de double colonne (`*_md` + `*_html`) reste inchangé. Les données circulent de la même manière :
1. L'utilisateur édite dans la modale → le composant émet `update:modelValue` (markdown) et `update:html` (HTML)
2. Le formulaire parent reçoit ces valeurs exactement comme avant
3. Le formulaire soumet les données au backend sans changement

## Entités UI (composants Vue)

### ToastUIEditor.client.vue — Modifications

| Prop | Type | Défaut | Nouveau |
|------|------|--------|---------|
| `mode` | `'inline' \| 'modal'` | `'modal'` | Nouvelle prop |
| `label` | `string` | `''` | Nouvelle prop (titre affiché sur le bouton et dans le header modale) |

**Comportement selon le mode** :
- `mode="modal"` (défaut) : affiche un bouton avec aperçu du contenu → clic ouvre la modale plein écran
- `mode="inline"` : comportement actuel inchangé (éditeur visible directement)

### RichTextEditorModal.vue — Nouveau composant interne

Composant de modale plein écran contenant l'éditeur TOAST UI. Utilisé en interne par `ToastUIEditor.client.vue` quand `mode="modal"`.

| Prop | Type | Description |
|------|------|-------------|
| `visible` | `boolean` | Contrôle l'affichage de la modale |
| `initialMarkdown` | `string` | Contenu markdown à charger à l'ouverture |
| `label` | `string` | Titre affiché dans le header |
| `direction` | `'ltr' \| 'rtl'` | Direction du texte |
| `placeholder` | `string` | Placeholder de l'éditeur |
| `language` | `string` | Langue de l'éditeur |

| Emit | Payload | Description |
|------|---------|-------------|
| `confirm` | `{ markdown: string, html: string }` | Validation du contenu |
| `cancel` | — | Annulation (contenu non sauvegardé) |

### admin/RichTextEditor.vue — Modifications

Le wrapper multilingue affichera un bouton unique ouvrant une modale contenant les onglets FR/EN/AR + l'éditeur. Le comportement est délégué à un composant modale dédié.

| Prop | Type | Défaut | Nouveau |
|------|------|--------|---------|
| `mode` | `'inline' \| 'modal'` | `'modal'` | Nouvelle prop, transmise aux instances de ToastUIEditor |
