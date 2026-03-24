# Tasks: Ajouter le type de formation CLOM

**Input**: Design documents from `/specs/011-add-cloms-formation/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Non demandés — pas de tâches de tests automatisés.

**Organization**: Tâches groupées par user story pour permettre l'implémentation et le test indépendants de chaque story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut s'exécuter en parallèle (fichiers différents, pas de dépendances)
- **[Story]**: User story associée (US1, US2, US3, US4)
- Chemins exacts inclus dans les descriptions

---

## Phase 1: Foundational (Prérequis bloquants)

**Purpose**: Migration DB + mise à jour des types ENUM sur toutes les couches. DOIT être complété avant toute user story.

**⚠️ CRITICAL**: Aucune tâche de user story ne peut commencer avant la fin de cette phase.

- [ ] T001 Créer la migration SQL `029_add_clom_program_type.sql` avec `ALTER TYPE program_type ADD VALUE 'clom'` dans `usenghor_backend/documentation/modele_de_données/migrations/029_add_clom_program_type.sql`
- [ ] T002 Mettre à jour la définition ENUM dans le schéma source : ajouter `'clom'` à `CREATE TYPE program_type` dans `usenghor_backend/documentation/modele_de_données/services/07_academic.sql`
- [ ] T003 Exécuter la migration localement : `docker exec -i usenghor_postgres psql -U usenghor -d usenghor < usenghor_backend/documentation/modele_de_données/migrations/029_add_clom_program_type.sql`
- [ ] T004 [P] Ajouter `CLOM = "clom"` à l'enum Python `ProgramType` dans `usenghor_backend/app/models/academic.py`
- [ ] T005 [P] Ajouter `| 'clom'` au type TypeScript `ProgramType` dans `usenghor_nuxt/app/types/api/programs.ts`

**Checkpoint**: La valeur `clom` est reconnue par la DB, le backend et le frontend. Les schemas Pydantic, routes et services se propagent automatiquement.

---

## Phase 2: User Story 1 - Consultation publique des CLOMs (Priority: P1) 🎯 MVP

**Goal**: Les visiteurs peuvent accéder à `/formations/cloms` et consulter la liste des CLOMs publiés avec filtres.

**Independent Test**: Naviguer vers `http://localhost:3000/formations/cloms` → la page s'affiche (vide si aucun CLOM publié, avec message approprié).

### Implementation for User Story 1

- [ ] T006 [US1] Ajouter le mapping slug→type `'cloms': 'clom'` et type→slug `'clom': 'cloms'` dans les objets `urlSlugToProgramType` et `programTypeToUrlSlug` de `usenghor_nuxt/app/composables/usePublicProgramsApi.ts`
- [ ] T007 [US1] Ajouter le label public `clom: 'CLOM'` dans `publicProgramTypeLabels` de `usenghor_nuxt/app/composables/usePublicProgramsApi.ts`
- [ ] T008 [US1] Ajouter la configuration couleur/icône pour `clom` (icon: `fa-solid fa-globe`, color: teal) dans `publicProgramTypeColors` de `usenghor_nuxt/app/composables/usePublicProgramsApi.ts`
- [ ] T009 [US1] Ajouter `'cloms'` au tableau `validTypes` dans `usenghor_nuxt/app/pages/formations/[type]/index.vue`

**Checkpoint**: La page `/formations/cloms` est accessible et fonctionnelle. Le filtrage par type CLOM fonctionne sur l'API publique.

---

## Phase 3: User Story 2 - Création et gestion admin (Priority: P1)

**Goal**: Les administrateurs peuvent créer, modifier et publier des formations de type CLOM via le back-office.

**Independent Test**: Se connecter à l'admin, créer un programme avec type « CLOM », vérifier qu'il apparaît dans la liste admin et sur `/formations/cloms`.

### Implementation for User Story 2

- [ ] T010 [US2] Ajouter le label admin `clom: 'CLOM'` dans `programTypeLabels` de `usenghor_nuxt/app/composables/useProgramsApi.ts`
- [ ] T011 [US2] Ajouter la classe CSS couleur `clom: 'bg-teal-100 text-teal-800 dark:bg-teal-900/30 dark:text-teal-400'` dans `programTypeColors` de `usenghor_nuxt/app/composables/useProgramsApi.ts`

**Checkpoint**: Le type CLOM apparaît dans le sélecteur de type du formulaire admin. Un CLOM peut être créé et géré.

---

## Phase 4: User Story 3+4 - Navigation, identité visuelle et support trilingue (Priority: P2)

**Goal**: Le type CLOM est visuellement distinct et traduit dans les trois langues (FR, EN, AR avec RTL).

**Independent Test**: Basculer la langue du site en EN puis AR et vérifier que les libellés CLOM/MOOC s'affichent correctement.

### Implementation for User Stories 3 & 4

- [ ] T012 [P] [US4] Ajouter les traductions françaises du type CLOM (clom, cloms, typeDescriptions.cloms) dans `usenghor_nuxt/i18n/locales/fr/formations.json`
- [ ] T013 [P] [US4] Ajouter les traductions anglaises du type CLOM (clom→MOOC, cloms→MOOCs, typeDescriptions.cloms) dans `usenghor_nuxt/i18n/locales/en/formations.json`
- [ ] T014 [P] [US4] Ajouter les traductions arabes du type CLOM (clom→مقرر مفتوح عبر الإنترنت, cloms→مقررات مفتوحة عبر الإنترنت) dans `usenghor_nuxt/i18n/locales/ar/formations.json`

**Checkpoint**: Le type CLOM est traduit dans les trois langues. La navigation et les filtres affichent le libellé correct dans chaque langue.

---

## Phase 5: Polish & Validation

**Purpose**: Vérification finale de bout en bout.

- [ ] T015 Exécuter la validation quickstart.md : vérifier API (`curl /api/public/programs/by-type/clom`), Swagger, création admin, page publique `/formations/cloms`, et bascule i18n
- [ ] T016 Vérifier que le schéma source `07_academic.sql` et la migration `029_add_clom_program_type.sql` sont cohérents

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 1)** : Pas de dépendance — commence immédiatement. BLOQUE toutes les user stories.
- **US1 (Phase 2)** : Dépend de la Phase 1 complète.
- **US2 (Phase 3)** : Dépend de la Phase 1 complète. Peut s'exécuter en parallèle avec US1.
- **US3+US4 (Phase 4)** : Dépend de la Phase 1 complète. Peut s'exécuter en parallèle avec US1 et US2.
- **Polish (Phase 5)** : Dépend de toutes les phases précédentes.

### User Story Dependencies

- **US1 (P1)** : Indépendant après Phase 1
- **US2 (P1)** : Indépendant après Phase 1 — pas de dépendance sur US1
- **US3+US4 (P2)** : Indépendant après Phase 1 — pas de dépendance sur US1/US2

### Within Each User Story

- Composable changes avant page routing (US1: T006-T008 avant T009)
- Labels avant colors (US2: T010 avant T011)
- Toutes les traductions i18n sont parallélisables (US4: T012, T013, T014 en parallèle)

### Parallel Opportunities

- T004 et T005 en parallèle (backend Python + frontend TypeScript)
- US1, US2, US3+US4 peuvent démarrer en parallèle après Phase 1
- T012, T013, T014 en parallèle (fichiers i18n distincts)

---

## Parallel Example: Phase 1 (Foundational)

```bash
# Séquentiel : DB d'abord
Task T001: "Créer migration 029_add_clom_program_type.sql"
Task T002: "Mettre à jour 07_academic.sql"
Task T003: "Exécuter migration localement"

# Parallèle : backend + frontend simultanément
Task T004: "Ajouter CLOM à ProgramType Python"
Task T005: "Ajouter 'clom' à ProgramType TypeScript"
```

## Parallel Example: User Stories (après Phase 1)

```bash
# US1, US2, US3+US4 peuvent démarrer en parallèle :
# Agent 1 : US1 (composable public + page)
Task T006-T009

# Agent 2 : US2 (composable admin)
Task T010-T011

# Agent 3 : US3+US4 (i18n trilingue)
Task T012-T014
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Compléter Phase 1 : Foundational (T001-T005)
2. Compléter Phase 2 : US1 (T006-T009)
3. **STOP and VALIDATE** : Tester `/formations/cloms` indépendamment
4. Déployer si prêt

### Incremental Delivery

1. Phase 1 → Foundation prête (DB + enums)
2. + US1 → Page publique `/formations/cloms` fonctionnelle (MVP!)
3. + US2 → Admin peut créer/gérer des CLOMs
4. + US3+US4 → Traductions trilingues complètes
5. Phase 5 → Validation finale

---

## Notes

- 16 tâches au total, dont 5 parallélisables
- Aucun nouveau fichier source — uniquement modifications de fichiers existants + 1 migration SQL
- Les schemas Pydantic, routes backend et pages admin se propagent automatiquement
- Commiter après chaque phase ou groupe logique de tâches
