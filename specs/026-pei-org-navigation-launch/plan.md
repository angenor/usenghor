# Implementation Plan: Rattachement du PEI à l'organigramme, navigation et mise en ligne du mini-site

**Branch**: `026-pei-org-navigation-launch` (travail sur `main`, convention des features PEI) | **Date**: 2026-09-15 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/026-pei-org-navigation-launch/spec.md`

## Summary

Donner au Pôle Entrepreneuriat et Innovation sa place dans l'organigramme, en **pôle** de la DDE, puis ouvrir et mettre en ligne l'accès au mini-site.

- **Données** : `services.parent_id` (FK `SET NULL`, un seul niveau, même secteur) et `services.landing_path` (chemin interne). La hiérarchie est garantie deux fois : validation backend avec messages français, et trigger `services_check_hierarchy` en base.
- **Migration 050 rejouable** : elle crée le service PEI (identifiant fixe, `/entrepreneuriat`) sous la DDE résolue par la clé puis par le nom, ajoute sans rien écraser l'entrée trilingue « Entreprendre à Senghor » au menu « Plus » › Nous connaître, et crée le lien court `pei`. Elle a son rollback. **SQL soumis à accord, testé à blanc** en local et avec la résolution vérifiée en lecture seule sur la production.
- **API** : ajouts de champs ; `with-services` et `/sectors/{code}` imbriquent les pôles sous `children` ; la fiche expose `parent` et `children`. Ces lectures deviennent **en lecture pure**, ce qui corrige un défaut de perte de données découvert au plan : elles supprimaient les services inactifs (research C1).
- **Backoffice** : sélecteur « Service parent » et champ « Page dédiée » dans la modale de la liste ; liste hiérarchique ; erreurs affichées. L'audit est déjà assuré par `AuditMiddleware`.
- **Public** :
  - pôles sous leur parent dans `OrganigrammeSection`, sans changement de rendu pour les services sans pôle ;
  - bloc « Pôles », lien vers le parent et lien vers la page dédiée sur la fiche ;
  - libellés trilingues facultatifs des entrées du menu éditorial (Q2) et lien dans le pied de page ;
  - fil d'Ariane factorisé (`usePeiBreadcrumb`) ;
  - plan du site corrigé ;
  - génération des codes courts qui saute les codes pris.
- **Mise en ligne** : contrôle en lecture seule (045 → 049 déjà jouées), 050 jouée deux fois, déploiement, contrôles, Lighthouse, clôture des tâches ouvertes — chaque étape soumise à accord.

Décisions : [research.md](research.md) (C1–C10, R1–R16).

## Technical Context

**Language/Version**: Python 3.14 (FastAPI) ; TypeScript 5.x / Vue 3 Composition API (Nuxt 4) ; SQL PostgreSQL 16 (PL/pgSQL pour le trigger).

**Primary Dependencies**: FastAPI, SQLAlchemy async, Pydantic v2 ; Nuxt 4, Tailwind CSS 3, `@nuxtjs/i18n` (`prefix_except_default`), `@nuxtjs/sitemap` (`autoI18n`), Font Awesome. **Aucune nouvelle dépendance.**

**Storage**: PostgreSQL 16 (`usenghor_postgres` en local, `usenghor_db` en production). `services` reçoit 2 colonnes, 2 CHECK, 1 FK, 1 index partiel, 1 trigger. Données seedées dans `services`, `editorial_contents` (`navbar.secondary.about.children`) et `short_links`.

**Testing**: pytest, nouveau `tests/integration/test_services_hierarchy.py` (validation, imbrication, régression C1, duplication, lien court) ; SQL du trigger testé à blanc (data-model § 6, quickstart § 2) ; frontend sans infrastructure de test, validé par [quickstart.md](quickstart.md) (captures avant / après, `curl` SSR, plan du site, JSON-LD) et `pnpm build`.

**Target Platform**: Docker Linux (nginx + Nuxt SSR + FastAPI + PostgreSQL) ; navigateurs récents, 390 px, mode sombre, RTL.

**Project Type**: application web monorepo (3 dépôts git : racine, `usenghor_nuxt`, `usenghor_backend`).

**Performance Goals**: aucune lecture SSR supplémentaire sur l'organigramme et les fiches (champs ajoutés aux lectures existantes). Sur le mini-site, `listServices` (26 lignes) remplace une lecture de service par page, dédupliquée par clé `useAsyncData`. Lighthouse mobile : accessibilité ≥ 90, performance comparée à une page existante.

**Constraints**:
- rendu strictement identique pour les services sans pôle ;
- entrées de menu éditées conservées ;
- `findServiceBySlug` et `getServiceUrl` inchangés ;
- aucune adresse publique modifiée ;
- `ddeServiceId` des données du mini-site inchangé ;
- SQL validé avant le code ;
- aucun rejeu de 045 → 049 sans écart constaté ;
- chaque action de production soumise à accord ;
- noms de fichiers `[a-z0-9_-]` ;
- `useSeoMeta` après la résolution de route.

**Scale/Scope**: 26 services en production, 1 pôle.
- **Backend** : 6 fichiers modifiés (modèle, schémas, service d'organisation, 2 routeurs publics, service des liens courts), 1 fichier de tests.
- **Frontend** : 2 composables, 1 fichier de types, 2 pages admin, `OrganigrammeSection`, fiche `[type]/[slug].vue`, `AppNavBar`, `NavItemsField`, `AppFooter`, `usePeiPage` et 2 pages PEI, plan du site.
- **i18n** : 3 langues, environ 6 clés.
- **SQL** : `04_organization.sql`, migration 050 et son rollback.
- **Documentation** : CLAUDE.md, roadmap, mémoire.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` est un gabarit non rempli. Les portes viennent de CLAUDE.md, de la mémoire projet, de la roadmap PEI et de la demande :

| Porte | Statut | Preuve |
|---|---|---|
| Structure BDD : accord → SQL → code | ✅ prévu | data-model § 3–5 **à valider** ; test à blanc (§ 6) ; aucune ligne de code avant accord |
| Résolution par nom testée en lecture seule en production (mémoire « apostrophe ’ ») | ✅ | research C4 : clé → DDE, motif → 1 ligne, `default_transaction_read_only=on` |
| Migration rejouable + rollback + ordre documenté (050 avant 049 → 045) | ✅ | data-model § 4–6 : 2 passages identiques, rollback ×2, rejeu après rollback |
| Réutiliser avant de créer (sous-agent) | ✅ | inventaire du 2026-09-15 : aucune carte de service réutilisable ; **aucun composant créé** (R9) |
| Public sans auth ; lectures publiques seulement côté public | ✅ | contracts/api.md § 3 ; `usePeiBreadcrumb` utilise `/api/public/services` |
| Routes statiques avant dynamiques | ✅ n/a | aucune route ajoutée |
| Permissions seedées | ✅ n/a | aucune permission nouvelle (`organization.*` existantes) ; contrôle `entrepreneurship.*` en production (C5 : 3 rôles × 4) |
| Collisions d'auto-import | ✅ | `getServiceLink`, `usePeiBreadcrumb`, `navChildLabel`, `slugifyServiceName` absents du dépôt ; `slugify` non déplacé (R13) |
| SEO : route avant `useSeoMeta`, plan du site, JSON-LD | ✅ | fil d'Ariane factorisé sans déplacer `applySeo` ; URLs du plan corrigées (R13) |
| Lenis et ancres | ✅ n/a | aucune ancre ajoutée |
| i18n FR / EN / AR, RTL, sombre | ✅ prévu | contracts/frontend.md § 3–5 (`rtl:-scale-x-100`, `border-s`, `ms-`) |
| Français avec accents (code et contenus) | ✅ | messages d'erreur, NOTICE, libellés |
| Déploiement : commit + push des sous-dépôts d'abord, `--force-recreate`, OOM → `buildx history` | ✅ | quickstart § 10 (a, e) ; `deploy.sh update` recrée déjà les conteneurs |
| Zéro régression fiches secteur / service, menu, pied de page | ✅ prévu | nœud DOM identique sans pôle ; `diff` JSON ; captures (quickstart § 0, 5, 9) |
| Audit des modifications | ✅ | `AuditMiddleware` existant (C2), vérifié au quickstart § 4.8 |
| Hors périmètre (contenu éditorial, hiérarchie > 1 niveau) | ✅ | trigger + validation limitent à 1 niveau |
| CLAUDE.md et mémoire maintenus | ✅ prévu | quickstart § 10 j |

**Re-check post-design (Phase 1)** : aucune violation. Trois écarts à la description, assumés et documentés :
1. **Correction d'un défaut de perte de données** (C1) sur deux lectures publiques, hors description mais indispensable : un pôle désactivé serait supprimé.
2. **Formulaire dans la modale de `index.vue`** et non dans `[id].vue` (C3). `[id].vue` affiche en lecture le parent, la page dédiée et les pôles.
3. **Audit sans code nouveau** (C2), pour éviter un double enregistrement.

## Project Structure

### Documentation (this feature)

```text
specs/026-pei-org-navigation-launch/
├── plan.md              # Ce fichier
├── research.md          # Phase 0 — constats C1–C10, décisions R1–R16
├── data-model.md        # Phase 1 — entités, SQL 04 / 050 / rollback À VALIDER, test à blanc
├── quickstart.md        # Phase 1 — 11 blocs de validation dont la mise en ligne (§ 10)
├── contracts/
│   ├── api.md           # schémas, validation hiérarchique, lectures publiques, liens courts
│   └── frontend.md      # composables, backoffice, organigramme, fiche, menu, pied de page, fil d'Ariane, plan du site
├── checklists/requirements.md
└── tasks.md             # Phase 2 (/speckit-tasks)
```

### Source Code (repository root)

```text
usenghor_backend/
├── app/models/organization.py                 # Service.parent_id, Service.landing_path
├── app/schemas/organization.py                # champs + ServiceRelativePublic, ServicePublicWithChildren, validateur landing_path
├── app/services/organization_service.py       # _validate_hierarchy ; create/update/duplicate ; lectures secteurs sans mutation ORM + children ;
│                                              #   get_service_with_details → parent/children
├── app/routers/public/sectors.py              # /with-services et /{code} : schémas construits (correctif C1)
├── app/routers/public/services.py             # ServicePublicWithDetailsEnriched + parent/children
├── app/routers/admin/services.py              # conversion 23514 → 409 (si non centralisée dans le service)
├── app/services/short_links_service.py        # tirages successifs, codes pris sautés
├── tests/integration/test_services_hierarchy.py   # nouveau
└── documentation/modele_de_données/
    ├── services/04_organization.sql           # colonnes, CHECK, index, trigger
    └── migrations/050_services_parent_landing.sql (+ _rollback.sql)   # nouveaux, après accord

usenghor_nuxt/
├── app/composables/usePublicOrganizationApi.ts    # types + getServiceLink
├── app/composables/useServicesApi.ts, app/types/api/organization.ts   # parent_id, landing_path
├── app/pages/admin/organisation/services/index.vue   # modale (parent, page dédiée, erreurs), liste hiérarchique, suppression
├── app/pages/admin/organisation/services/[id].vue    # Informations : parent, page dédiée, pôles
├── app/components/organization/OrganigrammeSection.vue   # pôles sous le parent ; carte → landing_path
├── app/pages/a-propos/organisation/[type]/[slug].vue     # Présentation : parent, page dédiée, bloc Pôles ; onglet Services du secteur : « + n pôle(s) »
├── app/components/AppNavBar.vue                   # label_en / label_ar, navChildLabel
├── app/components/admin/editorial/NavItemsField.vue   # champs Libellé (anglais / arabe)
├── app/components/AppFooter.vue                   # lien Entreprendre à Senghor
├── app/composables/usePeiPage.ts                  # usePeiBreadcrumb exporté et utilisé
├── app/pages/entrepreneuriat/index.vue, activites.vue   # fil d'Ariane via usePeiBreadcrumb (duplications retirées)
├── server/api/__sitemap__/urls.ts                 # URLs secteur / service corrigées, pôles inclus
└── i18n/locales/{fr,en,ar}/{organization-detail,organization,footer}.json

CLAUDE.md, specs/roadmap-pei-entrepreneuriat.md, specs/021-*/tasks.md (T071), specs/023-*/tasks.md (T039, T048, T051), mémoire projet
```

**Structure Decision** : monorepo existant, modifications en place. Pas de nouveau composant ni de nouvelle page. Backend additif, à l'exception de la correction C1, qui ne change que la construction de la réponse et pas sa forme pour les services sans pôle.

## Phase 0 — Research (terminée)

[research.md](research.md) : 10 constats de terrain (dont le défaut de perte de données C1, l'audit existant C2, le formulaire en modale C3, l'état de production C4–C7) et 16 décisions (contraintes R1–R2, correctif et imbrication R3, migration R4, API R5, audit R6, duplication R7, backoffice R8, public R9, menu R10, pied de page R11, liens courts R12, plan du site R13, fil d'Ariane R14, tests R15, mise en ligne R16). Aucun `NEEDS CLARIFICATION`.

## Phase 1 — Design (terminée)

- [data-model.md](data-model.md) — **SQL à valider** : § 3 schéma de référence, § 4 migration 050, § 5 rollback, § 6 test à blanc, § 7 cinq points à confirmer (libellés EN / AR, icône, trigger, portée du rollback, normalisation du JSON du menu).
- [contracts/api.md](contracts/api.md), [contracts/frontend.md](contracts/frontend.md).
- [quickstart.md](quickstart.md).

## Ordre d'implémentation recommandé (pour /speckit-tasks)

1. **Porte d'accord SQL** (data-model § 3–7) ; en attendant, captures et JSON de référence (quickstart § 0).
2. **Correctif C1 d'abord** : test d'intégration qui reproduit la perte, puis lectures secteurs sans mutation. Indépendant du SQL, livrable seul.
3. Après accord : `04_organization.sql`, migration 050 et rollback ; DDE de test locale ; deux passages (quickstart § 1–2).
4. Backend : modèle, schémas et validateur ; `_validate_hierarchy` ; create / update / duplicate ; imbrication `children` ; `parent` / `children` de la fiche ; liens courts ; tests (quickstart § 3).
5. Frontend transverse : types, `getServiceLink`, i18n ×3.
6. US2 backoffice (modale, liste, suppression, `[id].vue`) → US1 public (organigramme, fiche) → US3 (menu `label_en` / `label_ar` + `NavItemsField`, pied de page, `/r/pei`) → US4 (`usePeiBreadcrumb`, retrait des duplications) → US5 (plan du site).
7. Validation quickstart § 4–9 ; `pnpm build` ; captures après.
8. US6 : mise en ligne § 10 a → j, **une action à la fois après accord** ; CLAUDE.md, roadmap, mémoire.

## Complexity Tracking

| Écart | Pourquoi | Alternative plus simple écartée |
|---|---|---|
| Trigger PL/pgSQL en plus de la validation backend | La règle « un niveau, même secteur » doit rester vraie face aux écritures concurrentes, aux migrations et au SQL manuel ; la contrainte CHECK ne peut pas lire d'autres lignes | Validation backend seule : deux enregistrements simultanés ou un `UPDATE` manuel peuvent créer un second niveau |
| Copie locale de `slugify` dans le plan du site | Nitro n'importe pas `app/` ; déplacer `slugify` dans `shared/` exposerait à des collisions d'auto-import (7 copies homonymes) | Champ `slug` calculé en Python : normalisation Unicode différente, risque d'URLs divergentes |
| Correctif C1 hors description | Perte de données avérée, et directement déclenchée par la désactivation d'un pôle | Le laisser : un pôle ou un service désactivé serait supprimé à la visite suivante de l'organigramme |
