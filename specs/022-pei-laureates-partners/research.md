# Research — 022 Lauréats, étudiants-entrepreneurs et partenaires du pôle

Phase 0 du plan. Toutes les inconnues du contexte technique sont résolues ; aucun `NEEDS CLARIFICATION` ne subsiste. Les décisions R1–R14 de la feature 021 ([research.md](../021-pei-entrepreneurship-core/research.md)) restent valables et ne sont pas répétées : convention additive des colonnes trilingues, gabarit backend FAQ, audit explicite, `vue-draggable-plus`, `AdminMediaPicker`, traduction `autofill_translations`, tests pytest, migration rejouable.

## R1. Extension du domaine existant plutôt que domaine parallèle

**Décision** : ajouter les deux entités aux fichiers existants du domaine `entrepreneurship` (`app/models/entrepreneurship.py`, `app/schemas/entrepreneurship.py`, `app/services/entrepreneurship_service.py`, `app/routers/admin/entrepreneurship.py`, `app/routers/public/entrepreneurship.py`, `useEntrepreneurshipApi.ts`, `types/api/entrepreneurship.ts`), en reprenant les helpers `_audit`, `_client_meta`, `_reorder`, `_apply_update`, `_media_url`, `_translate_request`.

**Justification** : demande explicite de la feature (« étendre ces fichiers … plutôt que d'en créer de parallèles ») ; le service est déjà organisé par entité (blocs Programs / Cohorts / Resources) et accueille deux blocs de plus sans refonte. Le service dépasse 1 000 lignes : acceptable (une classe, blocs homogènes) ; un découpage en modules est reporté tant qu'aucun besoin ne l'impose.

**Alternative écartée** : nouveau service `entrepreneurship_laureates_service.py` — duplication des helpers et deux points d'entrée pour un même domaine.

## R2. Ordre par cohorte et reorder « scopé »

**Décision** : `display_order` des portraits est relatif à la cohorte. Le helper générique `_reorder` (liste complète, renumérotation 0..n-1, audit unique) est généralisé avec un **filtre de portée** optionnel : `PATCH /laureates/reorder` reçoit `{ cohort_id, ids }` et exige tous les identifiants de cette cohorte ; `PATCH /partners/reorder` reçoit `{ family, ids }` et exige tous les partenaires de cette famille. Création → `MAX(display_order) + 1` dans la portée ; changement de cohorte / famille → `MAX + 1` dans la nouvelle portée puis renumérotation de l'ancienne.

**Justification** : clarification Q3 de la spec (ordre par cohorte) et FR-020 (ordre par famille). Un seul helper paramétré évite trois implémentations.

**Alternative écartée** : ordre global + gel du glisser-déposer sous filtre (convention 021) — contredit la clarification.

## R3. Cohérence type de portrait ↔ type de cohorte

**Décision** : règle métier dans le service (`_assert_laureate_cohort(type, cohort)` → 422 « Un lauréat FSE doit appartenir à une cohorte FSE » / « Un étudiant-entrepreneur doit appartenir à une cohorte SEE »), appliquée à la création, à la modification du type ou de la cohorte. Côté formulaire, la liste des cohortes est filtrée par le type choisi. Pas de contrainte SQL inter-tables (impossible en `CHECK`) ; pas de trigger (aucun précédent dans le projet, et la règle vit déjà dans le service).

**Justification** : clarification Q1 ; message explicite exigé par FR-003 et FR-015.

## R4. Suppression d'une cohorte utilisée

**Décision** : activer `_assert_cohort_deletable` (021, no-op) : `SELECT count(*) FROM pei_laureates WHERE cohort_id = :id` → `ConflictException("Cohorte utilisée par N lauréats")` (409). En base, `pei_laureates.cohort_id … ON DELETE RESTRICT` sert de filet.

**Justification** : contrat 021 (FR-015b, contracts/admin-api.md « 409 réservé »).

## R5. Rattachement des partenaires : vraie clé étrangère avec cascade

**Décision** : `pei_partners.partner_id UUID PRIMARY KEY REFERENCES partners(id) ON DELETE CASCADE`. Colonne nommée `partner_id` (et non `partner_external_id` comme dans la feuille de route) parce que la convention `*_external_id` du projet désigne une référence inter-service **sans** contrainte ; ici la contrainte est explicitement demandée (« suppression en cascade ») et les deux tables vivent dans la même base.

**Justification** : critère d'acceptation « un partenaire supprimé … disparaît du pôle sans erreur » ; la cascade garantit l'absence de rattachement orphelin sans code applicatif. La clé primaire sur `partner_id` impose « un partenaire, une famille » (spec, Assumptions).

**Alternative écartée** : référence sans FK + nettoyage à la lecture (« LEFT JOIN … WHERE partners.id IS NOT NULL ») — laisse des lignes mortes et un compteur faux au tableau de bord.

## R6. Lecture des partenaires : jointure et exclusion des inactifs

**Décision** : le service charge `PeiPartner` joint à `Partner` (une requête, `selectinload` ou `join` explicite), puis les logos par lot (`_load_media` sur les `logo_external_id` distincts) → `logo_url` via `resolve_media_url`. Public : `WHERE partners.active IS TRUE`. Admin : tous les rattachements, avec `partner.active` exposé pour le badge « Inactif ».

**Justification** : `partners.active` est la seule notion d'état (pas de `deleted_at`) ; `PartnerPublic` existant expose `logo_external_id` brut, or FR-029 interdit les UUID de média en public → schéma dédié `PeiPartnerPublic` avec `logo_url`.

## R7. Recherche de partenaires à rattacher

**Décision** : endpoint dédié `GET /api/admin/entrepreneurship/partners/available?q=` (permission `entrepreneurship.view`) qui réutilise la recherche du `PartnerService` (`ILIKE` sur nom et description) et exclut les partenaires déjà rattachés ; réponse légère `{ id, name, type, active, logo_url }`. Le sélecteur frontend est un nouveau composant `EntrepreneurshipAdminPartnerPicker` calqué sur `components/admin/AlbumSelector.vue` (modale, champ de recherche, liste filtrée, sélection puis choix de famille).

**Justification** : la liste admin des partenaires (`GET /api/admin/partners`) est protégée par les permissions du domaine Partenaires, qu'un éditeur du pôle n'a pas forcément ; l'exclusion des partenaires déjà rattachés côté serveur évite de charger 100 partenaires pour en filtrer 7. Aucun sélecteur de partenaires réutilisable n'existe (exploration par sous-agent : pattern dupliqué inline dans `programmes/[id]/edit.vue` et `ProjectPartnersSection.vue`).

**Alternative écartée** : appeler `usePartnersApi().listPartners({ search })` depuis le picker — dépendance à une permission étrangère au pôle.

## R8. Lecture publique des portraits : groupes + chiffres

**Décision** : une seule réponse `{ groups: [{ cohort: PeiCohortPublic, laureates: PeiLaureatePublic[] }], stats: { laureates, cohorts, max_grant_amount } }`, filtre `?type=`. Requête : portraits publiés joints aux cohortes actives, tri `cohorts.display_order, laureates.display_order`, groupement en mémoire (volumes : dizaines). `stats` calculés sur le même jeu filtré ; `max_grant_amount` renvoyé en chaîne décimale (`"5000.00"`) ou `null`. Photos résolues par lot.

**Justification** : clarification Q5 (chiffres calculés, aucune clé éditoriale) ; un seul appel pour la page alumni de la feature 024 ; cohortes sans portrait publié omises (FR-026).

## R9. Montant de subvention

**Décision** : `NUMERIC(10,2)` en base, `Decimal` côté Pydantic (`ge=0`, sérialisé en chaîne), champ facultatif ; libellé « Montant de la subvention (€) » dans le formulaire, saisie numérique.

**Justification** : le cahier des charges parle de « jusqu'à 5 000 € » ; une monnaie unique (euro) suffit, sans colonne de devise.

## R10. Liens et validation

**Décision** : cinq colonnes `VARCHAR(500)` (`website_url`, `linkedin_url`, `instagram_url`, `facebook_url`, `video_url`), validées par Pydantic `HttpUrl` → `str` (comme `pei_resources.url`), chaîne vide normalisée en `NULL` par un validateur. Aucune transformation de l'URL vidéo (R : « n'importe quelle adresse web valide »).

## R11. Verbatim limité à 600 caractères

**Décision** : `quote`, `quote_en`, `quote_ar` en `TEXT` avec `CHECK (char_length(quote) <= 600)` pour chaque colonne, et `max_length=600` côté Pydantic (message 422 « Le verbatim ne doit pas dépasser 600 caractères »). Traduction automatique en `text` ; si la traduction dépasse 600 caractères (rare, EN/AR plus longs), elle est tronquée proprement par le service avant écriture (`_clamp_quote`).

**Justification** : clarification Q4. Le `CHECK` SQL protège les écritures hors API ; le clamp évite qu'une traduction automatique fasse échouer une sauvegarde valide en français.

## R12. Mise en avant

**Décision** : `PATCH /laureates/{id}/featured { is_featured }` (permission edit, audit `feature` / `unfeature`) en plus du champ dans `PeiLaureateUpdate` ; bouton étoile dans la liste. Pas d'effet sur l'ordre.

## R13. Données initiales de partenaires (migration)

**Décision** : bloc `DO $$` dans `046_pei_laureates_partners.sql` avec une liste de couples (motif, famille) :

| Famille | Motifs (`~*`, insensible à la casse) |
|---|---|
| `academic` | `r.seau senghor`, `campus france` |
| `support` | `\mCEF\M`, `\mCCI\M`, `chambre de commerce` |
| `international` | `\mAUF\M`, `agence universitaire de la francophonie`, `\mAFD\M`, `agence fran.aise de d.veloppement`, `\mOIF\M`, `organisation internationale de la francophonie` |

Pour chaque motif : `INSERT INTO pei_partners (partner_id, family, display_order) SELECT id, famille, rang FROM partners WHERE name ~* motif ON CONFLICT (partner_id) DO NOTHING` ; `RAISE NOTICE` « aucun partenaire pour le motif … » quand rien ne correspond. Le point `.` dans les motifs absorbe l'accent ou l'apostrophe typographique. Avant la production : exécuter la requête `SELECT id, name FROM partners WHERE name ~* '…'` en lecture seule sur `usenghor_db` pour chaque motif (gotcha « apostrophe ’ » de la mémoire projet) et ajuster les motifs si besoin.

**Justification** : FR-006 (rattacher sans créer, idempotent, ne pas écraser une famille modifiée). `ON CONFLICT DO NOTHING` conserve la famille choisie par un éditeur.

**Alternative écartée** : seeds par identifiant fixe — les UUID diffèrent entre local et production.

**Correspondances constatées** : base locale (2026-09-13) → `AUF`, `OIF` (international), `CCI Côte d'Ivoire` (support). Production (lecture seule, 2026-09-13, 79 partenaires) : `AUF`, `Agence française de développement`, `CCI Côte d'Ivoire`, et **deux fiches OIF** (« Organisation internationale de la Francophonie » et « … (OIF) »). Aucun « Réseau Senghor », « Campus France », « CEF ». Conséquence : le bloc de rattachement prend **au plus un partenaire par motif** (actif, logo, description, ancienneté) et ne fait rien si un partenaire du motif est déjà rattaché — évite le doublon OIF, y compris au rejeu.

## R14. Migration 046 et rollbacks

**Décision** : `046_pei_laureates_partners.sql` = `BEGIN; … COMMIT;`, deux ENUM gardés (`duplicate_object`), `CREATE TABLE IF NOT EXISTS` × 2, index `IF NOT EXISTS`, triggers `update_pei_laureates_updated_at` / `update_pei_partners_updated_at` gardés par `pg_trigger`, seeds R13, `\echo`. `046_pei_laureates_partners_rollback.sql` = `DROP TABLE IF EXISTS pei_laureates, pei_partners; DROP TYPE IF EXISTS pei_laureate_type, pei_partner_family;`. L'en-tête de `045_entrepreneurship_rollback.sql` reçoit une ligne « Jouer d'abord 046_pei_laureates_partners_rollback.sql (FK pei_laureates → pei_cohorts) ». Aucune permission ni clé éditoriale dans 046.

## R15. Frontend : composants et pages

**Décision** :
- Portraits : pages dédiées `laureats/{index,nouveau,[id]}.vue` copiées de `cohortes/*` ; composants `LaureateList.vue` (drag actif seulement si `cohortId` filtré et aucun autre filtre), `LaureateForm.vue` (sélecteur de cohorte filtré par type, `EntrepreneurshipAdminLangTabs` pour département + verbatim, compteur 0/600, `AdminMediaPicker type="image"` avec aperçu, cinq liens, montant, cases « mis en avant » / « publié », bouton « Traduire »).
- Partenaires : page unique `partenaires/index.vue` ; composants `PartnerFamilyBoard.vue` (trois colonnes ou trois sections, chacune un `VueDraggable` indépendant, `handle=".drag-handle"`, `<select>` de famille inline, bouton retrait, badge « Inactif », lien `/admin/partenaires`) et `PartnerPicker.vue` (modale calquée sur `AlbumSelector`, recherche debouncée 300 ms sur `/partners/available`, choix de la famille avant validation).
- `DashboardCards.vue` : deux cartes de plus (couleurs `amber`, `red` ajoutées au map) ; `PeiDashboardStats` étendu.
- `useAdminSidebar.ts` : deux enfants insérés entre « Cohortes » et « Boîte à outils » ; `usePermissions.ts` : rien à faire (préfixe `/admin/entrepreneuriat` couvre les sous-routes).
- Libellés FR en dur dans les gabarits, comme le reste du backoffice PEI (R11 de 021).

**Justification** : réutilisation maximale (exploration par sous-agent) ; une seule page pour une table de liaison (spec, Assumptions).

## R16. Tests

**Décision** : nouveaux fichiers pytest, mêmes fixtures que 021 (`authenticated_client`, `admin_role`, fixture locale `entrepreneurship_permissions` copiée ou factorisée dans `tests/integration/_pei_fixtures.py`) :
- `tests/integration/test_admin_pei_laureates_api.py` : 403, création + traduction (mock `translation_service.autofill_translations`), 422 cohérence type/cohorte, 422 verbatim > 600, 422 URL, publish/unpublish + `published_at`, featured, reorder par cohorte (liste incomplète → 422), changement de cohorte → dernière position, 409 suppression de cohorte utilisée, audit.
- `tests/integration/test_admin_pei_partners_api.py` : available exclut les rattachés, 201 rattachement, 409 doublon, changement de famille → dernière position, reorder par famille, retrait, cascade après `DELETE partners`, badge inactif dans la liste admin, audit.
- `tests/integration/test_public_pei_api.py` : groupes par cohorte active, exclusion dépubliés / cohorte inactive / cohorte vide, filtre `type`, stats, partenaires groupés en trois familles, inactifs exclus, cascade.
- `tests/unit/test_entrepreneurship_service.py` (extension) : `_clamp_quote`, renumérotation scopée, validation type/cohorte.
Frontend : validation manuelle (quickstart) + `pnpm build` (pas de script lint, cf. écarts 021).
