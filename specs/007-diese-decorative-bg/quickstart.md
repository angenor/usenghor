# Quickstart: Dièses décoratifs

## 1. Créer `DecorativeDiese.vue`

**Emplacement** : `usenghor_nuxt/app/components/ui/DecorativeDiese.vue`

Ce composant est auto-importé par Nuxt (convention `components/`).

### Props attendues

| Prop | Type | Défaut | Description |
|------|------|--------|-------------|
| `position` | `'top-right' \| 'top-left' \| 'bottom-right' \| 'bottom-left'` | `'bottom-right'` | Coin de positionnement |
| `size` | `'sm' \| 'md' \| 'lg' \| 'xl'` | `'lg'` | Taille (sm=128px, md=192px, lg=256px, xl=320px) |
| `opacity` | `number` | `0.05` | Opacité (0.03–0.10) |

### Logique clé

- Utilise `useDarkMode()` → `isDark` pour switcher l'image source
- Image mode clair : `/images/logos/diese-usenghor.png`
- Image mode sombre : `/images/logos/diese-usenghor_degrade.png`
- `aria-hidden="true"` + `role="presentation"` sur `<img>`
- `pointer-events-none` + `print:hidden` sur le wrapper

## 2. Intégrer dans les 4 zones cibles

### Footer (`AppFooter.vue`)

Dans le `<div class="absolute inset-0 overflow-hidden">` existant :

```html
<DecorativeDiese position="bottom-right" size="xl" :opacity="0.06" />
```

### Hero (`HeroSection.vue`)

Dans la couche background du hero (déjà `relative overflow-hidden`) :

```html
<DecorativeDiese position="bottom-left" size="xl" :opacity="0.05" />
```

### Section "Découvrir" (`pages/a-propos/index.vue`)

Wrapper de la section à rendre `relative overflow-hidden`, puis :

```html
<DecorativeDiese position="top-right" size="lg" :opacity="0.05" />
```

### Cartes preview (`section/Preview.vue`)

Dans le `<section>` wrapper (ajouter `relative overflow-hidden` si absent) :

```html
<DecorativeDiese position="top-right" size="md" :opacity="0.04" />
```

## 3. Vérification

```bash
cd usenghor_nuxt
pnpm lint          # Aucune erreur TypeScript/ESLint
pnpm dev           # Vérification visuelle sur http://localhost:3000
```

**Points à vérifier** :
- [ ] Footer : dièse visible en bas-droite, mode clair ET sombre
- [ ] Hero (accueil) : dièse visible en bas-gauche, très subtil sur fond sombre
- [ ] Page À propos, section "Découvrir" : dièse en haut-droite
- [ ] Cartes preview : dièse discret en haut-droite
- [ ] Impression (`Ctrl+P`) : aucun dièse visible
- [ ] Mobile : motif proportionné, pas de surcharge
