# Data Model: Migration EditorJS vers TOAST UI Editor

**Date**: 2026-03-08
**Feature**: `001-migrate-toastui-editor`

## Changements de schéma

### Stratégie de migration des colonnes

Pour chaque colonne TEXT stockant du contenu EditorJS, la migration :
1. Renomme la colonne existante en `*_legacy` (backup temporaire)
2. Ajoute deux nouvelles colonnes : `*_html` (TEXT) et `*_md` (TEXT)
3. Convertit le JSON EditorJS en HTML et Markdown via un script Python
4. Après 30 jours de validation, supprime les colonnes `*_legacy`

### Tables impactées

#### events
```
content (TEXT)          → content_legacy (TEXT)  [backup]
                        + content_html (TEXT)    [nouveau - rendu public]
                        + content_md (TEXT)      [nouveau - édition]
```

#### news
```
content (TEXT)          → content_legacy (TEXT)
                        + content_html (TEXT)
                        + content_md (TEXT)
```

#### projects
```
description (TEXT)      → description_legacy (TEXT)
                        + description_html (TEXT)
                        + description_md (TEXT)

summary (TEXT)          → summary_legacy (TEXT)
                        + summary_html (TEXT)
                        + summary_md (TEXT)
```

#### project_calls
```
description (TEXT)      → description_legacy (TEXT)
                        + description_html (TEXT)
                        + description_md (TEXT)

conditions (TEXT)       → conditions_legacy (TEXT)
                        + conditions_html (TEXT)
                        + conditions_md (TEXT)
```

#### programs
```
description (TEXT)      → description_legacy (TEXT)
                        + description_html (TEXT)
                        + description_md (TEXT)

teaching_methods (TEXT) → teaching_methods_legacy (TEXT)
                        + teaching_methods_html (TEXT)
                        + teaching_methods_md (TEXT)

format (TEXT)           → format_legacy (TEXT)
                        + format_html (TEXT)
                        + format_md (TEXT)

evaluation_methods (TEXT) → evaluation_methods_legacy (TEXT)
                          + evaluation_methods_html (TEXT)
                          + evaluation_methods_md (TEXT)
```

**Note** : `objectives` (JSONB) et `target_audience` (JSONB) ne sont PAS du contenu EditorJS. Pas de migration nécessaire.

#### application_calls
```
description (TEXT)      → description_legacy (TEXT)
                        + description_html (TEXT)
                        + description_md (TEXT)

target_audience (TEXT)  → target_audience_legacy (TEXT)
                        + target_audience_html (TEXT)
                        + target_audience_md (TEXT)
```

#### sectors
```
description (TEXT)      → description_legacy (TEXT)
                        + description_html (TEXT)
                        + description_md (TEXT)

mission (TEXT)          → mission_legacy (TEXT)
                        + mission_html (TEXT)
                        + mission_md (TEXT)
```

#### services
```
description (TEXT)      → description_legacy (TEXT)
                        + description_html (TEXT)
                        + description_md (TEXT)

mission (TEXT)          → mission_legacy (TEXT)
                        + mission_html (TEXT)
                        + mission_md (TEXT)
```

#### service_objectives
```
description (TEXT)      → description_legacy (TEXT)
                        + description_html (TEXT)
                        + description_md (TEXT)
```

#### service_achievements
```
description (TEXT)      → description_legacy (TEXT)
                        + description_html (TEXT)
                        + description_md (TEXT)
```

#### service_projects
```
description (TEXT)      → description_legacy (TEXT)
                        + description_html (TEXT)
                        + description_md (TEXT)
```

### Résumé volumétrie

| Métrique | Valeur |
|----------|--------|
| Tables impactées | 11 |
| Colonnes à migrer | ~20 |
| Nouvelles colonnes | ~40 (2 par colonne migrée) |
| Colonnes legacy (temporaires) | ~20 |

## Entités inchangées

Les entités suivantes ne sont **pas** impactées par la migration :
- `users`, `roles`, `permissions` (pas de contenu riche)
- `media`, `albums` (fichiers, pas de contenu éditorial)
- `countries`, `campuses`, `partners` (données structurées)
- `tags`, `newsletter_*` (pas de contenu EditorJS)

## Validation des données

### Règles de validation post-migration
- Chaque colonne `*_html` doit contenir du HTML valide (pas de JSON EditorJS résiduel)
- Chaque colonne `*_md` doit contenir du Markdown valide
- Les colonnes `*_html` et `*_md` doivent représenter le même contenu
- Les images doivent conserver leurs URLs (`/api/public/media/{uuid}/download`)
- Les valeurs NULL restent NULL (pas de conversion de NULL en chaîne vide)
