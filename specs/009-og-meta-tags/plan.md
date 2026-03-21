# Implementation Plan: Balises Open Graph pour le partage de liens

**Branch**: `009-og-meta-tags` | **Date**: 2026-03-21 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/009-og-meta-tags/spec.md`

## Summary

Ajouter les balises Open Graph (og:title, og:description, og:image, etc.) et Twitter Card a toutes les pages publiques du site pour un rendu professionnel lors du partage sur les reseaux sociaux. L'approche est a deux niveaux : defaults globaux dans `nuxt.config.ts` + surcharge par page via `useSeoMeta()`. L'image par defaut est le logo Dieese (version 1200x630), les pages de contenu utilisent leur image de couverture en variante `medium` (1200px) via `?variant=medium`.

## Technical Context

**Language/Version**: TypeScript (Nuxt 4 / Vue 3)
**Primary Dependencies**: `@nuxtjs/i18n` (prefix_except_default), `@nuxtjs/sitemap`, `useSeoMeta()` (Nuxt built-in)
**Storage**: N/A — feature purement frontend, lecture seule des donnees existantes
**Testing**: Inspection manuelle du HTML source + outils de debug OG (Facebook Sharing Debugger, Twitter Card Validator)
**Target Platform**: SSR web (Nuxt 4, node-server preset)
**Project Type**: Web application (frontend uniquement pour cette feature)
**Performance Goals**: Aucune degradation > 100ms sur le temps de chargement des pages
**Constraints**: URLs OG absolues requises (domaine configurable), images minimum 1200x630, variante `medium` privilegiee
**Scale/Scope**: ~35 pages publiques a couvrir (28 avec meta existantes, 5 sans meta, 2 a migrer)

## Constitution Check

*GATE: Le projet n'a pas de constitution formelle (template vierge). Aucune violation a verifier.*

**Post-Phase 1**: Aucun nouveau pattern architectural introduit. La feature utilise exclusivement les mecanismes Nuxt existants (`nuxt.config.ts`, `useSeoMeta()`). Aucune nouvelle dependance. Conforme.

## Project Structure

### Documentation (this feature)

```text
specs/009-og-meta-tags/
├── plan.md              # Ce fichier
├── spec.md              # Specification fonctionnelle
├── research.md          # Recherche et decisions techniques
├── data-model.md        # Entites utilisees (lecture seule)
├── quickstart.md        # Guide de demarrage rapide
├── contracts/
│   └── og-meta-contract.md  # Contrat des balises attendues par page
├── checklists/
│   └── requirements.md  # Checklist qualite spec
└── tasks.md             # (Phase 2 — /speckit.tasks)
```

### Source Code (repository root)

```text
usenghor_nuxt/
├── nuxt.config.ts                          # +app.head meta defaults + runtimeConfig.public.siteUrl
├── public/images/og/
│   └── og-default.png                      # NOUVEAU: image OG par defaut 1200x630
├── app/
│   ├── pages/
│   │   ├── index.vue                       # AJOUTER useSeoMeta()
│   │   ├── about.vue                       # AJOUTER useSeoMeta()
│   │   ├── formations/index.vue            # AJOUTER useSeoMeta()
│   │   ├── formulaires/[slug].vue          # AJOUTER useSeoMeta()
│   │   ├── levees-de-fonds/index.vue       # MIGRER useHead → useSeoMeta reactif
│   │   ├── levees-de-fonds/[slug].vue      # MIGRER useHead → useSeoMeta reactif + ogImage
│   │   ├── actualites/[slug].vue           # MODIFIER ogImage → ?variant=medium + URL absolue
│   │   ├── actualites/evenements/[id].vue  # MODIFIER ogImage → ?variant=medium + URL absolue
│   │   ├── actualites/appels/[slug].vue    # MODIFIER ogImage → ?variant=medium + URL absolue
│   │   ├── formations/[type]/[slug].vue    # MODIFIER ogImage → ?variant=medium + URL absolue
│   │   ├── projets/[slug]/index.vue        # MODIFIER ogImage → ?variant=medium + URL absolue
│   │   ├── a-propos/partenaires/campus/[slug].vue  # MODIFIER ogImage → URL absolue
│   │   ├── a-propos/equipe/[id].vue        # MODIFIER ogImage → URL absolue
│   │   └── [toutes les autres pages publiques]  # AJOUTER ogUrl, ogLocale, ogLocaleAlternate
│   └── i18n/locales/
│       ├── fr/index.ts                     # AJOUTER cles og.defaultDescription, og.siteName
│       ├── en/index.ts                     # AJOUTER cles og.defaultDescription, og.siteName
│       └── ar/index.ts                     # AJOUTER cles og.defaultDescription, og.siteName
```

**Structure Decision**: Feature purement frontend dans `usenghor_nuxt/`. Aucune modification backend. Les modifications touchent la config Nuxt, un fichier image statique, les fichiers i18n, et ~35 fichiers de pages existants.

## Complexity Tracking

> Aucune violation a justifier — feature simple utilisant les mecanismes Nuxt standards.
