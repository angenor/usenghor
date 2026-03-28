# Data Model: Médiathèque publique générale

**Branch**: `015-mediatheque` | **Date**: 2026-03-28

## Modifications de schéma

### Table `albums` — Ajout du champ `slug`

**Champ ajouté** :

| Colonne | Type | Contraintes | Description |
|---------|------|-------------|-------------|
| `slug` | `VARCHAR(300)` | `UNIQUE NOT NULL` | Identifiant URL-friendly généré à partir du titre |

**Index** : Index unique sur `slug` (recherche par slug dans l'endpoint public)

### Aucune nouvelle table

La médiathèque publique réutilise les tables existantes :
- `albums` (avec le nouveau champ `slug`)
- `media`
- `album_media` (table de jonction avec `display_order`)

## Entités existantes (rappel)

### Album

| Colonne | Type | Contraintes |
|---------|------|-------------|
| `id` | `UUID` | PK, default `uuid_generate_v4()` |
| `title` | `VARCHAR(255)` | NOT NULL |
| `description` | `TEXT` | nullable |
| `slug` | `VARCHAR(300)` | UNIQUE NOT NULL **(NOUVEAU)** |
| `status` | `publication_status` | NOT NULL, default `'draft'` |
| `created_at` | `TIMESTAMPTZ` | default `NOW()` |
| `updated_at` | `TIMESTAMPTZ` | default `NOW()` |

**États** : `draft` → `published` (et inversement). Seuls les albums `published` avec au moins 1 média apparaissent dans la médiathèque publique.

### Media (inchangé)

| Colonne | Type | Description |
|---------|------|-------------|
| `id` | `UUID` | PK |
| `name` | `VARCHAR(255)` | Nom du fichier |
| `description` | `TEXT` | Description optionnelle |
| `type` | `media_type` | `image`, `video`, `audio`, `document` |
| `url` | `VARCHAR(500)` | Chemin du fichier |
| `mime_type` | `VARCHAR(100)` | Type MIME |
| `size_bytes` | `BIGINT` | Taille |
| `alt_text` | `VARCHAR(255)` | Texte alternatif |
| `credits` | `VARCHAR(255)` | Crédits |

### AlbumMedia (inchangé)

| Colonne | Type | Description |
|---------|------|-------------|
| `album_id` | `UUID` | FK → albums |
| `media_id` | `UUID` | FK → media |
| `display_order` | `INT` | Ordre d'affichage |

## Migration SQL requise

**Fichier** : `usenghor_backend/documentation/modele_de_données/migrations/016_add_album_slug.sql`

**Opérations** :
1. Ajouter la colonne `slug` (nullable temporairement)
2. Générer les slugs pour les albums existants via une fonction de slugification
3. Rendre la colonne `NOT NULL`
4. Créer l'index unique

## Règles de validation

- Le slug est généré automatiquement à la création de l'album si non fourni
- Le slug doit être unique (contrainte BDD + vérification applicative)
- Format du slug : `[a-z0-9-]+` (minuscules, chiffres, tirets)
- Longueur max : 300 caractères
- En cas de doublon, suffixe numérique ajouté (`logos`, `logos-2`, `logos-3`)
