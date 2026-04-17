# Quickstart: 014-link-shortener

**Date**: 2026-03-25

## Prérequis

- Docker (PostgreSQL local via `docker compose`)
- Python 3.14 + venv activé
- Node.js + pnpm

## Fichiers à créer

### Backend

| Fichier | Description |
|---------|-------------|
| `usenghor_backend/documentation/modele_de_données/services/13_short_links.sql` | Schéma SQL (table + séquence + domaines) |
| `usenghor_backend/documentation/modele_de_données/migrations/013_short_links.sql` | Migration SQL |
| `usenghor_backend/app/models/short_links.py` | Modèles SQLAlchemy (ShortLink, AllowedDomain) |
| `usenghor_backend/app/schemas/short_links.py` | Schémas Pydantic (Create, Read, etc.) |
| `usenghor_backend/app/services/short_links_service.py` | Service métier (CRUD + génération base 36) |
| `usenghor_backend/app/routers/admin/short_links.py` | Endpoints admin |
| `usenghor_backend/app/routers/public/short_links.py` | Endpoint public (lookup par code) |

### Frontend

| Fichier | Description |
|---------|-------------|
| `usenghor_nuxt/server/routes/r/[code].get.ts` | Server route Nuxt pour redirection 302 |
| `usenghor_nuxt/app/composables/useShortLinksApi.ts` | Composable API admin |
| `usenghor_nuxt/app/pages/admin/liens-courts/index.vue` | Page admin (liste + création + suppression) |
| `usenghor_nuxt/i18n/locales/fr/short-links.json` | Traductions FR |
| `usenghor_nuxt/i18n/locales/en/short-links.json` | Traductions EN |
| `usenghor_nuxt/i18n/locales/ar/short-links.json` | Traductions AR |

### Fichiers à modifier

| Fichier | Modification |
|---------|--------------|
| `usenghor_backend/app/routers/admin/__init__.py` | Importer et inclure le router short_links |
| `usenghor_backend/app/routers/public/__init__.py` | Importer et inclure le router short_links |
| `usenghor_backend/app/models/__init__.py` | Importer ShortLink et AllowedDomain |
| `usenghor_backend/documentation/modele_de_données/services/main.sql` | Ajouter `\i 13_short_links.sql` |
| `usenghor_nuxt/app/composables/useAdminSidebar.ts` | Ajouter l'entrée menu "Liens courts" |
| `usenghor_nuxt/i18n/locales/fr/index.ts` | Importer short-links.json |
| `usenghor_nuxt/i18n/locales/en/index.ts` | Importer short-links.json |
| `usenghor_nuxt/i18n/locales/ar/index.ts` | Importer short-links.json |

## Commandes de démarrage

```bash
# 1. Migration SQL locale
docker exec -i usenghor_postgres psql -U usenghor -d usenghor < usenghor_backend/documentation/modele_de_données/migrations/013_short_links.sql

# 2. Backend
cd usenghor_backend && source .venv/bin/activate
uvicorn app.main:app --reload

# 3. Frontend
cd usenghor_nuxt && pnpm dev

# 4. Vérification
# - Admin : http://localhost:3000/admin/liens-courts
# - Redirect : http://localhost:3000/r/{code}
# - API docs : http://localhost:8000/api/docs
```

## Ordre d'implémentation recommandé

1. SQL (schéma + migration)
2. Modèles SQLAlchemy
3. Schémas Pydantic
4. Service métier (avec conversion base 36)
5. Routers backend (admin + public)
6. Server route Nuxt (redirection)
7. Composable API frontend
8. Page admin
9. Sidebar + i18n
