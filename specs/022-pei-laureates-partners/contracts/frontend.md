# Contrat — Backoffice Nuxt (ajouts 022)

Complète [frontend.md](../../021-pei-entrepreneurship-core/contracts/frontend.md) de la feature 021. Libellés FR en dur dans les gabarits (convention PEI) ; seuls les libellés partagés de traduction passent par `adminTranslate.*`.

## Routes admin (`definePageMeta({ layout: 'admin' })`)

| Route | Fichier | Rôle |
|---|---|---|
| `/admin/entrepreneuriat/laureats` | `pages/admin/entrepreneuriat/laureats/index.vue` | Liste : recherche (nom, projet) + filtres cohorte / type / publication ; glisser-déposer **actif seulement si une cohorte est filtrée et qu'aucun autre filtre ni recherche n'est actif** (message explicatif sinon) ; publier / dépublier, étoile « mis en avant », supprimer |
| `/admin/entrepreneuriat/laureats/nouveau` | `laureats/nouveau.vue` | Création → redirection vers `/laureats/{id}` |
| `/admin/entrepreneuriat/laureats/[id]` | `laureats/[id].vue` | Édition, bascule publication / mise en avant, suppression |
| `/admin/entrepreneuriat/partenaires` | `pages/admin/entrepreneuriat/partenaires/index.vue` | Page unique : trois familles, ajout par sélecteur, changement de famille, glisser-déposer par famille, retrait, lien vers `/admin/partenaires` |

Protection : déjà couverte par `ROUTE_PERMISSIONS['/admin/entrepreneuriat']` (préfixe). Boutons conditionnés par `hasPermission('entrepreneurship.create'|'edit'|'delete')`.

## Barre latérale (`composables/useAdminSidebar.ts`)

Deux enfants insérés après `entrepreneurship-cohorts` et avant `entrepreneurship-resources` :
```ts
{ id: 'entrepreneurship-laureates', label: 'Lauréats et étudiants-entrepreneurs', icon: 'fa-solid fa-award',
  route: '/admin/entrepreneuriat/laureats', permissions: ['entrepreneurship.view'] },
{ id: 'entrepreneurship-partners', label: 'Partenaires du pôle', icon: 'fa-solid fa-handshake',
  route: '/admin/entrepreneuriat/partenaires', permissions: ['entrepreneurship.view'] },
```

## Types `types/api/entrepreneurship.ts` (ajouts)

`PeiLaureateType`, `PeiPartnerFamily`, `PeiLaureateAdmin`, `PeiLaureateCreatePayload`, `PeiLaureateUpdatePayload`, `PeiLaureateListParams { q?, cohort_id?, type?, is_published?, page?, page_size? }`, `FeaturedStatus`, `PeiPartnerLinkAdmin`, `PeiPartnerAvailable`, `PeiLaureatesPublic`, `PeiPartnerFamilyPublic` ; `PeiDashboardStats` + `laureates: { published, total }`, `partners: { active, total }` ; `PeiTranslateMissingResponse` + `laureates`.

## Composable `composables/useEntrepreneurshipApi.ts` (ajouts)

Exports de module : `laureateTypeOptions` (`[{ value: 'fse_laureate', label: 'Lauréat FSE' }, { value: 'student_entrepreneur', label: 'Étudiant-entrepreneur' }]`), `laureateTypeLabels`, `partnerFamilyOptions` (ordre fixe : académiques et institutionnels, organisations d'appui, organisations internationales), `partnerFamilyLabels`, `cohortTypeForLaureateType` (`fse_laureate → 'fse'`, `student_entrepreneur → 'see'`).

Fonctions : `listLaureates(params)`, `getLaureate(id)`, `createLaureate(p)`, `updateLaureate(id, p)`, `deleteLaureate(id)`, `reorderLaureates(cohortId, ids)`, `setLaureatePublished(id, bool)`, `setLaureateFeatured(id, bool)`, `translateLaureate(p)` ; `listPeiPartners(family?)`, `searchAvailablePartners(q, limit?)`, `linkPeiPartner(partnerId, family)`, `updatePeiPartnerFamily(partnerId, family)`, `unlinkPeiPartner(partnerId)`, `reorderPeiPartners(family, ids)`. `getDashboard()` et `translateMissing()` inchangés (types étendus).

## Composants `components/entrepreneurship/admin/` (auto-import `EntrepreneurshipAdmin*`)

| Composant | Props | Emits | Notes |
|---|---|---|---|
| `LaureateList.vue` | `items`, `loading`, `canEdit`, `canDelete`, `dragDisabled` | `edit(id)`, `delete(id)`, `togglePublish(item)`, `toggleFeatured(item)`, `reorder(ids)` | Copie de `CohortList` ; colonnes vignette photo, nom, projet, cohorte (badge), type (badge), mis en avant (étoile), publié (badge) ; `VueDraggable tag="tbody" handle=".drag-handle"` |
| `LaureateForm.vue` | `laureate?`, `cohorts: PeiCohortAdmin[]`, `saving` | `submit(payload)`, `cancel` | Copie de `CohortForm` ; `<select>` type → filtre les cohortes proposées (`cohortTypeForLaureateType`) ; `EntrepreneurshipAdminLangTabs` pour département + verbatim (compteur `n/600`, `maxlength=600`) ; photo via `AdminMediaPicker type="image"` + aperçu / retirer (pattern `ProgramForm` « Visuel ») ; cinq champs URL ; montant (`type="number" min="0" step="0.01"`) ; cases « Mis en avant », « Publié » ; bouton « Traduire FR → EN/AR » (champs vides uniquement) |
| `PartnerFamilyBoard.vue` | `links: PeiPartnerLinkAdmin[]`, `loading`, `canEdit`, `canDelete` | `changeFamily(partnerId, family)`, `unlink(partnerId)`, `reorder(family, ids)` | Trois sections (une par famille, ordre fixe) ; chaque section = `VueDraggable` indépendant ; ligne = logo (ou initiale), nom, type (badge `partnerTypeLabels` de `usePartnersApi`), badge « Inactif » + info-bulle « non visible publiquement », `<select>` famille, lien « Ouvrir dans Partenaires » (`/admin/partenaires`), bouton retirer (confirmation) ; état vide par famille |
| `PartnerPicker.vue` | `open`, `defaultFamily?` | `select(partnerId, family)`, `close` | Modale calquée sur `AlbumSelector` : recherche debouncée 300 ms → `searchAvailablePartners`, liste (logo, nom, type, badge inactif), sélection unique, `<select>` famille, bouton « Rattacher » ; message « Le partenaire n'existe pas ? Créez-le dans le backoffice Partenaires » avec lien |
| `DashboardCards.vue` (modifié) | inchangé | — | + carte « Lauréats et étudiants-entrepreneurs » (publiés / total, `fa-award`, couleur `amber`) et « Partenaires du pôle » (actifs / rattachés, `fa-handshake`, couleur `red`) |

Nouveaux composants uniquement après vérification d'absence d'équivalent (faite : aucun sélecteur de partenaires ni carte lauréat réutilisables).

## Tableau de bord `pages/admin/entrepreneuriat/index.vue`

Deux cartes supplémentaires via `DashboardCards` ; message de l'action « Traduire les champs manquants » étendu (« … , N lauréats complétés »). Bloc « Géré ailleurs » : ajouter le raccourci « Partenaires (fiches) » → `/admin/partenaires`, convention « Créer ou modifier un partenaire ici, puis le rattacher dans Partenaires du pôle ».
