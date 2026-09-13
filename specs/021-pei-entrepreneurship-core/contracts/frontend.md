# Contrat — Backoffice Nuxt (routes, composable, composants)

## Routes admin (`definePageMeta({ layout: 'admin' })`)

| Route | Fichier | Rôle |
|---|---|---|
| `/admin/entrepreneuriat` | `pages/admin/entrepreneuriat/index.vue` | Tableau de bord : compteurs, raccourcis, bloc « Géré ailleurs », action « Traduire les champs manquants », avertissement si `dde_service_id` vide |
| `/admin/entrepreneuriat/dispositifs` | `dispositifs/index.vue` | Liste + recherche + filtres phase / état + glisser-déposer + toggle actif + suppression |
| `/admin/entrepreneuriat/dispositifs/nouveau` | `dispositifs/nouveau.vue` | Création → redirection vers `/dispositifs/{id}` |
| `/admin/entrepreneuriat/dispositifs/[id]` | `dispositifs/[id].vue` | Édition + aperçu FR (`RichTextRenderer`) |
| `/admin/entrepreneuriat/cohortes`, `/nouveau`, `/[id]` | `cohortes/*.vue` | idem |
| `/admin/entrepreneuriat/ressources`, `/nouveau`, `/[id]` | `ressources/*.vue` | idem, filtres type / catégorie / publication |

Protection : `ROUTE_PERMISSIONS['/admin/entrepreneuriat'] = ['entrepreneurship.view']` (`composables/usePermissions.ts`) — couvre toutes les sous-routes par préfixe. Boutons créer / supprimer conditionnés par `hasPermission('entrepreneurship.create')` / `('entrepreneurship.delete')`.

## Barre latérale (`composables/useAdminSidebar.ts`)

```ts
{
  id: 'entrepreneurship', label: 'Entrepreneuriat (PEI)', icon: 'fa-solid fa-lightbulb',
  permissions: ['entrepreneurship.view'], description: 'Pôle Entrepreneuriat et Innovation',
  children: [
    { id: 'entrepreneurship-dashboard', label: 'Tableau de bord', icon: 'fa-solid fa-gauge', route: '/admin/entrepreneuriat', permissions: ['entrepreneurship.view'] },
    { id: 'entrepreneurship-programs', label: 'Dispositifs du parcours', icon: 'fa-solid fa-route', route: '/admin/entrepreneuriat/dispositifs', permissions: ['entrepreneurship.view'] },
    { id: 'entrepreneurship-cohorts', label: 'Cohortes', icon: 'fa-solid fa-people-group', route: '/admin/entrepreneuriat/cohortes', permissions: ['entrepreneurship.view'] },
    { id: 'entrepreneurship-resources', label: 'Boîte à outils', icon: 'fa-solid fa-toolbox', route: '/admin/entrepreneuriat/ressources', permissions: ['entrepreneurship.view'] },
  ]
}
```
Placée après la section « FAQ ».

## Composable `composables/useEntrepreneurshipApi.ts`

Basé sur `useApi().apiFetch`. Types dans `types/api/entrepreneurship.ts` (`PeiProgramAdmin`, `PeiProgramCreatePayload`, `PeiProgramUpdatePayload`, `PeiCohort*`, `PeiResource*`, `PeiDashboardStats`, `ReorderResponse`, `PeiProgramPhase`, `PeiCohortType`, `PeiResourceType`, `PeiColor`).

Exports de module (options d'enum, convention projet) : `programPhaseOptions`, `programPhaseLabels`, `cohortTypeOptions`, `resourceTypeOptions`, `resourceTypeLabels`, `colorOptions` (`{ value, label, swatchClass, badgeClass }`).

Fonctions : `getDashboard()`, `translateMissing()` ; `listPrograms(params)`, `getProgram(id)`, `createProgram(p)`, `updateProgram(id, p)`, `deleteProgram(id)`, `reorderPrograms(ids)`, `setProgramActive(id, active)`, `translateProgram(p)` ; mêmes 8 fonctions pour `Cohort` ; `listResources`, `listResourceCategories`, `getResource`, `createResource`, `updateResource`, `deleteResource`, `reorderResources`, `setResourcePublished`, `translateResource`.

## Composants `components/entrepreneurship/admin/` (auto-import `EntrepreneurshipAdmin*`)

| Composant | Props | Emits |
|---|---|---|
| `ProgramList.vue` | `items`, `loading`, `canEdit`, `canDelete`, `dragDisabled` | `edit(id)`, `delete(id)`, `toggleActive(item)`, `reorder(ids)` |
| `ProgramForm.vue` | `program?`, `saving` | `submit(payload)`, `cancel` |
| `CohortList.vue` / `CohortForm.vue` | idem | idem |
| `ResourceList.vue` / `ResourceForm.vue` | idem (+ `categories` pour le filtre) | idem (+ `togglePublish`) |
| `LangTabs.vue` | `modelValue: 'fr'\|'en'\|'ar'` | `update:modelValue` — onglets FR / EN / AR pour les champs simples ; AR rendu `dir="rtl"` |
| `DashboardCards.vue` | `stats: PeiDashboardStats` | — |

Composant transverse nouveau (R5) : `components/admin/MediaPicker.vue` (`<AdminMediaPicker>`), props `{ open: boolean, type?: MediaType, title?: string }`, emits `select(media: MediaRead)`, `close`. Champ associé dans les formulaires : aperçu (`useMediaApi().getMediaUrl(id)`), boutons « Choisir dans la médiathèque » / « Retirer ».

Éditeur riche : `<AdminRichTextEditor mode="modal" v-model="md" v-model:model-value-en v-model:model-value-ar v-model:html-value v-model:html-value-en v-model:html-value-ar />` (les 6 v-model activent les onglets EN/AR internes).

Réordonnancement : `import { VueDraggable } from 'vue-draggable-plus'`, `tag="tbody"`, `handle=".drag-handle"`, `:disabled="dragDisabled"`, `@end` → `emit('reorder', items.map(i => i.id))`.

## Tableau de bord — bloc « Géré ailleurs »

| Raccourci | Cible | Rappel de convention |
|---|---|---|
| Actualités de la DDE | `/admin/contenus/actualites` | « Rattacher l'actualité au service DDE » |
| Événements de la DDE | `/admin/contenus/evenements` | « Renseigner le service DDE sur l'événement » |
| Albums de la DDE | `/admin/organisation/services` (+ `?service_id=` si clé présente) | « Albums dans l'onglet Médias de la fiche DDE » |
| FAQ | `/admin/faq` | « Catégorie “see” pour les questions du statut » |
| Appels à candidatures | `/admin/candidatures/appels` | « Appel de type Formation ; slug à reporter dans la page Entrepreneuriat » |
| Page éditoriale « Entrepreneuriat » | `/admin/editorial/valeurs` | « Textes, chiffres clés, images du slider, e-mail de contact, service DDE » |

Si `dashboard.dde_service.id` est null : bandeau ambre « Le service DDE n'est pas identifié : renseignez la clé « Service DDE » dans la page Entrepreneuriat (Valeurs) ».
