# Feuille de route — Pôle Entrepreneuriat et Innovation (PEI)

Mini-site public « Entreprendre à Senghor » (`/entrepreneuriat`) rattaché au service
« Direction du Développement et de l'Entrepreneuriat (DDE) » du secteur « Rectorat »,
avec son backoffice. Cahier des charges : `Communication - cahier de charges Page EI.pdf`.

**Maquette de référence** : dossier `specs/maquettes-pei/` (rendus PNG + sources HTML + `README.md` qui
explique comment les lire et les écarts assumés). Version éditable : canvas
https://claude.ai/code/artifact/43435b8e-2b26-4512-9a0e-37da522d8611. Chaque prompt cite les fichiers
de la maquette qu'il doit suivre ; l'agent doit **ouvrir le PNG** (référence visuelle) et **lire le HTML**
(valeurs exactes) avant de planifier.

Le projet est découpé en **6 features speckit indépendantes**, à lancer dans l'ordre.
Chaque bloc « Prompt » ci-dessous se colle tel quel après `/speckit-specify`, puis on enchaîne
`/speckit-clarify` → `/speckit-plan` → `/speckit-tasks` → `/speckit-implement`.

---

## 0. Décisions à prendre avant de commencer

| # | Question | Choix retenu par défaut dans les prompts |
|---|----------|------------------------------------------|
| D1 | Rattachement du pôle à l'organigramme | `services.parent_id` (nullable) + `services.landing_path` — un vrai niveau « pôle », réutilisable. Alternative sans migration : encart dans le contenu riche de la fiche DDE. |
| D2 | Adresse publique | `/entrepreneuriat` (FR par défaut, `/en/entrepreneuriat`, `/ar/entrepreneuriat`). Alias court possible via le raccourcisseur de liens existant. |
| D3 | Qui gère le contenu du pôle ? | Nouvelles permissions `entrepreneurship.view / create / edit / delete` (seedées en migration, cf. règle « permissions à seeder »). |
| D4 | Slider du hero (3 visuels) | Étendre `PageHero` avec une prop optionnelle `images[]` plutôt que créer un hero dédié. |

---

## 1. Règles transversales (à rappeler dans chaque feature)

- **Réutiliser, ne pas recréer** : hero = `PageHero` (mode image, étendu en slider), en-tête et pied de page = layout par défaut (`AppNavBar`, `AppFooter`), texte riche = `RichTextRenderer` (public) et `AdminRichTextEditor` en `mode="modal"` (admin, sinon les onglets EN/AR sont masqués), listes admin = mêmes gabarits que `admin/contenus/levees-de-fonds` et `admin/faq`.
- **Trilingue** : colonnes `*_fr / *_en / *_ar`, traduction automatique à l'écriture via `autofill_translations` côté backend, lecture via `useLocalizedField` côté frontend, repli FR silencieux, RTL en arabe.
- **Contenu riche** : double colonne `*_html` + `*_md`.
- **Base de données** : toute structure passe par le SQL de référence (`documentation/modele_de_données/services/`) **et** une migration `0XX_*.sql` rejouable, avant le code. Noms de fichiers sans accents.
- **API** : public sous `/api/public/entrepreneurship/*` (sans auth, `useApiBase()` + `$fetch`), admin sous `/api/admin/entrepreneurship/*` (JWT, `useApi()`), routes statiques déclarées avant les routes dynamiques.
- **Audit** : les écritures admin passent par le service d'audit existant (`audit_logs`).
- **SEO** : `useSeoMeta` déclaré après la route (gotcha TDZ), pages ajoutées au sitemap, OG image.
- **Maquette** : suivre les fichiers de `specs/maquettes-pei/` cités par le prompt (ordre et contenu des
  sections, hiérarchie, densité). Les HTML donnent les valeurs exactes mais ne sont pas des composants à
  copier : tout est réimplémenté avec les composants Vue/Tailwind existants. Lire `specs/maquettes-pei/README.md`.
- **Sous-agents** : avant tout nouveau composant, vérifier qu'un composant similaire n'existe pas déjà dans `usenghor_nuxt/app/components/`.

---

## 2. Proposition de backoffice

Le pôle a une gestion « un peu particulière » parce qu'il **mélange trois sources** : des données propres au pôle, des données déjà gérées ailleurs (actualités, événements, albums, partenaires, FAQ, appels), et de la copie de page. Le backoffice reflète cette séparation.

### 2.1 Nouvelle section de la barre latérale admin : « Entrepreneuriat (PEI) »

| Entrée | Route admin | Données | Ce qu'on y fait |
|--------|-------------|---------|-----------------|
| Tableau de bord du pôle | `/admin/entrepreneuriat` | agrégation | Raccourcis vers chaque rubrique, compteurs (dispositifs actifs, lauréats publiés, ressources), rappel des éléments gérés ailleurs avec liens directs (actualités DDE, événements DDE, albums DDE, FAQ « SEE », appel SEE en cours). |
| Dispositifs du parcours | `/admin/entrepreneuriat/dispositifs` | `pei_programs` | CRUD trilingue : titre, sigle (OSER, SEE, MTI, FSE…), phase (`awareness / status / pre_incubation / incubation / funding / ecosystem`), accroche, contenu riche, chiffre mis en avant (ex. « 4 crédits », « 5 000 € »), visuel, ordre, actif. Réordonnancement par glisser-déposer. |
| Cohortes | `/admin/entrepreneuriat/cohortes` | `pei_cohorts` | CRUD : libellé (FSE 1, FSE 2…), année, type (`fse / see`), focus, bilan riche, ordre, actif. |
| Lauréats et étudiants-entrepreneurs | `/admin/entrepreneuriat/laureats` | `pei_laureates` | CRUD : nom, type (`fse_laureate / student_entrepreneur`), cohorte, projet, département (lien optionnel vers `sectors`/programme), verbatim trilingue, photo (médiathèque), liens (site, réseaux), montant obtenu, mis en avant, publié, ordre. Filtres par cohorte et type. |
| Partenaires du pôle | `/admin/entrepreneuriat/partenaires` | `pei_partners` (table de liaison) | Sélecteur sur la table `partners` existante + famille (`academic / support / international`) + ordre. On ne recrée pas de partenaires : on **référence** ceux du backoffice Partenaires. |
| Boîte à outils | `/admin/entrepreneuriat/ressources` | `pei_resources` | CRUD : titre trilingue, description, type (`document / link / video`), document (médiathèque) ou URL, catégorie, ordre, publié. |
| Textes et chiffres clés | `/admin/editorial/valeurs` → page « Entrepreneuriat » | `editorial_contents` | Nouvelle page front-office « entrepreneurship » dans `editorial-pages-config.ts` : slogan, sous-titre, images du slider, présentation (riche), citation et auteur, texte d'impact, 4 chiffres clés, textes des CTA, e-mail de contact, slug de l'appel SEE en cours, textes du guide SEE. Aucune page admin nouvelle : l'éditeur de pages éditoriales existant suffit. |

### 2.2 Réutilisation des backoffices existants (aucune nouvelle page admin)

| Rubrique publique | Backoffice existant | Convention |
|-------------------|---------------------|------------|
| Actualités | Contenus → Actualités | Actualité liée au service DDE (`news_services`). Le mini-site filtre par `service_id` = DDE. |
| Événements (2SE, hackathons…) | Contenus → Événements | `events.service_external_id` = DDE. |
| Médiathèque | Organisation → Services → DDE → Albums | `service_media_library` de la DDE. |
| FAQ du SEE | FAQ | Catégorie `see` (code réservé) ; la page SEE affiche cette catégorie seule. |
| Appel à candidatures SEE | Candidatures → Appels | Appel de type `training` avec critères, documents, calendrier, formulaire. La page SEE lit l'appel désigné par la clé éditoriale `entrepreneurship.see.call_slug`. |
| Équipe du pôle | Organisation → Services → DDE → Équipe | `service_team` de la DDE (affichage optionnel). |

### 2.3 Permissions et rôles

- `entrepreneurship.view`, `entrepreneurship.create`, `entrepreneurship.edit`, `entrepreneurship.delete` seedées en migration et attribuées à `super_admin` + rôle éditeur de contenu.
- La section de la barre latérale n'apparaît qu'avec `entrepreneurship.view`.

### 2.4 Modèle de données proposé (`16_entrepreneurship.sql`)

Vue d'ensemble : `specs/maquettes-pei/arborescence.png` (organigramme, rubriques du mini-site et source de données de chacune).

```
pei_cohorts     id, code UNIQUE, label_fr/en/ar, year, type ENUM(fse, see), focus_fr/en/ar,
                summary_html/md (+ en/ar), display_order, active, created_at, updated_at
pei_programs    id, code UNIQUE, sigle, title_fr/en/ar, phase ENUM(awareness, status,
                pre_incubation, incubation, funding, ecosystem), tagline_fr/en/ar,
                content_html/md (+ en/ar), highlight_fr/en/ar, color, cover_image_external_id,
                display_order, active, created_at, updated_at
pei_laureates   id, cohort_id FK, type ENUM(fse_laureate, student_entrepreneur), full_name,
                project_name, department_label_fr/en/ar, quote_fr/en/ar, photo_external_id,
                website_url, linkedin_url, instagram_url, facebook_url, video_url,
                grant_amount NUMERIC, is_featured, is_published, display_order, created_at, updated_at
pei_partners    partner_id (PK, FK → partners.id ON DELETE CASCADE — livré en 022, au lieu de
                partner_external_id), family ENUM(academic, support, international),
                display_order (relatif à la famille)
pei_resources   id, title_fr/en/ar, description_fr/en/ar, type ENUM(document, link, video),
                media_external_id, url, category_fr/en/ar, display_order, is_published,
                created_at, updated_at
services        + parent_id UUID NULL REFERENCES services(id), + landing_path VARCHAR(255) NULL
```

---

## 3. Les prompts speckit, dans l'ordre

### Feature 021 — Socle du pôle : modèle de données, API et backoffice « Dispositifs, cohortes, ressources »

**Dépend de** : rien. **Livre** : SQL + migration, permissions, routeurs admin/public, section admin, page éditoriale « entrepreneurship ».

```
Créer le socle backend et backoffice du « Pôle Entrepreneuriat et Innovation (PEI) », pôle du service
« Direction du Développement et de l'Entrepreneuriat (DDE) » (secteur Rectorat), qui alimentera un futur
mini-site public « Entreprendre à Senghor ». Cette feature ne crée AUCUNE page publique.

Maquette : ouvrir `specs/maquettes-pei/arborescence.png` (rubriques du mini-site et source de données de
chacune) et lire `specs/maquettes-pei/README.md`. Les pages `accueil.html`, `alumni.html` et
`statut-etudiant-entrepreneur.html` du même dossier montrent quels champs chaque table doit porter
(ex. dispositif : numéro, phase, titre, description, chiffre mis en avant, couleur ; ressource : titre,
type, document ou lien, catégorie).

Contexte : la hiérarchie organisationnelle est secteur → service, sans niveau « pôle ». Le contenu demandé
(parcours en dispositifs, cohortes de lauréats, boîte à outils, chiffres clés) n'a pas de place dans les
onglets génériques d'un service. On crée donc des tables dédiées, sur le modèle des levées de fonds
(`13_fundraising.sql`, `admin/contenus/levees-de-fonds`, `routers/admin/fundraisers.py`).

Périmètre :
1. Base de données : nouveau fichier `documentation/modele_de_données/services/16_entrepreneurship.sql`
   inclus dans `main.sql`, et migration `0XX_entrepreneurship.sql` rejouable, avec les tables `pei_cohorts`,
   `pei_programs`, `pei_resources` (colonnes trilingues `*_fr/*_en/*_ar`, contenu riche en double colonne
   `*_html` + `*_md`, `display_order`, `active`/`is_published`, horodatages). Les tables `pei_laureates` et
   `pei_partners` seront ajoutées dans la feature suivante. Demander l'accord sur le SQL avant de coder.
2. Permissions : seed de `entrepreneurship.view/create/edit/delete` dans la migration, attribuées au
   super_admin et au rôle éditeur de contenu (même logique que `033_faq.sql`). Tout `PermissionChecker`
   utilisé doit exister en base.
3. Backend FastAPI : modèles SQLAlchemy async, schémas Pydantic v2, routeur admin
   `/api/admin/entrepreneurship/{cohorts,programs,resources}` (CRUD, reorder, toggle, traduction
   automatique FR→EN/AR via `autofill_translations` à la création et à la modification, audit dans
   `audit_logs`) et routeur public `/api/public/entrepreneurship/{cohorts,programs,resources}` en lecture
   seule des éléments actifs/publiés. Routes statiques avant les routes dynamiques.
4. Backoffice Nuxt : nouvelle section « Entrepreneuriat (PEI) » dans `useAdminSidebar.ts`, visible avec
   `entrepreneurship.view`, avec un tableau de bord `/admin/entrepreneuriat` (compteurs + raccourcis vers
   les rubriques gérées ailleurs : actualités et événements liés à la DDE, albums de la DDE, FAQ, appels),
   et trois pages CRUD `/admin/entrepreneuriat/{dispositifs,cohortes,ressources}` reprenant les gabarits
   de `admin/faq` et `admin/contenus/levees-de-fonds` (liste, filtres, réordonnancement par glisser-déposer,
   modale ou page d'édition, onglets FR/EN/AR, `AdminRichTextEditor` en mode modal, sélecteur de média
   existant pour les visuels et documents). Composable `useEntrepreneurshipApi()`.
5. Page éditoriale : nouvelle entrée `entrepreneurship` dans `editorial-pages-config.ts` (slug
   `/entrepreneuriat`) avec ses sections et clés (slogan, sous-titre, images du slider, présentation riche,
   citation + auteur + fonction, texte d'impact, 4 chiffres clés, textes des CTA, e-mail de contact
   `entrepreneuriat@usenghor.org`, `entrepreneurship.see.call_slug`), et migration de seed des clés avec
   les textes du cahier des charges. Éditable dans la page « Valeurs » existante, sans nouvelle page admin.
6. Données initiales : seed des 5 dispositifs (Parcours OSER, Statut Étudiant-Entrepreneur, Mature Ton Idée,
   Senghor'Innov, Fonds de Soutien à l'Entrepreneuriat) et des 3 cohortes FSE (2023, consolidation, 2025)
   à partir du cahier des charges, en français ; les traductions sont générées automatiquement.

Hors périmètre : pages publiques, lauréats, partenaires, rattachement à l'organigramme, menu.

Critères d'acceptation : un éditeur disposant des permissions crée, modifie, réordonne et désactive un
dispositif dans les trois langues ; les endpoints publics ne renvoient que les éléments actifs ; chaque
écriture est tracée dans l'audit ; la migration se rejoue sans erreur en local et en production ; CLAUDE.md
est mis à jour (nouveau fichier SQL, nouvelle section admin, nouveau composable).
```

### Feature 022 — Lauréats, étudiants-entrepreneurs et partenaires du pôle (backoffice)

**Dépend de** : 021. **Livre** : tables `pei_laureates`, `pei_partners`, API, deux pages admin.

> ✅ **Livrée** (specs/022-pei-laureates-partners/, migration `046_pei_laureates_partners.sql`).
> Portée retenue : ordre des portraits **par cohorte** et des partenaires **par famille**, verbatim en
> texte simple (600 caractères par langue), chiffres du bandeau calculés (`stats` de
> `GET /api/public/entrepreneurship/laureates`), `pei_partners.partner_id` avec FK en cascade,
> rattachement initial des partenaires du cahier des charges par motifs (sans création).

```
Ajouter au backoffice « Entrepreneuriat (PEI) » la gestion des lauréats du Fonds de Soutien à
l'Entrepreneuriat (FSE), des étudiants-entrepreneurs, et des partenaires du pôle. Aucune page publique.

Maquette : `specs/maquettes-pei/alumni.png` et `alumni.html` (carte portrait : photo, nom, badge de
cohorte, projet, département, verbatim, liens site/réseaux/vidéo ; en-tête de cohorte : libellé, année,
focus ; bandeau de chiffres) et la section « Nos partenaires » de `accueil.png` (trois familles, logos).
Les champs des tables et des formulaires doivent couvrir exactement ce que ces cartes affichent.

Périmètre :
1. Base de données : compléter `16_entrepreneurship.sql` et ajouter une migration `0XX_pei_laureates_partners.sql`
   avec `pei_laureates` (nom, type `fse_laureate | student_entrepreneur`, cohorte FK vers `pei_cohorts`,
   nom du projet, libellé de département trilingue, verbatim trilingue, photo `photo_external_id` vers
   `media`, liens site/LinkedIn/Instagram/Facebook/vidéo, montant de subvention, mis en avant, publié,
   ordre) et `pei_partners` (liaison vers `partners.id` existante + famille
   `academic | support | international` + ordre). Demander l'accord sur le SQL avant de coder.
2. Backend : CRUD admin `/api/admin/entrepreneurship/laureates` et `/api/admin/entrepreneurship/partners`
   (traduction automatique des champs texte, audit), lecture publique `/api/public/entrepreneurship/laureates`
   (publiés, groupés par cohorte, photo résolue via `resolve_media_url`) et
   `/api/public/entrepreneurship/partners` (enrichis avec nom, logo, site et réseaux du partenaire).
3. Backoffice : page `/admin/entrepreneuriat/laureats` (liste filtrable par cohorte et type, formulaire
   avec sélecteur de photo depuis la médiathèque, onglets FR/EN/AR pour le verbatim, mise en avant,
   publication, réordonnancement) et page `/admin/entrepreneuriat/partenaires` (sélecteur de partenaires
   existants par recherche, affectation d'une famille, réordonnancement ; on ne crée jamais de partenaire
   ici, un lien renvoie vers le backoffice Partenaires). Mettre à jour le tableau de bord du pôle.
4. Le cahier des charges impose 3 familles de partenaires : académiques et institutionnels (réseau
   Senghor, Campus France), organisations d'appui (incubateurs, accélérateurs, CCI, CEF), organisations
   internationales (AUF, AFD, OIF). Les familles sont fixes (ENUM), les partenaires sont libres.

Hors périmètre : pages publiques, import automatique des lauréats (saisie manuelle).

Critères d'acceptation : un éditeur publie un lauréat avec photo et verbatim dans les trois langues et le
retrouve dans l'endpoint public sous sa cohorte ; un partenaire retiré du backoffice Partenaires disparaît
du pôle sans erreur ; audit et permissions `entrepreneurship.*` respectés.
```

### Feature 023 — Mini-site public : accueil, présentation et parcours (« Nos activités »)

**Dépend de** : 021 (et 022 pour le bloc partenaires de l'accueil). **Livre** : `/entrepreneuriat`, `/entrepreneuriat/activites`, sous-navigation, hero slider.

```
Créer le mini-site public « Entreprendre à Senghor » du Pôle Entrepreneuriat et Innovation (PEI) :
la page d'accueil (rubrique « Présentation ») et la page « Nos activités ».

Maquette à suivre : `specs/maquettes-pei/accueil.png` (référence visuelle : ordre, contenu et densité
des sections) et `specs/maquettes-pei/accueil.html` (valeurs exactes : couleurs, tailles, espacements,
rayons). Lire `specs/maquettes-pei/README.md` pour les écarts assumés (hero et footer réutilisés, icônes
Font Awesome, mode sombre et mobile à dériver des pages voisines). La page « Nos activités » n'est pas
dessinée : reprendre les cartes du parcours de l'accueil en version longue, une section par phase.

Contraintes de réutilisation (obligatoires) :
- Hero : réutiliser `PageHero` et l'étendre avec une prop optionnelle `images[]` (slider de 3 visuels avec
  points de navigation, défilement automatique respectant `prefers-reduced-motion`) ; pas de nouveau composant hero.
- En-tête et pied de page : ceux du layout par défaut (`AppNavBar`, `AppFooter`), rien à recréer.
- Sous-navigation collante des rubriques du pôle (Présentation, Nos activités, Nos alumni, Nos partenaires,
  Nos ressources, Actualités + bouton « Devenir étudiant-entrepreneur ») : vérifier d'abord si
  `SectionAboutTabsNav` ou `FundraisingAnchorNav` peut être généralisé ; sinon créer un composant
  `EntrepreneurshipSubNav` calqué dessus (top-20, z-40, onglets avec icônes Font Awesome, actif par route).
- Texte riche : `RichTextRenderer`. Chiffres clés : `SectionStats` existant ou son style.
- Contenu : lu via `useEditorialContent('entrepreneurship')` (copie, slider, chiffres clés, citation) et
  `usePublicEntrepreneurshipApi()` (dispositifs, partenaires). Aucun texte codé en dur dans les pages.

Périmètre :
1. `/entrepreneuriat` : hero slider (slogan « INNOVER. AGIR. TRANSFORMER. », visuels d'étudiants), badge,
   fil d'Ariane Accueil › Nous connaître › Organisation › DDE › Pôle Entrepreneuriat et Innovation,
   sous-navigation, section présentation (deux colonnes : texte + panneau chiffres clés), section parcours
   (5 dispositifs en cartes numérotées, chips des événements récurrents, lien vers Nos activités), encadré
   citation du directeur de la DDE + texte d'impact + visuel, aperçu de 3 actualités liées à la DDE (via
   `listPublishedNews({ service_id })`), partenaires par famille (logos), CTA « Prêt à passer à l'action ? »
   avec lien vers la future page SEE et l'e-mail du pôle.
2. `/entrepreneuriat/activites` : page longue en ancres, un bloc par phase du parcours (sensibilisation,
   statut, pré-incubation, incubation, financement, animation de l'écosystème), contenu riche de chaque
   dispositif, visuels, et liste des prochains événements liés à la DDE (`events.service_external_id`).
3. i18n : clés FR/EN/AR des libellés fixes (rubriques, boutons), RTL vérifié en arabe.
4. SEO : `useSeoMeta` après la route, balises OG, ajout au sitemap, JSON-LD `Organization`/`WebPage`.
5. Responsive : vérifier à 390 px (sous-navigation défilante, cartes du parcours en colonne, slider).

Hors périmètre : Nos alumni, Nos partenaires, Nos ressources, Actualités, page SEE, menu principal,
rattachement à l'organigramme (features suivantes). Les liens de la sous-navigation vers ces rubriques
pointent déjà vers leurs futures routes.

Critères d'acceptation : la page d'accueil s'affiche en SSR avec les données du backoffice dans les
trois langues ; le slider est accessible au clavier ; le score Lighthouse mobile reste ≥ 90 en performance
et accessibilité ; aucune régression sur `PageHero` là où il est déjà utilisé.
```

### Feature 024 — Mini-site public : alumni, partenaires, ressources, actualités

**Dépend de** : 022, 023. **Livre** : `/entrepreneuriat/{alumni,partenaires,ressources,actualites}`.

```
Compléter le mini-site « Entreprendre à Senghor » avec les quatre rubriques restantes, en réutilisant
le hero `PageHero`, le layout par défaut, la sous-navigation du pôle et les composants publics existants
(cartes d'actualités, grille de partenaires, galerie de la médiathèque).

Maquette : `specs/maquettes-pei/alumni.png` et `alumni.html` pour la page alumni (sous-onglets pilule,
bandeau de chiffres, sections par cohorte, cartes portrait, CTA mentor). Les pages partenaires,
ressources et actualités ne sont pas dessinées : reprendre respectivement la section « Nos partenaires »
de `accueil.png`, les cartes de `accueil.html` pour la boîte à outils, et les cartes d'actualités de
`accueil.png` (identiques à celles de `/actualites`).

Périmètre :
1. `/entrepreneuriat/alumni` : sous-onglets « Lauréats FSE » et « Étudiants entrepreneurs » (style des
   sous-onglets pilule de `SectionAboutTabsNav`), bandeau de chiffres (projets financés, subvention maximale,
   cohortes) lu depuis les clés éditoriales, puis une section par cohorte (titre, année, focus, bilan) avec
   les portraits publiés : photo, nom, projet, département, verbatim, liens site et réseaux. CTA
   « Vous êtes alumni entrepreneur ? Devenir mentor » (lien e-mail).
2. `/entrepreneuriat/partenaires` : trois familles (académiques et institutionnels, organisations d'appui,
   organisations internationales), chaque partenaire avec logo, description, site web et réseaux sociaux,
   depuis `/api/public/entrepreneurship/partners`. Réutiliser la carte partenaire de `/a-propos/partenaires`.
3. `/entrepreneuriat/ressources` : deux blocs. « Médiathèque » : albums photo et vidéos de la DDE via
   `service_media_library` (réutiliser la galerie de la fiche service ou de la médiathèque publique).
   « Boîte à outils » : ressources publiées groupées par catégorie, documents téléchargeables via
   `/api/public/media/{id}/download`, liens externes, vidéos.
4. `/entrepreneuriat/actualites` : liste paginée des actualités et événements liés à la DDE (filtre
   `service_id`), même cartes que `/actualites`, lien vers l'article complet existant (pas de duplication
   de pages d'article).
5. i18n, SEO (sitemap, OG), responsive 390 px, repli FR silencieux, RTL.

Hors périmètre : page SEE, menu principal, organigramme.

Critères d'acceptation : chaque rubrique est atteignable depuis la sous-navigation et rend en SSR ;
un lauréat dépublié disparaît de la page ; un document de la boîte à outils se télécharge ; aucune
nouvelle page d'article ou de partenaire n'est créée en doublon.
```

### Feature 025 — Page « Entreprendre et étudier » : Statut Étudiant-Entrepreneur (guide, FAQ, candidature)

> ✅ **Livrée** (2026-09-14, `specs/025-pei-see-status-page/`). Portée retenue : quatre catégories FAQ au code
> réservé `see-*` (visibles aussi sur `/faq`) lues via `GET /api/public/faq?category_prefix=see-` ; conditions
> et pièces **de l'appel d'abord, textes éditoriaux en secours** ; état d'appel ouvert / à venir / clos / absent
> sans erreur ; migration `049_pei_see_page.sql` (65 clés, 4 catégories, 8 questions dont 2 publiées et
> 6 brouillons) ; la 9ᵉ question du cahier des charges reste à créer par l'équipe dans le backoffice FAQ.

**Dépend de** : 023. **Livre** : `/entrepreneuriat/statut-etudiant-entrepreneur`, catégorie FAQ « see », liaison à l'appel.

```
Créer la page publique « Entreprendre et étudier à Senghor » dédiée au Statut Étudiant-Entrepreneur (SEE),
appel à l'action permanent du mini-site du PEI, selon les pages 4 à 7 du cahier des charges.

Maquette à suivre : `specs/maquettes-pei/statut-etudiant-entrepreneur.png` (ordre des sections : intro
et cartes SEE 1 / SEE 2, six leviers, conditions + critères + dossier avec agenda collant, FAQ groupée,
CTA final) et `specs/maquettes-pei/statut-etudiant-entrepreneur.html` (valeurs exactes). L'agenda de la
maquette est un exemple avec les dates 2026 du cahier des charges : en production il vient de l'appel.

Contraintes de réutilisation :
- Hero `PageHero` (mode motif, badge « Statut Étudiant-Entrepreneur · Appel {année} »), layout par défaut,
  sous-navigation du pôle avec le bouton « Postuler au statut » mis en évidence.
- FAQ : les questions/réponses vivent dans le backoffice FAQ existant, dans une catégorie de code réservé
  `see` ; la page affiche cette catégorie seule avec le composant d'accordéon de `/faq` (sous-groupes
  Généralités, Avantages et aménagements, Engagement et risques, Confidentialité). Seed de la catégorie et
  des 9 questions du cahier des charges par migration.
- Appel à candidatures : l'appel SEE est un `application_calls` de type `training` géré dans le backoffice
  des appels (critères d'éligibilité, pièces du dossier, calendrier, formulaire). La page lit l'appel dont
  le slug est dans la clé éditoriale `entrepreneurship.see.call_slug` et affiche son calendrier, ses pièces
  et son bouton « Postuler via le formulaire » ; si l'appel est fermé, afficher un état « appel clos,
  prochaine session » avec le formulaire de contact. Pas de nouveau formulaire de candidature.
- Textes du guide (intro, SEE 1 / SEE 2, six avantages, conditions, critères du jury) : clés éditoriales
  `entrepreneurship.see.*` créées en 021, complétées ici si besoin, éditables dans la page « Valeurs ».

Périmètre :
1. Sections dans l'ordre : intro « Vous avez une idée ? Nous avons le cadre pour la faire grandir » +
   encadré « Le SEE, c'est quoi ? » avec cartes SEE 1 et SEE 2 ; « Pourquoi postuler ? » (6 leviers avec
   icônes Font Awesome) ; « Suis-je le bon candidat ? » (conditions, critères du jury, dossier) avec
   l'agenda de l'appel en panneau collant ; FAQ ; lien vers le réseau PÉPITE France ; CTA final avec
   e-mail `entrepreneuriat@usenghor.org` et rappel « mettre votre directeur de département en copie ».
2. JSON-LD `FAQPage` en SSR (même mécanisme que `/faq`).
3. i18n, SEO, responsive, RTL.

Hors périmètre : workflow de sélection des candidatures (déjà couvert par le module Candidatures), menu.

Critères d'acceptation : la page reflète en direct l'appel ouvert et ses dates ; une question modifiée
dans le backoffice FAQ apparaît sans redéploiement ; le bouton « Postuler » mène au formulaire de l'appel ;
un appel clos affiche l'état prévu sans erreur.
```

### Feature 026 — Rattachement à l'organigramme, navigation et mise en ligne

**Dépend de** : 023 à 025. **Livre** : `services.parent_id` + `landing_path`, carte « pôle » sur la fiche DDE, menu « Plus », fil d'Ariane, redirections, déploiement.

```
Rattacher le Pôle Entrepreneuriat et Innovation (PEI) à l'organigramme et l'intégrer à la navigation du
site, puis préparer la mise en ligne.

Maquette : colonne « Organigramme (existant) » de `specs/maquettes-pei/arborescence.png` (Rectorat →
DDE → pôle PEI, carte du pôle renvoyant vers le mini-site) et fil d'Ariane du hero de `accueil.png`.

Périmètre :
1. Niveau « pôle » dans l'organigramme (décision D1) : ajouter à `services` les colonnes `parent_id`
   (UUID nullable, FK vers `services.id`, un seul niveau de profondeur) et `landing_path` (chemin public
   optionnel, ex. `/entrepreneuriat`). Mettre à jour `04_organization.sql`, une migration rejouable, les
   schémas Pydantic, les endpoints admin et publics des services (`with-services` renvoie les pôles sous
   leur service parent), et le formulaire admin des services (sélecteur « Service parent » limité aux
   services du même secteur, champ « Page dédiée »). Créer par migration le service « Pôle Entrepreneuriat
   et Innovation (PEI) » rattaché à la DDE avec `landing_path = /entrepreneuriat`, sigle `PEI`.
   Alternative si D1 est refusée : ne rien migrer, ajouter un encart « Pôles » dans le contenu riche de la DDE.
2. Affichage public : sur la fiche service de la DDE (`/a-propos/organisation/service/...`), nouvel onglet ou
   bloc « Pôles » listant les services enfants sous forme de cartes (style des cartes de
   `OrganizationOrganigrammeSection`) ; une carte avec `landing_path` renvoie vers ce chemin, sinon vers
   la fiche générique. Dans `OrganizationOrganigrammeSection`, les pôles apparaissent sous leur service
   parent (indentation légère), pas comme des services du secteur.
3. Menu : ajouter « Entreprendre à Senghor » (→ `/entrepreneuriat`) dans le menu « Plus » via la clé
   éditoriale `navbar.secondary.*.children` (migration de seed, pas de code dans `AppNavBar`), et un lien
   dans le pied de page (groupe « L'Université ») si `AppFooter` lit une source éditoriale ; sinon l'ajouter
   dans les fichiers i18n du footer.
4. Fil d'Ariane du mini-site : Accueil › Nous connaître › Organisation › DDE › PEI, chaque niveau cliquable.
5. Lien court `/pei` via le raccourcisseur de liens existant (seed).
6. Mise en ligne : vérifier les migrations en production (`docker exec -i usenghor_db psql ...`), les
   permissions des rôles existants, le sitemap, les redirections, et mettre à jour CLAUDE.md
   (tables, section admin, routes publiques, composables). Ne pas déployer sans commit + push préalable.

Hors périmètre : contenu éditorial (saisi par l'équipe du pôle dans le backoffice).

Critères d'acceptation : le PEI apparaît sous la DDE dans l'organigramme et sa carte mène au mini-site ;
un service sans enfants ne change pas d'affichage ; le menu « Plus » propose l'entrée dans les trois
langues ; la migration est rejouable et son rollback documenté ; aucune régression sur les fiches secteur
et service existantes.
```

---

## 4. Après la dernière feature

- Faire saisir le contenu réel (photos d'étudiants, portraits et verbatims des lauréats, logos des
  partenaires, documents de la boîte à outils) par l'équipe du pôle dans le backoffice.
- Ouvrir l'appel SEE 2026 dans le module Candidatures et renseigner `entrepreneurship.see.call_slug`.
- Contrôler les traductions automatiques EN/AR générées et les corriger dans les onglets EN/AR.
