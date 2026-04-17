# Implementation Plan: Ajout direct de fichiers dans la médiathèque (sans album)

**Branch**: `016-mediatheque-direct-upload` | **Date**: 2026-04-12 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/016-mediatheque-direct-upload/spec.md`

## Summary

Corriger le bouton « Ajouter des fichiers » de la médiathèque admin qui est actuellement non fonctionnel (l'`<input type="file">` n'a aucun handler). Il faut permettre le téléversement direct de fichiers vers la bibliothèque sans passer par la création d'un album.

**Approche technique** :

1. **Aucun changement backend** — les endpoints `POST /api/admin/media/upload` (single) et `POST /api/admin/media/upload-multiple` (batch) existent et fonctionnent déjà. Le modèle de données supporte nativement les médias « orphelins » (l'association à un album est optionnelle via table de liaison).

2. **Frontend : extraire un composant dédié** `MediaDirectUploadModal.vue` qui remplace le bloc modal décoratif actuel dans [index.vue:1809-1870](../../usenghor_nuxt/app/pages/admin/mediatheque/index.vue#L1809-L1870). Le composant encapsule la file d'attente, le contrôle de concurrence, la validation, l'annulation et le feedback par fichier.

3. **Extraire la logique de file d'attente** dans un composable `useMediaUploadQueue.ts` pour isolation, testabilité et réutilisation future. Le composable :
   - Utilise `uploadMedia()` unitaire (pas `uploadMultipleMedia`) pour obtenir un `AbortController` et un suivi par fichier.
   - Limite stricte à 5 téléversements simultanés (FR-015) via un pool/semaphore en TypeScript pur.
   - Expose un `state: Ref<UploadItem[]>` avec `status: 'queued' | 'uploading' | 'done' | 'error' | 'cancelled'` + `progress`, `error`, `mediaId`.
   - Fournit `cancelAll()`, `cancelItem(id)`, `retryItem(id)`, `clearDone()`.

4. **Annulation propre (FR-013)** : chaque upload `fetch` reçoit un `signal` d'un `AbortController`. À la fermeture de la modale pendant un upload, une confirmation native (`confirm()` ou un petit `ConfirmDialog.vue` existant) est présentée. Si confirmée, `cancelAll()` abort tous les uploads en cours ; les fichiers déjà terminés restent en base (FR-013).

5. **Retrait du champ « URL externe » (FR-014)** : suppression pure du markup [index.vue:1845-1857](../../usenghor_nuxt/app/pages/admin/mediatheque/index.vue#L1845-L1857) dans le nouveau composant.

6. **Rafraîchissement de la grille et des compteurs (FR-006, FR-007)** : à chaque fichier terminé, émission d'un évènement `@uploaded` vers `index.vue` qui appelle la fonction existante `loadMedia()` et `getMediaStatistics()` (pattern déjà présent dans le fichier).

7. **Non-régression (SC-005)** : la page album [albums/[id].vue](../../usenghor_nuxt/app/pages/admin/mediatheque/albums/[id].vue) N'EST PAS modifiée dans cette feature. La refactorisation DRY pour qu'elle utilise aussi `MediaDirectUploadModal` est volontairement hors scope.

## Technical Context

**Language/Version**: TypeScript 5.x (Nuxt 4 / Vue 3 Composition API) — aucune partie Python touchée
**Primary Dependencies**: Vue 3, Nuxt 4, Tailwind CSS, `@nuxtjs/i18n`, `useMediaApi` composable existant, Font Awesome (icônes). Aucune nouvelle dépendance.
**Storage**: N/A (backend inchangé). PostgreSQL `media` + `album_media` tables existantes utilisées tel quel.
**Testing**: Tests manuels via dev server + scénarios d'acceptation du spec. (Projet sans infra de tests unitaires frontend automatisés — voir `research.md`.)
**Target Platform**: Interface admin web, desktop & mobile, FR/EN/AR (RTL), mode clair/sombre.
**Project Type**: Web application (backend FastAPI + frontend Nuxt) — modifications frontend uniquement.
**Performance Goals**: Jusqu'à 5 téléversements simultanés, file d'attente sans limite haute (10 fichiers mentionné dans SC-002 comme cas typique). Affichage de la grille rafraîchi en < 500 ms après chaque fichier terminé.
**Constraints**:
- Taille max par fichier : 50 Mo (alignée sur album, FR-011).
- Types autorisés : `image/*`, `video/*`, `audio/*`, `application/pdf` (alignés sur album, FR-011).
- Respect des permissions existantes : `media.create` (backend, FR-010).
- Conservation du mode sombre, i18n, RTL, accessibilité clavier (Échap, focus trap), fermeture clic extérieur (FR-012).
- Aucune modification de [albums/[id].vue](../../usenghor_nuxt/app/pages/admin/mediatheque/albums/[id].vue).

**Scale/Scope**:
- 1 nouveau composant Vue (`MediaDirectUploadModal.vue`)
- 1 nouveau composable (`useMediaUploadQueue.ts`)
- 1 modification ciblée dans [index.vue](../../usenghor_nuxt/app/pages/admin/mediatheque/index.vue) : retrait du bloc modal décoratif + utilisation du composant
- 0 migration SQL, 0 fichier backend, 0 nouvelle dépendance npm/pip
- 3 fichiers i18n touchés (`fr.json`, `en.json`, `ar.json` — namespace mediatheque existant)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Le fichier [`.specify/memory/constitution.md`](../../.specify/memory/constitution.md) est encore le template non ratifié (aucun principe concret défini). Aucune porte spécifique à valider. Les règles applicables proviennent donc de `~/.claude/rules/common/` et `~/.claude/rules/typescript/` :

| Règle | Statut | Note |
|---|---|---|
| Immutabilité (coding-style) | ✅ OK | La file d'attente manipule le state via spread et tableau nouveau — cohérent avec Vue reactivity |
| Fichiers < 800 lignes (coding-style) | ⚠️ À surveiller | `index.vue` est déjà à 1870 lignes. **L'extraction du composant réduit ce fichier au lieu de l'augmenter** — amélioration nette |
| Gestion explicite des erreurs | ✅ OK | Chaque upload capture son erreur dans `UploadItem.error` avec message i18n |
| Pas de console.log | ✅ OK | Utiliser uniquement l'affichage UI pour les erreurs |
| Validation aux frontières | ✅ OK | `validateFile()` existant réutilisé côté client ; backend revalidate |
| Secrets | ✅ N/A | Aucun secret manipulé |
| Pas de mutation | ✅ OK | File d'attente immutable — chaque mise à jour produit un nouvel item |
| TDD obligatoire (testing) | ⚠️ Non applicable en pratique | Projet sans Vitest/Playwright configuré. Tests manuels via scénarios d'acceptation. Non-régression vérifiée à la main sur le parcours album. Documenté dans `research.md`. |

**Gate: PASS** avec la réserve documentée sur l'absence d'infra de tests automatisés (hors scope de cette feature).

## Project Structure

### Documentation (this feature)

```text
specs/016-mediatheque-direct-upload/
├── plan.md              # Ce fichier
├── research.md          # Phase 0 output — décisions techniques
├── data-model.md        # Phase 1 output — modèle (inchangé, documentation seule)
├── quickstart.md        # Phase 1 output — parcours de validation manuel
├── contracts/
│   └── media-upload.md  # Phase 1 output — contrat des endpoints existants consommés
├── checklists/
│   └── requirements.md  # Déjà créé par /speckit.specify
└── tasks.md             # À créer par /speckit.tasks
```

### Source Code (repository root)

```text
usenghor_nuxt/
├── app/
│   ├── components/
│   │   └── mediatheque/
│   │       └── MediaDirectUploadModal.vue    # NOUVEAU — modale de téléversement
│   ├── composables/
│   │   ├── useMediaApi.ts                    # EXISTANT — réutilisé (uploadMedia, validateFile)
│   │   └── useMediaUploadQueue.ts            # NOUVEAU — file d'attente + pool de concurrence
│   └── pages/
│       └── admin/
│           └── mediatheque/
│               └── index.vue                 # MODIFIÉ — retrait modal décoratif, intégration composant
├── i18n/
│   └── locales/
│       ├── fr/
│       │   └── admin.json                    # MODIFIÉ — clés mediatheque.upload.*
│       ├── en/
│       │   └── admin.json                    # MODIFIÉ
│       └── ar/
│           └── admin.json                    # MODIFIÉ

usenghor_backend/                             # NON MODIFIÉ — hors scope
```

**Structure Decision** : Feature purement frontend. Un composant dédié + un composable isolé permettent de respecter la séparation des préoccupations (UI vs logique de file d'attente) et réduisent la taille d'`index.vue`. Aucune restructuration de la pyramide de dossiers.

## Complexity Tracking

> Aucune violation à justifier. Le plan réutilise les endpoints backend existants et n'introduit aucune nouvelle dépendance.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| *(aucune)* | *(aucune)* | *(aucune)* |
