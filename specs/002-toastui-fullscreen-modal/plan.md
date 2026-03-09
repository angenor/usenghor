# Implementation Plan: Éditeur TOAST UI en modale plein écran

**Branch**: `002-toastui-fullscreen-modal` | **Date**: 2026-03-09 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/002-toastui-fullscreen-modal/spec.md`

## Summary

Transformer l'éditeur TOAST UI Editor, actuellement intégré en inline dans les formulaires admin, en un bouton d'action ouvrant une modale plein écran (couvrant navbar, footer, et tout le viewport). L'approche consiste à ajouter une prop `mode` (`'inline' | 'modal'`) au composant `ToastUIEditor.client.vue` existant, avec `'modal'` comme valeur par défaut. Un nouveau sous-composant `RichTextEditorModal.vue` gère la modale. Seules les 3 pages utilisant l'éditeur dans une modale existante nécessitent l'ajout explicite de `mode="inline"`.

## Technical Context

**Language/Version**: TypeScript (Vue 3 / Nuxt 4)
**Primary Dependencies**: `@toast-ui/editor@3.2.2`, `@toast-ui/editor-plugin-table-merged-cell`, Tailwind CSS, `@nuxtjs/i18n`
**Storage**: N/A (fonctionnalité purement frontend, aucune modification backend/BDD)
**Testing**: Tests manuels (pas de framework de test frontend configuré dans le projet)
**Target Platform**: Navigateurs web modernes (Chrome, Firefox, Safari, Edge)
**Project Type**: Web application (monorepo Nuxt 4 frontend)
**Performance Goals**: Ouverture/fermeture modale < 500ms perçus
**Constraints**: Doit supporter dark mode, RTL (arabe), trilingue FR/EN/AR
**Scale/Scope**: ~19 pages admin concernées, 2 composants principaux à modifier, 1 nouveau composant

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Le fichier `constitution.md` contient uniquement des placeholders (pas de principes définis pour ce projet). Aucune gate de constitution à vérifier. Passage libre.

**Post-Phase 1 re-check** : Toujours conforme — aucun principe constitutionnel défini à valider.

## Project Structure

### Documentation (this feature)

```text
specs/002-toastui-fullscreen-modal/
├── plan.md              # Ce fichier
├── spec.md              # Spécification fonctionnelle
├── research.md          # Recherche et décisions techniques
├── data-model.md        # Modèle de données (composants Vue)
├── quickstart.md        # Guide de démarrage rapide
└── tasks.md             # Tâches (généré par /speckit.tasks)
```

### Source Code (repository root)

```text
usenghor_nuxt/app/
├── components/
│   ├── ToastUIEditor.client.vue          # Modifié : ajout props mode/label, logique bouton/modale
│   └── admin/
│       ├── RichTextEditor.vue            # Modifié : transmission prop mode, modale multilingue
│       └── RichTextEditorModal.vue       # Nouveau : modale plein écran avec éditeur
├── pages/admin/
│   ├── organisation/
│   │   ├── secteurs/index.vue            # Modifié : ajout mode="inline" (2 éditeurs)
│   │   └── services/index.vue            # Modifié : ajout mode="inline" (2 éditeurs)
│   └── administration/
│       └── utilisateurs/components/
│           └── UserFormModal.vue          # Modifié : ajout mode="inline" (1 éditeur)
└── composables/
    └── useToastUIEditor.ts               # Inchangé
```

**Structure Decision** : Modifications ciblées dans le dossier `usenghor_nuxt/app/`. Un seul nouveau composant (`RichTextEditorModal.vue`) dans `components/admin/` car c'est un composant d'interface admin. Le composant de base `ToastUIEditor.client.vue` reste dans `components/` (racine) car il est utilisé par les deux contextes.

## Complexity Tracking

Aucune violation de constitution à justifier (constitution non définie).
