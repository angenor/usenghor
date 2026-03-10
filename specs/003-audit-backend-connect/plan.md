# Implementation Plan: Page d'audit admin connectée au backend

**Branch**: `003-audit-backend-connect` | **Date**: 2026-03-10 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/003-audit-backend-connect/spec.md`

## Summary

Rendre la page d'audit admin pleinement fonctionnelle en corrigeant les problèmes d'intégration frontend/backend identifiés lors de la recherche : pagination filtrée incorrecte, absence des données utilisateur dans les réponses API, et vérification de bout en bout.

## Technical Context

**Language/Version**: TypeScript (Nuxt 4 / Vue 3) + Python 3.14 (FastAPI)
**Primary Dependencies**: Nuxt 4, Vue 3, Tailwind CSS, FastAPI, SQLAlchemy (async)
**Storage**: PostgreSQL 16 (table `audit_logs` existante)
**Testing**: Test manuel end-to-end (pas de framework de test automatisé en place)
**Target Platform**: Web (navigateur desktop/mobile)
**Project Type**: Web application (monorepo frontend + backend)
**Performance Goals**: Chargement < 3s, filtrage < 2s
**Constraints**: Permission `admin.audit` requise, données en français
**Scale/Scope**: Centaines à milliers de logs d'audit

## Constitution Check

*GATE: Constitution non configurée (template vide) - pas de contraintes formelles à vérifier.*

## Issues Identified During Research

### Issue 1: Pagination count ignores filters (CRITICAL)

La fonction `paginate()` dans `app/core/pagination.py` (ligne 76) utilise `select(func.count()).select_from(model_class)` qui compte TOUS les enregistrements de la table, sans appliquer les filtres de la requête originale. Résultat : le `total` et `pages` renvoyés sont toujours les mêmes quel que soit le filtre appliqué.

**Fix**: Utiliser une subquery de la requête filtrée pour le comptage.

### Issue 2: Missing user data in audit log responses (MAJOR)

Le schéma `AuditLogRead` backend ne renvoie que `user_id` (string). Le frontend `AuditLogWithUser` attend un objet `user` optionnel avec `{id, name, email}`. La fonction `enrichLog()` du composable n'ajoute pas de données utilisateur. Résultat : le nom de l'utilisateur ne s'affichera jamais, seul l'UUID tronqué.

**Fix**: Enrichir la réponse backend avec un join vers la table `users` pour inclure les données utilisateur, ou créer un schéma de réponse enrichi.

### Issue 3: Potential type mismatch on statistics

Le backend `AuditLogStatistics` renvoie `by_table` comme `dict[str, int]`, ce qui correspond au type frontend `Record<string, number>`. La conversion `statsToUI` dans le composable gère correctement cette transformation. Pas de problème ici.

## Project Structure

### Documentation (this feature)

```text
specs/003-audit-backend-connect/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
usenghor_backend/
├── app/
│   ├── core/
│   │   └── pagination.py         # FIX: count query with filters
│   ├── routers/admin/
│   │   └── audit_logs.py         # OK (existing endpoints)
│   ├── schemas/
│   │   └── identity.py           # MODIFY: add user data to AuditLogRead
│   ├── services/
│   │   └── identity_service.py   # MODIFY: join users in audit query
│   └── models/
│       └── identity.py           # OK (existing model)

usenghor_nuxt/
├── app/
│   ├── composables/
│   │   └── useAuditApi.ts        # OK (already complete)
│   ├── pages/admin/administration/audit/
│   │   └── index.vue             # VERIFY: end-to-end functionality
│   └── types/api/
│       └── audit.ts              # OK (types already defined)
```

**Structure Decision**: Monorepo existant avec modifications ciblées dans le backend (pagination + enrichissement des données) et vérification du frontend.
