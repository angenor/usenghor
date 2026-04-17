# Quickstart: Médiathèque publique générale

**Branch**: `015-mediatheque` | **Date**: 2026-03-28

## Prérequis

- Docker compose en cours (`usenghor_postgres`)
- Backend FastAPI en cours (`uvicorn app.main:app --reload`)
- Frontend Nuxt en cours (`pnpm dev`)

## Ordre d'implémentation

### 1. Migration BDD — Ajout du slug aux albums

```bash
# Créer le fichier de migration
# usenghor_backend/documentation/modele_de_données/migrations/016_add_album_slug.sql

# Appliquer la migration
docker exec -i usenghor_postgres psql -U usenghor -d usenghor < usenghor_backend/documentation/modele_de_données/migrations/016_add_album_slug.sql
```

### 2. Backend — Modèle et schémas

1. Ajouter le champ `slug` au modèle SQLAlchemy `Album` (`app/models/media.py`)
2. Mettre à jour les schémas Pydantic (`app/schemas/media.py`) : `AlbumCreate`, `AlbumUpdate`, `AlbumRead`
3. Mettre à jour le service (`app/services/media_service.py`) : génération automatique du slug

### 3. Backend — Endpoints publics

1. Ajouter `GET /api/public/albums` (listing paginé avec filtres)
2. Ajouter `GET /api/public/albums/by-slug/{slug}` (album par slug)
3. Mettre à jour le schéma SQL source (`03_media.sql`)

### 4. Frontend — Composable

1. Étendre `usePublicAlbumsApi.ts` : `listPublicAlbums()`, `getAlbumBySlug()`

### 5. Frontend — Page listing médiathèque

1. Créer `usenghor_nuxt/app/pages/mediatheque/index.vue`
2. Grille de `MediaAlbumCard` + barre de recherche + filtres par type
3. Pagination
4. SEO meta tags + i18n

### 6. Frontend — Page dédiée album

1. Créer `usenghor_nuxt/app/pages/mediatheque/[slug].vue`
2. Grille de médias avec visionneuse au clic
3. Boutons de téléchargement
4. SEO meta tags + breadcrumb

### 7. Frontend — Traductions i18n

1. Ajouter les clés de traduction dans `i18n/locales/fr/`, `en/`, `ar/`

## Vérification rapide

```bash
# Vérifier que la migration a fonctionné
docker exec usenghor_postgres psql -U usenghor -d usenghor -c "SELECT id, title, slug FROM albums LIMIT 5;"

# Vérifier l'endpoint de listing
curl http://localhost:8000/api/public/albums

# Vérifier l'endpoint par slug
curl http://localhost:8000/api/public/albums/by-slug/logos-institutionnels

# Ouvrir la page
open http://localhost:3000/mediatheque
```
