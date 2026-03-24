# Data Model: 012-media-events-news

**Date**: 2026-03-24

## Entités existantes (non modifiées)

### Album
- `id` : UUID (PK)
- `title` : VARCHAR(255), NOT NULL
- `description` : TEXT
- `status` : publication_status ENUM (draft, published, archived)
- `created_at`, `updated_at` : TIMESTAMPTZ

### Media
- `id` : UUID (PK)
- `name` : VARCHAR(255), NOT NULL
- `type` : media_type ENUM (image, video, document, audio)
- `url` : VARCHAR(500), NOT NULL
- Métadonnées : size_bytes, mime_type, width, height, duration_seconds, alt_text, credits

### AlbumMedia (table de liaison existante)
- `album_id` → albums.id (PK, CASCADE)
- `media_id` → media.id (PK, CASCADE)
- `display_order` : INT, DEFAULT 0

## Entités modifiées

### EventMediaLibrary (table existante, à enrichir)

**Modification** : Ajouter la colonne `display_order`.

| Champ | Type | Contrainte | Notes |
|-------|------|------------|-------|
| `event_id` | UUID | PK, FK → events.id ON DELETE CASCADE | Existant |
| `album_external_id` | UUID | PK | Existant, référence albums.id |
| `display_order` | INT | DEFAULT 0 | **NOUVEAU** - ordre d'affichage |

**Relations** :
- Event 1 → N EventMediaLibrary N → 1 Album (N:N)

## Nouvelles entités

### NewsMediaLibrary (nouvelle table)

| Champ | Type | Contrainte | Notes |
|-------|------|------------|-------|
| `news_id` | UUID | PK, FK → news.id ON DELETE CASCADE | |
| `album_external_id` | UUID | PK | Référence albums.id |
| `display_order` | INT | DEFAULT 0 | Ordre d'affichage |

**Relations** :
- News 1 → N NewsMediaLibrary N → 1 Album (N:N)

## Diagramme des relations

```
┌─────────┐     ┌──────────────────────┐     ┌─────────┐     ┌─────────────┐     ┌───────┐
│  Event  │────▶│ event_media_library   │◀────│  Album  │────▶│ album_media  │◀────│ Media │
│         │  1:N│ event_id (PK,FK)     │N:1  │         │  1:N│ album_id     │N:1  │       │
│         │     │ album_external_id(PK)│     │         │     │ media_id     │     │       │
│         │     │ display_order        │     │         │     │ display_order│     │       │
└─────────┘     └──────────────────────┘     └─────────┘     └─────────────┘     └───────┘
                                                  ▲
┌─────────┐     ┌──────────────────────┐          │
│  News   │────▶│ news_media_library    │──────────┘
│         │  1:N│ news_id (PK,FK)      │N:1
│         │     │ album_external_id(PK)│
│         │     │ display_order        │
└─────────┘     └──────────────────────┘
```

## Règles de validation

- Un album ne peut être associé qu'une seule fois à un même événement/actualité (contrainte PK composite).
- Un album peut être associé à plusieurs événements et/ou actualités différentes.
- `display_order` est un entier positif, géré par l'application (pas de contrainte DB).
- La suppression d'un événement/actualité supprime en cascade ses associations (FK ON DELETE CASCADE).
- La suppression d'un album n'est pas gérée par FK (external_id sans contrainte) : le backend doit nettoyer les associations orphelines ou les ignorer au chargement.

## Transitions d'état

Les albums suivent le cycle de publication existant :
- `draft` → `published` → `archived`
- Seuls les albums `published` sont visibles sur les pages publiques.
- Les albums dans tous les états sont visibles dans l'admin.

## Migration SQL requise

```sql
-- 1. Ajouter display_order à event_media_library
ALTER TABLE event_media_library
ADD COLUMN display_order INT DEFAULT 0;

-- 2. Créer news_media_library
CREATE TABLE news_media_library (
    news_id UUID REFERENCES news(id) ON DELETE CASCADE,
    album_external_id UUID NOT NULL,
    display_order INT DEFAULT 0,
    PRIMARY KEY (news_id, album_external_id)
);
```
