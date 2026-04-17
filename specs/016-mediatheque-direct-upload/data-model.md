# Data Model — Ajout direct de fichiers dans la médiathèque

**Feature**: `016-mediatheque-direct-upload`
**Date**: 2026-04-12

## 1. Modèle de base de données — INCHANGÉ

Cette feature **n'introduit aucune modification** du schéma PostgreSQL. Les entités existantes couvrent le besoin :

### 1.1 Table `media` (existante)

Colonnes pertinentes :

| Colonne | Type | Notes |
|---|---|---|
| `id` | `UUID` | Identifiant unique |
| `media_type` | `ENUM('image', 'video', 'audio', 'document')` | Déterminé par MIME côté serveur |
| `file_path` | `TEXT` | Chemin de stockage |
| `size_bytes` | `BIGINT` | Taille originale |
| `mime_type` | `TEXT` | Validé côté serveur |
| `original_filename` | `TEXT` | Nom d'origine conservé |
| `created_at` | `TIMESTAMPTZ` | Utilisé pour tri desc |
| `created_by` | `UUID` | FK vers `users` — utilisé pour audit |
| `folder` | `TEXT` | Regroupement logique (`"general"`, `"albums"`…) |

**Règle pour cette feature** : les médias téléversés directement depuis la médiathèque utiliseront `folder = "general"` (comportement par défaut du endpoint `/api/admin/media/upload`).

### 1.2 Table `album_media` (existante, inutilisée par cette feature)

Table de liaison `many-to-many` entre `albums` et `media`. **Un média existe indépendamment de tout album** : c'est déjà le modèle natif, aucune migration nécessaire pour permettre des médias « orphelins ». Cette feature n'écrit jamais dans cette table.

### 1.3 Cohérence avec le spec

- **FR-003** : « sans qu'un album soit requis » → naturellement satisfait puisque `album_media` est facultative.
- **FR-008** : « associer a posteriori à un ou plusieurs albums » → l'action existante « Ajouter à un album » dans [index.vue](../../usenghor_nuxt/app/pages/admin/mediatheque/index.vue) créera les lignes `album_media` au moment voulu.

---

## 2. Modèle d'état côté client (nouveau)

Le composable `useMediaUploadQueue.ts` maintient une file d'attente réactive. Structures TypeScript introduites **uniquement en mémoire client**.

### 2.1 `UploadStatus`

```ts
type UploadStatus =
  | 'queued'       // En attente d'un slot libre dans le pool (max 5)
  | 'uploading'    // Requête en vol
  | 'done'         // Succès — media créé côté serveur
  | 'error'        // Échec récupérable (réseau, serveur)
  | 'rejected'     // Rejeté avant envoi (type, taille) — pas retryable
  | 'cancelled'    // Aborté par l'utilisateur (fermeture fenêtre avec confirmation)
```

### 2.2 `UploadItem`

```ts
interface UploadItem {
  readonly id: string              // UUID client, identifiant stable dans la liste
  readonly file: File              // Référence native au File
  readonly name: string            // file.name — cache pour affichage rapide
  readonly size: number            // file.size — cache pour affichage rapide
  readonly mimeType: string        // file.type — cache pour icône
  status: UploadStatus
  progress: 0 | 50 | 100           // Pas de progression réelle (cf. research R5)
  error: string | null             // Message i18n-clé ou texte utilisateur
  mediaId: string | null           // Rempli à la résolution côté serveur
  abortController: AbortController // Stocké pour permettre cancel(id)
  attempts: number                 // Incrémenté à chaque retry — information seulement
}
```

### 2.3 Transitions d'état

```
              ┌────────────┐
              │  (création)│
              └──────┬─────┘
                     │ validateFile()
         ┌───────────┼───────────┐
         │ valid     │           │ invalide
         ▼           │           ▼
     ┌─────────┐     │       ┌──────────┐
     │ queued  │     │       │ rejected │  (terminal, non retryable)
     └────┬────┘     │       └──────────┘
          │ slot libre (< 5 inflight)
          ▼
     ┌──────────┐
     │uploading │────┐
     └────┬─────┘    │ cancelAll()
          │          ▼
          │      ┌───────────┐
          │      │ cancelled │  (terminal si pas retryable dans cette session)
          │      └───────────┘
   ┌──────┴──────┐
   │ success     │ échec (non-abort)
   ▼             ▼
┌──────┐     ┌───────┐
│ done │     │ error │
└──────┘     └───┬───┘
 (terminal)      │ retryItem()
                 ▼
             ┌────────┐
             │ queued │  (retour en file, attempts++)
             └────────┘
```

**Règles** :

- Une seule transition possible par action utilisateur — pas de concurrence interne.
- `done` et `rejected` sont terminaux. `cancelled` peut être retiré par l'utilisateur (retire de la liste, ne repart pas en queue automatiquement).
- `error` → `queued` uniquement via action explicite `retryItem(id)`.
- Les items `done` peuvent être purgés par `clearDone()` ou lors de la fermeture normale de la fenêtre.

### 2.4 Invariants

1. **À tout instant** : `count(status === 'uploading') <= 5` (FR-015).
2. **Chaque item a un `AbortController` unique** — jamais partagé, jamais réutilisé après abort.
3. **`error.message` n'est jamais vide** quand `status === 'error' || 'rejected'` — permet à l'UI d'afficher quelque chose d'actionnable.
4. **`mediaId !== null`** ⇔ `status === 'done'`.
5. **La liste est immuable** : toute mise à jour passe par `queue.value = queue.value.map(…)` ou `[...queue.value, newItem]`. Aucune mutation directe d'un item (compatible strict avec la règle d'immutabilité).

### 2.5 API publique du composable

```ts
interface UseMediaUploadQueue {
  readonly items: Readonly<Ref<readonly UploadItem[]>>
  readonly stats: ComputedRef<{
    total: number
    queued: number
    uploading: number
    done: number
    error: number
    rejected: number
    cancelled: number
  }>
  readonly hasActiveUploads: ComputedRef<boolean>  // true si queued || uploading > 0

  addFiles(files: File[]): void          // validateFile puis push
  retryItem(id: string): void            // error → queued, relance le pool
  removeItem(id: string): void           // retire de la liste (seulement si non-uploading)
  cancelAll(): void                      // abort tous les uploading + marque cancelled
  clearDone(): void                      // purge les done et rejected
  reset(): void                          // vide tout (utilisé à la fermeture validée)
}
```

---

## 3. Résumé

- **Base de données** : 0 modification, 0 migration.
- **API** : 0 nouveau endpoint, 0 modification de schéma Pydantic.
- **Frontend** : nouvelles structures TypeScript uniquement en mémoire client, isolées dans un composable, immutables, testables indépendamment.
