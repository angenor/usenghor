# Feature Specification: Page « Entreprendre et étudier à Senghor » — Statut Étudiant-Entrepreneur (guide, FAQ, candidature)

**Feature Branch**: `025-pei-see-status-page`

**Created**: 2026-09-14

**Status**: Draft

**Input**: User description: "Créer la page publique « Entreprendre et étudier à Senghor » (`/entrepreneuriat/statut-etudiant-entrepreneur`) dédiée au Statut Étudiant-Entrepreneur (SEE), appel à l'action permanent du mini-site du PEI, selon les pages 4 à 7 du cahier des charges. [...] Maquette `statut-etudiant-entrepreneur.{png,html}`. Hero `PageHero` (mode motif, badge « Statut Étudiant-Entrepreneur · Appel {année} »), sous-navigation avec le bouton « Postuler au statut » mis en évidence. FAQ dans le backoffice FAQ existant : quatre catégories au code réservé `see-*`, sans modification de schéma, filtre optionnel rétrocompatible sur la lecture publique, visibilité sur `/faq` à clarifier, seed de 4 catégories et 9 questions. Appel SEE = appel à candidatures de type formation désigné par la clé `entrepreneurship.see.call_slug`, lu par la lecture publique existante ; états ouvert / à venir / clos / absent, sans erreur ; pas de nouveau formulaire. Textes du guide en clés éditoriales `entrepreneurship.see.*`. Migration rejouable 049 (+ rollback, accord préalable sur le SQL). JSON-LD `FAQPage` + `BreadcrumbList`, i18n FR/EN/AR, RTL, SEO, 390 px, mode sombre. Hors périmètre : sélection des candidatures, création de l'appel SEE 2026, menu principal, organigramme."

**Références** : `specs/roadmap-pei-entrepreneuriat.md` (prompt 025), `specs/021-pei-entrepreneurship-core/` (clés éditoriales `entrepreneurship.*`, section « Valeurs » `entrepreneurship-see`, clé `see.call_slug`), `specs/023-pei-public-home-activities/` (cadre commun : hero, sous-navigation, fil d'Ariane, SEO, i18n, masquage), `specs/024-pei-public-alumni-resources-news/` (cadre de rubrique partagé, états vides, bandeau CTA), `specs/019-faq-backoffice/` (FAQ trilingue, catégories, JSON-LD), `specs/maquettes-pei/README.md`, `specs/maquettes-pei/statut-etudiant-entrepreneur.{png,html}`.

## Contexte

Le mini-site « Entreprendre à Senghor » (features 023 et 024) compte six rubriques publiques. Trois liens y mènent déjà vers `/entrepreneuriat/statut-etudiant-entrepreneur` (bouton du hero de l'accueil, bandeau CTA de l'accueil, bouton rouge de la sous-navigation) mais cette adresse répond aujourd'hui par la page « introuvable ».

Cette feature livre la page de conversion du pôle : elle explique le Statut Étudiant-Entrepreneur (deux parcours SEE 1 / SEE 2, six avantages, conditions, critères du jury, pièces du dossier), répond aux questions fréquentes, et mène le candidat vers le formulaire de l'appel SEE en cours. Rien n'est dupliqué : la FAQ reste gérée dans le backoffice FAQ du site, l'appel (dates, pièces, formulaire) dans Candidatures → Appels, les textes du guide dans la page éditoriale « Valeurs » du pôle. La page reflète ces trois sources en direct.

Constats de l'existant qui encadrent la feature (vérifiés dans le code) :

- Le statut d'un appel (à venir, en cours, clos) est **saisi en backoffice** ; il n'évolue pas seul avec les dates, sauf la clôture automatique des appels en cours dont la date limite est dépassée, déclenchée par les listes d'appels et non par la lecture d'un appel isolé.
- La lecture publique d'un appel répond « introuvable » pour un appel inexistant **et** pour un appel non publié.
- Le bouton « Postuler » de la page de détail d'un appel ignore l'option « formulaire interne désactivé » : un appel sans adresse externe et sans formulaire interne renvoie vers un formulaire que le serveur refuse. La page SEE ne doit pas reproduire ce défaut (voir FR-018).
- La lecture publique de la FAQ renvoie **toutes** les catégories actives, y compris vides, sans paramètre ; les libellés des catégories ne bénéficient d'aucune traduction automatique (seules les entrées sont traduites, à l'enregistrement).
- La sous-navigation du pôle n'a pas d'onglet pour le SEE ; son bouton rouge n'a pas d'état « page courante ».
- La maquette montre **8 questions en 3 groupes** (le 3ᵉ groupe réunit « Engagement, risques et confidentialité ») et ne rédige que 2 réponses ; la description demande **9 questions en 4 groupes**. Le cahier des charges source n'est pas présent dans le dépôt (voir la clarification Q2).

## Clarifications

### Session 2026-09-14 (décisions prises dans la description de la feature)

- Les sous-groupes de FAQ sont modélisés comme **quatre catégories FAQ** au code réservé `see-general`, `see-avantages`, `see-engagement`, `see-confidentialite`, sans modification de la structure de la FAQ.
- La lecture publique de la FAQ reçoit un **filtre optionnel** par préfixe de code de catégorie ; sans ce filtre, sa forme et ses règles sont inchangées.
- L'agenda de la maquette (dates 2026) est un exemple : en production, il vient du calendrier de l'appel désigné.
- Un appel **absent** (clé vide, appel introuvable ou non publié) produit le même état que l'appel clos, jamais une erreur ni une page « introuvable ».

### Session 2026-09-14 (réponses du demandeur)

- Q1 : Les catégories FAQ `see-*` sont-elles visibles sur `/faq` ? → **Oui**, elles restent visibles dans la FAQ générale (quatre groupes supplémentaires) ; `/faq` et la lecture publique sans filtre ne sont pas modifiées ; les mêmes questions figurent dans les données structurées des deux adresses (doublon accepté).
- Q2 : Contenu des questions / réponses ? → Les deux réponses rédigées dans la maquette (« Le statut est-il payant ? », « Ai-je droit à des aménagements académiques grâce au SEE ? ») sont seedées **publiées** ; les autres questions connues de la maquette sont seedées **en brouillon** avec une réponse provisoire à compléter par l'équipe dans le backoffice FAQ avant publication. La maquette ne nomme que 8 questions : la 9ᵉ question du cahier des charges, dont le texte n'est pas disponible, est créée par l'équipe dans le backoffice (aucun intitulé inventé).
- Q3 : Source des conditions et des pièces du dossier ? → **L'appel d'abord, les textes éditoriaux en secours** : les critères d'éligibilité de l'appel alimentent « Conditions » et ses pièces requises « Mon dossier de candidature » ; si l'appel est absent ou si la liste correspondante est vide, les textes éditoriaux s'affichent. Les critères du jury restent éditoriaux.

### Session 2026-09-14 (suite des décisions de la description)

- La copie de page suit la convention monolingue du système éditorial (clarification Q1 de la 023) ; les libellés fixes (états de l'appel, textes d'accessibilité, fil d'Ariane) sont traduits.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Comprendre le statut et postuler à l'appel ouvert (Priority: P1)

Une étudiante de Master clique « Devenir étudiant-entrepreneur » dans la sous-navigation du pôle. Elle arrive sur `/entrepreneuriat/statut-etudiant-entrepreneur` : hero à motif (badge « Statut Étudiant-Entrepreneur · Appel 2026 », titre « Entreprendre et étudier à Senghor », sous-titre, fil d'Ariane prolongé de « Entreprendre et étudier »), sous-navigation dont le bouton « Postuler au statut » est marqué comme page courante. Elle lit l'intro « Vous avez une idée ? Nous avons le cadre pour la faire grandir. », l'encadré « Le SEE, c'est quoi ? » et les cartes SEE 1 (idée → Mature Ton Idée) et SEE 2 (plan d'affaires → Senghor'Innov), puis « Six leviers pour votre projet ». Dans « Suis-je le bon candidat ? », elle vérifie les conditions, les critères du jury et les pièces du dossier, pendant que le panneau « Agenda 2026 » reste visible à côté (badge « Appel ouvert », étapes datées, date limite en rouge). Elle clique « Postuler via le formulaire » et arrive sur le formulaire de l'appel.

**Why this priority**: C'est la raison d'être de la page (appel à l'action permanent du pôle) et la destination de trois liens existants qui mènent aujourd'hui à « introuvable ».

**Independent Test**: Créer en backoffice un appel publié de type formation, statut « en cours », date limite future, avec calendrier de six étapes, critères et pièces, formulaire interne ; renseigner son adresse dans la clé `entrepreneurship.see.call_slug` ; ouvrir la page sans être connecté ; vérifier chaque section dans l'ordre de la maquette, le panneau collant, le bouton ; modifier une date de l'appel et constater la mise à jour au rechargement.

**Acceptance Scenarios**:

1. **Given** l'appel désigné est publié, en cours, date limite future, **When** la visiteuse ouvre la page, **Then** les sections apparaissent dans l'ordre : hero, sous-navigation, intro + encadré + cartes SEE 1 / SEE 2, six leviers, « Suis-je le bon candidat ? » avec agenda, FAQ, lien PÉPITE France, CTA final ; le badge du hero indique l'année de l'appel et le panneau agenda porte le badge « Appel ouvert ».
2. **Given** l'appel a un calendrier de six étapes, **When** le panneau agenda s'affiche, **Then** chaque étape apparaît dans l'ordre du backoffice avec sa date (ou sa période) formatée dans la langue du visiteur, son intitulé et sa description éventuelle ; l'étape correspondant à la date limite est distinguée (pastille rouge).
3. **Given** un écran large, **When** la visiteuse fait défiler la section « Suis-je le bon candidat ? », **Then** le panneau agenda reste visible sous la sous-navigation collante sans la recouvrir, jusqu'à la fin de la section ; à 390 px le panneau n'est pas collant et s'insère dans le flux (après le contenu de candidature).
4. **Given** l'appel utilise le formulaire interne, **When** la visiteuse clique « Postuler via le formulaire » (panneau agenda) ou le bouton du CTA final, **Then** elle arrive sur la page de candidature du site pour cet appel, dans sa langue.
5. **Given** l'appel a une adresse de formulaire externe, **When** elle clique l'un des boutons « Postuler », **Then** le formulaire externe s'ouvre dans un nouvel onglet sécurisé.
6. **Given** la page SEE ouverte, **When** on examine la sous-navigation, **Then** aucun des six onglets n'est actif et le bouton « Postuler au statut » porte l'état « page courante » (visuel et accessible).
7. **Given** une date de l'appel modifiée en backoffice, **When** la page est rechargée (au plus une minute après), **Then** la nouvelle date est affichée, sans redéploiement.

---

### User Story 2 - Trouver les réponses à ses questions dans la FAQ du statut (Priority: P1)

Un étudiant hésite : le statut est-il payant ? peut-il postuler en groupe ? son idée sera-t-elle protégée ? Il descend à « Vos questions sur le statut » et parcourt les questions regroupées sous « Généralités », « Avantages et aménagements », « Engagement et risques », « Confidentialité ». Il ouvre plusieurs réponses à la fois. Il partage le lien direct vers une question. L'équipe du pôle corrige une réponse dans le backoffice FAQ : la correction est visible sur la page sans redéploiement.

**Why this priority**: La FAQ lève les freins à la candidature ; son alimentation par le backoffice FAQ est un critère d'acceptation explicite et touche une page existante (`/faq`) dont la non-régression est exigée.

**Independent Test**: Jouer la migration 049 ; ouvrir la page et vérifier les quatre groupes et les deux questions publiées ; publier une question en brouillon après avoir complété sa réponse, modifier une réponse et dépublier une question en backoffice, recharger ; ouvrir `/faq` et comparer avec la capture d'avant la feature ; valider les données structurées de la page.

**Acceptance Scenarios**:

1. **Given** les quatre catégories `see-*` actives ayant chacune au moins une entrée publiée, **When** la FAQ de la page s'affiche, **Then** quatre groupes titrés apparaissent dans l'ordre du backoffice, chacun avec ses questions dans l'ordre du backoffice, en accordéon (plusieurs réponses ouvrables simultanément) ; aucune question d'une autre catégorie n'apparaît.
2. **Given** une réponse modifiée en backoffice, **When** la page est rechargée (au plus une minute après), **Then** la nouvelle réponse est affichée.
3. **Given** une question dépubliée, ou une catégorie `see-*` désactivée ou sans entrée publiée, **When** la page est rechargée, **Then** la question ou le groupe entier disparaît ; si plus aucune question SEE n'est publiée, la section FAQ (titre compris) et ses données structurées sont absentes.
4. **Given** l'adresse de la page suivie de l'ancre d'une question, **When** elle est ouverte, **Then** la question ciblée est dépliée et visible, comme sur `/faq`.
5. **Given** la page rendue par le serveur, **When** on inspecte ses données structurées, **Then** une page de questions fréquentes (type « FAQPage ») liste exactement les questions SEE publiées dans la langue courante, ainsi qu'un fil d'Ariane cohérent avec celui affiché.
6. **Given** `/faq` avant et après la feature, **When** on compare, **Then** les catégories `see-*` y apparaissent comme toute autre catégorie active (règles existantes de `/faq` inchangées, y compris pour une catégorie sans entrée publiée) et rien d'autre ne change (recherche, filtre, ancres, données structurées).
7. **Given** la lecture publique de la FAQ appelée sans filtre, **When** on compare sa réponse avant / après la feature, **Then** sa forme et ses règles sont identiques (seules les nouvelles catégories et entrées seedées s'y ajoutent).

---

### User Story 3 - Comprendre qu'il n'y a pas d'appel ouvert et savoir quoi faire (Priority: P2)

En dehors de la période de candidature, un étudiant arrive sur la page. Le guide, les avantages, les conditions et la FAQ restent consultables. À la place du bouton « Postuler », il voit l'état de l'appel : « Appel à venir — ouverture le 1ᵉʳ avril 2027 » si l'appel est annoncé, ou « Appel clos — prochaine session » avec l'invitation à écrire à `entrepreneuriat@usenghor.org`. Aucune page d'erreur, même si l'équipe n'a encore désigné aucun appel.

**Why this priority**: La page est un appel à l'action **permanent** ; la plupart du temps, aucun appel n'est ouvert. Elle doit rester utile et sans erreur dans ces états.

**Independent Test**: Tester successivement : appel « à venir » ; appel « clos » ; appel « en cours » mais date limite dépassée ; appel non publié ; adresse inexistante ; clé vide ; lecture de l'appel en erreur. Pour chacun, vérifier l'état affiché, le badge du hero, le CTA final, l'absence d'erreur et le statut HTTP 200 de la page.

**Acceptance Scenarios**:

1. **Given** l'appel désigné est publié avec le statut « à venir », **When** la page s'affiche, **Then** le panneau agenda porte le badge « Appel à venir », affiche le calendrier s'il existe et la date d'ouverture si elle est renseignée, ne propose aucun bouton menant au formulaire, et invite à écrire au pôle ; le badge du hero indique l'année de l'appel.
2. **Given** l'appel désigné est clos (statut « clos », ou statut « en cours » avec date limite dépassée), **When** la page s'affiche, **Then** le panneau affiche le badge « Appel clos », le message « appel clos, prochaine session » (texte éditorial) et un bouton / lien de contact par e-mail vers l'adresse du pôle ; le calendrier passé reste consultable ; aucun bouton ne mène au formulaire.
3. **Given** la clé `entrepreneurship.see.call_slug` vide, ou désignant un appel inexistant ou non publié, ou une lecture de l'appel en erreur, **When** la page s'affiche, **Then** elle répond normalement (pas de page « introuvable » ni d'erreur serveur), le panneau affiche l'état « appel clos, prochaine session » avec le contact e-mail et sans calendrier, et le badge du hero est affiché sans mention d'année.
4. **Given** un état autre que « ouvert », **When** la visiteuse arrive au CTA final, **Then** son bouton principal ouvre un e-mail à l'adresse du pôle au lieu de mener au formulaire ; l'adresse e-mail reste visible.
5. **Given** un appel ouvert dont le formulaire interne est désactivé et sans adresse externe, **When** la page s'affiche, **Then** aucun bouton ne mène à un formulaire inexistant : l'état proposé est le contact par e-mail.

---

### User Story 4 - Mettre à jour le guide sans développeur (Priority: P2)

La chargée de communication du pôle ouvre la page éditoriale « Valeurs » du backoffice, section « Entrepreneuriat — Statut Étudiant-Entrepreneur ». Elle y retrouve, préremplis avec les textes du cahier des charges, tous les textes de la page : hero, intro, encadré, cartes SEE 1 / SEE 2, six leviers (titre, texte, icône), conditions, critères du jury, pièces du dossier, message « appel clos », lien PÉPITE France, CTA final, rappel « directeur de département en copie ». Elle modifie le texte d'un levier et désigne l'appel SEE 2027 : la page reflète les deux changements au rechargement.

**Why this priority**: Garantit « aucun texte codé en dur » et l'autonomie de l'équipe entre deux sessions d'appel ; dépend de la migration 049.

**Independent Test**: Jouer la migration 049 sur une base avec les migrations 045 à 048 ; ouvrir la section éditoriale ; modifier un levier, vider une condition, changer l'adresse de l'appel ; recharger la page publique ; rejouer la migration et vérifier que les valeurs modifiées sont conservées.

**Acceptance Scenarios**:

1. **Given** la migration 049 jouée, **When** l'éditrice ouvre la section éditoriale SEE, **Then** chaque texte visible de la page (hors libellés fixes traduits, données de l'appel et FAQ) y est présent avec sa valeur initiale issue du cahier des charges.
2. **Given** le titre et l'icône du levier 4 modifiés, **When** la page est rechargée, **Then** la carte du levier 4 affiche le nouveau titre et la nouvelle icône ; une icône inconnue ou vide affiche une icône neutre.
3. **Given** une condition, un critère, une pièce ou un levier dont le titre est vidé, **When** la page est rechargée, **Then** l'élément est omis sans laisser d'emplacement vide ; si tous les éléments d'un bloc sont vides, le bloc (titre compris) est masqué.
4. **Given** la migration 049 rejouée après ces modifications, **When** on relit la section, **Then** les valeurs modifiées sont conservées et aucune ligne n'est dupliquée.
5. **Given** la clé `entrepreneurship.see.call_slug` changée pour un autre appel, **When** la page est rechargée, **Then** agenda, badge d'année et boutons reflètent le nouvel appel.

---

### User Story 5 - Lire la page en anglais et en arabe, sur mobile et en mode sombre (Priority: P3)

Un candidat anglophone ou arabophone ouvre la page dans sa langue, sur téléphone, en mode sombre. Les libellés fixes (états de l'appel, fil d'Ariane, textes d'accessibilité) sont traduits ; les questions et réponses de la FAQ et les données de l'appel sont dans sa langue avec repli français ; la copie éditoriale est en français (convention du site) ; la mise en page est en miroir en arabe. Le partage du lien produit un aperçu avec titre, description et image.

**Why this priority**: Exigence transversale du site, vérifiable une fois la page construite.

**Independent Test**: Ouvrir la page dans les trois langues à 1440 px et 390 px, en clair et en sombre ; vérifier les libellés, le sens de lecture, l'absence de défilement horizontal, le panneau agenda non collant sur mobile, le plan du site, l'aperçu de partage et la validité des données structurées.

**Acceptance Scenarios**:

1. **Given** la langue arabe, **When** le visiteur ouvre `/ar/entrepreneuriat/statut-etudiant-entrepreneur`, **Then** le document est en sens droite-à-gauche, les deux colonnes, la frise de l'agenda, les cartes et les accordéons sont en miroir, et aucun libellé fixe n'apparaît en français ou sous forme de clé technique.
2. **Given** une question FAQ sans traduction anglaise et une étape d'agenda sans description anglaise, **When** la page est ouverte en anglais, **Then** les valeurs françaises s'affichent à leur place sans mention d'erreur.
3. **Given** une largeur de 390 px, **When** la page s'affiche, **Then** toutes les sections sont en une colonne (cartes SEE, six leviers, conditions / critères, pièces, agenda), la sous-navigation défile horizontalement, et aucun défilement horizontal de page n'apparaît.
4. **Given** le mode sombre, **When** la page s'affiche, **Then** l'encadré, les cartes, l'agenda, la FAQ et le CTA ont un contraste suffisant, sans zone blanche non prévue.
5. **Given** le partage de l'adresse de la page, **When** l'aperçu se génère, **Then** il montre le titre, une description et une image ; la page figure dans le plan du site dans les trois langues.

---

### Edge Cases

- **Appel en cours, date limite dépassée** (la lecture isolée d'un appel ne déclenche pas la clôture automatique) : la page le traite comme **clos**, selon la règle déjà utilisée par la page de candidature du site (ouvert = statut « en cours » **et** date limite non dépassée).
- **Appel à venir dont la date d'ouverture est passée** (le statut n'évolue pas seul) : la page suit le statut saisi (« à venir ») ; aucune ouverture automatique n'est inventée.
- **Appel sans calendrier** : le panneau conserve son en-tête, son badge d'état et ses boutons ; la frise est remplacée par la date limite (si renseignée), sinon omise.
- **Étape d'agenda sans date de fin** : date unique ; avec date de fin : période. Aucune étape n'est marquée « date limite » par son intitulé : la distinction s'applique à l'étape dont la date correspond à la date limite de l'appel ; si aucune ne correspond, la date limite est ajoutée en ligne dédiée à sa place chronologique [décision de conception à confirmer au plan, aucune donnée nouvelle].
- **Année du badge** : année de la date d'ouverture de l'appel, sinon de la date limite, sinon badge sans année ; les appels à cheval sur deux années affichent l'année d'ouverture.
- **Appel d'un autre type que « formation »** désigné par erreur : affiché normalement (le type n'est pas bloquant) ; le type attendu est documenté dans la description de la clé.
- **Pièces du dossier et conditions** : source appel d'abord, textes éditoriaux en secours, **bloc par bloc** (un appel avec pièces mais sans critères affiche les pièces de l'appel et les conditions éditoriales) ; les critères d'éligibilité marqués non obligatoires sont affichés avec une mention « souhaité » traduite, les pièces non obligatoires avec « facultatif » ; dans tous les cas, un bloc sans élément est masqué et la section « Suis-je le bon candidat ? » garde au moins son titre, son introduction et l'agenda.
- **FAQ vide** (migration 049 non jouée, catégories désactivées, entrées dépubliées) : section FAQ masquée, sans données structurées « FAQPage » ; le lien PÉPITE France reste affiché s'il est renseigné.
- **Question en double** : une entrée n'appartient qu'à une catégorie ; aucune déduplication nécessaire.
- **Code de catégorie réservé** : le code d'une catégorie n'est pas modifiable dans le backoffice FAQ ; un éditeur peut créer une nouvelle catégorie `see-…` : elle apparaît alors sur la page SEE (règle du préfixe) et reste visible sur `/faq` (Q1).
- **Lien PÉPITE France** sans adresse valide : le lien est masqué (jamais de lien « # ») ; il s'ouvre dans un nouvel onglet sécurisé.
- **E-mail du pôle vide** : le contact par e-mail est masqué ; dans un état non ouvert sans e-mail, le panneau affiche seulement le message éditorial de l'appel clos.
- **Clés éditoriales non chargées** (migration 049 non jouée) : hero avec le titre de rubrique traduit, aucune clé brute ; les blocs du guide sans texte sont masqués ; l'agenda et la FAQ fonctionnent indépendamment.
- **Ancre de FAQ inconnue** : ignorée sans erreur.
- **Ancres internes** (« Postuler » vers l'agenda, liens de section) : défilement compatible avec le défilement doux du site et la sous-navigation collante.
- **Cache** : modifications backoffice (FAQ, appel, textes) visibles au plus une minute après.

## Requirements *(mandatory)*

### Functional Requirements

**Cadre de la page**

- **FR-001**: La page MUST être servie à `/entrepreneuriat/statut-etudiant-entrepreneur` (et ses équivalents `/en/…`, `/ar/…`), rendue côté serveur avec ses données, et MUST reprendre le cadre des rubriques du pôle (024) : hero du site en mode motif (image éditoriale optionnelle), fil d'Ariane « Accueil › Nous connaître › Organisation › DDE › Pôle Entrepreneuriat et Innovation › Entreprendre et étudier », sous-navigation du pôle, layout par défaut.
- **FR-002**: Le badge du hero MUST afficher le libellé éditorial du badge suivi de « · Appel {année} » lorsque l'année est connue (voir Edge Cases), sinon le libellé seul ; le hero n'a aucun bouton (maquette).
- **FR-003**: Sur cette page, la sous-navigation MUST n'activer aucun des six onglets et MUST marquer le bouton « Postuler au statut » comme page courante (indication visuelle et accessible), sans changer son rendu sur les autres rubriques. Le libellé du bouton reste celui de la sous-navigation existante (aujourd'hui « Devenir étudiant-entrepreneur », « Postuler au statut » dans la maquette) : un éventuel alignement sur la maquette est un changement de traduction commun aux sept pages du pôle, tranché au plan.
- **FR-004**: Aucun texte visible ne MUST être codé en dur : copie de page dans les clés éditoriales `entrepreneurship.see.*` ; libellés fixes (états de l'appel, fil d'Ariane, « Agenda », textes d'accessibilité, repli du titre) dans les traductions du pôle FR / EN / AR ; données de l'appel via la lecture publique des appels ; questions / réponses via la lecture publique de la FAQ. Aucune lecture réservée à l'administration n'est appelée.
- **FR-005**: Tout bloc sans données ou dont la source est en erreur MUST être masqué entièrement (titre compris) sans empêcher le rendu des autres ; la page MUST toujours répondre normalement (jamais « introuvable » ni erreur serveur du fait de l'appel, de la FAQ ou des textes).
- **FR-006**: Avant tout nouveau composant, l'existence d'un composant similaire MUST être vérifiée. Inventaire vérifié : hero étendu, sous-navigation, bandeau CTA (avec e-mail), état vide, cadre de rubrique partagé, accordéon et élément de FAQ, sections d'appel (calendrier, pièces, éligibilité, bouton « Postuler ») existent et servent de base ; il n'existe ni carte à icône générique pour les leviers, ni panneau d'agenda collant (motif en ligne seulement), ni variante de l'accordéon FAQ sans barre de recherche.

**Section 1 — Intro et « Le SEE, c'est quoi ? »**

- **FR-007**: La section MUST afficher, en deux colonnes (7/5) sur écran large : à gauche surtitre, titre, paragraphe d'accroche et paragraphe courant ; à droite l'encadré sombre « Le SEE, c'est quoi ? » (libellé + texte) puis la carte SEE 1 (badge bleu, titre, texte) et la carte SEE 2 (badge rouge, titre, texte), avec les valeurs de la maquette HTML.

**Section 2 — « Pourquoi postuler ? »**

- **FR-008**: La section MUST afficher surtitre, titre et jusqu'à six leviers en grille (3 colonnes sur écran large, 2 en tablette, 1 en mobile), chacun avec icône (nom d'icône Font Awesome éditable), titre et texte ; valeurs initiales : Coaching et mentorat, Programmes d'élite, Diplôme et projet liés, Flexibilité, Financement, Espace de travail (textes de la maquette).

**Section 3 — « Suis-je le bon candidat ? » et agenda**

- **FR-009**: La section MUST afficher, en deux colonnes (7/5) sur écran large : à gauche surtitre, titre, introduction, puis côte à côte la carte « Conditions » (éléments avec coche) et la carte « Les critères du jury » (éléments numérotés), puis la carte pleine largeur « Mon dossier de candidature » (pièces en deux colonnes) ; à droite le panneau agenda.
- **FR-010**: La carte « Conditions » MUST afficher les critères d'éligibilité de l'appel désigné (ordre du backoffice, langue du visiteur, repli français) et la carte « Mon dossier de candidature » ses pièces requises (nom, description éventuelle) ; lorsque l'appel est absent ou que la liste correspondante est vide, chaque carte MUST afficher à la place ses éléments éditoriaux (`entrepreneurship.see.*`), bloc par bloc. La carte « Les critères du jury » MUST toujours provenir des textes éditoriaux. Les titres des trois cartes sont éditoriaux.
- **FR-011**: Le panneau agenda MUST afficher : titre « Agenda {année} », badge d'état (« Appel ouvert », « Appel à venir », « Appel clos »), frise verticale des étapes du calendrier de l'appel (ordre du backoffice, dates formatées dans la langue du visiteur, étape de date limite distinguée), bouton d'action selon l'état (FR-018 à FR-020) et, en état ouvert, la note éditoriale « Mettez votre Directeur de département en copie. ».
- **FR-012**: Le panneau agenda MUST rester visible au défilement de la section sur écran large (collant, sans passer sous la sous-navigation collante ni sous l'en-tête) et MUST être non collant, dans le flux, en dessous de 1024 px de large.

**Section 4 — FAQ**

- **FR-013**: La section MUST afficher surtitre, titre centré, puis les questions des catégories FAQ actives dont le code commence par `see-`, groupées par catégorie (intitulé de catégorie dans la langue du visiteur, repli français), dans l'ordre du backoffice, en accordéon à ouverture multiple, avec ancres par question et sans barre de recherche ni filtre de catégorie. Les catégories sans question publiée sont omises.
- **FR-014**: La lecture publique de la FAQ MUST accepter un filtre optionnel restreignant la réponse aux catégories dont le code commence par un préfixe donné ; sans ce filtre, la réponse MUST rester identique à l'existant pour les clients autres que `/faq`. Le filtre ne MUST exposer aucune catégorie inactive ni entrée non publiée.
- **FR-015**: Les catégories `see-*` MUST rester visibles sur `/faq` comme toute catégorie active ; ni la page `/faq` ni la lecture publique sans filtre ne sont modifiées (le doublon de données structurées « FAQPage » entre `/faq` et la page SEE est accepté).
- **FR-016**: La page MUST exposer, dans le HTML rendu par le serveur, des données structurées de type « FAQPage » listant exactement les questions SEE publiées (question et réponse en texte brut, langue courante), selon le même mécanisme que `/faq` ; aucune donnée « FAQPage » si aucune question n'est publiée.

**Appel à candidatures : états et boutons**

- **FR-017**: La page MUST lire l'appel dont l'adresse (slug) est la valeur de `entrepreneurship.see.call_slug` via la lecture publique existante d'un appel, et en déduire un état unique : **ouvert** (statut « en cours » et date limite non dépassée), **à venir** (statut « à venir »), **clos** (statut « clos », ou « en cours » avec date limite dépassée), **absent** (clé vide, appel introuvable ou non publié, lecture en erreur).
- **FR-018**: En état ouvert, les boutons « Postuler via le formulaire » (panneau) et du CTA final MUST mener : à l'adresse de formulaire externe de l'appel si elle est renseignée (nouvel onglet sécurisé) ; sinon, si le formulaire interne est activé, à la page de candidature du site pour cet appel (localisée) ; sinon, l'état est traité comme « contact » (FR-020).
- **FR-019**: En état à venir, le panneau MUST afficher le calendrier s'il existe, la date d'ouverture si elle est renseignée, et le contact par e-mail ; aucun bouton ne mène au formulaire.
- **FR-020**: En états clos et absent, le panneau MUST afficher le message éditorial « appel clos, prochaine session » et un lien de contact par e-mail vers `entrepreneurship.contact.email` (sujet prérempli traduit) ; le calendrier est affiché en état clos et omis en état absent ; le bouton du CTA final ouvre le même e-mail.
- **FR-021**: La page MUST NOT créer de formulaire de candidature ni modifier la page de détail d'un appel (`/actualites/appels/[slug]`) ; ses composants partagés ne changent de rendu que par ajout de variantes optionnelles.

**Section 5 — PÉPITE France et CTA final**

- **FR-022**: Sous la FAQ, la page MUST afficher « Pour aller plus loin : » suivi du lien « Réseau PÉPITE France » (texte et adresse éditoriaux, nouvel onglet sécurisé) ; adresse vide ou invalide → ligne masquée.
- **FR-023**: Le CTA final MUST afficher titre, texte, bouton (cible selon l'état de l'appel, FR-018 / FR-020) et l'adresse e-mail du pôle en lien `mailto:`, avec le rappel éditorial « mettre votre Directeur de département en copie » ; il réutilise le bandeau CTA du pôle.

**Contenu éditorial, FAQ initiale et migration**

- **FR-024**: Les clés éditoriales `entrepreneurship.see.*` nécessaires (hero, intro, encadré, cartes SEE 1 / SEE 2, surtitre / titre et six leviers {icône, titre, texte}, section candidature, conditions, critères du jury, pièces du dossier, note « directeur en copie », message « appel clos », surtitre / titre de FAQ, lien PÉPITE France, CTA final) MUST être déclarées dans la section éditoriale existante `entrepreneurship-see` (qui conserve ses 4 clés actuelles) **et** seedées avec les textes de la maquette / du cahier des charges. La liste exacte et le décompte sont fixés au plan et soumis avec le SQL.
- **FR-025**: Une migration rejouable `049_pei_see_page.sql` et son script de retour arrière MUST : insérer les clés éditoriales ; insérer les quatre catégories FAQ `see-general` (« Généralités »), `see-avantages` (« Avantages et aménagements »), `see-engagement` (« Engagement et risques »), `see-confidentialite` (« Confidentialité »), actives, avec libellés anglais et arabes ; insérer en français (réponse Markdown et HTML) les huit questions de la maquette réparties en quatre groupes — Généralités : « Le statut est-il payant ? », « Dois-je déjà avoir créé mon entreprise ? », « Est-ce que je peux postuler en groupe ? » ; Avantages et aménagements : « Ai-je droit à des aménagements académiques grâce au SEE ? », « Puis-je remplacer mon stage par mon projet ? » ; Engagement et risques : « Que se passe-t-il si j'échoue dans mes études ou mon projet ? », « Combien de temps le statut est-il valable ? » ; Confidentialité : « Mon idée sera-t-elle protégée ? » ; le tout sans écraser une valeur existante (insertion ignorée en cas de conflit sur la clé, le code ou l'adresse de l'entrée), sans modification de structure. Le rollback retire exactement ce qui a été ajouté (entrées puis catégories puis clés). Le SQL MUST être soumis à accord avant tout code.
- **FR-026**: Parmi les entrées seedées, seules les deux dont la maquette donne la réponse MUST être publiées (« Le statut est-il payant ? » : « Non, l'obtention du statut est gratuite pour les étudiants en cours de cursus. » ; « Ai-je droit à des aménagements académiques grâce au SEE ? » : « Oui : 10 h de temps libéré sur vos temps de cours et 4 crédits universitaires, sous condition de validation des évaluations du parcours. ») ; les six autres MUST être seedées non publiées, avec une réponse provisoire explicite (« Réponse à rédiger par le Pôle Entrepreneuriat et Innovation. ») que l'équipe remplace avant publication. La 9ᵉ question du cahier des charges (texte indisponible) est créée par l'équipe dans le backoffice ; aucun intitulé n'est inventé. Aucune réponse provisoire ne MUST être visible publiquement (ni sur la page SEE, ni sur `/faq`, ni dans les données structurées).
- **FR-027**: Les entrées FAQ seedées MUST pouvoir recevoir leurs traductions anglaises et arabes sans ressaisie par l'équipe (traduction automatique existante des entrées FAQ, déclenchée par une action de backoffice), et, en attendant, s'afficher en français (repli).

**Internationalisation, référencement, responsive, non-régression**

- **FR-028**: Les libellés fixes MUST exister en FR / EN / AR dans l'espace de traduction du pôle ; en arabe, la page MUST se rendre en sens droite-à-gauche.
- **FR-029**: La page MUST déclarer titre, description et balises de partage (titre, description, image, adresse, langue, langues alternatives) après résolution de sa route (contrainte connue du site), et exposer les données structurées de l'organisation du pôle, de la page, du fil d'Ariane et de FAQ (FR-016) ; elle MUST figurer dans le plan du site dans les trois langues.
- **FR-030**: La page MUST fonctionner à 390 px (une colonne, sous-navigation défilante, agenda non collant, aucun défilement horizontal) et en mode sombre.
- **FR-031**: `/faq`, `/actualites/appels/[slug]`, `/candidatures/postuler/[slug]` et les six rubriques existantes du pôle MUST rester inchangées hors ajout des quatre catégories `see-*` et de leurs entrées publiées sur `/faq` (Q1) et hors mise en évidence du bouton de sous-navigation sur la seule page SEE.
- **FR-032**: CLAUDE.md MUST être mis à jour (nouvelle page, migration 049, filtre de la FAQ publique, convention des catégories `see-*`, nouveaux composants éventuels).

### Key Entities *(include if feature involves data)*

- **Appel SEE** (existant, Candidatures → Appels) : titre, adresse (slug), type, statut saisi (à venir / en cours / clos), publication, date d'ouverture, date limite, adresse de formulaire externe, formulaire interne activé ; listes : calendrier (étape, date de début, date de fin, description), critères d'éligibilité, pièces requises (nom, description, obligatoire) — trilingues avec repli français. Désigné par la clé éditoriale `entrepreneurship.see.call_slug`.
- **Catégorie FAQ SEE** (existante, convention nouvelle) : code réservé préfixé `see-`, libellés trilingues, actif, ordre. Quatre instances seedées.
- **Entrée FAQ SEE** (existante) : catégorie, adresse d'ancre unique, question et réponse trilingues (Markdown + HTML), publiée, ordre. Neuf instances seedées.
- **Contenu éditorial « Entrepreneuriat — SEE »** (021) : 4 clés existantes (adresse de l'appel, encart mentor) complétées des textes du guide ; e-mail du pôle `entrepreneurship.contact.email` réutilisé.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Les trois liens existants vers la page (hero et CTA de l'accueil du pôle, bouton de la sous-navigation) mènent à une page valide dans les trois langues (0 page « introuvable »).
- **SC-002**: Le contenu principal (hero, guide, agenda, FAQ, CTA) est présent dans la réponse initiale du serveur, sans exécution de script, dans les trois langues.
- **SC-003**: Pour chacun des sept cas d'appel (ouvert interne, ouvert externe, ouvert sans formulaire, à venir, clos, en cours date dépassée, absent — clé vide / introuvable / non publié / erreur), la page répond avec succès, affiche l'état prévu, et 0 bouton ne mène à un formulaire fermé ou inexistant.
- **SC-004**: Une modification de date d'appel, de question FAQ ou de texte éditorial en backoffice est visible sur la page au plus une minute après, sans redéploiement.
- **SC-005**: Les données structurées « FAQPage » et fil d'Ariane de la page sont valides dans un validateur et listent 100 % des questions SEE publiées, 0 question hors SEE.
- **SC-006**: Un candidat trouve le bouton « Postuler » (ou le contact si l'appel est fermé) sans défiler au-delà de la section « Suis-je le bon candidat ? » sur écran large, grâce au panneau collant.
- **SC-007**: `/faq` et `/actualites/appels/[slug]` : aucune différence visuelle ou fonctionnelle hors l'apparition des groupes SEE publiés sur `/faq` (captures avant / après à 1440 px et 390 px) ; la lecture publique de la FAQ sans filtre conserve sa forme et ses règles, et 0 réponse provisoire (entrée non publiée) n'est visible.
- **SC-008**: Dans les trois langues, 0 clé technique et 0 libellé fixe non traduit visible ; en arabe, sens droite-à-gauche sur 100 % des blocs ; à 390 px, 0 défilement horizontal ; Lighthouse mobile ≥ 90 en accessibilité et performance comparable aux rubriques existantes du pôle.
- **SC-009**: La migration 049 s'exécute deux fois de suite sans erreur en local puis en production ; les comptes de clés, catégories et entrées sont identiques après le second passage ; une valeur modifiée entre les deux passages est conservée ; le rollback retire exactement les éléments ajoutés.
- **SC-010**: Chaque texte visible du guide est modifiable dans la page « Valeurs » (100 % des textes hors libellés fixes, appel et FAQ).

## Assumptions

- **Règle d'état de l'appel** : on reprend la règle de la page de candidature du site (ouvert = statut « en cours » et date limite non dépassée) plutôt que celle du bouton de la page de détail d'un appel, qui ignore le formulaire interne désactivé. La correction de ce défaut sur la page de détail est **hors périmètre** (signalée) ; de même, un défaut de rechargement de la page de détail lors d'un changement d'adresse sans rechargement complet est signalé mais non corrigé ici.
- **Statut non recalculé** : aucune tâche planifiée ni ouverture automatique n'est ajoutée ; l'équipe fait passer l'appel « à venir » → « en cours » dans le backoffice.
- **Pas de nouvelle permission, pas de nouvelle table ni colonne** : filtre de lecture publique uniquement côté FAQ ; aucune modification de la lecture publique des appels.
- **Traduction des catégories FAQ** : aucune traduction automatique n'existe pour les libellés de catégorie ; la migration fournit directement les quatre libellés en anglais et en arabe (courts). Les entrées sont seedées en français ; la traduction automatique des entrées FAQ du site s'applique lors d'un enregistrement en backoffice, et le plan choisit l'action la plus simple pour traduire les entrées `see-*` en une fois (par exemple extension de « Traduire les champs manquants » du pôle aux entrées `see-*`).
- **Texte du hero** : badge « Statut Étudiant-Entrepreneur », titre « Entreprendre et étudier à Senghor », sous-titre de la maquette ; image vide (mode motif).
- **Rappel « directeur de département en copie »** : placé sous le bouton de l'agenda (maquette) et repris dans le CTA final (description) à partir de la même clé éditoriale.
- **Accordéon FAQ** : l'accordéon de `/faq` est réutilisé via une variante sans recherche ni filtre, avec intitulés de groupe toujours affichés ; l'ouverture multiple et les ancres existent déjà.
- **Icônes des leviers** : nom de classe Font Awesome saisi en texte dans la page « Valeurs » (valeurs initiales choisies d'après les icônes de la maquette : bulle, fusée, toque, horloge, pièce, immeuble).
- **Critères du jury** : sans pondération (la maquette n'en affiche pas).
- **Sous-navigation** : aucun septième onglet n'est ajouté (maquette) ; la mise en évidence repose sur le bouton existant.
- **Cache** : lectures publiques mises en cache une minute (convention FAQ et pôle).
- **Menu principal, organigramme, création de l'appel SEE 2026 et sélection des candidatures** : hors périmètre (feature 026 et équipe du pôle).

## Dependencies

- Feature 021 : section éditoriale `entrepreneurship-see`, clés `see.call_slug`, `contact.email`, `dde_service_id`.
- Features 023 / 024 : hero étendu (badge, mode motif), sous-navigation, cadre de rubrique partagé (fil d'Ariane, SEO, données structurées), bandeau CTA, état vide, libellés `pei.*`.
- Feature 019 : backoffice FAQ (catégories, entrées, publication, traduction des entrées), page `/faq`, accordéon, données structurées « FAQPage ».
- Module Candidatures : appels publiés, calendrier, critères, pièces, formulaire interne ou externe, page de candidature du site.
- Maquettes `specs/maquettes-pei/statut-etudiant-entrepreneur.{png,html}` et `README.md`.
- Cahier des charges « Page EI », pages 4 à 7 (non présent dans le dépôt ; décision Q2, voir FR-026).
