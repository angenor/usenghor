# Implementation Plan: Album médiathèque « Gouvernance » pour les textes fondateurs

**Branch**: `018-governance-media-album` | **Date**: 2026-04-16 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/018-governance-media-album/spec.md`

## Summary

Migrer les documents fondateurs de la page gouvernance (aujourd'hui stockés en JSON dans `editorial_contents`) vers un vrai album médiathèque avec slug `gouvernance`, exposé publiquement via l'API albums existante, tout en préservant l'affichage en flip cards de la page `/a-propos/gouvernance`.

**Approche technique validée par les clarifications (Q1–Q5) et la recherche (D1–D8)** :

1. Enrichir le schéma `media` d'une colonne `thumbnail_url VARCHAR(500) NULL` pour aligner le backend sur le contrat TS existant (dette technique pré-feature).
2. Fournir un script SQL idempotent (`032_gouvernance_album.sql`) qui crée l'album, extrait la liste depuis `editorial_contents` via `jsonb_array_elements`, upsert les `media` et les liens `album_media`. L'idempotence et le rollback ciblé s'appuient sur l'URL source (`media.url`).
3. Mettre à jour le frontend `gouvernance.vue` pour consommer `usePublicAlbumsApi().getAlbumBySlug('gouvernance')` via un mapper inline vers l'interface existante `FoundingDocument`. Le composant `FoundingTextsSection.vue` reçoit ses données inchangées dans la forme, mais gagne un bouton « Prévisualiser » qui ouvre `MediaFilePreviewModal`.
4. Déprécier côté admin éditorial le champ JSON `governance.foundingTexts.documents` (`editable: false` + note + lien vers `/admin/mediatheque/albums`).
5. Aucun nouvel endpoint d'API ; seule extension : ajout du champ nullable `thumbnail_url` dans les schémas Pydantic `Media*` et `CoverMedia`.

## Technical Context

**Language/Version**: TypeScript 5.x (Nuxt 4 / Vue 3 Composition API) côté frontend, Python 3.14 (FastAPI) côté backend.
**Primary Dependencies**: Nuxt 4, Vue 3, Tailwind CSS, `@nuxtjs/i18n` ; FastAPI, SQLAlchemy (async), Pydantic v2, `asyncpg`. Pas de nouvelle dépendance ajoutée.
**Storage**: PostgreSQL 16 via Docker (`usenghor_postgres` local, `usenghor_db` prod). Tables impactées : `media`, `albums`, `album_media`. Lecture seule de `editorial_contents` au moment de la migration.
**Testing**: pytest côté backend (existant), tests manuels via `quickstart.md` côté frontend (pas de suite E2E déployée pour cette feature).
**Target Platform**: navigateurs desktop + mobile (Nuxt 4 SSR/SSG), backend Linux Docker.
**Project Type**: web (monorepo front + back).
**Performance Goals**: pas d'exigence nouvelle ; l'endpoint `albums/by-slug` répond en < 200 ms p95 sur prod (état actuel, mesuré sur les autres albums).
**Constraints**:
- Pas de nouvel endpoint public (FR-023).
- Aucun changement d'API cassant (FR-022).
- Migration idempotente + rollback ciblé par URL (Q1, FR-005/FR-006).
- Contenu documentaire FR-only pour cette itération (A1, Q3).
- Noms de fichiers en `[a-z0-9_-]` uniquement (convention CLAUDE.md).
**Scale/Scope**: ~5–15 documents fondateurs (ordre de grandeur actuel), album unique, impact BDD minimal.

## Constitution Check

Le fichier `.specify/memory/constitution.md` est un template non renseigné pour ce projet. Aucun principe formel ne contraint cette feature spécifique.

**Gates applicables depuis `CLAUDE.md` et `~/.claude/rules/common/`** :

| Gate | État | Note |
|------|------|------|
| Source de vérité SQL mise à jour avant le code | ✅ | `03_media.sql` modifié + migration `032_*.sql` livrée avant backend/frontend. |
| Nommage fichiers `[a-z0-9_-]` | ✅ | `032_gouvernance_album.sql`, `032_gouvernance_album_rollback.sql`. |
| Français avec accents dans contenus/commentaires | ✅ | Description d'album, messages d'état vide, notes admin. |
| Pas de nouveaux endpoints | ✅ | FR-023 respecté. |
| Testing 80 % coverage commun | ⚠️ | Feature très légère (mapping + SQL). Tests unitaires recommandés pour le mapper ; vérification manuelle via `quickstart.md` pour le flux complet. |
| Code review avant merge | 🕒 | À déclencher via l'agent `code-reviewer` après implémentation. |
| Pas de hardcoded secrets | ✅ | N/A pour cette feature. |

Aucune violation justifiée requise ; pas d'entrée dans « Complexity Tracking ».

## Project Structure

### Documentation (this feature)

```text
specs/018-governance-media-album/
├── spec.md                       # Spec clarifiée (Q1–Q5)
├── plan.md                       # Ce fichier
├── research.md                   # Phase 0 — 8 décisions techniques
├── data-model.md                 # Phase 1 — schéma détaillé et logique de migration
├── contracts/
│   └── public-albums-api.md      # Phase 1 — contrats API existants + enrichissements
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
│   │   └── media.py                       # [MODIFY] +thumbnail_url
│   ├── schemas/
│   │   └── media.py                       # [MODIFY] +thumbnail_url dans Media*/CoverMedia
│   ├── services/
│   │   └── media_service.py               # [VERIFY/MODIFY] tri display_order pour cover_media
│   └── routers/public/
│       └── albums.py                      # [NO CHANGE] (endpoints réutilisés)
└── documentation/modele_de_données/
    ├── services/
    │   └── 03_media.sql                   # [MODIFY] +colonne thumbnail_url
    └── migrations/
        ├── 032_gouvernance_album.sql           # [NEW] migration forward
        └── 032_gouvernance_album_rollback.sql  # [NEW] rollback

usenghor_nuxt/
├── app/
│   ├── components/
│   │   ├── governance/
│   │   │   └── FoundingTextsSection.vue   # [MODIFY] bouton « Prévisualiser » + emit
│   │   └── media/
│   │       └── MediaFilePreviewModal.vue  # [NO CHANGE] (réutilisé tel quel)
│   ├── composables/
│   │   ├── usePublicAlbumsApi.ts          # [NO CHANGE]
│   │   └── editorial-pages-config.ts      # [MODIFY] editable:false + note dépréciation
│   ├── pages/
│   │   └── a-propos/
│   │       └── gouvernance.vue            # [MODIFY] API + mapper + modal
│   └── types/api/
│       └── media.ts                       # [VERIFY] thumbnail_url sur MediaRead/CoverMedia
└── i18n/locales/
    ├── fr/governance.json                 # [MODIFY] +preview, +emptyState
    ├── en/governance.json                 # [MODIFY] +preview, +emptyState
    └── ar/governance.json                 # [MODIFY] +preview, +emptyState
```

**Structure Decision**: Option « Web application (frontend + backend) ». Monorepo existant, aucune nouvelle arborescence. L'ensemble des modifications reste localisé dans les dossiers déjà établis ; aucune nouvelle route/page/composant créé.

## Complexity Tracking

Aucune violation de gate justifiée. Ne pas remplir.

## Suites du workflow

- **Phase 2** : exécuter `/speckit.tasks` pour générer `tasks.md` avec les tâches atomiques (migration SQL, backend, frontend, i18n, QA manuelle).
- **Implémentation** : suivre l'ordre imposé par CLAUDE.md — SQL source + migrations **avant** les modifications Python/TS.
- **Revue** : invoquer l'agent `code-reviewer` après implémentation ; passage par `database-reviewer` recommandé sur les scripts SQL.
