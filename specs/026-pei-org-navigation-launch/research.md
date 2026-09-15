# Research — 026 Rattachement du PEI à l'organigramme, navigation et mise en ligne

Relevé du code et de la base le 2026-09-15. Deux sous-agents d'exploration (backend, frontend) ont été lancés. La base locale a été testée, et la production (`usenghor_db`) interrogée en transaction **lecture seule** (`default_transaction_read_only=on`).

## Constats de terrain qui modifient la description

| # | Constat | Preuve | Conséquence |
|---|---|---|---|
| C1 | **Défaut de perte de données** : `get_active_sectors_with_active_services` et `GET /api/public/sectors/{code}` réaffectent `sector.services = [s for s in … if s.active]` sur un objet ORM attaché. La relation `Sector.services` est en `cascade="all, delete-orphan"` et `get_db` fait un commit. Résultat : **un appel public supprime définitivement les services inactifs**, avec leur équipe, leurs objectifs, etc. | `organization_service.py:435`, `routers/public/sectors.py:49`. Reproduit en local : service inactif inséré, `GET /with-services` → 200, service supprimé (`count = 0`). En production : 0 service inactif sur 26, et aucune trace d'un service disparu sans suppression dans `audit_logs`. | Correction **obligatoire** dans cette feature (R3) : ces deux lectures sont modifiées, et un pôle désactivé serait supprimé. Test de non-régression. |
| C2 | Les écritures admin sur les services **sont déjà auditées** par `AuditMiddleware` (`ROUTE_TO_TABLE["services"]`) : action create / update / delete, ancienne ligne `to_jsonb(t.*)`, corps JSON en nouvelles valeurs, utilisateur tiré du JWT. | `app/middleware/audit.py:40-68`, `main.py:199` | La spec disait « pas tracées » : corrigé. FR-008 est couvert sans code. Les nouvelles colonnes entrent automatiquement dans `old_values`. Aucun `_audit` explicite, pour éviter un double audit (R6). |
| C3 | Le formulaire de création et d'édition d'un service est une **modale de `pages/admin/organisation/services/index.vue`** (l.1267-1533). `[id].vue` n'affiche qu'un onglet Informations en lecture seule, plus l'équipe. | rapport frontend § 1-2 | Sélecteur « Service parent » et champ « Page dédiée » dans la modale. `[id].vue` affiche en lecture le parent, la page dédiée et les pôles (R8). |
| C4 | Production : DDE = `72eca1c4-4109-457e-beae-6a5a4b379b84` (« Direction du développement et de l’entrepreneuriat », sigle DDE, secteur `SEC-REC`, `display_order` 2), désignée par `entrepreneurship.dde_service_id`. Le motif `'%veloppement et de l_entrepreneuriat%'` trouve **une seule** ligne. Aucun service `PEI`. Colonnes `parent_id` / `landing_path` absentes. | requêtes en lecture seule | La résolution de la migration 050 est validée sur la production (R4). |
| C5 | Production : clés `entrepreneurship.*` = 138 ; 4 catégories `see-*` ; clés hero de la 047 présentes ; `pei_programs` 5, `pei_cohorts` 3, `pei_partners` 4, **`pei_resources` 0** (la 045 en seedait 4) ; permissions `entrepreneurship.{view,create,edit,delete}` accordées à `super_admin`, `admin` et `editor`. | requêtes en lecture seule | Les migrations 045 → 049 sont jouées. La mise en ligne joue uniquement la 050 (R14). Les 0 ressources sont à confirmer avec l'équipe (suppression volontaire probable) : ce n'est pas un motif de rejeu. |
| C6 | Production : `navbar.secondary.about.children` contient 4 entrées, dont une ajoutée en backoffice (`id` hexadécimal, « Notre Organisation », route `/a-propos/organisation`). La migration 012 **écrase** au rejeu. | requête en lecture seule | Seed 050 non destructif (ajout en fin de tableau, R10). Ne jamais rejouer 012. |
| C7 | Production : `short_link_counter_seq.last_value = 65`. Le code `pei` correspond au compteur 32 922 (`int_to_base36` sans remplissage). Aucune gestion d'`IntegrityError`, et tout échec est présenté comme « Capacité maximale atteinte ». | `short_links_service.py:92-137` | Génération qui saute les codes déjà pris (R12). Collision lointaine, mais certaine. |
| C8 | Local : aucune DDE (3 services de test), clé DDE vide. | requête locale | Le guide de démarrage rapide crée une DDE de test en local avant de jouer 050 (quickstart § 1). |
| C9 | Plan du site : secteurs émis en `secteurs/{CODE}` ; services seulement si `service.slug`, champ absent de l'API, donc **0 fiche service émise**. `autoI18n: true` produit les variantes `/en` et `/ar`. `slugify` n'existe que côté `app/`, pas dans Nitro. | `server/api/__sitemap__/urls.ts:125-149`, `nuxt.config.ts:68-72` | R13. |
| C10 | `OrganigrammeSection` : noms de services non localisés, clés `organization.empty.*` absentes (repli en dur), flèche non inversée en RTL. | rapport frontend § 5 | Défauts existants **hors périmètre**, sauf le rendu des nouvelles cartes de pôle (localisées, miroir RTL). |

## Décisions

### R1 — Contraintes de hiérarchie : base de données + service

- **Décision** : double garde.
  - **Base** : FK `parent_id → services(id) ON DELETE SET NULL` ; `CHECK (parent_id IS NULL OR parent_id <> id)` ; `CHECK` de forme sur `landing_path` ; index partiel `idx_services_parent`. Trigger `BEFORE INSERT OR UPDATE OF parent_id, sector_id` (`services_check_hierarchy()`) qui refuse, avec `ERRCODE = 'check_violation'` :
    - un parent qui a lui-même un parent ;
    - un parent qui n'existe pas ;
    - l'attribution d'un parent à un service qui a des pôles ;
    - un parent d'un autre secteur (`IS DISTINCT FROM`) ;
    - le changement de secteur d'un service qui a des pôles.
  - **Backend** : `OrganizationService._validate_hierarchy()` applique les mêmes règles avant l'écriture, avec des messages français (409 `ConflictException` pour les conflits d'état, 422 `ValidationException` pour les valeurs invalides).
  - **Filet** : un `DBAPIError` de SQLSTATE `23514` levé au `flush` est converti en 409.
- **Rationale** : la validation backend donne des messages clairs. Le trigger rend la règle vraie en permanence, y compris pour les migrations, les écritures SQL manuelles et deux enregistrements concurrents (A devient parent de B pendant que B devient parent de C). Coût négligeable : écritures rares, 26 services.
- **Alternatives** : validation backend seule (ne couvre ni les courses ni le SQL manuel) ; contrainte d'exclusion ou colonne `depth` (impossible sans sous-requête, trigger requis de toute façon).

### R2 — Forme de `landing_path`

- **Décision** : chemin interne stocké sans préfixe de langue.
  - **Base** : `CHECK (landing_path IS NULL OR (landing_path ~ '^/' AND landing_path !~ '^//' AND landing_path !~ '\s' AND char_length(landing_path) <= 255))`.
  - **Pydantic** : `field_validator` qui ramène `''` / espaces à `None`, puis applique la regex `^/(?!/)(?!(en|ar)(/|$))(?!r/)[^\s?#]*$`. Le `?` et le `#` sont refusés pour garder un chemin propre à `localePath`.
  - **Frontend** : même regex dans la modale, message immédiat.
- **Rationale** : `localePath(landing_path)` produit `/en/entrepreneuriat`. Un chemin déjà préfixé serait doublé, et `/r/` boucle sur le raccourcisseur. On ne vérifie pas que la route existe (spec, cas limites).

### R3 — Correction du défaut C1 et imbrication des pôles

- **Décision** : ne plus jamais muter une collection ORM dans une lecture publique. `get_active_sectors_with_active_services()` et la lecture par code renvoient des **schémas Pydantic construits**, sans modifier `sector.services` :
  1. charger les secteurs actifs (`selectinload(Sector.services)`, lecture seule) ;
  2. pour chaque secteur : `tops` = services actifs avec `parent_id IS NULL`, triés par `(display_order, name)` ;
  3. `children` = services actifs dont le parent est dans `tops`, triés de la même façon ;
  4. `SectorPublicWithServices(**SectorPublic.model_validate(sector).model_dump(), services=[ServicePublicWithChildren(..., children=[...])])`.

  Les pôles dont le parent est inactif ne figurent ni au niveau du secteur ni en enfants. Leur fiche reste accessible par `/api/public/services`. Le service est partagé par `/with-services` et `/{code}`.
- **Rationale** : supprime la cause (orphelins en `delete-orphan`) sans toucher au modèle ni aux cascades utilisées par l'admin. Un test d'intégration reproduit la perte avant correction.
- **Alternatives** : `session.expunge()` ou `set_committed_value` (fragile, dépend de l'ordre des chargements) ; retirer `delete-orphan` du modèle (change la suppression admin des secteurs).

### R4 — Migration 050 : résolution de la DDE et création du pôle

- **Décision** :
  - DDE = service désigné par `entrepreneurship.dde_service_id` si la valeur est un UUID existant, sinon l'unique service `name ILIKE '%veloppement et de l_entrepreneuriat%'`. S'il y a 0 ou plus d'une correspondance, `RAISE NOTICE` et aucune création.
  - Pôle existant reconnu, dans l'ordre : identifiant fixe `5e1c0050-0000-4000-8000-00000000e1ab` ; `landing_path = '/entrepreneuriat'` ; `sigle ILIKE 'PEI'` dans le secteur de la DDE ; nom `ILIKE 'p_le entrepreneuriat et innovation'`.
  - Pôle trouvé : complétion uniquement (`parent_id` s'il est NULL et que la DDE n'a pas de parent, `landing_path` s'il est NULL).
  - Pôle absent : insertion avec l'**identifiant fixe** et les champs suivants :
    - nom « Pôle Entrepreneuriat et Innovation » ;
    - `name_en` « Entrepreneurship and Innovation Hub », `name_ar` « قطب ريادة الأعمال والابتكار » ;
    - sigle `PEI`, `color` = celle de la DDE, secteur = celui de la DDE, `parent_id` = DDE, `landing_path` `/entrepreneuriat` ;
    - `display_order` 0, `active` TRUE.
- **Rationale** : l'identifiant fixe permet au rollback de ne retirer que ce que la migration a créé. Le motif est testé en production (C4). Les traductions du nom sont fournies parce que la migration contourne `autofill_translations`.
- **Alternatives** : nouvelle clé `entrepreneurship.pole_service_id` (redondante avec `landing_path`) ; création par le backoffice seulement (écarté par la demande).

### R5 — Schémas et API

- **Décision** (détail dans [contracts/api.md](contracts/api.md)) :
  - `ServiceBase` + `parent_id: str | None`, `landing_path: str | None`, repris par `Create`, `Update`, `Read`, `WithDetails` et `ServicePublic`.
  - Nouveaux schémas `ServiceRelativePublic` (id, name, name_en, name_ar, sigle, color, landing_path, display_order) et `ServicePublicWithChildren(ServicePublic)` avec `children: list[ServicePublic]`.
  - `SectorPublicWithServices.services: list[ServicePublicWithChildren]`.
  - `ServicePublicWithDetailsEnriched` + `parent: ServiceRelativePublic | None` (parent actif seulement) + `children: list[ServiceRelativePublic]` (actifs, triés).
  - `GET /api/public/services` inchangé (tous les services actifs, pôles compris), plus les deux champs.
  - Admin : `GET /api/admin/services` renvoie les deux champs par `ServiceRead`. La hiérarchie est calculée côté client, qui charge déjà tous les services.
- **Rationale** : changements additifs, clients existants intacts. `findServiceBySlug` et `getServiceUrl` fonctionnent sans modification (la liste inclut les pôles).

### R6 — Audit

- **Décision** : s'appuyer sur `AuditMiddleware` (C2), sans code d'audit. Le guide de démarrage vérifie la présence de `parent_id` / `landing_path` dans `old_values` / `new_values` après une modification.
- **Limite documentée** : le détachement des pôles par `ON DELETE SET NULL` à la suppression du parent n'a pas d'entrée d'audit propre. Il est implicite dans l'entrée `delete` du parent, et la modale l'annonce.
- **Alternative** : audit explicite façon `_audit` PEI (produirait un double enregistrement tant que `services` reste dans `ROUTE_TO_TABLE`).

### R7 — Duplication, activation, suppression

- **Décision** :
  - `duplicate_service` recopie `parent_id` (la copie reste un pôle du même parent) mais **pas** `landing_path` (évite deux cartes vers la même page).
  - La duplication d'un service qui a des pôles ne duplique pas ses pôles.
  - `toggle_service_active` est inchangé : un parent inactif masque ses pôles, sans les modifier.
  - `delete_service` est inchangé : le `SET NULL` en base détache les pôles. `getServiceUsage` / la modale indiquent le nombre de pôles.

### R8 — Backoffice

- **Décision** :
  - Modale de `services/index.vue` : sous « Secteur », un `<select>` « Service parent ».
    - Options : `Aucun` et `services.filter(s => !s.parent_id && s.sector_id === form.sector_id && s.id !== editingId)`, triés par nom.
    - Désactivé, avec l'aide « Ce service a N pôle(s) : il ne peut pas être rattaché », quand le service édité a des enfants.
    - Remis à `null` si le secteur change et que le parent n'y appartient plus.
  - Champ « Page dédiée » : texte, placeholder `/entrepreneuriat`, aide et validation R2.
  - Bandeau d'erreur dans la modale : `detail` des 409 / 422, qui ne passaient qu'en `console.error`.
  - Liste (vues tableau et groupée) : ordre hiérarchique (parent puis ses pôles), pôles en retrait `ps-8` avec icône `fa-turn-up fa-rotate-90` (miroir RTL) et pastille « Pôle de {sigle ou nom} ».
    - Pour la recherche et les filtres : un pôle dont le parent est filtré s'affiche seul, avec sa pastille.
    - Glisser-déposer désactivé sur les lignes de pôle ; ordre des pôles = `display_order`, puis nom.
  - Modale de suppression : avertissement si le service a des pôles.
  - `[id].vue` (onglet Informations) : parent (lien), page dédiée, liste des pôles (liens).
- **Rationale** : l'édition a lieu dans la modale existante (C3). Le glisser-déposer des pôles est hors besoin (1 pôle aujourd'hui).

### R9 — Affichage public

- **Décision** :
  - Nouveau helper `getServiceLink(service)` dans `usePublicOrganizationApi` : renvoie `landing_path || getServiceUrl(service)`, à passer à `localePath` par l'appelant.
  - `OrganigrammeSection` : un service **sans enfants** garde exactement le même nœud (`NuxtLink data-card` direct dans la grille). Un service **avec enfants** est rendu dans un `div.flex.flex-col.gap-2`, avec la même carte puis une liste `ms-4 ps-3 border-s-2` de cartes compactes de pôle (sigle ou icône, nom localisé, flèche inversée en RTL, `NuxtLink` vers `localePath(getServiceLink(child))`).
    - La carte d'un service ou d'un pôle ayant `landing_path` pointe vers ce chemin.
  - Fiche `[type]/[slug].vue`, onglet Présentation, entre la carte de description et le bouton « onglet suivant » :
    - lien de parent (« Pôle de {sigle/nom} », flèche) si `entity.parent` ;
    - lien « Voir la page dédiée » si `landing_path` ;
    - bloc « Pôles » (titre `organizationDetail.poles.title`, grille `sm:grid-cols-2`, cartes au style de l'organigramme) si `entity.children.length`.
  - Fiche secteur, onglet Services : liste les services de premier niveau, avec une ligne « + N pôle(s) » sous un parent qui en a (lien vers la fiche du parent). Aucun autre changement.
- **Rationale** : DOM identique sans pôles (SC-002). Composants inline dans les fichiers existants, pas de nouveau composant : les cartes font moins de 20 lignes.
- **Vérification des composants existants** : aucun composant de carte de service réutilisable n'existe. Les cartes de l'organigramme et de l'onglet Services sont inline.

### R10 — Menu : seed non destructif et libellés trilingues

- **Décision SQL** (dans la 050) : bloc `DO`.
  - Lecture de `navbar.secondary.about.children`.
  - Clé absente ou valeur vide : insertion `[entry]` (`value_type 'json'`, catégorie `values`, `admin_editable` TRUE).
  - Valeur illisible ou non tableau : `RAISE NOTICE`, aucune écriture.
  - Élément avec `id = 'entrepreneurship'` ou `route = '/entrepreneuriat'` déjà présent : NOTICE.
  - Sinon, `arr || jsonb_build_array(entry || jsonb_build_object('sort_order', max(sort_order)+1))`.
  - `entry` = `{"id":"entrepreneurship","label":"Entreprendre à Senghor","label_en":"Entrepreneurship at Senghor","label_ar":"ريادة الأعمال في سنغور","route":"/entrepreneuriat","icon":"fa-solid fa-lightbulb"}`.
- **Décision frontend** (Q2) :
  - `AppNavBar` : le type JSON gagne `label_en?`, `label_ar?` (primaire et secondaire). Les enfants mappés conservent `_labels: { fr, en, ar }`, et un helper `navChildLabel(sectionKey, child)` renvoie `_labels[locale] || _labels.fr || t('nav.dropdowns.…')`.
  - Les trois points de rendu (l.446, 537, 782) utilisent ce helper, ce qui gère le changement de langue sans rechargement.
  - `NavItemsField.vue` : deux champs facultatifs « Libellé (anglais) » et « Libellé (arabe) » (`dir="rtl"`) ; `NavSubItem` étendu. L'enregistrement conserve les propriétés inconnues (spread de l'item existant).
- **Rationale** : entrées existantes sans `label_en` / `label_ar` → rendu identique. Aucun changement de format pour les listes existantes.
- **Hors périmètre** : descriptions traduites des sous-menus principaux.

### R11 — Pied de page

- **Décision** : `AppFooter.vue`, colonne University : nouveau `<li>` après `governance`, `NuxtLink :to="localePath('/entrepreneuriat')"`, libellé `footer.university.entrepreneurship` (FR « Entreprendre à Senghor », EN « Entrepreneurship at Senghor », AR « ريادة الأعمال في سنغور »).

### R12 — Lien court `pei` et génération qui saute les codes pris

- **Décision** :
  - Seed dans la 050 : `INSERT INTO short_links (code, target_url, created_by) VALUES ('pei', '/entrepreneuriat', NULL) ON CONFLICT (code) DO NOTHING`, avec NOTICE si `pei` existe vers une autre cible.
  - `ShortLinkService.create_short_link` : boucle d'au plus 20 tirages `nextval`. On sort dès que `int_to_base36(counter)` n'existe pas (`SELECT 1 FROM short_links WHERE code = :c`) ; au-delà, `ValidationException` explicite.
  - L'exception « Capacité maximale » est limitée au dépassement réel du compteur. Les autres erreurs remontent.
- **Rationale** : la cible relative est déjà acceptée (`_validate_target_url`). `server/routes/r/[code].get.ts` redirige tel quel en 302 vers `/entrepreneuriat` (visiteur FR ; la détection de langue du site s'applique ensuite comme pour tout lien).

### R13 — Plan du site

- **Décision** : dans `server/api/__sitemap__/urls.ts` :
  - secteurs lus depuis `/api/public/sectors` → `/a-propos/organisation/secteur/${code.toLowerCase()}` ;
  - services depuis `/api/public/services` (tous les services actifs, pôles et services sans secteur compris) → `/a-propos/organisation/service/${slugifyServiceName(name)}`, dédupliqués par `Set`.
  - `slugifyServiceName` est une copie locale, commentée « identique à `slugify` de `usePublicOrganizationApi.ts` », de la même normalisation NFD.
  - Les sept pages `/entrepreneuriat/*` restent émises par la découverte automatique des routes statiques ; contrôle dans le guide de démarrage.
- **Rationale** : Nitro n'importe pas `app/`. Déplacer `slugify` dans `shared/` exposerait à des collisions d'auto-import (mémoire projet : `slugify` est dupliqué dans 7 fichiers). Cohérence vérifiée par un test de bout en bout : 100 % des URLs du plan répondent 200 (quickstart § 7).
- **Alternative** : champ `slug` calculé en Python (normalisation Unicode différente du JS, risque de divergence).

### R14 — Fil d'Ariane factorisé

- **Décision** :
  - Nouvelle fonction `usePeiBreadcrumb(current?: string)` exportée par `app/composables/usePeiPage.ts`, utilisée par `usePeiPage` et par `pages/entrepreneuriat/{index,activites}.vue`, qui perdent leurs blocs l.59-67 / l.69-77.
  - Données : `useAsyncData('pei-org-services', listServices)` (clé partagée, dédupliquée).
    - pôle = service de `landing_path === '/entrepreneuriat'` ;
    - niveau DDE = `services.find(id === pole.parent_id)`, sinon `services.find(id === dde_service_id)`, sinon omis.
  - Libellés : `nav.home`, `nav.about` (« Nous connaître »), `about.tabs.organization`, `sigle || pei.breadcrumb.dde`, `pei.breadcrumb.pole`, puis la rubrique.
  - Le dernier élément n'a pas de `to`, ce qui le marque comme page courante dans `PageHero`.
  - `ddeServiceId` / `ddeService`, utilisés pour filtrer les actualités, événements et médias, **restent** fondés sur la clé : aucun changement de données sur les pages.
- **Rationale** : une seule construction (FR-025), sans changer les sources de contenu. `listServices` renvoie 26 lignes : négligeable, et cela évite un `getServiceById` supplémentaire. Aucune collision d'auto-import : `usePeiBreadcrumb` et `getServiceLink` sont absents du dépôt (grep 2026-09-15).

### R15 — Tests

- **Backend** : nouveau `tests/integration/test_services_hierarchy.py`, avec une fixture de permissions `organization.view` / `organization.edit` sur le modèle de `test_admin_faq_categories_api.py`.
  - Création et modification avec parent valide ; refus 409 / 422 pour l'auto-référence, le second niveau, le parent d'un autre secteur, le parent donné à un service qui a des pôles, le changement de secteur d'un parent ; `landing_path` invalide (422) et vide (→ NULL).
  - `with-services` : pôle sous son parent, absent du niveau secteur ; parent inactif → pôle absent.
  - **Régression C1** : un service inactif existe toujours après `GET /with-services` et `GET /sectors/{code}`.
  - `GET /services/{id}` : `parent` et `children`.
  - `duplicate` : `parent_id` recopié, `landing_path` non.
  - Lien court : `create_short_link` saute un code existant (séquence créée dans la fixture, car `create_all` ne crée pas les séquences).
- **Trigger** : non créé par `create_all`, donc testé en SQL dans le guide de démarrage (§ 2).
- **Frontend** : aucune infrastructure de test ; validations du guide, `pnpm build` (heap 8 Go), captures avant / après.

### R16 — Mise en ligne

- **Décision** : procédure du guide de démarrage § 10. Chaque étape est soumise à accord :
  1. commit et push des trois dépôts ;
  2. `./deploy.sh backup` ;
  3. contrôle en lecture seule (déjà fait en C4 / C5, à refaire le jour J) ;
  4. `050` jouée deux fois, puis `050` comptes ;
  5. `./deploy.sh update` avec `--force-recreate` ;
  6. contrôles ;
  7. « Traduire les champs manquants » ;
  8. Lighthouse derrière nginx.

  Aucun rejeu de 045 → 049 sans écart constaté. Les tâches T071 (021) et T051 (023) sont cochées sur la base des preuves C5 et des suivis ; T039 et T048 (023) sont reprises dans les § 8 et 9.
- **Ordre des rollbacks** : `050_…_rollback.sql` **avant** `049` → `045`. La 050 ne dépend d'aucune table PEI, mais la documentation impose l'ordre inverse de la chaîne.
