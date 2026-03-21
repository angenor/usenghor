# Contrat : Balises Meta OG attendues par page

**Date**: 2026-03-21

## Balises globales (toutes pages publiques)

Definies dans `nuxt.config.ts` → `app.head.meta` :

```html
<meta property="og:site_name" content="Universite Senghor" />
<meta property="og:type" content="website" />
<meta property="og:image" content="{SITE_URL}/images/og/og-default.png" />
<meta property="og:image:width" content="1200" />
<meta property="og:image:height" content="630" />
<meta name="twitter:card" content="summary_large_image" />
<meta name="twitter:image" content="{SITE_URL}/images/og/og-default.png" />
```

## Balises par page (surcharge via useSeoMeta)

### Pages statiques (i18n keys)

| Balise | Source | Fallback |
|--------|--------|----------|
| `og:title` | `t('page.seo.title')` | Titre i18n de la page |
| `og:description` | `t('page.seo.description')` | Description institutionnelle i18n |
| `og:image` | — | Image globale par defaut |
| `og:url` | URL canonique courante | — |
| `og:locale` | `fr_FR` / `en_US` / `ar_SA` selon locale active | `fr_FR` |
| `og:locale:alternate` | Les 2 autres locales | — |

### Pages dynamiques (contenu BDD)

| Balise | Source | Fallback |
|--------|--------|----------|
| `og:title` | Titre localise du contenu | Titre i18n de la section |
| `og:description` | Description/extrait localise (max 160 chars, plain text) | Description i18n de la section |
| `og:image` | `/api/public/media/{cover_image_external_id}/download?variant=medium` | Image globale par defaut |
| `og:type` | `article` (actualites, evenements) / `website` (autres) | `website` |
| `og:url` | URL canonique courante | — |
| `og:locale` | Selon locale active | `fr_FR` |

## Pattern d'URL image OG

```
# Image par defaut (fichier statique)
{SITE_URL}/images/og/og-default.png

# Image de contenu (variante medium via API)
{SITE_URL}/api/public/media/{uuid}/download?variant=medium

# Image resolue par backend (campus, users)
{SITE_URL}{cover_image_url}?variant=medium
```

## Mapping locale

| Code i18n | og:locale |
|-----------|-----------|
| `fr` | `fr_FR` |
| `en` | `en_US` |
| `ar` | `ar_SA` |
