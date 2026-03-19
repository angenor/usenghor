# Tasks: Dièses décoratifs en arrière-plan

**Input**: Design documents from `specs/007-diese-decorative-bg/`
**Feature Branch**: `007-diese-decorative-bg`
**Stack**: TypeScript, Vue 3 (Nuxt 4), Tailwind CSS

**Organisation**: Tâches groupées par user story pour permettre une implémentation et un test indépendants.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut s'exécuter en parallèle (fichiers différents, pas de dépendances)
- **[Story]**: User story concernée (US1, US2, US3)

---

## Phase 1: Setup

**Purpose**: Vérification des assets et préparation

- [x] T001 Vérifier la présence des deux images dans `usenghor_nuxt/public/images/logos/` : `diese-usenghor.png` (mode clair) et `diese-usenghor_degrade.png` (mode sombre)
- [x] T002 Vérifier que le dossier `usenghor_nuxt/app/components/ui/` existe (le créer si absent)

---

## Phase 2: Fondation — Composant réutilisable (Prérequis bloquant)

**Purpose**: Créer le composant `DecorativeDiese.vue` utilisé par toutes les user stories

**⚠️ CRITIQUE** : Aucune user story ne peut commencer avant que cette phase soit complète

- [x] T003 Créer le composant `usenghor_nuxt/app/components/ui/DecorativeDiese.vue` avec les props `position` (`'top-right' | 'top-left' | 'bottom-right' | 'bottom-left'`, défaut `'bottom-right'`), `size` (`'sm' | 'md' | 'lg' | 'xl'`, défaut `'lg'`), `opacity` (`number`, défaut `0.05`) — utiliser `useDarkMode()` pour switcher entre `diese-usenghor.png` (clair) et `diese-usenghor_degrade.png` (sombre), appliquer `aria-hidden="true"` et `role="presentation"` sur l'`<img>`, `pointer-events-none` et `print:hidden` sur le wrapper, positionnement absolu dans le coin via classes Tailwind mappées depuis la prop `position`

**Checkpoint**: Composant créé et auto-importé par Nuxt — prêt à être intégré dans les 4 zones

---

## Phase 3: User Story 1 — Dièse décoratif dans le footer (Priority: P1) 🎯 MVP

**Goal**: Afficher le motif dièse en arrière-plan du footer sur toutes les pages, en mode clair et sombre

**Independent Test**: Ouvrir n'importe quelle page sur `http://localhost:3000`, faire défiler jusqu'au footer, vérifier la présence du motif dièse partiellement rogné en bas-droite — basculer en mode sombre et vérifier l'adaptation de l'image

### Implémentation

- [x] T004 [US1] Dans `usenghor_nuxt/app/components/AppFooter.vue`, à l'intérieur du `<div class="absolute inset-0 overflow-hidden">` existant (après les deux divs de cercles flous), ajouter `<DecorativeDiese position="bottom-right" size="xl" :opacity="0.06" />`

**Checkpoint**: US1 complète — le footer affiche le dièse sur toutes les pages en mode clair et sombre

---

## Phase 4: User Story 2 — Dièse dans les sections de contenu (Priority: P2)

**Goal**: Afficher le motif dièse dans la section hero (accueil) et la section "Découvrir l'Université" (À propos)

**Independent Test**: Ouvrir `http://localhost:3000` et vérifier le dièse en bas-gauche du hero — puis ouvrir `http://localhost:3000/a-propos` et vérifier le dièse en haut-droite de la section "Découvrir l'Université" — tester en mode clair et sombre

### Implémentation

- [x] T005 [P] [US2] Dans `usenghor_nuxt/app/components/HeroSection.vue`, dans la couche background (section avec `relative h-screen overflow-hidden`), ajouter `<DecorativeDiese position="bottom-left" size="xl" :opacity="0.05" />` dans le bloc décoratif existant (après les overlays gradient, avant le contenu `z-10`)
- [x] T006 [P] [US2] Dans `usenghor_nuxt/app/pages/a-propos/index.vue`, identifier le wrapper de la section "Découvrir l'Université" (contenant `discoverTitle` et les cartes), s'assurer qu'il a les classes `relative overflow-hidden`, puis ajouter `<DecorativeDiese position="top-right" size="lg" :opacity="0.05" />` à l'intérieur en positionnement absolu

**Checkpoint**: US2 complète — hero et section "Découvrir" affichent le dièse, indépendamment testables

---

## Phase 5: User Story 3 — Dièse sur les cartes preview (Priority: P3)

**Goal**: Afficher un motif dièse discret dans les cartes "preview" de section

**Independent Test**: Ouvrir `http://localhost:3000/a-propos`, localiser les cartes preview (section "Découvrir l'Université"), vérifier la présence du dièse partiellement rogné en haut-droite de chaque carte avec une opacité très faible — vérifier en mode clair et sombre

### Implémentation

- [x] T007 [US3] Dans `usenghor_nuxt/app/components/section/Preview.vue`, sur le `<section>` wrapper (actuellement `py-16 lg:py-20 bg-white dark:bg-gray-900 transition-colors duration-300`), ajouter les classes `relative overflow-hidden` si absentes, puis ajouter `<DecorativeDiese position="top-right" size="md" :opacity="0.04" />` comme premier enfant du `<section>` (avant le contenu existant)

**Checkpoint**: US3 complète — les cartes preview affichent un dièse subtil, les 3 user stories sont fonctionnelles

---

## Phase Finale: Polish & vérifications transversales

**Purpose**: Validation visuelle, accessibilité, responsive, impression

- [ ] T008 [P] Vérifier sur mobile (DevTools, viewport 375px) que le dièse dans le footer, le hero et les sections n'est pas surdimensionné ni gênant — ajuster la taille mobile dans `DecorativeDiese.vue` si nécessaire (réduire d'une taille sur sm:)
- [ ] T009 [P] Vérifier le rendu impression (`Ctrl+P` ou `window.print()`) — confirmer que `print:hidden` masque tous les motifs dièse
- [ ] T010 [P] Vérifier le balisage accessibilité avec les DevTools : inspecter chaque `<img>` dièse et confirmer `aria-hidden="true"` et `role="presentation"`
- [x] T011 Lancer `pnpm eslint` dans `usenghor_nuxt/` — aucune nouvelle erreur introduite (erreurs pré-existantes non liées au dièse confirmées)
- [ ] T012 Vérification visuelle finale : parcourir les pages cibles (accueil, à-propos) en mode clair puis sombre, confirmer l'aspect subtil et élégant sur Chrome, Firefox et Safari

---

## Dépendances & Ordre d'exécution

### Dépendances entre phases

- **Phase 1 (Setup)** : Pas de dépendance — démarrer immédiatement
- **Phase 2 (Fondation)** : Dépend de Phase 1 — **bloque toutes les user stories**
- **Phase 3, 4, 5 (US1, US2, US3)** : Dépendent toutes de Phase 2 — peuvent s'exécuter en parallèle ensuite
- **Phase Finale (Polish)** : Dépend de toutes les US complètes

### Dépendances entre user stories

- **US1 (P1)** : Démarrable après Phase 2 — aucune dépendance inter-story
- **US2 (P2)** : Démarrable après Phase 2 — indépendante de US1
- **US3 (P3)** : Démarrable après Phase 2 — indépendante de US1 et US2

### Opportunités de parallélisation

- T005 et T006 (US2) peuvent s'exécuter en parallèle (fichiers différents)
- T008, T009, T010 (Polish) peuvent s'exécuter en parallèle

---

## Exemple d'exécution parallèle : Phase 4 (US2)

```text
# Lancer en parallèle après T003 complété :
Tâche A : T005 — Intégrer dans HeroSection.vue
Tâche B : T006 — Intégrer dans a-propos/index.vue
```

---

## Stratégie d'implémentation

### MVP (User Story 1 uniquement)

1. Compléter Phase 1 (Setup)
2. Compléter Phase 2 (Fondation — créer `DecorativeDiese.vue`)
3. Compléter Phase 3 (US1 — footer)
4. **STOP et VALIDER** : footer opérationnel sur toutes les pages
5. Déployer si satisfaisant

### Livraison incrémentale

1. Setup + Fondation → composant prêt
2. US1 → footer → valider → déployer (MVP)
3. US2 → hero + section À propos → valider
4. US3 → cartes preview → valider
5. Polish → validation finale

---

## Notes

- Toutes les intégrations utilisent le même composant `DecorativeDiese.vue` — aucune duplication
- Les images sont des assets statiques existants — pas de build step supplémentaire
- Nuxt auto-importe `components/ui/DecorativeDiese.vue` — pas d'import manuel nécessaire
- `useDarkMode()` est un composable existant dans le projet — disponible immédiatement
