# Tasks: Association Partenaires-Formations

**Input**: Design documents from `/specs/013-program-partners/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/

**Tests**: Non demandés - pas de tâches de test incluses.

**Organization**: Tasks groupées par user story pour permettre une implémentation et un test indépendants de chaque story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut s'exécuter en parallèle (fichiers différents, pas de dépendances)
- **[Story]**: User story concernée (US1, US2, US3)
- Chemins de fichiers exacts inclus dans les descriptions

---

## Phase 1: Foundational (Backend + i18n)

**Purpose**: Ajouter le schema public, le service enrichi, l'endpoint public et les clés i18n. Ces éléments sont requis par US1 (composable admin) et US2 (affichage public).

**CRITICAL**: Aucune user story ne peut être complétée sans cette phase.

- [X] T001 [P] Ajouter le schema `ProgramPartnerPublic` dans `usenghor_backend/app/schemas/academic.py` avec les champs : partner_external_id, name, logo_external_id, website, partner_type, partnership_type
- [X] T002 [P] Ajouter les clés i18n pour la section partenaires dans `usenghor_nuxt/i18n/locales/fr/`, `usenghor_nuxt/i18n/locales/en/`, `usenghor_nuxt/i18n/locales/ar/` (clés : programs.partners_title, programs.partners_empty, programs.add_partner, programs.remove_partner, programs.partnership_type, programs.select_partner, programs.partner_already_added, programs.no_logo)
- [X] T003 Ajouter la méthode `get_program_partners_enriched(program_id)` dans `usenghor_backend/app/services/academic_service.py` qui joint `program_partners` avec `partners` (filtre `active=true` pour le public) et retourne une liste de `ProgramPartnerPublic`
- [X] T004 Ajouter l'endpoint `GET /api/public/programs/{slug}/partners` dans `usenghor_backend/app/routers/public/programs.py` qui résout le slug en program_id puis appelle `get_program_partners_enriched`, retourne `list[ProgramPartnerPublic]`, 404 si slug invalide

**Checkpoint**: Backend prêt - les endpoints admin existants + le nouvel endpoint public fonctionnent. Les clés i18n sont en place.

---

## Phase 2: User Story 1 - Associer des partenaires à une formation existante (Priority: P1) MVP

**Goal**: Un administrateur peut rechercher, ajouter et retirer des partenaires depuis la page d'édition d'une formation.

**Independent Test**: Ouvrir une formation existante dans l'admin, ajouter un partenaire, sauvegarder, recharger la page et vérifier que le partenaire est toujours affiché.

### Implementation for User Story 1

- [X] T005 [US1] Ajouter les méthodes `listProgramPartners(programId)`, `addPartnerToProgram(programId, data)`, `removePartnerFromProgram(programId, partnerExternalId)` dans `usenghor_nuxt/app/composables/useProgramsApi.ts` en appelant les endpoints admin existants (`/api/admin/programs/{id}/partners`)
- [X] T006 [US1] Ajouter la section "Partenaires" dans `usenghor_nuxt/app/pages/admin/formations/programmes/[id]/edit.vue` avec : (1) état réactif pour la liste des partenaires associés, le chargement, et le partenaire sélectionné, (2) chargement des partenaires via `watch` sur `program` (comme skills/career), (3) chargement de tous les partenaires via `getAllPartners()` de `usePartnersApi`, (4) dropdown/select filtrable affichant les partenaires non encore associés avec recherche par nom, (5) bouton d'ajout qui appelle `addPartnerToProgram` puis recharge la liste, (6) liste des partenaires associés avec logo (via `/api/public/media/{logo_external_id}/download`), nom, type de partenariat optionnel, et bouton de suppression, (7) gestion des partenaires inactifs visibles avec badge d'avertissement, (8) gestion du doublon avec message d'avertissement, (9) style cohérent avec les sections skills/career (card blanche, titre avec compteur, états vide et chargement)

**Checkpoint**: US1 fonctionnelle - un admin peut gérer les partenaires d'une formation existante.

---

## Phase 3: User Story 2 - Afficher les partenaires sur la page publique (Priority: P1)

**Goal**: Les visiteurs voient les logos et noms des partenaires actifs sur la page publique d'une formation, avec liens vers leurs sites web.

**Independent Test**: Associer des partenaires à une formation (via admin ou directement en BDD), puis visiter la page publique de cette formation et vérifier l'affichage.

### Implementation for User Story 2

- [X] T007 [P] [US2] Ajouter la méthode `getProgramPartners(slug)` dans `usenghor_nuxt/app/composables/usePublicProgramsApi.ts` qui appelle `GET /api/public/programs/${slug}/partners` via `useApiBase()` + `$fetch()`
- [X] T008 [P] [US2] Créer le composant `usenghor_nuxt/app/components/formations/ProgramPartners.vue` qui : (1) reçoit en prop une liste de partenaires (ProgramPartnerPublic[]), (2) affiche une grille responsive (1 col mobile, 2 cols tablette, 3-4 cols desktop) de cartes partenaires, (3) chaque carte montre le logo (via NuxtImg ou img avec `/api/public/media/{logo_external_id}/download`) et le nom du partenaire, (4) placeholder visuel si pas de logo, (5) lien vers le site web du partenaire (target="_blank" rel="noopener") si renseigné, (6) titre de section traduit via i18n, (7) ne s'affiche pas si la liste est vide, (8) support dark mode et RTL (arabe), (9) style inspiré de `usenghor_nuxt/app/components/projet/ProjetPartenaires.vue`
- [X] T009 [US2] Intégrer le composant `ProgramPartners` dans `usenghor_nuxt/app/pages/formations/[type]/[slug].vue` : (1) importer et appeler `getProgramPartners(slug)` au chargement de la page, (2) placer le composant dans la colonne principale (lg:w-2/3) après la section "Débouchés professionnels" (career opportunities), (3) passer les partenaires en prop, (4) conditionner l'affichage à la présence de partenaires

**Checkpoint**: US2 fonctionnelle - les partenaires s'affichent sur la page publique des formations.

---

## Phase 4: User Story 3 - Associer des partenaires lors de la création (Priority: P2)

**Goal**: Un administrateur peut pré-sélectionner des partenaires lors de la création d'une nouvelle formation. Les associations sont créées après la sauvegarde du programme.

**Independent Test**: Créer une nouvelle formation avec des partenaires sélectionnés, puis vérifier dans la page d'édition que les partenaires sont bien associés.

**Dépendance**: Réutilise les méthodes composable de T005 (US1).

### Implementation for User Story 3

- [X] T010 [US3] Ajouter la section "Partenaires" dans `usenghor_nuxt/app/pages/admin/formations/programmes/nouveau.vue` avec : (1) même UI de sélection que la page d'édition (dropdown filtrable, liste des sélections), (2) stockage local des partenaires sélectionnés (pas d'appel API immédiat car le programme n'existe pas encore), (3) après la création réussie du programme (réponse avec ID), boucler sur les partenaires sélectionnés et appeler `addPartnerToProgram` pour chacun, (4) gestion d'erreur : si l'ajout d'un partenaire échoue, afficher un avertissement mais ne pas bloquer la redirection, (5) style identique à la page d'édition

**Checkpoint**: US3 fonctionnelle - les partenaires peuvent être associés dès la création d'une formation.

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Améliorations transversales et validation finale

- [X] T011 [P] Vérifier le rendu responsive (mobile, tablette, desktop) du composant ProgramPartners et de la section admin partenaires
- [X] T012 [P] Vérifier le support RTL (arabe) du composant ProgramPartners dans `usenghor_nuxt/app/components/formations/ProgramPartners.vue`
- [X] T013 [P] Vérifier le dark mode pour la section partenaires admin et le composant public
- [X] T014 Valider le parcours complet : créer une formation avec partenaires (US3), éditer pour modifier les partenaires (US1), consulter la page publique (US2)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 1)**: Pas de dépendance - peut démarrer immédiatement
- **US1 (Phase 2)**: Dépend de T001, T002, T003 (schema, i18n, service backend). T004 n'est pas requis pour US1 (qui utilise les endpoints admin existants)
- **US2 (Phase 3)**: Dépend de T001, T002, T003, T004 (a besoin de l'endpoint public)
- **US3 (Phase 4)**: Dépend de T005 (réutilise le composable admin de US1)
- **Polish (Phase 5)**: Dépend de toutes les user stories

### User Story Dependencies

- **US1 (P1)**: Peut démarrer dès que Phase 1 est complète. Indépendante des autres stories.
- **US2 (P1)**: Peut démarrer dès que Phase 1 est complète. Indépendante de US1 (utilise l'endpoint public, pas admin).
- **US3 (P2)**: Dépend de US1 (réutilise les méthodes composable et le pattern UI).

### Within Each User Story

- Composables avant pages (les pages dépendent des composables)
- Composants avant intégration dans les pages
- Core implementation avant edge cases

### Parallel Opportunities

- **Phase 1**: T001 et T002 en parallèle (fichiers différents). T003 après T001 (utilise le schema). T004 après T003 (utilise le service).
- **Phase 2 + Phase 3**: US1 et US2 peuvent démarrer en parallèle après Phase 1 (fichiers et endpoints différents).
- **Phase 3**: T007 et T008 en parallèle (composable et composant sont indépendants). T009 après T007 et T008.
- **Phase 5**: T011, T012, T013 en parallèle (vérifications indépendantes).

---

## Parallel Example: Phase 1

```bash
# Lancer T001 et T002 en parallèle :
Task: "Ajouter ProgramPartnerPublic schema dans usenghor_backend/app/schemas/academic.py"
Task: "Ajouter clés i18n dans usenghor_nuxt/i18n/locales/fr/, en/, ar/"

# Puis T003 (dépend de T001) :
Task: "Ajouter get_program_partners_enriched dans usenghor_backend/app/services/academic_service.py"

# Puis T004 (dépend de T003) :
Task: "Ajouter endpoint public dans usenghor_backend/app/routers/public/programs.py"
```

## Parallel Example: US1 + US2 simultanées

```bash
# Après Phase 1, lancer US1 et US2 en parallèle :

# US1 :
Task: "Ajouter méthodes partner dans usenghor_nuxt/app/composables/useProgramsApi.ts"
# Puis :
Task: "Section partenaires dans usenghor_nuxt/app/pages/admin/formations/programmes/[id]/edit.vue"

# US2 (en parallèle de US1) :
Task: "Ajouter getProgramPartners dans usenghor_nuxt/app/composables/usePublicProgramsApi.ts"
Task: "Créer ProgramPartners.vue dans usenghor_nuxt/app/components/formations/"
# Puis :
Task: "Intégrer ProgramPartners dans usenghor_nuxt/app/pages/formations/[type]/[slug].vue"
```

---

## Implementation Strategy

### MVP First (US1 + US2)

1. Compléter Phase 1: Foundational (T001-T004)
2. Compléter Phase 2: US1 - Admin edit (T005-T006)
3. Compléter Phase 3: US2 - Affichage public (T007-T009)
4. **STOP and VALIDATE**: Tester le parcours admin → public
5. Déployer si prêt

### Incremental Delivery

1. Phase 1 → Backend prêt
2. Phase 2 (US1) → Admin peut gérer les partenaires → Valider
3. Phase 3 (US2) → Visiteurs voient les partenaires → Valider
4. Phase 4 (US3) → Création complète avec partenaires → Valider
5. Phase 5 → Polish responsive/RTL/dark mode

---

## Notes

- Aucune migration BDD requise (table `program_partners` et endpoints admin existent déjà)
- Le composable `usePartnersApi` (existant) fournit `getAllPartners()` pour la liste de sélection dans l'admin
- Les logos partenaires sont résolus via `/api/public/media/{logo_external_id}/download`
- Le composant `ProjetPartenaires.vue` (existant) sert de référence visuelle pour le composant public
- 14 tâches au total, réparties en 5 phases
