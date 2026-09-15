---

description: "Tâches d'implémentation — rattachement du PEI à l'organigramme, navigation et mise en ligne du mini-site (026)"
---

# Tasks: Rattachement du PEI à l'organigramme, navigation et mise en ligne du mini-site

**Input**: Design documents from `/specs/026-pei-org-navigation-launch/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md)

**Tests**: tests pytest dans un fichier unique `usenghor_backend/tests/integration/test_services_hierarchy.py` (research R15) : régression de perte de données C1, règles de hiérarchie, imbrication publique, duplication, codes courts. Le trigger SQL est testé en SQL (quickstart § 2). Le frontend n'a pas d'infrastructure de test : validation par les blocs du quickstart, `pnpm build` et captures avant / après.

**Organization** :

| Story | Contenu | Priorité |
|---|---|---|
| US1 | Organigramme et fiches publiques | P1 |
| US2 | Backoffice et règles de hiérarchie | P1 |
| US3 | Menu, pied de page, lien court | P2 |
| US4 | Fil d'Ariane du mini-site | P2 |
| US5 | Plan du site | P3 |
| US6 | Mise en ligne | P1, en dernier |

Après les phases 1–2 (dont la migration 050), US1 à US5 sont indépendantes. US6 vient après tout le reste.

## Format: `[ID] [P?] [Story] Description`

- **[P]** : parallélisable (fichiers différents, aucune dépendance sur une tâche inachevée)
- **[Story]** : US1…US6 (phases de user story uniquement)

## Path Conventions

- **Backend** : `usenghor_backend/app/{models,schemas,services,routers}`, `usenghor_backend/tests/integration/`.
- **SQL** : `usenghor_backend/documentation/modele_de_données/{services,migrations}/`.
- **Frontend** : `usenghor_nuxt/app/{pages,components,composables,types}`, `usenghor_nuxt/server/`, `usenghor_nuxt/i18n/locales/{fr,en,ar}/`.
- **Conventions transverses** :
  - français accentué dans le code, les messages et les NOTICE ;
  - noms de fichiers `[a-z0-9_-]` ;
  - classes `dark:` et propriétés logiques (`ms-`, `ps-`, `border-s`, `rtl:`) ;
  - aucun texte visible en dur (i18n) ;
  - aucun appel `/api/admin/*` depuis une page publique ;
  - `useSeoMeta` après la résolution de la route et des `useAsyncData`.
- **Environnement de développement** : pas de `pnpm lint` (mémoire projet). Dev sur un autre port que 3000 avec `NUXT_INTERNAL_API_BASE=http://localhost:8000`, heap 8 Go.

---

## Phase 1: Setup (porte d'accord, inventaire, références)

**Purpose**: accord sur le SQL, vérification de réutilisation et captures de référence avant tout code.

- [X] T001 Présenter au responsable le SQL de `specs/026-pei-org-navigation-launch/data-model.md` : § 3 (schéma de référence), § 4 (migration 050), § 5 (rollback), § 6 (test à blanc). — **Fait (2026-09-15)** : accord du responsable, points 1, 3, 4, 5 tels que proposés ; icône **`fa-solid fa-rocket`** (data-model § 7).
  - Faire trancher les 5 points du § 7 :
    1. libellés anglais et arabe du pôle (« Entrepreneurship and Innovation Hub », « قطب ريادة الأعمال والابتكار ») et de l'entrée de menu / du pied de page (« Entrepreneurship at Senghor », « ريادة الأعمال في سنغور ») ;
    2. icône `fa-solid fa-lightbulb` ;
    3. trigger `services_check_hierarchy` en plus de la validation backend ;
    4. rollback qui conserve le pôle s'il a du contenu ;
    5. normalisation du JSON du menu.
  - **Attendre l'accord explicite** avant T008–T011.
  - Reporter les ajustements dans `data-model.md` § 4–5, `contracts/frontend.md` § 3 (i18n) et le fichier SQL temporaire.
- [X] T002 [P] Vérifier par sous-agent dans `usenghor_nuxt/app/**` et `usenghor_nuxt/server/**` :
  - (a) aucun export nommé `getServiceLink`, `usePeiBreadcrumb`, `navChildLabel`, `slugifyServiceName`, `orderHierarchically`, `ServiceRelativePublic`, `ServicePublicWithChildren` (gotcha des collisions d'auto-import) ;
  - (b) aucun composant de carte de service réutilisable (inventaire du 2026-09-15 : cartes inline dans `OrganigrammeSection.vue` et `[type]/[slug].vue`).

  Consigner le résultat à la fin de R9 dans `specs/026-pei-org-navigation-launch/research.md`, et renommer en cas de collision.
- [X] T003 [P] Capturer les références avant tout changement (quickstart § 0 ; backend `:8000`, frontend `pnpm dev --port 3001`) : — **Fait** : JSON gardés ; captures avant prises sur une copie de travail du frontend à `HEAD` après le début du code (même backend), comparées par DOM normalisé (quickstart § 0).
  - **Captures** en 1440 px et 390 px, clair, FR et AR : `/a-propos/organisation` ; `/a-propos/organisation/secteur/sec-tes` ; une fiche service sans pôle ; `/entrepreneuriat` ; `/entrepreneuriat/activites` ; menu « Plus » ouvert ; pied de page ; une fiche formation, une fiche projet et une fiche appel (reprise de T039 de la 023).
  - **JSON** dans le scratchpad :
    - `curl -s localhost:8000/api/public/sectors/with-services | jq -S . > with-services-avant.json` ;
    - `curl -s localhost:8000/api/public/services | jq -S . > services-avant.json` ;
    - `curl -s localhost:3001/sitemap.xml > sitemap-avant.xml` ;
    - JSON-LD `BreadcrumbList` de `/entrepreneuriat/activites`.

---

## Phase 2: Foundational (prérequis bloquants)

**Purpose**: correctif de perte de données, structure SQL, migration 050, modèle, schémas et types partagés par toutes les stories.

**⚠️ CRITICAL**: T004–T005 sont indépendantes du SQL et à faire en premier. T008–T011 attendent l'accord T001. Aucune story avant T012–T015.

- [X] T004 Créer `usenghor_backend/tests/integration/test_services_hierarchy.py` :
  - **En-tête** : docstring renvoyant à `specs/026-pei-org-navigation-launch/contracts/api.md`.
  - **Fixture `organization_permissions`** : `organization.view` « Voir l'organisation » et `organization.edit` « Modifier l'organisation » attribués à `admin_role`, sur le modèle de `faq_permissions` dans `tests/integration/test_admin_faq_categories_api.py`.
  - **Fixture `org_tree`** : secteurs actifs `SEC-A` et `SEC-B` ; dans `SEC-A`, services actifs `DDE` (`display_order` 2) et `DRE` (`display_order` 3), plus un service **inactif** `OLD`.
  - **Test de régression C1** `test_public_sector_reads_do_not_delete_inactive_services` : `GET /api/public/sectors/with-services` puis `GET /api/public/sectors/SEC-A` → 200. Faire `await db_session.commit()`, puis vérifier par `select(Service).where(Service.id == OLD.id)` que `OLD` existe toujours et que `OLD` est absent des deux réponses.
  - **Vérifier que ce test échoue** sur le code actuel (`pytest … -k inactive` avant T005) et consigner l'échec.
- [X] T005 Corriger la perte de données C1 (research R3, spec FR-008b) sans réaffecter aucune collection ORM : — **Fait** : `build_public_sector` construit la réponse ; imbrication `children` ajoutée dans la foulée (T017), `diff` JSON identique hors nouveaux champs.
  - dans `usenghor_backend/app/services/organization_service.py`, remplacer `get_active_sectors_with_active_services` (l.424-437) par une construction de réponse qui ne modifie pas `sector.services` ;
  - dans `usenghor_backend/app/routers/public/sectors.py`, supprimer la ligne `sector.services = [s for s in sector.services if s.active]` (l.49) de `get_sector_by_code` et construire la réponse de la même façon, via une fonction de service partagée `build_public_sector(sector)` ;
  - à ce stade, garder la forme actuelle : services actifs à plat triés par `(display_order, name)` ;
  - relancer `pytest tests/integration/test_services_hierarchy.py -k inactive -v` → passe ;
  - `diff` du JSON `with-services` avec `with-services-avant.json` → identique.
- [X] T006 [P] Ajouter `parent_id` et `landing_path` au modèle `Service` dans `usenghor_backend/app/models/organization.py` (après `album_external_id`) :
  - `parent_id: Mapped[str | None] = mapped_column(UUID(as_uuid=False), ForeignKey("services.id", ondelete="SET NULL"), nullable=True)` ;
  - `landing_path: Mapped[str | None] = mapped_column(String(255), nullable=True)` ;
  - **aucune relation ORM** `parent` / `children` (data-model § 2).
- [X] T007 [P] Étendre `usenghor_backend/app/schemas/organization.py` selon `contracts/api.md` § 1 :
  - **Constante** `LANDING_PATH_RE = r"^/(?!/)(?!(?:en|ar)(?:/|$))(?!r/)[^\s?#]*$"`.
  - **`ServiceBase`** : `parent_id: str | None = None`, `landing_path: str | None = Field(None, max_length=255)`.
  - **`field_validator("landing_path", mode="before")`** : `strip()` ; `""` → `None` ; hors regex → `ValueError("La page dédiée doit être un chemin interne du site commençant par / (ex. /entrepreneuriat), sans préfixe de langue")`.
  - **`ServiceUpdate`** : mêmes champs et même validateur (en validateur partagé).
  - **`ServicePublic`** : `parent_id: str | None = None`, `landing_path: str | None = None`.
  - **Nouveau `ServiceRelativePublic`** (`from_attributes`) : `id`, `name`, `name_en`, `name_ar`, `sigle`, `color`, `landing_path`, `display_order`.
  - **Nouveau `ServicePublicWithChildren(ServicePublic)`** : `children: list[ServicePublic] = []`.
  - **`SectorPublicWithServices.services`** : `list[ServicePublicWithChildren]`.
- [X] T008 Mettre à jour `usenghor_backend/documentation/modele_de_données/services/04_organization.sql` **après l'accord T001**, en recopiant data-model § 3 :
  - dans `CREATE TABLE services`, après `album_external_id` : `parent_id UUID REFERENCES services(id) ON DELETE SET NULL`, `landing_path VARCHAR(255)`, avec leurs commentaires ;
  - après `idx_services_sector` : `services_parent_not_self`, `services_landing_path_format`, `idx_services_parent`, fonction `services_check_hierarchy()` et trigger `services_check_hierarchy` (corps identique à la migration).
- [X] T009 Créer `usenghor_backend/documentation/modele_de_données/migrations/050_services_parent_landing.sql` **après l'accord T001**, par copie exacte du SQL validé de data-model § 4 : en-tête, `BEGIN`, puis les étapes 1 à 4, `COMMIT`, `\echo`. Détail des étapes :
  1. **Structure** : colonnes, `services_parent_id_fkey`, `services_parent_not_self`, `services_landing_path_format`, index partiel, fonction et trigger.
  2. **Pôle** :
     - identifiant fixe `5e1c0050-0000-4000-8000-00000000e1ab` ;
     - DDE résolue par la clé `entrepreneurship.dde_service_id`, sinon par l'unique `name ILIKE '%veloppement et de l_entrepreneuriat%'` ;
     - reconnaissance d'un pôle existant par identifiant, `landing_path = '/entrepreneuriat'`, `sigle ILIKE 'PEI'` ou nom ;
     - si le pôle existe, compléter sans rien écraser ;
     - NOTICE en français.
  3. **Menu** : ajout non destructif en fin de `navbar.secondary.about.children`, avec `id` `entrepreneurship`, `label`, `label_en`, `label_ar`, `route` `/entrepreneuriat`, `icon`, `sort_order` = max + 1 ; liste absente ou vide → création ; valeur illisible ou non tableau → NOTICE sans écriture.
  4. **Lien court** : `pei` → `/entrepreneuriat`, `created_by NULL`, `ON CONFLICT (code) DO NOTHING`.
- [X] T010 [P] Créer `usenghor_backend/documentation/modele_de_données/migrations/050_services_parent_landing_rollback.sql` **après l'accord T001**, par copie exacte de data-model § 5, avec en en-tête « à jouer AVANT les rollbacks 049 → 045 ». Il retire, dans l'ordre :
  - le lien `pei` vers `/entrepreneuriat` ;
  - l'entrée de menu `id = 'entrepreneurship'` ;
  - le pôle d'identifiant fixe, s'il n'a pas de contenu dans `service_team`, `service_objectives`, `service_achievements`, `service_projects` ou `service_media_library` (sinon NOTICE et conservation) ;
  - le trigger, la fonction, l'index, les contraintes et les colonnes.
- [X] T011 Jouer quickstart § 1–2 en local :
  - créer la DDE de test (`aaaaaaaa-0000-4000-8000-0000000000dd`, secteur `SEC-TES`, nom avec apostrophe typographique ’) ;
  - migration 050 ×2 : NOTICE attendues, comptes `pei | poles | menu | lien` identiques ;
  - § 2 : les 6 refus du trigger et le rattachement valide, en `BEGIN … ROLLBACK` ;
  - rollback ×2, puis rejeu de la migration.

  Consigner le résultat sous le § 1 de `specs/026-pei-org-navigation-launch/quickstart.md`.
- [X] T012 [P] Étendre les types admin : — Mappage : `transformToDisplay` / `transformWithDetailsToDisplay` recopient déjà tous les champs (spread) ; `transformMockToDisplay` complété.
  - `usenghor_nuxt/app/types/api/organization.ts` (`ServiceRead`) ;
  - `usenghor_nuxt/app/composables/useServicesApi.ts` (`ServiceWithDetails`, `ServiceCreate`, `ServiceUpdate`, `ServiceDisplay`) : `parent_id?: string | null`, `landing_path?: string | null` ;
  - recopier ces deux champs dans le mappage de `getAllServices` → `ServiceDisplay`.
- [X] T013 [P] Étendre `usenghor_nuxt/app/composables/usePublicOrganizationApi.ts` selon `contracts/frontend.md` § 1 : — `getServiceUrl` accepte désormais `Pick<ServicePublic, 'name'>` (élargissement de type, même comportement).
  - `ServicePublic` : `parent_id: string | null`, `landing_path: string | null` ;
  - nouveaux `ServiceRelativePublic`, `ServicePublicWithChildren` (`children: ServicePublic[]`) ;
  - `SectorPublicWithServices.services: ServicePublicWithChildren[]` ;
  - `ServicePublicWithDetails` : `parent?: ServiceRelativePublic | null`, `children?: ServiceRelativePublic[]` ;
  - nouvelle fonction retournée `getServiceLink(service: Pick<ServicePublic, 'name' | 'landing_path'>): string` = `service.landing_path || getServiceUrl(service)` (non localisée) ;
  - `findServiceBySlug` et `getServiceUrl` inchangés.
- [X] T014 Vérifier que le backend démarre et que le JSON public est additif :
  - `uvicorn app.main:app --reload` sans erreur ;
  - `curl -s localhost:8000/api/public/services | jq -S .` comparé à `services-avant.json` : seuls `parent_id` et `landing_path` sont ajoutés, et le pôle PEI apparaît dans la liste.
- [X] T015 [P] Ajouter à `organization_service.py` le helper `_is_uuid` (ou réutiliser celui de `entrepreneurship_service.py`, s'il est importable sans cycle) et la méthode `get_children_counts(service_ids) -> dict[str, int]`, qui renvoie le nombre de pôles par parent en une seule requête. T018 et T026 s'en servent. — `_is_uuid` local (pas d'import croisé).

**Checkpoint** : correctif C1 livré, colonnes et pôle en base locale, schémas et types prêts. Les stories peuvent commencer.

---

## Phase 3: User Story 1 - Découvrir le pôle depuis l'organigramme et la fiche DDE (Priority: P1) 🎯 MVP

**Goal** : le PEI apparaît sous la DDE dans l'organigramme, avec une carte qui mène au mini-site ; la fiche DDE a un bloc « Pôles » ; la fiche du pôle renvoie à son parent ; les services sans pôle ne changent pas.

**Independent Test** : quickstart § 5, organigramme et fiches en FR / EN / AR, 1440 et 390 px, clair et sombre, captures avant / après.

- [X] T016 [US1] Ajouter les tests publics à `usenghor_backend/tests/integration/test_services_hierarchy.py`. Données : `POLE` actif, `parent_id = DDE`, `landing_path = '/entrepreneuriat'`.
  - `with-services` :
    - `SEC-A.services` ne contient que `DDE` et `DRE`, dans cet ordre ;
    - `DDE.children == [POLE]` ;
    - `DRE.children == []` ;
    - aucun pôle au niveau du secteur.
  - DDE rendue inactive → `POLE` absent partout, et DDE toujours en base.
  - `GET /api/public/sectors/SEC-A` → même imbrication.
  - `GET /api/public/services` → contient `POLE`, avec `parent_id` et `landing_path`.
  - `GET /api/public/services/{POLE}` → `parent.id == DDE`, `children == []`.
  - `GET /api/public/services/{DDE}` → `parent is None`, `children[0].landing_path == '/entrepreneuriat'`.
  - Parent inactif → `GET /api/public/services/{POLE}` renvoie `parent is None`.
- [X] T017 [US1] Implémenter l'imbrication dans `build_public_sector(sector)` de `usenghor_backend/app/services/organization_service.py` (research R3, `contracts/api.md` § 3.1) :
  - `tops` = services actifs avec `parent_id is None`, triés par `(display_order, name)` ;
  - `children` de chaque top = services actifs du secteur avec `parent_id == top.id`, même tri ;
  - retourner `SectorPublicWithServices`, avec des `services` de type `ServicePublicWithChildren` ;
  - un pôle dont le parent est inactif ou hors secteur n'apparaît pas ;
  - utilisé par `/with-services` et `/{code}`.
- [X] T018 [US1] Exposer `parent` et `children` sur la fiche publique :
  - dans `usenghor_backend/app/routers/public/services.py`, `ServicePublicWithDetailsEnriched` reçoit `parent: ServiceRelativePublic | None = None` et `children: list[ServiceRelativePublic] = []` ;
  - dans `get_service_with_details` (`organization_service.py:717`), ou dans une nouvelle méthode `get_service_relatives(service)` : parent chargé seulement s'il est **actif**, enfants actifs triés par `(display_order, name)` ;
  - la construction champ par champ du routeur (l.137-164) remplit les deux champs ;
  - lancer `pytest tests/integration/test_services_hierarchy.py -v` → US1 et C1 passent.
- [X] T019 [P] [US1] Ajouter les clés i18n françaises :
  - dans `usenghor_nuxt/i18n/locales/fr/organization-detail.json` : `organizationDetail.poles.title` « Pôles », `organizationDetail.poles.parentOf` « Pôle de », `organizationDetail.poles.dedicatedPage` « Voir la page dédiée », `organizationDetail.poles.count` « + {n} pôle | + {n} pôles » ;
  - dans `usenghor_nuxt/i18n/locales/fr/organization.json` : `organization.poles.of` « Pôles de {name} ».
- [X] T020 [P] [US1] Ajouter les mêmes clés en anglais dans `usenghor_nuxt/i18n/locales/en/organization-detail.json` et `usenghor_nuxt/i18n/locales/en/organization.json` : « Hubs », « Hub of », « Visit the dedicated page », « + {n} hub | + {n} hubs », « Hubs of {name} ».
- [X] T021 [P] [US1] Ajouter les mêmes clés en arabe dans `usenghor_nuxt/i18n/locales/ar/organization-detail.json` et `usenghor_nuxt/i18n/locales/ar/organization.json` : « الأقطاب », « قطب تابع لـ », « زيارة الصفحة المخصصة », « + {n} قطب | + {n} أقطاب », « أقطاب {name} ».
- [X] T022 [US1] Afficher les pôles dans `usenghor_nuxt/app/components/organization/OrganigrammeSection.vue` (`contracts/frontend.md` § 3, research R9) : — Carte factorisée par `createReusableTemplate({ inheritAttrs: false })` (DOM identique vérifié).
  - **Sans enfants** : dans la boucle de la grille (l.232-278), un service sans `children?.length` garde **exactement** le nœud `NuxtLink data-card` actuel. Seule sa destination change, et seulement s'il a `landing_path` : `localePath(getServiceLink(service))`.
  - **Avec enfants** : il est rendu dans `<div class="flex flex-col gap-2">`, avec la même carte, puis `<ul class="ms-4 ps-3 border-s-2 space-y-2" :aria-label="t('organization.poles.of', { name })">`. La bordure prend la couleur du parent (`service.color`) ou la palette du secteur.
  - **Carte compacte de pôle** (`NuxtLink :to="localePath(getServiceLink(pole))"`) : pastille du sigle, sinon `fa-building` ; nom `localized(pole, 'name')` ; flèche `fa-arrow-right` avec `rtl:-scale-x-100` ; variantes `dark:bg-gray-800` / `dark:text-*`.
  - Importer `getServiceLink` depuis `usePublicOrganizationApi`, sans redéfinir de helper local homonyme.
- [X] T023 [US1] Dans `usenghor_nuxt/app/pages/a-propos/organisation/[type]/[slug].vue`, onglet Présentation d'un service : insérer entre la carte de description (l.519-523) et le bouton « onglet suivant » (l.531) :
  - (1) si `entity.parent` : lien `t('organizationDetail.poles.parentOf')` + `parent.sigle || localized(parent, 'name')` → `localePath(getServiceUrl(entity.parent))`, avec une flèche en miroir RTL ;
  - (2) si `entity.landing_path` : bouton `t('organizationDetail.poles.dedicatedPage')` → `localePath(entity.landing_path)` ;
  - (3) si `entity.children?.length` : `<section aria-labelledby="poles-title">` avec `<h3 id="poles-title">` `t('organizationDetail.poles.title')` et une grille `grid sm:grid-cols-2 gap-4` de cartes au style de l'organigramme → `localePath(getServiceLink(child))`.

  Sans parent, page dédiée ni enfant, aucun nœud ni aucune marge ne sont ajoutés. Dans l'onglet Services d'une fiche **secteur** (l.690-731), sous un service avec `children.length`, ajouter la ligne `t('organizationDetail.poles.count', { n }, n)` liée à la fiche du parent.
- [X] T024 [US1] Dérouler quickstart § 5 (étapes 1 à 6) en local :
  - organigramme en FR / EN / AR, 1440 / 390 px, clair / sombre, RTL ;
  - désactivation de la DDE → pôle masqué, et DDE toujours en base après plusieurs rechargements ;
  - fiche DDE (bloc « Pôles ») et fiche PEI (liens) ;
  - onglet Services du secteur ;
  - captures après, comparées à T003 pour les services sans pôle : aucune différence.

  Consigner le résultat dans `specs/026-pei-org-navigation-launch/quickstart.md` § 5.

**Checkpoint** : US1 livrable seule. Le pôle est visible et cliquable, sans régression.

---

## Phase 4: User Story 2 - Structurer un pôle dans le backoffice sans pouvoir casser la hiérarchie (Priority: P1)

**Goal** : le backoffice propose « Service parent » et « Page dédiée », affiche la hiérarchie et refuse cycles, second niveau et incohérences de secteur, par l'interface comme par appel direct ; l'audit contient les nouveaux champs.

**Independent Test** : quickstart § 4 (étapes 1 à 8) et appels `curl` directs.

- [X] T025 [US2] Ajouter les tests admin à `usenghor_backend/tests/integration/test_services_hierarchy.py`, avec `authenticated_client` et `organization_permissions`. Refus attendus (**rien d'enregistré**, vérifié en base) :

  | Requête | Code | `detail` |
  |---|---|---|
  | `POST /api/admin/services` avec `parent_id` inexistant | 422 | « Service parent introuvable » |
  | `PUT /{DDE}` avec `parent_id = DDE` | 422 | « Un service ne peut pas être son propre parent » |
  | `PUT /{DRE}` avec `parent_id = POLE` | 409 | « Le service parent est lui-même un pôle : un seul niveau est autorisé » |
  | `PUT /{DDE}` avec `parent_id = DRE` alors que DDE a un pôle | 409 | « Ce service a 1 pôle(s) : il ne peut pas être rattaché » |
  | `PUT /{X de SEC-B}` avec `parent_id = DDE` | 409 | « Le service parent doit appartenir au même secteur » |
  | `PUT /{DDE}` avec `sector_id = SEC-B` | 409 | « Déplacez ou détachez d'abord ses 1 pôle(s) » |
  | `landing_path` `'en/x'`, `'//x'`, `'/en/x'`, `'/ar'`, `'/r/pei'`, `'/a b'`, `'/x?y'` | 422 | — |

  Cas acceptés :
  - `landing_path: "  "` → enregistré `NULL` ;
  - rattachement valide de DRE à DDE → 200, `parent_id` renvoyé ;
  - `parent_id: null` explicite → détache ;
  - `POST /{POLE}/duplicate?new_name=Copie` → copie avec `parent_id = DDE` et `landing_path is None` ;
  - `DELETE /{DDE}` → 200 et `POLE.parent_id is None` (la FK `ondelete="SET NULL"` déclarée sur le modèle en T006 est créée par `create_all`).
- [X] T026 [US2] Implémenter `async def _validate_hierarchy(self, service_id: str | None, sector_id: str | None, parent_id: str | None, sector_changed: bool) -> None` dans `usenghor_backend/app/services/organization_service.py` (table de `contracts/api.md` § 2) :
  - `ValidationException` (422) pour un parent introuvable, un UUID invalide ou l'auto-référence ;
  - `ConflictException` (409) pour un parent qui a un parent, un service avec N pôles qui reçoit un parent, un secteur différent (`IS DISTINCT FROM`), ou un changement de secteur d'un service qui a N pôles.

  Intégration dans les méthodes existantes :
  - `create_service` (l.500) : appel avant `Service(...)` ;
  - `update_service` (l.537) : appel avec l'état fusionné (`kwargs.get('parent_id', current.parent_id)`, `kwargs.get('sector_id', current.sector_id)`), seulement si `parent_id` ou `sector_id` est présent dans `kwargs` ;
  - `update_service` et `create_service` : autour du `flush`, `except DBAPIError as exc` avec `getattr(exc.orig, 'sqlstate', None) == '23514'` (asyncpg : `exc.orig.__cause__.sqlstate`) → `ConflictException(message du trigger)` ;
  - `duplicate_service` (l.626) : recopier `parent_id`, laisser `landing_path` à `None`.

  Lancer `pytest tests/integration/test_services_hierarchy.py -v` → tout passe.
- [X] T027 [US2] Ajouter au formulaire de la modale de `usenghor_nuxt/app/pages/admin/organisation/services/index.vue` (l.1267-1533, `contracts/frontend.md` § 2) :
  - **Sélecteur « Service parent »** sous « Secteur » (l.1292) : `<select v-model="newService.parent_id">`.
    - Options : `null` « Aucun (service de premier niveau) », puis `parentOptions` = services avec `!s.parent_id && s.sector_id === newService.sector_id && s.id !== editingServiceId`, triés par nom, libellé `sigle — name`.
    - `:disabled="editingChildrenCount > 0"`, avec l'aide « Ce service a {n} pôle(s) : il ne peut pas être rattaché ».
    - `watch` sur `newService.sector_id` : remettre `parent_id` à `null` s'il n'est plus dans `parentOptions`.
  - **Champ « Page dédiée (facultatif) »** : `<input v-model.trim="newService.landing_path" placeholder="/entrepreneuriat">`.
    - Aide « Chemin interne sans préfixe de langue. Si renseigné, la carte du service dans l'organigramme mène à cette page. ».
    - Validation immédiate avec `const LANDING_PATH_RE = /^\/(?!\/)(?!(?:en|ar)(?:\/|$))(?!r\/)[^\s?#]*$/`.
    - Bouton Enregistrer (l.1524) également désactivé si la valeur est invalide.
  - **Valeurs initiales** : `parent_id` et `landing_path` à l'ouverture en édition, `null` / `''` en création ; `''` envoyé comme `null`.
  - **Erreurs** : `modalError` affiche `error.data?.detail` des réponses 409 / 422 dans un bandeau `role="alert"` en haut de la modale, à la place du seul `console.error` de `saveService` (l.482) ; remis à vide à l'ouverture.
- [X] T028 [US2] Afficher la hiérarchie dans la liste de `usenghor_nuxt/app/pages/admin/organisation/services/index.vue` : — Écart : miroir RTL de l'icône porté par un `<span>` parent (`fa-rotate-90` et `rtl:-scale-x-100` s'écrasent sur le même élément).
  - fonction locale `orderHierarchically(list)` : pôles juste après leur parent, parents triés par `(display_order, name)`, pôles par `(display_order, name)` ; appliquée à `filteredServices` (l.302) et à chaque groupe de `filteredServicesGrouped` (l.346) ;
  - ligne ou carte de pôle, dans la vue tableau (l.856) et la vue groupée (l.1109-1247) : `ps-8`, icône `fa-solid fa-turn-up fa-rotate-90` avec `rtl:-scale-x-100`, pastille « Pôle de {parent.sigle || parent.name} » ; un pôle dont le parent est filtré s'affiche seul, avec sa pastille ;
  - `canDrag` (l.594) faux pour une ligne de pôle ; les `ids` passés à `reorderServices` dans `handleDrop` (l.610) excluent les pôles.
- [X] T029 [US2] Dans la modale de suppression de `usenghor_nuxt/app/pages/admin/organisation/services/index.vue` (l.1536-1599) : si le service a N pôles (compte calculé sur `services`), afficher l'avertissement « Ses N pôle(s) deviendront des services de premier niveau du secteur. », sans bloquer la suppression.
- [X] T030 [P] [US2] Dans l'onglet Informations de `usenghor_nuxt/app/pages/admin/organisation/services/[id].vue` (l.427-455), ajouter trois lignes en lecture seule :
  - « Service parent » : `NuxtLink` vers `/admin/organisation/services/{parent_id}` avec le nom du parent (via `getAllServices` ou `getServiceById(parent_id)`), sinon « — » ;
  - « Page dédiée » : chemin, sinon « — » ;
  - « Pôles » : liens vers les services dont `parent_id === service.id`, ligne masquée s'il n'y en a aucun.
- [X] T031 [US2] Dérouler quickstart § 4 (étapes 1 à 8) :
  - liste hiérarchique, recherche et glisser-déposer ;
  - rattachement d'un service de test ;
  - DDE non rattachable et bandeau 409 au changement de secteur ;
  - refus immédiats de la page dédiée ;
  - `curl` directs → 409 / 422 ;
  - suppression avec avertissement, **sur une copie** ;
  - `[id].vue` ;
  - audit : `SELECT action, record_id, old_values->>'parent_id', new_values->>'parent_id', new_values->>'landing_path' FROM audit_logs WHERE table_name = 'services' ORDER BY created_at DESC LIMIT 5`, une entrée par écriture sans doublon.

  Consigner le résultat dans quickstart § 4.

**Checkpoint** : US2 livrable seule. Hiérarchie éditable et garantie.

---

## Phase 5: User Story 3 - Accéder au mini-site depuis le menu, le pied de page et un lien court (Priority: P2)

**Goal** : l'entrée « Entreprendre à Senghor » est présente dans le menu « Plus » › Nous connaître et dans le pied de page, dans les trois langues ; les entrées du menu acceptent des libellés anglais et arabe ; `/r/pei` redirige ; la génération de codes courts ne bute plus sur un code pris.

**Independent Test** : quickstart § 6.

- [X] T032 [US3] Ajouter le test à `usenghor_backend/tests/integration/test_services_hierarchy.py` : `create_short_link` saute un code déjà pris.
  - Fixture locale : `CREATE SEQUENCE IF NOT EXISTS short_link_counter_seq START WITH 0 MINVALUE 0 MAXVALUE 1679615`, puis `SELECT setval('short_link_counter_seq', 32921)`, et un `ShortLink(code='pei', target_url='/entrepreneuriat')`.
  - Appel `ShortLinkService(db_session).create_short_link('/actualites', created_by=None)` → le code obtenu est différent de `'pei'` (`int_to_base36(32923)`), sans exception.
- [X] T033 [US3] Modifier `create_short_link` dans `usenghor_backend/app/services/short_links_service.py` (l.92-137, research R12, `contracts/api.md` § 4) :
  - boucle d'au plus 20 itérations : `nextval('short_link_counter_seq')` → si `counter > MAX_COUNTER`, `ValidationException` « Capacité maximale atteinte (1 679 616 liens)… » (message existant) → `code = int_to_base36(counter)` → sortie si `SELECT 1 FROM short_links WHERE code = :code` est vide ;
  - après 20 échecs : `ValidationException("Impossible de générer un code court libre, réessayez")` ;
  - réduire le `try/except Exception` actuel à l'erreur de séquence épuisée, sans masquer les autres exceptions ;
  - lancer `pytest … -k short_link -v` → passe.
- [X] T034 [P] [US3] Libellés trilingues dans `usenghor_nuxt/app/components/AppNavBar.vue` (research R10, `contracts/frontend.md` § 4) :
  - types JSON des enfants primaires (l.227-262) et secondaires (l.266-297) : `label_en?: string`, `label_ar?: string` ;
  - `NavChild` (l.29-36) : `_labels?: { fr?: string, en?: string, ar?: string }`, rempli par le mappage en plus de `_label` ;
  - fonction `navChildLabel(sectionKey: string, child: NavChild): string` = `child._labels?.[locale.value as 'fr' | 'en' | 'ar'] || child._label || t(\`nav.dropdowns.${sectionKey}.${child.key}\`)` ;
  - remplacer les trois expressions `child._label || t('nav.dropdowns.…')` (méga-menu l.446, menu « Plus » l.537, mobile l.782) ;
  - une entrée sans `label_en` ni `label_ar` doit donner une sortie identique.
- [X] T035 [P] [US3] Étendre `usenghor_nuxt/app/components/admin/editorial/NavItemsField.vue` :
  - `NavSubItem` (l.4-12) : `label_en?: string`, `label_ar?: string` ;
  - formulaire d'ajout et d'édition (l.318-391) : champs facultatifs « Libellé (anglais) » (`dir="ltr"`) et « Libellé (arabe) » (`dir="rtl"`) sous « Libellé » ;
  - enregistrement de l'item : fusion `{ ...itemExistant, ...formData }` (clés inconnues préservées), suppression des clés `label_en` / `label_ar` vides ;
  - affichage de la liste : libellés EN / AR discrets sous le libellé FR quand ils existent.
- [X] T036 [P] [US3] Ajouter le lien au pied de page :
  - `usenghor_nuxt/app/components/AppFooter.vue`, colonne University (l.256-288) : `<li>` après `governance` avec `NuxtLink :to="localePath('/entrepreneuriat')"` et `t('footer.university.entrepreneurship')`, mêmes classes que les liens voisins ;
  - `footer.university.entrepreneurship` = « Entreprendre à Senghor » dans `usenghor_nuxt/i18n/locales/fr/footer.json`, « Entrepreneurship at Senghor » dans `…/en/footer.json`, « ريادة الأعمال في سنغور » dans `…/ar/footer.json`.
- [X] T037 [US3] Dérouler quickstart § 6 :
  - menu « Plus » en FR / EN / AR, bureau et mobile, changement de langue à chaud ;
  - libellé anglais ajouté à « Notre histoire » dans le backoffice, visible en EN seulement ;
  - suppression de l'entrée du pôle puis rejeu de la 050 → rajoutée une fois ;
  - pied de page dans les trois langues ;
  - `curl -sI localhost:3001/r/pei` et `/r/PEI` → `302`, `location: /entrepreneuriat` ;
  - lien visible dans `/admin/liens-courts`.

  Consigner le résultat dans quickstart § 6.

**Checkpoint** : US3 livrable seule.

---

## Phase 6: User Story 4 - Se repérer dans le mini-site grâce au fil d'Ariane (Priority: P2)

**Goal** : un seul fil d'Ariane « Accueil › Nous connaître › Organisation › DDE › Pôle Entrepreneuriat et Innovation (› rubrique) » sur les sept pages. Le niveau DDE est résolu par le parent du pôle, sinon par la clé.

**Independent Test** : quickstart § 7.

- [X] T038 [US4] Ajouter `export function usePeiBreadcrumb(current: MaybeRefOrGetter<string | null>, ddeServiceId: MaybeRefOrGetter<string | null>)` dans `usenghor_nuxt/app/composables/usePeiPage.ts` (`contracts/frontend.md` § 6) :
  - données : `useAsyncData('pei-org-services', () => listServices().catch(() => []))` ;
  - `pole` = service avec `landing_path === '/entrepreneuriat'` ;
  - `dde` = service avec `id === pole?.parent_id`, sinon `id === toValue(ddeServiceId)` ;
  - `breadcrumb` calculé :
    1. `{ label: t('nav.home'), to: '/' }` ;
    2. `{ label: t('nav.about'), to: '/a-propos' }` ;
    3. `{ label: t('about.tabs.organization'), to: '/a-propos/organisation' }` ;
    4. si `dde` : `{ label: dde.sigle || t('pei.breadcrumb.dde'), to: getServiceUrl(dde) }` ;
    5. `{ label: t('pei.breadcrumb.pole'), to: toValue(current) ? '/entrepreneuriat' : undefined }` ;
    6. si `current` : `{ label: toValue(current) }` ;
  - retour `{ breadcrumb, ready }`.

  Dans `usePeiPage`, remplacer le bloc l.71-79 par `usePeiBreadcrumb(() => t(\`pei.nav.${navKey}\`), ddeServiceId)` et attendre `ready` dans le `Promise.all` final. `ddeService` et `ddeServiceId` restent inchangés (données des rubriques).
- [X] T039 [P] [US4] Dans `usenghor_nuxt/app/pages/entrepreneuriat/index.vue` :
  - supprimer `ddeLink` et le `breadcrumb` local (l.59-67) ;
  - utiliser `const { breadcrumb, ready: breadcrumbReady } = usePeiBreadcrumb(null, ddeServiceId)`, avec `breadcrumbReady` ajouté au `Promise.all` (l.30) ;
  - conserver la lecture `pei-home-dde`, **seulement si** `ddeService` sert encore à autre chose que le fil d'Ariane (sinon la retirer) ;
  - le JSON-LD `BreadcrumbList` (l.83-104) utilise le `breadcrumb` partagé.
- [X] T040 [P] [US4] Même changement dans `usenghor_nuxt/app/pages/entrepreneuriat/activites.vue` : supprimer les l.69-77, puis `usePeiBreadcrumb(() => t('pei.nav.activities'), ddeServiceId)`, `ready` dans le `Promise.all` (l.28), JSON-LD (l.94-100) sur le `breadcrumb` partagé. Garder intacts l'ancre `route.hash` et `scrollToPageAnchor` (l.57-62).
- [X] T041 [US4] Dérouler quickstart § 7 :
  - les sept pages en FR / EN / AR : niveaux et liens, dernier niveau sans lien ;
  - JSON-LD `BreadcrumbList` identique au fil affiché ;
  - pôle détaché → repli sur la clé ; clé vide + pôle détaché → niveau DDE omis sans erreur ;
  - `grep -rn "pei.breadcrumb.dde" usenghor_nuxt/app` → une seule occurrence (`usePeiPage.ts`).

  Consigner le résultat dans quickstart § 7.

**Checkpoint** : US4 livrable seule.

---

## Phase 7: User Story 5 - Référencer correctement l'organisation et le mini-site (Priority: P3)

**Goal** : le plan du site émet des URLs de secteurs, services et pôles valides dans les trois langues, ainsi que les sept pages du mini-site.

**Independent Test** : quickstart § 8.

- [X] T042 [US5] Réécrire le bloc organisation (l.124-149) de `usenghor_nuxt/server/api/__sitemap__/urls.ts` (research R13, `contracts/frontend.md` § 7) : — Ajout de `_i18nTransform: true` sur les entrées d'organisation (sinon émises en français seulement).
  - ajouter en tête `function slugifyServiceName(name: string): string`, avec le commentaire « Copie de slugify (app/composables/usePublicOrganizationApi.ts l.137-144) — doit rester identique » et le même corps (NFD, suppression des diacritiques, minuscules, `[^a-z0-9]+` → `-`, `-` retirés aux extrémités) ;
  - bloc `try` secteurs : `$fetch<Array<{ code: string }>>(\`${backendUrl}/api/public/sectors\`)` → `loc: \`/a-propos/organisation/secteur/${code.toLowerCase()}\`` ;
  - bloc `try` services séparé : `$fetch<Array<{ name: string }>>(\`${backendUrl}/api/public/services\`)` → `loc: \`/a-propos/organisation/service/${slugifyServiceName(name)}\``, dédupliqué par `Set` ;
  - chaque bloc garde son `catch` silencieux ;
  - aucune ligne pour `/entrepreneuriat/*` (découverte automatique).
- [X] T043 [US5] Dérouler quickstart § 8 :
  - `sitemap.xml` en local ;
  - 100 % des URLs d'organisation en 200 ;
  - aucune `secteurs/` ni `services/` ;
  - chaque service et pôle actif une fois par langue ;
  - sept pages `/entrepreneuriat*` × 3 langues.

  Comparer avec `sitemap-avant.xml` (T003) et consigner le résultat dans quickstart § 8.

**Checkpoint** : US5 livrable seule.

---

## Phase 8: Polish (avant la mise en ligne)

**Purpose** : build, non-régression complète et documentation.

- [X] T044 Lancer la suite backend `cd usenghor_backend && source .venv/bin/activate && pytest -q`. `test_services_hierarchy.py` est entièrement vert. Les 5 échecs FAQ liés au vrai traducteur (`record_id="bulk"`, gotcha connu) sont notés sans être masqués. Aucun autre échec nouveau.
- [X] T045 [P] Lancer le build `cd usenghor_nuxt && NODE_OPTIONS=--max-old-space-size=8192 pnpm build` : aucune erreur de type ou d'import, aucun `WARN` de collision d'auto-import sur les noms de T002.
- [X] T046 Non-régression visuelle (quickstart § 9) : captures après pour toutes les pages de T003, comparées à l'avant ; différences acceptées uniquement pour les cartes et fiches liées au pôle, le menu « Nous connaître » et le pied de page.
  - Fiches formation, projet et appel à 1440 et 390 px : si elles sont identiques, cocher T039 dans `specs/023-pei-public-home-activities/tasks.md` avec la date et le résultat.
- [X] T047 [P] Mettre à jour `CLAUDE.md` :
  - ligne « Composants clés » `OrganigrammeSection` (pôles sous le parent, carte vers `landing_path`) ;
  - `usePeiPage` → `usePeiBreadcrumb` ;
  - `AppNavBar` et `NavItemsField` : `label_en` / `label_ar` ;
  - section « Recent Changes », entrée `026-pei-org-navigation-launch` :
    - colonnes `services.parent_id` / `landing_path`, trigger `services_check_hierarchy` (un niveau, même secteur) ;
    - pôle PEI (identifiant fixe) ;
    - bloc « Pôles » de la fiche ;
    - menu « Plus » › Nous connaître ;
    - pied de page ;
    - lien court `/r/pei` et génération qui saute les codes pris ;
    - plan du site corrigé (`secteur/`, `service/`) ;
    - correctif des lectures publiques des secteurs, qui supprimaient les services inactifs ;
    - migration 050 et ordre des rollbacks (050 avant 049 → 045).
- [X] T048 [P] Mettre à jour `specs/roadmap-pei-entrepreneuriat.md` : bandeau « ✅ Livrée » sous « Feature 026 », avec la portée retenue (pôle par `parent_id` / `landing_path`, menu « Nous connaître » trilingue, pied de page, `/r/pei`, plan du site, correctif C1). — Bandeau « Livrée en local », production en attente d'accord.
- [X] T049 Commit local dans chaque dépôt concerné, **sans push**, avec des messages en français :
  - `usenghor_backend` : correctif C1, hiérarchie des services, liens courts, SQL 050 ;
  - `usenghor_nuxt` : backoffice, organigramme, fiche, menu, pied de page, fil d'Ariane, plan du site ;
  - racine : specs 026, CLAUDE.md, roadmap.

  **Fait (2026-09-15)** : `usenghor_backend` bc5c17f, `usenghor_nuxt` 45df7f5 (sans les modifications `i18n/locales/*/actualites.json`, étrangères à la 026), racine (specs, CLAUDE.md, roadmap, T039 de la 023, pointeurs des sous-dépôts). Aucun push.

---

## Phase 9: User Story 6 - Mettre en ligne et clôturer le mini-site (Priority: P1, en dernier)

**Goal** : mise en production contrôlée de la 026 et clôture des tâches de production restées ouvertes (021, 023).

**Independent Test** : quickstart § 10, compte rendu par étape.

**⚠️ Chaque tâche de cette phase attend un accord explicite distinct du responsable avant exécution.**

- [ ] T050 [US6] **Après accord** : `git -C usenghor_backend push origin main`, `git -C usenghor_nuxt push origin main`, puis `git push origin main` à la racine. Vérifier `git status` propre et `origin/main` à jour dans les trois dépôts (mémoire : `deploy.sh` part de GitHub).
- [ ] T051 [US6] **Après accord** : `./deploy.sh backup` ; noter le nom et la date du fichier de sauvegarde dans quickstart § 10 b.
- [ ] T052 [US6] Contrôle en **lecture seule** en production (aucune écriture) : `ssh ubuntu@137.74.117.231 'docker exec -i -e PGOPTIONS="-c default_transaction_read_only=on" usenghor_db psql -U usenghor -d usenghor'`, avec les requêtes de research C4 / C5.

  | Élément contrôlé | Attendu |
  |---|---|
  | clé `entrepreneurship.dde_service_id` | `72eca1c4-4109-457e-beae-6a5a4b379b84` |
  | motif de nom de la DDE | 1 ligne |
  | clés `entrepreneurship.%` | 138 |
  | catégories `see-%` | 4 |
  | clés `entrepreneurship.activities.hero.%` | 4 |
  | colonnes `parent_id` / `landing_path` | absentes |
  | `short_links` code `pei` | absent |
  | menu `about` | 4 entrées |
  | permissions `entrepreneurship.*` | 4 par rôle `super_admin` / `admin` / `editor` |

  **Tout écart** → arrêt et signalement : aucune migration 045–049 rejouée sans raison. Consigner dans quickstart § 10 c.
- [ ] T053 [US6] **Après accord** : copier la migration sur le serveur (dépôt tiré ou `scp`), puis jouer deux fois `docker exec -i usenghor_db psql -U usenghor -d usenghor < 050_services_parent_landing.sql`.
  - Passage 1 : NOTICE « pôle créé », « entrée du pôle ajoutée (sort_order 5) », `INSERT 0 1`.
  - Passage 2 : « déjà présent » ×2, `INSERT 0 0`.
  - Comptes `pei | poles | menu | lien` = `1 | 1 | 5 | 1`, identiques après les deux passages.

  Consigner dans quickstart § 10 d.
- [ ] T054 [US6] **Après accord** : `./deploy.sh update` (recrée `backend`, `frontend` et `db` avec `--force-recreate`).
  - `docker ps` : uptime récent de `usenghor_frontend` et `usenghor_backend`.
  - Si le build frontend échoue sans effet visible, lire le journal par `docker buildx history logs` (mémoire OOM).

  Consigner dans quickstart § 10 e.
- [ ] T055 [US6] Contrôles de production (quickstart § 10 f), dans les trois langues :
  - organigramme : PEI sous la DDE, carte vers `/entrepreneuriat` ;
  - fiche DDE : bloc « Pôles » ;
  - fiche PEI : liens ;
  - menu « Plus » › Nous connaître ;
  - pied de page ;
  - `curl -sI https://<domaine>/r/pei` → 302 `/entrepreneuriat` ;
  - plan du site : URLs d'organisation en 200, sept pages × 3 langues ;
  - fil d'Ariane des sept pages, contenu présent dans le HTML SSR (`curl`).

  Compte rendu par point dans quickstart § 10 f.
- [ ] T056 [US6] **Après accord** : lancer « Traduire les champs manquants » depuis `/admin/entrepreneuriat` en production. Consigner les compteurs retournés, puis vérifier que les pages EN et AR du pôle n'affichent aucun champ vide dû à une traduction manquante (quickstart § 10 g).
- [ ] T057 [P] [US6] Mesurer Lighthouse mobile derrière nginx en production :
  - commande : `npx -y lighthouse@12 https://<domaine>/<page> --form-factor=mobile --only-categories=performance,accessibility --output=json --output-path=<scratchpad>/lh-<page>.json` ;
  - pages : `/entrepreneuriat`, `/entrepreneuriat/activites`, `/entrepreneuriat/statut-etudiant-entrepreneur` et la référence `/a-propos/organisation` ;
  - attendu : accessibilité ≥ 90 ; écart de performance consigné par rapport à la référence (mémoire : production ≈ 65–80).

  Consigner les scores dans quickstart § 10 h et dans `specs/023-pei-public-home-activities/quickstart.md` § 11. Cocher T048 de la 023.
- [ ] T058 [US6] Clôturer les tâches ouvertes (quickstart § 10 i) :
  - **T071** de `specs/021-pei-entrepreneurship-core/tasks.md` : cocher avec les preuves du suivi (migration 045 jouée deux fois en production le 2026-09-13, clé DDE renseignée) et de T052 (état du 2026-09-15). Noter que `pei_resources = 0` en production (4 ressources seedées par la 045, suppression par l'équipe à confirmer) et que « Traduire les champs manquants » a été lancé en T056.
  - **T051** de `specs/023-pei-public-home-activities/tasks.md` : cocher avec les preuves de T052 (clés hero 047 présentes) et T055. Les images du slider restent à choisir par l'équipe si elles sont absentes.
  - **T039** et **T048** de la 023 : cochés en T046 et T057, sinon laissés ouverts avec la raison.
- [ ] T059 [US6] Enregistrer la mémoire du projet dans `/Users/mac/.claude/projects/-Users-mac-Documents-projets-2025-usenghor/memory/`, et mettre à jour l'index `MEMORY.md` :
  - mettre à jour `public-sectors-read-deletes-inactive-services.md` : correctif déployé, date ;
  - mettre à jour `pei-mini-site-proposal.md` : 026 livrée, décision D1 appliquée ;
  - ajouter un fait sur les libellés `label_en` / `label_ar` du menu éditorial, et un sur le trigger `services_check_hierarchy` et l'ordre des rollbacks.
- [ ] T060 [US6] **Après accord** : commit + push de la documentation finale (quickstart renseigné, tâches 021 / 023 / 026 cochées, CLAUDE.md, roadmap) dans le dépôt racine.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1** : T001 bloque T008–T011. T002 et T003 sont immédiates, et T003 doit précéder tout code.
- **Phase 2** :
  - T004 → T005 (correctif C1, indépendant du SQL, à faire en premier) ;
  - T006, T007, T012, T013 en parallèle dès T003 ;
  - T008 → T009 → T011, avec T010 en parallèle de T009 ;
  - T014 après T006, T007 et T011 ;
  - T015 après T006.
- **US1 (Phase 3)** : après la phase 2. Côté backend, T016 → T017 → T018 ; T019–T021 en parallèle ; T022 et T023 après T013 et T019 ; T024 en fin.
- **US2 (Phase 4)** : après la phase 2. T025 → T026 ; T027 → T028 → T029 (même fichier) ; T030 en parallèle ; T031 en fin.
- **US3 (Phase 5)** : après la phase 2 (T011 pour l'entrée de menu seedée). T032 → T033 ; T034, T035, T036 en parallèle ; T037 en fin.
- **US4 (Phase 6)** : après T011 (pôle en base) et T013. T038 → T039 ∥ T040 → T041.
- **US5 (Phase 7)** : après T011 et T018 (pôles dans `/api/public/services`). T042 → T043.
- **Phase 8** : après les stories retenues. T044, T045, T047, T048 en parallèle ; T046 après T045 ; T049 en dernier.
- **US6 (Phase 9)** : après la phase 8, strictement dans l'ordre T050 → T051 → T052 → T053 → T054 → T055 → T056. T057 est possible après T054. T058 → T059 → T060.

### Fichiers partagés (pas de parallélisme)

- `usenghor_backend/tests/integration/test_services_hierarchy.py` : T004, T016, T025, T032 (séquentielles).
- `usenghor_backend/app/services/organization_service.py` : T005, T015, T017, T018, T026 (séquentielles).
- `usenghor_nuxt/app/pages/admin/organisation/services/index.vue` : T027, T028, T029 (séquentielles).

### Within Each User Story

Tests backend (qui doivent échouer) → service ou routeur → frontend → validation quickstart.

---

## Parallel Example: User Story 1

```text
# Après T018 (backend US1) :
T019 [P] i18n FR — organization-detail.json, organization.json
T020 [P] i18n EN — organization-detail.json, organization.json
T021 [P] i18n AR — organization-detail.json, organization.json
# puis T022 (OrganigrammeSection.vue) et T023 ([type]/[slug].vue) : fichiers distincts, parallélisables entre eux
```

## Parallel Example: User Story 3

```text
T034 [P] AppNavBar.vue — label_en / label_ar, navChildLabel
T035 [P] NavItemsField.vue — champs Libellé (anglais / arabe)
T036 [P] AppFooter.vue + footer.json ×3
# en parallèle côté backend : T032 → T033 (short_links_service.py)
```

## Parallel Example: stories entre elles (après la phase 2)

```text
Développeur A : US1 (T016–T024)  — organization_service.py côté public, organigramme, fiche
Développeur B : US3 frontend (T034–T037) puis US4 (T038–T041)
Développeur C : US5 (T042–T043)
# US2 (T025–T031) après US1 si un seul développeur backend (organization_service.py partagé)
```

---

## Implementation Strategy

### MVP (correctif + US1)

1. Phase 1 (accord SQL, inventaire, captures).
2. T004–T005 : correctif C1, **livrable et déployable seul** si la situation l'exige (perte de données), après accord.
3. Fin de la phase 2 (SQL 050, modèle, schémas, types).
4. US1 : le pôle est visible sous la DDE et mène au mini-site. **STOP et validation** (quickstart § 5).

### Incremental Delivery

1. MVP (correctif + US1).
2. US2 : backoffice et règles → validation § 4.
3. US3 : menu, pied de page, `/r/pei` → validation § 6.
4. US4 : fil d'Ariane → validation § 7.
5. US5 : plan du site → validation § 8.
6. Phase 8 : build, non-régression, documentation, commits locaux.
7. US6 : mise en ligne, une action à la fois après accord.

### Notes

- Aucune ligne de code SQL, backend ou frontend dépendant du schéma avant l'accord T001. T002–T005 peuvent avancer avant.
- Ne jamais rejouer `012_seed_navbar_subitems.sql` : elle écrase les menus édités.
- Ne désactiver aucun service en production avant le déploiement du correctif C1.
- Commit après chaque tâche ou groupe logique ; push et actions de production uniquement en phase 9, après accord.
