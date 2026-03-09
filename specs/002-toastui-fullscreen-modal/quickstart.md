# Quickstart: Éditeur TOAST UI en modale plein écran

**Feature**: `002-toastui-fullscreen-modal`
**Date**: 2026-03-09

## Prérequis

- Node.js, pnpm installés
- Projet `usenghor_nuxt/` fonctionnel (cf. CLAUDE.md)

## Lancer le projet

```bash
cd usenghor_nuxt
pnpm install
pnpm dev
```

## Fichiers à modifier

### 1. Composant principal — `app/components/ToastUIEditor.client.vue`
- Ajouter la prop `mode: 'inline' | 'modal'` (défaut `'modal'`)
- Ajouter la prop `label: string`
- En mode `modal` : rendre un bouton avec aperçu au lieu de l'éditeur inline
- Au clic : ouvrir la modale plein écran via `RichTextEditorModal`

### 2. Nouveau composant — `app/components/admin/RichTextEditorModal.vue`
- Modale plein écran (`position: fixed`, `inset-0`, `z-[9999]`)
- Header : titre du champ + boutons Valider/Annuler
- Body : éditeur TOAST UI avec `height: calc(100vh - 64px)`
- Gestion Échap, confirmation si contenu modifié, scroll lock

### 3. Wrapper multilingue — `app/components/admin/RichTextEditor.vue`
- Ajouter prop `mode` passée aux instances de ToastUIEditor
- En mode modal : un seul bouton ouvre la modale avec onglets langue à l'intérieur

### 4. Pages exception (mode inline) — 3 fichiers
- `app/pages/admin/organisation/secteurs/index.vue` → ajouter `mode="inline"` aux 2 éditeurs
- `app/pages/admin/organisation/services/index.vue` → ajouter `mode="inline"` aux 2 éditeurs
- `app/pages/admin/administration/utilisateurs/components/UserFormModal.vue` → ajouter `mode="inline"` au 1 éditeur

## Tester

1. Aller sur une page admin avec éditeur riche (ex. `/admin/contenus/actualites/nouveau`)
2. Vérifier que le bouton d'édition est visible avec le label du champ
3. Cliquer → la modale plein écran s'ouvre avec l'éditeur
4. Saisir du contenu, cliquer Valider → la modale se ferme, le contenu est dans le formulaire
5. Rouvrir, modifier, cliquer Annuler → confirmation demandée
6. Tester Échap → même comportement que Annuler
7. Tester sur une page multilingue → onglets FR/EN/AR dans la modale
8. Tester sur secteurs/services → l'éditeur reste inline (dans la modale existante)
9. Tester le dark mode et le RTL arabe
