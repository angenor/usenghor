# Feature Specification: Mini-site public « Entreprendre à Senghor » — alumni, partenaires, ressources, actualités

**Feature Branch**: `024-pei-public-alumni-resources-news`

**Created**: 2026-09-14

**Status**: Draft

**Input**: User description: "Compléter le mini-site « Entreprendre à Senghor » avec les quatre rubriques restantes : `/entrepreneuriat/alumni`, `/entrepreneuriat/partenaires`, `/entrepreneuriat/ressources`, `/entrepreneuriat/actualites`. [...] Reprendre exactement les conventions de la 023 (structure de page, fil d'Ariane, SEO, i18n, masquage des sections vides) : les quatre pages doivent être visuellement cohérentes avec `/entrepreneuriat/activites`. Maquette `alumni.png` / `alumni.html` pour la page alumni ; les trois autres pages reprennent des blocs de `accueil.png` / `accueil.html`. Périmètre : alumni (sous-onglets par type dans l'adresse, bandeau de chiffres éditorial, sections par cohorte, cartes portrait, CTA mentor), partenaires (trois familles, logo / description / site web / réseaux), ressources (médiathèque de la DDE + boîte à outils par catégorie), actualités (actualités et événements DDE paginés, mêmes cartes que `/actualites`), clés éditoriales manquantes via migration 048 rejouable (+ rollback, accord préalable sur le SQL), i18n FR/EN/AR, RTL, SEO (OG, sitemap, JSON-LD BreadcrumbList + CollectionPage), responsive 390 px, mode sombre. Hors périmètre : page SEE, menu principal, organigramme, backoffices."

**Références** : `specs/roadmap-pei-entrepreneuriat.md` (règles transversales, prompt 024), `specs/021-pei-entrepreneurship-core/` (cohortes, ressources, clés éditoriales `entrepreneurship.*`, lecture publique), `specs/022-pei-laureates-partners/` (portraits, partenaires par famille, lecture publique, clarifications Q2 et Q5), `specs/023-pei-public-home-activities/` (cadre commun du mini-site : hero, sous-navigation, fil d'Ariane, SEO, i18n, masquage), `specs/maquettes-pei/README.md`, `specs/maquettes-pei/alumni.{png,html}`, `specs/maquettes-pei/accueil.{png,html}`.

## Contexte

Les features 021 et 022 ont livré les données du Pôle Entrepreneuriat et Innovation (PEI) : cohortes (label, année, type FSE / SEE, focus, bilan riche), portraits publiés (lauréats du Fonds de Soutien à l'Entrepreneuriat et étudiants-entrepreneurs : photo, nom, projet, département, verbatim, liens, mise en avant), partenaires rattachés au pôle par famille, boîte à outils (documents, liens, vidéos, catégorie libre). La feature 023 a ouvert le mini-site public avec l'accueil et « Nos activités », et posé son cadre commun : hero, sous-navigation collante (dont les six rubriques pointent déjà vers les quatre adresses de cette feature), fil d'Ariane, référencement, libellés trilingues, masquage des sections vides, rattachement au service « Direction du Développement et de l'Entrepreneuriat » (DDE) par une clé éditoriale.

Aujourd'hui, les quatre rubriques restantes de la sous-navigation répondent par la page « introuvable » du site. Cette feature les livre : **« Nos alumni »** (portraits par cohorte), **« Nos partenaires »** (écosystème d'appui détaillé), **« Nos ressources »** (médiathèque de la DDE et boîte à outils) et **« Actualités »** (vie du pôle : actualités et événements rattachés à la DDE). Comme pour la 023, rien n'est dupliqué : les actualités, événements, albums et partenaires restent gérés dans leurs backoffices d'origine et ouvrent leurs pages existantes.

## Clarifications

### Session 2026-09-14 (décisions prises dans la description de la feature)

- Les trois chiffres du bandeau alumni sont **saisis en backoffice** (clés éditoriales créées ici), et non calculés (la lecture publique des portraits renvoie aussi des agrégats, laissés en réserve — clarification Q5 de la 022).
- Les partenaires du pôle n'ont **aucun lien de réseau social** en base (clarification Q2 de la 022, backoffice Partenaires inchangé et hors périmètre) : la page partenaires affiche logo, nom, description et site web ; la mention « réseaux sociaux » de la description est traitée comme « liens du partenaire disponibles », c'est-à-dire le site web uniquement.
- Le sous-onglet courant de la page alumni est porté par l'**adresse** (paramètre de requête `type`), pour le partage de lien et le rendu serveur.
- Les libellés fixes des quatre pages (intitulés de blocs génériques, boutons, états vides, textes d'accessibilité) sont traduits ; la copie de page (heros, chiffres, titres de section éditoriaux, CTA) suit la convention monolingue du système éditorial (clarification Q1 de la 023).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Découvrir les portraits d'alumni par cohorte (Priority: P1)

Un visiteur ouvre `/entrepreneuriat/alumni` depuis la sous-navigation. Il voit le hero du site (badge « Portraits et témoignages », titre « Nos alumni et lauréats », sous-titre, fil d'Ariane prolongé de « Nos alumni »), la sous-navigation avec « Nos alumni » active, puis une barre de deux sous-onglets pilule « Lauréats FSE » (actif par défaut) et « Étudiants entrepreneurs ». Sous les onglets, un bandeau bleu foncé affiche trois chiffres (« 15 · projets financés depuis 2023 », « 5 000 € · de subvention d'amorçage maximum », « 3 · cohortes, dont les alumni sont mentors »). Vient ensuite le titre de section (« Lauréats FSE » / « Portraits de lauréats et témoignages ») puis **une section par cohorte** dans l'ordre du backoffice : titre de la cohorte, sous-titre (année · focus), badge de focus, bilan riche (s'il existe), et une grille de cartes portrait (4 colonnes) : photo (ou substitut), nom, badge de cohorte, nom du projet, département, verbatim en italique (s'il existe), icônes de liens (site web, LinkedIn, Instagram, Facebook, vidéo — seuls les liens renseignés). Les portraits **mis en avant** apparaissent en premier dans leur cohorte. En bas de page, l'encart « Vous êtes alumni entrepreneur ? » avec le bouton « Devenir mentor » qui ouvre un e-mail à l'adresse du pôle. En cliquant « Étudiants entrepreneurs », l'adresse devient `/entrepreneuriat/alumni?type=student_entrepreneur` et les sections affichent les cohortes SEE et leurs portraits.

**Why this priority**: C'est la seule rubrique dessinée par la maquette et la vitrine des résultats du pôle (les données de la 022 n'ont aucun rendu public aujourd'hui) ; elle porte aussi le seul élément nouveau du cadre commun (sous-onglets par adresse).

**Independent Test**: Avec les données initiales des features 021 / 022 (trois cohortes FSE, au moins une cohorte SEE, des portraits publiés des deux types dont un mis en avant et un dépublié), ouvrir `/entrepreneuriat/alumni` sans être connecté ; vérifier chaque bloc de la maquette dans l'ordre ; basculer l'onglet ; partager l'adresse avec `?type=student_entrepreneur` et constater le bon onglet dès le chargement ; dépublier un portrait et constater sa disparition au rechargement.

**Acceptance Scenarios**:

1. **Given** trois cohortes FSE actives avec des portraits publiés, **When** le visiteur ouvre `/entrepreneuriat/alumni`, **Then** l'onglet « Lauréats FSE » est actif, une section par cohorte apparaît dans l'ordre du backoffice avec son titre, son année, son focus et son bilan, et chaque portrait publié de la cohorte est présent une seule fois, dans l'ordre du backoffice, les portraits mis en avant d'abord.
2. **Given** un portrait avec photo, verbatim, site web et vidéo mais sans LinkedIn / Instagram / Facebook, **When** sa carte s'affiche, **Then** elle montre la photo, le nom, le badge de la cohorte, le projet, le département, le verbatim, et exactement deux icônes de lien (site, vidéo) ouvrant chacune la cible dans un nouvel onglet ; un portrait sans photo montre un substitut neutre, un portrait sans verbatim n'affiche pas de bloc vide.
3. **Given** l'adresse `/entrepreneuriat/alumni?type=student_entrepreneur` ouverte directement, **When** la page se charge, **Then** l'onglet « Étudiants entrepreneurs » est actif dès le rendu serveur et seules les cohortes SEE ayant des portraits publiés sont listées ; un `type` inconnu retombe sur l'onglet par défaut sans erreur.
4. **Given** un portrait dépublié en backoffice, **When** le visiteur recharge la page (au plus une minute après), **Then** le portrait n'apparaît plus ; si sa cohorte n'a plus aucun portrait publié, la section de la cohorte disparaît entièrement.
5. **Given** les trois clés de chiffres renseignées, **When** le bandeau s'affiche, **Then** les trois valeurs et libellés du backoffice sont visibles ; une clé sans valeur retire son chiffre du bandeau ; aucune valeur → bandeau masqué.
6. **Given** la clé e-mail du pôle renseignée, **When** le visiteur clique « Devenir mentor », **Then** son client de messagerie s'ouvre avec cette adresse en destinataire ; sans e-mail, l'encart est masqué.
7. **Given** aucun portrait publié pour le type sélectionné, **When** la section s'affiche, **Then** un état vide propre (message traduit) remplace la liste, sans erreur, et les onglets restent utilisables.

---

### User Story 2 - Parcourir l'écosystème de partenaires du pôle (Priority: P2)

Le visiteur ouvre `/entrepreneuriat/partenaires`. Sous le hero et la sous-navigation, il retrouve les trois familles de la section « Nos partenaires » de l'accueil, dans le même ordre et avec les mêmes intitulés (académiques et institutionnels, organisations d'appui, organisations internationales), mais en version détaillée : pour chaque partenaire actif, une carte avec logo (ou nom si absent), nom, description dans la langue du visiteur (repli français) et lien vers le site web (nouvel onglet) lorsqu'il existe. Une famille sans partenaire n'apparaît pas.

**Why this priority**: Rubrique simple, entièrement alimentée par la lecture publique de la 022 ; elle complète la vitrine institutionnelle du pôle et réutilise le composant de familles de l'accueil.

**Independent Test**: Avec des partenaires rattachés dans deux familles (dont un sans logo, un sans site web et un inactif), ouvrir la page ; vérifier deux familles seulement, les cartes complètes, l'absence du partenaire inactif ; vérifier que l'accueil `/entrepreneuriat` et `/a-propos/partenaires` sont inchangés.

**Acceptance Scenarios**:

1. **Given** des partenaires rattachés dans les familles « académiques » et « internationales », **When** la page s'affiche, **Then** seules ces deux familles apparaissent, dans l'ordre fixe, chacune avec l'intitulé traduit et ses cartes dans l'ordre du backoffice.
2. **Given** un partenaire sans logo et sans site web, **When** sa carte s'affiche, **Then** son nom tient lieu de logo et aucun lien n'est rendu ; un partenaire avec site web a un lien explicite ouvrant un nouvel onglet.
3. **Given** un partenaire désactivé dans le backoffice Partenaires, **When** la page se recharge, **Then** il n'apparaît plus ; s'il était le dernier de sa famille, la famille disparaît.
4. **Given** aucun partenaire rattaché, **When** la page s'affiche, **Then** un état vide propre (message traduit) s'affiche sous le hero, sans erreur.

---

### User Story 3 - Consulter les ressources : médiathèque et boîte à outils (Priority: P2)

Le visiteur ouvre `/entrepreneuriat/ressources`. Deux blocs : **« Médiathèque »**, qui présente les albums (photos et vidéos) rattachés au service DDE sous forme de cartes d'album ouvrant la visionneuse du site (grille, filtre par type, lecture des vidéos hébergées, téléchargement) ; **« Boîte à outils »**, qui liste les ressources publiées groupées par catégorie (dans la langue du visiteur, repli français), chaque ressource en carte : icône selon le type, titre, description, et une action : « Télécharger » pour un document, « Ouvrir » pour un lien externe (nouvel onglet), « Voir la vidéo » pour une vidéo externe (nouvel onglet, vignette du fournisseur quand elle peut être déduite).

**Why this priority**: Rubrique de service très demandée (guides, formulaires), mais dépendante de la constitution des albums et de la boîte à outils en backoffice ; livrable indépendamment des deux premières.

**Independent Test**: Avec deux albums rattachés au service DDE (photos + une vidéo hébergée) et des ressources publiées de trois types dans deux catégories (plus une sans catégorie et une dépubliée), ouvrir la page ; ouvrir un album, filtrer par vidéo, lire la vidéo ; télécharger un document ; ouvrir un lien et une vidéo externe ; vérifier `/mediatheque` et la fiche du service DDE inchangées.

**Acceptance Scenarios**:

1. **Given** deux albums rattachés au service DDE, **When** le bloc « Médiathèque » s'affiche, **Then** deux cartes d'album (titre, aperçu, compteurs par type) apparaissent ; cliquer une carte ouvre la visionneuse du site avec ses photos et vidéos, la lecture d'une vidéo hébergée fonctionne, et la visionneuse se ferme proprement.
2. **Given** des ressources publiées dans les catégories « Financement » et « Juridique », **When** le bloc « Boîte à outils » s'affiche, **Then** deux groupes titrés apparaissent (ordre d'apparition des ressources), chaque ressource une seule fois dans l'ordre du backoffice, et une ressource sans catégorie est placée dans un groupe « Autres ressources » (libellé traduit) en dernier.
3. **Given** une ressource de type document, **When** le visiteur clique « Télécharger », **Then** le fichier de la médiathèque se télécharge (ou s'ouvre selon le navigateur) via l'adresse publique de téléchargement du site.
4. **Given** une ressource de type lien et une de type vidéo, **When** le visiteur clique leur action, **Then** la cible s'ouvre dans un nouvel onglet sans donner accès à la page d'origine ; la carte vidéo montre une vignette lorsque le fournisseur le permet, sinon l'icône du type.
5. **Given** une ressource dépubliée en backoffice, **When** la page se recharge, **Then** elle n'apparaît plus ; un groupe sans ressource disparaît.
6. **Given** aucun album rattaché à la DDE (ou service DDE non identifié), **When** la page s'affiche, **Then** le bloc « Médiathèque » est masqué entièrement ; **and** sans ressource publiée, le bloc « Boîte à outils » est masqué ; **and** si les deux sont vides, un état vide propre remplace le contenu.

---

### User Story 4 - Suivre la vie du pôle : actualités et événements (Priority: P2)

Le visiteur ouvre `/entrepreneuriat/actualites`. Sous le hero et la sous-navigation, un bloc **« Actualités »** liste les actualités publiées rattachées au service DDE, de la plus récente à la plus ancienne, avec **les mêmes cartes** que la page `/actualites` du site (visuel, catégorie ou date, titre, résumé), par lots (premier lot rendu serveur, bouton « Voir plus » pour les suivants) ; chaque carte ouvre l'article existant. Un bloc **« Événements »** liste les événements rattachés à la DDE : « À venir » (du plus proche au plus lointain) puis « Passés » (du plus récent au plus ancien), chacun avec date, titre, lieu et lien vers la fiche événement existante, par lots avec « Voir plus ».

**Why this priority**: Prolonge la section « La vie du pôle » de l'accueil (qui pointe déjà vers cette adresse par « Toutes les actualités du PEI ») ; dépend uniquement de contenus déjà gérés par les backoffices existants.

**Independent Test**: Avec quinze actualités DDE, trois événements DDE à venir, cinq passés et des actualités / événements d'autres services, ouvrir la page ; vérifier le filtrage, l'ordre, les lots, les liens vers les pages existantes ; comparer une carte à celle de `/actualites` ; vérifier `/actualites` inchangée.

**Acceptance Scenarios**:

1. **Given** quinze actualités publiées rattachées à la DDE et d'autres non rattachées, **When** la page s'affiche, **Then** seules les actualités DDE apparaissent, les plus récentes d'abord, par lot de douze, avec un bouton « Voir plus » qui révèle les suivantes et disparaît quand tout est affiché ; aucune actualité d'un autre service n'est visible.
2. **Given** une carte d'actualité de la page, **When** on la compare à la même actualité sur `/actualites`, **Then** l'aspect et le contenu sont identiques et le clic mène au même article.
3. **Given** trois événements DDE à venir et cinq passés, **When** le bloc « Événements » s'affiche, **Then** « À venir » liste les trois du plus proche au plus lointain et « Passés » les cinq du plus récent au plus ancien, chaque entrée menant à la fiche existante ; un sous-bloc sans événement est masqué.
4. **Given** aucune actualité ni aucun événement rattaché à la DDE (ou service DDE non identifié), **When** la page s'affiche, **Then** un état vide propre (message traduit) remplace le contenu, sans erreur.

---

### User Story 5 - Lire les quatre rubriques en anglais et en arabe, sur mobile et en mode sombre (Priority: P3)

Le visiteur ouvre chaque rubrique en anglais et en arabe (sens droite-à-gauche) : libellés fixes traduits, données trilingues dans sa langue avec repli français silencieux, copie de page en français (convention du site), mise en page miroir en arabe (sous-onglets, cartes, bandeau de chiffres, icônes de liens). Sur un téléphone (390 px) et en mode sombre, les quatre pages restent lisibles et complètes ; le partage d'un lien produit un aperçu avec titre, description et image.

**Why this priority**: Exigence transversale du site, vérifiable après la construction des pages.

**Independent Test**: Ouvrir les quatre pages dans les trois langues à 1440 px et 390 px, en clair et en sombre ; vérifier les libellés, le sens de lecture, l'absence de débordement horizontal, le passage des grilles en une colonne, la présence des pages dans le plan du site, et la validité des données structurées.

**Acceptance Scenarios**:

1. **Given** la langue arabe, **When** le visiteur ouvre `/ar/entrepreneuriat/alumni`, **Then** le document est en sens droite-à-gauche, les sous-onglets, le bandeau et les cartes sont en miroir, et aucun libellé fixe n'apparaît en français ou sous forme de clé technique.
2. **Given** un portrait sans département anglais et un partenaire sans description anglaise, **When** le visiteur ouvre les pages en anglais, **Then** les valeurs françaises s'affichent à leur place, sans mention d'erreur.
3. **Given** une largeur de 390 px, **When** le visiteur ouvre chaque page, **Then** les grilles (portraits, partenaires, albums, ressources, actualités) sont en une colonne, les sous-onglets alumni restent accessibles (défilement horizontal ou empilement), et aucun défilement horizontal de page n'apparaît.
4. **Given** le mode sombre, **When** le visiteur ouvre les quatre pages, **Then** cartes, bandeau, encart CTA et états vides ont un contraste suffisant, sans zone blanche non prévue.
5. **Given** le partage de `/entrepreneuriat/ressources`, **When** l'aperçu se génère, **Then** il montre le titre de la rubrique, une description et une image ; les quatre pages figurent dans le plan du site en trois langues et exposent des données structurées de type page de collection et fil d'Ariane valides.

---

### Edge Cases

- **Service DDE non identifié** (clé `entrepreneurship.dde_service_id` vide ou service introuvable) : « Nos ressources » masque le bloc Médiathèque ; « Actualités » affiche l'état vide ; le fil d'Ariane affiche « DDE » sans lien ; aucune erreur visible.
- **Rubrique entièrement vide** (0 portrait du type, 0 partenaire, 0 album et 0 ressource, 0 actualité et 0 événement) : hero, sous-navigation et un état vide propre (icône, message traduit, lien vers l'accueil du pôle) ; jamais de page blanche ni de message d'erreur technique.
- **Section partiellement vide** : un bloc sans données est masqué avec son titre (Médiathèque, Boîte à outils, Événements à venir / passés, bandeau de chiffres, encart mentor sans e-mail) ; les blocs voisins se rejoignent sans espace anormal.
- **Lecture publique indisponible** (erreur ou délai dépassé sur une source) : la page se rend avec les blocs disponibles ; la source en erreur est traitée comme « sans données ».
- **Sous-onglet alumni** : `type` absent → « Lauréats FSE » ; `type` inconnu → onglet par défaut sans redirection ; changement d'onglet sans rechargement complet, l'adresse est mise à jour et l'historique du navigateur permet de revenir ; les deux onglets sont toujours affichés même si l'un est vide.
- **Portrait mis en avant** : classé en premier dans sa cohorte, puis ordre du backoffice ; plusieurs portraits mis en avant conservent entre eux l'ordre du backoffice ; aucun signe distinctif obligatoire au-delà du classement (un marqueur discret est admis).
- **Cohorte sans bilan ni focus** : le sous-titre se limite à l'année ; pas de badge ni de bloc vide.
- **Verbatim long** (jusqu'à 600 caractères) : affiché en entier ; la hauteur des cartes d'une même ligne peut différer sans casser la grille.
- **Liens externes** : site, réseaux, vidéo des portraits, site web des partenaires, liens et vidéos de la boîte à outils s'ouvrent dans un nouvel onglet sans transmettre l'accès à la page d'origine ; une adresse malformée est ignorée (icône non rendue).
- **Ressource vidéo** : lien externe (pas de lecteur tiers intégré, cohérent avec le reste du site) ; vignette dérivée seulement pour les fournisseurs reconnus par le site (YouTube) ; sinon icône du type.
- **Document dont le média a été supprimé** : la lecture publique ne renvoie pas d'adresse → la carte est masquée.
- **Catégorie de ressource** : libellé libre, comparé après normalisation (espaces, casse) sur la valeur française pour le regroupement, affiché dans la langue du visiteur ; ressource sans catégorie → groupe « Autres ressources » en dernier.
- **Albums de la DDE** : un album vide (0 média) est ignoré ; un album contenant uniquement des documents est affiché (la visionneuse propose le téléchargement).
- **Actualités et événements** : une actualité rattachée à la DDE **et** à un autre service apparaît une seule fois ; la répartition « À venir » / « Passés » se fait sur la **date de début** (règle existante de la page Événements du site) : un événement déjà commencé, même non terminé, est classé « Passés » ; chaque événement apparaît dans exactement une des deux listes.
- **Clés éditoriales non chargées** (environnement neuf, migration 048 non jouée) : les heros affichent au minimum le titre de rubrique traduit (libellé fixe) ; aucune clé brute ; le bandeau de chiffres et les titres éditoriaux sont masqués.
- **Cache** : une modification en backoffice est visible au plus une minute après (convention des lectures publiques du pôle).

## Requirements *(mandatory)*

### Functional Requirements

**Cadre commun des quatre pages**

- **FR-001**: Chaque page MUST reprendre la structure de `/entrepreneuriat/activites` : hero du site (badge, titre, sous-titre, image ou motif, lus dans des clés éditoriales dédiées à la page), fil d'Ariane « Accueil › Nous connaître › Organisation › DDE › Pôle Entrepreneuriat et Innovation › [Rubrique] », sous-navigation du pôle avec la rubrique courante active, en-tête et pied de page du layout.
- **FR-002**: Chaque page MUST être rendue côté serveur avec ses données (contenu visible sans script), dans les trois langues, et MUST être atteignable depuis la sous-navigation existante sans modification de celle-ci.
- **FR-003**: Aucun texte visible ne MUST être codé en dur : copie de page dans les clés éditoriales « Entrepreneuriat » ; libellés fixes (intitulés de blocs génériques, boutons, états vides, textes d'accessibilité, intitulés de familles) dans les traductions FR / EN / AR ; données métier via les lectures publiques existantes du pôle, des actualités, des événements, des services et des albums. Aucune page publique ne MUST appeler une lecture réservée à l'administration.
- **FR-004**: Les champs trilingues MUST être lus avec le repli français silencieux du site ; la copie de page éditoriale s'affiche telle quelle dans les trois langues (convention du site).
- **FR-005**: Tout bloc dont la source ne renvoie aucune donnée, ou est en erreur, MUST être masqué entièrement (titre compris), sans message d'erreur, sans empêcher le rendu des autres blocs ; lorsqu'**aucun** bloc de contenu d'une page n'a de données, la page MUST afficher un état vide propre (icône, message traduit, lien vers l'accueil du pôle) sous le hero et la sous-navigation.
- **FR-006**: Le rattachement à la DDE (fil d'Ariane, médiathèque, actualités, événements) MUST utiliser la clé éditoriale `entrepreneurship.dde_service_id` ; clé vide ou service introuvable → blocs dépendants masqués, « DDE » non cliquable.
- **FR-007**: Avant tout nouveau composant, l'existence d'un composant similaire MUST être vérifiée ; les composants publics du pôle MUST rester dans le dossier public du pôle, distinct de l'administration. Inventaire vérifié pour cette feature : aucune carte de portrait, aucune carte de ressource, aucune carte de partenaire branchée sur la lecture publique du pôle n'existe (la carte partenaire du site est liée aux données fictives) ; le composant de familles du pôle n'affiche que des logos ; la visionneuse d'albums, la carte d'actualité partagée, la liste d'événements du pôle, le panneau de chiffres, le bandeau CTA et les sous-onglets « Nous connaître » existent et servent de base.

**Page « Nos alumni » `/entrepreneuriat/alumni`**

- **FR-008**: La page MUST afficher, dans l'ordre de `alumni.png` : hero, sous-navigation, barre de deux sous-onglets pilule (« Lauréats FSE », « Étudiants entrepreneurs ») dans le style des sous-onglets « Nous connaître », bandeau de chiffres, titre de section (badge + titre) propre à l'onglet, sections par cohorte, encart « Devenir mentor ».
- **FR-009**: Le sous-onglet courant MUST être déterminé par le paramètre d'adresse `type` (`fse_laureate` par défaut, `student_entrepreneur`), présent dès le rendu serveur ; le changement d'onglet MUST mettre à jour l'adresse (historique navigable) et le contenu sans rechargement complet ; une valeur inconnue retombe sur l'onglet par défaut ; les deux onglets sont toujours visibles.
- **FR-010**: Le bandeau MUST afficher jusqu'à trois chiffres (valeur + libellé) lus dans les clés éditoriales `entrepreneurship.alumni.stats.{1,2,3}.{value,label}`, dans le style du bandeau sombre de la maquette (valeur en grand, libellé en capitales espacées, séparateurs) ; un chiffre sans valeur est omis ; aucun chiffre → bandeau masqué ; les valeurs sont affichées telles que saisies (« 5 000 € », « 15 »).
- **FR-011**: Pour le type sélectionné, la page MUST afficher une section par cohorte ayant au moins un portrait publié, dans l'ordre du backoffice : libellé de la cohorte (titre), sous-titre « année · focus », badge de focus (ambre, comme la maquette) si le focus existe, bilan riche rendu par le composant de texte riche du site s'il existe, puis la grille des portraits.
- **FR-012**: Chaque carte portrait MUST afficher : photo (format paysage 4:3, substitut neutre si absente), nom, badge de cohorte (libellé court), nom du projet, département, verbatim en italique s'il existe, et une rangée d'icônes de liens limitée aux adresses renseignées (site web, LinkedIn, Instagram, Facebook, vidéo), chacune avec un libellé accessible traduit et ouvrant un nouvel onglet en sécurité. Les portraits mis en avant MUST précéder les autres dans leur cohorte, à ordre du backoffice conservé par ailleurs.
- **FR-013**: L'encart mentor MUST afficher le titre, la description et le bouton lus dans les clés existantes `entrepreneurship.see.mentor.{title,description,button}` ; le bouton MUST ouvrir un e-mail à l'adresse `entrepreneurship.contact.email` ; sans adresse, l'encart est masqué.

**Page « Nos partenaires » `/entrepreneuriat/partenaires`**

- **FR-014**: La page MUST afficher les familles non vides dans l'ordre fixe (académiques et institutionnels, organisations d'appui, organisations internationales), avec l'intitulé traduit et le style de la section « Nos partenaires » de `accueil.png`, chaque partenaire actif en carte détaillée dans l'ordre du backoffice : logo (nom en texte si absent), nom, description (langue du visiteur, repli français), lien vers le site web (nouvel onglet, sécurisé) s'il existe.
- **FR-015**: La version détaillée MUST être obtenue en **étendant** le composant de familles du pôle utilisé par l'accueil (variante « détaillée »), sans changer le rendu de l'accueil `/entrepreneuriat` (variante « logos ») ni celui de `/a-propos/partenaires`.
- **FR-016**: Aucun lien de réseau social n'est affiché (donnée inexistante, hors périmètre) ; aucune page de détail de partenaire n'est créée.

**Page « Nos ressources » `/entrepreneuriat/ressources`**

- **FR-017**: Le bloc « Médiathèque » MUST afficher les albums rattachés au service DDE (médiathèque du service, lue via la fiche publique du service) sous forme des cartes d'album du site, ouvrant la visionneuse d'album existante (grille, vue unique, filtre par type, lecture des vidéos hébergées, téléchargement des documents) ; albums vides ignorés ; aucun album → bloc masqué.
- **FR-018**: Le bloc « Boîte à outils » MUST afficher les ressources publiées groupées par catégorie (regroupement sur la valeur française normalisée, intitulé affiché dans la langue du visiteur, groupes dans l'ordre d'apparition des ressources, ressources sans catégorie regroupées en dernier sous un intitulé traduit « Autres ressources »), chaque ressource en carte dans le style des cartes de `accueil.html` : icône du type, titre, description, action.
- **FR-019**: L'action d'une ressource MUST dépendre de son type : document → « Télécharger » vers l'adresse publique de téléchargement du média (une ressource dont le média a disparu est masquée) ; lien → « Ouvrir » vers l'adresse dans un nouvel onglet sécurisé ; vidéo → « Voir la vidéo » vers l'adresse dans un nouvel onglet sécurisé, avec une vignette du fournisseur lorsque le site sait la déduire (YouTube), sinon l'icône du type ; aucun lecteur tiers intégré.
- **FR-020**: Les intitulés « Médiathèque » et « Boîte à outils » sont des libellés fixes traduits ; la page MUST ne pas modifier `/mediatheque` ni la fiche publique du service.

**Page « Actualités » `/entrepreneuriat/actualites`**

- **FR-021**: Le bloc « Actualités » MUST lister les actualités publiées rattachées au service DDE, des plus récentes aux plus anciennes, avec la carte d'actualité partagée extraite en 023 (aspect et contenu identiques à `/actualites`), chaque carte menant à l'article existant ; affichage par lots de douze : premier lot rendu serveur, bouton « Voir plus » (libellé traduit) révélant les suivants et disparaissant à la fin.
- **FR-022**: Le bloc « Événements » MUST lister les événements publiés rattachés à la DDE en deux sous-blocs répartis sur la date de début : « À venir » (date de début à partir de maintenant, du plus proche au plus lointain) puis « Passés » (date de début antérieure, du plus récent au plus ancien), chaque entrée avec date, titre, lieu et lien vers la fiche événement existante, avec la liste d'événements du pôle (023) ; sous-bloc vide masqué ; chaque sous-bloc par lots de dix avec « Voir plus », chaque lot étant complet (filtrage à la source, pas de tri après coup).
- **FR-023**: Aucune page d'article, d'événement, d'album ou de partenaire ne MUST être créée ; la page `/actualites` MUST rester inchangée (comparaison de captures).

**Contenu éditorial et migration**

- **FR-024**: Les clés éditoriales manquantes MUST être ajoutées à la configuration de la page éditoriale « Entrepreneuriat » (sections dédiées) **et** seedées par une migration rejouable numérotée 048 avec script de retour arrière, sur le modèle de la 047 (insertion sans écrasement d'une valeur existante), le SQL étant soumis à accord préalable avant tout code. Clés proposées (26) :
  - heros des quatre pages : `entrepreneurship.{alumni,partners,resources,news}.hero.{badge,title,subtitle,image}` (16 clés ; valeurs FR initiales issues de la maquette alumni pour la page alumni et du cahier des charges pour les autres, images vides) ;
  - bandeau alumni : `entrepreneurship.alumni.stats.{1,2,3}.{value,label}` (6 clés ; valeurs initiales « 15 / projets financés depuis 2023 », « 5 000 € / de subvention d'amorçage maximum », « 3 / cohortes, dont les alumni sont mentors ») ;
  - titres de section alumni : `entrepreneurship.alumni.fse.{badge,title}` (« Lauréats FSE » / « Portraits de lauréats et témoignages ») et `entrepreneurship.alumni.see.{badge,title}` (« Étudiants entrepreneurs » / « Portraits d'étudiants-entrepreneurs ») (4 clés).
  Les clés de l'encart mentor et de l'e-mail existent déjà (021) et sont réutilisées. Total attendu après migration : 73 clés `entrepreneurship.*` déclarées côté configuration et 74 lignes `entrepreneurship.%` en base (la base compte une clé de plus que la configuration depuis la 045 ; écart préexistant, documenté par la migration 047).
- **FR-025**: Aucune modification de structure de données (tables, colonnes, énumérations) ni de lecture publique n'est attendue ; si le tri « mis en avant en premier » ou le regroupement par catégorie exige un traitement, il est réalisé à l'affichage.

**Internationalisation, référencement, responsive**

- **FR-026**: Les libellés fixes des quatre pages MUST exister en français, anglais et arabe dans l'espace de traduction du pôle ; en arabe, les pages MUST se rendre en sens droite-à-gauche (sous-onglets, bandeau, cartes, icônes de liens en miroir).
- **FR-027**: Chaque page MUST déclarer titre, description et balises de partage (titre, description, image, adresse, langue et langues alternatives) après la résolution de sa route (contrainte connue du site) ; pour la page alumni, l'adresse partagée MUST conserver le paramètre `type`.
- **FR-028**: Chaque page MUST exposer des données structurées : organisation du pôle (existant), **page de collection** (type « CollectionPage ») et **fil d'Ariane** cohérent avec le fil affiché ; les quatre pages MUST figurer dans le plan du site en trois langues (découverte automatique des pages statiques, à vérifier).
- **FR-029**: Les quatre pages MUST fonctionner à 390 px de large (grilles en une colonne, sous-onglets accessibles, aucun défilement horizontal de page) et en mode sombre.

**Non-régression et documentation**

- **FR-030**: `/actualites`, `/mediatheque`, `/a-propos/partenaires`, `/entrepreneuriat` et la fiche publique du service DDE MUST rester visuellement et fonctionnellement inchangées (comparaison de captures à 1440 px et 390 px pour `/actualites`, `/a-propos/partenaires` et l'accueil du pôle).
- **FR-031**: La documentation projet (CLAUDE.md) MUST être mise à jour : quatre routes publiques, extension du composant de familles, nouveaux composants publics du pôle (carte portrait, carte ressource, sous-onglets), clés éditoriales 048.

### Key Entities *(include if data involved)*

Aucune entité nouvelle. Entités lues (toutes existantes) :

- **Portrait** (022) : type (lauréat FSE / étudiant-entrepreneur), nom, projet, département trilingue, verbatim trilingue (≤ 600 caractères), photo, liens (site, LinkedIn, Instagram, Facebook, vidéo), mis en avant, ordre dans la cohorte ; seuls les portraits publiés de cohortes actives sont renvoyés, déjà groupés par cohorte.
- **Cohorte** (021) : libellé, année, type (FSE / SEE), focus, bilan riche, ordre — trilingue.
- **Partenaire du pôle** (022) : famille (fixe, trois valeurs), ordre ; enrichi du nom, logo, description trilingue, site web du partenaire actif. Pas de réseau social.
- **Ressource de la boîte à outils** (021) : titre, description, catégorie (texte libre) trilingues, type (document / lien / vidéo), adresse de téléchargement du média ou adresse externe, ordre ; seules les ressources publiées sont renvoyées.
- **Album de la médiathèque du service DDE** (existant) : titre, médias (image, vidéo, audio, document) avec adresse et type ; liste des albums lue dans la fiche publique du service.
- **Actualité** et **Événement** (existants) : publiés, rattachés au service DDE ; l'événement porte sa date, son lieu et son rattachement.
- **Contenu éditorial « Entrepreneuriat »** (021, 023) : 47 clés existantes, complétées de 26 clés (heros, bandeau alumni, titres de section alumni) ; réutilisation des clés mentor et e-mail.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Les six rubriques de la sous-navigation mènent chacune à une page valide (0 page « introuvable ») dans les trois langues, avec la rubrique active correcte sur 100 % des rubriques.
- **SC-002**: Le contenu principal de chaque page (hero, portraits ou cartes du premier lot, groupes de ressources, familles de partenaires) est présent dans la réponse initiale du serveur, sans exécution de script, dans les trois langues ; pour la page alumni, l'onglet demandé par l'adresse est actif dès cette réponse.
- **SC-003**: 100 % des portraits publiés du type sélectionné sont affichés, une seule fois, dans la bonne cohorte ; un portrait dépublié disparaît au rechargement suivant (délai de cache d'une minute au plus) ; 0 portrait non publié visible.
- **SC-004**: 100 % des documents publiés de la boîte à outils se téléchargent depuis la page en un clic ; 100 % des liens externes (portraits, partenaires, ressources) s'ouvrent dans un nouvel onglet sécurisé.
- **SC-005**: Chacune des situations « sans données » (0 portrait, 0 partenaire, 0 album, 0 ressource, 0 actualité, 0 événement, DDE non identifiée, source en erreur) produit une page sans erreur visible, sans bloc vide, avec un état vide propre lorsque la page entière est vide.
- **SC-006**: Aucune différence visuelle (comparaison de captures avant / après, 1440 px et 390 px) sur `/actualites`, `/a-propos/partenaires` et `/entrepreneuriat` ; `/mediatheque` et la fiche du service DDE fonctionnent à l'identique.
- **SC-007**: Dans les trois langues, 0 clé technique et 0 libellé fixe non traduit visible ; en arabe, sens droite-à-gauche sur 100 % des blocs.
- **SC-008**: À 390 px, 0 défilement horizontal de page sur les quatre pages ; Lighthouse mobile ≥ 90 en performance et ≥ 90 en accessibilité sur chaque page avec les données initiales.
- **SC-009**: Les quatre pages figurent dans le plan du site en trois langues ; l'aperçu de partage affiche titre, description et image ; les données structurées (organisation, page de collection, fil d'Ariane) sont valides dans un validateur.
- **SC-010**: La migration 048 s'exécute deux fois de suite sans erreur en local, puis en production lors de la mise en ligne de la feature ; le nombre de lignes `entrepreneurship.%` est identique après le second passage (74 en local avec les données initiales) et une valeur modifiée en backoffice entre les deux passages est conservée ; le rollback retire exactement les 26 clés ajoutées.
- **SC-011**: Aucune nouvelle page d'article, d'événement, d'album ou de partenaire n'existe après livraison (inventaire des routes publiques : +4 pages exactement).

## Assumptions

- **Chiffres du bandeau alumni** : source unique = clés éditoriales (décision de la description) ; aucun repli sur les agrégats calculés par la lecture publique des portraits, qui restent disponibles pour une évolution ultérieure.
- **Réseaux sociaux des partenaires** : aucun champ n'existe (022, Q2) et le backoffice Partenaires est hors périmètre ; la page affiche logo, nom, description et site web. Ajouter des réseaux relèverait d'une feature dédiée.
- **Sous-onglets par adresse** : paramètre `type` avec les valeurs du type de portrait (`fse_laureate`, `student_entrepreneur`) ; l'adresse sans paramètre est l'adresse canonique de l'onglet par défaut. Le style reprend les pilules de niveau 2 des onglets « Nous connaître » ; ce composant n'a ni props ni gestion de paramètre d'adresse, d'où un petit composant de sous-onglets propre au pôle (vérification faite).
- **Portraits mis en avant en premier** : la lecture publique trie par cohorte puis ordre du backoffice ; le classement « mis en avant d'abord » est appliqué à l'affichage, sans changement d'API.
- **Bilan de cohorte** : rendu en entier sous le sous-titre de la cohorte ; s'il est long, un repli / déplier est admis mais non exigé.
- **Titre de section par onglet** : quatre clés éditoriales (badge + titre pour FSE, badge + titre pour SEE) plutôt que des libellés fixes, car il s'agit de copie de page modifiable par le pôle.
- **Vidéos** : le site ne dispose d'aucun lecteur tiers intégré (YouTube / Vimeo) ; les vidéos hébergées dans la médiathèque se lisent dans la visionneuse existante, les vidéos externes (portraits, boîte à outils) sont des liens sortants, avec vignette YouTube lorsque l'adresse le permet (pratique existante de la médiathèque de projets).
- **Catégories de la boîte à outils** : champ libre sans liste publique ; le regroupement est calculé à l'affichage sur la valeur française normalisée ; l'intitulé affiché est celui de la première ressource du groupe dans la langue du visiteur.
- **Médiathèque de la DDE** : la fiche publique du service renvoie la liste des identifiants d'albums de sa médiathèque ; chaque album est lu par la lecture publique des albums, puis affiché avec la grille + visionneuse du site (celle des pages actualité et événement). La fiche du service utilise sa propre grille et n'est pas modifiée.
- **Pagination** : le site n'a pas de composant de pagination ; on reprend le modèle « premier lot rendu serveur + Voir plus » de `/actualites` (lots de douze actualités, dix événements), avec chargement serveur filtré par service. La numérotation de page dans l'adresse n'est pas exigée.
- **Événements** : le filtrage par service, le tri et les bornes de date existent déjà dans la lecture publique des événements (023) ; la répartition « À venir » / « Passés » se fait sur la date de début, comme sur la page Événements du site : un événement déjà commencé est « passé », chaque événement figure dans une seule liste, et les deux listes sont obtenues par des filtres à la source (aucun tri après coup), ce qui garantit des lots complets.
- **Heros** : images vides dans les données initiales (hero à motif) jusqu'au choix des visuels en backoffice ; le titre de rubrique traduit sert de titre de secours si la clé éditoriale est vide.
- **Copie de page et langues** : convention du site (023, Q1) : copie éditoriale en français dans les trois langues, libellés fixes traduits.
- **Plan du site** : découverte automatique des pages statiques avec préfixes de langue (vérifié) ; aucune liste manuelle à modifier.
- **Données structurées** : le pôle et le fil d'Ariane sont déjà produits par l'outil de données structurées du pôle (023) ; le type « page de collection » est ajouté à cet outil pour les quatre pages.
- **Cache** : lectures publiques mises en cache une minute ; le délai de visibilité d'une modification est accepté.
- **Menu principal et organigramme** : hors périmètre (feature 026) ; le mini-site reste atteignable par son adresse et ses liens internes.

## Dependencies

- Feature 021 : cohortes, ressources, clés éditoriales « Entrepreneuriat » (dont mentor, e-mail, `dde_service_id`), lecture publique.
- Feature 022 : portraits publiés groupés par cohorte (filtre par type), partenaires du pôle par famille.
- Feature 023 : hero étendu, sous-navigation du pôle, fil d'Ariane, carte d'actualité partagée, liste d'événements du pôle, panneau / bandeau de chiffres, bandeau CTA, composable de lecture publique du pôle, outil de données structurées, filtre par service des événements, libellés `pei.*`.
- Backoffices existants : actualités et événements rattachés à la DDE ; médiathèque du service DDE (albums) ; Partenaires (actif, logo, description, site web) ; médiathèque (photos des portraits, documents de la boîte à outils, images des heros).
- Composants et outils existants du site : layout, rendu de texte riche, cartes et visionneuse d'albums, système de traduction et de repli français, référencement (balises de partage, plan du site), style des sous-onglets « Nous connaître ».
- Maquettes `specs/maquettes-pei/alumni.{png,html}` (page alumni) et `accueil.{png,html}` (section partenaires, cartes de la boîte à outils, cartes d'actualités).
- Feuille de route PEI : la feature 025 (page SEE) réutilisera l'encart mentor et les sous-onglets ; la feature 026 branchera le menu principal.
