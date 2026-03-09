# Tasks: Migration EditorJS vers TOAST UI Editor

**Input**: Design documents from `/specs/001-migrate-toastui-editor/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/

**Tests**: Non demandés explicitement. Validation manuelle uniquement.

**Organization**: Tasks groupées par user story pour implémentation et test indépendants.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut être exécuté en parallèle (fichiers différents, pas de dépendances)
- **[Story]**: User story associée (US1, US2, US3, US4, US5)
- Chemins exacts inclus dans les descriptions

## Path Conventions

- **Frontend**: `usenghor_nuxt/app/`
- **Backend**: `usenghor_backend/app/`
- **SQL**: `usenghor_backend/documentation/modele_de_données/`
- **Scripts**: `usenghor_backend/scripts/`

---

## Phase 1: Setup

**Purpose**: Installation des dépendances et création de la structure de base

- [x] T001 Installer les dépendances TOAST UI Editor dans `usenghor_nuxt/` : `pnpm add @toast-ui/editor @toast-ui/editor-plugin-table-merged-cell`
- [x] T002 [P] Créer les déclarations TypeScript pour TOAST UI Editor dans `usenghor_nuxt/app/types/toastui-editor.d.ts`

---

## Phase 2: Foundational (Bloquant)

**Purpose**: Composants et composables de base nécessaires avant toute user story

**Attention**: Les phases US1-US3 ne peuvent pas commencer tant que cette phase n'est pas terminée.

- [x] T003 Créer le composable `useToastUIEditor` dans `usenghor_nuxt/app/composables/useToastUIEditor.ts` avec l'interface définie dans `contracts/editor-component.md` : `html`, `markdown`, `setContent()`, `clearContent()`, `hasContent`, `getPlainText()`, `toJSON()`, `fromJSON()`
- [x] T004 Créer le composant éditeur `ToastUIEditor.client.vue` dans `usenghor_nuxt/app/components/ToastUIEditor.client.vue`. Instanciation directe de l'API JS (sans wrapper Vue officiel). Props : `modelValue`, `initialEditType`, `height`, `placeholder`, `language`, `direction`, `disabled`. Events : `update:modelValue`, `update:html`, `ready`, `image-upload`. Configurer le plugin `table-merged-cell`, la locale `fr-FR`, et le hook `addImageBlobHook` pour l'upload d'images vers `/api/admin/media/`
- [x] T005 Créer le composant renderer `RichTextRenderer.vue` dans `usenghor_nuxt/app/components/RichTextRenderer.vue`. Props : `html`, `class`. Rendu via `v-html` avec classes `prose dark:prose-invert`. Post-traitement des liens : ajout `target="_blank"` et `rel="noopener noreferrer"` sur les liens externes

**Checkpoint**: Les 3 composants/composables de base sont prêts. Les user stories peuvent commencer.

---

## Phase 3: User Story 1 - Édition de contenu riche dans l'administration (Priority: P1)

**Goal**: Les administrateurs peuvent créer et éditer du contenu riche via TOAST UI Editor sur toutes les pages admin.

**Independent Test**: Ouvrir `http://localhost:3000/admin/contenus/actualites/nouveau`, saisir du contenu riche (titres, listes, images, tableaux), sauvegarder, recharger et vérifier que le contenu est intact.

### Implementation for User Story 1

- [x] T006 [US1] Adapter le wrapper multilingue `RichTextEditor.vue` dans `usenghor_nuxt/app/components/admin/RichTextEditor.vue` : remplacer `<EditorJS>` par `<ToastUIEditor>`, conserver les onglets FR/EN/AR, émettre `content_html` et `content_md` au lieu de l'ancien format JSON EditorJS
- [x] T007 [P] [US1] Modifier les schémas Pydantic dans `usenghor_backend/app/schemas/content.py` : remplacer `content: str | None` par `content_html: str | None` + `content_md: str | None` dans `EventCreate`, `EventUpdate`, `EventRead`, `NewsCreate`, `NewsUpdate`, `NewsRead`
- [x] T008 [P] [US1] Modifier les schémas Pydantic dans `usenghor_backend/app/schemas/project.py` : remplacer `description` par `description_html` + `description_md`, et `conditions` par `conditions_html` + `conditions_md` dans les schémas Project et ProjectCall
- [x] T009 [P] [US1] Modifier les schémas Pydantic dans `usenghor_backend/app/schemas/academic.py` : remplacer `description`, `teaching_methods`, `format`, `evaluation_methods` par leurs variantes `*_html` + `*_md` dans les schémas Program
- [x] T010 [P] [US1] Modifier les schémas Pydantic dans `usenghor_backend/app/schemas/organization.py` (si existant) ou le fichier correspondant : remplacer `description` et `mission` par `*_html` + `*_md` pour les schémas sectors, services, service_objectives, service_achievements, service_projects
- [x] T011 [P] [US1] Modifier les schémas Pydantic dans `usenghor_backend/app/schemas/application.py` (ou fichier correspondant) : remplacer `description` et `target_audience` par `*_html` + `*_md` pour application_calls
- [x] T012 [US1] Mettre à jour la page admin `usenghor_nuxt/app/pages/admin/contenus/actualites/nouveau.vue` : remplacer `<EditorJS>` par le nouveau composant, adapter le payload de sauvegarde pour envoyer `content_html` + `content_md`
- [x] T013 [P] [US1] Mettre à jour la page admin `usenghor_nuxt/app/pages/admin/contenus/actualites/[id]/edit.vue` : remplacer `<EditorJS>` par le nouveau composant, charger le contenu depuis `content_md` et sauvegarder `content_html` + `content_md`
- [x] T014 [P] [US1] Mettre à jour la page admin `usenghor_nuxt/app/pages/admin/contenus/evenements/nouveau.vue` : remplacer `<EditorJS>` par le nouveau composant
- [x] T015 [P] [US1] Mettre à jour la page admin `usenghor_nuxt/app/pages/admin/contenus/evenements/[id]/edit.vue` : remplacer `<EditorJS>` par le nouveau composant
- [x] T016 [P] [US1] Mettre à jour la page admin `usenghor_nuxt/app/pages/admin/projets/liste/nouveau.vue` : remplacer `<EditorJS>` par le nouveau composant
- [x] T017 [P] [US1] Mettre à jour la page admin `usenghor_nuxt/app/pages/admin/projets/liste/[id]/edit.vue` : remplacer `<EditorJS>` par le nouveau composant
- [x] T018 [P] [US1] Mettre à jour la page admin `usenghor_nuxt/app/pages/admin/projets/appels/nouveau.vue` : remplacer `<EditorJS>` par le nouveau composant
- [x] T019 [P] [US1] Mettre à jour la page admin `usenghor_nuxt/app/pages/admin/projets/appels/[id]/edit.vue` : remplacer `<EditorJS>` par le nouveau composant
- [x] T020 [P] [US1] Mettre à jour la page admin `usenghor_nuxt/app/pages/admin/formations/programmes/[id]/edit.vue` : remplacer `<EditorJS>` par le nouveau composant
- [x] T021 [P] [US1] Mettre à jour la page admin `usenghor_nuxt/app/pages/admin/candidatures/appels/nouveau.vue` : remplacer `<EditorJS>` par le nouveau composant
- [x] T022 [P] [US1] Mettre à jour la page admin `usenghor_nuxt/app/pages/admin/candidatures/appels/[id]/edit.vue` : remplacer `<EditorJS>` par le nouveau composant

**Checkpoint**: Toutes les 11 pages admin utilisent TOAST UI Editor. L'édition de contenu fonctionne de bout en bout.

---

## Phase 4: User Story 2 - Affichage du contenu sur les pages publiques (Priority: P1)

**Goal**: Le contenu créé via TOAST UI Editor est correctement affiché sur les pages publiques avec dark mode et sécurité des liens.

**Independent Test**: Créer du contenu via l'admin, naviguer vers la page publique correspondante, vérifier le rendu en mode clair et sombre.

### Implementation for User Story 2

- [x] T023 [P] [US2] Mettre à jour la page publique `usenghor_nuxt/app/pages/actualites/[slug].vue` : remplacer `<EditorJSRenderer :data="...">` par `<RichTextRenderer :html="content_html">`
- [x] T024 [P] [US2] Mettre à jour la page publique `usenghor_nuxt/app/pages/actualites/evenements/[id].vue` : remplacer `<EditorJSRenderer>` par `<RichTextRenderer>`
- [x] T025 [P] [US2] Mettre à jour la page publique `usenghor_nuxt/app/pages/projets/[slug]/index.vue` : remplacer `<EditorJSRenderer>` par `<RichTextRenderer>`
- [x] T026 [P] [US2] Mettre à jour la page publique `usenghor_nuxt/app/pages/formations/[type]/[slug].vue` : remplacer `<EditorJSRenderer>` par `<RichTextRenderer>`
- [x] T027 [P] [US2] Mettre à jour la page publique `usenghor_nuxt/app/pages/a-propos/equipe/[id].vue` : remplacer `<EditorJSRenderer>` par `<RichTextRenderer>`
- [x] T028 [P] [US2] Mettre à jour la page publique `usenghor_nuxt/app/pages/profil/index.vue` : remplacer `<EditorJSRenderer>` par `<RichTextRenderer>`
- [x] T029 [P] [US2] Mettre à jour la page publique `usenghor_nuxt/app/pages/a-propos/organisation/[type]/[slug].vue` : remplacer `<EditorJSRenderer>` par `<RichTextRenderer>`
- [x] T030 [P] [US2] Mettre à jour le composant `usenghor_nuxt/app/components/organization/OrganigrammeSection.vue` : remplacer `<EditorJSRenderer>` par `<RichTextRenderer>`
- [x] T031 [P] [US2] Mettre à jour le composant `usenghor_nuxt/app/components/campus/CampusPresentation.vue` : remplacer `<EditorJSRenderer>` par `<RichTextRenderer>`
- [x] T032 [P] [US2] Mettre à jour le composant `usenghor_nuxt/app/components/partners/CampusMapSection.vue` : remplacer `<EditorJSRenderer>` par `<RichTextRenderer>`
- [x] T033 [P] [US2] Mettre à jour le composant `usenghor_nuxt/app/components/calls/DescriptionSection.vue` : remplacer `<EditorJSRenderer>` par `<RichTextRenderer>`

**Checkpoint**: Les 11 pages/composants publics affichent le contenu HTML avec dark mode et liens sécurisés.

---

## Phase 5: User Story 3 - Support multilingue et RTL (Priority: P1)

**Goal**: L'éditeur supporte les trois langues (FR/EN/AR) avec basculement RTL automatique pour l'arabe.

**Independent Test**: Dans l'admin, sélectionner l'onglet arabe sur un formulaire multilingue et vérifier que l'éditeur passe en mode RTL.

### Implementation for User Story 3

- [x] T034 [US3] Ajouter le workaround CSS RTL pour TOAST UI Editor dans `usenghor_nuxt/app/assets/css/main.css` ou directement dans `ToastUIEditor.client.vue` (scoped styles). Couvrir : direction du texte, alignement toolbar, placeholder, zones de saisie
- [x] T035 [US3] Modifier `usenghor_nuxt/app/components/admin/RichTextEditor.vue` : passer la prop `direction="rtl"` au composant `<ToastUIEditor>` lorsque l'onglet arabe est sélectionné. Vérifier que le basculement LTR/RTL fonctionne lors du changement d'onglet

**Checkpoint**: L'édition en arabe fonctionne en mode RTL dans l'administration.

---

## Phase 6: User Story 4 - Migration des contenus existants (Priority: P2)

**Goal**: Tous les contenus EditorJS existants en base de données sont convertis en HTML + Markdown compatibles avec TOAST UI Editor.

**Independent Test**: Exécuter le script de migration sur la base locale, vérifier qu'un échantillon de pages publiques affiche correctement les contenus migrés.

### Implementation for User Story 4

- [x] T036 [US4] Créer la migration SQL `usenghor_backend/documentation/modele_de_données/migrations/018_migrate_editorjs_to_toastui.sql` : pour chaque table et colonne identifiées dans data-model.md, renommer la colonne existante en `*_legacy`, ajouter `*_html` (TEXT) et `*_md` (TEXT)
- [x] T037 [US4] Créer le script de conversion Python `usenghor_backend/scripts/migrate_editorjs_to_toastui.py` : parser le JSON EditorJS OutputData de chaque colonne `*_legacy`, convertir chaque type de bloc en HTML et Markdown. Types supportés : paragraph, header (H1-H4), list (ordered/unordered/nested v2), image, quote, embed (→ iframe), table/MergeTable (→ table HTML standard), delimiter (→ hr), checklist (→ ul), linkTool, inlineCode, marker. Gérer les NULL et les JSON invalides (log + skip)
- [x] T038 [US4] Mettre à jour les fichiers SQL de référence dans `usenghor_backend/documentation/modele_de_données/services/` pour refléter les nouvelles colonnes `*_html` et `*_md` dans les tables : `09_content.sql` (events, news), `10_project.sql` (projects, project_calls), `07_academic.sql` (programs), `08_application.sql` (application_calls), `04_organization.sql` (sectors, services, service_objectives, service_achievements, service_projects)
- [x] T039 [US4] Valider le script de migration en local : exécuter sur la base Docker locale (`usenghor_postgres`), vérifier un échantillon de contenus migrés, confirmer que les valeurs NULL restent NULL et que les URLs d'images sont préservées

**Checkpoint**: La migration des données fonctionne en local. Prêt pour le déploiement en production.

---

## Phase 7: User Story 5 - Suppression complète d'EditorJS (Priority: P3)

**Goal**: Toutes les dépendances EditorJS sont supprimées du projet. Le code est propre et le build réussit.

**Independent Test**: Rechercher "editorjs" / "EditorJS" dans tout le code source — aucun résultat ne doit apparaître. `pnpm build` réussit sans erreur.

### Implementation for User Story 5

- [x] T040 [P] [US5] Supprimer le composant `usenghor_nuxt/app/components/EditorJS.vue`
- [x] T041 [P] [US5] Supprimer le composant `usenghor_nuxt/app/components/EditorJSRenderer.vue`
- [x] T042 [P] [US5] Supprimer le dossier plugin custom `usenghor_nuxt/app/components/editorjs/MergeTable/` (index.ts, types.ts, MergeTable.ts, Table.ts, SelectionManager.ts, ResizeManager.ts, icons.ts, styles.css)
- [x] T043 [P] [US5] Supprimer le composable `usenghor_nuxt/app/composables/useEditorJS.ts`
- [x] T044 [P] [US5] Supprimer les déclarations TypeScript `usenghor_nuxt/app/types/editorjs.d.ts`
- [x] T045 [US5] Désinstaller les 13 paquets npm EditorJS dans `usenghor_nuxt/` : `pnpm remove @editorjs/editorjs @editorjs/header @editorjs/list @editorjs/paragraph @editorjs/image @editorjs/quote @editorjs/embed @editorjs/table @editorjs/delimiter @editorjs/inline-code @editorjs/marker @editorjs/link @editorjs/checklist editorjs-undo`
- [x] T046 [US5] Vérifier qu'aucune référence à EditorJS ne subsiste dans le code source (grep "editorjs" et "EditorJS" dans tout le monorepo) et corriger les éventuels résidus
- [x] T047 [US5] Lancer `pnpm build` dans `usenghor_nuxt/` et confirmer que le build de production réussit sans erreur

**Checkpoint**: Le projet est entièrement nettoyé d'EditorJS.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Validation finale, déploiement en production

- [x] T048 Effectuer un backup complet de la base de données de production via `pg_dump` sur le conteneur `usenghor_db`
- [x] T049 Exécuter la migration SQL sur la base de production : `docker exec -i usenghor_db psql -U usenghor -d usenghor < migration.sql`
- [x] T050 Exécuter le script de conversion Python sur la base de production
- [x] T051 Déployer le nouveau code via `./deploy.sh update`
- [ ] T052 Valider manuellement un échantillon de pages publiques et admin en production (actualités, événements, programmes, projets, organisation)
- [x] T053 Mettre à jour `CLAUDE.md` pour refléter le changement d'éditeur (remplacer les références à EditorJS par TOAST UI Editor dans les sections Composants clés et Architecture Frontend)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Pas de dépendances — commencer immédiatement
- **Foundational (Phase 2)**: Dépend de Phase 1 — **BLOQUE** toutes les user stories
- **US1 (Phase 3)**: Dépend de Phase 2. Inclut les modifications backend (schémas Pydantic)
- **US2 (Phase 4)**: Dépend de Phase 2. Peut être fait en parallèle avec US1 (fichiers différents)
- **US3 (Phase 5)**: Dépend de Phase 2 + T004 (composant éditeur). Peut être fait en parallèle avec US1/US2
- **US4 (Phase 6)**: Dépend de Phase 3 (schémas backend modifiés). Nécessite aussi Phase 4 pour validation
- **US5 (Phase 7)**: Dépend de US1 + US2 + US3 + US4 validés. Dernière phase avant déploiement
- **Polish (Phase 8)**: Dépend de toutes les phases précédentes

### User Story Dependencies

- **US1 (P1)**: Après Phase 2 — Pas de dépendance sur d'autres stories
- **US2 (P1)**: Après Phase 2 — Peut être parallélisé avec US1 (fichiers publics vs admin)
- **US3 (P1)**: Après Phase 2 — Peut être parallélisé avec US1/US2 (CSS + composant wrapper)
- **US4 (P2)**: Après US1 — Nécessite les schémas backend modifiés
- **US5 (P3)**: Après US1 + US2 + US3 + US4 validés — Phase de nettoyage finale

### Parallel Opportunities

- T002 en parallèle avec T001
- T007, T008, T009, T010, T011 en parallèle (schémas Pydantic, fichiers différents)
- T012-T022 en parallèle (pages admin, fichiers différents)
- T023-T033 en parallèle (pages publiques, fichiers différents)
- T040-T044 en parallèle (suppression de fichiers)
- US1, US2, US3 en parallèle après Phase 2

---

## Parallel Example: User Story 1

```bash
# Lancer toutes les modifications de schémas Pydantic en parallèle :
Task T007: "Modifier schemas/content.py"
Task T008: "Modifier schemas/project.py"
Task T009: "Modifier schemas/academic.py"
Task T010: "Modifier schemas/organization.py"
Task T011: "Modifier schemas/application.py"

# Puis lancer toutes les pages admin en parallèle :
Task T012: "admin/contenus/actualites/nouveau.vue"
Task T013: "admin/contenus/actualites/[id]/edit.vue"
Task T014: "admin/contenus/evenements/nouveau.vue"
# ... (11 tâches parallèles)
```

---

## Implementation Strategy

### MVP First (User Story 1 uniquement)

1. Phase 1: Setup (T001-T002)
2. Phase 2: Foundational (T003-T005)
3. Phase 3: User Story 1 (T006-T022)
4. **STOP et VALIDER** : L'édition admin fonctionne de bout en bout
5. Continuer avec US2, US3, US4, US5

### Déploiement en production

1. Compléter US1 + US2 + US3 + US4 en local
2. Valider exhaustivement en local
3. US5 : Nettoyage EditorJS
4. Phase 8 : Backup → Migration SQL → Script conversion → Déploiement → Validation

---

## Notes

- Tâches [P] = fichiers différents, pas de dépendances
- Le composant éditeur est `.client.vue` (pas de SSR)
- Le RTL nécessite un workaround CSS (TOAST UI ne le supporte pas nativement)
- **RAPPEL** : TOAST UI Editor est abandonné. Envisager un pivot vers Tiptap si des problèmes bloquants apparaissent
- Committer après chaque tâche ou groupe logique
- Toujours faire un backup avant la migration en production
