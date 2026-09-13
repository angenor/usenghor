# Feature Specification: Socle du Pôle Entrepreneuriat et Innovation (PEI) — données, API et backoffice

**Feature Branch**: `021-pei-entrepreneurship-core`

**Created**: 2026-09-13

**Status**: Draft

**Input**: User description: "Créer le socle backend et backoffice du « Pôle Entrepreneuriat et Innovation (PEI) », pôle du service « Direction du Développement et de l'Entrepreneuriat (DDE) » (secteur Rectorat), qui alimentera un futur mini-site public « Entreprendre à Senghor ». Cette feature ne crée AUCUNE page publique. [...] Périmètre : base de données (pei_cohorts, pei_programs, pei_resources), permissions, API admin et publique, backoffice (tableau de bord + 3 pages CRUD), page éditoriale « entrepreneurship », données initiales (5 dispositifs, 3 cohortes FSE). Hors périmètre : pages publiques, lauréats, partenaires, rattachement à l'organigramme, menu."

**Références** : `specs/roadmap-pei-entrepreneuriat.md` (sections 1, 2 et prompt 021), `specs/maquettes-pei/README.md`, `specs/maquettes-pei/arborescence.png` (rubriques et source de données), `accueil.html` (champs d'un dispositif, chiffres clés, citation, CTA), `alumni.html` (champs d'une cohorte), `statut-etudiant-entrepreneur.html` (clé de l'appel SEE, contact).

## Contexte

Le Pôle Entrepreneuriat et Innovation (PEI) est un pôle du service « Direction du Développement et de l'Entrepreneuriat (DDE) », lui-même rattaché au secteur Rectorat. La hiérarchie organisationnelle du site ne connaît que deux niveaux (secteur → service) et les onglets génériques d'un service (présentation, missions, équipe, réalisations, projets, actualités, médias) ne peuvent pas accueillir le contenu structuré du pôle : un parcours en cinq dispositifs, des cohortes de lauréats, une boîte à outils et des chiffres clés.

Cette feature pose le **socle** : les données propres au pôle, leur gestion en backoffice et leur exposition en lecture publique, pour qu'un futur mini-site public « Entreprendre à Senghor » (features 023 à 026) puisse s'en nourrir. Les données déjà gérées ailleurs (actualités et événements de la DDE, albums de la DDE, FAQ, appels à candidatures, partenaires) ne sont **pas** dupliquées : le backoffice du pôle y renvoie.

## Clarifications

### Session 2026-09-13

- Q: Comment les traductions EN/AR des 5 dispositifs et des 3 cohortes chargés par la migration doivent-elles être générées ? → A: Option A — action admin idempotente « Traduire les champs manquants » sur le tableau de bord du pôle (permission modifier), qui remplit uniquement les champs EN/AR vides des dispositifs, cohortes et ressources ; lancée une fois après la migration, en local puis en production.
- Q: Les formulaires de création et de modification des dispositifs, cohortes et ressources doivent-ils s'ouvrir dans une page dédiée ou dans une modale ? → A: Option A — pages dédiées pour les trois types (liste + page « nouveau » + page d'édition), sur le modèle exact du backoffice FAQ.
- Q: Comment le tableau de bord (et plus tard le mini-site) identifie-t-il le service DDE pour les raccourcis « actualités, événements, albums de la DDE » ? → A: Option A — clé éditoriale `entrepreneurship.dde_service_id` dans la page « Entrepreneuriat », prérenseignée par la migration à partir du nom du service (« Développement et de l'Entrepreneuriat ») quand il existe, sinon laissée vide ; le tableau de bord signale une clé vide. *(Précision de planification 2026-09-13 : la table des services n'a pas de slug ; la clé stocke l'identifiant du service, d'où le nom `dde_service_id` au lieu de `dde_service_slug`.)*
- Q: Que fait la suppression d'un dispositif, d'une cohorte ou d'une ressource en backoffice ? → A: Option A — suppression définitive après confirmation, réservée à la permission « supprimer » ; une cohorte à laquelle des lauréats sont rattachés (feature 022) ne pourra pas être supprimée tant qu'ils existent ; la désactivation reste le moyen recommandé de retirer un élément du public.
- Q: Comment l'éditeur choisit-il la couleur d'un dispositif ? → A: Option A — liste fermée de couleurs nommées de la charte (bleu, bleu foncé, rouge, ambre, turquoise), stockées par leur nom ; le rendu clair / sombre est défini une fois par le site ; extension possible en ajoutant un nom.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Gérer les dispositifs du parcours entrepreneurial (Priority: P1)

Un éditeur de contenu disposant des droits « entrepreneuriat » ouvre la section « Entrepreneuriat (PEI) » du backoffice, page « Dispositifs du parcours ». Il voit les cinq dispositifs préchargés (Parcours OSER, Statut Étudiant-Entrepreneur, Mature Ton Idée, Senghor'Innov, Fonds de Soutien à l'Entrepreneuriat), classés par ordre d'affichage. Il peut créer un dispositif, modifier son titre, son sigle, sa phase, son accroche, son contenu riche, son chiffre mis en avant, sa couleur et son visuel dans les trois langues (onglets FR / EN / AR), le réordonner par glisser-déposer, l'activer ou le désactiver, et le supprimer. À la sauvegarde, les champs anglais et arabes laissés vides sont remplis automatiquement à partir du français.

**Why this priority**: Les dispositifs constituent le cœur du futur mini-site (section « Nos activités » et parcours de l'accueil). C'est le critère d'acceptation explicite de la demande : créer, modifier, réordonner et désactiver un dispositif dans les trois langues.

**Independent Test**: Se connecter avec un compte éditeur, ouvrir `/admin/entrepreneuriat/dispositifs`, créer un sixième dispositif en français uniquement, vérifier que ses versions EN et AR sont générées, le déplacer en deuxième position, le désactiver, puis vérifier que l'interface publique de lecture ne le renvoie plus.

**Acceptance Scenarios**:

1. **Given** un éditeur avec la permission de création, **When** il enregistre un nouveau dispositif avec uniquement les champs français renseignés (titre, phase, accroche, contenu riche, chiffre mis en avant), **Then** le dispositif apparaît dans la liste, ses champs anglais et arabes sont remplis automatiquement, et l'onglet AR affiche le contenu en sens de lecture droite-à-gauche.
2. **Given** un dispositif existant dont le titre anglais a été saisi manuellement, **When** l'éditeur modifie le titre français, **Then** le titre anglais saisi manuellement est conservé et seuls les champs EN/AR vides sont recalculés.
3. **Given** cinq dispositifs classés 1 à 5, **When** l'éditeur glisse le dispositif n° 5 en position 2, **Then** l'ordre 1, 5, 2, 3, 4 est enregistré immédiatement et persiste après rechargement de la page.
4. **Given** un dispositif actif, **When** l'éditeur le désactive depuis la liste, **Then** il reste visible dans la liste admin avec un état « inactif » et n'est plus renvoyé par la lecture publique.
5. **Given** un utilisateur connecté sans la permission « entrepreneuriat », **When** il tente d'ouvrir la page des dispositifs ou d'appeler l'interface d'écriture, **Then** l'accès est refusé et la section n'apparaît pas dans sa barre latérale.
6. **Given** un dispositif, **When** l'éditeur choisit un visuel de couverture, **Then** il le sélectionne dans la médiathèque existante (pas de nouvel outil de téléversement) et l'aperçu s'affiche dans le formulaire.

---

### User Story 2 - Gérer les cohortes de lauréats (Priority: P2)

L'éditeur ouvre la page « Cohortes ». Il voit les trois cohortes FSE préchargées (FSE 1 · Lancement 2023, FSE 2 · Consolidation, FSE 3 · Promotion 2025). Il peut créer une cohorte (libellé trilingue, code, année, type FSE ou SEE, focus trilingue, bilan riche trilingue), la modifier, la réordonner, l'activer ou la désactiver et la supprimer. Les cohortes serviront à regrouper les lauréats ajoutés dans la feature suivante.

**Why this priority**: Les cohortes sont un prérequis structurel des lauréats (feature 022) et alimentent le bandeau « Nos alumni ». Elles sont simples et indépendantes des dispositifs.

**Independent Test**: Ouvrir `/admin/entrepreneuriat/cohortes`, créer une cohorte « SEE 2026 » de type SEE, vérifier la traduction automatique du libellé et du focus, la désactiver, et vérifier qu'elle disparaît de la lecture publique tout en restant listée en admin.

**Acceptance Scenarios**:

1. **Given** la page « Cohortes », **When** l'éditeur crée une cohorte avec un code déjà utilisé, **Then** un message d'erreur explicite indique le doublon et rien n'est enregistré.
2. **Given** trois cohortes actives et une inactive, **When** un consommateur anonyme lit la liste publique des cohortes, **Then** il obtient exactement les trois cohortes actives, dans l'ordre d'affichage défini en admin.
3. **Given** une cohorte, **When** l'éditeur renseigne le bilan en éditeur de texte riche, **Then** le bilan est conservé à la fois en version affichable et en version éditable, et l'ouverture ultérieure du formulaire restitue fidèlement la mise en forme.

---

### User Story 3 - Gérer la boîte à outils (ressources) (Priority: P2)

L'éditeur ouvre la page « Ressources » (boîte à outils). Il crée une ressource avec un titre et une description trilingues, un type (document, lien ou vidéo), soit un document choisi dans la médiathèque, soit une adresse web, une catégorie trilingue, un ordre et un état publié / non publié. Il peut filtrer la liste par type, par catégorie et par état de publication.

**Why this priority**: La boîte à outils alimentera la rubrique « Nos ressources » du mini-site. Elle est indépendante des dispositifs et des cohortes.

**Independent Test**: Ouvrir `/admin/entrepreneuriat/ressources`, créer une ressource de type « document » liée à un fichier de la médiathèque et une ressource de type « lien » avec une URL, publier la première seulement, puis vérifier que la lecture publique renvoie uniquement la première avec l'adresse de téléchargement du document.

**Acceptance Scenarios**:

1. **Given** le formulaire de ressource, **When** l'éditeur choisit le type « document » sans sélectionner de fichier, ou le type « lien » / « vidéo » sans saisir d'URL, **Then** l'enregistrement est refusé avec un message indiquant le champ manquant.
2. **Given** une ressource de type « lien » avec une URL mal formée, **When** l'éditeur enregistre, **Then** l'enregistrement est refusé avec un message explicite.
3. **Given** dix ressources dont quatre de catégorie « Financement », **When** l'éditeur filtre par cette catégorie, **Then** seules les quatre ressources correspondantes restent affichées.
4. **Given** une ressource non publiée, **When** un consommateur anonyme lit la liste publique des ressources, **Then** cette ressource est absente de la réponse.

---

### User Story 4 - Tableau de bord du pôle et raccourcis vers les rubriques gérées ailleurs (Priority: P3)

L'éditeur ouvre `/admin/entrepreneuriat`. Il voit des compteurs (dispositifs actifs / total, cohortes actives / total, ressources publiées / total), des raccourcis vers les trois pages CRUD du pôle, et un bloc « Géré ailleurs » avec des liens directs vers : les actualités liées à la DDE, les événements liés à la DDE, les albums de la DDE, la FAQ, les appels à candidatures et la page éditoriale « Entrepreneuriat ». Chaque raccourci rappelle en une phrase la convention à respecter (par exemple « rattacher l'actualité au service DDE »). Le tableau de bord porte aussi l'action « Traduire les champs manquants », qui complète en anglais et en arabe les éléments dont la traduction est vide (données initiales, ou écritures faites pendant une panne du service de traduction).

**Why this priority**: Le tableau de bord évite aux éditeurs de chercher où gérer chaque rubrique du futur mini-site, mais il n'est pas indispensable pour produire les données.

**Independent Test**: Ouvrir le tableau de bord avec les données initiales, vérifier les compteurs (5 dispositifs actifs, 3 cohortes actives, 0 ressource), cliquer sur chaque raccourci et vérifier qu'il mène à la page admin existante attendue, puis lancer « Traduire les champs manquants » deux fois et vérifier que seul le premier lancement complète des éléments.

**Acceptance Scenarios**:

1. **Given** les données initiales chargées, **When** l'éditeur ouvre le tableau de bord, **Then** les compteurs affichent 5 dispositifs actifs, 3 cohortes actives et 0 ressource publiée.
2. **Given** la clé `entrepreneurship.dde_service_id` renseignée, **When** l'éditeur clique sur « Actualités de la DDE », **Then** il arrive sur la liste des actualités du backoffice existant, ciblée sur le service DDE.
2b. **Given** la clé `entrepreneurship.dde_service_id` vide, **When** l'éditeur ouvre le tableau de bord, **Then** un avertissement l'invite à renseigner le service DDE dans la page « Entrepreneuriat », et les raccourcis ouvrent les listes complètes.
3. **Given** l'éditeur désactive un dispositif, **When** il revient sur le tableau de bord, **Then** le compteur « dispositifs actifs » passe de 5 à 4.
4. **Given** les données initiales chargées en français seul, **When** un éditeur avec la permission « modifier » lance « Traduire les champs manquants », **Then** les champs EN / AR vides des 5 dispositifs et 3 cohortes sont remplis, le nombre d'éléments complétés est affiché, une entrée d'audit est créée, et un second lancement ne modifie rien (0 élément complété).
5. **Given** un dispositif dont le titre anglais a été corrigé à la main, **When** l'action « Traduire les champs manquants » est lancée, **Then** le titre anglais corrigé est conservé.

---

### User Story 5 - Éditer les textes et chiffres clés de la page « Entrepreneuriat » (Priority: P3)

L'éditeur ouvre la page « Valeurs » (éditeur de pages éditoriales existant) et y trouve une nouvelle page front-office « Entrepreneuriat ». Il peut y modifier le slogan, le sous-titre, les images du slider, la présentation riche, la citation avec son auteur et sa fonction, le texte d'impact, les quatre chiffres clés (valeur et libellé), les textes des boutons d'appel à l'action, l'adresse e-mail de contact, le slug de l'appel à candidatures SEE en cours et l'identifiant du service DDE. Ces clés sont préremplies avec les textes du cahier des charges.

**Why this priority**: La copie de page est nécessaire au futur mini-site mais s'appuie entièrement sur un outil existant ; aucun nouvel écran n'est créé.

**Independent Test**: Ouvrir la page « Valeurs », sélectionner « Entrepreneuriat », vérifier que toutes les clés sont présentes avec leurs valeurs initiales (slogan « INNOVER. AGIR. TRANSFORMER. », e-mail `entrepreneuriat@usenghor.org`, chiffres « 3 ans d'existence », « 3 événements internationaux », « 12 lauréats du FSE », « 500+ étudiants et alumni formés »), modifier un chiffre clé et vérifier sa persistance.

**Acceptance Scenarios**:

1. **Given** la migration jouée, **When** l'éditeur ouvre la page « Entrepreneuriat » dans l'éditeur éditorial, **Then** chaque section (hero, présentation, chiffres clés, citation, impact, appels à l'action, contact, statut étudiant-entrepreneur) affiche ses clés avec les valeurs du cahier des charges.
2. **Given** la clé du slug de l'appel SEE, **When** l'éditeur la remplace par le slug d'un appel existant, **Then** la valeur est enregistrée et sera lue par la future page « Entreprendre et étudier ».
3. **Given** la migration déjà jouée une première fois, **When** elle est rejouée, **Then** les valeurs modifiées par l'éditeur entre-temps ne sont pas écrasées.

---

### User Story 6 - Lecture publique des données actives (Priority: P2)

Un consommateur anonyme (le futur mini-site, ou tout client de l'interface publique) lit la liste des dispositifs, des cohortes et des ressources. Il n'obtient que les éléments actifs / publiés, triés par ordre d'affichage, avec les trois langues renseignées, et peut lire un dispositif ou une cohorte individuellement par son code.

**Why this priority**: Sans lecture publique, le socle ne peut pas alimenter le mini-site ; mais cette lecture n'a de valeur que si les données existent (P1/P2).

**Independent Test**: Sans être connecté, lire les trois listes publiques et vérifier qu'elles ne contiennent que les éléments actifs, puis lire un dispositif par son code et vérifier qu'un code inactif ou inconnu renvoie « introuvable ».

**Acceptance Scenarios**:

1. **Given** cinq dispositifs actifs et un inactif, **When** un client anonyme lit la liste publique des dispositifs, **Then** il obtient cinq éléments dans l'ordre d'affichage admin, chacun avec son titre, sa phase, son accroche, son contenu riche affichable, son chiffre mis en avant, sa couleur et l'adresse de son visuel.
2. **Given** un dispositif inactif, **When** un client anonyme le lit par son code, **Then** il obtient une réponse « introuvable » et aucune information sur le dispositif.
3. **Given** une écriture par l'interface publique, **When** un client tente de créer ou modifier un élément via l'interface publique, **Then** l'opération est impossible (aucun point d'écriture public n'existe).

---

### Edge Cases

- **Traduction automatique indisponible** : si le service de traduction échoue ou expire, l'enregistrement en français aboutit quand même, les champs EN/AR restent vides et le repli FR s'applique silencieusement à la lecture ; l'éditeur peut ressaisir ou relancer plus tard.
- **Suppression d'une cohorte** : définitive après confirmation ; dans cette feature une cohorte n'a pas encore de lauréats. La feature 022 rendra la suppression impossible tant que des lauréats y sont rattachés (refus explicite, pas de cascade) ; la désactivation reste le moyen recommandé de retirer une cohorte du public.
- **Média supprimé de la médiathèque** : un dispositif ou une ressource dont le visuel ou le document a été supprimé reste éditable ; la lecture publique renvoie l'élément sans adresse de média.
- **Réordonnancement concurrent** : si deux éditeurs réordonnent en même temps, le dernier enregistrement l'emporte ; les positions sont renumérotées de façon contiguë à chaque réordonnancement.
- **Code de dispositif ou de cohorte** : unique, stable, en minuscules sans accents ; sa modification est possible en admin mais signalée comme impactant les futures adresses publiques.
- **Couleur d'un dispositif** : valeur choisie parmi une liste fermée de cinq couleurs nommées (bleu, bleu foncé, rouge, ambre, turquoise), stockée par son nom ; toute valeur hors liste est refusée à l'enregistrement. Le rendu clair / sombre de chaque nom est défini une fois par le site.
- **Rejeu de migration** : la migration doit pouvoir être exécutée plusieurs fois sans erreur ni doublon (tables, types, permissions, données initiales, clés éditoriales), en local comme en production ; le script de retour arrière supprime uniquement ce que la migration a créé.
- **Éditeur sans droit de suppression** : les boutons de suppression sont masqués ou désactivés, et toute tentative directe est refusée.

## Requirements *(mandatory)*

### Functional Requirements

**Données du pôle**

- **FR-001**: Le système MUST stocker les **dispositifs** du parcours avec : code unique, sigle, titre trilingue, phase (sensibilisation, cadre / statut, pré-incubation, incubation, amorçage, écosystème), accroche trilingue, contenu riche trilingue (version affichable + version éditable), chiffre mis en avant trilingue, couleur choisie dans une liste fermée de cinq couleurs nommées de la charte (bleu, bleu foncé, rouge, ambre, turquoise), visuel de couverture (référence médiathèque), ordre d'affichage, état actif, horodatages de création et de modification.
- **FR-002**: Le système MUST stocker les **cohortes** avec : code unique, libellé trilingue, année, type (FSE ou SEE), focus trilingue, bilan riche trilingue (affichable + éditable), ordre d'affichage, état actif, horodatages.
- **FR-003**: Le système MUST stocker les **ressources** de la boîte à outils avec : titre trilingue, description trilingue, type (document, lien, vidéo), référence à un document de la médiathèque ou adresse web, catégorie trilingue, ordre d'affichage, état publié, horodatages.
- **FR-004**: Le modèle de référence MUST être documenté dans un nouveau fichier de schéma dédié au pôle, inclus dans l'orchestrateur du schéma, et livré avec une migration rejouable accompagnée de son script de retour arrière. Les fichiers créés MUST porter des noms sans accents ni caractères spéciaux.
- **FR-005**: Le SQL du modèle MUST être soumis à l'accord du responsable du projet avant toute écriture de code applicatif.

**Permissions et sécurité**

- **FR-006**: Le système MUST définir quatre permissions « entrepreneuriat » (voir, créer, modifier, supprimer), créées par la migration et attribuées aux rôles « super administrateur » et « éditeur » sans doublon au rejeu.
- **FR-007**: Chaque opération d'écriture MUST exiger la permission correspondante ; la consultation admin MUST exiger la permission « voir ». Aucune vérification de permission ne MUST référencer un code absent de la base.
- **FR-008**: La section « Entrepreneuriat (PEI) » de la barre latérale admin MUST n'être visible qu'aux utilisateurs disposant de la permission « voir ».

**Gestion admin (dispositifs, cohortes, ressources)**

- **FR-009**: Les éditeurs autorisés MUST pouvoir créer, lire, modifier, supprimer, réordonner et activer / désactiver (ou publier / dépublier) chaque type d'élément depuis le backoffice.
- **FR-010**: Chaque type d'élément MUST disposer d'une page de liste, d'une page de création et d'une page d'édition dédiées (pas de modale), sur le modèle du backoffice FAQ. Chaque formulaire MUST proposer les trois langues sous forme d'onglets FR / EN / AR, avec sens de lecture droite-à-gauche pour l'arabe, et le contenu riche MUST être édité avec l'éditeur de texte riche existant en mode modal (afin que les onglets de langue restent accessibles).
- **FR-011**: À la création et à la modification, les champs anglais et arabes vides MUST être remplis automatiquement à partir du français ; les valeurs saisies manuellement MUST être conservées.
- **FR-012**: Le réordonnancement MUST se faire par glisser-déposer dans la liste, être enregistré immédiatement et renuméroter les positions de façon contiguë.
- **FR-013**: Les visuels et documents MUST être choisis via le sélecteur de médiathèque existant ; aucun nouvel outil de téléversement ne MUST être créé.
- **FR-014**: Les listes admin MUST proposer une recherche textuelle sur le titre français et des filtres (par phase et état pour les dispositifs ; par type et état pour les cohortes ; par type, catégorie et état de publication pour les ressources).
- **FR-015**: Le système MUST refuser un code de dispositif ou de cohorte déjà utilisé et une ressource incohérente (document sans fichier, lien ou vidéo sans URL, URL mal formée), avec un message d'erreur explicite.
- **FR-015b**: La suppression MUST être définitive, précédée d'une confirmation explicite et réservée à la permission « supprimer » ; les boutons de suppression MUST être masqués aux éditeurs qui n'ont pas cette permission. Le contrat de suppression d'une cohorte MUST prévoir un refus explicite (message « cohorte utilisée par N lauréats ») dès qu'un lauréat y sera rattaché (feature 022) ; dans cette feature, aucune cohorte n'ayant de lauréat, la suppression aboutit toujours.
- **FR-016**: Chaque création, modification, suppression, réordonnancement et changement d'état MUST être tracé dans le journal d'audit existant, avec l'auteur, l'action, l'entité et l'horodatage.

**Tableau de bord**

- **FR-017**: Le tableau de bord du pôle MUST afficher les compteurs actifs / total (dispositifs, cohortes) et publiées / total (ressources), des raccourcis vers les trois pages de gestion, et des liens vers les rubriques gérées ailleurs : actualités DDE, événements DDE, albums DDE, FAQ, appels à candidatures, page éditoriale « Entrepreneuriat », chacun accompagné d'un rappel de la convention à respecter, ainsi que l'action « Traduire les champs manquants » (FR-024).
- **FR-017b**: Le service DDE MUST être identifié par la clé éditoriale `entrepreneurship.dde_service_id` (page « Entrepreneuriat »). Les raccourcis « actualités DDE », « événements DDE » et « albums DDE » MUST utiliser cette clé pour cibler le service ; si la clé est vide, le tableau de bord MUST afficher un avertissement invitant à la renseigner et ouvrir les listes non filtrées.

**Lecture publique**

- **FR-018**: Le système MUST exposer une lecture publique, sans authentification, des dispositifs, cohortes et ressources, ne renvoyant que les éléments actifs / publiés, triés par ordre d'affichage, avec l'ensemble des champs trilingues et l'adresse de téléchargement des médias référencés.
- **FR-019**: Le système MUST permettre la lecture publique d'un dispositif ou d'une cohorte par son code ; un code inconnu ou inactif MUST renvoyer « introuvable ».
- **FR-020**: L'interface publique MUST être strictement en lecture seule.

**Page éditoriale**

- **FR-021**: Le système MUST ajouter une page front-office « Entrepreneuriat » (adresse `/entrepreneuriat`) à la configuration des pages éditoriales, éditable dans la page « Valeurs » existante, avec les sections et clés suivantes : slogan, sous-titre, images du slider, présentation riche, citation + auteur + fonction, texte d'impact, quatre chiffres clés (valeur + libellé), textes des appels à l'action, e-mail de contact, slug de l'appel SEE en cours, identifiant du service DDE (`entrepreneurship.dde_service_id`).
- **FR-022**: Les clés éditoriales MUST être préremplies en français par la migration avec les textes du cahier des charges (slogan « INNOVER. AGIR. TRANSFORMER. », e-mail `entrepreneuriat@usenghor.org`, chiffres clés « 3 ans d'existence », « 3 événements internationaux », « 12 lauréats du FSE », « 500+ étudiants et alumni formés », citation de Gaël Gbonsou, Directeur du Développement et de l'Entrepreneuriat), sans écraser une valeur déjà modifiée au rejeu. La clé `entrepreneurship.dde_service_id` MUST être prérenseignée avec l'identifiant du service dont le nom contient « Développement et de l'Entrepreneuriat » s'il existe dans la base cible, sinon laissée vide.

**Données initiales**

- **FR-023**: La migration MUST charger en français, sans doublon au rejeu, les cinq dispositifs (1 · Sensibilisation · Parcours OSER ; 2 · Cadre · Statut Étudiant-Entrepreneur ; 3 · Pré-incubation · Mature Ton Idée, chiffre « 4 crédits » ; 4 · Incubation · Senghor'Innov ; 5 · Amorçage · Fonds de Soutien à l'Entrepreneuriat, chiffre « 5 000 € » ; couleurs respectives turquoise, bleu foncé, bleu, rouge, ambre) et les trois cohortes FSE (FSE 1 · Lancement 2023 · preuve de concept ; FSE 2 · Consolidation · dimension intrapreneuriale ; FSE 3 · Promotion 2025 · innovation et passage à l'échelle), à partir des textes du cahier des charges.
- **FR-024**: Le tableau de bord du pôle MUST proposer une action « Traduire les champs manquants » (permission « modifier ») qui remplit, pour les dispositifs, cohortes et ressources, uniquement les champs EN / AR vides à partir du français, sans écraser les valeurs existantes ; l'action MUST être rejouable sans effet de bord, tracée dans l'audit, et afficher le nombre d'éléments complétés. Elle est lancée une fois après la migration pour les données initiales ; en attendant, le repli FR s'applique.

**Transversal**

- **FR-025**: Avant toute création de composant d'interface, l'équipe MUST vérifier qu'un composant équivalent n'existe pas déjà et le réutiliser le cas échéant (gabarits FAQ et levées de fonds).
- **FR-026**: La lecture des champs trilingues côté interface MUST utiliser le repli français silencieux existant.
- **FR-027**: La documentation projet (CLAUDE.md) MUST être mise à jour : nouveau fichier de schéma, nouvelle section admin, nouveau composable.

### Key Entities *(include if data involved)*

- **Dispositif (pei_programs)** : une étape du parcours entrepreneurial (OSER, SEE, MTI, Senghor'Innov, FSE). Attributs : code, sigle, phase, titre / accroche / contenu riche / chiffre mis en avant trilingues, couleur (nom parmi une liste fermée), visuel, ordre, état actif. Indépendant des autres entités.
- **Cohorte (pei_cohorts)** : une promotion de lauréats ou d'étudiants-entrepreneurs (FSE 1, FSE 2, FSE 3, SEE 2026…). Attributs : code, libellé / focus / bilan trilingues, année, type (FSE / SEE), ordre, état actif. Regroupera les lauréats de la feature 022.
- **Ressource (pei_resources)** : un élément de la boîte à outils (guide, formulaire, lien utile, vidéo). Attributs : titre / description / catégorie trilingues, type (document / lien / vidéo), document de la médiathèque ou URL, ordre, état publié. Référence la médiathèque existante.
- **Permission « entrepreneuriat »** : quatre droits (voir, créer, modifier, supprimer) rattachés aux rôles existants.
- **Clés éditoriales « entrepreneurship »** : textes et chiffres de la page « Entrepreneuriat », gérés par l'outil éditorial existant.
- **Entrée d'audit** : trace de chaque écriture admin (auteur, action, entité, horodatage), dans le journal existant.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Un éditeur autorisé crée un dispositif complet (français, contenu riche, visuel) en moins de 5 minutes, et ses versions anglaise et arabe sont disponibles sans saisie supplémentaire.
- **SC-002**: 100 % des écritures admin (création, modification, suppression, réordonnancement, changement d'état) sur les trois types d'éléments produisent une entrée dans le journal d'audit.
- **SC-003**: 100 % des éléments inactifs ou non publiés sont absents des réponses publiques ; 100 % des éléments actifs y figurent dans l'ordre défini en admin.
- **SC-004**: Un utilisateur sans permission « entrepreneuriat » ne voit pas la section dans sa barre latérale et obtient un refus sur 100 % des tentatives d'accès direct.
- **SC-005**: La migration s'exécute deux fois de suite sans erreur en local et en production, et le nombre de dispositifs, cohortes, permissions et clés éditoriales est identique après le second passage.
- **SC-006**: Après migration, le tableau de bord affiche 5 dispositifs actifs, 3 cohortes actives et 0 ressource, et chacun des raccourcis « géré ailleurs » mène à une page admin existante (aucun lien mort).
- **SC-007**: Les listes publiques répondent en moins d'une seconde pour 100 éléments par type.
- **SC-008**: Un réordonnancement par glisser-déposer est visible après rechargement de page dans 100 % des cas.

## Assumptions

- **Rôle éditeur de contenu** : le rôle `editor` (« Éditeur ») déjà présent dans les rôles du site est celui qui reçoit les permissions, en plus du super administrateur.
- **Numérotation** : la migration prend le numéro 045 (dernière migration existante : 044).
- **Suppression** : définitive après confirmation, réservée à la permission « supprimer » (voir Clarifications) ; la désactivation reste le moyen recommandé de retirer un élément du public ; aucune corbeille ni archivage.
- **Mode d'édition** : pages dédiées (liste, création, édition) pour les trois types, copiées du gabarit FAQ (voir Clarifications) ; seul l'éditeur de texte riche s'ouvre en modale, depuis la page d'édition.
- **Couleur d'un dispositif** : liste fermée de cinq noms (bleu, bleu foncé, rouge, ambre, turquoise), soit les cinq teintes de la maquette `accueil.html` ; données initiales : OSER turquoise, SEE bleu foncé, MTI bleu, Senghor'Innov rouge, FSE ambre (voir Clarifications).
- **Cohorte FSE 2** : le cahier des charges ne donne pas d'année ; la valeur initiale est 2024 (entre 2023 et 2025) et reste modifiable en admin.
- **Codes initiaux** : dispositifs `oser`, `see`, `mti`, `senghor-innov`, `fse` ; cohortes `fse-1`, `fse-2`, `fse-3`.
- **Traduction des données initiales** : la migration SQL ne contient que le français ; les versions EN / AR sont produites par l'action admin « Traduire les champs manquants » du tableau de bord (voir Clarifications), lancée après la migration en local puis en production.
- **Filtre « service DDE » des actualités, événements et albums** : le service est identifié par la clé éditoriale `entrepreneurship.dde_service_id` (voir Clarifications). Le raccourci passe le paramètre de filtre lorsqu'il est déjà supporté par la liste cible ; sinon il ouvre la liste complète. Aucune modification des backoffices existants n'est prévue.
- **Clés éditoriales** : le champ « images du slider » réutilise le type de champ média existant de l'éditeur éditorial (jusqu'à 3 visuels) ; le slug de l'appel SEE est un texte libre validé par l'éditeur, non contrôlé contre la liste des appels dans cette feature.
- **Hors périmètre confirmé** : aucune page publique, aucune table de lauréats ni de partenaires, aucun rattachement à l'organigramme (pas de colonne parent / chemin d'atterrissage sur les services), aucune entrée de menu.

## Dependencies

- Médiathèque existante (sélecteur de média, adresses de téléchargement).
- Service de traduction automatique existant (français → anglais / arabe).
- Journal d'audit existant.
- Éditeur de pages éditoriales existant (page « Valeurs ») et son mécanisme de clés.
- Rôles et permissions existants (super administrateur, éditeur).
- Feuille de route PEI : les features 022 (lauréats, partenaires), 023-025 (mini-site public) et 026 (organigramme, navigation) s'appuient sur ce socle.
