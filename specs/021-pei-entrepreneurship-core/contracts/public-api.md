# Contrat — API publique `/api/public/entrepreneurship`

Sans authentification, lecture seule, `Cache-Control: public, max-age=60, stale-while-revalidate=300`. Seuls les éléments actifs / publiés sont renvoyés, triés par `display_order ASC, created_at ASC`. Les trois langues sont renvoyées (le front applique `useLocalizedField`). Les UUID de média ne sont pas exposés : ils sont résolus en `*_url` via `resolve_media_url` (`/api/public/media/{id}/download` ou URL externe).

Routes statiques (`/programs`, `/cohorts`, `/resources`) avant les routes dynamiques `/{code}`.

## GET /programs → `PeiProgramPublic[]`

```json
[{
  "id": "uuid", "code": "mti", "sigle": "MTI", "phase": "pre_incubation",
  "title": "Mature Ton Idée", "title_en": "…", "title_ar": "…",
  "tagline": "…", "tagline_en": "…", "tagline_ar": "…",
  "content_html": "<p>…</p>", "content_en_html": "…", "content_ar_html": "…",
  "highlight": "4 crédits", "highlight_en": "…", "highlight_ar": "…",
  "color": "blue", "cover_image_url": "/api/public/media/…/download",
  "display_order": 2
}]
```
Pas de `content_md` en public.

## GET /programs/{code} → `PeiProgramPublic` · 404 si inconnu **ou inactif**

## GET /cohorts → `PeiCohortPublic[]`

```json
[{
  "id": "uuid", "code": "fse-3", "label": "FSE 3 · Promotion 2025", "label_en": "…", "label_ar": "…",
  "year": 2025, "type": "fse",
  "focus": "…", "focus_en": "…", "focus_ar": "…",
  "summary_html": "…", "summary_en_html": "…", "summary_ar_html": "…",
  "display_order": 0
}]
```
Paramètre optionnel `type=fse|see`.

## GET /cohorts/{code} → `PeiCohortPublic` · 404 si inconnu ou inactif

## GET /resources → `PeiResourcePublic[]`

```json
[{
  "id": "uuid", "title": "…", "title_en": "…", "title_ar": "…",
  "description": "…", "description_en": "…", "description_ar": "…",
  "type": "document", "media_url": "/api/public/media/…/download", "url": null,
  "category": "Financement", "category_en": "…", "category_ar": "…",
  "display_order": 0
}]
```
Paramètres optionnels `type=document|link|video`, `category=<texte FR exact>`. Pour `link`/`video`, `media_url` est null et `url` renseigné.

## Garanties (SC-003, FR-020)
- Aucun verbe d'écriture n'est exposé sous `/api/public/entrepreneurship`.
- Un élément `active = false` / `is_published = false` n'apparaît ni en liste ni par code.
