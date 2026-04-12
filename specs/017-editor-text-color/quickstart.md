# Quickstart: 017-editor-text-color

**Date**: 2026-04-12

## Prérequis

- Node.js 18+, pnpm
- Projet `usenghor_nuxt` fonctionnel (`pnpm dev` sur http://localhost:3000)
- Backend démarré (`uvicorn app.main:app --reload` sur http://localhost:8000)

## Fichiers à créer

```
usenghor_nuxt/
├── app/
│   ├── plugins/
│   │   └── toastui-color-plugin.ts     # Plugin TOAST UI (commands + toolbar items)
│   └── composables/
│       └── useColorPicker.ts            # État du color picker (catalogue, dernière couleur)
```

## Fichiers à modifier

```
usenghor_nuxt/
├── app/
│   ├── components/
│   │   └── ToastUIEditor.client.vue     # Import et activation du plugin
│   └── assets/css/
│       └── main.css                      # Styles du popup color picker (ou scoped dans le composant)
```

## Aucun fichier backend modifié

Cette feature est purement frontend. Le HTML inline (`<span style="...">`) est déjà compatible avec le stockage `*_html` existant et le `RichTextRenderer.vue`.

## Démarrage rapide

```bash
cd usenghor_nuxt
pnpm dev
```

1. Ouvrir http://localhost:3000 et naviguer vers une page admin avec éditeur rich text
2. Vérifier la présence des deux nouveaux boutons dans la toolbar de l'éditeur
3. Sélectionner du texte → cliquer sur le bouton couleur → vérifier l'application
4. Sauvegarder → vérifier le rendu public via `RichTextRenderer`

## Vérifications

- [ ] Les deux boutons split apparaissent dans la toolbar
- [ ] Le popup affiche le catalogue (vives + pastels)
- [ ] Un clic sur une pastille applique la couleur
- [ ] Le champ hex accepte un code valide
- [ ] Le sélecteur visuel (`<input type="color">`) fonctionne
- [ ] Le bouton split retient la dernière couleur
- [ ] Les couleurs persistent après sauvegarde
- [ ] Le rendu public affiche les couleurs correctement
- [ ] Dark mode : les popups sont lisibles
- [ ] RTL : les popups s'alignent correctement
