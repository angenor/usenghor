# Feature Specification: Associer une médiathèque aux événements et actualités

**Feature Branch**: `012-media-events-news`
**Created**: 2026-03-24
**Status**: Draft
**Input**: User description: "on veut pouvoir associer une médiathèque à un événement et une actualité, visible dans un onglet sur les pages de détail"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Associer des albums à un événement (Priority: P1)

En tant qu'administrateur, je veux pouvoir associer un ou plusieurs albums de la médiathèque à un événement, afin d'illustrer cet événement avec des galeries photos/vidéos.

**Why this priority**: C'est la fonctionnalité principale demandée. Les événements (conférences, cérémonies, ateliers) génèrent beaucoup de contenu visuel qui doit être présenté de manière organisée.

**Independent Test**: Peut être testé en créant un événement dans l'admin, en lui associant un album existant, puis en vérifiant que l'album apparaît dans l'onglet médiathèque de la page publique de l'événement.

**Acceptance Scenarios**:

1. **Given** un événement existant et des albums publiés dans la médiathèque, **When** l'administrateur édite l'événement et sélectionne un ou plusieurs albums, **Then** les albums sont associés à l'événement et sauvegardés.
2. **Given** un événement avec des albums associés, **When** l'administrateur retire un album de la sélection, **Then** l'association est supprimée sans affecter l'album lui-même.
3. **Given** un événement avec des albums associés, **When** un visiteur consulte la page publique de l'événement, **Then** un onglet "Médiathèque" affiche les albums avec leurs médias (images, vidéos).

---

### User Story 2 - Associer des albums à une actualité (Priority: P1)

En tant qu'administrateur, je veux pouvoir associer un ou plusieurs albums de la médiathèque à une actualité, afin d'enrichir les articles avec du contenu visuel organisé.

**Why this priority**: Même niveau que les événements car la demande couvre les deux entités de manière équivalente.

**Independent Test**: Peut être testé en créant une actualité dans l'admin, en lui associant un album, puis en vérifiant l'affichage dans l'onglet médiathèque de la page publique de l'actualité.

**Acceptance Scenarios**:

1. **Given** une actualité existante et des albums publiés, **When** l'administrateur édite l'actualité et sélectionne un ou plusieurs albums, **Then** les albums sont associés à l'actualité.
2. **Given** une actualité avec des albums associés, **When** l'administrateur retire un album, **Then** l'association est supprimée sans affecter l'album.
3. **Given** une actualité avec des albums associés, **When** un visiteur consulte la page publique de l'actualité, **Then** un onglet "Médiathèque" affiche les albums et leurs contenus.

---

### User Story 3 - Affichage de la médiathèque dans un onglet dédié (Priority: P1)

En tant que visiteur, je veux voir les albums associés à un événement ou une actualité dans un onglet "Médiathèque" sur la page de détail, afin de parcourir facilement les photos et vidéos liées.

**Why this priority**: L'affichage public est indissociable de l'association elle-même ; sans onglet visible, la fonctionnalité n'a pas de valeur pour les visiteurs.

**Independent Test**: Peut être testé en naviguant vers une page de détail d'un événement ou d'une actualité ayant des albums associés et en vérifiant que l'onglet est présent et fonctionnel.

**Acceptance Scenarios**:

1. **Given** un événement/actualité avec des albums associés, **When** le visiteur arrive sur la page de détail, **Then** un onglet "Médiathèque" est visible parmi les onglets disponibles.
2. **Given** un événement/actualité sans album associé, **When** le visiteur arrive sur la page de détail, **Then** l'onglet "Médiathèque" n'est pas affiché.
3. **Given** le visiteur est dans l'onglet "Médiathèque", **When** il parcourt les albums, **Then** il voit les miniatures des médias organisées par album, avec possibilité de visualiser en grand (lightbox ou modal).
4. **Given** un album contenant des images et des vidéos, **When** le visiteur consulte la médiathèque, **Then** les images sont affichées en grille et les vidéos sont lisibles directement.

---

### User Story 4 - Gestion de l'ordre d'affichage des albums (Priority: P2)

En tant qu'administrateur, je veux pouvoir réordonner les albums associés à un événement ou une actualité, afin de contrôler l'ordre de présentation.

**Why this priority**: Utile mais pas bloquant pour le lancement ; un ordre par défaut (date d'association) suffit initialement.

**Independent Test**: Peut être testé en associant plusieurs albums à un événement, en modifiant leur ordre dans l'admin, puis en vérifiant que l'ordre est respecté sur la page publique.

**Acceptance Scenarios**:

1. **Given** un événement avec plusieurs albums associés, **When** l'administrateur modifie l'ordre d'affichage, **Then** le nouvel ordre est sauvegardé et respecté sur la page publique.

---

### Edge Cases

- Que se passe-t-il si un album associé est supprimé de la médiathèque ? L'association doit être supprimée en cascade, et l'onglet ne doit plus montrer cet album.
- Que se passe-t-il si un album associé est passé en brouillon (draft) ? Il ne doit plus apparaître sur la page publique mais reste visible dans l'admin.
- Que se passe-t-il si tous les albums associés sont en brouillon ou supprimés ? L'onglet "Médiathèque" ne doit pas apparaître sur la page publique.
- Que se passe-t-il si un même album est associé à plusieurs événements/actualités ? C'est permis, un album peut être partagé entre plusieurs contenus.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT permettre d'associer un ou plusieurs albums à un événement via l'interface d'administration.
- **FR-002**: Le système DOIT permettre d'associer un ou plusieurs albums à une actualité via l'interface d'administration.
- **FR-003**: Le système DOIT afficher un onglet "Médiathèque" sur la page de détail publique d'un événement lorsqu'au moins un album publié y est associé.
- **FR-004**: Le système DOIT afficher un onglet "Médiathèque" sur la page de détail publique d'une actualité lorsqu'au moins un album publié y est associé.
- **FR-005**: L'onglet "Médiathèque" DOIT se masquer automatiquement lorsqu'aucun album publié n'est associé.
- **FR-006**: Le système DOIT afficher les médias de chaque album (images en grille, vidéos lisibles) dans l'onglet "Médiathèque".
- **FR-007**: Le système DOIT permettre de visualiser les images en taille réelle (lightbox ou modal) depuis l'onglet "Médiathèque".
- **FR-008**: Le système DOIT permettre de dissocier un album d'un événement ou d'une actualité sans supprimer l'album lui-même.
- **FR-009**: Le système DOIT permettre de définir un ordre d'affichage pour les albums associés.
- **FR-010**: Le système DOIT supprimer automatiquement les associations lorsqu'un album ou un événement/actualité est supprimé (suppression en cascade).
- **FR-011**: Le système DOIT filtrer les albums en brouillon (draft) ou archivés de l'affichage public, tout en les conservant visibles dans l'administration.

### Key Entities

- **Album** : Collection de médias (images, vidéos, documents, audio) avec un titre, une description et un statut de publication. Entité existante.
- **Événement** : Événement organisé par l'université. Entité existante. Possède déjà une table d'association `event_media_library` pour les albums.
- **Actualité** : Article d'actualité publié par l'université. Entité existante. Nécessite une nouvelle association au niveau album.
- **Association événement-albums** : Relation N:N entre événements et albums, avec ordre d'affichage. Table existante à enrichir.
- **Association actualité-albums** : Relation N:N entre actualités et albums, avec ordre d'affichage. Nouvelle relation à créer.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Un administrateur peut associer un album à un événement ou une actualité en moins de 30 secondes depuis le formulaire d'édition.
- **SC-002**: L'onglet "Médiathèque" s'affiche en moins de 2 secondes sur les pages de détail publiques, même avec 5 albums contenant chacun 50 médias.
- **SC-003**: 100% des albums en brouillon ou archivés sont invisibles sur les pages publiques.
- **SC-004**: La suppression d'un album entraîne la suppression automatique de toutes ses associations sans erreur.
- **SC-005**: Les visiteurs peuvent visualiser les images en taille réelle et lire les vidéos directement depuis l'onglet "Médiathèque" sans quitter la page.

## Assumptions

- Les albums et médias sont déjà gérés dans la médiathèque existante (tables `albums`, `media`, `album_media`).
- La table `event_media_library` existe déjà en base de données pour l'association événement-albums (sans `display_order`).
- La table `news_media` existe pour les médias individuels associés aux actualités, mais une nouvelle association au niveau album sera nécessaire pour les actualités.
- Le composant de sélection d'albums dans l'admin suivra le pattern existant de sélection d'entités (dropdown/modal avec recherche).
- L'onglet "Médiathèque" s'intègre dans le système d'onglets existant des pages de détail des événements et actualités.
- Les médias sont déjà accessibles via l'endpoint public `/api/public/media/{uuid}/download`.
