# Phase 0 — Research: Album médiathèque « Gouvernance »

**Feature**: 018-governance-media-album
**Date**: 2026-04-16
**Branch**: `018-governance-media-album`

## Objectif

Lever toutes les inconnues techniques détectées à partir de la spec et des clarifications (Q1–Q5), et fixer les décisions de conception avant d'écrire les contrats et le modèle de données.

## Inventaire des inconnues

À partir de la spec clarifiée :

1. Schéma exact des tables `albums`, `media`, `album_media` et migration en cours.
2. Forme actuelle des données éditoriales `governance.foundingTexts.documents` en base.
3. Endpoints publics albums effectivement disponibles et leurs schémas de réponse.
4. Mécanisme de couverture (cover / thumbnail) pour un média de type `document`.
5. Capacité du composant de prévisualisation existant à gérer les PDF.
6. Pattern de configuration éditoriale pour marquer un champ « non éditable / déprécié ».
7. Modalités d'idempotence et de rollback en SQL pur.

---

## Décision 1 — Colonne `thumbnail_url` sur `media` (résolution d'incohérence schéma ⇄ types TS)

**Contexte**
- `03_media.sql` (lignes 16–32) définit la table `media` avec `url`, `alt_text`, `credits`, mais **aucune colonne `thumbnail_url`**.
- Le schéma Pydantic `MediaRead` (`app/schemas/media.py` lignes 52–67) **n'expose pas `thumbnail_url`** non plus.
- Le type TypeScript `MediaRead` côté frontend (`app/types/api/media.ts:21`) **déclare `thumbnail_url: string | null`**. Incohérence préexistante avec le backend.
- La spec exige que chaque document fondateur ait une couverture visible dans les flip cards (FR-004, FR-012) et dans la vue album médiathèque (FR-009, Q4).

**Decision**: Ajouter la colonne `thumbnail_url VARCHAR(500) NULL` à la table `media`, mettre à jour le fichier source SQL `03_media.sql`, exposer le champ dans `MediaCreate` / `MediaUpdate` / `MediaRead` Pydantic, et le renseigner lors de la migration de gouvernance pour chaque document PDF.

**Rationale**
- Aligne le schéma réel avec le contrat TypeScript déjà publié côté frontend (correction d'une dette technique).
- Évite tout hack (stocker une URL d'image dans `alt_text` ou `credits`).
- Coût minimal : colonne nullable, aucun impact sur les médias existants.
- Couvre aussi le besoin générique « couverture pour un PDF/vidéo/audio » qui reviendra pour d'autres features.

**Alternatives rejetées**
- *A. Utiliser `alt_text` ou `credits` pour porter l'URL* — sale, mélange des responsabilités, casse la sémantique des colonnes existantes.
- *B. Créer un média-image séparé et le lier via `cover_media_id UUID`* — refactor plus large, introduit une auto-référence sur `media`, allonge les queries N+1 pour la médiathèque publique ; gain faible pour cette feature.
- *C. Ne pas gérer de thumbnail côté backend, afficher une icône PDF générique partout* — régression visible (les flip cards actuelles ont des couvertures dédiées), inacceptable pour FR-012.

---

## Décision 2 — Identification des items migrés via `media.url`

**Contexte**
- Q1 a tranché : idempotence et rollback basés sur l'URL du fichier source.
- Pas de colonne « tag de migration » ajoutée (choix délibéré de limiter les changements de schéma, cf. Q1/Q4 du clarify).

**Decision**
- **Insertion idempotente** : pour chaque URL issue de `governance.foundingTexts.documents`, la migration exécute `INSERT ... SELECT ... WHERE NOT EXISTS (SELECT 1 FROM media WHERE url = src.url)`. Si le média existe déjà (même URL), on ne le recrée pas ; si nécessaire, on met à jour ses champs (UPDATE par `url`).
- **Liaison album ⇄ média idempotente** : `INSERT INTO album_media ... ON CONFLICT (album_id, media_id) DO UPDATE SET display_order = EXCLUDED.display_order` pour permettre de corriger l'ordre à la ré-exécution.
- **Création d'album idempotente** : `INSERT INTO albums (slug, title, description, status) VALUES ('gouvernance', ...) ON CONFLICT (slug) DO UPDATE SET description = EXCLUDED.description` (préserve l'ID si l'album existe déjà).
- **Rollback** : un fichier `032_gouvernance_album_rollback.sql` supprime les lignes `album_media` et `media` dont l'URL figure dans une liste connue (encodée directement dans le script via `WHERE url IN (...)` ou via lecture de la clé éditoriale source si encore présente), puis supprime l'album `gouvernance` uniquement s'il ne contient plus aucun média.

**Rationale**
- Zéro migration de schéma supplémentaire.
- `media.url` est déjà stable (URLs CDN / paths internes déjà en place — cf. A5 de la spec).
- La logique SQL reste lisible, sans procédure stockée, sans table d'audit.
- Robuste en cas de re-run : c'est le cas nominal sur prod si on veut corriger un libellé.

**Alternatives rejetées**
- *Colonne `migration_source VARCHAR(50)` sur `media`* — violerait le principe « pas d'altération de schéma hors nécessité ».
- *Table séparée `migration_governance_items`* — complexité pour zéro bénéfice net.

---

## Décision 3 — Réutilisation des endpoints publics existants

**Contexte**
- La spec impose « aucun nouvel endpoint d'API public » (FR-023).
- Les endpoints publics albums existent déjà :
  - `GET /api/public/albums` (paginé, filtrable par type de média, inclut `cover_media`, `media_count`).
  - `GET /api/public/albums/by-slug/{slug}` (retourne un `AlbumWithMedia`).
  - Filtre : `status == PUBLISHED` ET album non vide.

**Decision**
- La page `/a-propos/gouvernance` consommera `getAlbumBySlug('gouvernance')` via `usePublicAlbumsApi` (composable existant).
- La médiathèque `/mediatheque` et `/mediatheque/[slug]` n'exigent aucune modification de code (l'album apparaîtra automatiquement dès publication).
- **Ajustement mineur requis** sur le schéma Pydantic `MediaRead` pour exposer le nouveau champ `thumbnail_url` (cf. Décision 1). Ceci ne modifie pas la forme de l'endpoint, seulement l'enrichit.
- **Vérification à faire pendant l'implémentation** : confirmer que `cover_media` (dans `PublicAlbumListItem`) est bien construit à partir du premier média de l'album selon `display_order`, comme requis par Q4. Si la dérivation n'est pas automatique, ajuster `media_service.get_published_albums_list()` pour trier par `display_order ASC` avant de prendre le premier média.

**Rationale**
- Respecte FR-023.
- Fait évoluer les contrats a minima (ajout d'un champ nullable, rétrocompatible).

**Alternatives rejetées**
- *Créer un endpoint dédié `/api/public/governance/founding-texts`* — duplication inutile ; la page gouvernance est la seule consommatrice spécifique et `getAlbumBySlug` suffit.

---

## Décision 4 — Consommation côté page gouvernance : mapper inline

**Contexte**
- `FoundingTextsSection.vue` (lignes 2–20) attend un type `FoundingDocument` avec des champs `title_fr`, `description_fr`, `file_url`, `file_size`, `year`, `cover_image`, `sort_order`.
- L'API publique retournera désormais un `AlbumWithMedia` contenant `media_items: MediaRead[]` avec des champs `name`, `description`, `url`, `size_bytes`, `thumbnail_url`, `credits`.
- Q3 a tranché : titres FR affichés tels quels en EN/AR.
- Q5 a tranché : l'année est stockée brute dans `credits` (ex. `"2015"`).

**Decision**
- Introduire un **mapper inline dans `gouvernance.vue`** (fonction `mapMediaToFoundingDocument(media: MediaRead): FoundingDocument`) qui transforme chaque `MediaRead` en `FoundingDocument`, puis transmet au composant existant via le même prop `documents`.
- **Laisser intact le contrat du composant `FoundingTextsSection.vue`** : il continue de recevoir `FoundingDocument[]`. Avantage : zéro régression dans les tests ou ailleurs si le composant est réutilisé, zéro ambiguïté dans les bindings template existants.
- Ajouter en plus un troisième bouton « Prévisualiser » dans `FoundingTextsSection.vue` qui émet un événement `preview(doc)` vers le parent ; le parent ouvre `MediaFilePreviewModal` avec le `MediaRead` d'origine (conservé dans une map `foundingId → mediaRead` pour passage au modal).

**Rationale**
- Le mapping inline localisé (dans `gouvernance.vue`) reste testable et simple ; pas de fichier utilitaire créé pour une seule occurrence.
- Conservation du composant comme contrat stable : une future migration vers `MediaRead` natif pourra être faite sans bloquant cette feature.
- La conservation de la map côté parent évite de polluer `FoundingDocument` avec un champ `_raw` non typé.

**Alternatives rejetées**
- *Réécrire `FoundingTextsSection.vue` pour consommer `MediaRead` directement* — refactor plus invasif, plus de tests à mettre à jour, sans bénéfice direct (le composant n'a qu'un seul consommateur).
- *Créer un composable `useGovernanceDocuments()` avec mapping intégré* — sur-ingénierie pour une transformation de ~10 lignes.

---

## Décision 5 — Visualisation PDF inline

**Contexte**
- `MediaFilePreviewModal.vue` existe déjà et gère nativement les PDF inline via `<iframe>` (confirmé par l'exploration).
- Le prompt d'origine demande d'ajouter un bouton de prévisualisation sur les flip cards.

**Decision**
- Réutiliser `MediaFilePreviewModal` tel quel côté `/a-propos/gouvernance` (import direct).
- Le bouton « Prévisualiser » émet un event vers le parent `gouvernance.vue`, qui gère l'ouverture du modal (même pattern que `/mediatheque/[slug]`).
- Ne pas passer `items/currentIndex` (navigation multi-média) depuis la page gouvernance : seul le document cliqué est prévisualisé, car la navigation séquentielle n'a pas été demandée par la spec. En revanche, on pourra facilement l'activer plus tard en passant `items: foundingMediaList`.

**Rationale**
- Zéro dépendance ajoutée, zéro duplication de logique.
- Comportement identique à celui de la médiathèque, ce qui garantit la cohérence UX.

**Alternatives rejetées**
- *Créer une modale dédiée gouvernance* — duplication inutile.
- *Ouvrir le PDF en nouvel onglet (comme aujourd'hui pour le bouton « voir »)* — déjà disponible, mais FR-013 exige un bouton prévisualisation inline distinct.

---

## Décision 6 — Configuration éditoriale : marquer le champ `documents` comme non éditable

**Contexte**
- `editorial-pages-config.ts` ligne 1177 expose le champ `documents` avec `editable: true` et `type: 'documents'`.
- La spec (FR-018, US4) demande de ne plus présenter ce champ comme éditable et d'indiquer où gérer désormais les documents.
- La config supporte déjà une clé `editable: boolean` sur chaque champ (pattern existant).

**Decision**
- Passer `editable: false` sur le champ `governance.foundingTexts.documents`.
- Ajouter une nouvelle clé optionnelle `deprecationNote?: string` (ou réutiliser la clé `description` existante) qui porte le texte d'explication : « Gestion désormais via la médiathèque admin — Album Gouvernance. ». Ajouter aussi `redirectLink?: string` pointant vers `/admin/mediatheque/albums?search=Gouvernance` (ou mieux : un lien direct `/admin/mediatheque/albums/{albumId}` — mais l'ID étant dynamique, on pointe plutôt vers la liste filtrée).
- **Côté rendu admin**, l'éditeur éditorial doit reconnaître `editable: false` pour griser le champ et afficher `deprecationNote` + lien. Si cette distinction n'est pas déjà gérée, passer en premier par la mise à jour de la config + un rendu conditionnel discret dans le composant d'édition éditorial.
- Ne pas supprimer la clé `governance.foundingTexts.documents` de la config (pour préserver l'affichage « historique » en lecture si besoin), mais documenter qu'elle n'est plus la source de vérité.

**Rationale**
- Pattern rétrocompatible : un bouléen + un texte explicatif, comme d'autres champs dépréciés du projet.
- Pas besoin de toucher à l'ordre ou à l'identité des sections existantes.
- L'admin reste informé du bon emplacement de gestion.

**Alternatives rejetées**
- *Supprimer entièrement l'entrée `documents` de la config* — perdrait la trace de la dépréciation, l'admin verrait le champ disparaître sans explication.
- *Créer une section « dépréciée » globale* — sur-ingénierie pour un seul champ.

---

## Décision 7 — Scripts de migration/rollback : exécution et localisation

**Contexte**
- Convention du projet : `usenghor_backend/documentation/modele_de_données/migrations/NNN_description.sql`, numéros séquentiels, dernière migration = `031_coverage_item_varchar500.sql`.
- Exécution locale : `docker exec -i usenghor_postgres psql -U usenghor -d usenghor < migrations/NNN.sql`.
- Exécution prod : `docker exec -i usenghor_db psql -U usenghor -d usenghor < migrations/NNN.sql`.
- Convention nommage fichiers : `[a-z0-9_-]` uniquement (pas d'accents), cf. CLAUDE.md.

**Decision**
- Deux fichiers livrés :
  - `032_gouvernance_album.sql` — migration forward, idempotente, contenant :
    1. `ALTER TABLE media ADD COLUMN IF NOT EXISTS thumbnail_url VARCHAR(500);`
    2. `INSERT INTO albums (slug, title, description, status) VALUES ('gouvernance', 'Gouvernance', 'Textes fondateurs de l''Université Senghor (chartes, conventions, statuts).', 'published') ON CONFLICT (slug) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status RETURNING id;`
    3. Utilisation d'un bloc `DO $$ ... $$` ou d'une `WITH` CTE pour itérer sur le JSON array extrait de `editorial_contents WHERE key = 'governance.foundingTexts.documents'` et insérer chaque document + lien album_media (idempotent par URL).
  - `032_gouvernance_album_rollback.sql` — script inverse :
    1. Supprime les lignes `album_media` pour l'album `gouvernance` et les URL connues.
    2. Supprime les médias dont l'URL correspond à la liste source et qui ne sont plus référencés par `album_media` (safety : `NOT EXISTS` clause).
    3. Supprime l'album `gouvernance` si et seulement si `album_media WHERE album_id = gouvernance.id` est vide.
    4. Ne touche PAS à la colonne `thumbnail_url` (la colonne reste en place même après rollback, c'est un enrichissement de schéma durable).
- Les deux scripts commencent par `BEGIN;` et se terminent par `COMMIT;` pour atomicité.
- Des `RAISE NOTICE` via `DO $$ ... $$` informent du nombre de lignes insérées/ignorées.

**Rationale**
- Respecte strictement la convention de nommage et d'exécution du projet.
- Atomique → si une ligne pose problème, tout est rollbacké sans laisser l'album orphelin.
- Rollback non destructif sur le schéma (conserve la colonne `thumbnail_url` ajoutée).

**Alternatives rejetées**
- *Scripts Python avec SQLAlchemy + Alembic* — le projet n'utilise pas Alembic pour ces migrations métier ; on reste cohérent avec les 31 migrations précédentes en SQL pur.

---

## Décision 8 — Mise à jour minimale côté service backend

**Contexte**
- `get_published_albums_list()` (service/media_service.py) produit la vignette `cover_media` pour l'onglet « Albums » de la médiathèque publique.
- Q4 impose : vignette dérivée du premier document selon `display_order`.

**Decision**
- **Vérifier** (pendant l'implémentation) que le tri par `display_order ASC` est bien appliqué avant d'extraire `cover_media`. Si non, ajuster la query (`ORDER BY am.display_order ASC NULLS LAST, m.created_at ASC LIMIT 1`).
- Exposer le nouveau champ `thumbnail_url` dans `MediaRead` (Pydantic) et dans le build de `CoverMedia` → mais **`CoverMedia` utilise `url`, pas `thumbnail_url`**. Pour un média de type `document`, on privilégiera l'URL du thumbnail pour la vignette d'album : donc **`CoverMedia.url` sera rempli avec `media.thumbnail_url` si présent, sinon `media.url`**. Ou plus propre : ajouter `thumbnail_url: str | None` à `CoverMedia` et laisser le front choisir.

**Recommandation finale** : ajouter `thumbnail_url: str | None` à `CoverMedia` (rétrocompatible), le frontend `/mediatheque` l'utilisera si présent pour afficher la vignette d'album (logique déjà probablement en place puisque le type TS l'attend). Validation à faire dans la phase 1 (tasks).

**Rationale**
- Minimise le changement contractuel tout en fournissant la donnée nécessaire.
- Reste rétrocompatible (champ nullable).

**Alternatives rejetées**
- *Overloader `url` avec la valeur de thumbnail_url côté service* — casserait la sémantique de `CoverMedia.url` et risquerait de casser d'autres consommateurs qui attendent l'URL du fichier.

---

## Récapitulatif des dépendances et contraintes validées

| Élément | État |
|--------|------|
| Tables `albums`, `media`, `album_media` | Existantes, prêtes |
| Endpoints publics albums (`list`, `by-slug`) | Existants, réutilisables tels quels |
| Composable frontend `usePublicAlbumsApi` | Existant, méthode `getAlbumBySlug` disponible |
| Composant `MediaFilePreviewModal` | Existant, supporte PDF inline via iframe |
| Composant `FoundingTextsSection` | À adapter (ajout bouton « Prévisualiser » + émission d'événement) |
| Page `/a-propos/gouvernance` | À adapter (appel API + mapper + gestion modal) |
| Config éditoriale `editorial-pages-config.ts` | À adapter (`editable: false` + note de redirection) |
| Schéma `media` SQL | À enrichir (colonne `thumbnail_url`) |
| Schéma `MediaRead` Pydantic | À enrichir (champ `thumbnail_url`) |
| i18n governance | Existant, clés `voir` / `télécharger` réutilisables ; à ajouter : `preview`, `emptyState` |

## NEEDS CLARIFICATION résiduels

Aucun. Toutes les inconnues critiques ont été résolues via la spec (Q1–Q5) ou les décisions ci-dessus (D1–D8).

## Risques identifiés et mitigations

| Risque | Impact | Mitigation |
|--------|--------|------------|
| `CoverMedia.url` ne pointe pas vers la vignette en prod | Vignette d'album cassée ou absente dans `/mediatheque` | Ajouter `thumbnail_url` à `CoverMedia` ; fallback frontend sur `url` si null |
| JSON éditorial source introuvable au moment de la migration | Album créé vide | Script poursuit sans erreur, log un `NOTICE`, l'admin peuple ensuite |
| Tri par `display_order` non appliqué dans `media_service.get_album_by_slug()` | Ordre des flip cards incorrect | Contrôle pendant implémentation ; ajuster la query si nécessaire |
| Double exécution en prod | — | Scripts idempotents, testés en local d'abord |
| Colonne `thumbnail_url` ajoutée mais aucun média historique n'a de valeur | Impact visuel sur d'autres albums | Aucun : colonne nullable, comportement identique aux médias existants |
