# Research: 013-program-partners

**Date**: 2026-03-25

## Decision 1: Infrastructure backend existante

**Decision**: Réutiliser les endpoints admin et le service existants, enrichir avec un endpoint public.

**Rationale**: La table `program_partners`, les endpoints admin CRUD (`/api/admin/programs/{id}/partners`), et les méthodes du `AcademicService` (get_program_partners, add_partner_to_program, update_program_partner, remove_partner_from_program) existent déjà. Il manque uniquement :
- Un endpoint public pour récupérer les partenaires enrichis (nom, logo, site web) d'une formation
- L'enrichissement du schéma `ProgramPublicWithDetails` ou un endpoint dédié
- Le service ne joint pas la table `partners` pour obtenir les détails

**Alternatives considered**:
- Inclure les partenaires directement dans `ProgramPublicWithDetails` via une relation SQLAlchemy → Plus complexe, nécessite un refactoring du modèle Program et de la query principale
- Endpoint public dédié `GET /api/public/programs/{slug}/partners` → Plus simple, cohérent avec le pattern existant (`/news`, `/media-library`)

**Choix retenu**: Endpoint public dédié, car c'est le pattern établi dans le projet.

## Decision 2: Pattern UI admin pour la sélection de partenaires

**Decision**: Utiliser un pattern de sélection depuis une liste existante (dropdown/search), différent du pattern skills/career qui crée de nouvelles entités.

**Rationale**: Les skills et career opportunities sont créés inline (modal avec titre + description). Les partenaires existent déjà dans le système - il faut les sélectionner, pas les créer. Le pattern doit être :
1. Charger tous les partenaires actifs via `getAllPartners()`
2. Filtrer ceux déjà associés
3. Permettre la recherche par nom
4. Ajouter/retirer avec appel API immédiat (comme skills)

**Alternatives considered**:
- Modal de recherche avec autocomplétion → Plus complexe, surdimensionné pour ~50 partenaires max
- Dropdown simple avec filtre texte → Suffisant et cohérent

## Decision 3: Affichage public - Positionnement

**Decision**: Afficher les partenaires dans le contenu principal (colonne gauche), après la section "Débouchés professionnels".

**Rationale**: Le "bloc d'appel" est dans la sidebar droite (sticky). Les logos de partenaires nécessitent de l'espace horizontal pour un affichage correct. Le pattern `ProjetPartenaires.vue` (grille 3 colonnes) est réutilisable. Position naturelle dans le flux : Compétences → Programme → Débouchés → **Partenaires**.

**Alternatives considered**:
- Dans la sidebar sous l'appel → Trop étroit pour des logos, mauvais rendu mobile
- Composant séparé dédié → `ProjetPartenaires.vue` existe déjà avec un layout similaire

## Decision 4: Enrichissement des données partenaires

**Decision**: Créer un endpoint public qui joint `program_partners` avec `partners` pour retourner les détails enrichis.

**Rationale**: Le service actuel `get_program_partners()` retourne uniquement `partner_external_id` et `partnership_type`. Pour l'affichage public, il faut : nom, logo (via `logo_external_id`), site web, type. L'enrichissement doit être fait côté backend (pas N+1 requêtes frontend).

**Schema de réponse suggéré**:
```
ProgramPartnerPublic:
  - partner_external_id: str
  - name: str
  - logo_external_id: str | None
  - website: str | None
  - partnership_type: str | None
  - partner_type: str (charter_operator, campus_partner, etc.)
```

## Decision 5: Composant d'affichage public réutilisable

**Decision**: Créer un composant `ProgramPartners.vue` inspiré de `ProjetPartenaires.vue`.

**Rationale**: `ProjetPartenaires.vue` a le bon layout (grille responsive, logos + noms, liens), mais est couplé aux données projets. Un composant dédié aux formations permet l'adaptation (titre de section, gestion du type de partenariat).

**Alternatives considered**:
- Réutiliser directement `ProjetPartenaires.vue` avec des props → Structure de données différente (project partners vs program partners)
- Composant générique partagé → Over-engineering pour 2 usages
