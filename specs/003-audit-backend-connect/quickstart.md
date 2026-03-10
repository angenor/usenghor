# Quickstart: Page d'audit admin

**Date**: 2026-03-10

## Prérequis

- Docker (PostgreSQL) lancé : `docker compose up -d` dans `usenghor_backend/`
- Backend Python : `source .venv/bin/activate && uvicorn app.main:app --reload`
- Frontend Nuxt : `pnpm dev` dans `usenghor_nuxt/`
- Un utilisateur admin avec la permission `admin.audit`

## Étapes de développement

### 1. Corriger la pagination filtrée

Modifier `usenghor_backend/app/core/pagination.py` :
- Remplacer le comptage non filtré par un comptage basé sur la requête filtrée
- Tester avec un filtre actif pour vérifier que le total change

### 2. Ajouter les données utilisateur aux réponses audit

Modifier `usenghor_backend/app/schemas/identity.py` :
- Ajouter `AuditLogUserInfo` et `AuditLogReadWithUser`

Modifier `usenghor_backend/app/services/identity_service.py` :
- Ajouter un LEFT JOIN avec la table `users` dans `get_audit_logs()`

Modifier `usenghor_backend/app/routers/admin/audit_logs.py` :
- Utiliser `AuditLogReadWithUser` pour l'endpoint de liste

### 3. Seeder les données de test

```bash
cd usenghor_backend
python scripts/seed_audit_logs.py
```

### 4. Tester manuellement

Accéder à `http://localhost:3000/admin/administration/audit` :
- Vérifier que la liste s'affiche avec les noms d'utilisateurs
- Tester les filtres (action, table, dates, recherche)
- Vérifier la pagination (total et pages corrects avec filtres)
- Ouvrir le détail d'un événement (modifications avant/après)
- Ouvrir le panneau statistiques

## Vérification rapide

```bash
# Tester l'endpoint API directement
curl -H "Authorization: Bearer <TOKEN>" http://localhost:8000/api/admin/audit-logs?limit=5
curl -H "Authorization: Bearer <TOKEN>" http://localhost:8000/api/admin/audit-logs/statistics
curl -H "Authorization: Bearer <TOKEN>" http://localhost:8000/api/admin/audit-logs?action=create
```
