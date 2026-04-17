---

description: "Task list for feature 018-governance-media-album"
---

# Tasks: Album médiathèque « Gouvernance » pour les textes fondateurs

**Input**: Design documents from `/specs/018-governance-media-album/`
**Prerequisites**: plan.md ✅ spec.md ✅ research.md ✅ data-model.md ✅ contracts/ ✅ quickstart.md ✅

**Tests**: Tests unitaires ciblés proposés en Phase de Polish uniquement (validation manuelle via `quickstart.md` pour le flux global). La spec n'exige pas de couverture E2E automatisée pour cette feature.

**Organization**: 4 user stories — US1 & US2 sont P1 (MVP), US3 & US4 sont P2 (gouvernance éditoriale).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Tâche parallélisable (fichiers distincts, aucune dépendance avec des tâches en cours)
- **[Story]**: US1 / US2 / US3 / US4 selon mapping à spec.md
- Les chemins de fichiers absolus sont donnés dans chaque tâche

## Path Conventions

Monorepo existant :

- Backend : `usenghor_backend/`
- Frontend : `usenghor_nuxt/`
- Migrations SQL : `usenghor_backend/documentation/modele_de_données/migrations/`
- Source SQL canonique : `usenghor_backend/documentation/modele_de_données/services/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Aucune initialisation ; projet déjà mature. Cette phase liste seulement les préconditions à vérifier avant de commencer.

- [X] T001 Vérifier que la branche `018-governance-media-album` est bien active et que l'environnement local est opérationnel (`docker compose up -d` dans `usenghor_backend/`, backend + frontend en cours). Confirmer que la clé éditoriale `governance.foundingTexts.documents` existe en base avec ≥1 document : `docker exec -i usenghor_postgres psql -U usenghor -d usenghor -c "SELECT key, jsonb_array_length(value::jsonb) FROM editorial_contents WHERE key='governance.foundingTexts.documents';"`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Modifications de schéma et migration SQL ; cette phase est **bloquante pour toutes les user stories**. Aucune US ne peut démarrer tant que la colonne `thumbnail_url` n'est pas en place et que l'album `gouvernance` n'existe pas en base.

**⚠️ CRITICAL**: Ne PAS commencer US1/US2/US3/US4 avant la fin de cette phase.

- [X] T002 Modifier `usenghor_backend/documentation/modele_de_données/services/03_media.sql` : ajouter `thumbnail_url VARCHAR(500)` dans la définition `CREATE TABLE media (...)` juste après `url VARCHAR(500) NOT NULL,` et avant `is_external_url`. Commenter en français l'intention (« URL de la vignette / couverture, utile pour documents et vidéos »).
- [X] T003 Créer `usenghor_backend/documentation/modele_de_données/migrations/032_gouvernance_album.sql` suivant le pseudo-SQL de `data-model.md` §3 : `BEGIN;` → `ALTER TABLE media ADD COLUMN IF NOT EXISTS thumbnail_url VARCHAR(500);` → upsert album `gouvernance` (slug, title, description FR, status=`published`) via `ON CONFLICT (slug) DO UPDATE` → extraction JSON via `jsonb_array_elements` depuis `editorial_contents WHERE key='governance.foundingTexts.documents'` → upsert idempotent `media` par `url` → upsert `album_media` avec `ON CONFLICT (album_id, media_id) DO UPDATE SET display_order=EXCLUDED.display_order` → `COMMIT;`. Ajouter des `RAISE NOTICE` sur nombre de médias insérés/mis à jour. Fichier en ASCII pour le nom ; accents FR autorisés à l'intérieur.
- [X] T004 Créer `usenghor_backend/documentation/modele_de_données/migrations/032_gouvernance_album_rollback.sql` suivant le pseudo-SQL de `data-model.md` §4 : extraction des URLs sources depuis `editorial_contents` → `DELETE FROM album_media` ciblé → `DELETE FROM media` pour les URLs sources non-orphelines → `DELETE FROM albums WHERE slug='gouvernance'` **uniquement si aucun `album_media` ne reste**. La colonne `thumbnail_url` reste en place. `BEGIN;` / `COMMIT;` encadrant l'ensemble.
- [X] T005 [P] Modifier `usenghor_backend/app/models/media.py` : ajouter sur la classe `Media` la colonne `thumbnail_url: Mapped[str | None] = mapped_column(String(500), nullable=True)`. Respecter le style du projet (type hints Python 3.14).
- [X] T006 [P] Modifier `usenghor_backend/app/schemas/media.py` pour exposer `thumbnail_url` :
  - Ajouter `thumbnail_url: str | None = Field(None, max_length=500, description="URL de la vignette / couverture")` dans `MediaBase` (propagation automatique à `MediaCreate`, `MediaRead`, `MediaExternalCreate`).
  - Ajouter `thumbnail_url: str | None = Field(None, max_length=500)` dans `MediaUpdate`.
  - Ajouter `thumbnail_url: str | None = None` dans la classe `CoverMedia`.
- [X] T007 Exécuter la migration en local : `docker exec -i usenghor_postgres psql -U usenghor -d usenghor < usenghor_backend/documentation/modele_de_données/migrations/032_gouvernance_album.sql`. Vérifier via SQL : `SELECT a.slug, a.status, COUNT(am.media_id) FROM albums a LEFT JOIN album_media am ON am.album_id = a.id WHERE a.slug='gouvernance' GROUP BY a.id;` (attendu : 1 ligne, status=`published`, count ≥ 1).
- [X] T008 Redémarrer le backend (`uvicorn app.main:app --reload` si non en watch mode) puis vérifier via Swagger `GET /api/public/albums/by-slug/gouvernance` → 200 avec `media_items` non vide et `thumbnail_url` exposé dans chaque item.

**Checkpoint**: Fondation prête — les user stories peuvent démarrer en parallèle. US1 et US2 (toutes deux P1) devraient être implémentées avant les P2.

---

## Phase 3: User Story 1 — Médiathèque publique (Priority: P1) 🎯 MVP

**Goal**: Un visiteur qui ouvre `/mediatheque` voit l'album « Gouvernance » dans les onglets « Tout » et « Albums », peut l'ouvrir via `/mediatheque/gouvernance` et prévisualiser chaque PDF inline.

**Independent Test**: Ouvrir http://localhost:3000/mediatheque, vérifier l'apparition de l'album dans les deux onglets avec vignette correcte ; cliquer l'album → /mediatheque/gouvernance → cliquer un PDF → modal inline fonctionne.

### Implementation for User Story 1

- [X] T009 [US1] Ouvrir `usenghor_backend/app/services/media_service.py` et vérifier le tri appliqué dans `get_published_albums_list()` lors du calcul de `cover_media` : le premier média retourné par album doit être celui avec le plus petit `display_order`. Si la query n'applique pas `ORDER BY am.display_order ASC NULLS LAST, m.created_at ASC LIMIT 1`, ajuster la requête SQL/ORM correspondante.
- [X] T010 [US1] Dans le même fichier `usenghor_backend/app/services/media_service.py`, vérifier `get_album_by_slug()` : les `media_items` retournés doivent être triés par `display_order ASC NULLS LAST, created_at ASC`. Ajuster si nécessaire pour garantir FR-014.
- [X] T011 [US1] Dans `usenghor_backend/app/services/media_service.py`, lors du build de `CoverMedia` (quelle que soit la fonction concernée — probablement `get_published_albums_list`), propager `thumbnail_url=media.thumbnail_url` pour alimenter le nouveau champ ajouté en T006.
- [X] T012 [P] [US1] Ouvrir `usenghor_nuxt/app/types/api/media.ts`, vérifier que `CoverMedia` (ou `PublicAlbumListItem.cover_media`) expose `thumbnail_url: string | null`. Si manquant, ajouter le champ. Vérifier que `MediaRead.thumbnail_url` est bien `string | null` (déjà présent à la ligne 21 d'après l'exploration — valider et laisser tel quel).
- [X] T013 [P] [US1] Ouvrir `usenghor_nuxt/app/pages/mediatheque/index.vue` et `usenghor_nuxt/app/pages/mediatheque/[slug].vue` (lecture seule de diagnostic) : vérifier que la vignette des albums utilise `cover_media.thumbnail_url ?? cover_media.url`. Si la logique existante ne consomme pas `thumbnail_url`, ajuster le template pour l'utiliser en priorité (fallback sur `url` ou icône générique pour les documents sans vignette).
- [X] T014 [US1] Valider manuellement selon `quickstart.md` §4 : http://localhost:3000/mediatheque onglet « Tout » puis « Albums » → album `Gouvernance` visible avec vignette = 1ère couverture de document. Cliquer → http://localhost:3000/mediatheque/gouvernance → liste des PDF avec `MediaFilePreviewModal` inline fonctionnel (touche Esc ferme, fleches naviguent, PDF s'affiche dans iframe).

**Checkpoint**: US1 pleinement fonctionnelle — l'album est exposé publiquement et prévisualisable sans aucune modification de la page gouvernance.

---

## Phase 4: User Story 2 — Page gouvernance alimentée par l'album (Priority: P1)

**Goal**: `/a-propos/gouvernance` lit les textes fondateurs depuis l'album `gouvernance` (plus depuis le JSON éditorial), présente les flip cards inchangées visuellement, ajoute un bouton « Prévisualiser » et gère l'état vide discret.

**Independent Test**: Ouvrir http://localhost:3000/a-propos/gouvernance → flip cards identiques à l'état avant migration, 3 boutons par card, modal de prévisualisation fonctionnel ; en dépubliant l'album, la section garde badge/titre/description et affiche un message court.

### Implementation for User Story 2

- [X] T015 [P] [US2] Modifier `usenghor_nuxt/i18n/locales/fr/governance.json` : ajouter sous `governance.foundingTexts` les clés `preview` (« Prévisualiser ») et `emptyState` (« Les documents seront bientôt disponibles. »). Conserver les clés existantes `badge`, `title`, `description`, `view`, `download`.
- [X] T016 [P] [US2] Modifier `usenghor_nuxt/i18n/locales/en/governance.json` : ajouter `preview` (« Preview ») et `emptyState` (« Documents will be available soon. »).
- [X] T017 [P] [US2] Modifier `usenghor_nuxt/i18n/locales/ar/governance.json` : ajouter `preview` et `emptyState` (traductions arabes cohérentes avec le ton du reste du fichier ; vérifier la bonne direction RTL côté rendu).
- [X] T018 [US2] Modifier `usenghor_nuxt/app/components/governance/FoundingTextsSection.vue` :
  - Conserver inchangée l'interface `FoundingDocument` (cf. data-model §6).
  - Ajouter dans le template de chaque flip card un 3e bouton « Prévisualiser » (icône œil distincte + `aria-label` i18n `governance.foundingTexts.preview`).
  - Déclarer `defineEmits<{ preview: [doc: FoundingDocument] }>()` et émettre `preview` au clic.
  - Ajouter un bloc conditionnel `v-if="!documents?.length"` qui affiche uniquement un texte `{{ $t('governance.foundingTexts.emptyState') }}` en lieu et place de la grille. Le bandeau haut (badge/titre/description) reste toujours rendu (cf. FR-015, Q2).
- [X] T019 [US2] Modifier `usenghor_nuxt/app/pages/a-propos/gouvernance.vue` :
  - Remplacer `foundingTexts = getRawContent('governance.foundingTexts.documents')` par un appel SSR via `usePublicAlbumsApi().getAlbumBySlug('gouvernance')` protégé par `try/catch` (en cas de 404, considérer `media_items = []`).
  - Ajouter la fonction locale `mapMediaToFoundingDocument(m, i)` comme défini dans `data-model.md` §6.2 (champ `year` = `credits ? Number.parseInt(credits, 10) || undefined : undefined`).
  - Construire une `Map<string, MediaRead>` `foundingMediaById` pour retrouver le `MediaRead` d'origine à partir de l'id.
  - Passer `:documents="foundingDocuments"` au composant (avec `foundingDocuments = album?.media_items.map(mapMediaToFoundingDocument) ?? []`).
  - Écouter l'event `@preview="onPreview"` et ouvrir `<MediaFilePreviewModal :media="selectedMedia" @close="selectedMedia = null" />` quand `selectedMedia` est non nul. `onPreview(doc)` fait `selectedMedia.value = foundingMediaById.get(doc.id) ?? null`.
  - Garder la lecture de `governance.foundingTexts.badge/title/description` inchangée (ces champs restent éditoriaux).
- [X] T020 [US2] Valider manuellement selon `quickstart.md` §5 et §6 :
  1. Page `/a-propos/gouvernance` en FR : flip cards OK, 3 boutons fonctionnent (voir nouvel onglet, téléchargement, modal).
  2. Même page en EN puis AR : interface traduite, titres/descriptions des documents en FR tels quels, layout RTL OK.
  3. Dépublier l'album en SQL (`UPDATE albums SET status='draft' WHERE slug='gouvernance';`) → rafraîchir : bandeau conservé, grille remplacée par le message `emptyState`. Republier ensuite.

**Checkpoint**: US2 pleinement fonctionnelle — la page gouvernance affiche des données BDD, sans régression visuelle.

---

## Phase 5: User Story 3 — Gestion admin via l'album (Priority: P2)

**Goal**: Un administrateur peut ajouter / retirer / réordonner / modifier les documents et leurs couvertures depuis `/admin/mediatheque/albums/{id}` de l'album Gouvernance. Les changements sont visibles sur les deux pages publiques.

**Independent Test**: Se connecter en admin, ouvrir l'album « Gouvernance », ajouter un nouveau PDF + modifier une couverture + réordonner ; vérifier sur `/mediatheque/gouvernance` ET sur `/a-propos/gouvernance` que les changements sont reflétés après rafraîchissement.

### Implementation for User Story 3

- [X] T021 [US3] Ouvrir `usenghor_nuxt/app/pages/admin/mediatheque/albums/[id].vue` (et composants associés type `MediaFormModal` / `MediaCard`) pour vérifier qu'il est possible de définir ou modifier `thumbnail_url` d'un média lors de l'ajout/édition. Si le champ n'est pas exposé dans le formulaire : ajouter un champ de type `file` ou `url` libellé « Image de couverture (optionnel) » lié à `thumbnail_url`, sans casser les autres types de médias.
- [X] T022 [US3] Si l'UI admin upload un fichier image pour la couverture, s'assurer que l'appel passe le `thumbnail_url` résultant dans le payload `POST /api/admin/albums/{id}/media` ou dans un `PUT /api/admin/media/{media_id}` subséquent (selon l'implémentation existante).
- [X] T023 [US3] Valider manuellement selon `quickstart.md` §7 :
  1. Ajouter un PDF avec couverture → apparaît sur les 2 pages publiques, vignette OK.
  2. Drag & drop de réordonnancement → l'ordre est reflété publiquement.
  3. Retrait d'un document → disparaît des 2 vues.
  4. Modification de la couverture d'un document existant → nouvelle vignette visible côté public.

**Checkpoint**: US3 fonctionnelle — l'équipe éditoriale a un point de gestion unique cohérent avec la médiathèque.

---

## Phase 6: User Story 4 — Dépréciation du champ JSON éditorial (Priority: P2)

**Goal**: Le champ `governance.foundingTexts.documents` n'apparaît plus comme éditable dans l'admin éditorial de la page gouvernance. Une note informe l'admin que la gestion passe par la médiathèque.

**Independent Test**: Ouvrir l'admin éditorial de la page gouvernance, constater que le champ `documents` est désactivé/non éditable, et que la note + lien vers l'admin médiathèque sont visibles.

### Implementation for User Story 4

- [X] T024 [US4] Modifier `usenghor_nuxt/app/composables/editorial-pages-config.ts` autour de la ligne 1177 (section `governance-founding-texts`), champ `governance.foundingTexts.documents` :
  - Passer `editable: false`.
  - Remplacer la clé `description` existante par (ou ajouter à la suite) un texte FR explicite : « Documents fondateurs désormais gérés dans la médiathèque — Album Gouvernance. »
  - Ajouter si la structure le permet une clé `redirectLink: '/admin/mediatheque/albums'` (ou libellé équivalent compatible avec la config existante).
  - Conserver le champ lui-même dans la config (ne pas le supprimer) pour tracer la dépréciation.
- [X] T025 [US4] Vérifier le composant qui rend les champs éditoriaux (probablement dans `usenghor_nuxt/app/components/admin/editorial/` ou un composant similaire référencé par la page d'édition éditoriale) : s'assurer que `editable: false` désactive effectivement le champ (grisé, non cliquable, pas d'appel d'enregistrement). Si non déjà géré, ajouter un rendu conditionnel minimal : `v-if="!field.editable"` affiche la note + le lien, désactive les boutons de modification.
- [X] T026 [US4] Valider manuellement :
  1. Se connecter en admin, ouvrir l'édition éditoriale de la page gouvernance.
  2. Vérifier que le champ `Documents fondateurs` apparaît en lecture seule avec la note + lien cliquable vers `/admin/mediatheque/albums`.
  3. Vérifier que les autres champs texte (`badge`, `title`, `description`, `donorCountries.*`) restent parfaitement éditables.

**Checkpoint**: US4 terminée — une seule source de vérité pour la liste des documents fondateurs, côté médiathèque.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: QA finale, tests ciblés optionnels, code review, préparation déploiement prod.

- [ ] T027 [P] (Optionnel) Ajouter un test pytest dans `usenghor_backend/tests/test_media_service.py` (créer le fichier si absent) vérifiant que `get_album_by_slug('gouvernance')` retourne les `media_items` triés par `display_order` croissant. Utiliser un fixture qui insère 3 médias avec `display_order` 2, 0, 1 et vérifier l'ordre renvoyé. Marquer `@pytest.mark.integration`.
- [ ] T028 [P] (Optionnel) Ajouter un test unitaire Vitest dans `usenghor_nuxt/tests/unit/mapMediaToFoundingDocument.spec.ts` (créer si absent) pour le mapper inline : cas avec `credits` numérique, `credits` vide, `thumbnail_url` null, `description` null.
- [X] T029 Tester l'idempotence : relancer `032_gouvernance_album.sql` et confirmer qu'aucune nouvelle ligne n'est créée (requête de comptage avant/après identique). Confirmer que modifier la clé éditoriale source puis relancer met à jour correctement les `media` existants.
- [X] T030 Tester le rollback : exécuter `032_gouvernance_album_rollback.sql` en local, vérifier la suppression de l'album + médias issus de la migration ET la préservation d'un média ajouté manuellement en admin entre-temps. Après rollback, relancer la migration pour restaurer l'état.
- [X] T031 Invoquer l'agent `database-reviewer` sur `usenghor_backend/documentation/modele_de_données/migrations/032_gouvernance_album.sql` et son rollback. Traiter les issues CRITICAL/HIGH.
- [X] T032 Invoquer l'agent `code-reviewer` sur le diff global (backend + frontend). Traiter les issues CRITICAL/HIGH.
- [ ] T033 Suivre `quickstart.md` §11 (checklist de release) intégralement : toutes les cases doivent être cochées.
- [ ] T034 Déployer en production selon `quickstart.md` §10 : `docker exec -i usenghor_db psql -U usenghor -d usenghor < migrations/032_gouvernance_album.sql`. Vérifier sur le site public que tout fonctionne (§10 + §13).
- [ ] T035 Commit + PR vers `main` avec un message clair : `feat: migrate governance founding texts to media album (spec 018)`. Inclure dans la description un lien vers `spec.md` et `quickstart.md`.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: aucune dépendance, peut démarrer immédiatement.
- **Foundational (Phase 2)**: dépend de Phase 1. **Bloque toutes les user stories**. T002 → T003 → T004 (SQL source avant migrations). T005/T006 parallélisables entre eux mais doivent précéder T007/T008. T007 précède T008.
- **US1 (Phase 3)**: dépend de Phase 2 complète. Indépendante de US2/US3/US4.
- **US2 (Phase 4)**: dépend de Phase 2 complète. Indépendante de US1/US3/US4 (mais partage la même source de données).
- **US3 (Phase 5)**: dépend de Phase 2 complète. Peut bénéficier de US1 (navigation admin plus confortable si médiathèque publique OK) mais indépendante.
- **US4 (Phase 6)**: dépend de Phase 2 complète. Indépendante des autres.
- **Polish (Phase 7)**: dépend des user stories livrées (au minimum US1+US2 pour le MVP).

### User Story Dependencies

- US1 & US2 : toutes deux P1, indépendantes l'une de l'autre après Phase 2. À implémenter tôt.
- US3 : P2, se prête au test manuel une fois US1 livrée.
- US4 : P2, purement admin, indépendante des US publiques.

### Within Each User Story

- Pas de tests automatisés obligatoires → validation manuelle selon `quickstart.md`.
- Backend avant frontend (T009/T010/T011 avant T014, etc.).
- i18n (T015/T016/T017) avant le composant qui les consomme (T018).

### Parallel Opportunities

- **Phase 2** : T005 ∥ T006 après T002. Puis T007 séquentiel, T008 séquentiel.
- **Phase 3 (US1)** : T012 ∥ T013 après T011.
- **Phase 4 (US2)** : T015 ∥ T016 ∥ T017 entre eux. T018 et T019 doivent attendre T015–T017. T020 en dernier.
- **Phase 7** : T027 ∥ T028.

---

## Parallel Example: Phase 2 Foundational

```bash
# Après T002, T003, T004 séquentiels (SQL source puis migrations) :
Task: "T005 [P] Ajouter thumbnail_url au modèle SQLAlchemy Media dans usenghor_backend/app/models/media.py"
Task: "T006 [P] Ajouter thumbnail_url aux schémas Pydantic dans usenghor_backend/app/schemas/media.py"
# Puis séquentiel :
Task: "T007 Exécuter la migration en local et vérifier"
Task: "T008 Vérifier Swagger expose thumbnail_url"
```

## Parallel Example: Phase 4 User Story 2 (i18n)

```bash
# Les 3 fichiers de traduction peuvent être mis à jour simultanément :
Task: "T015 [P] [US2] Ajouter preview/emptyState dans usenghor_nuxt/i18n/locales/fr/governance.json"
Task: "T016 [P] [US2] Ajouter preview/emptyState dans usenghor_nuxt/i18n/locales/en/governance.json"
Task: "T017 [P] [US2] Ajouter preview/emptyState dans usenghor_nuxt/i18n/locales/ar/governance.json"
```

---

## Implementation Strategy

### MVP (US1 + US2)

1. Phase 1 (T001) — vérification environnement.
2. Phase 2 (T002–T008) — schéma + migration SQL + modèles/schemas Pydantic.
3. Phase 3 (T009–T014) — US1 publique médiathèque.
4. Phase 4 (T015–T020) — US2 page gouvernance.
5. **STOP & validate** : à ce stade, le visiteur public voit tout ce qu'il doit voir. Le MVP est livrable.

### Incremental Delivery

1. MVP (Phase 1→4) → démo / déploiement éventuel.
2. US3 (Phase 5) → confort admin sur la médiathèque.
3. US4 (Phase 6) → hygiène éditoriale, source de vérité unique.
4. Polish (Phase 7) → QA finale, tests optionnels, déploiement prod.

### Parallel Team Strategy

Avec 2 développeurs après Phase 2 :

- Dev A : US1 (Phase 3) — backend/service + vérif médiathèque publique.
- Dev B : US2 (Phase 4) — frontend gouvernance + i18n.
- Ensuite un seul dev peut traiter US3 + US4 en série (petits changements).

---

## Notes

- [P] tasks = fichiers distincts, aucune dépendance en cours.
- Chaque user story est indépendamment testable (cf. spec.md).
- Aucun test automatisé obligatoire ; les tests de Phase 7 sont optionnels mais recommandés pour le mapper et le tri SQL.
- Commit après chaque phase logique (Phase 2, puis une par user story, puis Polish).
- Checkpoint à la fin de Phase 2, puis après chaque US avant de passer à la suivante.
- Éviter de modifier `FoundingTextsSection.vue` et `gouvernance.vue` en même temps sans coordination (fichiers interdépendants).
