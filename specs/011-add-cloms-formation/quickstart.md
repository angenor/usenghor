# Quickstart: Ajouter le type de formation CLOM

**Feature**: 011-add-cloms-formation
**Date**: 2026-03-24

## Prérequis

- Docker compose lancé (`docker compose up -d` dans `usenghor_backend/`)
- Backend actif (`uvicorn app.main:app --reload`)
- Frontend actif (`pnpm dev` dans `usenghor_nuxt/`)

## Ordre d'implémentation

### Étape 1 : Base de données

1. Ajouter `'clom'` à l'ENUM dans `07_academic.sql`
2. Créer la migration `029_add_clom_program_type.sql`
3. Exécuter la migration localement :
   ```bash
   docker exec -i usenghor_postgres psql -U usenghor -d usenghor < usenghor_backend/documentation/modele_de_données/migrations/029_add_clom_program_type.sql
   ```

### Étape 2 : Backend Python

4. Ajouter `CLOM = "clom"` à l'enum `ProgramType` dans `app/models/academic.py`

   Les schemas Pydantic, routes et services se propagent automatiquement.

### Étape 3 : Frontend TypeScript

5. Ajouter `| 'clom'` au type `ProgramType` dans `app/types/api/programs.ts`
6. Ajouter label + color dans `useProgramsApi.ts`
7. Ajouter slug mappings + label + color dans `usePublicProgramsApi.ts`
8. Ajouter `'cloms'` au tableau `validTypes` dans `app/pages/formations/[type]/index.vue`

### Étape 4 : Traductions i18n

9. Ajouter les entrées CLOM dans `fr/formations.json`
10. Ajouter les entrées MOOC dans `en/formations.json`
11. Ajouter les entrées arabes dans `ar/formations.json`

## Vérification rapide

1. **API** : `curl http://localhost:8000/api/public/programs/by-type/clom` → `200 OK` (tableau vide)
2. **Swagger** : `http://localhost:8000/api/docs` → le type `clom` apparaît dans les enums
3. **Admin** : Créer un programme avec type « CLOM » → sauvegarde OK
4. **Public** : `http://localhost:3000/formations/cloms` → page affichée (vide ou avec le programme créé)
5. **i18n** : Basculer en anglais → « MOOC » affiché, en arabe → libellé arabe affiché

## Migration production

```bash
docker exec -i usenghor_db psql -U usenghor -d usenghor < usenghor_backend/documentation/modele_de_données/migrations/029_add_clom_program_type.sql
```
