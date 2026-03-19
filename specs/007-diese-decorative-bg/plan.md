# Implementation Plan: Dièses décoratifs en arrière-plan

**Branch**: `007-diese-decorative-bg` | **Date**: 2026-03-19 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `specs/007-diese-decorative-bg/spec.md`

## Summary

Ajouter le symbole dièse de l'Université Senghor comme élément décoratif subtil dans 4 zones cibles : le footer (toutes pages), le hero de la page d'accueil, la section "Découvrir l'Université" de la page À propos, et les cartes "preview". L'approche retenue est un composant Vue réutilisable `DecorativeDiese.vue` positionné en absolu dans un coin, avec basculement automatique entre les deux variantes d'image selon le mode clair/sombre.

## Technical Context

**Language/Version**: TypeScript, Vue 3 (Nuxt 4)
**Primary Dependencies**: Tailwind CSS, `useDarkMode()` composable (existant)
**Storage**: N/A — feature purement frontend/visuelle
**Testing**: Vérification visuelle + lint (`pnpm lint`)
**Target Platform**: Web (navigateurs modernes, SSR Nuxt)
**Project Type**: Web application (frontend Nuxt 4)
**Performance Goals**: Chargement supplémentaire < 100ms (images légères, lazy-loadées hors footer)
**Constraints**: `aria-hidden` obligatoire, `print:hidden`, `overflow-hidden` sur conteneurs
**Scale/Scope**: 4 composants modifiés, 1 nouveau composant créé

## Constitution Check

*Constitution non configurée pour ce projet → pas de gates formels à valider.*

Vérifications de bon sens appliquées :

| Vérification | Statut |
|---|---|
| Aucun nouveau endpoint backend | ✅ Conforme — feature 100% frontend |
| Aucune migration BDD | ✅ Conforme — aucune donnée impliquée |
| Composant réutilisable (pas de duplication) | ✅ Conforme — 1 composant, 4 usages |
| Accessibilité WCAG (aria-hidden décoratif) | ✅ Conforme |
| Pas d'impact sur les performances critiques | ✅ Conforme — images statiques légères |

## Project Structure

### Documentation (this feature)

```text
specs/007-diese-decorative-bg/
├── plan.md           ✅ Ce fichier
├── research.md       ✅ Phase 0 — décisions techniques
├── quickstart.md     ✅ Phase 1 — guide d'intégration
└── tasks.md          (Phase 2 — /speckit.tasks)
```

*Pas de `data-model.md` ni `contracts/` — feature purement visuelle, aucune entité de données ni interface API.*

### Source Code

```text
usenghor_nuxt/
├── app/
│   ├── components/
│   │   ├── ui/
│   │   │   └── DecorativeDiese.vue          # NOUVEAU — composant réutilisable
│   │   ├── AppFooter.vue                    # MODIFIÉ — ajout du dièse P1
│   │   ├── HeroSection.vue                  # MODIFIÉ — ajout du dièse P2
│   │   └── section/
│   │       └── Preview.vue                  # MODIFIÉ — ajout du dièse P3
│   └── pages/
│       └── a-propos/
│           └── index.vue                    # MODIFIÉ — section "Découvrir" P2
└── public/
    └── images/logos/
        ├── diese-usenghor.png               # EXISTANT — mode clair
        └── diese-usenghor_degrade.png       # EXISTANT — mode sombre
```

**Structure Decision** : Le composant est placé dans `components/ui/` conformément au pattern d'organisation du projet (composants utilitaires génériques). Les 4 modifications ciblent des composants déjà bien identifiés — pas de nouveau fichier de page.

## Phase 0 — Research ✅

**Output** : [research.md](./research.md)

Décisions clés résolues :

| Décision | Choix retenu |
|----------|-------------|
| Image mode clair | `diese-usenghor.png` (correction : `Dieese_couleur.png` n'existe pas) |
| Image mode sombre | `diese-usenghor_degrade.png` |
| Switch dark mode | `useDarkMode()` → `isDark` ref → `computed` src |
| Positionnement | `absolute` dans coin, rogné par `overflow-hidden` parent |
| Accessibilité | `aria-hidden="true"` + `role="presentation"` |
| Impression | `print:hidden` |
| Opacité | 4–6% selon la zone (footer 6%, hero 5%, sections 5%, cartes 4%) |

## Phase 1 — Design

### Composant `DecorativeDiese.vue`

**Interface des props** :

```typescript
interface Props {
  position?: 'top-right' | 'top-left' | 'bottom-right' | 'bottom-left'
  // défaut: 'bottom-right'
  size?: 'sm' | 'md' | 'lg' | 'xl'
  // sm = w-32 h-32 (128px), md = w-48 h-48 (192px)
  // lg = w-64 h-64 (256px), xl = w-80 h-80 (320px)
  opacity?: number
  // défaut: 0.05 — plage recommandée: 0.03–0.10
}
```

**Comportement** :
- Sélectionne automatiquement `diese-usenghor.png` (clair) ou `diese-usenghor_degrade.png` (sombre) via `useDarkMode()`
- Positionné en `absolute` dans le coin défini par `position`
- Rendu uniquement côté client si nécessaire pour éviter les flash SSR (à évaluer à l'implémentation)
- `aria-hidden="true"` + `role="presentation"` sur le `<img>`
- Classe `print:hidden` sur le wrapper
- `pointer-events-none` pour ne pas intercepter les clics

**Classes de position** (mapping) :

| Valeur prop | Classes Tailwind |
|---|---|
| `top-right` | `-top-8 -right-8` |
| `top-left` | `-top-8 -left-8` |
| `bottom-right` | `-bottom-8 -right-8` |
| `bottom-left` | `-bottom-8 -left-8` |

Le décalage négatif (-8) permet au dièse d'être partiellement rogné naturellement par le `overflow-hidden` du parent.

### Paramètres par zone cible

| Zone | Composant | `position` | `size` | `opacity` |
|------|-----------|-----------|--------|-----------|
| Footer | `AppFooter.vue` | `bottom-right` | `xl` (320px) | `0.06` |
| Hero | `HeroSection.vue` | `bottom-left` | `xl` (320px) | `0.05` |
| Section "Découvrir" | `a-propos/index.vue` | `top-right` | `lg` (256px) | `0.05` |
| Cartes preview | `section/Preview.vue` | `top-right` | `md` (192px) | `0.04` |

### Point d'intégration dans chaque composant

**AppFooter.vue** : Dans le `<div class="absolute inset-0 overflow-hidden">` existant (ligne ~116), juste après les cercles flous déjà présents.

**HeroSection.vue** : Dans la couche background existante (`relative h-screen ... overflow-hidden`), dans le bloc décoratif.

**a-propos/index.vue** : Dans le wrapper de la section "Découvrir", en ajoutant `relative overflow-hidden` si absent, puis `<DecorativeDiese>` en absolu.

**section/Preview.vue** : Dans le wrapper de la section (`<section class="py-16 ... bg-white dark:bg-gray-900">`), en ajoutant `relative overflow-hidden` et le composant.

## Complexity Tracking

*Aucune violation de constitution — section non applicable.*
