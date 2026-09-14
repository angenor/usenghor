# Data model — Mini-site public PEI : accueil et « Nos activités » (023)

> **Point de contrôle FR-029** : le SQL du § 3 est la proposition à valider par le responsable du projet **avant** toute écriture de code. Aucune table, colonne ni type nouveau : seulement quatre lignes dans `editorial_contents`.

## 1. Entités lues (existantes, aucune modification)

| Entité | Source | Champs utilisés par le mini-site |
|---|---|---|
| Dispositif (`pei_programs`) | `GET /api/public/entrepreneurship/programs` → `PeiProgramPublic[]` | `code`, `sigle`, `phase`, `title(_en/_ar)`, `tagline(_en/_ar)`, `content_html` (`content_en_html`, `content_ar_html`), `highlight(_en/_ar)`, `color`, `cover_image_url`, `display_order` |
| Partenaire du pôle (`pei_partners` ⋈ `partners`) | `GET /api/public/entrepreneurship/partners` → `PeiPartnerFamilyPublic[]` (3 familles, ordre fixe) | `family`, `partners[].{name, logo_url, website, description(_en/_ar), display_order}` |
| Contenu éditorial « Entrepreneuriat » (`editorial_contents`) | `GET /api/public/editorial/contents?keys=…` via `useEditorialContent('entrepreneurship')` | 43 clés existantes (021) + 4 clés ajoutées (§ 3) ; une valeur FR par clé |
| Actualité (`news` ⋈ `news_services`) | `GET /api/public/news?service_id=…&limit=3` → `NewsDisplay[]` | `slug`, `title(_en/_ar)`, `summary(_en/_ar)`, `cover_image_external_id` / `cover_image`, `published_at`, `sector_name`, `service_names`, `project_name` |
| Événement (`events`) | `GET /api/public/events?service_id=…&upcoming=true&order=asc&limit=6` → `EventPublic[]` | `slug`, `title(_en/_ar)`, `start_date`, `end_date`, `venue`, `city`, `is_online`, `cover_image_external_id` |
| Service DDE (`services`) | `GET /api/public/services/{id}` (id = clé `entrepreneurship.dde_service_id`) | `id`, `name`, `sigle` → adresse de la fiche `/a-propos/organisation/service/{slugify(name)}` |

Relations : un dispositif appartient à une phase (`pei_program_phase`) ; un partenaire du pôle appartient à une famille (`pei_partner_family`) ; actualités et événements sont rattachés au service DDE (`news_services.service_external_id`, `events.service_external_id`).

## 2. Règles de présentation dérivées

| Règle | Détail |
|---|---|
| Numérotation des cartes (accueil) | index 1..n sur les dispositifs actifs triés par `display_order` (un dispositif désactivé ne laisse pas de trou) |
| Ordre des blocs (« Nos activités ») | `awareness → status → pre_incubation → incubation → funding → ecosystem` ; une phase sans dispositif actif n'a pas de bloc ; `ecosystem` s'affiche si chips **ou** événements à venir |
| Couleur d'un dispositif | `color ∈ {blue, blue_dark, red, amber, teal}` → classes `PEI_COLOR_CLASSES[color]` (bordure haute, pastille numéro, libellé de phase) ; valeur inconnue → `blue` |
| Chiffres clés | `stats.{1..4}.{value,label}` : une tuile par paire dont `value` non vide ; 0 tuile → panneau masqué ; compteur animé si `value` ~ `^\d+[^\d]*$` |
| Chips de l'écosystème | `activities.ecosystem.items` scindée sur `\n`, lignes vides ignorées |
| Familles de partenaires | ordre fixe `academic, support, international` ; famille vide masquée ; section masquée si les trois sont vides |
| Actualités | 3 plus récentes (`published_at` desc) ; section masquée si 0 |
| Événements | à venir (`start_date ≥ now`), tri asc, 6 au plus ; liste masquée si 0 |
| Fil d'Ariane | 5 niveaux (accueil) / 6 niveaux (activités) ; « DDE » cliquable seulement si le service est résolu |
| Langue | données métier : `localized(obj, base)` (EN/AR → FR → '') ; copie éditoriale : FR (Q1) ; libellés fixes : i18n `pei.*` |

## 3. Migration 047 — clés éditoriales du hero « Nos activités » (à valider)

Fichier : `usenghor_backend/documentation/modele_de_données/migrations/047_pei_activities_hero_keys.sql`

```sql
-- 047 — Clés éditoriales du hero de la page « Nos activités » (mini-site PEI, feature 023)
-- Rejouable : ON CONFLICT (key) DO NOTHING ; ne modifie jamais une valeur existante.
BEGIN;

INSERT INTO editorial_contents (key, value, value_type, category_id, description)
SELECT v.key, v.value, v.value_type::editorial_value_type,
       (SELECT id FROM editorial_categories WHERE code = 'values'), v.description
FROM (VALUES
    ('entrepreneurship.activities.hero.badge',
     'Nos activités', 'text',
     'Badge du hero de la page « Nos activités » du mini-site PEI'),
    ('entrepreneurship.activities.hero.title',
     'Un parcours, de l''idée à l''entreprise', 'text',
     'Titre du hero de la page « Nos activités »'),
    ('entrepreneurship.activities.hero.subtitle',
     'Le PEI a structuré son intervention autour d''un parcours de croissance complet, conçu pour transformer une simple intuition en une entreprise viable et structurée.', 'text',
     'Sous-titre du hero de la page « Nos activités »'),
    ('entrepreneurship.activities.hero.image',
     '', 'text',
     'Image de fond du hero de la page « Nos activités » (identifiant de média ; vide = hero à motif)')
) AS v(key, value, value_type, description)
ON CONFLICT (key) DO NOTHING;

COMMIT;
```

Retour arrière : `047_pei_activities_hero_keys_rollback.sql`

```sql
BEGIN;
DELETE FROM editorial_contents
WHERE key IN (
    'entrepreneurship.activities.hero.badge',
    'entrepreneurship.activities.hero.title',
    'entrepreneurship.activities.hero.subtitle',
    'entrepreneurship.activities.hero.image'
);
COMMIT;
```

Ordre de retour arrière : 047 est indépendante de 046 ; le rollback 045 (qui supprime `entrepreneurship.%`) couvre aussi ces clés — le rollback 047 n'est nécessaire que si 045 reste en place.

Commandes : local `docker exec -i usenghor_postgres psql -U usenghor -d usenghor < …/047_pei_activities_hero_keys.sql` ; production `docker exec -i usenghor_db psql -U usenghor -d usenghor < …`. Le schéma de référence (`services/12_editorial.sql`, `99_data_init.sql`) ne seed pas les clés éditoriales `entrepreneurship.*` : aucun fichier de référence à modifier (convention de 045).

Le contrat complet des 47 clés est dans [contracts/editorial-keys.md](contracts/editorial-keys.md).

## 4. Backend — filtre public des événements (aucun changement de schéma)

| Élément | Avant | Après |
|---|---|---|
| `GET /api/public/events` (`routers/public/events.py`) | `from_date`, `to_date`, `campus_id`, `upcoming` | + `service_id: str \| None` (UUID du service), + `order: "asc" \| "desc"` (défaut `desc`) |
| `ContentService.get_events` (`services/content_service.py`) | `search, status, event_type, from_date, to_date, campus_id` | + `service_id`, + `order` ; `where(Event.service_external_id == service_id)` ; `order_by(start_date asc/desc)` |
| `EventPublic` | inchangé | inchangé |

## 5. Frontend — types

Aucun type nouveau côté API. Ajouts :

- `types/api/editorial.ts` : 4 littéraux dans `ValueSectionKey`.
- `usePublicEventsApi.ts` : `listPublishedEvents(params)` accepte `service_id?: string`, `order?: 'asc' | 'desc'`.
- `utils/pei-presentation.ts` : `PEI_PHASE_ORDER`, `PEI_PHASE_ANCHORS`, `PEI_COLOR_CLASSES`, `PEI_FAMILY_ORDER`.
- `components/page/Hero.vue` : `images?: string[]`, `badge?: string`, `badgeIcon?: string`, `actions?: { label; to; variant?; icon? }[]`.
- `components/actualites/NewsCard.vue` : `item: NewsDisplay`, `showAssociations?: boolean`, `imageVariant?: 'low' | 'medium'`.
- `components/entrepreneurship/StatsPanel.vue` : `title: string`, `stats: { value: string; label: string }[]`.
