# Feature Specification: Mini-site public « Entreprendre à Senghor » — accueil et « Nos activités »

**Feature Branch**: `023-pei-public-home-activities`

**Created**: 2026-09-13

**Status**: Draft

**Input**: User description: "Créer le mini-site public « Entreprendre à Senghor » du Pôle Entrepreneuriat et Innovation (PEI) : la page d'accueil (rubrique « Présentation ») et la page « Nos activités ». [...] Périmètre : `/entrepreneuriat` (hero slider, badge, fil d'Ariane, sous-navigation, présentation + chiffres clés, parcours en 5 dispositifs + chips de l'écosystème, citation + impact, 3 actualités DDE, partenaires par famille, CTA), `/entrepreneuriat/activites` (une section par phase, contenu riche, prochains événements DDE), i18n FR/EN/AR + RTL, SEO (OG, sitemap, JSON-LD), responsive 390 px et mode sombre. Contraintes : réutiliser le hero existant (étendu en slider accessible), l'en-tête et le pied de page du layout, les cartes d'actualités existantes, le rendu de texte riche existant ; aucun texte codé en dur ; aucune modification de schéma. Hors périmètre : Nos alumni, Nos partenaires, Nos ressources, Actualités, page SEE, menu principal, organigramme."

**Références** : `specs/roadmap-pei-entrepreneuriat.md` (règles transversales, prompt 023), `specs/021-pei-entrepreneurship-core/` (dispositifs, cohortes, clés éditoriales `entrepreneurship.*`, clé `entrepreneurship.dde_service_id`, lecture publique), `specs/022-pei-laureates-partners/` (lecture publique des partenaires par famille), `specs/maquettes-pei/README.md`, `specs/maquettes-pei/accueil.png` (ordre, contenu, densité des sections) et `accueil.html` (valeurs exactes).

## Contexte

Les features 021 et 022 ont livré les données du Pôle Entrepreneuriat et Innovation (PEI) et leur backoffice : cinq dispositifs du parcours (avec phase, accroche, contenu riche, chiffre mis en avant, couleur, visuel), des cohortes, une boîte à outils, des portraits de lauréats, des partenaires rattachés au pôle par famille, une page éditoriale « Entrepreneuriat » (slogan, sous-titre, images du slider, présentation riche, chiffres clés, citation, texte d'impact, appels à l'action, e-mail de contact) et l'identifiant du service « Direction du Développement et de l'Entrepreneuriat (DDE) » auquel le pôle est rattaché. Tout cela est lisible publiquement, mais **aucune page publique n'existe encore** : un visiteur ne peut pas découvrir le pôle.

Cette feature ouvre le mini-site « Entreprendre à Senghor » avec ses deux premières rubriques : l'**accueil** (rubrique « Présentation »), qui donne en une page la vision d'ensemble du pôle, et **« Nos activités »**, qui détaille chaque phase du parcours, de la sensibilisation à l'animation de l'écosystème. Elle pose aussi le **cadre commun** des rubriques suivantes (features 024 et 025) : le hero en slider, la sous-navigation collante du pôle, les libellés fixes trilingues, le référencement.

Le mini-site ne duplique rien : les actualités et les événements affichés sont ceux rattachés au service DDE dans les backoffices existants ; les partenaires viennent du backoffice Partenaires via le rattachement du pôle ; la copie de page vient de la page éditoriale « Entrepreneuriat ».

## Clarifications

### Session 2026-09-13

- Q: La copie de page (slogan, sous-titre, présentation, libellés des chiffres clés, citation, texte d'impact, appel à l'action) est stockée en **une seule langue (français)** par le système éditorial du site — c'est la convention de toutes les pages éditoriales existantes, qui affichent la valeur du backoffice quelle que soit la langue du visiteur. Quel comportement retenir pour la copie de page en anglais et en arabe ? → A: Option A — convention du site : la copie de page s'affiche en français dans les trois langues ; seuls les libellés fixes (rubriques, boutons génériques, intitulés de phases et de familles, textes d'accessibilité) sont traduits. Le critère « données du backoffice dans les trois langues » s'applique aux données métier trilingues (dispositifs, partenaires, actualités, événements). Une copie de page trilingue relèverait d'une évolution du système éditorial, hors de cette feature.
- Q: D'où viennent le titre, le sous-titre et l'image du hero de la page « Nos activités », qui n'a aucune clé éditoriale dédiée aujourd'hui ? (FR-010) → A: Option B — clés éditoriales dédiées `entrepreneurship.activities.hero.{badge,title,subtitle,image}` ajoutées à la page éditoriale « Entrepreneuriat » et seedées par une migration rejouable 047 (accord préalable sur le SQL) ; la page a ainsi un titre, un sous-titre et une image propres, modifiables en backoffice.
- Q: Comment ajouter le badge au hero partagé sans changer l'apparence des deux pages existantes (Partenaires, fiche Organisation) qui lui passent déjà un badge jamais affiché ? (FR-017) → A: Option A — ajouter une prop optionnelle « badge » au hero et retirer les deux attributs orphelins (attribut `badge` de la page Partenaires, slot `#badge` de la fiche Organisation) ; le rendu de toutes les pages existantes reste strictement identique.
- Q: Comment obtenir sur l'accueil du pôle des cartes d'actualités identiques à celles de la page Actualités, dont le gabarit est écrit dans la page ? (FR-007) → A: Option A — extraire une carte d'actualité partagée (composant unique) utilisée par la page Actualités et par l'accueil du pôle, avec comparaison de captures avant / après de la page Actualités ; la feature 024 réutilisera la même carte.
- Q: Pour la sous-navigation collante du pôle, généraliser une barre existante ou créer un composant propre au pôle ? (FR-015, FR-016) → A: Option A — composant dédié au pôle, calqué sur les onglets « Nous connaître » (collant sous l'en-tête, actif par adresse, défilement horizontal mobile, icônes, bouton d'action), sans modifier les barres existantes ; réutilisé tel quel par les features 024 et 025.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Découvrir le pôle depuis la page d'accueil (Priority: P1)

Un visiteur (étudiant, alumni, partenaire potentiel, journaliste) ouvre `/entrepreneuriat`. Il voit le hero image du site (hauteur standard) avec le badge « Entreprendre à Senghor », le slogan « INNOVER. AGIR. TRANSFORMER. », le sous-titre, deux boutons (« Devenir étudiant-entrepreneur », « Découvrir le parcours ») et un fond qui alterne entre trois visuels d'étudiants, avec des points de navigation. Sous le hero, une sous-navigation collante liste les rubriques du pôle. Il lit ensuite, dans l'ordre de la maquette : la présentation du pôle avec un panneau de quatre chiffres clés ; le parcours en cinq cartes numérotées (phase, titre, accroche, chiffre mis en avant, couleur propre) suivies des chips « Et toute l'année, l'animation de l'écosystème » et d'un lien « Voir toutes nos activités » ; un encadré sombre avec la citation du directeur de la DDE, son nom, sa fonction, sa photo, le texte d'impact et un visuel ; « La vie du pôle » avec trois actualités rattachées à la DDE et un lien « Toutes les actualités du PEI » ; « Un écosystème d'appui » avec les logos des partenaires en trois familles ; enfin l'appel à l'action « Prêt à passer à l'action ? » avec le bouton « Postuler au statut » et l'e-mail du pôle.

**Why this priority**: C'est la porte d'entrée du mini-site et l'objet même du cahier des charges du pôle : sans elle, aucune des données produites par les features 021 et 022 n'est visible du public.

**Independent Test**: Ouvrir `/entrepreneuriat` sans être connecté, avec les données initiales des features 021 et 022 et au moins trois actualités rattachées à la DDE ; vérifier que chaque section de la maquette est présente, dans l'ordre, avec les valeurs du backoffice ; modifier un chiffre clé et le titre d'un dispositif en backoffice, recharger, et constater la mise à jour.

**Acceptance Scenarios**:

1. **Given** les clés éditoriales « Entrepreneuriat » renseignées et trois images de slider choisies, **When** le visiteur ouvre `/entrepreneuriat`, **Then** le hero affiche le badge, le slogan, le sous-titre et les deux boutons, le premier visuel est visible dès le chargement initial (rendu serveur), et les points de navigation indiquent trois visuels.
2. **Given** cinq dispositifs actifs, **When** la section « Nos activités » s'affiche, **Then** cinq cartes numérotées 1 à 5 apparaissent dans l'ordre d'affichage du backoffice, chacune avec le libellé de sa phase, son titre, son accroche, son chiffre mis en avant (s'il existe) et la couleur nommée de sa charte ; un dispositif désactivé en backoffice disparaît sans laisser de trou dans la numérotation.
3. **Given** des partenaires rattachés au pôle dans deux familles seulement, **When** la section « Nos partenaires » s'affiche, **Then** seules ces deux familles sont visibles, chacune avec ses logos (ou le nom du partenaire si aucun logo) dans l'ordre défini en backoffice, et un logo est cliquable vers le site du partenaire quand il en a un.
4. **Given** cinq actualités publiées rattachées à la DDE, **When** la section « La vie du pôle » s'affiche, **Then** les trois plus récentes apparaissent avec le même aspect que les cartes de la page Actualités du site (visuel, catégorie ou date, titre, résumé) et chaque carte mène à l'article existant.
5. **Given** la clé e-mail du pôle renseignée, **When** le visiteur clique sur l'e-mail de l'appel à l'action, **Then** son client de messagerie s'ouvre avec cette adresse ; **and** le bouton « Postuler au statut » mène à l'adresse de la future page « Statut Étudiant-Entrepreneur » du mini-site.
6. **Given** le fil d'Ariane du hero, **When** le visiteur clique sur « DDE », **Then** il arrive sur la fiche publique du service DDE ; « Accueil », « Nous connaître » et « Organisation » mènent aux pages existantes correspondantes ; le dernier élément « Pôle Entrepreneuriat et Innovation » n'est pas cliquable.
7. **Given** le bouton « Découvrir le parcours » du hero, **When** le visiteur clique, **Then** la page défile jusqu'à la section du parcours de la même page.

---

### User Story 2 - Explorer le parcours en détail sur « Nos activités » (Priority: P2)

Le visiteur ouvre `/entrepreneuriat/activites` (depuis la sous-navigation ou le lien « Voir toutes nos activités »). La page présente le parcours sous forme longue : un bloc par phase, dans l'ordre du parcours (sensibilisation, cadre / statut, pré-incubation, incubation, financement, animation de l'écosystème). Chaque bloc reprend la carte du parcours en version étendue : numéro, libellé de phase, titre, sigle, accroche, chiffre mis en avant, visuel du dispositif et **contenu riche complet** du dispositif. Le bloc « Animation de l'écosystème » liste les événements récurrents (chips de l'accueil) et les **prochains événements** rattachés à la DDE (titre, date, lieu, lien vers la fiche événement existante). Une navigation par ancres en tête de page permet de sauter directement à une phase.

**Why this priority**: C'est la première rubrique de contenu du mini-site et la réponse au besoin « je veux comprendre concrètement ce que le pôle propose à chaque étape ». Elle dépend des mêmes données que l'accueil et peut être livrée juste après.

**Independent Test**: Ouvrir `/entrepreneuriat/activites` ; vérifier un bloc par phase dans l'ordre, le contenu riche de chaque dispositif rendu avec sa mise en forme, les visuels, et la liste des événements à venir rattachés à la DDE ; cliquer une ancre et constater le défilement vers la phase ; modifier le contenu riche d'un dispositif en backoffice et constater la mise à jour.

**Acceptance Scenarios**:

1. **Given** cinq dispositifs actifs couvrant cinq phases, **When** la page s'affiche, **Then** six blocs apparaissent dans l'ordre du parcours (les cinq phases des dispositifs puis l'animation de l'écosystème), chacun atteignable par une ancre ; une phase sans dispositif actif n'a pas de bloc.
2. **Given** un dispositif dont le contenu riche contient des titres, des listes et des liens, **When** son bloc s'affiche, **Then** la mise en forme est restituée fidèlement, dans la langue du visiteur (repli français silencieux si la traduction manque).
3. **Given** trois événements publiés à venir rattachés à la DDE et deux événements passés, **When** le bloc « Animation de l'écosystème » s'affiche, **Then** seuls les trois événements à venir apparaissent, du plus proche au plus lointain, chacun menant à la fiche événement existante ; **and** s'il n'y a aucun événement à venir, la liste est masquée sans message d'erreur.
4. **Given** le visiteur arrive sur la page via une adresse contenant une ancre de phase, **When** la page se charge, **Then** la page est positionnée sur le bloc de cette phase, en tenant compte de la hauteur de l'en-tête et de la sous-navigation collante.

---

### User Story 3 - Naviguer entre les rubriques du pôle et parcourir le slider (Priority: P2)

Le visiteur utilise la sous-navigation collante commune aux rubriques du pôle : « Présentation », « Nos activités », « Nos alumni », « Nos partenaires », « Nos ressources », « Actualités », plus le bouton « Devenir étudiant-entrepreneur » mis en évidence. La rubrique courante est marquée. La barre reste visible sous l'en-tête du site pendant le défilement et, sur mobile, défile horizontalement. Dans le hero, le visiteur peut changer de visuel au clavier ou à la souris via les points de navigation ; le défilement automatique se met en pause quand il survole ou prend le focus, et ne démarre pas s'il a demandé à réduire les animations.

**Why this priority**: La sous-navigation et le slider sont le socle partagé par toutes les rubriques suivantes (024, 025) ; leur accessibilité est un critère d'acceptation explicite.

**Independent Test**: Sur `/entrepreneuriat` et `/entrepreneuriat/activites`, vérifier la rubrique active et la position collante de la barre ; à 390 px, vérifier le défilement horizontal ; au clavier seul, atteindre les points du slider, changer de visuel avec les touches habituelles, constater la pause au focus ; activer la préférence « réduire les animations » du système et constater l'absence de défilement automatique.

**Acceptance Scenarios**:

1. **Given** le visiteur est sur `/entrepreneuriat/activites`, **When** la sous-navigation s'affiche, **Then** « Nos activités » est marquée active et les autres entrées mènent à leurs adresses respectives (`/entrepreneuriat`, `/entrepreneuriat/alumni`, `/entrepreneuriat/partenaires`, `/entrepreneuriat/ressources`, `/entrepreneuriat/actualites`), le bouton menant à `/entrepreneuriat/statut-etudiant-entrepreneur`.
2. **Given** le visiteur défile de 1 500 px vers le bas, **When** il regarde le haut de l'écran, **Then** la sous-navigation est toujours visible, juste sous l'en-tête du site, sans le recouvrir ni être recouverte.
3. **Given** le visiteur navigue au clavier, **When** il tabule jusqu'aux points du slider, **Then** chaque point est focusable, annoncé (« Visuel 2 sur 3 »), activable avec Entrée ou Espace, et les flèches gauche / droite changent de visuel ; le défilement automatique est en pause tant qu'un point a le focus ou que le hero est survolé.
4. **Given** la préférence système « réduire les animations » active, **When** le hero s'affiche, **Then** aucun défilement automatique ne démarre et le changement de visuel reste possible manuellement, sans animation de transition.
5. **Given** une seule image de slider renseignée (ou aucune), **When** le hero s'affiche, **Then** il se comporte comme le hero image classique du site (pas de points, pas de défilement) ou, sans image, comme le hero à motif du site, sans erreur.

---

### User Story 4 - Lire le mini-site en anglais et en arabe, sur mobile et en mode sombre (Priority: P3)

Le visiteur change de langue : en anglais (`/en/entrepreneuriat`) et en arabe (`/ar/entrepreneuriat`, sens de lecture droite-à-gauche), les libellés fixes (rubriques, boutons, intitulés de sections d'aide, textes d'accessibilité) sont traduits, les données trilingues (dispositifs, partenaires, actualités, événements) s'affichent dans sa langue avec repli français silencieux, la copie de page éditoriale reste en français (convention du site), et la mise en page est miroir en arabe (sous-navigation, cartes, fil d'Ariane, points du slider). Sur un téléphone (390 px) et en mode sombre, les deux pages restent lisibles et complètes.

**Why this priority**: Exigence transversale du site (trilingue, RTL, responsive, sombre) ; indispensable avant mise en ligne mais vérifiable après la construction des pages.

**Independent Test**: Ouvrir les deux pages dans les trois langues, à 1440 px et 390 px, en clair et en sombre ; vérifier les libellés, le sens de lecture arabe, l'absence de débordement horizontal, le passage des cartes du parcours en colonne, et le partage de lien (aperçu avec titre, description et image).

**Acceptance Scenarios**:

1. **Given** la langue arabe, **When** le visiteur ouvre `/ar/entrepreneuriat`, **Then** le document est en sens droite-à-gauche, la sous-navigation et les cartes sont en miroir, les chiffres clés restent lisibles et aucun libellé fixe n'apparaît en français ou sous forme de clé technique (la copie de page éditoriale, elle, reste en français par convention du site).
2. **Given** un dispositif sans titre anglais, **When** le visiteur ouvre `/en/entrepreneuriat`, **Then** le titre français s'affiche à sa place, sans mention d'erreur ni de langue manquante.
3. **Given** une largeur de 390 px, **When** le visiteur ouvre l'accueil, **Then** les cinq cartes du parcours sont empilées en une colonne, la sous-navigation défile horizontalement, le slider occupe toute la largeur, et aucun défilement horizontal de page n'apparaît.
4. **Given** le mode sombre du site, **When** le visiteur ouvre les deux pages, **Then** tous les blocs (cartes, encadré citation, panneau de chiffres, chips, logos) ont un contraste suffisant et aucune zone blanche non prévue n'apparaît.
5. **Given** un partage du lien `/entrepreneuriat` sur un réseau social, **When** l'aperçu se génère, **Then** il montre le titre du pôle, une description et une image représentative ; chaque page déclare son titre, sa description, sa langue et ses équivalents dans les autres langues.

---

### Edge Cases

- **Service DDE non identifié** (clé `entrepreneurship.dde_service_id` vide ou service introuvable) : les sections « La vie du pôle » et « prochains événements » sont masquées, le fil d'Ariane affiche « DDE » sans lien, aucun message d'erreur n'est visible du public.
- **Section sans données** (aucune actualité DDE, aucun partenaire rattaché, aucun événement à venir, aucun dispositif actif, citation vide) : la section entière est masquée, y compris son titre et son lien « voir tout » ; les sections voisines se rejoignent sans espace vide anormal.
- **Clé éditoriale vide ou non chargée** : aucun texte ne s'affiche sous forme de clé technique ; le bloc concerné est masqué ou omis (un chiffre clé sans valeur ne compte pas parmi les quatre affichés ; un panneau sans aucun chiffre est masqué).
- **Lecture publique indisponible** (erreur ou délai dépassé sur l'une des sources) : la page se rend quand même avec les sections dont les données sont disponibles ; les autres sont masquées comme « sans données ».
- **Images du slider** : 0 image → hero à motif ; 1 image → hero image sans slider ; 2 ou 3 images → slider ; un média supprimé de la médiathèque est ignoré (le slider passe à 2 puis 1 visuel sans erreur).
- **Chiffre clé non numérique** (ex. « 500+ », « ∞ ») : affiché tel quel ; l'éventuelle animation de compteur ne s'applique qu'aux valeurs numériques et ne déforme jamais la valeur saisie.
- **Actualités DDE en nombre insuffisant** : 1 ou 2 actualités s'affichent sans emplacement vide ; 0 masque la section.
- **Phase sans dispositif / dispositif sans phase connue** : la page « Nos activités » n'affiche que les phases ayant au moins un dispositif actif ; plusieurs dispositifs d'une même phase sont listés dans le même bloc, dans l'ordre du backoffice.
- **Rubriques non encore livrées** (alumni, partenaires, ressources, actualités, statut) : la sous-navigation pointe déjà vers leurs adresses futures ; tant qu'elles n'existent pas, le site répond par sa page « introuvable » habituelle (comportement accepté et documenté jusqu'aux features 024 et 025).
- **Hero existant** : l'extension du hero ne doit rien changer aux 17 pages qui l'utilisent aujourd'hui (titre, sous-titre, image unique, fil d'Ariane, séparateur oblique) ; les deux pages qui passent un « badge » non rendu sont nettoyées de cet attribut pour que leur rendu reste **identique** après l'ajout de la prop badge.
- **Repli i18n du système éditorial** : si les clés éditoriales ne sont pas chargées en base (environnement neuf), la page ne doit ni planter ni afficher de clés brutes.

## Requirements *(mandatory)*

### Functional Requirements

**Page d'accueil `/entrepreneuriat`**

- **FR-001**: La page MUST afficher, dans l'ordre de la maquette `accueil.png` : hero, sous-navigation, présentation + chiffres clés, parcours + chips + lien, encadré citation + impact, actualités du pôle, partenaires par famille, appel à l'action final ; l'en-tête et le pied de page sont ceux du site.
- **FR-002**: Le hero MUST afficher le badge, le slogan, le sous-titre, deux boutons (le premier vers `/entrepreneuriat/statut-etudiant-entrepreneur`, le second vers l'ancre du parcours de la page) et le fil d'Ariane « Accueil › Nous connaître › Organisation › DDE › Pôle Entrepreneuriat et Innovation », chaque niveau sauf le dernier étant cliquable vers la page existante correspondante ; tous ces textes proviennent des clés éditoriales « Entrepreneuriat » ou des libellés fixes traduits.
- **FR-003**: Le hero MUST proposer un slider des images choisies en backoffice (jusqu'à trois) : points de navigation, défilement automatique toutes les 6 secondes environ, pause au survol et au focus, arrêt du défilement automatique si le visiteur préfère les animations réduites, commande au clavier (points focusables, Entrée / Espace, flèches gauche / droite), annonce accessible du visuel courant ; le premier visuel MUST être présent dans le rendu serveur.
- **FR-004**: La section présentation MUST afficher sur deux colonnes le badge, le titre, le contenu riche de présentation, le lien « Historique, vision et missions du pôle » (vers la fiche publique du service DDE) et un panneau « Chiffres clés » de quatre valeurs avec libellés, dans le style des chiffres clés du site (panneau sombre de la maquette).
- **FR-005**: La section parcours MUST afficher le badge, le titre, le sous-titre, puis une carte par dispositif actif dans l'ordre du backoffice, numérotée à partir de 1 : libellé de phase (traduit), titre, accroche, chiffre mis en avant, couleur nommée du dispositif (rendu clair / sombre défini par le site) ; puis le titre et les chips de l'animation de l'écosystème (liste éditoriale) ; puis un lien vers `/entrepreneuriat/activites`. Chaque carte MUST mener à l'ancre de sa phase sur « Nos activités ».
- **FR-006**: L'encadré citation MUST afficher la citation, l'auteur, sa fonction, sa photo (ou un substitut si absente), le texte d'impact et le visuel d'impact, sur fond sombre comme dans la maquette.
- **FR-007**: La section actualités MUST afficher les trois actualités publiées les plus récentes rattachées au service DDE, avec une carte d'actualité partagée extraite de la page Actualités et utilisée par les deux pages (même aspect, même contenu : visuel, catégorie ou date, titre, résumé), chacune menant à l'article existant, et un lien « Toutes les actualités du PEI » vers `/entrepreneuriat/actualites`. L'extraction MUST ne changer ni l'apparence ni le comportement de la page Actualités (clarification Q4).
- **FR-008**: La section partenaires MUST afficher les familles non vides dans l'ordre fixe (académiques et institutionnels, organisations d'appui, organisations internationales), avec l'intitulé traduit de chaque famille et les logos des partenaires actifs dans l'ordre du backoffice ; un partenaire sans logo MUST être représenté par son nom ; un partenaire avec site web MUST être cliquable vers ce site (nouvel onglet).
- **FR-009**: L'appel à l'action final MUST afficher le titre, la description, le bouton (vers `/entrepreneuriat/statut-etudiant-entrepreneur`) et l'e-mail du pôle en lien de messagerie.

**Page « Nos activités » `/entrepreneuriat/activites`**

- **FR-010**: La page MUST afficher le hero du site (sans slider) alimenté par des clés éditoriales dédiées à la page — badge, titre, sous-titre, image (mode image si renseignée, motif sinon) —, le fil d'Ariane prolongé de « Nos activités », la sous-navigation avec « Nos activités » active, une navigation par ancres vers les phases, puis un bloc par phase dans l'ordre du parcours : sensibilisation, cadre / statut, pré-incubation, incubation, financement, animation de l'écosystème.
- **FR-011**: Chaque bloc de phase MUST reprendre, pour chaque dispositif actif de la phase, la carte du parcours en version longue : numéro, libellé de phase, titre, sigle, accroche, chiffre mis en avant, visuel du dispositif (s'il existe) et contenu riche complet rendu avec sa mise en forme, dans la langue du visiteur avec repli français.
- **FR-012**: Le bloc « Animation de l'écosystème » MUST afficher les chips des événements récurrents (liste éditoriale) et la liste des événements publiés **à venir** rattachés au service DDE, du plus proche au plus lointain (titre, date, lieu, lien vers la fiche événement existante) ; sans événement à venir, la liste est masquée.
- **FR-013**: La lecture publique des événements MUST permettre de ne retenir que les événements rattachés à un service donné, sans modification de la structure des données (le rattachement existe déjà sur chaque événement).
- **FR-014**: Les ancres MUST être stables (identifiant par phase) et accessibles directement par l'adresse ; la position tient compte de l'en-tête et de la sous-navigation collante.

**Sous-navigation du pôle**

- **FR-015**: Une sous-navigation collante commune aux rubriques du pôle MUST afficher, avec une icône chacune : Présentation (`/entrepreneuriat`), Nos activités, Nos alumni, Nos partenaires, Nos ressources, Actualités, et un bouton mis en évidence « Devenir étudiant-entrepreneur » (`/entrepreneuriat/statut-etudiant-entrepreneur`) ; la rubrique courante est déterminée par l'adresse de la page ; la barre reste visible juste sous l'en-tête du site au défilement et défile horizontalement sur mobile.
- **FR-016**: La sous-navigation MUST être un composant dédié au pôle, calqué sur les onglets « Nous connaître » (même position collante, même style d'onglet actif, même défilement horizontal mobile), sans modification des deux barres collantes existantes du site (vérification faite : leurs contrats sont trop spécifiques pour être généralisés sans risque — clarification Q5).

**Réutilisation et contenu**

- **FR-017**: Le hero du site MUST être étendu de props optionnelles (liste d'images pour le slider, badge avec icône facultative, boutons d'action) et non remplacé ; l'extension MUST ne changer ni l'apparence ni le comportement des pages qui l'utilisent déjà (inventaire : 17 fichiers, 19 usages). Les deux pages qui passent aujourd'hui un badge jamais rendu (Partenaires, fiche Organisation) MUST être nettoyées de ces attributs orphelins dans la même livraison, afin que leur rendu reste strictement identique (clarification Q3).
- **FR-018**: Aucun texte visible ne MUST être codé en dur dans les pages : la copie de page vient des clés éditoriales « Entrepreneuriat », les libellés fixes (rubriques, boutons génériques, intitulés de phases et de familles, textes d'accessibilité) des fichiers de traduction FR / EN / AR, les données métier des lectures publiques du pôle, des actualités et des événements.
- **FR-019**: Les champs trilingues des données métier MUST être lus avec le repli français silencieux existant ; la copie de page éditoriale (monolingue) s'affiche telle quelle dans les trois langues, conformément à la convention du site (clarification Q1).
- **FR-020**: Le contenu riche (présentation, contenu des dispositifs) MUST être rendu par le composant d'affichage de texte riche du site.
- **FR-021**: Un nouveau composable public du pôle MUST regrouper les lectures publiques des dispositifs et des partenaires (sans authentification), et être utilisé par les deux pages ; il peut exposer les autres lectures publiques du pôle (cohortes, portraits, ressources) sans les utiliser ici, pour les rubriques suivantes ; aucune page publique ne MUST appeler une lecture réservée à l'administration.
- **FR-022**: Les composants publics du pôle MUST vivre dans un dossier dédié distinct de l'administration ; avant chaque nouveau composant, l'existence d'un composant similaire dans le site MUST être vérifiée.
- **FR-023**: Toute section dont la source ne renvoie aucune donnée, ou est en erreur, MUST être masquée entièrement (titre compris), sans message d'erreur visible, et sans empêcher le rendu des autres sections.

**Internationalisation, référencement, responsive**

- **FR-024**: Les libellés fixes MUST exister en français, anglais et arabe ; en arabe, les deux pages MUST se rendre en sens droite-à-gauche (mise en page miroir, sous-navigation et slider compris).
- **FR-025**: Chaque page MUST déclarer son titre, sa description, ses balises de partage (titre, description, image, adresse, langue et langues alternatives), après la résolution de sa route (contrainte connue du site), et être présente dans le plan du site dans les trois langues.
- **FR-026**: Chaque page MUST exposer des données structurées : organisation (le pôle, rattaché à l'Université), page web, et fil d'Ariane, cohérentes avec le fil d'Ariane affiché.
- **FR-027**: Les deux pages MUST être rendues côté serveur avec leurs données (contenu visible sans exécution de script), fonctionner à 390 px de large (cartes du parcours en colonne, sous-navigation défilante, slider pleine largeur, aucun défilement horizontal de page) et en mode sombre.
- **FR-028**: Le rattachement au service DDE (fil d'Ariane, actualités, événements) MUST utiliser la clé éditoriale `entrepreneurship.dde_service_id` ; une clé vide ou un service introuvable masque les sections dépendantes et rend « DDE » non cliquable.

**Documentation**

- **FR-029**: Aucune modification de structure de données n'est attendue. Les quatre clés éditoriales du hero de « Nos activités » (badge, titre, sous-titre, image — section « Nos activités » de la page éditoriale « Entrepreneuriat ») MUST être ajoutées par une migration rejouable numérotée 047, sans écraser une valeur déjà modifiée au rejeu, avec son script de retour arrière, le SQL étant soumis à accord préalable ; les valeurs initiales françaises (badge « Nos activités », titre « Un parcours, de l'idée à l'entreprise », sous-titre du cahier des charges, image vide) sont proposées dans la migration. Les 43 autres clés existent déjà (feature 021).
- **FR-030**: La documentation projet (CLAUDE.md) MUST être mise à jour : routes publiques `/entrepreneuriat` et `/entrepreneuriat/activites`, nouveau composable public, extension du hero, sous-navigation du pôle.

### Key Entities *(include if data involved)*

Aucune entité nouvelle. Entités lues (toutes existantes) :

- **Dispositif du parcours** (feature 021) : code, sigle, titre, phase, accroche, contenu riche, chiffre mis en avant, couleur nommée, visuel, ordre, actif — trilingue.
- **Partenaire du pôle** (feature 022) : famille, ordre, enrichi du nom, logo, description, site web du partenaire — seuls les partenaires actifs sont renvoyés.
- **Contenu éditorial « Entrepreneuriat »** (feature 021) : 43 clés (hero, présentation, chiffres, activités, citation / impact, appel à l'action, statut, paramètres) — une valeur par clé, en français — complétées ici de 4 clés pour le hero de « Nos activités » (badge, titre, sous-titre, image).
- **Actualité** et **Événement** (existants) : publiés, rattachés au service DDE ; l'événement porte directement son service de rattachement.
- **Service DDE** (existant) : identifié par la clé éditoriale ; son nom sert à construire l'adresse de sa fiche publique.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Un visiteur ouvrant `/entrepreneuriat` voit les huit sections de la maquette, dans l'ordre, avec 100 % des valeurs saisies en backoffice (copie, chiffres, dispositifs, partenaires, actualités) ; une modification en backoffice est visible au rechargement suivant (délai de cache d'une minute au plus).
- **SC-002**: Le contenu principal des deux pages (hero, présentation, parcours, contenu riche des dispositifs) est présent dans la réponse initiale du serveur, sans exécution de script, dans les trois langues.
- **SC-003**: Score Lighthouse mobile ≥ 90 en performance et ≥ 90 en accessibilité sur `/entrepreneuriat` et `/entrepreneuriat/activites`, avec les données initiales et trois images de slider.
- **SC-004**: 100 % des commandes du slider sont réalisables au clavier seul ; avec la préférence « réduire les animations », aucun changement automatique de visuel n'a lieu en 60 secondes d'observation.
- **SC-005**: Aucune différence visuelle (comparaison de captures avant / après) sur les 17 pages utilisant déjà le hero du site ni sur la page Actualités (carte extraite), aux largeurs 1440 px et 390 px.
- **SC-006**: Dans les trois langues, 0 clé technique et 0 libellé fixe non traduit visible sur les deux pages (la copie de page éditoriale reste en français par convention) ; en arabe, le sens de lecture est droite-à-gauche sur 100 % des blocs.
- **SC-007**: Chacune des situations « sans données » (0 actualité, 0 partenaire, 0 événement, 0 dispositif, service DDE non identifié, source en erreur) produit une page sans erreur visible ni bloc vide.
- **SC-008**: À 390 px, aucun défilement horizontal de page ; la sous-navigation reste visible pendant tout le défilement et la rubrique active est correcte sur 100 % des rubriques testées.
- **SC-009**: Les deux pages figurent dans le plan du site en trois langues, l'aperçu de partage affiche titre, description et image, et les données structurées (organisation, page, fil d'Ariane) sont valides dans un validateur de données structurées.
- **SC-010**: Un visiteur atteint le contenu détaillé d'un dispositif depuis l'accueil en un clic (carte → ancre de phase sur « Nos activités »).
- **SC-011**: La migration 047 s'exécute deux fois de suite sans erreur en local et en production ; le nombre de clés éditoriales « Entrepreneuriat » est identique après le second passage (47) et une valeur modifiée en backoffice entre les deux passages est conservée.

## Assumptions

- **Copie de page et langues** : décision Q1 — convention du site : la copie de page éditoriale s'affiche en français dans les trois langues, les libellés fixes sont traduits. Aucune traduction statique EN / AR de la copie de page n'est livrée et aucune extension du système éditorial n'est faite.
- **Extension du hero** : une prop optionnelle « images » (liste d'adresses) déclenche le slider à partir de deux images ; une prop optionnelle « badge » est ajoutée pour le badge de la maquette. Les deux pages qui passent déjà un badge non rendu (Partenaires, fiche Organisation) sont nettoyées de ces attributs orphelins (clarification Q3) ; la comparaison de captures avant / après (SC-005) couvre ces deux pages en priorité. Le carrousel maison du hero de la page d'accueil du site sert de modèle (résolution des images éditoriales, filtrage des images absentes).
- **Sous-navigation** : après inventaire, les deux barres existantes ont des contrats trop spécifiques (onglets codés en dur pour l'une, détection par défilement pour l'autre) ; décision Q5 : composant dédié au pôle calqué sur les onglets « Nous connaître » (collant sous l'en-tête, actif par adresse, défilement horizontal mobile, icônes, bouton d'action), sans toucher aux barres existantes.
- **Chiffres clés** : le composant de chiffres du site attend exactement des valeurs textuelles avec suffixe ; la maquette montre un panneau sombre encastré et non une bande pleine largeur. On reprend le style (typographie, animation de compteur pour les valeurs numériques) dans un panneau ; les valeurs non numériques sont affichées telles quelles.
- **Cartes d'actualités** : aucune carte réutilisable n'existe (les cartes de la page Actualités sont écrites dans la page) ; une carte partagée est extraite et utilisée par la page Actualités et par l'accueil du pôle (clarification Q4) ; la page Actualités est comparée avant / après (captures 1440 px et 390 px).
- **Événements de la DDE** : la lecture publique des événements n'offre pas encore de filtre par service ; il sera ajouté côté lecture publique (paramètre de filtre sur le rattachement existant), sans changement de structure. Seuls les événements à venir sont affichés sur « Nos activités » ; les événements passés relèvent de la rubrique Actualités (feature 024).
- **Fiche du service DDE** : l'adresse de la fiche publique d'un service se construit à partir de son nom ; le nom est obtenu en lisant le service par son identifiant via la lecture publique de l'organisation. En cas d'échec, « DDE » reste affiché sans lien.
- **Lien « Historique, vision et missions du pôle »** : mène à la fiche publique du service DDE (onglet présentation) ; masqué si le service n'est pas identifié.
- **Second bouton du hero** : « Découvrir le parcours » défile vers la section parcours de l'accueil (ancre), pas vers « Nos activités ».
- **Phase « Animation de l'écosystème »** : aucun dispositif ne porte cette phase dans les données initiales ; son bloc sur « Nos activités » est constitué des chips éditoriales et des événements à venir, et s'affiche dès qu'au moins l'un des deux existe.
- **Plan du site** : les pages statiques sont découvertes automatiquement à partir des fichiers de pages, avec les préfixes de langue ; aucune liste manuelle à modifier, seulement une vérification.
- **Données structurées** : le site déclare déjà une organisation (l'Université) globalement ; le pôle est déclaré comme organisation rattachée à l'Université sur ses pages, avec la page web et le fil d'Ariane ; le fil d'Ariane structuré est une première sur le site.
- **Images du slider et du hero « Nos activités »** : les clés `entrepreneurship.hero.slide{1,2,3}.image` et `entrepreneurship.activities.hero.image` sont vides dans les données initiales ; les visuels seront choisis par l'équipe du pôle en backoffice. Tant qu'aucune image n'est renseignée, l'accueil utilise une image par défaut du site (hero image classique, sans slider) et « Nos activités » le hero à motif.
- **Cache** : les lectures publiques du pôle sont mises en cache une minute (convention des features 021 / 022) ; le délai de visibilité d'une modification est accepté.
- **Rubriques futures** : les adresses `/entrepreneuriat/{alumni,partenaires,ressources,actualites,statut-etudiant-entrepreneur}` sont référencées mais non livrées ; leur réponse « introuvable » temporaire est acceptée.
- **Migration 047** : les 43 clés éditoriales de la feature 021 existent déjà (inventaire vérifié entre la configuration éditoriale et la migration 045) ; la seule migration de cette feature ajoute les 4 clés du hero de « Nos activités » (clarification Q2), rejouable, avec retour arrière, sans changement de structure.
- **Menu principal et organigramme** : hors périmètre (feature 026) ; le mini-site n'est atteignable que par son adresse directe ou les liens internes.

## Dependencies

- Feature 021 : dispositifs (lecture publique), clés éditoriales « Entrepreneuriat », clé `entrepreneurship.dde_service_id`, page éditoriale en backoffice.
- Feature 022 : lecture publique des partenaires du pôle par famille (nom, logo, description, site web).
- Backoffices existants : actualités et événements rattachés au service DDE ; médiathèque (images du slider, visuels des dispositifs, photo et visuel de l'encadré citation).
- Composants et outils existants du site : hero de page, en-tête et pied de page du layout, rendu de texte riche, style des chiffres clés, cartes d'actualités de la page Actualités, système de traduction et de repli français, référencement (balises de partage, plan du site).
- Maquette `specs/maquettes-pei/accueil.{png,html}` et cahier des charges du pôle pour les textes (déjà seedés en 021).
- Feuille de route PEI : les features 024 et 025 réutilisent la sous-navigation, le hero étendu et le composable public livrés ici.
