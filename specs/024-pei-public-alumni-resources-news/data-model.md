# Data model — Mini-site public PEI : alumni, partenaires, ressources, actualités (024)

> **Point de contrôle FR-024** : le SQL du § 3 est la proposition à valider par le responsable du projet **avant** toute écriture de code. Aucune table, colonne, type ni endpoint nouveau : seulement 26 lignes dans `editorial_contents`.

## 1. Entités lues (existantes, aucune modification)

| Entité | Source | Champs utilisés |
|---|---|---|
| Portraits groupés par cohorte (`pei_laureates` ⋈ `pei_cohorts`) | `GET /api/public/entrepreneurship/laureates` → `PeiLaureatesPublic { groups[], stats }` | `groups[].cohort.{id, code, type, year, label(_en/_ar), focus(_en/_ar), summary_html (_en/_ar), display_order}`, `groups[].laureates[].{id, type, full_name, project_name, department_label(_en/_ar), quote(_en/_ar), photo_url, website_url, linkedin_url, instagram_url, facebook_url, video_url, is_featured, cohort_label(_en/_ar), display_order}` ; `stats` non utilisé (décision : chiffres éditoriaux) |
| Partenaire du pôle (`pei_partners` ⋈ `partners`) | `GET /api/public/entrepreneurship/partners` → `PeiPartnerFamilyPublic[]` (3 familles, ordre fixe) | `family`, `partners[].{id, name, logo_url, description(_en/_ar), website, display_order}` — pas de réseau social |
| Ressource (`pei_resources`) | `GET /api/public/entrepreneurship/resources` → `PeiResourcePublic[]` | `id`, `title(_en/_ar)`, `description(_en/_ar)`, `type` (`document` / `link` / `video`), `media_url`, `url`, `category(_en/_ar)`, `display_order` |
| Service DDE (`services` ⋈ `service_media_library`) | `GET /api/public/services/{id}` (id = clé `entrepreneurship.dde_service_id`) | `id`, `name`, `sigle`, `album_ids[]`, `album_external_id` (repli) |
| Album (`albums` ⋈ `album_media` ⋈ `media`) | `GET /api/public/albums/{id}` via `usePublicAlbumsApi().getAlbumById` → `AlbumWithMedia` | `id`, `title`, `description`, `display_order`, `media_items[].{id, name, alt_text, url, type, mime_type}` |
| Actualité (`news` ⋈ `news_services`) | `GET /api/public/news?service_id=…&page=&limit=12` → `PaginatedResponse<NewsDisplay>` | `items[]` (champs de `ActualitesNewsCard`), `page`, `pages`, `total` |
| Événement (`events`) | `GET /api/public/events?service_id=…&upcoming=true&order=asc&page=&limit=10` (à venir) et `…?service_id=…&to_date=<now>&order=desc&page=&limit=10` (passés) → `PaginatedResponse<EventPublic>` | `slug`, `title(_en/_ar)`, `start_date`, `end_date`, `venue`, `city`, `is_online` ; `page`, `pages` |
| Contenu éditorial « Entrepreneuriat » (`editorial_contents`) | `useEditorialContent('entrepreneurship')` | 47 clés existantes + 26 ajoutées (§ 3) ; réutilisées : `dde_service_id`, `contact.email`, `see.mentor.{title,description,button}`, `hero.title` (nom du pôle pour le JSON-LD) |

Relations : un portrait appartient à une cohorte du même type (`fse` ↔ `fse_laureate`, `see` ↔ `student_entrepreneur`, contrainte 022) ; un partenaire du pôle appartient à une famille ; une ressource référence au plus un média ; un service référence n albums ; actualités et événements sont rattachés au service DDE.

## 2. Règles de présentation dérivées

| Règle | Détail |
|---|---|
| Onglet alumni | `route.query.type === 'student_entrepreneur'` → cohortes `see` ; sinon cohortes `fse` (défaut, adresse canonique sans query) |
| Sections de cohorte | groupes du type courant, ordre de l'API (`cohort.display_order`), uniquement ceux ayant ≥ 1 portrait |
| Ordre des portraits | `is_featured` desc puis `display_order` asc (tri stable, à l'affichage) |
| Sous-titre de cohorte | `t('pei.alumni.cohortYear', { year })` (« Promotion 2025 ») + (` · ` + `focus` localisé si non vide) ; badge focus si `focus` non vide ; bilan `summary_html` localisé rendu si non vide |
| Liens d'un portrait | icône rendue seulement si l'URL est non vide et commence par `http(s)://` ; ordre site, LinkedIn, Instagram, Facebook, vidéo |
| Bandeau alumni | paires `alumni.stats.{1,2,3}.{value,label}` avec `value` non vide ; 0 paire → masqué ; compteur animé si `isNumericStat(value)` |
| Encart mentor | affiché si `see.mentor.title` **et** `contact.email` non vides ; bouton `mailto:{email}?subject={pei.alumni.mentorSubject}` |
| Familles de partenaires | ordre `academic, support, international` ; famille vide masquée ; page vide → état vide |
| Carte partenaire | logo ou nom ; description localisée (`line-clamp-4`) si non vide ; lien site si `website` |
| Albums DDE | `album_ids` (repli `album_external_id`) → albums non nuls avec ≥ 1 média ; bloc masqué si 0 ou DDE non identifiée |
| Groupes de la boîte à outils | clé = `category` FR normalisée (`trim`, minuscules, espaces réduits) ; ordre = première apparition ; intitulé = `category` localisé de la première ressource ; sans catégorie → dernier groupe, intitulé i18n |
| Action d'une ressource | `document` → `media_url + '?download=1'` (masquée si `media_url` nul) ; `link` / `video` → `url` en nouvel onglet ; vignette YouTube si `youTubeId(url)` |
| Actualités | filtre `service_id` serveur, tri `published_at` desc (défaut API), lots de 12, « Voir plus » tant que `page < pages` |
| Événements | à venir : `upcoming=true&order=asc` (`start_date ≥ now`), lots de 10 ; passés : `to_date=<now ISO>&order=desc` (`start_date ≤ now`, comme `getPastEvents()` du site), lots de 10 ; aucun filtre client (filtres serveur complémentaires : un événement commencé est « passé ») ; sous-bloc vide masqué |
| État vide de page | alumni : 0 section pour le type courant ; partenaires : 3 familles vides ; ressources : 0 album et 0 ressource ; actualités : 0 actualité et 0 événement (ou DDE non identifiée) |
| Fil d'Ariane | 6 niveaux : Accueil › À propos › Organisation › DDE (lien si service résolu) › Pôle › rubrique (`pei.nav.{alumni,partners,resources,news}`) |
| Hero | `text('<page>.hero.title') || t('pei.seo.<page>Title')` ; sous-titre et badge affichés si non vides ; image via `getMediaUrl(id, 'medium')` ou motif |

## 3. Migration 048 — SQL à valider (FR-024)

> **Décision (2026-09-14)** : SQL accepté par le responsable, textes tels quels. Migration jouée deux fois en local (26 insertions puis 0) : 73 lignes `entrepreneurship.%` en base locale (47 avant ; la base locale n'avait pas la ligne supplémentaire décrite par la 047).

Fichiers : `usenghor_backend/documentation/modele_de_données/migrations/048_pei_public_pages_keys.sql` et `048_pei_public_pages_keys_rollback.sql`. Même forme que 047 : rejouable, jamais d'écrasement d'une valeur modifiée.

```sql
-- =============================================================================
-- Migration 048 : Clés éditoriales des pages alumni, partenaires, ressources
--                 et actualités du mini-site PEI
-- =============================================================================
-- Feature 024-pei-public-alumni-resources-news. Dépend de 045 (catégorie values).
-- Effets : 26 lignes dans editorial_contents. Aucune table, colonne ni type nouveau.
-- Rejouable : ON CONFLICT (key) DO NOTHING. Rollback : 048_pei_public_pages_keys_rollback.sql
-- =============================================================================

BEGIN;

INSERT INTO editorial_contents (key, value, value_type, category_id, description)
SELECT v.key, v.value, v.value_type::editorial_value_type,
       (SELECT id FROM editorial_categories WHERE code = 'values'), v.description
FROM (VALUES
    -- Page « Nos alumni » : hero
    ('entrepreneurship.alumni.hero.badge',     'Portraits et témoignages', 'text', 'Badge du hero de la page « Nos alumni » du mini-site PEI'),
    ('entrepreneurship.alumni.hero.title',     'Nos alumni et lauréats', 'text', 'Titre du hero de la page « Nos alumni »'),
    ('entrepreneurship.alumni.hero.subtitle',  'Ils sont passés de l''idée au projet, puis du projet à l''entreprise. Découvrez les lauréats du Fonds de Soutien à l''Entrepreneuriat et les étudiants-entrepreneurs de Senghor.', 'text', 'Sous-titre du hero de la page « Nos alumni »'),
    ('entrepreneurship.alumni.hero.image',     '', 'text', 'Image de fond du hero de la page « Nos alumni » (identifiant de média ; vide = hero à motif)'),
    -- Page « Nos alumni » : bandeau de chiffres
    ('entrepreneurship.alumni.stats.1.value',  '15', 'text', 'Bandeau alumni — chiffre 1 (valeur)'),
    ('entrepreneurship.alumni.stats.1.label',  'projets financés depuis 2023', 'text', 'Bandeau alumni — chiffre 1 (libellé)'),
    ('entrepreneurship.alumni.stats.2.value',  '5 000 €', 'text', 'Bandeau alumni — chiffre 2 (valeur)'),
    ('entrepreneurship.alumni.stats.2.label',  'de subvention d''amorçage maximum', 'text', 'Bandeau alumni — chiffre 2 (libellé)'),
    ('entrepreneurship.alumni.stats.3.value',  '3', 'text', 'Bandeau alumni — chiffre 3 (valeur)'),
    ('entrepreneurship.alumni.stats.3.label',  'cohortes, dont les alumni sont mentors', 'text', 'Bandeau alumni — chiffre 3 (libellé)'),
    -- Page « Nos alumni » : titres de section par onglet
    ('entrepreneurship.alumni.fse.badge',      'Lauréats FSE', 'text', 'Badge de la section des lauréats FSE'),
    ('entrepreneurship.alumni.fse.title',      'Portraits de lauréats et témoignages', 'text', 'Titre de la section des lauréats FSE'),
    ('entrepreneurship.alumni.see.badge',      'Étudiants entrepreneurs', 'text', 'Badge de la section des étudiants-entrepreneurs'),
    ('entrepreneurship.alumni.see.title',      'Portraits d''étudiants-entrepreneurs', 'text', 'Titre de la section des étudiants-entrepreneurs'),
    -- Page « Nos partenaires » : hero
    ('entrepreneurship.partners.hero.badge',    'Nos partenaires', 'text', 'Badge du hero de la page « Nos partenaires »'),
    ('entrepreneurship.partners.hero.title',    'Un écosystème d''appui', 'text', 'Titre du hero de la page « Nos partenaires »'),
    ('entrepreneurship.partners.hero.subtitle', 'Institutions académiques, organisations d''appui et organisations internationales : les partenaires qui accompagnent le Pôle Entrepreneuriat et Innovation.', 'text', 'Sous-titre du hero de la page « Nos partenaires »'),
    ('entrepreneurship.partners.hero.image',    '', 'text', 'Image de fond du hero de la page « Nos partenaires » (identifiant de média ; vide = hero à motif)'),
    -- Page « Nos ressources » : hero
    ('entrepreneurship.resources.hero.badge',    'Nos ressources', 'text', 'Badge du hero de la page « Nos ressources »'),
    ('entrepreneurship.resources.hero.title',    'Médiathèque et boîte à outils', 'text', 'Titre du hero de la page « Nos ressources »'),
    ('entrepreneurship.resources.hero.subtitle', 'Revivez les temps forts du pôle en images et retrouvez guides, formulaires et liens utiles pour structurer votre projet.', 'text', 'Sous-titre du hero de la page « Nos ressources »'),
    ('entrepreneurship.resources.hero.image',    '', 'text', 'Image de fond du hero de la page « Nos ressources » (identifiant de média ; vide = hero à motif)'),
    -- Page « Actualités » : hero
    ('entrepreneurship.news.hero.badge',    'Actualités', 'text', 'Badge du hero de la page « Actualités » du pôle'),
    ('entrepreneurship.news.hero.title',    'La vie du pôle', 'text', 'Titre du hero de la page « Actualités » du pôle'),
    ('entrepreneurship.news.hero.subtitle', 'Actualités, événements et temps forts du Pôle Entrepreneuriat et Innovation.', 'text', 'Sous-titre du hero de la page « Actualités » du pôle'),
    ('entrepreneurship.news.hero.image',    '', 'text', 'Image de fond du hero de la page « Actualités » du pôle (identifiant de média ; vide = hero à motif)')
) AS v(key, value, value_type, description)
ON CONFLICT (key) DO NOTHING;

COMMIT;

\echo 'Migration 048_pei_public_pages_keys terminée'
```

```sql
-- Rollback 048 : indépendant de 046 / 047 ; le rollback 045 (entrepreneurship.%) couvre aussi ces clés.
BEGIN;
DELETE FROM editorial_contents
WHERE key IN (
    'entrepreneurship.alumni.hero.badge', 'entrepreneurship.alumni.hero.title',
    'entrepreneurship.alumni.hero.subtitle', 'entrepreneurship.alumni.hero.image',
    'entrepreneurship.alumni.stats.1.value', 'entrepreneurship.alumni.stats.1.label',
    'entrepreneurship.alumni.stats.2.value', 'entrepreneurship.alumni.stats.2.label',
    'entrepreneurship.alumni.stats.3.value', 'entrepreneurship.alumni.stats.3.label',
    'entrepreneurship.alumni.fse.badge', 'entrepreneurship.alumni.fse.title',
    'entrepreneurship.alumni.see.badge', 'entrepreneurship.alumni.see.title',
    'entrepreneurship.partners.hero.badge', 'entrepreneurship.partners.hero.title',
    'entrepreneurship.partners.hero.subtitle', 'entrepreneurship.partners.hero.image',
    'entrepreneurship.resources.hero.badge', 'entrepreneurship.resources.hero.title',
    'entrepreneurship.resources.hero.subtitle', 'entrepreneurship.resources.hero.image',
    'entrepreneurship.news.hero.badge', 'entrepreneurship.news.hero.title',
    'entrepreneurship.news.hero.subtitle', 'entrepreneurship.news.hero.image'
);
COMMIT;
\echo 'Rollback 048_pei_public_pages_keys terminé'
```

Textes des heros partenaires / ressources / actualités : proposés (non dessinés dans les maquettes ; l'accueil fournit « Un écosystème d'appui » et « La vie du pôle »). Modifiables en backoffice après migration. En production : `docker exec -i usenghor_db psql -U usenghor -d usenghor < 048_pei_public_pages_keys.sql`.

## 4. Configuration éditoriale (frontend)

`app/composables/editorial-pages-config.ts` — quatre sections ajoutées à `entrepreneurshipPageSections` (après `entrepreneurship-see`, avant `entrepreneurship-settings`) :

| `id` | `name` | Clés | Types |
|---|---|---|---|
| `entrepreneurship-alumni` | Nos alumni | `alumni.hero.{badge,title,subtitle,image}`, `alumni.stats.{1,2,3}.{value,label}`, `alumni.fse.{badge,title}`, `alumni.see.{badge,title}` | text / textarea (subtitle) / image |
| `entrepreneurship-partners-page` | Nos partenaires (page) | `partners.hero.{badge,title,subtitle,image}` | text / textarea / image |
| `entrepreneurship-resources` | Nos ressources | `resources.hero.{badge,title,subtitle,image}` | idem |
| `entrepreneurship-news` | Actualités du pôle | `news.hero.{badge,title,subtitle,image}` | idem |

`app/types/api/editorial.ts` — 26 littéraux ajoutés à `ValueSectionKey` (après `'entrepreneurship.activities.hero.image'`). Total déclaré : 73 clés `entrepreneurship.*`.

## 5. Ajouts de types et d'utilitaires (frontend, additifs)

- `utils/pei-presentation.ts` : `cohortTypeForLaureateType(type)`, `sortLaureatesFeaturedFirst(list)`, `groupResourcesByCategory(resources, localized)`, `youTubeId(url)`, `isHttpUrl(value)`, constante `PEI_LAUREATE_TAB_QUERY = 'type'`.
- `usePeiJsonLd.buildWebPage(params & { type?: 'WebPage' | 'CollectionPage' })`.
- Aucun type d'API nouveau : `PeiLaureatesPublic`, `PeiPartnerFamilyPublic`, `PeiResourcePublic`, `AlbumWithMedia`, `NewsDisplay`, `EventPublic`, `PaginatedResponse<T>` existent.
