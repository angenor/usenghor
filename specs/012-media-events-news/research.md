# Research: 012-media-events-news

**Date**: 2026-03-24
**Branch**: `012-media-events-news`

## R1 - État actuel des tables d'association

### Decision
Réutiliser la table `event_media_library` existante (ajouter `display_order`) et créer une nouvelle table `news_media_library` sur le même modèle.

### Rationale
- `event_media_library` existe en SQL et dans le modèle SQLAlchemy, mais **aucun service method, endpoint, ou schema** ne l'exploite. Il faut tout construire côté applicatif.
- `news_media` existe pour des médias individuels (pas des albums). Pour les actualités, il faut une **nouvelle table** `news_media_library` pour l'association news→albums.
- Le champ `album_external_id` (1:1) sur `Event` peut coexister avec `event_media_library` (N:N) mais ils ont des usages différents. Le champ 1:1 sert d'album principal, le N:N sert à la médiathèque multi-albums.

### Alternatives considered
- Réutiliser `news_media` pour les albums → rejeté car cette table lie des médias individuels, pas des albums.
- Créer une table générique `content_media_library(content_type, content_id, album_id)` → rejeté car le pattern du projet utilise des tables de liaison dédiées par entité.

## R2 - Pattern d'endpoints pour les associations N:N

### Decision
Suivre le pattern Albums→Media : endpoints dédiés `POST /{entity_id}/albums`, `DELETE /{entity_id}/albums/{album_id}`, `PUT /{entity_id}/albums/reorder`.

### Rationale
Le codebase a un pattern mature dans `albums.py` :
- `POST /{album_id}/media` : ajoute des médias à un album (body: liste d'IDs)
- `DELETE /{album_id}/media/{media_id}` : retire un média
- `PUT /{album_id}/media/reorder` : réordonne les médias

Ce pattern est répliqué dans `fundraisers.py` pour fundraiser→media. Il est naturel de l'appliquer pour event→albums et news→albums.

### Alternatives considered
- Gérer les albums dans le payload de create/update (comme tags/campuses dans news) → rejeté car les albums sont des entités complexes avec un ordre, et le pattern dédié est plus flexible pour l'UX (ajout/retrait sans resoumettre tout le formulaire).

## R3 - Affichage public : ajout d'onglets aux pages de détail

### Decision
Ajouter un système d'onglets aux pages publiques de détail (événement et actualité) avec un onglet "Médiathèque" conditionnel.

### Rationale
- Les pages publiques actuelles n'ont **pas de système d'onglets** : elles sont en layout linéaire (hero → contenu → infos).
- Il faut introduire un système d'onglets minimal : "Détails" (contenu existant) + "Médiathèque" (nouveau, conditionnel).
- Les composants `MediaAlbumCard.vue` et `MediaAlbumModal.vue` existent déjà pour l'affichage des albums avec lightbox.

### Alternatives considered
- Afficher la médiathèque en section supplémentaire sans onglets → rejeté car l'utilisateur a explicitement demandé un onglet.
- Utiliser une bibliothèque de tabs tierce → rejeté car un système d'onglets simple avec Tailwind CSS suffit et reste cohérent avec le projet.

## R4 - Sélecteur d'albums dans l'admin

### Decision
Créer un composant `AlbumSelector.vue` réutilisable avec liste déroulante multi-sélection et preview des albums.

### Rationale
- L'admin event utilise actuellement un **simple champ texte UUID** pour `album_external_id` (avec la note "En production: sélecteur d'album").
- Il existe des patterns de sélection dans le codebase : toggle buttons pour les campus/services/tags (news), dropdowns pour les entités uniques (campus, projet).
- Pour les albums, un composant dédié avec recherche + preview miniature est plus adapté car les albums sont visuels.

### Alternatives considered
- Réutiliser le pattern toggle buttons (comme les tags) → rejeté car les albums nécessitent un aperçu visuel pour être identifiés.
- Dropdown simple avec noms → acceptable en MVP mais moins ergonomique.

## R5 - Endpoints publics pour récupérer les albums d'un contenu

### Decision
Ajouter des endpoints publics : `GET /api/public/events/{slug}/albums` et `GET /api/public/news/{slug}/albums` retournant uniquement les albums publiés avec leurs médias.

### Rationale
- L'endpoint public `GET /api/public/albums/{album_id}` existe déjà et retourne un album avec ses médias (si publié).
- Plutôt que de faire N appels (un par album), il est plus efficace d'avoir un endpoint dédié qui retourne tous les albums d'un contenu en une seule requête.
- Le filtrage par `status = published` doit être fait côté serveur.

### Alternatives considered
- Inclure les albums directement dans EventPublic/NewsPublic → rejeté car cela alourdit les réponses de liste et le chargement n'est nécessaire que sur la page de détail.
- Faire N appels via `GET /api/public/albums/{id}` côté frontend → rejeté pour des raisons de performance (N+1 queries).
