---
description: "Task list for feature 016-mediatheque-direct-upload"
---

# Tasks: Ajout direct de fichiers dans la médiathèque (sans album)

**Input**: Design documents from `/specs/016-mediatheque-direct-upload/`
**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/media-upload.md](./contracts/media-upload.md), [quickstart.md](./quickstart.md)

**Tests**: Aucune infra Vitest/Playwright n'est configurée côté Nuxt — les tâches de test automatisé sont donc omises. La validation repose sur [quickstart.md](./quickstart.md) (11 scénarios manuels) comme défini dans research R8.

**Organization**: Tâches regroupées par user story (US1 P1, US2 P2) pour permettre une livraison incrémentale. US1 seul constitue déjà un MVP utilisable.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut s'exécuter en parallèle (fichiers différents, sans dépendance)
- **[Story]**: User story concernée (US1 / US2)
- Chaque tâche cite son chemin de fichier absolu (depuis la racine du repo)

## Path Conventions

- **Frontend Nuxt** : `usenghor_nuxt/app/...`
- **i18n** : `usenghor_nuxt/i18n/locales/{fr,en,ar}/`
- **Spec** : `specs/016-mediatheque-direct-upload/`
- Aucun fichier dans `usenghor_backend/` n'est touché (cf. plan.md Summary §1).

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Vérifier l'environnement et les dépendances existantes — aucune installation à effectuer (plan.md confirme zéro nouvelle dépendance).

- [ ] T001 Vérifier que le dev server frontend démarre sans erreur via `pnpm dev` depuis [usenghor_nuxt/](../../usenghor_nuxt/) et que la page [/admin/mediatheque](../../usenghor_nuxt/app/pages/admin/mediatheque/index.vue) est accessible avec un compte admin (pré-requis fonctionnel pour toutes les phases suivantes). _(vérification manuelle — à exécuter par l'utilisateur)_
- [ ] T002 Vérifier côté backend que l'endpoint `POST /api/admin/media/upload` est opérationnel via Swagger à http://localhost:8000/api/docs en téléversant un fichier de test manuellement (preuve que le contrat de [contracts/media-upload.md](./contracts/media-upload.md) est respecté avant toute modif front). _(vérification manuelle — à exécuter par l'utilisateur)_

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Préparer les briques de base partagées par US1 et US2 — composable de file d'attente, extension mineure de `useMediaApi` pour l'annulation, et clés i18n. Ces tâches DOIVENT être terminées avant de démarrer les phases US1/US2.

**⚠️ CRITICAL**: Aucune tâche de story ne peut commencer avant la complétion de cette phase.

- [X] T003 Étendre la signature de `uploadMedia` dans [usenghor_nuxt/app/composables/useMediaApi.ts](../../usenghor_nuxt/app/composables/useMediaApi.ts) pour accepter une option optionnelle `signal?: AbortSignal` et la passer au `apiFetch` sous-jacent (modification rétro-compatible ≤ 5 lignes, cf. research R3). Vérifier qu'aucun appelant existant n'est cassé.
- [X] T004 [P] Créer le composable `useMediaUploadQueue` dans un nouveau fichier [usenghor_nuxt/app/composables/useMediaUploadQueue.ts](../../usenghor_nuxt/app/composables/useMediaUploadQueue.ts) avec :
  - Les types `UploadStatus` et `UploadItem` exactement comme spécifiés dans [data-model.md §2.1-2.2](./data-model.md)
  - La constante `MAX_CONCURRENT = 5`
  - Un state réactif `items: Ref<readonly UploadItem[]>` manipulé de façon immuable (spread + map, jamais de mutation directe)
  - Les computed `stats` et `hasActiveUploads` tels que définis en §2.5
  - Les méthodes publiques : `addFiles`, `retryItem`, `removeItem`, `cancelAll`, `clearDone`, `reset`
  - Une fonction privée `processQueue()` qui maintient l'invariant `count(uploading) <= 5` via un compteur `inflight` et relance récursivement au retour de chaque `processItem`
  - Chaque `processItem` crée son `AbortController`, appelle `uploadMedia(file, { folder: 'general', signal })`, met à jour `status` → `uploading` → `done`/`error`/`cancelled`, puis décrémente `inflight` et rappelle `processQueue()`
  - La validation au moment du `addFiles` via `useMediaApi().validateFile` avec `{ maxSizeMB: 50, allowedTypes: ['image/*', 'video/*', 'audio/*', 'application/pdf'] }` — les fichiers rejetés sont insérés avec `status: 'rejected'` et un `error` non vide
  - Respect strict de l'immutabilité (règle coding-style) et de la typage explicite (règle typescript/coding-style)
- [X] T005 [P] Ajouter les clés i18n dans [usenghor_nuxt/i18n/locales/fr/mediatheque.json](../../usenghor_nuxt/i18n/locales/fr/mediatheque.json) sous un namespace `admin.upload.*` conformément à la liste de research R7 (16 clés : `title`, `dropzone`, `browse`, `acceptedTypes`, `status.queued`, `status.uploading`, `status.done`, `status.error`, `status.rejected`, `status.cancelled`, `retry`, `remove`, `closeConfirm`, `summary`, `errorTooLarge`, `errorBadType`, `errorNetwork`).
- [X] T006 [P] Ajouter les mêmes clés i18n traduites en anglais dans [usenghor_nuxt/i18n/locales/en/mediatheque.json](../../usenghor_nuxt/i18n/locales/en/mediatheque.json).
- [X] T007 [P] Ajouter les mêmes clés i18n traduites en arabe dans [usenghor_nuxt/i18n/locales/ar/mediatheque.json](../../usenghor_nuxt/i18n/locales/ar/mediatheque.json) (respect du RTL dans la formulation, pas de mise en forme directionnelle dans les strings).

**Checkpoint** : Foundation prête — les phases US1 et US2 peuvent démarrer. Le composable `useMediaUploadQueue` doit pouvoir être importé sans erreur TypeScript et `pnpm dev` doit toujours compiler.

---

## Phase 3: User Story 1 - Téléverser un ou plusieurs fichiers directement dans la médiathèque (Priority: P1) 🎯 MVP

**Goal** : Permettre à un administrateur de téléverser 1..N fichiers directement depuis l'onglet « Fichiers » de la médiathèque, sans passer par un album. Les fichiers apparaissent immédiatement dans la grille avec compteurs à jour.

**Independent Test** : Exécuter [quickstart.md scénario 1](./quickstart.md) (parcours heureux simple) et [scénario 2](./quickstart.md) (10 fichiers en parallèle, limite 5). Le compteur de l'onglet doit passer de N à N+10.

### Implementation for User Story 1

- [X] T008 [P] [US1] Créer le composant `MediaDirectUploadModal.vue` dans un nouveau fichier [usenghor_nuxt/app/components/mediatheque/MediaDirectUploadModal.vue](../../usenghor_nuxt/app/components/mediatheque/MediaDirectUploadModal.vue) avec :
  - Props : `modelValue: boolean` (v-model pour ouverture/fermeture)
  - Emits : `update:modelValue`, `uploaded(mediaId: string)` (émis à chaque fichier terminé)
  - Utilise le composable `useMediaUploadQueue()` importé depuis `~/composables/useMediaUploadQueue`
  - Zone dropzone fonctionnelle avec gestion des évènements `dragover`, `dragleave`, `drop`, appelant `queue.addFiles(Array.from(event.dataTransfer.files))`
  - Un `<input type="file" multiple>` caché déclenché par un bouton « Parcourir », dont l'évènement `change` appelle également `queue.addFiles(Array.from(input.files))`
  - Liste des items avec nom, taille formatée (`formatFileSize`), icône selon `mimeType`, badge de status traduit via `t('admin.upload.status.' + item.status)`, bouton « Retirer » ou « Réessayer » selon status
  - Pas de rendu du champ « URL externe » (FR-014)
  - Respect du mode sombre (classes `dark:`), RTL (classes `rtl:`), i18n (`$t('admin.upload.*')`), accessibilité clavier (focus trap, Échap, aria-labels)
  - Utilise un `<Teleport to="body">` pour l'overlay comme les autres modales de l'app
- [X] T009 [US1] Dans [usenghor_nuxt/app/pages/admin/mediatheque/index.vue](../../usenghor_nuxt/app/pages/admin/mediatheque/index.vue) : **supprimer le bloc modal décoratif existant** aux lignes ~1808-1870 (tout le `<!-- Modal Upload -->` avec son `<Teleport>`). Remplacer par une utilisation du nouveau composant : `<MediaDirectUploadModal v-model="showUploadModal" @uploaded="onMediaUploaded" />` (auto-importé par Nuxt grâce au dossier `components/mediatheque/`).
- [X] T010 [US1] Dans le même fichier [index.vue](../../usenghor_nuxt/app/pages/admin/mediatheque/index.vue), ajouter dans le script setup une fonction `onMediaUploaded()` qui appelle les fonctions de rechargement existantes (`loadMedia()` et `loadStats()` ou leurs équivalents déjà présents dans le fichier — les identifier via un `Grep` préalable). Debounce léger (200 ms) via `useDebounceFn` (déjà importé dans le fichier) pour éviter N requêtes consécutives lors d'un burst d'uploads (research R6).
- [X] T011 [US1] Vérifier à la compilation que le bouton « Ajouter des fichiers » de l'onglet Fichiers (ligne ~898-905 de [index.vue](../../usenghor_nuxt/app/pages/admin/mediatheque/index.vue)) continue d'ouvrir la nouvelle modale via `showUploadModal = true` sans modification de son handler — la référence `showUploadModal = ref(false)` à la ligne ~108 est conservée.

**Checkpoint** : À ce stade, l'US1 est fonctionnelle. Exécuter manuellement les **scénarios 1, 2, 8 et 11** de [quickstart.md](./quickstart.md) :
- Parcours heureux, drag&drop 10 fichiers (limite 5 vérifiée en Network), association à un album a posteriori, absence du champ URL externe.

---

## Phase 4: User Story 2 - Validation et retour utilisateur pendant le téléversement (Priority: P2)

**Goal** : Afficher un état clair par fichier, rejeter les fichiers invalides avec un message actionnable, présenter un récapitulatif final et permettre le retry en cas d'échec réseau.

**Independent Test** : Exécuter [quickstart.md scénarios 3, 4, 5, 6](./quickstart.md) — rejet type, rejet taille, récapitulatif partiel, retry après coupure réseau.

**Note** : La plupart de la logique d'état est déjà dans le composable (Phase 2) et dans le composant (T008). US2 affine l'expérience : messages précis, récapitulatif, gestion fine du retry.

### Implementation for User Story 2

- [X] T012 [US2] Compléter le template de [MediaDirectUploadModal.vue](../../usenghor_nuxt/app/components/mediatheque/MediaDirectUploadModal.vue) pour afficher les messages d'erreur spécifiques par fichier : mapper `item.error` vers les clés i18n (`errorTooLarge`, `errorBadType`, `errorNetwork`) dans une fonction utilitaire `errorLabel(item)`, avec un fallback générique. Vérifier que les rejets `validateFile` injectent un message distinguable entre « taille » et « type » (déjà le cas dans `validateFile` existant).
- [X] T013 [US2] Ajouter dans [MediaDirectUploadModal.vue](../../usenghor_nuxt/app/components/mediatheque/MediaDirectUploadModal.vue) un bloc récapitulatif en pied de modale, visible uniquement quand `queue.stats.value.total > 0 && queue.hasActiveUploads.value === false`, affichant `{{ t('admin.upload.summary', { done: stats.done, total: stats.total }) }}`. Le récapitulatif doit se mettre à jour réactivement.
- [X] T014 [US2] Ajouter dans [MediaDirectUploadModal.vue](../../usenghor_nuxt/app/components/mediatheque/MediaDirectUploadModal.vue) un bouton « Réessayer » par ligne d'item avec `status === 'error'`, appelant `queue.retryItem(item.id)`. Le bouton ne doit PAS être présent pour les items `rejected` (non retryable, cf. data-model §2.3). Pour les items `rejected` uniquement un bouton « Retirer » (appelant `queue.removeItem(item.id)`).

**Checkpoint** : US2 complète. Exécuter les scénarios 3–6 du quickstart. Tous les cas d'erreur doivent être explicites et actionnables.

---

## Phase 5: User Story 1 suite - Annulation à la fermeture (Priority: P1, pris en charge après US2 car dépend de la validation)

**Goal** : Implémenter la confirmation de fermeture pendant un upload (FR-013) avec annulation propre via `AbortController`.

**Rationale du placement** : Bien que FR-013 serve US1 (et non US2), sa logique dépend de l'état `hasActiveUploads` exposé par le composable et de la UX de la modale. Il est plus propre de l'ajouter après T008-T014 pour éviter de revenir plusieurs fois sur le même fichier.

**Independent Test** : [quickstart.md scénario 7](./quickstart.md) — lancer 5 gros uploads, tenter de fermer, vérifier dialogue confirmation, annuler → modale reste ouverte ; confirmer → uploads aborted, modale se ferme, fichiers déjà terminés restent.

### Implementation

- [X] T015 [US1] Dans [MediaDirectUploadModal.vue](../../usenghor_nuxt/app/components/mediatheque/MediaDirectUploadModal.vue), intercepter **toutes** les sources de fermeture (bouton « Fermer », touche Échap, clic extérieur sur l'overlay) via un handler commun `attemptClose()`. Si `queue.hasActiveUploads.value === true`, afficher une confirmation (`window.confirm(t('admin.upload.closeConfirm'))` ou un composant `ConfirmDialog.vue` existant dans le projet — à vérifier via un `Grep`). Si l'utilisateur confirme, appeler `queue.cancelAll()` puis `emit('update:modelValue', false)`. Sinon, ne rien faire (modale reste ouverte).
- [X] T016 [US1] Vérifier dans `useMediaUploadQueue.cancelAll()` (T004) que chaque item en `uploading` appelle bien `item.abortController.abort()`, puis met le status à `cancelled`. Vérifier que `uploadMedia` (T003) propage correctement le signal → `fetch` abort la requête (l'onglet Network DevTools doit montrer un status `(canceled)`).
- [X] T017 [US1] Vérifier que la fermeture normale (sans upload actif) fonctionne toujours : bouton Fermer, Échap, clic extérieur → ferme immédiatement sans dialogue. Les items `done` / `error` / `rejected` restent non comptés comme « actifs » dans `hasActiveUploads`.

**Checkpoint** : US1 totalement finalisée, y compris FR-013. Le MVP complet est livrable.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Finitions transverses, non-régression, validation finale.

- [X] T018 [P] Vérifier que [usenghor_nuxt/app/pages/admin/mediatheque/albums/[id].vue](../../usenghor_nuxt/app/pages/admin/mediatheque/albums/[id].vue) n'a **pas été modifié** par cette feature (`git diff --stat` doit être vide pour ce fichier). Exécuter [quickstart.md scénario 9](./quickstart.md) pour confirmer la non-régression du parcours d'upload via album (SC-005). _(git diff vérifié : 0 fichier modifié dans albums/ ; scénario 9 manuel restant)_
- [ ] T019 [P] Vérifier la cohérence dark mode, RTL et i18n via [quickstart.md scénario 10](./quickstart.md) : basculer fr → en → ar, basculer light → dark, valider au clavier sans souris.
- [X] T020 Mesurer la taille d'[index.vue](../../usenghor_nuxt/app/pages/admin/mediatheque/index.vue) après T009 avec `wc -l` : elle doit avoir diminué (le bloc modal décoratif de 62 lignes a été retiré). Documenter la nouvelle taille dans le message de commit.
- [ ] T021 Exécuter **l'intégralité** de la checklist de sortie de [quickstart.md](./quickstart.md) (tous les scénarios 1–11 + checklist finale). Marquer chaque item comme passant.
- [X] T022 [P] Vérifier qu'aucun `console.log` ne subsiste dans les fichiers créés/modifiés ([useMediaUploadQueue.ts](../../usenghor_nuxt/app/composables/useMediaUploadQueue.ts), [MediaDirectUploadModal.vue](../../usenghor_nuxt/app/components/mediatheque/MediaDirectUploadModal.vue), [index.vue](../../usenghor_nuxt/app/pages/admin/mediatheque/index.vue), [useMediaApi.ts](../../usenghor_nuxt/app/composables/useMediaApi.ts)) — règle common/security.
- [ ] T023 [P] Lancer `pnpm lint` depuis [usenghor_nuxt/](../../usenghor_nuxt/) et corriger toute erreur ESLint sur les fichiers touchés.
- [X] T024 Mettre à jour la liste « Recent Changes » de [CLAUDE.md](../../CLAUDE.md) avec une ligne synthétique : `016-mediatheque-direct-upload: upload direct de fichiers dans la médiathèque (composant + composable, sans album)`.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)** : Pas de dépendance — peut démarrer immédiatement.
- **Phase 2 (Foundational)** : Dépend de Phase 1. BLOQUE toutes les phases suivantes.
- **Phase 3 (US1)** : Dépend de Phase 2 — en particulier de T004 (composable) et T005-T007 (i18n).
- **Phase 4 (US2)** : Dépend de Phase 3 (les tâches US2 éditent le même fichier `MediaDirectUploadModal.vue` créé en T008).
- **Phase 5 (US1 suite - annulation)** : Dépend de Phase 4 pour éviter de revenir plusieurs fois sur le même fichier (voir rationale).
- **Phase 6 (Polish)** : Dépend de toutes les phases user story.

### Task-Level Dependencies inside Phase 2

- T003 (extension `uploadMedia`) est **préalable** à T004 (composable, qui utilise `uploadMedia` avec `signal`).
- T004, T005, T006, T007 sont parallélisables (fichiers différents) — **mais** T004 dépend de T003.

### Task-Level Dependencies inside Phase 3 (US1)

- T008 (création composant) peut démarrer dès que Phase 2 est finie.
- T009, T010, T011 éditent tous [index.vue](../../usenghor_nuxt/app/pages/admin/mediatheque/index.vue) et doivent donc s'enchaîner **séquentiellement** sur ce fichier.
- T009 → T010 → T011.

### Task-Level Dependencies inside Phase 4 (US2)

- T012, T013, T014 éditent tous [MediaDirectUploadModal.vue](../../usenghor_nuxt/app/components/mediatheque/MediaDirectUploadModal.vue) → s'enchaînent séquentiellement.

### Task-Level Dependencies inside Phase 5 (US1 suite)

- T015 édite le composant modal, T016 vérifie le composable (créé en T004), T017 est un test manuel. T015 → T016 → T017.

### Parallel Opportunities

- **Phase 1** : T001 et T002 peuvent tourner en parallèle (vérifications indépendantes).
- **Phase 2** : T004, T005, T006, T007 peuvent avancer en parallèle **une fois T003 terminé**. Les 3 fichiers i18n (T005/T006/T007) et le composable (T004) sont 4 fichiers distincts.
- **Phase 6** : T018, T019, T022, T023 sont parallélisables (contrôles indépendants sur fichiers distincts).

---

## Parallel Example: Phase 2 après T003

```bash
# Une fois T003 (extension uploadMedia) terminée, lancer en parallèle :
Task: "T004 — Créer useMediaUploadQueue.ts dans usenghor_nuxt/app/composables/"
Task: "T005 — Ajouter clés i18n admin.upload.* dans usenghor_nuxt/i18n/locales/fr/mediatheque.json"
Task: "T006 — Ajouter clés i18n admin.upload.* dans usenghor_nuxt/i18n/locales/en/mediatheque.json"
Task: "T007 — Ajouter clés i18n admin.upload.* dans usenghor_nuxt/i18n/locales/ar/mediatheque.json"
```

## Parallel Example: Phase 6 (Polish)

```bash
# Contrôles indépendants :
Task: "T018 — Vérifier non-régression albums/[id].vue via git diff + quickstart scénario 9"
Task: "T019 — Vérifier i18n/dark mode/RTL via quickstart scénario 10"
Task: "T022 — Grep console.log sur les fichiers touchés"
Task: "T023 — pnpm lint sur usenghor_nuxt/"
```

---

## Implementation Strategy

### MVP First (US1 seul)

1. Compléter Phase 1 (Setup) : T001, T002
2. Compléter Phase 2 (Foundational) : T003, T004, T005, T006, T007
3. Compléter Phase 3 (US1) : T008, T009, T010, T011
4. **STOP et VALIDER** : exécuter quickstart scénarios 1, 2, 8, 11
5. À ce stade, un utilisateur peut déjà téléverser des fichiers directement. L'annulation fine et le récapitulatif sont absents mais la valeur principale est livrée.

### Livraison incrémentale recommandée

1. **MVP** (Phases 1–3) → déployable → démo possible
2. **US2 + feedback fin** (Phase 4) → déployable → UX améliorée
3. **Annulation propre** (Phase 5) → déployable → FR-013 couvert
4. **Polish & non-régression** (Phase 6) → PR prête pour revue / merge

### Stratégie équipe parallèle

Avec plusieurs développeurs :

1. Dev A termine Phase 1 + T003 seul (petite chaîne critique)
2. Une fois T003 passé, Dev A prend T004 pendant que Dev B prend T005/T006/T007 en parallèle
3. Dev A enchaîne sur T008 dès que T004 est vert ; Dev B aide à la relecture
4. Un seul dev à la fois sur [index.vue](../../usenghor_nuxt/app/pages/admin/mediatheque/index.vue) (T009→T010→T011) pour éviter les conflits de merge

---

## Notes

- Aucune tâche ne touche [usenghor_backend/](../../usenghor_backend/) — c'est volontaire et doit être vérifié en fin de parcours (T018).
- Aucune tâche ne touche [usenghor_nuxt/app/pages/admin/mediatheque/albums/](../../usenghor_nuxt/app/pages/admin/mediatheque/albums/) — non-régression stricte (SC-005).
- Chaque tâche est conçue pour être complétable par un agent LLM sans contexte supplémentaire : elle cite le fichier exact, les symboles existants à réutiliser, les références croisées (plan, research, data-model).
- Commit recommandé après chaque phase plutôt qu'après chaque tâche (meilleure granularité d'historique pour une feature de cette taille).
- Si une tâche révèle un blocage (ex. un refactor nécessaire dans un fichier voisin), **ne pas étendre le scope** sans re-planifier — documenter et poser la question.
