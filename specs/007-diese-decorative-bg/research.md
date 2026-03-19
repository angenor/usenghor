# Research: Dièses décoratifs en arrière-plan

**Feature**: 007-diese-decorative-bg
**Date**: 2026-03-19

---

## 1. Assets disponibles

| Fichier | Chemin réel | Usage |
|---------|-------------|-------|
| `diese-usenghor.png` | `public/images/logos/diese-usenghor.png` | Mode clair |
| `diese-usenghor_degrade.png` | `public/images/logos/diese-usenghor_degrade.png` | Mode sombre |

**Correction** : La spec mentionne `Dieese_couleur.png` — ce fichier n'existe pas. Le fichier coloré réel est `diese-usenghor.png`. Tous les chemins dans le plan utilisent les noms corrects.

---

## 2. Pattern de positionnement existant

Tous les composants du projet utilisent ce patron pour les éléments décoratifs :

```html
<section class="relative overflow-hidden">
  <!-- Couche décorative (derrière) -->
  <div class="absolute inset-0 overflow-hidden pointer-events-none">
    <!-- éléments absolus ici -->
  </div>
  <!-- Contenu (devant) -->
  <div class="relative z-10">...</div>
</section>
```

**Décision** : Le composant `DecorativeDiese.vue` s'insère dans la couche décorative existante de chaque zone cible, sans créer de nouveau wrapper.

---

## 3. Gestion du mode sombre

**Pattern existant** : `useDarkMode()` composable exposant `isDark` (ref boolean). Utilisé dans `AppNavBar.vue` et d'autres composants.

**Décision** : Utiliser `isDark` pour switcher dynamiquement la source d'image entre les deux variantes. Pas de CSS `dark:` pour les images (l'approche `v-bind:src` est plus fiable et déjà établie dans le projet).

```typescript
const { isDark } = useDarkMode()
const dieseSrc = computed(() =>
  isDark.value
    ? '/images/logos/diese-usenghor_degrade.png'
    : '/images/logos/diese-usenghor.png'
)
```

---

## 4. Zones cibles et paramètres visuels

| Zone | Composant | Opacité | Taille | Coin |
|------|-----------|---------|--------|------|
| Footer | `AppFooter.vue` | 6% | 280px | Bas-droite |
| Hero (accueil) | `HeroSection.vue` | 5% | 320px | Bas-gauche |
| Section "Découvrir" (À propos) | `pages/a-propos/index.vue` | 5% | 280px | Haut-droite |
| Cartes preview | `section/Preview.vue` | 4% | 200px | Haut-droite |

**Rationale opacité** : Le footer est sur fond très sombre (gray-900) → légèrement plus visible. Les cartes preview sont plus petites → plus discret. Le hero est sur fond dark avec images → très subtil.

---

## 5. Accessibilité

**Décision** : `aria-hidden="true"` + `role="presentation"` sur le `<img>`. Les images ne portent aucune sémantique. Conforme WCAG 2.1 (technique H67 — utiliser alt="" et role="presentation" pour les images décoratives).

---

## 6. Impression

**Décision** : Classe utilitaire Tailwind `print:hidden` sur le composant. Simple et sans CSS custom.

---

## 7. Responsivité

**Décision** : Taille réduite sur mobile (classe responsive) :
- Mobile : `w-32 h-32` (~128px)
- Tablette : `sm:w-48 sm:h-48` (~192px)
- Desktop : `lg:w-[280px] lg:h-[280px]` ou plus selon la zone

Les tailles exactes sont configurables via les props du composant.

---

## 8. Composant : interface retenue

```typescript
interface Props {
  position?: 'top-right' | 'top-left' | 'bottom-right' | 'bottom-left'
  size?: 'sm' | 'md' | 'lg' | 'xl'  // sm=128, md=192, lg=280, xl=320
  opacity?: number  // 0.03 à 0.10, défaut 0.05
}
```

**Rationale** : Props simples et intentionnelles — pas de surconfiguartion. Le composant gère lui-même le choix de l'image selon `isDark`.

---

## Alternatives rejetées

| Alternative | Rejetée parce que |
|-------------|-------------------|
| CSS `dark:` sur `<img>` | Tailwind ne gère pas `src` via dark: |
| `background-image` CSS | Moins flexible pour les transitions et le SSR |
| Plusieurs petits dièses | Trop chargé visuellement (validé en clarification) |
| Image centrée plein-format | Trop visible, gêne la lecture (validé en clarification) |
