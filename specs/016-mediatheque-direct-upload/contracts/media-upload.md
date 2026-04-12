# Contract — Endpoints de téléversement consommés

**Feature**: `016-mediatheque-direct-upload`
**Date**: 2026-04-12

Cette feature **ne crée ni ne modifie aucun endpoint**. Elle consomme un endpoint existant du backend FastAPI. Ce document fige le contrat tel qu'il est observé aujourd'hui et servira de référence pour détecter une rupture accidentelle.

---

## Endpoint consommé : `POST /api/admin/media/upload`

**Source** : [usenghor_backend/app/routers/admin/media.py:87-106](../../../usenghor_backend/app/routers/admin/media.py#L87-L106)

**Authentification** : requise — JWT admin.
**Permission** : `media.create` (vérifiée par `PermissionChecker("media.create")`).
**Content-Type** : `multipart/form-data`.

### Corps de la requête (FormData)

| Champ | Type | Obligatoire | Utilisation par cette feature |
|---|---|---|---|
| `file` | `UploadFile` | ✅ oui | Le fichier à téléverser |
| `folder` | `string` | non — défaut `"general"` | Laissé au défaut `"general"` |
| `alt_text` | `string \| null` | non | Non utilisé à ce stade — édition différée via modal d'édition existant |
| `credits` | `string \| null` | non | Non utilisé à ce stade |
| `base_filename` | `string \| null` | non | Non utilisé |

### Réponse succès (201 Created)

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "media_type": "image",
  "file_path": "general/2026/04/xyz.jpg",
  "file_name": "xyz.jpg",
  "original_filename": "photo.jpg",
  "size_bytes": 123456,
  "mime_type": "image/jpeg",
  "created_at": "2026-04-12T14:30:00Z",
  "..."
}
```

Schéma Pydantic : `MediaUploadResponse` (déjà défini backend, typé côté front dans `~/types/api`).

### Réponses d'erreur

| Code | Cas | Gestion côté client |
|---|---|---|
| `400` | Fichier invalide (type, taille, corrompu) | `status = 'error'`, message backend affiché |
| `401` | Non authentifié | Redirection login (déjà géré par `useApi()`) |
| `403` | Permission `media.create` absente | `status = 'error'` + message « Permission refusée » |
| `413` | Payload trop gros (Nginx/FastAPI) | `status = 'error'` + message « Fichier trop volumineux » |
| `500` | Erreur serveur | `status = 'error'` + message générique + bouton réessayer |
| *(AbortError)* | Annulation utilisateur | `status = 'cancelled'` — pas un vrai échec HTTP |

### Côté client — appel

```ts
// Via useMediaApi (existant)
const result: MediaUploadResponse = await uploadMedia(file, { folder: 'general' })
// ou, pour cette feature avec annulation :
const result = await uploadMedia(file, { folder: 'general', signal: abortController.signal })
```

**Modification mineure requise** dans `useMediaApi.ts` : ajouter `signal?: AbortSignal` aux options et le passer à `apiFetch`. Rétro-compatible.

---

## Endpoints NON consommés (à documenter pour éviter confusion)

- ❌ `POST /api/admin/media/upload-multiple` — utilisé par la page album, ignoré par cette feature (cf. research R1).
- ❌ `POST /api/admin/media/external` — correspond à l'ancienne fonctionnalité « URL externe » retirée (FR-014).

---

## Contrat de non-régression

**Test de non-régression à effectuer** (cf. `quickstart.md` §6) :

1. Ouvrir `/admin/mediatheque/albums/{id}` existant.
2. Téléverser un fichier via le bouton existant.
3. Vérifier dans l'onglet Network : un seul `POST /api/admin/media/upload-multiple` doit partir, avec `folder=albums`.
4. Le fichier doit apparaître dans l'album.

Toute modification involontaire de `useMediaApi.uploadMedia` ou de l'endpoint signalerait une rupture de contrat.

---

## Schéma réponse consolidé (TypeScript)

Re-documenté ici pour référence — type déjà exporté par `~/types/api`. Ne pas dupliquer, juste importer.

```ts
import type { MediaUploadResponse, MediaType } from '~/types/api'

// MediaUploadResponse = {
//   id: string
//   media_type: MediaType
//   file_path: string
//   file_name: string
//   original_filename: string
//   size_bytes: number
//   mime_type: string
//   created_at: string
//   // ... (variants d'image si applicable)
// }
```
