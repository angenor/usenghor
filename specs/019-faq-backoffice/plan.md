# Implementation Plan: Page FAQ managée dans le backoffice

**Branch**: `019-faq-backoffice` | **Date**: 2026-05-02 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/019-faq-backoffice/spec.md`

## Summary

Ajouter une page publique `/faq` (trilingue FR/EN/AR-RTL, accordéon, recherche client, ancres URL, JSON-LD `FAQPage` SSR) alimentée par une nouvelle ressource managée dans le backoffice. La FAQ s'organise en catégories ordonnables et en entrées (question + réponse riche) ordonnables au sein de chaque catégorie, avec statut de publication. Le contenu riche réutilise le pipeline existant TOAST UI Editor (double colonne `*_html` + `*_md` par langue). L'authentification admin réutilise la permission de gestion de contenu existante (mêmes éditeurs que news/events). Toutes les opérations sont tracées via `audit_logs`.

**Approche technique validée par les clarifications (Q1–Q5) et la recherche (D1–D8)** :

1. Nouveau service SQL `13_faq.sql` (deux tables `faq_categories`, `faq_entries`) inclus dans `main.sql`. Migration `033_faq.sql` (forward) + rollback. Convention double colonne `*_html`/`*_md` par langue suivie strictement.
2. Backend FastAPI : modèles SQLAlchemy + schémas Pydantic + 2 routeurs (admin authentifié JWT avec permission `content:manage`, public lecture seule). Endpoint public unique `/api/public/faq` retournant l'arborescence (catégories actives + entrées publiées) en une seule requête (cohérent avec recherche client en Q2).
3. Frontend Nuxt 4 :
   - Page publique `app/pages/faq.vue` : accordéon, filtre catégorie, recherche client temps réel, gestion ancre `#slug`, bouton « copier le lien », rendu via `RichTextRenderer.vue`, JSON-LD injecté avec `useHead`/`useSeoMeta`.
   - Pages admin `app/pages/admin/faq/index.vue` (liste + DnD) et `app/pages/admin/faq/[id].vue` (édition trilingue avec `ToastUIEditor.client.vue`), plus gestion des catégories en page dédiée.
   - Composables `useFaqApi.ts` (admin authentifié) et `usePublicFaqApi.ts` (public).
   - i18n : nouveaux fichiers `fr/faq.json`, `en/faq.json`, `ar/faq.json`.
4. Repli silencieux vers FR si traduction manquante (Q5) — implémenté côté backend dans le sérialiseur public et côté frontend pour cohérence.
5. Slug dérivé automatiquement du libellé FR à la création (éditable manuellement), unique sur `faq_entries`. Catégorie par défaut « Général » (`code='general'`) injectée dans `99_data_init.sql`.

## Technical Context

**Language/Version**: TypeScript 5.x (Nuxt 4 / Vue 3 Composition API) côté frontend, Python 3.14 (FastAPI) côté backend.
**Primary Dependencies**: Nuxt 4, Vue 3, Tailwind CSS, `@nuxtjs/i18n`, TOAST UI Editor 3.2.2 ; FastAPI, SQLAlchemy (async), Pydantic v2, `asyncpg`. Pas de nouvelle dépendance ajoutée.
**Storage**: PostgreSQL 16 via Docker (`usenghor_postgres` local, `usenghor_db` prod). Nouvelles tables : `faq_categories`, `faq_entries`. Réutilisation : `users` (FK auteur), `audit_logs` (traces), permissions/rôles existants.
**Testing**: pytest côté backend (existant) — tests d'intégration pour endpoints admin/public + tests de service pour l'arbre public. Tests manuels via `quickstart.md` côté frontend.
**Target Platform**: navigateurs desktop + mobile (Nuxt 4 SSR/SSG), backend Linux Docker.
**Project Type**: web (monorepo front + back).
**Performance Goals**: SC-005 (interactif < 2 s sur 4G avec 100 questions). Endpoint public `/api/public/faq` < 200 ms p95 (lecture en une requête, pas de N+1).
**Constraints**:
- FR par défaut + repli silencieux (Q5).
- Recherche purement client (Q2) → endpoint public renvoie tout publié en un appel.
- JSON-LD `FAQPage` injecté en SSR (Q3) → Nuxt `useHead` côté serveur, pas de génération client uniquement.
- Ancres URL stables (Q4) → slug unique, immuable après publication recommandé (modifiable mais avec avertissement admin).
- Permission existante de gestion de contenu réutilisée (Q1) — pas de nouvelle permission.
- Nommage fichiers `[a-z0-9_-]` uniquement (CLAUDE.md).
- Source de vérité SQL : `13_faq.sql` mis à jour AVANT le code Python/TS.
**Scale/Scope**: 5 à ~150 questions à terme, 5 à 15 catégories. Charge négligeable côté serveur (< 1 req/s en moyenne, peak admissible < 50 req/s).

## Constitution Check

Le fichier `.specify/memory/constitution.md` est un template non renseigné pour ce projet. Aucun principe formel ne contraint cette feature spécifique.

**Gates applicables depuis `CLAUDE.md` et `~/.claude/rules/common/`** :

| Gate | État | Note |
|------|------|------|
| Source de vérité SQL mise à jour avant le code | OK | `13_faq.sql` créé + inclus dans `main.sql` ; migration `033_faq.sql` livrée avant backend. |
| Nommage fichiers `[a-z0-9_-]` | OK | `13_faq.sql`, `033_faq.sql`, `033_faq_rollback.sql`, `useFaqApi.ts`. |
| Français avec accents dans contenus/commentaires | OK | Libellés UI, messages, données seed (catégorie « Général »). |
| Convention `*_fr/_en/_ar` pour le multilingue | OK | Question + réponse en triple colonne ; pour la réponse riche, double colonne `*_html`/`*_md` par langue (6 colonnes). |
| Sécurité — assainissement HTML | OK | FR-006 réutilise le pipeline TOAST UI existant. |
| Endpoints public vs admin | OK | `/api/public/faq` (anonyme) vs `/api/admin/faq/*` (JWT + permission `content:manage`). |
| Audit | OK | Toutes mutations admin tracées dans `audit_logs` (FR-015). |
| Testing 80 % coverage commun | WARN | Tests d'intégration backend ciblés (CRUD + arbre public + repli FR). Tests frontend manuels via quickstart. |
| Pas de hardcoded secrets | OK | N/A pour cette feature. |
| Code review avant merge | TODO | À déclencher via l'agent `code-reviewer` après implémentation (et `database-reviewer` sur les scripts SQL). |

Aucune violation justifiée requise ; pas d'entrée dans « Complexity Tracking ».

## Project Structure

### Documentation (this feature)

```text
specs/019-faq-backoffice/
├── spec.md                       # Spec clarifiée (Q1–Q5)
├── plan.md                       # Ce fichier
├── research.md                   # Phase 0 — 8 décisions techniques
├── data-model.md                 # Phase 1 — schéma détaillé
├── contracts/
│   ├── public-faq-api.md         # Phase 1 — endpoint public
│   └── admin-faq-api.md          # Phase 1 — endpoints admin (catégories + entrées)
├── quickstart.md                 # Phase 1 — procédure locale & prod
├── checklists/
│   └── requirements.md           # Validation qualité (créée à /speckit.specify)
└── tasks.md                      # Phase 2 — à générer par /speckit.tasks
```

### Source Code (repository root)

Monorepo existant, deux moitiés :

```text
usenghor_backend/
├── app/
│   ├── models/
│   │   └── faq.py                          # [NEW] FaqCategory, FaqEntry
│   ├── schemas/
│   │   └── faq.py                          # [NEW] *Create/Update/Read/Public/Tree
│   ├── services/
│   │   └── faq_service.py                  # [NEW] CRUD + arbre public + repli FR
│   ├── routers/
│   │   ├── admin/
│   │   │   └── faq.py                      # [NEW] /api/admin/faq/* (categories + entries)
│   │   └── public/
│   │       └── faq.py                      # [NEW] /api/public/faq
│   └── main.py                             # [MODIFY] register routers
└── documentation/modele_de_données/
    ├── services/
    │   ├── 13_faq.sql                      # [NEW] tables faq_categories, faq_entries
    │   ├── main.sql                        # [MODIFY] +\i 13_faq.sql
    │   └── 99_data_init.sql                # [MODIFY] insert catégorie 'general'
    └── migrations/
        ├── 033_faq.sql                     # [NEW] migration forward
        └── 033_faq_rollback.sql            # [NEW] rollback

usenghor_nuxt/
├── app/
│   ├── components/
│   │   ├── faq/
│   │   │   ├── FaqAccordion.vue            # [NEW] composant public principal
│   │   │   ├── FaqAccordionItem.vue        # [NEW] item ouvrable, bouton copier-lien
│   │   │   ├── FaqSearchBar.vue            # [NEW] champ recherche client
│   │   │   ├── FaqCategoryFilter.vue       # [NEW] sélection catégorie
│   │   │   └── admin/
│   │   │       ├── FaqEntryForm.vue        # [NEW] form trilingue + ToastUIEditor
│   │   │       ├── FaqEntryList.vue        # [NEW] liste DnD
│   │   │       ├── FaqCategoryForm.vue     # [NEW] form trilingue catégorie
│   │   │       └── FaqCategoryList.vue     # [NEW] liste DnD catégories
│   │   ├── ToastUIEditor.client.vue        # [NO CHANGE] (réutilisé)
│   │   └── RichTextRenderer.vue            # [NO CHANGE] (réutilisé)
│   ├── composables/
│   │   ├── useFaqApi.ts                    # [NEW] admin authentifié
│   │   └── usePublicFaqApi.ts              # [NEW] public anonyme
│   ├── pages/
│   │   ├── faq.vue                         # [NEW] page publique /faq
│   │   └── admin/
│   │       └── faq/
│   │           ├── index.vue               # [NEW] dashboard liste questions + onglet catégories
│   │           ├── nouveau.vue             # [NEW] création
│   │           └── [id].vue                # [NEW] édition
│   └── types/api/
│       └── faq.ts                          # [NEW] FaqCategoryRead, FaqEntryRead, FaqTree
└── i18n/locales/
    ├── fr/faq.json                         # [NEW]
    ├── en/faq.json                         # [NEW]
    └── ar/faq.json                         # [NEW]
```

**Structure Decision**: Option « Web application (frontend + backend) ». Monorepo existant. Une nouvelle paire de routes (public + admin), un nouveau service SQL, deux nouvelles tables. L'ensemble suit strictement les conventions des features récentes (014, 018) : routeurs publics dans `routers/public/`, admin dans `routers/admin/`, frontend pages publiques à la racine + admin sous `pages/admin/`.

## Complexity Tracking

Aucune violation de gate justifiée. Ne pas remplir.

## Suites du workflow

- **Phase 2** : exécuter `/speckit.tasks` pour générer `tasks.md` avec les tâches atomiques (SQL source + migration → backend models/schemas/services/routers → frontend composables/pages/components → i18n → QA manuelle).
- **Implémentation** : suivre l'ordre imposé par CLAUDE.md — SQL source + migrations **avant** les modifications Python/TS.
- **Revue** : invoquer l'agent `code-reviewer` après implémentation ; `database-reviewer` recommandé sur `13_faq.sql` et `033_faq.sql` ; `security-reviewer` sur les routeurs admin (auth + audit).
