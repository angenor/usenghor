# Research: Page Levée de Fonds

**Feature Branch**: `004-fundraising-page`
**Date**: 2026-03-17

## R1: Pattern modèles SQLAlchemy avec rich text et trilingue

**Decision**: Suivre le pattern existant des modèles Content (Event, News) avec `UUIDMixin`, `TimestampMixin`, champs `*_html`/`*_md` pour le rich text, et `external_id` pour les références cross-service (média).

**Rationale**: Le pattern est éprouvé dans le projet (Event, News, Service, Program). Il gère correctement les UUID, les timestamps auto, le rich text dual-column et les références aux médias sans FK directe.

**Alternatives considered**:
- FK directe vers la table media → Rejeté : le projet utilise systématiquement des `external_id` (UUID sans FK) pour les références cross-service
- Champ JSON pour le contenu trilingue → Rejeté : le projet utilise des colonnes séparées `*_fr`/`*_en`/`*_ar` (non trouvé dans les modèles existants, mais présent dans le schéma SQL)

## R2: Pattern ENUM pour le statut à 3 états

**Decision**: Créer un nouveau type ENUM `fundraiser_status` avec les valeurs `draft`, `active`, `completed` (mapping vers brouillon / en cours / terminée).

**Rationale**: Le projet utilise déjà `publication_status` (draft, published, archived) mais notre cycle de vie est différent (3 états spécifiques). Un ENUM dédié est plus clair qu'un détournement de `publication_status`.

**Alternatives considered**:
- Réutiliser `publication_status` avec mapping (draft → brouillon, published → en cours, archived → terminée) → Rejeté : sémantique différente, "archived" ≠ "terminée" (une campagne terminée reste affichée)

## R3: Pattern catégories de contributeurs

**Decision**: Créer un type ENUM `contributor_category` avec les valeurs `state_organization`, `foundation_philanthropist`, `company`.

**Rationale**: Les catégories sont fixes (clarification confirmée). Un ENUM garantit l'intégrité et simplifie le filtrage/groupement côté frontend.

**Alternatives considered**:
- Table de catégories configurable → Rejeté : catégories fixes, pas besoin de complexité supplémentaire
- Champ libre → Rejeté : pas de garantie de cohérence pour le groupement

## R4: Pattern association many-to-many avec le module news

**Decision**: Créer une table de liaison `fundraiser_news` (fundraiser_id FK, news_id UUID sans FK) avec `display_order`.

**Rationale**: Le pattern `album_media` existant utilise des FK + `display_order`. Pour les news, on utilise `news_id` comme UUID sans FK (cohérent avec les `external_id` du projet) puisque les news sont dans le même service content.

**Alternatives considered**:
- FK directe vers news → Acceptable aussi car même base de données, mais on reste cohérent avec le pattern `external_id` utilisé ailleurs

## R5: Pattern routers et services backend

**Decision**: Créer `FundraisingService` dans `app/services/`, des routers admin (`app/routers/admin/fundraisers.py`) et public (`app/routers/public/fundraisers.py`), avec les schemas Pydantic correspondants.

**Rationale**: Pattern identique à ContentService/events/news. Le service encapsule la logique métier, les routers gèrent HTTP/auth/pagination.

## R6: Pattern frontend pages et composables

**Decision**: Créer des pages publiques (`pages/levees-de-fonds/index.vue`, `pages/levees-de-fonds/[slug].vue`), des pages admin (`pages/admin/contenus/levees-de-fonds/`), un composable public et un composable admin, un composant CardFundraiser, et un composant tabs.

**Rationale**: Suit exactement le pattern actualites (list + detail, admin CRUD, composables séparés public/admin).

## R7: Calcul automatique de la somme totale

**Decision**: La somme totale levée sera calculée côté backend via une requête agrégée (SUM) sur les contributions. Pas de champ dupliqué en base — calcul à la volée ou via vue SQL.

**Rationale**: Évite la désynchronisation entre la somme stockée et les contributions réelles. La vue SQL `99_views.sql` existe déjà pour d'autres agrégations.

**Alternatives considered**:
- Champ `total_raised` mis à jour par trigger → Plus performant en lecture mais risque de désynchronisation
- Calcul côté frontend → Rejeté : charge réseau inutile, calcul dupliqué
