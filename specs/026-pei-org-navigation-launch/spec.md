# Feature Specification: Rattachement du PEI à l'organigramme, navigation et mise en ligne du mini-site

**Feature Branch**: `026-pei-org-navigation-launch`

**Created**: 2026-09-15

**Status**: Draft

**Input**: User description: "Rattacher le Pôle Entrepreneuriat et Innovation (PEI) à l'organigramme comme « pôle » du service DDE, l'intégrer à la navigation du site, puis préparer la mise en ligne de l'ensemble du mini-site (features 021 à 025). [...] Décision D1 prise : niveau « pôle » via `services.parent_id` + `services.landing_path` (pas d'encart). [...] Périmètre : 1. niveau « pôle » (colonnes, contraintes, migration 050 + rollback, création du service PEI rattaché à la DDE) ; 2. admin (sélecteur « Service parent », champ « Page dédiée », liste hiérarchique, audit) ; 3. public (bloc « Pôles » sur la fiche service, pôles sous leur parent dans l'organigramme) ; 4. menu « Plus » (clé `navbar.secondary.{section}.children`, seed non destructif) et pied de page ; 5. fil d'Ariane factorisé ; 6. lien court `/r/pei` ; 7. sitemap ; 8. mise en ligne soumise à accord. Hors périmètre : contenu éditorial réel, hiérarchie de plus d'un niveau. Critères d'acceptation : [...] rollback 050 avant les rollbacks 049 → 045 ; aucune régression sur les fiches secteur et service existantes."

**Références** : `specs/roadmap-pei-entrepreneuriat.md` (prompt 026, décision D1), `specs/021-pei-entrepreneurship-core/` (clé `entrepreneurship.dde_service_id`, T071), `specs/022-pei-laureates-partners/`, `specs/023-pei-public-home-activities/` (fil d'Ariane, T039, T048, T051), `specs/024-pei-public-alumni-resources-news/` (`usePeiPage`), `specs/025-pei-see-status-page/`, `specs/014-link-shortener/`, `specs/maquettes-pei/arborescence.png` (colonne « Organigramme (existant) »), `specs/maquettes-pei/accueil.png` (fil d'Ariane du hero).

## Contexte

Le mini-site « Entreprendre à Senghor » (sept pages sous `/entrepreneuriat`) est en ligne, mais on n'y accède que par une adresse directe. Il n'apparaît ni dans l'organigramme, ni dans le menu, ni dans le pied de page. Cette feature donne au pôle sa place dans la structure de l'Université : c'est un **pôle** de la Direction du développement et de l'entrepreneuriat (DDE), ni un secteur ni un service de premier niveau. Elle ouvre ensuite les portes d'entrée publiques vers le mini-site (organigramme, fiche DDE, menu « Plus », pied de page, lien court, plan du site) et clôt la mise en ligne de l'ensemble.

Constats de l'existant qui encadrent la feature (vérifiés dans le code et dans les suivis des features précédentes) :

- **Organisation** : un service appartient à un secteur (facultatif) ; il n'existe aucune notion de parent ni de page dédiée. L'organigramme public et la liste des secteurs avec services affichent les services à plat, sans adresse de fiche ni date de mise à jour. L'adresse d'une fiche service est calculée à partir de son nom (`/a-propos/organisation/service/{nom-normalisé}`) et retrouvée en parcourant la liste de tous les services.
- **Audit** : les créations, modifications et suppressions de services sont déjà tracées par le journal d'audit général des écritures du backoffice (ancienne ligne et valeurs envoyées). *(Corrigé au plan : la première version de la spec les disait non tracées.)*
- **Perte de données (constaté au plan)** : la lecture publique des secteurs avec leurs services, et celle d'un secteur par son code, **suppriment définitivement les services inactifs** de la base à chaque appel (reproduit en local le 2026-09-15 ; aucune perte constatée en production, où aucun service n'est inactif). Tout service ou pôle désactivé disparaîtrait à la visite suivante de l'organigramme.
- **Formulaire du backoffice** : la création et la modification d'un service se font dans une fenêtre de la liste des services ; la page de détail d'un service est en lecture seule (équipe mise à part).
- **Menu « Plus »** : ses sous-menus (`about`, `projects`, `alumni`, `site`) sont lus depuis des listes éditoriales. Chaque entrée porte **un seul libellé, en français** : une entrée saisie s'affiche en français dans les trois langues. Seules les entrées sans libellé reprennent une traduction du site. La migration de référence (012) **écrase** les listes au rejeu.
- **Pied de page** : le groupe « L'Université » a cinq liens codés dans le composant, avec des libellés traduits.
- **Fil d'Ariane du mini-site** : il est construit dans le cadre commun des rubriques. Il est **dupliqué** dans l'accueil du pôle et dans « Nos activités », qui n'utilisent pas ce cadre. Le niveau DDE vient de la clé `entrepreneurship.dde_service_id`. L'accueil ne rend pas cliquable le niveau « pôle ».
- **Liens courts** : le code fait au plus 4 caractères, en minuscules et chiffres. Les codes générés automatiquement viennent d'un compteur en base 36 **sans remplissage**. Le code manuel `pei` correspond donc à la valeur 32 922 du compteur : le jour où le compteur l'atteindrait, la création d'un lien échouerait sur le doublon.
- **Plan du site** : les adresses d'organisation émises sont fausses. Les secteurs sortent en `secteurs/{CODE}` au lieu de `secteur/{code}`. Les services dépendent d'un champ `slug` que l'API ne renvoie pas, si bien qu'**aucune fiche service n'est émise** (et le préfixe serait faux). Les pages statiques `/entrepreneuriat/*` sont découvertes automatiquement ; leur présence dans les trois langues a été contrôlée pour la page SEE (025).
- **Production** : les suivis indiquent les migrations 045 (2026-09-13, clé DDE renseignée, service « Direction du développement et de l’entrepreneuriat » avec apostrophe typographique), 046, 048 et 049 jouées (2026-09-14 : 138 clés `entrepreneurship.*`), et les features 022, 024 et 025 déployées et vérifiées. La 047 n'a pas de trace propre, mais elle est antérieure aux migrations 048 et 049 jouées. Les tâches T071 (021) et T051 (023) sont restées non cochées alors que leur contenu semble réalisé : la mise en ligne consiste d'abord à **contrôler** cet état, puis à jouer la seule migration nouvelle (050).

## Clarifications

### Session 2026-09-15 (décisions prises dans la description de la feature)

- Décision D1 : niveau « pôle » par un service parent et une page dédiée, pas d'encart dans le contenu riche de la DDE.
- Un seul niveau de profondeur. Un pôle appartient au même secteur que son parent.
- Le SQL (structure + migration 050) est soumis à accord **avant** tout code.
- Chaque action de mise en ligne (push, sauvegarde, migration en production, déploiement) est soumise à un accord explicite distinct.

### Session 2026-09-15 (réponses du demandeur)

- Q1 : Dans quelle section du menu « Plus » placer « Entreprendre à Senghor » ? → **« Nous connaître » (`about`)**, cohérent avec le fil d'Ariane Nous connaître › Organisation › DDE › PEI.
- Q2 : Comment traduire le libellé de l'entrée de menu ? → **Libellés anglais et arabe facultatifs ajoutés aux entrées du menu éditorial**. Ils sont lus selon la langue du visiteur, avec repli sur le libellé français (puis sur la traduction du site pour une entrée sans libellé). Le rendu des entrées existantes est inchangé. L'éditeur du menu permet de saisir ces libellés pour toutes les entrées, et la migration remplit les trois libellés de l'entrée du pôle.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Découvrir le pôle depuis l'organigramme et la fiche DDE (Priority: P1)

Un partenaire consulte « Notre organisation ». Dans le secteur du Rectorat, sous la carte « DDE », il voit une carte légèrement décalée « PEI — Pôle Entrepreneuriat et Innovation ». Il clique dessus et arrive sur l'accueil du mini-site `/entrepreneuriat`, dans sa langue. Plus tard, depuis la fiche de la DDE, onglet Présentation, il retrouve le bloc « Pôles » avec la même carte.

**Why this priority**: C'est la décision D1 et le premier critère d'acceptation. Cette porte d'entrée institutionnelle est aujourd'hui absente, et la structure de données sert de base au reste (fil d'Ariane, plan du site).

**Independent Test**: Jouer la migration 050 en local. Ouvrir `/a-propos/organisation`, la fiche de la DDE et la fiche d'un service sans pôle, sans être connecté, dans les trois langues. Suivre la carte du pôle. Comparer les fiches secteur et service existantes avec des captures d'avant la feature.

**Acceptance Scenarios**:

1. **Given** la migration 050 jouée, **When** le visiteur ouvre l'organigramme, **Then** la carte du pôle apparaît immédiatement sous la carte de la DDE, avec une indentation légère et un repère visuel de rattachement. Elle n'apparaît nulle part ailleurs, et en particulier pas parmi les services de premier niveau du secteur. Le nombre de services affiché pour le secteur est inchangé.
2. **Given** la carte du pôle (page dédiée `/entrepreneuriat`), **When** le visiteur la suit en anglais, **Then** il arrive sur `/en/entrepreneuriat`.
3. **Given** la fiche de la DDE, **When** le visiteur ouvre l'onglet Présentation, **Then** un bloc « Pôles » liste les pôles actifs de la DDE en cartes au style de l'organigramme (sigle ou icône, nom, couleur), dans l'ordre d'affichage. Chaque carte mène à la page dédiée du pôle si elle existe, sinon à sa fiche.
4. **Given** un service sans pôle (tout service existant autre que la DDE), **When** on compare sa fiche et sa carte dans l'organigramme avant / après, **Then** aucune différence visuelle ni fonctionnelle.
5. **Given** un pôle sans page dédiée, **When** le visiteur ouvre sa fiche, **Then** elle s'affiche comme toute fiche service et propose un lien de retour vers la fiche de son service parent.
6. **Given** l'adresse de fiche du pôle PEI (dérivée de son nom), **When** elle est ouverte directement, **Then** la fiche s'affiche (la recherche d'une fiche par son adresse inclut les pôles), avec le lien vers son service parent.

---

### User Story 2 - Structurer un pôle dans le backoffice sans pouvoir casser la hiérarchie (Priority: P1)

Une administratrice ouvre Organisation → Services. La liste montre la DDE, puis le PEI en retrait juste en dessous. Elle édite un autre service et choisit la DDE comme « Service parent » : le sélecteur ne propose que des services de premier niveau du même secteur, jamais le service lui-même. Elle renseigne une « Page dédiée ». Elle essaie ensuite de donner un parent à la DDE, qui a déjà un pôle : l'enregistrement est refusé avec un message clair. Toutes ses modifications apparaissent dans le journal d'audit. Elle désactive un pôle : il disparaît de l'organigramme public mais reste présent dans le backoffice.

**Why this priority**: Les critères d'acceptation exigent que le formulaire empêche un cycle ou un second niveau. La règle doit tenir même en cas d'appel direct au serveur.

**Independent Test**: Dans le backoffice local, rattacher un service, puis tenter successivement : auto-rattachement, rattachement à un pôle, rattachement d'un service qui a des pôles, parent d'un autre secteur, changement de secteur d'un parent, page dédiée invalide. Refaire les mêmes tentatives par appel direct au serveur. Consulter le journal d'audit.

**Acceptance Scenarios**:

1. **Given** le formulaire d'un service du secteur S, **When** l'administratrice ouvre « Service parent », **Then** la liste contient « Aucun » et les services **sans parent** du secteur S, à l'exclusion du service édité. Si le service édité a lui-même des pôles, le sélecteur est désactivé avec une explication (« Ce service a N pôle(s) : il ne peut pas être rattaché »).
2. **Given** un service sans secteur, **When** l'administratrice ouvre le sélecteur, **Then** seuls les services de premier niveau sans secteur sont proposés.
3. **Given** une requête qui donne au service son propre identifiant comme parent, ou un parent qui a lui-même un parent, ou un parent d'un autre secteur, ou un parent à un service qui a des pôles, **When** elle est envoyée au serveur, **Then** elle est refusée avec un message explicite en français et rien n'est enregistré.
4. **Given** un service parent qui a des pôles, **When** l'administratrice change son secteur, **Then** l'enregistrement est refusé (« Déplacez ou détachez d'abord ses N pôle(s) ») ; de même pour le changement de secteur d'un pôle vers un secteur différent de celui de son parent.
5. **Given** le champ « Page dédiée », **When** l'administratrice saisit une valeur, **Then** seules les adresses internes sont acceptées : elles commencent par `/` (et non par `//`), ne contiennent ni espace, ni schéma, ni préfixe de langue, font 255 caractères au plus et ne visent pas `/r/`. Un champ vide signifie « pas de page dédiée ». L'aide du champ l'explique avec l'exemple `/entrepreneuriat`.
6. **Given** la liste des services, **When** elle s'affiche, **Then** chaque pôle apparaît en retrait sous son parent (repère « Pôle de … »). Les filtres et la recherche restent opérationnels : un pôle trouvé par la recherche montre le nom de son parent.
7. **Given** une création, une modification (y compris du parent ou de la page dédiée) ou une suppression de service, **When** l'opération réussit, **Then** une entrée d'audit est créée avec l'auteur, l'action, le service et les valeurs avant / après des champs modifiés.
8. **Given** la suppression d'un service qui a des pôles, **When** l'administratrice la demande, **Then** la confirmation annonce que ses N pôle(s) deviendront des services de premier niveau du secteur. Après suppression, ils le sont.

---

### User Story 3 - Accéder au mini-site depuis le menu, le pied de page et un lien court (Priority: P2)

Une étudiante ouvre le menu « Plus » du site en arabe et y trouve « Entreprendre à Senghor » (avec une icône), qui la mène à `/ar/entrepreneuriat`. Un visiteur anglophone trouve le même lien dans le groupe « The University » du pied de page. L'équipe du pôle imprime sur ses supports l'adresse courte `…/r/pei`, qui mène au mini-site.

**Why this priority**: Rend le mini-site trouvable par tous. C'est un critère d'acceptation, mais il dépend peu de la structure de l'organigramme et se livre indépendamment.

**Independent Test**: Jouer la migration de seed du menu sur une base où la liste du sous-menu a été modifiée à la main. Vérifier que les entrées existantes sont intactes et que l'entrée est ajoutée une seule fois, même en rejouant. Ouvrir le menu et le pied de page dans les trois langues, sur écran large et à 390 px. Appeler `/r/pei`.

**Acceptance Scenarios**:

1. **Given** la migration jouée, **When** le visiteur ouvre le menu « Plus » dans la section « Nous connaître », **Then** l'entrée « Entreprendre à Senghor » (icône Font Awesome, par exemple une ampoule ou une fusée) apparaît après les entrées existantes. Elle mène à `/entrepreneuriat` localisé et porte son libellé dans la langue du visiteur : « Entreprendre à Senghor », « Entrepreneurship at Senghor », « ريادة الأعمال في سنغور ».
2. **Given** une liste de sous-menu déjà éditée en backoffice (entrées ajoutées, retirées ou réordonnées), **When** la migration est jouée puis rejouée, **Then** les entrées éditées sont conservées à l'identique et l'entrée du pôle est présente une seule fois (reconnue par son identifiant **ou** par sa route `/entrepreneuriat`).
3. **Given** une liste absente ou vide pour la section « Nous connaître », **When** la migration est jouée, **Then** la liste est créée avec la seule entrée du pôle, sans erreur, et les autres sections du menu sont inchangées.
4. **Given** une liste présente mais invalide (JSON illisible), **When** la migration est jouée, **Then** elle n'est pas modifiée et la migration le signale sans échouer.
5. **Given** l'entrée ajoutée, **When** l'éditrice ouvre l'éditeur du menu en backoffice, **Then** elle peut la modifier, la déplacer ou la retirer comme toute autre entrée. Si elle la retire, un rejeu de la migration la **rajoute** : ce comportement est documenté dans le script.
5b. **Given** l'éditeur du menu, **When** l'éditrice ouvre n'importe quelle entrée (principale ou « Plus »), **Then** elle peut saisir un libellé anglais et un libellé arabe facultatifs. Une entrée existante sans ces libellés s'affiche en anglais et en arabe exactement comme avant la feature.
6. **Given** le pied de page, **When** il s'affiche dans les trois langues, **Then** le groupe « L'Université » contient un lien « Entreprendre à Senghor » (traduit) vers `/entrepreneuriat` localisé, placé après « Gouvernance ». Les cinq liens existants sont inchangés.
7. **Given** le lien court seedé, **When** on ouvre `/r/pei` (ou `/r/PEI`), **Then** le navigateur est redirigé vers `/entrepreneuriat`. Le lien apparaît dans la liste des liens courts du backoffice.
8. **Given** le code `pei` réservé, **When** le compteur des liens générés atteint la valeur qui produirait `pei`, **Then** la création d'un lien court ne tombe pas en erreur : le code déjà pris est sauté.

---

### User Story 4 - Se repérer dans le mini-site grâce au fil d'Ariane (Priority: P2)

Sur n'importe quelle page du mini-site, le fil d'Ariane du hero indique « Accueil › Nous connaître › Organisation › DDE › Pôle Entrepreneuriat et Innovation (› rubrique) », et chaque niveau mène à sa page. Le libellé « DDE » suit le sigle réel du service parent.

**Why this priority**: Il matérialise le rattachement pour le visiteur du mini-site et supprime deux duplications de code, mais les pages fonctionnent déjà sans lui.

**Independent Test**: Ouvrir les sept pages du mini-site dans les trois langues. Suivre chaque niveau du fil d'Ariane. Valider les données structurées du fil d'Ariane. Détacher le pôle de la DDE en local, puis vider la clé DDE, et vérifier le repli.

**Acceptance Scenarios**:

1. **Given** l'accueil du pôle, **When** le fil d'Ariane s'affiche, **Then** il vaut Accueil (lien) › Nous connaître (lien vers `/a-propos`) › Organisation (lien vers `/a-propos/organisation`) › {sigle du parent, sinon « DDE »} (lien vers la fiche du parent) › Pôle Entrepreneuriat et Innovation. Ce dernier niveau est la page courante, marqué comme tel.
2. **Given** une rubrique (par exemple « Nos activités »), **When** le fil d'Ariane s'affiche, **Then** le niveau du pôle est un lien vers `/entrepreneuriat` et le nom de la rubrique est la page courante.
3. **Given** les sept pages, **When** on compare leur fil d'Ariane visible et leurs données structurées « BreadcrumbList », **Then** ils sont identiques niveau par niveau, dans les trois langues, avec des liens localisés.
4. **Given** le pôle sans service parent (détaché) mais la clé DDE renseignée, **When** une page du mini-site s'affiche, **Then** le niveau DDE est résolu par la clé. Si ni parent ni clé ne donnent un service, le niveau DDE est omis sans erreur ni lien vide.
5. **Given** le code du mini-site, **When** on recherche la construction du fil d'Ariane, **Then** elle n'existe qu'à un seul endroit, partagé par les sept pages.

---

### User Story 5 - Référencer correctement l'organisation et le mini-site (Priority: P3)

Un moteur de recherche lit le plan du site : il y trouve des adresses valides pour chaque secteur, chaque service et chaque pôle, ainsi que les sept pages du mini-site dans les trois langues.

**Why this priority**: Corrige un défaut existant révélé par la feature, sans impact visible direct pour le visiteur.

**Independent Test**: Récupérer le plan du site en local et en production. Extraire les adresses d'organisation et vérifier qu'elles répondent toutes avec succès. Vérifier les sept pages `/entrepreneuriat/*` dans les trois langues.

**Acceptance Scenarios**:

1. **Given** le plan du site, **When** on extrait les adresses de secteurs, **Then** chacune est de la forme `/a-propos/organisation/secteur/{code en minuscules}` (et ses équivalents `/en`, `/ar`) et répond avec succès.
2. **Given** le plan du site, **When** on extrait les adresses de services, **Then** chaque service actif **et chaque pôle actif** a une adresse `/a-propos/organisation/service/{nom normalisé}` identique à celle des liens du site, et 100 % de ces adresses répondent avec succès.
3. **Given** le plan du site, **When** on cherche `/entrepreneuriat`, **Then** les sept pages sont présentes dans les trois langues.
4. **Given** la lecture des secteurs indisponible pendant la génération, **When** le plan du site est produit, **Then** il reste valide, sans adresses d'organisation.

---

### User Story 6 - Mettre en ligne et clôturer le mini-site (Priority: P1, en dernier)

Le responsable technique valide, étape par étape, la mise en production. Les trois dépôts sont poussés, une sauvegarde est faite, l'état des migrations 045 à 049 est contrôlé en production (et chacune rejouée si elle manque), la migration 050 est jouée deux fois, puis le site est déployé. Le responsable contrôle les pages, le menu, l'organigramme, le lien court et le plan du site. Il mesure les performances mobiles, puis referme les tâches restées ouvertes dans les features précédentes et met à jour la documentation du projet.

**Why this priority**: Sans mise en ligne, rien n'est livré aux visiteurs. Elle intervient en dernier et chaque action irréversible attend un accord explicite.

**Independent Test**: Dérouler la procédure de mise en ligne du guide de démarrage rapide de la feature, avec un compte rendu consigné par étape (commande, résultat, date).

**Acceptance Scenarios**:

1. **Given** le code terminé, **When** la mise en ligne est lancée, **Then** chaque étape est demandée et approuvée séparément, dans l'ordre : (a) commit et push `origin/main` des trois dépôts (racine, frontend, backend) ; (b) sauvegarde de production ; (c) contrôle **en lecture seule** de l'état des migrations 045 → 049 et de la requête de résolution de la DDE ; (d) migrations manquantes jouées dans l'ordre, deux fois chacune ; (e) migration 050 jouée deux fois ; (f) déploiement avec recréation forcée des conteneurs ; (g) contrôles.
2. **Given** la migration 050 jouée deux fois en production, **When** on compte les services, **Then** il existe exactement un pôle PEI, rattaché à la DDE, avec la page dédiée `/entrepreneuriat`. Le second passage n'ajoute rien et ne modifie aucune valeur éditée entre-temps.
3. **Given** le site déployé, **When** le responsable contrôle la production, **Then** : les sept pages du mini-site répondent dans les trois langues avec leur contenu dans la réponse du serveur ; l'organigramme et la fiche DDE montrent le pôle ; le menu « Plus » et le pied de page proposent l'entrée dans les trois langues ; `/r/pei` redirige ; le plan du site émet des adresses de services valides.
4. **Given** les rôles de production, **When** on contrôle les permissions `entrepreneurship.*`, **Then** elles existent et sont attribuées comme défini en 021. Toute anomalie est signalée avant correction, qui reste soumise à accord.
5. **Given** l'action « Traduire les champs manquants » du pôle lancée en production, **When** elle se termine, **Then** son compte rendu est consigné (champs traduits par domaine) et les pages anglaises et arabes du pôle n'affichent aucun champ vide dû à une traduction manquante.
6. **Given** Lighthouse mobile mesuré derrière nginx en production sur `/entrepreneuriat`, `/entrepreneuriat/activites`, `/entrepreneuriat/statut-etudiant-entrepreneur` et une page existante de référence, **When** les scores sont consignés, **Then** l'accessibilité est ≥ 90 et la performance du mini-site est dans l'écart de la page de référence (écart documenté).
7. **Given** les tâches T071 (021), T039, T048, T051 (023), **When** la mise en ligne est terminée, **Then** chacune est cochée avec sa preuve (date, résultat) ou laissée ouverte avec la raison écrite. La 025 n'a pas de tâche ouverte : ses contrôles de production sont repris dans le scénario 3.
8. **Given** la feature livrée, **When** on lit CLAUDE.md et la mémoire du projet, **Then** ils décrivent les colonnes parent et page dédiée des services, l'affichage des pôles dans l'organigramme, l'entrée de menu, le lien court, la correction du plan du site et l'ordre de rollback.

---

### Edge Cases

- **Résolution de la DDE par la migration** : la clé `entrepreneurship.dde_service_id` est utilisée si elle désigne un service existant. Sinon, la DDE est cherchée par nom, avec apostrophe typographique ’ ou droite et sans tenir compte de la casse. Si plusieurs services correspondent, ou aucun, la migration **ne crée pas** le pôle, le signale et se termine sans erreur : les colonnes sont ajoutées et le rattachement se fait à la main dans le backoffice. La requête est testée en lecture seule sur la base de production avant d'être jouée.
- **Pôle PEI déjà présent** (rejeu, ou service créé à la main) : il est reconnu par sa page dédiée `/entrepreneuriat` ou, à défaut, par son sigle `PEI` dans le secteur de la DDE. Il n'est pas dupliqué et ses valeurs éditées ne sont pas écrasées. Seuls un parent vide et une page dédiée vide sont complétés.
- **Service existant nommé « PEI » ailleurs ou nom en collision** : l'adresse de fiche d'un service dépend de son nom. Si un autre service a déjà le nom « Pôle Entrepreneuriat et Innovation », la migration ne crée pas de second service homonyme et le signale.
- **Parent désactivé** : ses pôles ne sont pas affichés dans l'organigramme (ils y sont imbriqués sous leur parent). Leur fiche et leur page dédiée restent accessibles s'ils sont actifs, et la fiche n'affiche pas de lien vers un parent inactif.
- **Pôle désactivé** : il est absent de l'organigramme, du bloc « Pôles » et du plan du site. Le mini-site `/entrepreneuriat` n'en dépend pas et reste en ligne, avec un fil d'Ariane qui se replie sur la clé DDE.
- **Suppression du parent** : les pôles deviennent des services de premier niveau du secteur. Ils réapparaissent alors comme services dans l'organigramme, ce qui est annoncé à la confirmation.
- **Suppression ou désactivation du secteur** : comportement existant inchangé pour le parent et ses pôles.
- **Page dédiée devenue introuvable** (route supprimée) : la carte mène à une page « introuvable ». Le backoffice ne vérifie pas l'existence de la route, ce qui est documenté dans l'aide du champ.
- **Page dédiée sur un service de premier niveau** (sans parent) : autorisée. Sa carte dans l'organigramme mène alors à cette page ; sans page dédiée, rien ne change.
- **Ordre des pôles** : ordre d'affichage des services, puis nom.
- **Fiche d'un pôle avec page dédiée** : la fiche reste accessible par son adresse et n'est pas redirigée. Elle affiche le lien vers le parent et un lien « Voir la page dédiée ».
- **Sigle absent** : la carte du pôle affiche l'icône par défaut, comme pour les services.
- **Langue arabe** : l'indentation et le repère de rattachement des pôles sont en miroir.
- **Libellé de menu non traduit** (libellé anglais ou arabe vide) : repli sur le libellé français, puis sur la traduction du site ; jamais une clé technique. Une entrée enregistrée avant la feature (sans libellés anglais ni arabe) s'affiche comme aujourd'hui.
- **Code court en conflit** : si `pei` est déjà pris par un autre lien, la migration ne le remplace pas et le signale. La cible `/entrepreneuriat` est une adresse relative, acceptée par la validation existante sans ajout de domaine.
- **Plan du site** : un service sans secteur n'apparaît pas dans la liste des secteurs avec services. L'émission des adresses de services couvre tous les services actifs, avec ou sans secteur, pôles inclus, et chaque adresse n'est émise qu'une fois.
- **Rollback** : le rollback 050 retire le pôle PEI créé par la migration (s'il n'a ni équipe ni contenu rattaché ; sinon il le détache et le signale), l'entrée de menu du pôle, le lien court `pei`, puis les colonnes. Il se joue **avant** les rollbacks 049 → 045. Rejoué, il ne produit pas d'erreur.

## Requirements *(mandatory)*

### Functional Requirements

**Niveau « pôle » (données et règles)**

- **FR-001**: Un service MUST pouvoir avoir un **service parent** facultatif et une **page dédiée** facultative (adresse interne du site, 255 caractères au plus).
- **FR-002**: La hiérarchie MUST être limitée à un niveau et valide en permanence :
  - pas d'auto-rattachement ;
  - un service qui a un parent ne peut pas être parent ;
  - un service qui a des pôles ne peut pas recevoir de parent ;
  - le parent et le pôle ont le même secteur (ou tous deux aucun).
  Ces règles MUST être garanties côté serveur pour toute écriture, par l'interface comme par un appel direct, avec un message explicite en français. La base MUST garantir au minimum l'absence d'auto-référence et l'effacement du lien à la suppression du parent.
- **FR-003**: Le changement de secteur d'un service qui a des pôles, ou d'un pôle vers un secteur différent de celui de son parent, MUST être refusé avec un message indiquant le nombre de pôles concernés.
- **FR-004**: La page dédiée MUST être une adresse interne commençant par `/` (hors `//`, schéma, espace, préfixe de langue et `/r/`), stockée sans préfixe de langue. Une valeur vide MUST être enregistrée comme absente.
- **FR-005**: La lecture publique des secteurs avec leurs services MUST renvoyer les pôles imbriqués sous leur service parent (liste `children`, triée par ordre d'affichage puis nom, pôles actifs uniquement) et MUST NOT les renvoyer au niveau du secteur. Chaque service et chaque pôle expose sa page dédiée. Pour un service sans pôle, la réponse ne change que par l'ajout de champs.
- **FR-006**: La lecture publique d'un service MUST exposer son parent (identifiant, nom, sigle, couleur, page dédiée ; absent si le parent est inactif) et ses pôles actifs, avec les mêmes champs. La lecture publique de la liste des services MUST continuer d'inclure les pôles, pour que la recherche d'une fiche par son adresse et le calcul de son adresse fonctionnent à l'identique.
- **FR-007**: Les lectures et écritures du backoffice sur les services MUST exposer et accepter le parent et la page dédiée. La lecture de la liste MUST permettre d'afficher la hiérarchie (parent de chaque service, nombre de pôles).
- **FR-008**: Chaque création, modification et suppression de service dans le backoffice MUST être tracée dans le journal d'audit existant : auteur, action, identifiant du service, valeurs avant et valeurs envoyées, dont le parent et la page dédiée. Le journal général des écritures du backoffice le fait déjà ; la feature vérifie que les deux nouvelles données y figurent, sans double enregistrement.
- **FR-008b**: Les lectures publiques des secteurs (avec leurs services, ou par code) MUST NOT modifier ni supprimer aucune donnée ; un service ou un pôle inactif MUST rester en base après tout nombre de lectures publiques (correction du défaut constaté au plan).

**Structure de référence et migration**

- **FR-009**: Le schéma de référence de l'organisation MUST décrire les deux nouvelles données et leurs contraintes.
- **FR-010**: Une migration rejouable `050_services_parent_landing.sql` et son script de retour arrière MUST :
  - ajouter les deux colonnes et leurs contraintes (sans échec si elles existent déjà) ;
  - créer, s'il n'existe pas, le service « Pôle Entrepreneuriat et Innovation » (sigle `PEI`, page dédiée `/entrepreneuriat`, actif, même secteur que la DDE, rattaché à la DDE), la DDE étant résolue comme décrit dans les cas limites ;
  - ajouter, sans écraser la liste existante, l'entrée trilingue « Entreprendre à Senghor » au sous-menu « Nous connaître » (FR-020) ;
  - créer le lien court `pei` → `/entrepreneuriat` s'il n'existe pas.

  Chaque étape MUST afficher un compte rendu (créé / déjà présent / ignoré et pourquoi). Le rollback MUST retirer exactement ces éléments dans l'ordre inverse et MUST être documenté comme devant être joué **avant** les rollbacks 049 → 045.
- **FR-011**: Le SQL (schéma de référence et migration 050 avec son rollback) MUST être soumis à accord **avant** tout code. La requête de résolution de la DDE MUST être testée en lecture seule sur la base de production avant la mise en ligne.

**Backoffice**

- **FR-012**: Le formulaire d'un service MUST proposer un sélecteur « Service parent ». Il contient « Aucun » et les services sans parent du même secteur que celui choisi dans le formulaire (liste mise à jour quand le secteur change), et MUST exclure le service édité. Le sélecteur MUST être désactivé, avec explication, si le service édité a des pôles. Une erreur renvoyée par le serveur MUST s'afficher près du champ.
- **FR-013**: Le formulaire MUST proposer un champ « Page dédiée » avec aide et exemple, et une validation immédiate de la forme de l'adresse (FR-004).
- **FR-014**: La liste des services MUST afficher chaque pôle en retrait sous son parent, avec un repère « Pôle de {parent} ». La recherche et les filtres existants continuent de fonctionner, et un pôle affiché hors de son parent (résultat de recherche, filtre) indique son parent.
- **FR-015**: La confirmation de suppression d'un service qui a des pôles MUST annoncer que ses pôles deviendront des services de premier niveau.

**Affichage public**

- **FR-016**: L'onglet Présentation de la fiche d'un service qui a au moins un pôle actif MUST afficher un bloc « Pôles » (titre traduit) listant ses pôles en cartes au style des cartes de l'organigramme. Une carte MUST mener à la page dédiée localisée du pôle si elle existe, sinon à sa fiche. Sans pôle actif, la fiche MUST rester identique à l'existant (aucun bloc, aucun espace réservé).
- **FR-017**: La fiche d'un pôle MUST afficher un lien de retour vers la fiche de son parent actif (libellé traduit, par exemple « Pôle de la DDE »). Si le pôle a une page dédiée, elle MUST aussi proposer un lien vers cette page.
- **FR-018**: Dans l'organigramme, les pôles actifs d'un service MUST apparaître immédiatement sous la carte de ce service, avec une indentation légère et un repère de rattachement (en miroir en arabe), et MUST NOT être comptés ni affichés comme services du secteur. La carte de tout service ou pôle ayant une page dédiée MUST mener à cette page localisée. Un service sans pôle et sans page dédiée MUST garder un affichage identique.
- **FR-019**: Tous les nouveaux libellés publics et du backoffice (bloc « Pôles », lien vers le parent, lien vers la page dédiée, aides) MUST exister en français, anglais et arabe pour le public, et en français avec accents pour le backoffice.

**Menu, pied de page et lien court**

- **FR-020**: Une migration de seed MUST **ajouter** l'entrée « Entreprendre à Senghor » (identifiant `entrepreneurship`, route `/entrepreneuriat`, icône Font Awesome, ordre après la dernière entrée) avec ses libellés français, anglais et arabe, au sous-menu « Nous connaître » (`about`) du menu « Plus », sans modifier ni réordonner les entrées existantes, sans doublon au rejeu (identifiant ou route déjà présents) et sans toucher une liste illisible. L'affichage MUST suivre la langue du visiteur, avec repli français et sans clé technique visible.
- **FR-020b**: Les entrées du menu éditorial (principal et « Plus ») MUST accepter des libellés anglais et arabe facultatifs, lus selon la langue du visiteur avec repli sur le libellé français, puis sur la traduction du site. L'éditeur du menu en backoffice MUST permettre de les saisir pour toute entrée. Les entrées existantes, sans ces libellés, MUST garder un rendu identique, et les listes enregistrées avant la feature MUST rester lisibles sans conversion.
- **FR-021**: Le groupe « L'Université » du pied de page MUST contenir un lien « Entreprendre à Senghor » vers `/entrepreneuriat` localisé, libellé en français, anglais et arabe. Les liens existants restent inchangés.
- **FR-022**: Un lien court de code `pei` MUST rediriger vers `/entrepreneuriat`, sans auteur ou attribué à un compte d'administration existant. La génération automatique des codes MUST sauter tout code déjà pris au lieu d'échouer.

**Fil d'Ariane du mini-site**

- **FR-023**: Les sept pages du mini-site MUST afficher le fil d'Ariane Accueil › Nous connaître › Organisation › {DDE} › Pôle Entrepreneuriat et Innovation (› rubrique). Chaque niveau autre que la page courante MUST être un lien localisé, et la page courante MUST être indiquée comme telle.
- **FR-024**: Le niveau {DDE} MUST être résolu d'abord par le service parent du pôle dont la page dédiée est `/entrepreneuriat`, sinon par la clé `entrepreneurship.dde_service_id`. Il affiche le sigle du service (repli : libellé traduit « DDE ») et mène à sa fiche. S'il est introuvable, il MUST être omis sans erreur.
- **FR-025**: La construction du fil d'Ariane et de ses données structurées MUST être unique et partagée par les sept pages. Les duplications de l'accueil du pôle et de « Nos activités » MUST être supprimées, sans autre changement visible sur ces pages.

**Plan du site**

- **FR-026**: Le plan du site MUST émettre, dans les trois langues, `/a-propos/organisation/secteur/{code en minuscules}` pour chaque secteur actif et `/a-propos/organisation/service/{nom normalisé}` pour chaque service et pôle actifs, avec la même normalisation que les liens du site. Il MUST continuer d'inclure les sept pages `/entrepreneuriat/*` dans les trois langues.

**Mise en ligne et documentation**

- **FR-027**: Chaque action de mise en ligne MUST être soumise à un accord explicite distinct et consignée (commande, résultat, date) dans le guide de démarrage rapide de la feature :
  1. commit et push `origin/main` des trois dépôts ;
  2. sauvegarde de production ;
  3. contrôle en lecture seule de l'état des migrations 045 → 049 (comptes attendus consignés dans leurs features), puis rejeu, dans l'ordre et deux fois, de celles qui manqueraient ;
  4. migration 050 jouée deux fois ;
  5. déploiement avec recréation forcée ;
  6. contrôles de production (pages, menu, pied de page, organigramme, fiche DDE, `/r/pei`, plan du site, permissions `entrepreneurship.*`) ;
  7. « Traduire les champs manquants » du pôle ;
  8. Lighthouse mobile derrière nginx comparé à une page existante.
- **FR-028**: Les tâches de production restées ouvertes (T071 de la 021 ; T039, T048, T051 de la 023) MUST être closes avec preuve ou laissées ouvertes avec une raison. Les captures avant / après de T039 non réalisées (fiches formation, projet, appel ; 390 px) MUST être reprises dans la non-régression de cette feature, avec les fiches secteur et service.
- **FR-029**: CLAUDE.md et la mémoire du projet MUST être mis à jour : données parent et page dédiée des services et leurs règles, pôles dans l'organigramme et sur la fiche, entrée de menu, pied de page, lien court, correction du plan du site, fil d'Ariane factorisé, migration 050 et ordre des rollbacks.

### Key Entities *(include if feature involves data)*

- **Service** (existant, étendu) : ajoute le **service parent** (facultatif, même secteur, un seul niveau) et la **page dédiée** (adresse interne facultative). Un service de premier niveau peut avoir plusieurs **pôles** (services enfants).
- **Pôle Entrepreneuriat et Innovation** (instance créée par la migration) : service de sigle `PEI`, rattaché à la DDE, page dédiée `/entrepreneuriat`.
- **Entrée du menu « Plus »** (existante, listes éditoriales) : identifiant, libellé, route, icône, ordre, et désormais libellés anglais et arabe facultatifs. Nouvelle instance `entrepreneurship`.
- **Lien court** (existant) : code `pei`, cible `/entrepreneuriat`.
- **Entrée d'audit** (existante) : désormais produite pour les écritures de services.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Depuis la page « Notre organisation », un visiteur atteint l'accueil du mini-site en 1 clic, et depuis la fiche de la DDE en 1 clic, dans les trois langues.
- **SC-002**: 100 % des fiches secteur et service existantes sans pôle sont identiques avant / après : captures à 1440 px et 390 px, organigramme compris.
- **SC-003**: 100 % des tentatives de cycle, de second niveau ou de rattachement inter-secteur sont refusées, par l'interface comme par appel direct, et 0 donnée hiérarchique invalide n'existe en base après les tests.
- **SC-004**: Le menu « Plus » et le pied de page proposent l'entrée dans les trois langues, avec 0 clé technique visible, et un rejeu de la migration de seed laisse 100 % des entrées de menu éditées inchangées, sans doublon.
- **SC-005**: `/r/pei` redirige vers le mini-site en production.
- **SC-006**: 100 % des adresses d'organisation du plan du site répondent avec succès, et chaque service et pôle actif y figure une fois par langue.
- **SC-007**: Les sept pages du mini-site affichent un fil d'Ariane de 5 ou 6 niveaux dont 100 % des niveaux intermédiaires sont des liens valides, identique à leurs données structurées.
- **SC-008**: Les migrations 050 et suivantes se jouent deux fois sans erreur en local puis en production, avec des comptes identiques après le second passage. Le rollback 050, joué avant les rollbacks 049 → 045, remet la base dans l'état antérieur sans erreur.
- **SC-009**: 100 % des créations, modifications et suppressions de services faites pendant les tests apparaissent dans le journal d'audit ; 0 service inactif supprimé par une lecture publique.
- **SC-010**: En production, les sept pages du mini-site ont une accessibilité mobile ≥ 90 et une performance dans l'écart de la page de référence (écart consigné). Les tâches T071, T039, T048 et T051 sont closes ou justifiées.

## Assumptions

- **Nom et sigle du pôle** : « Pôle Entrepreneuriat et Innovation », sigle `PEI`. Les traductions du nom sont produites par la traduction automatique existante de l'organisation (ou par « Traduire les champs manquants »). La couleur est celle de la DDE et la description reste vide, à saisir par l'équipe.
- **Pôle et secteur** : le pôle reprend le secteur de la DDE à la création. Un pôle ne peut pas être créé dans un autre secteur que son parent.
- **Libellé DDE du fil d'Ariane** : sigle du service parent tel que saisi (aujourd'hui « DDE »), repli traduit. Le libellé du niveau pôle reste le libellé traduit du mini-site.
- **Fiche d'un pôle avec page dédiée** : pas de redirection automatique vers la page dédiée, pour ne pas changer le comportement des adresses de fiche. Liens vers le parent et vers la page dédiée.
- **Audit** : on réutilise le journal d'audit existant, sans nouvelle permission. Le rattachement et le détachement sont des modifications ordinaires du service.
- **Icône du menu** : `fa-solid fa-lightbulb` par défaut (modifiable dans l'éditeur du menu).
- **Position dans le pied de page** : après « Gouvernance », dont le lien mène à l'organisation.
- **Lien court** : `pei` fait 3 caractères, ce qui respecte la limite de 4. La cible relative ne demande aucun ajout de domaine autorisé.
- **Production** : d'après les suivis, 045 à 049 sont déjà jouées. Le contrôle en lecture seule le confirme avant toute écriture, et aucune migration n'est rejouée sans raison, même si toutes sont rejouables.
- **Aucune nouvelle permission** : les écrans et lectures du backoffice des services gardent leurs permissions actuelles.
- **Hors périmètre** : contenu éditorial réel du pôle, hiérarchie de plus d'un niveau, redirections d'anciennes adresses (aucune adresse publique ne change), traduction du libellé des autres entrées de menu existantes : les champs de libellés anglais et arabe deviennent disponibles pour toutes les entrées, mais seule celle du pôle est remplie.

## Dependencies

- Features 021 à 025 (mini-site, clé `entrepreneurship.dde_service_id`, cadre commun des rubriques, permissions `entrepreneurship.*`, « Traduire les champs manquants » du pôle).
- Organisation existante : secteurs, services, fiches publiques, organigramme, formulaire et liste du backoffice.
- Barre de navigation éditoriale (listes `navbar.secondary.*.children`, éditeur du menu), pied de page, raccourcisseur de liens (feature 014), plan du site, journal d'audit.
- Accès à la production (sauvegarde, base, déploiement) et accord explicite du responsable pour chaque action.
