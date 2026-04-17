# Research: Médiathèque publique générale

**Branch**: `015-mediatheque` | **Date**: 2026-03-28

## R1 — Identification des albums (slug vs UUID)

**Decision**: Ajouter un champ `slug` à la table `albums` pour des URLs SEO-friendly (`/mediatheque/logos` au lieu de `/mediatheque/550e8400-e29b-41d4-a716-446655440000`).

**Rationale**: La spec exige des pages dédiées partageables avec bon SEO. Un slug lisible améliore le référencement, la partageabilité et l'expérience utilisateur. Le slug sera généré automatiquement à partir du titre lors de la création et modifiable par l'admin.

**Alternatives considered**:
- UUID dans l'URL : fonctionnel mais mauvais pour le SEO et non lisible
- Titre encodé dans l'URL : fragile si le titre change

**Impact**: Migration SQL pour ajouter la colonne `slug` (UNIQUE, NOT NULL) + mise à jour du modèle SQLAlchemy, des schémas Pydantic et du service.

## R2 — Endpoint public de listing des albums

**Decision**: Créer `GET /api/public/albums` avec pagination, recherche et filtre par type de média.

**Rationale**: L'endpoint existant `GET /api/public/albums/{album_id}` ne retourne qu'un seul album. La page d'accueil de la médiathèque a besoin de lister tous les albums publiés non vides.

**Alternatives considered**:
- Réutiliser l'endpoint admin avec un flag public : complexifie la logique d'autorisation
- Charger côté client via plusieurs appels : trop lent, pas de SSR

**Paramètres prévus**: `page`, `limit`, `search`, `media_type` (filtrer les albums contenant au moins un média de ce type)

## R3 — Endpoint public d'album par slug

**Decision**: Créer `GET /api/public/albums/by-slug/{slug}` en complément de l'existant `GET /api/public/albums/{album_id}`.

**Rationale**: La page dédiée `/mediatheque/{slug}` a besoin de résoudre un album par son slug. L'endpoint existant par ID est conservé pour la rétrocompatibilité.

**Alternatives considered**:
- Remplacer l'endpoint par ID par un endpoint par slug : casserait les usages existants

## R4 — Titres trilingues des albums

**Decision**: Ne PAS rendre les titres trilingues pour cette feature. Les albums gardent un champ `title` unique.

**Rationale**: La page sera trilingue via i18n pour les éléments d'interface (labels, filtres, boutons). Le contenu des albums (titre, description) est géré par les administrateurs qui saisissent le texte dans la langue appropriée. Ajouter `title_fr`, `title_en`, `title_ar` serait un changement structurel majeur impactant toute l'administration des albums — hors scope de cette feature.

**Alternatives considered**:
- Champs trilingues complets : impact trop large (migration, modèle, schémas, toute l'interface admin)

## R5 — Composants frontend réutilisables

**Decision**: Réutiliser `MediaAlbumCard.vue` sur la page listing et adapter `MediaAlbumModal.vue` en visionneuse sur la page dédiée d'album.

**Rationale**: Ces composants existent et sont fonctionnels. La carte d'album affiche déjà les aperçus empilés et le décompte par type. La modale gère déjà la navigation, le filtrage par type et le téléchargement.

**Adaptation nécessaire**: Sur la page dédiée d'album, le contenu de la modale sera affiché directement en pleine page au lieu d'être dans une modale (grille de médias + visionneuse au clic).

## R6 — Génération du slug pour les albums existants

**Decision**: La migration SQL génère automatiquement un slug pour les albums existants à partir du titre (slugify).

**Rationale**: Les albums existants doivent avoir un slug valide dès la migration pour ne pas casser la médiathèque publique.

**Méthode**: Fonction SQL de slugification (translitération, lowercase, remplacement des espaces par des tirets, suppression des caractères spéciaux) + suffixe numérique en cas de doublon.
