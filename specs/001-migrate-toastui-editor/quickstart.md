# Quickstart: Migration EditorJS vers TOAST UI Editor

## Prérequis

- Node.js 20+, pnpm
- Python 3.14, Docker (PostgreSQL)
- Accès au back-office admin

## Installation des dépendances

```bash
cd usenghor_nuxt/
pnpm add @toast-ui/editor @toast-ui/editor-plugin-table-merged-cell
```

## Structure des nouveaux fichiers

```
usenghor_nuxt/app/
├── components/
│   ├── ToastUIEditor.client.vue          # Éditeur (client-only)
│   ├── RichTextRenderer.vue              # Rendu HTML public (remplace EditorJSRenderer)
│   └── admin/
│       └── RichTextEditor.vue            # Wrapper multilingue (modifié)
├── composables/
│   └── useToastUIEditor.ts               # Composable (remplace useEditorJS)
└── types/
    └── toastui-editor.d.ts               # Déclarations TypeScript

usenghor_backend/
├── documentation/modele_de_données/
│   └── migrations/
│       └── 0XX_migrate_editorjs_to_toastui.sql  # Migration SQL
├── scripts/
│   └── migrate_editorjs_to_toastui.py    # Script de conversion Python
└── app/schemas/                          # Schémas Pydantic (modifiés)
```

## Ordre d'implémentation

1. **Installer les dépendances** npm TOAST UI
2. **Créer le composant** `ToastUIEditor.client.vue`
3. **Créer le composable** `useToastUIEditor.ts`
4. **Créer le renderer** `RichTextRenderer.vue`
5. **Adapter** `RichTextEditor.vue` (wrapper multilingue)
6. **Écrire le script de conversion** Python (EditorJS JSON → HTML + Markdown)
7. **Créer la migration SQL** (nouvelles colonnes)
8. **Modifier les schémas Pydantic** backend
9. **Mettre à jour les 11 pages admin** (remplacer `<EditorJS>` par `<ToastUIEditor>`)
10. **Mettre à jour les 11 pages/composants publics** (remplacer `<EditorJSRenderer>` par `<RichTextRenderer>`)
11. **Tester** en local (édition + rendu + RTL)
12. **Déployer** en production (backup + migration + déploiement)
13. **Supprimer** EditorJS (dépendances, composants, types)

## Vérification rapide

```bash
# Frontend
cd usenghor_nuxt/ && pnpm dev
# Ouvrir http://localhost:3000/admin/contenus/actualites/nouveau
# Vérifier que l'éditeur TOAST UI s'affiche et fonctionne

# Build
pnpm build  # Doit réussir sans erreur
```

## Points d'attention

- Le composant éditeur est `.client.vue` (pas de SSR)
- L'upload d'image utilise le hook `addImageBlobHook` → endpoint `/api/admin/media/`
- Le RTL pour l'arabe nécessite un workaround CSS (TOAST UI ne le supporte pas nativement)
- Les embeds vidéo nécessitent un plugin custom ou une insertion HTML directe
