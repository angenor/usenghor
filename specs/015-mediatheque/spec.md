# Feature Specification: Médiathèque publique générale

**Feature Branch**: `015-mediatheque`
**Created**: 2026-03-28
**Status**: Draft
**Input**: User description: "On veut une médiathèque générale à la plateforme, où on mettra logos, rapports d'activité et d'événements etc."

## Clarifications

### Session 2026-03-28

- Q: Comment organiser la médiathèque publique (catégories dédiées ou albums existants) ? → A: La médiathèque publique est organisée par albums. Pas de nouvelle entité "catégorie" — les albums publiés sont le moyen d'organisation.
- Q: Présentation de la page médiathèque ? → A: Grille de cartes d'albums avec barre de recherche et filtres en haut de page.
- Q: Action au clic sur un album ? → A: Navigation vers une page dédiée `/mediatheque/{slug}` — lien partageable, meilleur SEO, visionneuse au clic sur un média individuel.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Consulter la médiathèque publique (Priority: P1)

Un visiteur du site accède à la page médiathèque depuis le menu principal. Il découvre une bibliothèque présentant tous les albums publiés (Logos, Rapports d'activité, Rapports d'événements, Photos officielles...). Il peut filtrer par type de média, parcourir les albums et télécharger les ressources qui l'intéressent.

**Why this priority**: C'est le coeur de la feature — sans page publique de consultation, la médiathèque n'a pas de raison d'être.

**Independent Test**: Un visiteur non connecté peut accéder à `/mediatheque`, voir les albums publiés, ouvrir un album, parcourir son contenu et télécharger un fichier.

**Acceptance Scenarios**:

1. **Given** un visiteur non connecté, **When** il accède à la page médiathèque, **Then** il voit tous les albums publiés sous forme de cartes de prévisualisation
2. **Given** la médiathèque affichée, **When** le visiteur filtre par type de média (image, document, vidéo...), **Then** seuls les albums contenant ce type de média apparaissent
3. **Given** la médiathèque affichée, **When** le visiteur effectue une recherche textuelle, **Then** les résultats correspondent au terme recherché (titre d'album, nom de média)
4. **Given** un album affiché, **When** le visiteur clique dessus, **Then** il est redirigé vers la page dédiée de l'album (`/mediatheque/{slug}`) affichant tous ses médias
5. **Given** un fichier affiché dans un album, **When** le visiteur clique sur le bouton de téléchargement, **Then** le fichier se télécharge sur son appareil

---

### User Story 2 - Naviguer dans un album depuis la médiathèque (Priority: P2)

Un visiteur ouvre un album depuis la médiathèque et navigue entre les médias dans une vue galerie/visionneuse. Il peut voir les images en plein écran, lire les vidéos/audios et télécharger les documents.

**Why this priority**: L'expérience de consultation au sein d'un album est essentielle pour que la médiathèque soit réellement utile et agréable.

**Independent Test**: Un visiteur clique sur un album, parcourt les médias un par un dans une visionneuse et télécharge un document PDF.

**Acceptance Scenarios**:

1. **Given** un album ouvert, **When** le visiteur clique sur une image, **Then** une visionneuse modale s'ouvre avec navigation entre les médias
2. **Given** la visionneuse ouverte, **When** le visiteur navigue, **Then** il peut passer d'un média à l'autre (précédent/suivant)
3. **Given** un album contenant des documents, **When** le visiteur clique sur un document, **Then** il peut le télécharger directement
4. **Given** un album contenant des vidéos, **When** le visiteur clique sur une vidéo, **Then** elle se lit dans la visionneuse

---

### Edge Cases

- Que se passe-t-il quand un album publié est vide (aucun média) ? Il ne doit pas apparaître sur la page publique.
- Que se passe-t-il quand un média est supprimé d'un album affiché ? L'association est supprimée automatiquement (cascade existante).
- Comment la page se comporte-t-elle avec un très grand nombre d'albums ? Pagination ou chargement progressif.
- Que se passe-t-il en mode RTL (arabe) ? La mise en page s'adapte correctement.
- Que se passe-t-il si un visiteur accède à la médiathèque et qu'aucun album n'est publié ? Un état vide approprié est affiché.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT afficher une page publique de médiathèque accessible sans authentification
- **FR-002**: La médiathèque DOIT présenter tous les albums ayant le statut "publié" sous forme d'une grille de cartes de prévisualisation avec recherche et filtres en haut
- **FR-003**: Le système DOIT permettre de filtrer les albums par type de média contenu (image, vidéo, audio, document)
- **FR-004**: Le système DOIT permettre une recherche textuelle sur le titre des albums et le nom des médias
- **FR-005**: Le visiteur DOIT pouvoir ouvrir un album via une page dédiée (`/mediatheque/{slug}`) avec un lien partageable et consulter tous ses médias
- **FR-006**: Le visiteur DOIT pouvoir naviguer entre les médias d'un album via une visionneuse (images, vidéos, audios)
- **FR-007**: Le visiteur DOIT pouvoir télécharger individuellement chaque média public
- **FR-008**: Les albums vides ou en brouillon NE DOIVENT PAS apparaître sur la page publique
- **FR-009**: Le système DOIT paginer les résultats pour gérer de grands volumes d'albums
- **FR-010**: La page DOIT être responsive et supporter le mode RTL pour l'arabe
- **FR-011**: La page DOIT supporter le mode sombre (dark mode) conformément au reste du site

### Key Entities

- **Album** (existant) : Collection ordonnée de médias avec titre, description, statut de publication (brouillon/publié). Sert d'unité d'organisation dans la médiathèque publique.
- **Média** (existant) : Fichier (image, vidéo, audio, document) avec métadonnées (nom, description, type, taille, crédits). Appartient à un ou plusieurs albums.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Les visiteurs peuvent accéder à la médiathèque et trouver un album spécifique en moins de 30 secondes grâce aux filtres et à la recherche
- **SC-002**: La page médiathèque s'affiche correctement sur mobile, tablette et desktop, en français, anglais et arabe (RTL)
- **SC-003**: 100% des médias dans les albums publiés sont consultables et téléchargeables par les visiteurs non connectés
- **SC-004**: Les albums vides ou en brouillon sont automatiquement masqués de la vue publique

## Assumptions

- Le système de médias et d'albums existant (upload, stockage, variants, téléchargement, CRUD albums) est réutilisé tel quel — aucune modification nécessaire
- Les composants d'affichage d'albums existants (`MediaAlbumModal.vue`, `MediaAlbumCard.vue`) sont réutilisés sur la page publique
- L'administration des albums se fait via l'interface admin existante (`/admin/mediatheque`) — pas de nouvel écran admin à créer
- La page publique sera accessible via le chemin `/mediatheque` (français) avec les équivalents i18n
- Les albums servent à la fois de moyen d'organisation thématique (ex: "Logos", "Rapports d'activité") et de galeries (ex: "Photos événement X")
