# API Contracts: Type CLOM

**Feature**: 011-add-cloms-formation
**Date**: 2026-03-24

## Endpoints impactés (existants, aucune modification de route)

Les endpoints suivants acceptent déjà `ProgramType` comme paramètre de filtre. L'ajout de la valeur `clom` à l'ENUM les rend automatiquement compatibles.

### Public

#### `GET /api/public/programs?program_type=clom`

Liste les programmes publiés de type CLOM.

**Response** : `200 OK` — Array de `ProgramPublic`

```json
[
  {
    "id": "uuid",
    "type": "clom",
    "name_fr": "Introduction à la francophonie numérique",
    "name_en": "Introduction to Digital Francophonie",
    "name_ar": "مقدمة في الفرنكوفونية الرقمية",
    "duration": "6 mois",
    "is_published": true,
    "campus_name": "Alexandrie",
    ...
  }
]
```

#### `GET /api/public/programs/by-type/clom`

Liste les programmes publiés filtrés par type CLOM (endpoint dédié).

**Response** : `200 OK` — Array de `ProgramPublic` (même format)

### Admin

#### `GET /api/admin/programs?type=clom`

Liste tous les programmes de type CLOM (publiés et non publiés).

**Auth** : JWT requis (rôle admin)
**Response** : `200 OK` — Array de `ProgramRead`

#### `POST /api/admin/programs`

Création d'un programme de type CLOM.

**Auth** : JWT requis (rôle admin)
**Body** :
```json
{
  "type": "clom",
  "name_fr": "Titre du CLOM",
  "name_en": "MOOC Title",
  "name_ar": "عنوان المقرر",
  "duration": "3 mois",
  ...
}
```

**Response** : `201 Created` — `ProgramRead`

## Valeurs ENUM acceptées par l'API

**Avant** : `master`, `doctorate`, `university_diploma`, `certificate`
**Après** : `master`, `doctorate`, `university_diploma`, `certificate`, `clom`

Toute requête avec `program_type=clom` ou `type=clom` sera acceptée par les endpoints existants.

## Routes frontend (URL publiques)

| Slug URL | Type backend | Page |
|----------|-------------|------|
| `/formations/masters` | `master` | Existante |
| `/formations/doctorat` | `doctorate` | Existante |
| `/formations/diplomes-universitaires` | `university_diploma` | Existante |
| `/formations/certifiantes` | `certificate` | Existante |
| `/formations/cloms` | `clom` | **Nouveau slug** (même composant `[type]/index.vue`) |
