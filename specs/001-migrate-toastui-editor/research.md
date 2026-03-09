# Research: Migration EditorJS vers TOAST UI Editor

**Date**: 2026-03-08
**Feature**: `001-migrate-toastui-editor`

## R1: Viabilité de TOAST UI Editor

### Decision
TOAST UI Editor (`@toast-ui/editor@3.2.2`) est techniquement utilisable mais présente des risques majeurs pour ce projet.

### Findings

| Critère | Statut | Détail |
|---------|--------|--------|
| Maintenance | **ABANDONNÉ** | Dernier commit : août 2024. Issue #3297 confirme l'abandon. Aucun correctif de sécurité à venir. |
| Vue 3 | OK | Wrapper `@toast-ui/vue-editor@3.x` compatible Vue 3, ou instanciation directe via Composition API. |
| SSR / Nuxt 4 | **Client-only** | Manipulation directe du DOM. Nécessite `<ClientOnly>` ou `.client.vue`. |
| RTL (arabe) | **NON SUPPORTÉ** | Issue #838 : "RTL is not supported". Workaround CSS partiel possible mais insuffisant pour un éditeur complet. |
| i18n français | OK | Locale `fr-FR` disponible via `@toast-ui/editor/dist/i18n/fr-fr.js`. |
| WYSIWYG + Markdown | OK | Double mode natif avec switch intégré dans la toolbar. |
| Upload d'images | OK | Hook `addImageBlobHook` permet l'upload vers un endpoint custom. |
| Tableaux + fusion | OK | Plugin officiel `@toast-ui/editor-plugin-table-merged-cell`. |
| Embeds vidéo | **NON NATIF** | Pas de plugin officiel. Nécessite un plugin custom ou widgetRules (v3.0+). |

### Risques identifiés

1. **CRITIQUE - RTL non supporté** : Le site Usenghor est trilingue avec l'arabe (RTL). Le workaround CSS ne couvre pas l'ensemble des interactions de l'éditeur (curseur, sélection, toolbar). Impact direct sur l'User Story 3 (P1).
2. **ÉLEVÉ - Projet abandonné** : Aucune correction de bugs ni de failles de sécurité. Dépendance morte à long terme.
3. **MOYEN - Pas d'embed natif** : Développement custom nécessaire pour YouTube/Vimeo (FR-008).

### Alternatives considérées

| Éditeur | RTL | Vue 3 | Maintenu | Markdown | Table merge |
|---------|-----|-------|----------|----------|-------------|
| **Tiptap** (ProseMirror) | Oui (extension) | Natif | Actif | Via extension | Via extension |
| **Milkdown** (ProseMirror) | Partiel | Plugin | Actif | Natif | Plugin |
| **EditorJS** (actuel) | Non natif | Wrapper | Actif | Non | Plugin custom existant |
| **TOAST UI** | Non | Wrapper | **Abandonné** | Natif | Plugin officiel |

### Recommandation

**Tiptap** serait un meilleur choix pour ce projet (Vue 3 natif, RTL supporté, activement maintenu, extensible). Cependant, la décision finale revient à l'utilisateur. Le plan ci-dessous est rédigé pour TOAST UI Editor comme demandé.

---

## R2: Format de stockage double colonne HTML + Markdown

### Decision
Stocker le contenu en deux colonnes par langue : `*_html` (pour le rendu public) et `*_md` (pour l'édition Markdown).

### Rationale
- TOAST UI Editor produit nativement les deux formats via `getHTML()` et `getMarkdown()`
- Le HTML est directement utilisable pour le rendu public (`v-html`), pas besoin de parser
- Le Markdown est plus lisible pour l'édition et le versionnage
- Synchronisation automatique par l'éditeur lors de la sauvegarde

### Implications sur le schéma DB
Les colonnes TEXT existantes (ex: `content`, `description`) stockent actuellement du JSON EditorJS. Après migration :
- Colonne existante → renommée `*_legacy` (backup temporaire)
- Nouvelle colonne `*_html` (TEXT) : contenu HTML
- Nouvelle colonne `*_md` (TEXT) : contenu Markdown
- Pour les champs trilingues : `content_fr_html`, `content_fr_md`, `content_en_html`, `content_en_md`, `content_ar_html`, `content_ar_md`

**Note** : Certains champs ne sont PAS trilingues (ex: `events.content`, `news.content` sont des champs simples TEXT). La structure de colonnes s'adapte à chaque cas.

---

## R3: Colonnes de base de données à migrer

### Decision
Identifier toutes les colonnes stockant du contenu EditorJS pour le script de migration.

### Findings

| Table | Colonne(s) | Type actuel | Trilingue ? |
|-------|-----------|-------------|-------------|
| `events` | `content` | TEXT | Non |
| `news` | `content` | TEXT | Non |
| `projects` | `description`, `summary` | TEXT | Non |
| `project_calls` | `description`, `conditions` | TEXT | Non |
| `programs` | `description`, `teaching_methods`, `format`, `evaluation_methods` | TEXT | Non |
| `application_calls` | `description`, `target_audience` | TEXT | Non |
| `sectors` | `description`, `mission` | TEXT | Non |
| `services` | `description`, `mission` | TEXT | Non |
| `service_objectives` | `description` | TEXT | Non |
| `service_achievements` | `description` | TEXT | Non |
| `service_projects` | `description` | TEXT | Non |

**Total** : 11 tables, ~20 colonnes à migrer.

**Note** : Les champs `objectives` et `target_audience` de `programs` sont JSONB (arrays de strings), pas du contenu EditorJS. Ils ne nécessitent pas de migration.

---

## R4: Pages d'administration utilisant l'éditeur

### Findings

| Page admin | Fichier | Composant utilisé |
|------------|---------|-------------------|
| Actualités (nouveau) | `admin/contenus/actualites/nouveau.vue` | `<EditorJS>` |
| Actualités (edit) | `admin/contenus/actualites/[id]/edit.vue` | `<EditorJS>` |
| Événements (nouveau) | `admin/contenus/evenements/nouveau.vue` | `<EditorJS>` |
| Événements (edit) | `admin/contenus/evenements/[id]/edit.vue` | `<EditorJS>` |
| Projets (nouveau) | `admin/projets/liste/nouveau.vue` | `<EditorJS>` |
| Projets (edit) | `admin/projets/liste/[id]/edit.vue` | `<EditorJS>` |
| Appels projets (nouveau) | `admin/projets/appels/nouveau.vue` | `<EditorJS>` |
| Appels projets (edit) | `admin/projets/appels/[id]/edit.vue` | `<EditorJS>` |
| Programmes (edit) | `admin/formations/programmes/[id]/edit.vue` | `<EditorJS>` |
| Appels candidatures (nouveau) | `admin/candidatures/appels/nouveau.vue` | `<EditorJS>` |
| Appels candidatures (edit) | `admin/candidatures/appels/[id]/edit.vue` | `<EditorJS>` |

**Total** : 11 pages admin à mettre à jour.

---

## R5: Pages publiques affichant du contenu riche

### Findings

| Page publique | Fichier | Composant utilisé |
|---------------|---------|-------------------|
| Article actualité | `actualites/[slug].vue` | `<EditorJSRenderer>` |
| Événement | `actualites/evenements/[id].vue` | `<EditorJSRenderer>` |
| Projet | `projets/[slug]/index.vue` | `<EditorJSRenderer>` |
| Programme | `formations/[type]/[slug].vue` | `<EditorJSRenderer>` |
| Équipe membre | `a-propos/equipe/[id].vue` | `<EditorJSRenderer>` |
| Profil utilisateur | `profil/index.vue` | `<EditorJSRenderer>` |
| Organisation | `a-propos/organisation/[type]/[slug].vue` | `<EditorJSRenderer>` |
| Organigramme | `components/organization/OrganigrammeSection.vue` | `<EditorJSRenderer>` |
| Campus présentation | `components/campus/CampusPresentation.vue` | `<EditorJSRenderer>` |
| Campus partenaires | `components/partners/CampusMapSection.vue` | `<EditorJSRenderer>` |
| Appel description | `components/calls/DescriptionSection.vue` | `<EditorJSRenderer>` |

**Total** : 11 pages/composants publics à mettre à jour.

---

## R6: Approche d'intégration avec Nuxt 4

### Decision
Composant `.client.vue` avec instanciation directe de l'API JavaScript TOAST UI Editor (sans le wrapper Vue officiel).

### Rationale
- Le wrapper `@toast-ui/vue-editor` n'est plus maintenu et peut casser avec les futures versions de Vue
- L'API JavaScript directe est plus stable et prévisible
- Le pattern `.client.vue` de Nuxt résout le problème SSR proprement
- Plus de contrôle sur le cycle de vie (init/destroy)

### Pattern d'implémentation

```typescript
// composables/useToastUIEditor.ts
// Wrapper Vue 3 Composition API autour de l'API JS native
// - Ref réactive pour le contenu (HTML + Markdown)
// - onMounted: new Editor({ el, hooks, plugins, language })
// - onUnmounted: editor.destroy()
// - Expose: getHTML(), getMarkdown(), setHTML(), setMarkdown()
```

---

## R7: Stratégie de migration big-bang

### Decision
Migration big-bang avec fenêtre de maintenance.

### Plan d'exécution
1. **Backup** : `pg_dump` complet de la base de données
2. **Script Python** : Parse chaque colonne JSON EditorJS → génère HTML + Markdown
3. **Migration SQL** : ALTER TABLE pour ajouter les nouvelles colonnes, UPDATE avec les données converties
4. **Déploiement** : Nouveau code frontend + backend
5. **Validation** : Vérification manuelle d'un échantillon de pages
6. **Nettoyage** (J+30) : Suppression des colonnes legacy

### Rollback
En cas d'échec : restaurer le backup `pg_dump` + redéployer l'ancienne version du code.
