# Quickstart: 009-og-meta-tags

## Prerequis

- Node.js + pnpm (frontend Nuxt)
- Le projet tourne en local (`pnpm dev`)

## Variables d'environnement

Ajouter dans `usenghor_nuxt/.env` :

```env
NUXT_PUBLIC_SITE_URL=http://localhost:3000
```

En production, configurer :

```env
NUXT_PUBLIC_SITE_URL=https://[domaine-production]
```

## Tester les meta OG en local

1. Lancer le frontend : `cd usenghor_nuxt && pnpm dev`
2. Ouvrir une page publique (ex: `http://localhost:3000/actualites`)
3. Inspecter le HTML source (Ctrl+U) et verifier la presence des balises `og:*` et `twitter:*`
4. Pour tester le rendu social :
   - Facebook : https://developers.facebook.com/tools/debug/
   - Twitter : https://cards-dev.twitter.com/validator
   - LinkedIn : https://www.linkedin.com/post-inspector/
   - (Necessite que le site soit accessible publiquement — utiliser un tunnel ngrok en dev si besoin)

## Fichiers principaux a modifier

| Fichier | Modification |
|---------|-------------|
| `nuxt.config.ts` | Ajouter `app.head` avec meta OG globales + `runtimeConfig.public.siteUrl` |
| `public/images/og/og-default.png` | Creer l'image OG par defaut (1200x630) |
| 28 pages avec `useSeoMeta()` | Ajouter `ogUrl`, `ogLocale`, `ogLocaleAlternate`, corriger `ogImage` pour utiliser `?variant=medium` et URL absolue |
| 5 pages sans meta | Ajouter `useSeoMeta()` complet |
| 2 pages `levees-de-fonds/` | Migrer de `useHead()` vers `useSeoMeta()` reactif |

## Validation

Chaque page publique doit avoir dans son `<head>` :
- `og:title` — titre localise
- `og:description` — description localisee (max 160 chars)
- `og:image` — URL absolue vers image medium ou default
- `og:url` — URL canonique absolue
- `og:type` — `website` ou `article`
- `og:site_name` — "Universite Senghor"
- `og:locale` — locale active (fr_FR, en_US, ar_SA)
- `twitter:card` — `summary_large_image`
- `twitter:title`, `twitter:description`, `twitter:image` — coherents avec OG
