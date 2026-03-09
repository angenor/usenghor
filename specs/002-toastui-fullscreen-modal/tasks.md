# Tasks: Éditeur TOAST UI en modale plein écran

**Input**: Design documents from `/specs/002-toastui-fullscreen-modal/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md

**Tests**: Aucun framework de test frontend configuré. Validation manuelle selon quickstart.md.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Frontend**: `usenghor_nuxt/app/` (Nuxt 4 monorepo)
- **Components**: `usenghor_nuxt/app/components/`
- **Pages admin**: `usenghor_nuxt/app/pages/admin/`

---

## Phase 1: Setup

**Purpose**: Aucune initialisation nécessaire — le projet existe et fonctionne déjà.

*(Pas de tâches dans cette phase)*

---

## Phase 2: Foundational (Composant modale plein écran)

**Purpose**: Créer le composant modale plein écran réutilisable, prérequis pour toutes les user stories.

**⚠️ CRITICAL**: Aucune user story ne peut commencer avant que cette phase soit terminée.

- [x] T001 Créer le composant modale plein écran dans `usenghor_nuxt/app/components/admin/RichTextEditorModal.vue` — Overlay `position: fixed inset-0 z-[9999]` avec fond sombre, header contenant le titre du champ (prop `label`) et deux boutons (Valider avec icône check, Annuler avec icône X), body contenant un slot ou un `ToastUIEditor` avec `height: calc(100vh - 64px)`. Le backdrop ne ferme PAS la modale (FR-013). Ajouter `overflow: hidden` sur `document.body` à l'ouverture, restaurer à la fermeture (FR-012). Gérer la touche Échap pour déclencher l'annulation (FR-006). À la fermeture par annulation : comparer le markdown actuel avec le snapshot initial, si différent afficher `window.confirm()` avant de fermer. Émettre `confirm` avec `{ markdown, html }` ou `cancel`. Supporter la prop `direction` pour le RTL. Supporter le dark mode via les classes Tailwind `dark:`.

**Checkpoint**: Le composant modale existe, peut être instancié avec un éditeur TOAST UI fonctionnel en plein écran.

---

## Phase 3: User Story 1+2 — Ouvrir, éditer, sauvegarder/annuler (Priority: P1) 🎯 MVP

**Goal**: Remplacer l'éditeur inline par un bouton qui ouvre la modale plein écran. L'utilisateur peut éditer, valider (contenu synchronisé au formulaire) ou annuler.

**Independent Test**: Aller sur `/admin/campus/liste/nouveau`, vérifier que le bouton apparaît, cliquer → modale plein écran, saisir du texte, Valider → contenu dans le formulaire. Annuler → confirmation si modifié.

### Implementation for User Story 1+2

- [x] T002 [US1] Ajouter les props `mode` (`'inline' | 'modal'`, défaut `'modal'`) et `label` (`string`, défaut `''`) au composant `usenghor_nuxt/app/components/ToastUIEditor.client.vue` — Ajouter à l'interface Props et aux withDefaults.

- [x] T003 [US1] Implémenter le rendu conditionnel dans `usenghor_nuxt/app/components/ToastUIEditor.client.vue` — En mode `'modal'` : ne PAS rendre l'éditeur inline. À la place, rendre un bouton d'action stylisé (bordure pointillée, icône d'édition, label du champ). Ajouter un état réactif `isModalOpen` (ref boolean). Au clic du bouton : `isModalOpen = true`. Rendre `<RichTextEditorModal>` avec `v-if="isModalOpen"` en passant le `modelValue` actuel comme `initialMarkdown`, le `label`, la `direction`, le `placeholder` et la `language`. En mode `'inline'` : garder le comportement actuel inchangé (l'éditeur est rendu directement).

- [x] T004 [US1] Implémenter la synchronisation du contenu dans `usenghor_nuxt/app/components/ToastUIEditor.client.vue` — Sur l'événement `confirm` de la modale : récupérer `{ markdown, html }`, émettre `update:modelValue` avec le markdown et `update:html` avec le HTML, fermer la modale (`isModalOpen = false`). Sur l'événement `cancel` : fermer la modale sans émettre. Le contenu du formulaire parent reste inchangé.

- [x] T005 [P] [US1] Ajouter `mode="inline"` aux 2 instances de ToastUIEditor dans `usenghor_nuxt/app/pages/admin/organisation/secteurs/index.vue` — Ajouter la prop `mode="inline"` aux deux `<ToastUIEditor>` (description et mission) pour qu'ils restent inline dans la modale existante.

- [x] T006 [P] [US1] Ajouter `mode="inline"` aux 2 instances de ToastUIEditor dans `usenghor_nuxt/app/pages/admin/organisation/services/index.vue` — Ajouter la prop `mode="inline"` aux deux `<ToastUIEditor>` (description et mission).

- [x] T007 [P] [US1] Ajouter `mode="inline"` à l'instance de ToastUIEditor dans `usenghor_nuxt/app/pages/admin/administration/utilisateurs/components/UserFormModal.vue` — Ajouter la prop `mode="inline"` au `<ToastUIEditor>` (biographie).

**Checkpoint**: L'éditeur s'ouvre en modale plein écran sur toutes les pages avec usage direct (campus nouveau/edit), et reste inline dans les 3 modales existantes (secteurs, services, utilisateurs). Le contenu est synchronisé correctement.

---

## Phase 4: User Story 4 — Compatibilité wrapper multilingue RichTextEditor (Priority: P1)

**Goal**: Le composant RichTextEditor (wrapper FR/EN/AR) affiche un bouton unique qui ouvre la modale avec les onglets de langue à l'intérieur. Le RTL arabe fonctionne.

**Independent Test**: Aller sur `/admin/contenus/actualites/nouveau`, cliquer sur le bouton d'édition du contenu riche, la modale s'ouvre avec onglets FR/EN/AR, saisir du contenu dans chaque onglet, Valider → les 3 contenus sont dans le formulaire.

### Implementation for User Story 4

- [x] T008 [US4] Ajouter la prop `mode` au composant `usenghor_nuxt/app/components/admin/RichTextEditor.vue` — Ajouter `mode: 'inline' | 'modal'` avec défaut `'modal'` aux Props et withDefaults. En mode `'inline'`, le comportement actuel est préservé (éditeurs inline avec onglets).

- [x] T009 [US4] Implémenter le mode modal dans `usenghor_nuxt/app/components/admin/RichTextEditor.vue` — En mode `'modal'` : remplacer le rendu des éditeurs par un bouton unique (même style que T003). Ajouter un état `isModalOpen`. Au clic : ouvrir une modale plein écran (réutiliser le layout de `RichTextEditorModal.vue` ou créer un variant multilingue). Dans la modale : afficher les onglets FR/EN/AR existants avec les `<ToastUIEditor mode="inline">` à l'intérieur (les éditeurs sont inline DANS la modale). Le header de la modale contient le titre (prop `title`), les boutons Valider/Annuler. À la validation : émettre les 6 events (md+html pour FR, EN, AR) avec les valeurs actuelles des éditeurs. À l'annulation : confirmer si modifié, puis fermer sans émettre. Gérer Échap et scroll lock comme dans `RichTextEditorModal.vue`.

**Checkpoint**: Toutes les ~11 pages utilisant RichTextEditor fonctionnent avec le nouveau comportement modal. Les onglets FR/EN/AR sont dans la modale, le RTL arabe fonctionne.

---

## Phase 5: User Story 3 — Prévisualisation du contenu sur le bouton (Priority: P2)

**Goal**: Le bouton d'édition affiche un aperçu du contenu existant (extrait texte brut) ou une indication "Aucun contenu" si vide.

**Independent Test**: Charger un formulaire d'édition avec du contenu existant (ex. `/admin/campus/liste/[id]/edit`), vérifier que l'aperçu du contenu est visible sur le bouton.

### Implementation for User Story 3

- [x] T010 [US3] Ajouter l'aperçu de contenu au bouton dans `usenghor_nuxt/app/components/ToastUIEditor.client.vue` — Dans le template du bouton (mode `'modal'`), ajouter un texte d'aperçu : si `modelValue` est non vide, afficher les ~100 premiers caractères du markdown en texte brut (strip les balises markdown basiques), tronqué avec `...`. Si `modelValue` est vide, afficher "Aucun contenu" en gris italique. Limiter l'aperçu à 2 lignes max (`line-clamp-2`).

- [x] T011 [US3] Ajouter l'aperçu de contenu au bouton dans `usenghor_nuxt/app/components/admin/RichTextEditor.vue` — Dans le template du bouton (mode `'modal'`), afficher un aperçu du contenu français (`modelValue`) avec la même logique que T010. Si le contenu français est vide mais d'autres langues ont du contenu, afficher "Contenu disponible en [EN/AR]" à la place.

**Checkpoint**: Tous les boutons d'édition affichent un aperçu pertinent du contenu ou "Aucun contenu".

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Vérifications finales et ajustements

- [ ] T012 Vérifier le dark mode sur la modale plein écran dans `usenghor_nuxt/app/components/admin/RichTextEditorModal.vue` — Tester visuellement en dark mode : fond de la modale, header, boutons, éditeur TOAST UI. Ajuster les classes Tailwind `dark:` si nécessaire. L'éditeur TOAST UI a déjà des styles dark mode dans `ToastUIEditor.client.vue`.

- [ ] T013 Vérifier le RTL arabe dans la modale multilingue — Ouvrir la modale multilingue, basculer sur l'onglet arabe, vérifier que l'éditeur est en RTL (texte aligné à droite, listes inversées, blockquotes à droite). Les styles RTL existants dans `ToastUIEditor.client.vue` doivent s'appliquer automatiquement.

- [ ] T014 Validation complète selon `specs/002-toastui-fullscreen-modal/quickstart.md` — Suivre les 9 scénarios de test du quickstart.md et valider chacun.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 2)**: Pas de dépendance — peut commencer immédiatement
- **US1+US2 (Phase 3)**: Dépend de Phase 2 (T001 doit être terminé)
- **US4 (Phase 4)**: Dépend de Phase 2 (T001). Peut être fait en parallèle de Phase 3.
- **US3 (Phase 5)**: Dépend de Phase 3 (T003 — le bouton doit exister) et Phase 4 (T009)
- **Polish (Phase 6)**: Dépend de toutes les phases précédentes

### User Story Dependencies

- **US1+US2 (P1)**: Dépend uniquement de la fondation (T001). MVP autonome.
- **US4 (P1)**: Dépend de T001. Peut être implémenté en parallèle de US1+US2 car travaille sur un fichier différent (`RichTextEditor.vue` vs `ToastUIEditor.client.vue`).
- **US3 (P2)**: Dépend de US1+US2 et US4 (les boutons doivent exister pour y ajouter l'aperçu).

### Within Each User Story

- Props et types d'abord → rendu conditionnel → logique de synchronisation → pages exception
- T005, T006, T007 sont parallélisables entre eux (fichiers différents)

### Parallel Opportunities

- T005, T006, T007 peuvent tous être exécutés en parallèle (3 fichiers d'exception différents)
- Phase 3 (US1+US2) et Phase 4 (US4) peuvent être exécutées en parallèle (fichiers différents)
- T010 et T011 peuvent être exécutés en parallèle (2 fichiers différents)
- T012 et T013 peuvent être exécutés en parallèle (vérifications indépendantes)

---

## Parallel Example: Phase 3 (US1+US2)

```bash
# Séquentiel (dépendances) :
T002 → T003 → T004 (même fichier ToastUIEditor.client.vue)

# Parallèle (fichiers différents, après T002-T004) :
T005: secteurs/index.vue (mode="inline")
T006: services/index.vue (mode="inline")
T007: UserFormModal.vue (mode="inline")
```

## Parallel Example: Phase 3 + Phase 4

```bash
# En parallèle (fichiers différents) :
Développeur A: T002 → T003 → T004 (ToastUIEditor.client.vue)
Développeur B: T008 → T009 (RichTextEditor.vue)
```

---

## Implementation Strategy

### MVP First (US1+US2 Only)

1. Compléter Phase 2 : T001 (RichTextEditorModal.vue)
2. Compléter Phase 3 : T002-T007 (ToastUIEditor + pages exception)
3. **STOP et VALIDER** : L'éditeur s'ouvre en modale sur les pages avec usage direct (campus)
4. Les pages multilingues restent inchangées pour l'instant (l'éditeur est inline par défaut dans RichTextEditor)

### Incremental Delivery

1. T001 → Fondation prête
2. T002-T007 → US1+US2 fonctionnel → Valider sur campus nouveau/edit
3. T008-T009 → US4 fonctionnel → Valider sur actualités, événements, programmes
4. T010-T011 → US3 fonctionnel → Aperçu visible sur tous les boutons
5. T012-T014 → Polish → Validation complète dark mode, RTL, quickstart

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Pas de modification backend/BDD — purement frontend
- Le défaut `mode="modal"` garantit que les ~16 pages non-exception obtiennent automatiquement le nouveau comportement
- Seules 3 pages nécessitent l'ajout explicite de `mode="inline"`
- Commit après chaque tâche ou groupe logique
