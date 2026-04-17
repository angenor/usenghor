# Research — Ajout direct de fichiers dans la médiathèque

**Feature**: `016-mediatheque-direct-upload`
**Date**: 2026-04-12

Ce document rassemble les décisions techniques et leurs justifications pour la phase de planification. Aucune ambiguïté `NEEDS CLARIFICATION` ne subsiste à l'issue de `/speckit.clarify`.

---

## R1 — Endpoint backend à utiliser : `uploadMedia` (unitaire) vs `uploadMultipleMedia` (batch)

**Décision** : Utiliser **`uploadMedia()` unitaire** (`POST /api/admin/media/upload`), appelé en parallèle dans un pool de 5.

**Rationale** :

- **FR-004** exige un état par fichier (en attente, en cours avec progression, terminé, en erreur). Un seul gros `POST /upload-multiple` ne permet pas de distinguer quel fichier a échoué sans parser la réponse serveur après coup, et ne fournit aucun signal intermédiaire.
- **FR-009** exige de pouvoir réessayer un fichier individuellement. Avec `uploadMultipleMedia`, réessayer un seul fichier forcerait à renvoyer tout le batch.
- **FR-013** exige de pouvoir **annuler** un téléversement en cours. Un appel unique ne permet d'annuler que le batch entier, pas un fichier précis ; avec des appels unitaires chacun reçoit son propre `AbortController`.
- **FR-015** exige une concurrence de 5. Un pool se pilote en TypeScript pur quand on contrôle chaque requête individuellement.

**Alternatives considérées** :

- `uploadMultipleMedia` (batch) : rejetée pour les raisons ci-dessus. Utilisée aujourd'hui par la page album mais avec une progression **simulée** ([albums/[id].vue:404-408](../../usenghor_nuxt/app/pages/admin/mediatheque/albums/[id].vue#L404-L408)), ce qui est précisément le comportement qu'on veut éviter ici.
- Nouveau endpoint WebSocket avec streaming de progression : rejeté — overkill, exige du travail backend alors qu'une feature « purement frontend » est annoncée dans les Assumptions du spec.

---

## R2 — Pool de concurrence : implémentation

**Décision** : Pool maison minimaliste basé sur `Promise` + un compteur d'inflight, dans `useMediaUploadQueue.ts`.

Pseudocode cible :

```ts
const MAX_CONCURRENT = 5

async function processQueue() {
  while (queue.value.some(i => i.status === 'queued') && inflight < MAX_CONCURRENT) {
    const next = queue.value.find(i => i.status === 'queued')
    if (!next) break
    void processItem(next.id)  // no await — parallèle
  }
}
```

Chaque `processItem` incrémente `inflight`, marque l'item `uploading`, lance `uploadMedia()`, puis sur résolution/rejet décrémente `inflight` et rappelle `processQueue()` pour déclencher l'item suivant.

**Rationale** :

- Pas de dépendance supplémentaire (p-limit, p-queue…). La règle `package.json` interne du projet minimise les deps.
- Le pattern tient en ~30 lignes, entièrement testable à la main, et correspond exactement au besoin.
- Réactivité Vue préservée : chaque mise à jour d'état passe par un tableau immuable (spread) pour que la grille se mette à jour sans flicker.

**Alternatives considérées** :

- `p-limit` (npm) : rejetée — dépendance minuscule mais injustifiée pour 30 lignes de code maison.
- `Promise.allSettled(files.map(uploadMedia))` sans limite : rejetée — viole FR-015 (limite stricte 5).

---

## R3 — Annulation : `AbortController` par upload

**Décision** : Chaque upload reçoit un `AbortController` stocké dans l'`UploadItem`. `apiFetch` (wrapper `$fetch` de Nuxt) accepte `signal: controller.signal`.

**Rationale** :

- **FR-013** exige une annulation propre, pas un fire-and-forget.
- `$fetch` (ofetch sous le capot) propage le signal à l'API `fetch` native qui abort la requête côté client ; le serveur verra une déconnexion et peut nettoyer.
- Un upload aborté passe son état à `cancelled`, les octets déjà écrits côté serveur sont orphelins (inoffensifs) et pourront être GC par la logique existante si applicable — pas un souci fonctionnel pour cette feature.

**Vérification à faire dans `useMediaApi.uploadMedia`** : accepter une option `signal` et la passer à `apiFetch`. Si absente, petite modification du composable pour l'ajouter (< 5 lignes, rétro-compatible).

**Alternatives considérées** :

- Laisser les uploads finir en arrière-plan : rejeté explicitement par la clarification Q1 (option B).
- Empêcher la fermeture de la fenêtre : rejeté par la clarification Q1 (option D).

---

## R4 — Validation client : réutiliser `validateFile`

**Décision** : Utiliser la fonction existante [`useMediaApi.validateFile`](../../usenghor_nuxt/app/composables/useMediaApi.ts) avec les mêmes options que la page album :

```ts
validateFile(file, {
  maxSizeMB: 50,
  allowedTypes: ['image/*', 'video/*', 'audio/*', 'application/pdf'],
})
```

**Rationale** : Cohérence stricte avec FR-011. Source unique de vérité. Aligne le comportement admin partout. Si un jour ces limites changent, un seul endroit à modifier.

**Alternatives considérées** : Redéfinir des limites locales au composant : rejeté (divergence inévitable).

---

## R5 — Progression par fichier : approche

**Décision** : Progression **binaire** (`0` → `50` → `100`) combinée à un spinner pendant la phase `uploading`.

**Rationale** :

- `fetch` + `FormData` ne fournit pas d'évènement de progression natif. Obtenir une vraie progression upload exige `XMLHttpRequest` (via `xhr.upload.onprogress`) ou un stream custom — complexité disproportionnée.
- Un spinner + libellé « En cours… » donne un feedback clair et non mensonger. Le spec (FR-004) demande un état visible, pas un pourcentage précis.
- À la résolution de la promise, on passe directement à `100` et `done`. À l'échec, `0` et `error`.

**Alternatives considérées** :

- XHR avec progression réelle : rejetée — complexité ×3, bénéfice UX marginal pour des fichiers < 50 Mo, et interopérabilité avec `$fetch` non triviale.
- Progression simulée comme sur la page album : rejetée — c'est mensonger et nous voulons justement une feature propre.

---

## R6 — Rafraîchissement de la grille

**Décision** : Le composant modal émet `@uploaded(mediaId)` à chaque fichier terminé. `index.vue` écoute et appelle **déjà existantes** `loadMedia()` et `loadStats()` (ou équivalents) avec debouncing optionnel (200 ms) pour éviter N requêtes de liste consécutives.

**Rationale** :

- **FR-006** + **FR-007** exigent l'apparition immédiate + compteurs à jour sans rechargement manuel.
- Le pattern `@event` → parent → refetch est cohérent avec le reste d'`index.vue` (déjà utilisé pour le modal « Ajouter à un album »).
- Alternative : insérer localement le média retourné dans le state — plus rapide mais risque de divergence avec les filtres/tris serveur actifs. Un refetch est plus robuste.

---

## R7 — i18n

**Décision** : Ajouter les clés sous `admin.mediatheque.upload.*` dans les 3 fichiers locale (`fr`, `en`, `ar`) :

```
admin.mediatheque.upload.title            # "Ajouter des fichiers"
admin.mediatheque.upload.dropzone         # "Glissez-déposez vos fichiers ici"
admin.mediatheque.upload.browse           # "Parcourir"
admin.mediatheque.upload.acceptedTypes    # "Images, vidéos, documents, audios — max 50 Mo"
admin.mediatheque.upload.status.queued    # "En attente"
admin.mediatheque.upload.status.uploading # "En cours…"
admin.mediatheque.upload.status.done      # "Terminé"
admin.mediatheque.upload.status.error     # "Erreur"
admin.mediatheque.upload.status.cancelled # "Annulé"
admin.mediatheque.upload.retry            # "Réessayer"
admin.mediatheque.upload.remove           # "Retirer"
admin.mediatheque.upload.closeConfirm     # "Des fichiers sont en cours d'envoi, voulez-vous annuler ?"
admin.mediatheque.upload.summary          # "{done} sur {total} fichiers ajoutés"
admin.mediatheque.upload.errorTooLarge    # "Fichier trop volumineux (max {max} Mo)"
admin.mediatheque.upload.errorBadType     # "Type de fichier non supporté"
admin.mediatheque.upload.errorNetwork     # "Erreur réseau — veuillez réessayer"
```

**Rationale** : Respect FR-012 (cohérence avec l'admin). Clés regroupées sous un namespace unique pour faciliter la maintenance.

---

## R8 — Tests et non-régression

**Décision** : Tests manuels scriptés dans `quickstart.md`. Aucune infra Vitest/Playwright n'est configurée pour le frontend Nuxt actuellement (vérification `package.json` + `nuxt.config.ts`). L'ajout d'une infra de test est un chantier hors scope.

**Stratégie** :

1. **Parcours heureux** : téléverser 3 images, vérifier apparition + compteurs.
2. **Parcours limite** : téléverser 10 fichiers en une fois, vérifier que seuls 5 partent en parallèle (observable via DevTools Network), que les 5 autres démarrent progressivement.
3. **Rejet type** : téléverser un `.exe` → rejet immédiat avec message.
4. **Rejet taille** : téléverser un fichier > 50 Mo → rejet.
5. **Annulation** : lancer 3 uploads, cliquer fermer → dialogue confirmation → annuler → vérifier que les uploads en cours disparaissent et que les terminés restent.
6. **Non-régression album** : aller sur `/admin/mediatheque/albums/{id}`, téléverser comme avant, vérifier que ça fonctionne à l'identique.

**Rationale** : Valide SC-001 à SC-005 sans dépendre d'une infra qui n'existe pas.

---

## Synthèse

Toutes les décisions techniques sont cohérentes avec :

- Les 15 FR du spec
- Les 3 clarifications de la session 2026-04-12
- Les règles communes (coding-style, security, patterns)
- Les règles TypeScript (types explicites, immutabilité, validation côté client)

Aucun marqueur `NEEDS CLARIFICATION` subsistant. Prêt pour Phase 1.
