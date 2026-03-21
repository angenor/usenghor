# Data Model: 009-og-meta-tags

**Date**: 2026-03-21

## Aucune modification de schema requise

Cette feature est purement frontend (meta tags HTML). Aucune table, colonne ou migration n'est necessaire.

## Entites existantes utilisees (lecture seule)

Les meta OG exploitent les champs existants des entites suivantes :

### News (actualites)
| Champ | Usage OG |
|-------|----------|
| `title_fr`, `title_en`, `title_ar` | `og:title` (selon locale) |
| `excerpt_fr`, `excerpt_en`, `excerpt_ar` | `og:description` (selon locale) |
| `cover_image_external_id` | `og:image` via `/api/public/media/{id}/download?variant=medium` |

### Events (evenements)
| Champ | Usage OG |
|-------|----------|
| `title_fr`, `title_en`, `title_ar` | `og:title` |
| `description` | `og:description` |
| `cover_image_external_id` | `og:image` via media API `?variant=medium` |

### Programs (formations)
| Champ | Usage OG |
|-------|----------|
| `name_fr`, `name_en`, `name_ar` | `og:title` |
| `description_fr`, `description_en`, `description_ar` | `og:description` |
| `cover_image_external_id` | `og:image` via media API `?variant=medium` |

### Projects (projets)
| Champ | Usage OG |
|-------|----------|
| `title_fr`, `title_en`, `title_ar` | `og:title` |
| `summary_fr`, `summary_en`, `summary_ar` | `og:description` |
| `cover_image_external_id` | `og:image` via media API `?variant=medium` |

### Campuses
| Champ | Usage OG |
|-------|----------|
| `name` | `og:title` |
| `description_fr`, `description_en`, `description_ar` | `og:description` |
| `cover_image_url` (resolu par backend) | `og:image` — URL deja construite, ajouter `?variant=medium` |

### Application Calls (appels a candidatures)
| Champ | Usage OG |
|-------|----------|
| `title` | `og:title` |
| `description_html` → plain text | `og:description` |
| `cover_image_external_id` | `og:image` via media API `?variant=medium` |

### Team Members (equipe)
| Champ | Usage OG |
|-------|----------|
| `first_name`, `last_name` | `og:title` |
| `biography_*` → plain text (160 chars) | `og:description` |
| `photo_url` (resolu par backend) | `og:image` |

## Configuration ajoutee

### Variable d'environnement
| Variable | Valeur dev | Valeur prod | Usage |
|----------|-----------|-------------|-------|
| `NUXT_PUBLIC_SITE_URL` | `http://localhost:3000` | `https://[domaine-prod]` | Prefixe pour URLs absolues OG |

### Fichier image
| Fichier | Dimensions | Usage |
|---------|-----------|-------|
| `public/images/og/og-default.png` | 1200x630 | Image OG par defaut (logo Dieese sur fond adapte) |
