# Research: 009-og-meta-tags

**Date**: 2026-03-21

## R-001: Strategie d'integration des meta OG dans Nuxt 4

**Decision**: Utiliser une approche a deux niveaux :
1. **Niveau global** : `app.head` dans `nuxt.config.ts` pour les defaults (og:site_name, og:type, og:image par defaut, twitter:card)
2. **Niveau page** : `useSeoMeta()` (deja en place sur 28 pages) pour surcharger titre, description et image specifiques

**Rationale**: Le projet utilise deja `useSeoMeta()` sur 28 pages publiques. Ajouter un socle global dans `nuxt.config.ts` permet de couvrir automatiquement les 5 pages publiques sans meta (index.vue, formations/index.vue, about.vue, formulaires/[slug].vue, profil/index.vue) et de fournir un fallback pour toutes les pages.

**Alternatives considered**:
- Composable dedie `useOgMeta()` : sur-engineering pour simplement ajouter des defaults. Les pages existantes utilisent deja `useSeoMeta()` correctement.
- Plugin Nuxt global : moins transparent, plus difficile a maintenir.
- `useServerSeoMeta()` : ameliorerait le SSR mais n'est utilise nulle part dans le projet — introduirait une inconsistance.

## R-002: Resolution des URLs d'images pour og:image

**Decision**: Pour les images de contenu, utiliser la variante `medium` via le query param `?variant=medium` sur l'endpoint `/api/public/media/{uuid}/download`. Les URLs doivent etre absolues (prefixees du domaine).

**Rationale**: L'utilisateur a explicitement demande de privilegier `medium` (1200px de large par defaut dans l'ImageEditor) — taille ideale pour OG (recommandation 1200x630). Le systeme de variantes est deja en place : endpoint `?variant=low|medium|original`, fichiers physiques generes a l'upload.

**Alternatives considered**:
- `original` : trop lourd pour les crawlers sociaux (temps de fetch)
- `low` (480px) : en dessous du minimum recommande OG de 1200px
- Generer une variante specifique OG : sur-engineering inutile, `medium` correspond deja a 1200px

## R-003: Image par defaut Dieese_couleur.png

**Decision**: Utiliser `/images/logos/Dieese_couleur.png` comme image OG par defaut. Si ses dimensions sont insuffisantes (< 1200x630), creer une version `og-default.png` optimisee dans `/public/images/og/`.

**Rationale**: Le fichier existe deja dans `usenghor_nuxt/public/images/logos/`. Les reseaux sociaux requierent des images d'au moins 200x200 (Facebook minimum) mais recommandent 1200x630 pour un affichage optimal. L'image actuelle est un logo carre — elle pourrait beneficier d'un recadrage sur fond blanc/brand pour un format paysage.

**Alternatives considered**:
- Utiliser le logo tel quel sans adaptation : risque de crop indesirable sur certaines plateformes
- Generer dynamiquement une image OG (type og:image generator) : complexite disproportionnee pour le besoin

## R-004: Construction des URLs absolues

**Decision**: Utiliser `runtimeConfig.public.siteUrl` (nouvelle variable d'environnement `NUXT_PUBLIC_SITE_URL`) pour prefixer toutes les URLs OG. En dev : `http://localhost:3000`, en prod : `https://usenghor.org` (ou le domaine reel).

**Rationale**: `og:image` et `og:url` exigent des URLs absolues. Le projet a deja `runtimeConfig.public.apiBase` pour l'API — meme pattern pour le site. `useRequestURL()` de Nuxt pourrait aussi fonctionner mais est moins fiable derriere un reverse proxy sans configuration specifique.

**Alternatives considered**:
- `useRequestURL()` : depend des headers du reverse proxy (X-Forwarded-*) et peut etre incorrect en production
- Hardcoder le domaine : non maintenable entre environnements

## R-005: Gestion du og:locale multilingue

**Decision**: Mapper les codes i18n vers les locales OG : `fr` → `fr_FR`, `en` → `en_US`, `ar` → `ar_SA`. Declarer les locales alternatives via `og:locale:alternate`.

**Rationale**: La strategie i18n du projet est `prefix_except_default` (FR sans prefixe, EN/AR avec prefixe). Les meta OG doivent refleter la langue de la page consultee. `useSeoMeta()` supporte `ogLocale` et `ogLocaleAlternate` nativement.

## R-006: Pages sans meta existantes

**Decision**: Ajouter `useSeoMeta()` aux 5 pages publiques manquantes : `index.vue`, `formations/index.vue`, `about.vue`, `formulaires/[slug].vue`, `profil/index.vue`. Corriger aussi les 2 pages `levees-de-fonds/` qui utilisent `useHead` non-reactif.

**Rationale**: L'audit revele que ces pages n'ont aucune meta. La homepage (`index.vue`) est la page la plus partagee — critique pour OG.

## R-007: Exclusion des pages admin

**Decision**: Pas d'action specifique necessaire — les pages admin n'ont deja aucun `useSeoMeta()`/`useHead()` et sont exclues du sitemap (`exclude: ['/admin/**']`). Les defaults globaux dans `nuxt.config.ts` s'appliqueront, mais c'est acceptable car ces pages sont derriere une authentification.

**Rationale**: Ajouter un `noindex` robot meta aux pages admin serait ideal mais sort du scope OG. Les balises OG globales (titre, description defaut) ne nuisent pas aux pages admin puisqu'elles ne sont pas crawlees.
