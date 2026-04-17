# Implementation Plan: Réducteur de liens (backoffice admin)

**Branch**: `014-link-shortener` | **Date**: 2026-03-25 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/014-link-shortener/spec.md`

## Summary

Système de réduction de liens pour le backoffice admin de l'Université Senghor. Les administrateurs créent des liens courts (`/r/{code}`) via une page admin dédiée. Le code est généré séquentiellement en base 36 (alphabet [0-9a-z], max 4 caractères, capacité 1 679 616). La redirection publique `/r/{code}` est gérée par un server route Nuxt qui appelle l'API backend. Les URLs de destination sont validées contre une liste blanche de domaines externes.

## Technical Context

**Language/Version**: Python 3.14 (FastAPI backend), TypeScript (Nuxt 4 / Vue 3 frontend)
**Primary Dependencies**: FastAPI, SQLAlchemy (async), Pydantic v2, Nuxt 4, Vue 3, Tailwind CSS
**Storage**: PostgreSQL 16 (Docker: `usenghor_postgres` local, `usenghor_db` prod)
**Testing**: Manuel (Swagger `/api/docs` + navigateur)
**Target Platform**: Web (serveur Linux, navigateurs modernes)
**Project Type**: Web application (monorepo frontend + backend)
**Performance Goals**: Redirection < 1s, création < 10s, liste < 2s
**Constraints**: Max 1 679 616 liens (36^4), URLs restreintes à internes + liste blanche
**Scale/Scope**: Quelques centaines de liens sur les premières années

## Constitution Check

*GATE: Constitution non configurée (template vide). Aucun gate à vérifier.*

## Project Structure

### Documentation (this feature)

```text
specs/014-link-shortener/
├── plan.md              # Ce fichier
├── spec.md              # Spécification fonctionnelle
├── research.md          # Recherche et décisions techniques
├── data-model.md        # Modèle de données
├── quickstart.md        # Guide de démarrage rapide
├── contracts/
│   └── api.md           # Contrats d'API (endpoints)
├── checklists/
│   └── requirements.md  # Checklist qualité de la spec
└── tasks.md             # (Phase 2 - /speckit.tasks)
```

### Source Code (repository root)

```text
usenghor_backend/
├── documentation/modele_de_données/
│   ├── services/13_short_links.sql        # Schéma SQL
│   └── migrations/013_short_links.sql     # Migration
├── app/
│   ├── models/short_links.py              # Modèles SQLAlchemy
│   ├── schemas/short_links.py             # Schémas Pydantic
│   ├── services/short_links_service.py    # Logique métier + base 36
│   └── routers/
│       ├── admin/short_links.py           # Endpoints admin
│       └── public/short_links.py          # Endpoint public (lookup)

usenghor_nuxt/
├── server/routes/r/[code].get.ts          # Redirection 302
├── app/
│   ├── composables/useShortLinksApi.ts    # API composable admin
│   └── pages/admin/liens-courts/
│       └── index.vue                      # Page admin (modale)
└── i18n/locales/
    ├── fr/short-links.json
    ├── en/short-links.json
    └── ar/short-links.json
```

**Structure Decision**: Web application fullstack existante. Les nouveaux fichiers suivent les conventions établies du monorepo (routers, models, schemas, services côté backend ; pages, composables, i18n côté frontend).

## Complexity Tracking

Aucune violation de constitution à justifier.
