# Contrat frontend — 026

Chemins relatifs à `usenghor_nuxt/`. Aucune nouvelle page, aucun nouveau composant, aucune dépendance. Noms vérifiés absents du dépôt, pour éviter les collisions d'auto-import : `getServiceLink`, `usePeiBreadcrumb`, `navChildLabel`, `slugifyServiceName`.

## 1. Types et composables

### `app/composables/usePublicOrganizationApi.ts`

```ts
interface ServicePublic { …; parent_id: string | null; landing_path: string | null }
interface ServiceRelativePublic { id; name; name_en?; name_ar?; sigle; color; landing_path; display_order }
interface ServicePublicWithChildren extends ServicePublic { children: ServicePublic[] }
interface SectorPublicWithServices extends SectorPublic { services: ServicePublicWithChildren[] }
interface ServicePublicWithDetails extends ServicePublic { …; parent?: ServiceRelativePublic | null; children?: ServiceRelativePublic[] }

function getServiceLink(service: Pick<ServicePublic, 'name' | 'landing_path'>): string
// → service.landing_path || getServiceUrl(service)   (non localisé : l'appelant applique localePath)
```

`findServiceBySlug` et `getServiceUrl` ne changent pas.

### `app/composables/useServicesApi.ts`, `app/types/api/organization.ts`

`ServiceRead`, `ServiceWithDetails`, `ServiceCreate`, `ServiceUpdate` et `ServiceDisplay` reçoivent `parent_id?: string | null` et `landing_path?: string | null`. Le mappage `getAllServices` → `ServiceDisplay` les recopie.

## 2. Backoffice

### `app/pages/admin/organisation/services/index.vue`

- **Modale** : sous « Secteur », deux champs.
  - `<select v-model="newService.parent_id">` « Service parent ».
    - Option `null` « Aucun (service de premier niveau) ».
    - Options : `parentOptions` = services avec `!parent_id`, `sector_id === newService.sector_id` et `id !== editingServiceId`, triés par nom (libellé `sigle — name`).
    - `:disabled="editingChildrenCount > 0"`, avec l'aide « Ce service a {n} pôle(s) : il ne peut pas être rattaché ».
    - `watch(newService.sector_id)` : le parent est remis à `null` s'il n'est plus proposé.
  - `<input v-model.trim="newService.landing_path">` « Page dédiée (facultatif) ».
    - Placeholder `/entrepreneuriat`.
    - Aide : « Chemin interne sans préfixe de langue. Si renseigné, la carte du service dans l'organigramme mène à cette page. »
    - Erreur immédiate si la valeur ne respecte pas `LANDING_PATH_RE` (même expression que l'API).
    - Bouton Enregistrer désactivé si la valeur est invalide.
- **Erreur serveur** : `modalError` affiche `error.data.detail` des 409 / 422 dans la modale (bandeau rouge `role="alert"`).
- **Liste** (vues tableau et groupée) :
  - `orderHierarchically(list)` place les pôles juste après leur parent, lui-même trié par `(display_order, name)`.
  - Ligne de pôle : `ps-8`, icône `fa-solid fa-turn-up fa-rotate-90` (`rtl:-scale-x-100`), pastille « Pôle de {parent.sigle || parent.name} ».
  - Un pôle dont le parent est filtré s'affiche seul, avec sa pastille.
  - `canDrag` est faux sur les lignes de pôle, et les `ids` envoyés à `reorderServices` excluent les pôles.
- **Modale de suppression** : si le service a N pôles, avertissement « Ses N pôle(s) deviendront des services de premier niveau du secteur. »
- **Duplication** : aucun changement d'interface.

### `app/pages/admin/organisation/services/[id].vue` (onglet Informations, lecture seule)

Lignes « Service parent » (lien vers `/admin/organisation/services/{parent_id}`, ou « — »), « Page dédiée » (chemin, ou « — »), « Pôles » (liens, ou rien). Les pôles viennent de `getAllServices` filtrés sur `parent_id === id`, ou d'une lecture existante.

## 3. Public

### `app/components/organization/OrganigrammeSection.vue`

```vue
<template v-for="service in sector.services" :key="service.id">
  <NuxtLink v-if="!service.children?.length" data-card …>  <!-- nœud STRICTEMENT identique à l'existant -->
  <div v-else class="flex flex-col gap-2">
    <NuxtLink data-card …>                                   <!-- même carte parent -->
    <ul class="ms-4 ps-3 border-s-2 space-y-2" :style="{ borderColor: … }" :aria-label="t('organization.poles.of', { name })">
      <li v-for="pole in service.children"><NuxtLink :to="localePath(getServiceLink(pole))" class="carte compacte">…</NuxtLink></li>
    </ul>
  </div>
</template>
```

- Destination d'une carte : `localePath(getServiceLink(service))`. C'est le changement de `to` pour les seuls services qui ont `landing_path` ; les autres gardent la même URL.
- Carte compacte de pôle :
  - pastille du sigle (ou `fa-building`) ;
  - nom localisé (`localized(pole, 'name')`) ;
  - flèche `fa-arrow-right` avec `rtl:-scale-x-100` ;
  - couleur : `pole.color`, sinon celle du parent, sinon la palette du secteur ;
  - variantes `dark:`.

### `app/pages/a-propos/organisation/[type]/[slug].vue` (service, onglet Présentation)

Insertion entre la carte de description et le bouton « onglet suivant » :

1. Si `entity.parent` : lien « {t('organizationDetail.poles.parentOf')} {sigle || nom localisé} » → `localePath(getServiceUrl(entity.parent))`.
2. Si `entity.landing_path` : bouton « {t('organizationDetail.poles.dedicatedPage')} » → `localePath(entity.landing_path)`.
3. Si `entity.children?.length` : `<section aria-labelledby>` avec le titre `organizationDetail.poles.title` (h3) et une grille `sm:grid-cols-2 gap-4` de cartes au style de l'organigramme → `localePath(getServiceLink(child))`.

Sans parent, sans page dédiée et sans pôle, rien n'est rendu : aucun élément et aucune marge ajoutés.

Onglet Services de la fiche **secteur** : sous un service qui a des pôles, une ligne `organizationDetail.poles.count` (« + {n} pôle(s) », pluriel i18n) avec lien vers la fiche du parent. Le reste est inchangé.

### i18n (`i18n/locales/{fr,en,ar}/`)

| Clé | FR | EN | AR |
|---|---|---|---|
| `organizationDetail.poles.title` | Pôles | Hubs | الأقطاب |
| `organizationDetail.poles.parentOf` | Pôle de | Hub of | قطب تابع لـ |
| `organizationDetail.poles.dedicatedPage` | Voir la page dédiée | Visit the dedicated page | زيارة الصفحة المخصصة |
| `organizationDetail.poles.count` | + {n} pôle \| + {n} pôles | + {n} hub \| + {n} hubs | + {n} قطب \| + {n} أقطاب |
| `organization.poles.of` | Pôles de {name} | Hubs of {name} | أقطاب {name} |
| `footer.university.entrepreneurship` | Entreprendre à Senghor | Entrepreneurship at Senghor | ريادة الأعمال في سنغور |

## 4. Menu

### `app/components/AppNavBar.vue`

- Types JSON primaire et secondaire : `label_en?: string`, `label_ar?: string`.
- `NavChild` : `_labels?: { fr?: string; en?: string; ar?: string }`. Le champ `_label` est conservé (= `label`).
- `function navChildLabel(sectionKey: string, child: NavChild): string` renvoie `child._labels?.[locale.value] || child._label || t(\`nav.dropdowns.${sectionKey}.${child.key}\`)`.
- Utilisé aux trois rendus (méga-menu, menu « Plus », mobile).
- Pour une entrée sans `label_en` / `label_ar`, la sortie est identique à l'actuelle.

### `app/components/admin/editorial/NavItemsField.vue`

- `NavSubItem` : `label_en?`, `label_ar?`.
- Formulaire : « Libellé (anglais) » et « Libellé (arabe) » (`dir="rtl"`), facultatifs, sous « Libellé ».
- À la sauvegarde : `{ ...itemExistant, ...formData }`, qui préserve les clés inconnues. Les valeurs vides sont supprimées de l'objet, sans écrire de chaîne vide.

## 5. Pied de page — `app/components/AppFooter.vue`

`<li>` après `governance` : `NuxtLink :to="localePath('/entrepreneuriat')"`, `t('footer.university.entrepreneurship')`, mêmes classes que les liens voisins.

## 6. Fil d'Ariane du mini-site — `app/composables/usePeiPage.ts`

```ts
export function usePeiBreadcrumb(current: MaybeRefOrGetter<string | null>, ddeServiceId: MaybeRefOrGetter<string | null>): {
  breadcrumb: ComputedRef<PeiBreadcrumbItem[]>
  ready: Promise<unknown>            // useAsyncData('pei-org-services', () => listServices().catch(() => []))
}
```

- `pole` = `services.find(s => s.landing_path === '/entrepreneuriat')`.
- `dde` = `services.find(s => s.id === pole?.parent_id)`, sinon `services.find(s => s.id === toValue(ddeServiceId))`.
- Éléments :
  1. Accueil (`/`) ;
  2. `nav.about` (`/a-propos`) ;
  3. `about.tabs.organization` (`/a-propos/organisation`) ;
  4. si `dde` : `dde.sigle || t('pei.breadcrumb.dde')` (`getServiceUrl(dde)`) ;
  5. `pei.breadcrumb.pole` (`/entrepreneuriat` si `current`, sinon sans `to`) ;
  6. si `current` : `current`, sans `to`.
- `usePeiPage` l'utilise (`current = t('pei.nav.' + navKey)`).
- `pages/entrepreneuriat/index.vue` : `usePeiBreadcrumb(null, ddeServiceId)`. Suppression des l.59-67.
- `pages/entrepreneuriat/activites.vue` : `usePeiBreadcrumb(t('pei.nav.activities'), ddeServiceId)`. Suppression des l.69-77.
- JSON-LD `BreadcrumbList` : `buildBreadcrumbList(breadcrumb.value)` sur les sept pages. Le rendu existant n'émet `item` que pour les éléments avec `to` et non derniers.
- `ddeServiceId` / `ddeService`, qui servent aux données (actualités, événements, médias), ne changent pas.

## 7. Plan du site — `server/api/__sitemap__/urls.ts`

```ts
// Copie de slugify (app/composables/usePublicOrganizationApi.ts) — doit rester identique
function slugifyServiceName(name: string): string { /* NFD, retrait des diacritiques, lower, [^a-z0-9]+ → '-', trim '-' */ }
```

- Secteurs : `GET /api/public/sectors` → `/a-propos/organisation/secteur/${code.toLowerCase()}`.
- Services : `GET /api/public/services` → `/a-propos/organisation/service/${slugifyServiceName(name)}` (tous actifs, pôles compris), dédupliqués.
- Chaque bloc a son propre `try` : une erreur vide ce bloc, sans casser le plan du site.
- `/entrepreneuriat/*` : routes statiques découvertes automatiquement (`autoI18n`), aucune ligne ajoutée.
