# Quickstart: 012-media-events-news

## Prérequis

```bash
# Backend
cd usenghor_backend
docker compose up -d          # PostgreSQL + Adminer
source .venv/bin/activate

# Frontend
cd usenghor_nuxt
pnpm install
```

## Migration de la base de données

```bash
# Créer le fichier de migration
cat > usenghor_backend/documentation/modele_de_données/migrations/012_media_events_news.sql << 'SQL'
-- Migration 012: Association médiathèque ↔ événements/actualités
-- Ajouter display_order à event_media_library
ALTER TABLE event_media_library
ADD COLUMN IF NOT EXISTS display_order INT DEFAULT 0;

-- Créer news_media_library
CREATE TABLE IF NOT EXISTS news_media_library (
    news_id UUID REFERENCES news(id) ON DELETE CASCADE,
    album_external_id UUID NOT NULL,
    display_order INT DEFAULT 0,
    PRIMARY KEY (news_id, album_external_id)
);
SQL

# Appliquer en local
docker exec -i usenghor_postgres psql -U usenghor -d usenghor < usenghor_backend/documentation/modele_de_données/migrations/012_media_events_news.sql
```

## Lancer le développement

```bash
# Terminal 1 - Backend
cd usenghor_backend
source .venv/bin/activate
uvicorn app.main:app --reload    # http://localhost:8000

# Terminal 2 - Frontend
cd usenghor_nuxt
pnpm dev                         # http://localhost:3000
```

## Vérification

1. **Swagger**: http://localhost:8000/api/docs
   - Vérifier les nouveaux endpoints sous `/api/admin/events/{id}/albums` et `/api/admin/news/{id}/albums`

2. **Admin**: http://localhost:3000/admin/contenus/evenements
   - Éditer un événement → vérifier le sélecteur d'albums

3. **Public**: http://localhost:3000/actualites/evenements/{id}
   - Vérifier l'onglet "Médiathèque" (visible seulement si des albums publiés sont associés)

## Fichiers clés à modifier

### Backend
- `usenghor_backend/app/models/content.py` - Ajouter NewsMediaLibrary, modifier EventMediaLibrary
- `usenghor_backend/app/schemas/content.py` - Nouveaux schemas pour albums
- `usenghor_backend/app/services/content_service.py` - Méthodes add/remove/list/reorder albums
- `usenghor_backend/app/routers/admin/events.py` - Endpoints albums pour événements
- `usenghor_backend/app/routers/admin/news.py` - Endpoints albums pour actualités
- `usenghor_backend/app/routers/public/events.py` - Endpoint public albums
- `usenghor_backend/app/routers/public/news.py` - Endpoint public albums

### Frontend
- `usenghor_nuxt/app/components/admin/AlbumSelector.vue` - Nouveau composant
- `usenghor_nuxt/app/components/media/MediaLibraryTab.vue` - Nouveau composant (onglet public)
- `usenghor_nuxt/app/pages/actualites/evenements/[id].vue` - Ajouter onglets + médiathèque
- `usenghor_nuxt/app/pages/actualites/[slug].vue` - Ajouter onglets + médiathèque
- `usenghor_nuxt/app/pages/admin/contenus/evenements/[id]/edit.vue` - Remplacer champ texte album
- `usenghor_nuxt/app/pages/admin/contenus/actualites/[id]/edit.vue` - Ajouter section albums
- `usenghor_nuxt/app/composables/useEventsApi.ts` - Méthodes albums
- `usenghor_nuxt/app/composables/useAdminNewsApi.ts` - Méthodes albums
- `usenghor_nuxt/app/composables/usePublicEventsApi.ts` - Méthode albums
- `usenghor_nuxt/app/composables/usePublicNewsApi.ts` - Méthode albums

### SQL
- `usenghor_backend/documentation/modele_de_données/migrations/012_media_events_news.sql` - Migration
- `usenghor_backend/documentation/modele_de_données/services/09_content.sql` - Mettre à jour le schéma source
