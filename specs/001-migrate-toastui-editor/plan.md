# Implementation Plan: Migration EditorJS vers TOAST UI Editor

**Branch**: `001-migrate-toastui-editor` | **Date**: 2026-03-08 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-migrate-toastui-editor/spec.md`

## Summary

Remplacer l'éditeur de texte riche EditorJS par TOAST UI Editor dans l'ensemble du monorepo Usenghor (frontend Nuxt 4 + backend FastAPI). La migration couvre : le composant éditeur (admin), le composant renderer (public), le composable de gestion d'état, les schémas backend Pydantic, la migration des données en base (11 tables, ~20 colonnes), et le nettoyage des dépendances EditorJS.

**Alerte** : La recherche a révélé que TOAST UI Editor est abandonné (dernier commit août 2024) et ne supporte pas le RTL nativement. Voir [research.md](research.md) pour les détails et alternatives.

## Technical Context

**Language/Version**: TypeScript (Nuxt 4 / Vue 3), Python 3.14 (FastAPI)
**Primary Dependencies**: `@toast-ui/editor@3.2.2`, `@toast-ui/editor-plugin-table-merged-cell`, Tailwind CSS
**Storage**: PostgreSQL 16 (colonnes TEXT → double colonne HTML + Markdown)
**Testing**: Validation manuelle (pas de framework de test automatisé en place)
**Target Platform**: Web (navigateurs modernes), Docker en production
**Project Type**: Web application (monorepo frontend + backend)
**Performance Goals**: Éditeur chargé en < 3 secondes
**Constraints**: Site en production, migration big-bang avec fenêtre de maintenance, pas d'accents dans les noms de fichiers
**Scale/Scope**: 11 tables DB, 11 pages admin, 11 pages/composants publics, 13 paquets npm à supprimer

## Constitution Check

*Pas de constitution configurée. Aucun gate applicable.*

## Project Structure

### Documentation (this feature)

```text
specs/001-migrate-toastui-editor/
├── spec.md              # Spécification
├── plan.md              # Ce fichier
├── research.md          # Recherche TOAST UI + alternatives
├── data-model.md        # Changements de schéma DB
├── quickstart.md        # Guide de démarrage rapide
├── contracts/
│   ├── editor-component.md  # Interface composant Vue + composable
│   └── backend-schema.md    # Changements schémas Pydantic
└── checklists/
    └── requirements.md  # Checklist qualité spec
```

### Source Code (repository root)

```text
usenghor_nuxt/app/
├── components/
│   ├── ToastUIEditor.client.vue          # NOUVEAU - Éditeur TOAST UI (client-only)
│   ├── RichTextRenderer.vue              # NOUVEAU - Rendu HTML public
│   ├── admin/
│   │   └── RichTextEditor.vue            # MODIFIÉ - Wrapper multilingue
│   ├── EditorJS.vue                      # SUPPRIMÉ (phase cleanup)
│   ├── EditorJSRenderer.vue              # SUPPRIMÉ (phase cleanup)
│   └── editorjs/MergeTable/              # SUPPRIMÉ (phase cleanup)
├── composables/
│   ├── useToastUIEditor.ts               # NOUVEAU (remplace useEditorJS.ts)
│   └── useEditorJS.ts                    # SUPPRIMÉ (phase cleanup)
├── types/
│   ├── toastui-editor.d.ts               # NOUVEAU
│   └── editorjs.d.ts                     # SUPPRIMÉ (phase cleanup)
└── pages/admin/                          # 11 pages MODIFIÉES

usenghor_backend/
├── app/schemas/                          # MODIFIÉ (champs *_html + *_md)
├── documentation/modele_de_données/
│   └── migrations/
│       └── 0XX_migrate_editorjs_to_toastui.sql  # NOUVEAU
└── scripts/
    └── migrate_editorjs_to_toastui.py    # NOUVEAU - Script conversion
```

**Structure Decision**: Monorepo existant (frontend Nuxt 4 + backend FastAPI). Pas de nouveau dossier racine. Les nouveaux fichiers s'intègrent dans la structure existante.

## Complexity Tracking

| Risque | Impact | Mitigation |
|--------|--------|------------|
| TOAST UI abandonné | Pas de correctifs futurs | Envisager pivot vers Tiptap si problèmes critiques |
| RTL non supporté nativement | Arabe mal géré dans l'éditeur | Workaround CSS + tests manuels approfondis |
| 20 colonnes à migrer | Script de migration complexe | Script Python avec validation + backup intégral |
| Double colonne HTML+MD | Volumétrie DB doublée | Impact négligeable pour du contenu éditorial (quelques Mo) |
