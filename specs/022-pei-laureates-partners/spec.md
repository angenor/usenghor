# Feature Specification: Lauréats, étudiants-entrepreneurs et partenaires du pôle PEI (backoffice)

**Feature Branch**: `022-pei-laureates-partners`

**Created**: 2026-09-13

**Status**: Draft

**Input**: User description: "Ajouter au backoffice « Entrepreneuriat (PEI) » la gestion des lauréats du Fonds de Soutien à l'Entrepreneuriat (FSE), des étudiants-entrepreneurs, et des partenaires du pôle. Aucune page publique. [...] Critères d'acceptation : un éditeur publie un lauréat avec photo et verbatim dans les trois langues et le retrouve dans l'endpoint public sous sa cohorte ; un lauréat dépublié ou d'une cohorte inactive n'apparaît pas ; un partenaire supprimé ou désactivé dans le backoffice Partenaires disparaît du pôle sans erreur ; audit et permissions `entrepreneurship.*` respectés ; la migration se rejoue sans erreur ; CLAUDE.md est mis à jour."

## Contexte

La feature 021 a livré le socle du Pôle Entrepreneuriat et Innovation (PEI) : dispositifs, cohortes (FSE 1, FSE 2, FSE 3) et boîte à outils, avec leur backoffice, leurs permissions « entrepreneuriat », leur journal d'audit, leur traduction automatique et leur lecture publique. Elle a explicitement réservé deux emplacements pour cette feature : le rattachement de lauréats à une cohorte (une cohorte utilisée par des lauréats ne pourra plus être supprimée) et l'action « Traduire les champs manquants » du tableau de bord.

Cette feature ajoute au même backoffice deux rubriques prévues par la feuille de route PEI :

- **Lauréats et étudiants-entrepreneurs** : les portraits qui alimenteront la page publique « Nos alumni » (feature 024). La maquette `specs/maquettes-pei/alumni.png` fixe ce qu'une carte affiche : photo, nom, badge de cohorte, nom du projet, département, verbatim (facultatif), trois liens (site, réseau social, vidéo). Chaque cohorte est présentée avec son libellé, son sous-titre d'année et son focus, données déjà gérées par la feature 021. Un bandeau de trois chiffres (projets financés, subvention maximale, cohortes) précède les sections.
- **Partenaires du pôle** : la section « Nos partenaires » de `specs/maquettes-pei/accueil.png` présente les logos en trois familles imposées par le cahier des charges : académiques et institutionnels (Réseau Senghor, Campus France), organisations d'appui (CEF, CCI, incubateurs, accélérateurs), organisations internationales (AUF, AFD, OIF). Les partenaires eux-mêmes existent déjà dans le backoffice Partenaires ; le pôle se contente de les référencer et de les classer.

Aucune page publique n'est livrée ici : seules les lectures publiques nécessaires à la feature 024 sont exposées.

## Clarifications

### Session 2026-09-13

- Q: Un portrait doit-il obligatoirement appartenir à une cohorte, et cette cohorte doit-elle être du même type que le portrait ? → A: Option A — cohorte obligatoire et de même type que le portrait (lauréat FSE → cohorte FSE, étudiant-entrepreneur → cohorte SEE) ; le formulaire ne propose que les cohortes du type choisi et le système refuse une combinaison incohérente.
- Q: La lecture publique des partenaires du pôle doit-elle inclure des liens vers les réseaux sociaux du partenaire, sachant que le backoffice Partenaires n'en gère aucun ? → A: Option A — hors périmètre : la lecture publique renvoie nom, logo, description trilingue et site web ; aucun champ de réseau social n'est ajouté au backoffice Partenaires ni au rattachement.
- Q: L'ordre d'affichage des portraits doit-il être global ou propre à chaque cohorte ? → A: Option B — ordre par cohorte : le glisser-déposer n'est actif que lorsque la liste est filtrée sur une seule cohorte (sans recherche ni autre filtre) ; la numérotation est contiguë au sein de la cohorte ; un portrait qui change de cohorte est placé en dernière position de sa nouvelle cohorte.
- Q: Le verbatim d'un portrait doit-il être un texte simple ou un contenu riche ? → A: Option A — texte simple trilingue, limité à une citation courte (600 caractères au maximum par langue), sans mise en forme ; pas d'éditeur modal ni de double stockage.
- Q: Les trois chiffres du bandeau de la page alumni doivent-ils être calculés automatiquement ou saisis à la main ? → A: Option C — la lecture publique renvoie les chiffres calculés (portraits publiés, cohortes représentées, subvention maximale) ; aucune clé éditoriale n'est créée ici ; la feature 024 choisira entre ces chiffres et des clés éditoriales qu'elle créera si besoin.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Gérer les lauréats et étudiants-entrepreneurs (Priority: P1)

Un éditeur du pôle ouvre la rubrique « Lauréats et étudiants-entrepreneurs » de la section « Entrepreneuriat (PEI) ». Il voit la liste des portraits existants, filtrable par cohorte, par type (lauréat FSE / étudiant-entrepreneur) et par état de publication, avec une recherche sur le nom et le projet. Il crée un portrait : nom, type, cohorte, nom du projet, département, verbatim, photo choisie dans la médiathèque, liens (site, LinkedIn, Instagram, Facebook, vidéo), montant de subvention, mise en avant. Le département et le verbatim sont saisis en français sous des onglets FR / EN / AR ; les versions anglaise et arabe vides sont remplies automatiquement. Il publie le portrait, le réordonne par glisser-déposer, puis peut le dépublier, le modifier ou le supprimer.

**Why this priority**: C'est le cœur de la feature : sans portraits saisis, ni la page publique « Nos alumni » (feature 024) ni le bandeau de chiffres n'ont de contenu. Les cartes de la maquette dictent exactement les champs à couvrir.

**Independent Test**: Créer un lauréat FSE complet (photo, verbatim en français, deux liens), vérifier que ses champs anglais et arabe sont remplis, le publier, le retrouver dans la liste filtrée sur sa cohorte, le déplacer dans la liste et retrouver son nouveau rang après rechargement.

**Acceptance Scenarios**:

1. **Given** un éditeur disposant de la permission « créer », **When** il enregistre un portrait avec nom, type « lauréat FSE », cohorte « FSE 1 », projet, département et verbatim en français, **Then** le portrait est créé non publié, ses champs anglais et arabe sont renseignés automatiquement, et une entrée d'audit « création » est tracée avec son auteur.
2. **Given** un portrait existant non publié, **When** l'éditeur (permission « modifier ») active la publication, **Then** l'état passe à « publié », la date de première publication est mémorisée, et une entrée d'audit « publication » est tracée.
3. **Given** la liste filtrée sur la cohorte « FSE 1 » (six portraits, sans recherche ni autre filtre), **When** l'éditeur déplace le dernier en première position par glisser-déposer, **Then** le nouvel ordre est enregistré immédiatement, les positions de la cohorte sont renumérotées de façon contiguë sans toucher aux autres cohortes, et l'ordre est identique après rechargement de la page.
4. **Given** la liste sans filtre de cohorte, ou filtrée sur une cohorte avec en plus une recherche ou un filtre de type ou d'état, **When** l'éditeur tente de réordonner, **Then** le glisser-déposer est désactivé et un message explique qu'il faut filtrer sur une seule cohorte, sans autre filtre, pour réordonner.
9. **Given** un portrait en deuxième position de « FSE 1 », **When** l'éditeur le rattache à « FSE 2 », **Then** il prend la dernière position de « FSE 2 » et les positions de « FSE 1 » sont renumérotées de façon contiguë.
5. **Given** un portrait dont la photo est choisie dans la médiathèque, **When** l'éditeur enregistre puis rouvre le formulaire, **Then** l'aperçu de la photo est affiché et un bouton permet de la retirer ou de la remplacer.
6. **Given** un formulaire avec un lien mal formé (par exemple « linkedin » sans adresse), **When** l'éditeur enregistre, **Then** l'enregistrement est refusé avec un message explicite sur le champ fautif.
7. **Given** un éditeur sans la permission « supprimer », **When** il consulte la liste, **Then** les boutons de suppression sont masqués et toute tentative de suppression directe est refusée.
8. **Given** un portrait de type « lauréat FSE », **When** l'éditeur choisit la cohorte, **Then** seules les cohortes de type FSE sont proposées (et seules les cohortes SEE pour un étudiant-entrepreneur) ; une combinaison incohérente envoyée directement est refusée avec un message explicite.

---

### User Story 2 - Lecture publique des portraits groupés par cohorte (Priority: P1)

Le site public (feature 024) doit pouvoir lire les portraits publiés, regroupés par cohorte active dans l'ordre d'affichage des cohortes, avec pour chaque cohorte son libellé, son année, son focus et son bilan, et pour chaque portrait l'ensemble des champs de la carte dans les trois langues, la photo résolue en adresse affichable, et le type. La lecture est filtrable par type (lauréats FSE seuls, ou étudiants-entrepreneurs seuls) et renvoie les chiffres du bandeau.

**Why this priority**: C'est le critère d'acceptation principal (« retrouver le lauréat dans l'endpoint public sous sa cohorte ») et la condition d'existence de la page « Nos alumni ».

**Independent Test**: Publier deux portraits dans FSE 1 et un dans FSE 3, en laisser un non publié dans FSE 2, désactiver la cohorte FSE 3, puis lire la liste publique : seule FSE 1 apparaît avec ses deux portraits, dans l'ordre défini en admin.

**Acceptance Scenarios**:

1. **Given** un portrait publié rattaché à une cohorte active, **When** la liste publique est lue sans filtre, **Then** le portrait figure sous sa cohorte, avec nom, badge (libellé de cohorte), projet, département, verbatim, adresse de la photo, liens et indicateur « mis en avant ».
2. **Given** un portrait dépublié, **When** la liste publique est lue, **Then** il n'y figure pas.
3. **Given** un portrait publié dont la cohorte est désactivée, **When** la liste publique est lue, **Then** ni la cohorte ni le portrait n'y figurent.
4. **Given** des portraits des deux types, **When** la liste publique est lue avec le filtre « étudiants-entrepreneurs », **Then** seuls les portraits de ce type et leurs cohortes sont renvoyés.
5. **Given** une cohorte active sans aucun portrait publié, **When** la liste publique est lue, **Then** cette cohorte n'apparaît pas dans les groupes.
6. **Given** quinze portraits FSE publiés répartis sur trois cohortes actives dont le montant de subvention le plus élevé est 5 000, **When** la liste publique est lue, **Then** les chiffres renvoyés indiquent 15 projets, 3 cohortes et une subvention maximale de 5 000.
7. **Given** un portrait dont le verbatim anglais est vide, **When** la liste publique est lue, **Then** le champ anglais est renvoyé vide et le repli vers le français est laissé à l'affichage (repli FR silencieux).

---

### User Story 3 - Composer les partenaires du pôle à partir du backoffice Partenaires (Priority: P2)

Un éditeur ouvre la rubrique « Partenaires du pôle ». Il voit les partenaires déjà rattachés, groupés en trois familles fixes (académiques et institutionnels, organisations d'appui, organisations internationales), avec logo, nom, état actif / inactif et un lien vers la fiche du backoffice Partenaires. Il ajoute un partenaire en le cherchant par nom parmi les partenaires existants, lui affecte une famille, change la famille d'un partenaire déjà rattaché, réordonne les partenaires par glisser-déposer au sein d'une famille, et retire un partenaire du pôle (sans le supprimer du backoffice Partenaires). Il ne peut pas créer de partenaire ici : un lien clairement visible renvoie vers le backoffice Partenaires.

**Why this priority**: Nécessaire à la section « Nos partenaires » (features 023 et 024) mais indépendante des lauréats ; le cahier des charges impose les trois familles.

**Independent Test**: Rattacher « Campus France » à la famille « académiques et institutionnels » et « AUF » à « organisations internationales », déplacer AUF, puis retirer Campus France : la liste reflète chaque action après rechargement et le backoffice Partenaires contient toujours les deux partenaires.

**Acceptance Scenarios**:

1. **Given** un partenaire existant non rattaché, **When** l'éditeur (permission « créer ») le sélectionne par recherche et choisit une famille, **Then** il apparaît dans cette famille en dernière position et une entrée d'audit « rattachement » est tracée.
2. **Given** un partenaire déjà rattaché, **When** l'éditeur ouvre le sélecteur, **Then** ce partenaire n'est plus proposé (un partenaire appartient à une seule famille).
3. **Given** un partenaire rattaché à « organisations d'appui », **When** l'éditeur change sa famille en « organisations internationales », **Then** il est déplacé en dernière position de la nouvelle famille et l'audit trace l'ancienne et la nouvelle valeur.
4. **Given** quatre partenaires dans une même famille, **When** l'éditeur les réordonne par glisser-déposer, **Then** l'ordre est enregistré immédiatement, renuméroté de façon contiguë au sein de la famille, sans toucher aux autres familles.
5. **Given** un partenaire rattaché, **When** l'éditeur (permission « supprimer ») le retire du pôle après confirmation, **Then** il disparaît de la rubrique mais reste intact dans le backoffice Partenaires, et l'audit trace le retrait.
6. **Given** un partenaire rattaché puis désactivé dans le backoffice Partenaires, **When** l'éditeur consulte la rubrique, **Then** le partenaire y figure avec un badge « Inactif » et un rappel qu'il n'est pas visible publiquement.
7. **Given** la rubrique ouverte, **When** l'éditeur cherche à créer un partenaire, **Then** aucun formulaire de création n'existe et un lien renvoie vers le backoffice Partenaires.

---

### User Story 4 - Lecture publique des partenaires du pôle enrichis (Priority: P2)

Le site public doit lire les partenaires du pôle groupés par famille, dans l'ordre fixe des familles puis dans l'ordre défini en admin, chaque partenaire étant enrichi avec les données du backoffice Partenaires : nom, logo résolu en adresse affichable, description trilingue, site web. Les partenaires désactivés ou supprimés dans le backoffice Partenaires n'apparaissent pas, sans provoquer d'erreur.

**Why this priority**: Deuxième critère d'acceptation explicite (« un partenaire supprimé ou désactivé disparaît du pôle sans erreur »).

**Independent Test**: Rattacher trois partenaires, en désactiver un et en supprimer un autre depuis le backoffice Partenaires, puis lire la liste publique : un seul partenaire est renvoyé, dans sa famille, avec nom, logo, description et site.

**Acceptance Scenarios**:

1. **Given** deux partenaires actifs rattachés à deux familles, **When** la liste publique est lue, **Then** les trois familles sont renvoyées dans l'ordre fixe (académiques et institutionnels, organisations d'appui, organisations internationales), la famille vide avec une liste vide, chaque partenaire avec nom, adresse du logo, description dans les trois langues et site web.
2. **Given** un partenaire rattaché puis désactivé dans le backoffice Partenaires, **When** la liste publique est lue, **Then** il n'y figure pas et la réponse est valide.
3. **Given** un partenaire rattaché puis supprimé dans le backoffice Partenaires, **When** la liste publique est lue, **Then** il n'y figure pas, son rattachement a disparu automatiquement, et la réponse est valide.
4. **Given** un partenaire sans logo, **When** la liste publique est lue, **Then** l'adresse du logo est vide et la réponse est valide.

---

### User Story 5 - Tableau de bord, barre latérale et traduction des champs manquants (Priority: P3)

Le tableau de bord du pôle affiche deux compteurs supplémentaires (portraits publiés / total, partenaires rattachés / total et actifs) et deux raccourcis vers les nouvelles rubriques. La section « Entrepreneuriat (PEI) » de la barre latérale gagne deux entrées, « Lauréats et étudiants-entrepreneurs » et « Partenaires du pôle », visibles avec la permission « voir ». L'action « Traduire les champs manquants » couvre désormais aussi le département et le verbatim des portraits.

**Why this priority**: Confort de navigation et cohérence avec le socle 021 ; ne bloque ni la saisie ni la lecture publique.

**Independent Test**: Publier trois portraits sur cinq, rattacher deux partenaires dont un inactif, ouvrir le tableau de bord : les compteurs affichent 3 / 5 et 2 (dont 1 actif), et chaque raccourci mène à sa rubrique.

**Acceptance Scenarios**:

1. **Given** cinq portraits dont trois publiés, **When** le tableau de bord est ouvert, **Then** le compteur « lauréats » affiche 3 / 5 et mène à la rubrique.
2. **Given** un utilisateur sans la permission « voir », **When** il ouvre l'admin, **Then** les deux nouvelles entrées sont absentes et les adresses directes sont refusées.
3. **Given** un portrait dont le verbatim anglais a été vidé manuellement, **When** l'action « Traduire les champs manquants » est lancée, **Then** le verbatim anglais est rempli à partir du français, les valeurs déjà présentes sont conservées, et le nombre d'éléments complétés inclut les portraits.

---

### User Story 6 - Rattachement initial des partenaires cités par le cahier des charges (Priority: P3)

Lors de la mise en place, les partenaires cités par le cahier des charges qui existent déjà dans le backoffice Partenaires (Campus France, CEF, CCI, AUF, AFD, OIF, Réseau Senghor) sont rattachés automatiquement à leur famille, sans qu'aucun partenaire ne soit créé. Les partenaires absents sont ignorés et signalés dans le compte rendu de la migration ; un rejeu ne crée aucun doublon et n'écrase pas une famille modifiée depuis par un éditeur.

**Why this priority**: Gain de temps à la mise en ligne, sans impact fonctionnel si la base ne contient aucun de ces partenaires.

**Independent Test**: Sur une base contenant « Campus France » et « AUF », rejouer la migration deux fois : les deux partenaires sont rattachés une seule fois chacun, dans la bonne famille, et aucun partenaire n'a été créé.

**Acceptance Scenarios**:

1. **Given** une base où « Agence universitaire de la Francophonie (AUF) » existe, **When** la migration est jouée, **Then** ce partenaire est rattaché à « organisations internationales » sans création de partenaire.
2. **Given** une base sans aucun des partenaires cités, **When** la migration est jouée, **Then** elle se termine sans erreur et la rubrique est vide.
3. **Given** un partenaire rattaché par la migration puis déplacé par un éditeur dans une autre famille, **When** la migration est rejouée, **Then** la famille choisie par l'éditeur est conservée.

---

### Edge Cases

- **Suppression d'une cohorte utilisée** : la suppression d'une cohorte à laquelle au moins un portrait est rattaché est refusée avec le message « cohorte utilisée par N lauréats » (contrat prévu par la feature 021) ; la désactivation reste possible et retire les portraits du public.
- **Cohorte désactivée puis réactivée** : les portraits publiés réapparaissent dans la lecture publique sans nouvelle action.
- **Changement de type d'un portrait** : si le nouveau type n'est pas cohérent avec la cohorte actuelle, l'enregistrement est refusé tant qu'une cohorte du bon type n'est pas choisie.
- **Photo retirée de la médiathèque** : le portrait reste valide, l'adresse de photo est vide en public et l'aperçu admin indique « média introuvable » avec possibilité de choisir une autre photo.
- **Portrait sans verbatim ni liens** : la carte est valide (la maquette présente des portraits sans verbatim) ; seuls le nom, le type, la cohorte et le projet sont obligatoires.
- **Montant de subvention** : facultatif, entier ou décimal positif, exprimé en euros ; un montant négatif est refusé.
- **Partenaire rattaché puis supprimé** : le rattachement disparaît automatiquement ; aucune trace orpheline dans la rubrique ni dans la lecture publique.
- **Réordonnancement avec un identifiant manquant ou inconnu** : refusé avec un message explicite, comme pour les autres listes du pôle (la liste complète des portraits de la cohorte, ou des partenaires de la famille, est exigée).
- **Rejeu de migration** : types, tables, index, déclencheurs et rattachements initiaux sont créés « s'ils n'existent pas » ; aucune valeur modifiée par un éditeur n'est écrasée.
- **Retour arrière** : le script de retour arrière de cette feature doit être joué avant celui de la feature 021, sinon la suppression des cohortes est bloquée par les portraits rattachés ; l'en-tête du script 045 est complété d'un avertissement.
- **Lien vidéo** : n'importe quelle adresse web valide est acceptée (YouTube, Vimeo, fichier hébergé) ; aucune transformation n'est faite à l'enregistrement.

## Requirements *(mandatory)*

### Functional Requirements

**Données du pôle**

- **FR-001**: Le système MUST stocker les **portraits** (lauréats FSE et étudiants-entrepreneurs) avec : nom complet, type (lauréat FSE / étudiant-entrepreneur), cohorte obligatoire (référence à une cohorte du pôle, suppression de la cohorte bloquée tant que des portraits y sont rattachés), nom du projet, libellé de département trilingue, verbatim trilingue (texte simple, 600 caractères au maximum par langue, pas de contenu riche), photo (référence à la médiathèque), liens site web, LinkedIn, Instagram, Facebook et vidéo, montant de subvention (facultatif, positif, en euros), indicateur « mis en avant », état publié avec date de première publication, ordre d'affichage au sein de la cohorte, horodatages et auteurs de création et de modification.
- **FR-002**: Le système MUST stocker les **rattachements de partenaires** au pôle : référence au partenaire existant (un partenaire ne peut être rattaché qu'une fois ; la suppression du partenaire supprime automatiquement le rattachement), famille parmi trois valeurs fixes (académiques et institutionnels, organisations d'appui, organisations internationales), ordre d'affichage au sein de la famille, horodatages.
- **FR-003**: Le type d'un portrait MUST être cohérent avec le type de sa cohorte : lauréat FSE avec une cohorte FSE, étudiant-entrepreneur avec une cohorte SEE. Le formulaire MUST ne proposer que les cohortes du type choisi et le système MUST refuser une combinaison incohérente avec un message explicite.
- **FR-004**: Le modèle de référence du pôle MUST être complété dans le fichier de schéma dédié (feature 021), et livré avec une migration rejouable numérotée 046 accompagnée de son script de retour arrière, tous deux nommés sans accents ni caractères spéciaux. Le script de retour arrière de la feature 021 MUST être annoté de l'ordre de retour arrière (046 avant 045).
- **FR-005**: Le SQL du modèle MUST être soumis à l'accord du responsable du projet avant toute écriture de code applicatif.
- **FR-006**: La migration MUST rattacher, sans en créer, les partenaires du cahier des charges déjà présents dans le backoffice Partenaires : Réseau Senghor et Campus France en « académiques et institutionnels » ; CEF et CCI en « organisations d'appui » ; AUF, AFD et OIF en « organisations internationales ». La correspondance se fait sur le nom (insensible à la casse, tolérante à l'apostrophe typographique) ; les partenaires absents sont ignorés et listés dans la sortie de la migration ; un rejeu ne crée aucun doublon et ne modifie pas un rattachement existant.

**Permissions et sécurité**

- **FR-007**: Aucune nouvelle permission ne MUST être créée : la consultation admin des deux rubriques exige la permission « entrepreneuriat : voir », la création et le rattachement « créer », la modification, la publication, le changement de famille et le réordonnancement « modifier », la suppression et le retrait « supprimer ».
- **FR-008**: Les deux nouvelles entrées de la barre latérale MUST n'apparaître qu'aux utilisateurs disposant de la permission « voir » ; les boutons de suppression et de retrait MUST être masqués sans la permission « supprimer ».

**Gestion admin des portraits**

- **FR-009**: Les éditeurs autorisés MUST pouvoir créer, lire, modifier, supprimer, réordonner, publier / dépublier et mettre en avant chaque portrait depuis une page de liste, une page de création et une page d'édition dédiées, sur le gabarit exact des cohortes du pôle (feature 021).
- **FR-010**: Le formulaire MUST proposer le département et le verbatim sous des onglets FR / EN / AR (sens droite-à-gauche pour l'arabe) et un bouton de traduction FR → EN / AR qui ne remplit que les champs vides ; le nom, le projet et les liens ne sont pas traduits.
- **FR-011**: À la création et à la modification, les champs anglais et arabes vides du département et du verbatim MUST être remplis automatiquement à partir du français ; les valeurs saisies manuellement MUST être conservées.
- **FR-012**: La photo MUST être choisie via le sélecteur de médiathèque existant, avec aperçu, remplacement et retrait dans le formulaire ; aucun nouvel outil de téléversement ne MUST être créé.
- **FR-013**: La liste des portraits MUST proposer une recherche textuelle (nom, projet) et des filtres par cohorte, par type et par état de publication ; elle MUST afficher pour chaque portrait la photo (vignette), le nom, le projet, la cohorte, le type, l'état publié, l'indicateur « mis en avant » et les actions.
- **FR-014**: Le réordonnancement des portraits MUST se faire par glisser-déposer au sein d'une cohorte : actif uniquement lorsque la liste est filtrée sur une seule cohorte sans recherche ni autre filtre (désactivé et expliqué sinon), enregistré immédiatement, avec renumérotation contiguë des positions de la cohorte sans affecter les autres cohortes. Le changement de cohorte d'un portrait MUST le placer en dernière position de sa nouvelle cohorte et renuméroter l'ancienne.
- **FR-015**: Le système MUST refuser un portrait sans nom, sans projet ou sans cohorte, un verbatim de plus de 600 caractères dans une langue, un lien qui n'est pas une adresse web valide, un montant négatif, et une cohorte incohérente avec le type, avec un message explicite par champ.
- **FR-016**: La suppression d'un portrait MUST être définitive, précédée d'une confirmation et réservée à la permission « supprimer » ; la dépublication reste le moyen recommandé de retirer un portrait du public.
- **FR-017**: La suppression d'une cohorte rattachée à au moins un portrait MUST être refusée avec le message « cohorte utilisée par N lauréats », en activant le point d'extension prévu par la feature 021.

**Gestion admin des partenaires du pôle**

- **FR-018**: La rubrique « Partenaires du pôle » MUST tenir sur une seule page : les partenaires rattachés groupés par famille dans l'ordre fixe des familles, chacun avec logo, nom, type du backoffice Partenaires, badge actif / inactif, lien vers sa fiche dans le backoffice Partenaires, sélecteur de famille et bouton de retrait.
- **FR-019**: L'ajout MUST passer par un sélecteur de partenaires existants avec recherche par nom (réutilisant la liste admin des partenaires), qui exclut les partenaires déjà rattachés et affiche leur logo et leur état ; l'éditeur choisit la famille à l'ajout. Aucun partenaire ne MUST pouvoir être créé ni modifié depuis cette rubrique ; un lien visible MUST renvoyer vers le backoffice Partenaires.
- **FR-020**: Le réordonnancement des partenaires MUST se faire par glisser-déposer au sein d'une famille, être enregistré immédiatement et renuméroter les positions de la famille de façon contiguë, sans affecter les autres familles. Le changement de famille MUST placer le partenaire en dernière position de sa nouvelle famille.
- **FR-021**: Le retrait d'un partenaire du pôle MUST supprimer uniquement le rattachement, après confirmation, et laisser le partenaire intact dans le backoffice Partenaires.

**Audit**

- **FR-022**: Chaque création, modification, suppression, réordonnancement, publication / dépublication et changement de mise en avant d'un portrait, ainsi que chaque rattachement, changement de famille, réordonnancement et retrait de partenaire, MUST être tracé dans le journal d'audit existant, avec l'auteur, l'action, l'entité, les anciennes et nouvelles valeurs, l'adresse d'origine et l'horodatage, selon la convention de nommage des actions du pôle.

**Tableau de bord et navigation**

- **FR-023**: Le tableau de bord du pôle MUST afficher deux compteurs supplémentaires, « lauréats et étudiants-entrepreneurs » (publiés / total) et « partenaires du pôle » (rattachés, dont actifs), chacun menant à sa rubrique, et conserver les raccourcis existants.
- **FR-024**: La section « Entrepreneuriat (PEI) » de la barre latérale MUST gagner deux entrées, « Lauréats et étudiants-entrepreneurs » (adresse `/admin/entrepreneuriat/laureats`) et « Partenaires du pôle » (adresse `/admin/entrepreneuriat/partenaires`), placées après « Cohortes » et avant « Boîte à outils ».
- **FR-025**: L'action « Traduire les champs manquants » MUST couvrir le département et le verbatim des portraits, avec les mêmes garanties (uniquement les champs vides, rejouable, tracée, compte des éléments complétés).

**Lecture publique**

- **FR-026**: Le système MUST exposer une lecture publique, sans authentification et en lecture seule, des portraits publiés, groupés par cohorte active, les cohortes dans leur ordre d'affichage et les portraits dans leur ordre au sein de la cohorte ; chaque groupe MUST porter le code, le libellé, l'année, le focus et le bilan trilingues de la cohorte, et chaque portrait le nom, le type, le projet, le département et le verbatim trilingues, l'adresse affichable de la photo, les cinq liens, l'indicateur « mis en avant » et le libellé de cohorte (badge). Les cohortes sans portrait publié MUST être omises.
- **FR-027**: La lecture publique des portraits MUST accepter un filtre par type et renvoyer, en plus des groupes, les chiffres du bandeau calculés sur les portraits publiés répondant au filtre : nombre de portraits, nombre de cohortes représentées, montant de subvention maximal.
- **FR-028**: Le système MUST exposer une lecture publique, sans authentification, des partenaires du pôle groupés par famille dans l'ordre fixe (les trois familles toujours présentes, éventuellement vides), chaque partenaire enrichi avec le nom, l'adresse affichable du logo, la description trilingue et le site web du backoffice Partenaires ; les partenaires désactivés MUST être exclus et les partenaires supprimés ne MUST laisser aucune trace.
- **FR-029**: Les lectures publiques MUST être déclarées avant toute route paramétrée du même groupe et ne MUST exposer aucun identifiant interne de média (seule l'adresse affichable est renvoyée).

**Transversal**

- **FR-030**: Avant toute création de composant d'interface, l'équipe MUST vérifier qu'un composant équivalent n'existe pas déjà : le sélecteur de médiathèque, les onglets de langue, les listes réordonnables et les formulaires du pôle MUST être réutilisés ; le sélecteur de partenaires MUST reprendre le gabarit du sélecteur d'albums existant (modale de recherche multi-sélection) car aucun sélecteur de partenaires réutilisable n'existe.
- **FR-031**: La lecture des champs trilingues côté interface MUST utiliser le repli français silencieux existant.
- **FR-032**: Tout contenu riche éventuel MUST utiliser l'éditeur existant en mode modal ; dans cette feature aucun champ riche n'est ajouté (le verbatim est un texte simple).
- **FR-033**: La documentation projet (CLAUDE.md) MUST être mise à jour : nouvelles tables, nouvelles rubriques admin, nouvelles lectures publiques, migration 046.

### Key Entities *(include if data involved)*

- **Portrait (pei_laureates)** : un lauréat du FSE ou un étudiant-entrepreneur mis en avant par le pôle. Attributs : nom, type, cohorte (obligatoire, cohérente avec le type), projet, département trilingue, verbatim trilingue, photo, liens (site, LinkedIn, Instagram, Facebook, vidéo), montant de subvention, mis en avant, publié + date de première publication, ordre au sein de la cohorte. Rattaché à une **Cohorte** de la feature 021 ; référence la médiathèque.
- **Rattachement de partenaire (pei_partners)** : le classement d'un partenaire existant dans l'une des trois familles du pôle. Attributs : partenaire (unique, supprimé en cascade avec le partenaire), famille, ordre au sein de la famille. Référence le **Partenaire** du backoffice Partenaires, dont il hérite nom, logo, description, site web et état actif.
- **Famille de partenaires** : valeur fixe parmi académiques et institutionnels, organisations d'appui, organisations internationales ; ordre d'affichage fixe.
- **Chiffres du bandeau** : agrégats calculés à la lecture publique (portraits publiés, cohortes représentées, subvention maximale), non stockés.
- **Entrée d'audit** : trace de chaque écriture admin, dans le journal existant.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Un éditeur autorisé crée et publie un portrait complet (photo, verbatim, trois liens) en moins de 4 minutes, et ses versions anglaise et arabe sont disponibles sans saisie supplémentaire.
- **SC-002**: 100 % des écritures admin sur les portraits et les rattachements de partenaires produisent une entrée dans le journal d'audit avec auteur et horodatage.
- **SC-003**: 100 % des portraits dépubliés ou rattachés à une cohorte inactive sont absents de la lecture publique ; 100 % des portraits publiés de cohortes actives y figurent sous leur cohorte, dans l'ordre défini en admin.
- **SC-004**: 100 % des partenaires désactivés ou supprimés dans le backoffice Partenaires sont absents de la lecture publique du pôle, et cette lecture répond sans erreur dans ces deux cas.
- **SC-005**: Un utilisateur sans permission « entrepreneuriat » ne voit aucune des deux nouvelles entrées et obtient un refus sur 100 % des accès directs.
- **SC-006**: La migration s'exécute deux fois de suite sans erreur en local et en production ; le nombre de rattachements et de portraits est identique après le second passage, et aucun partenaire n'a été créé.
- **SC-007**: Sur une base contenant les partenaires cités par le cahier des charges, 100 % d'entre eux sont rattachés à la bonne famille après migration.
- **SC-008**: Un éditeur rattache un partenaire existant et lui affecte sa famille en moins de 30 secondes, sans quitter la rubrique.
- **SC-009**: Un réordonnancement par glisser-déposer (portraits d'une cohorte ou partenaires d'une famille) est visible après rechargement de page dans 100 % des cas.
- **SC-010**: Les lectures publiques répondent en moins d'une seconde pour 100 portraits et 50 partenaires.
- **SC-011**: Le tableau de bord affiche des compteurs exacts (publiés / total, rattachés / actifs) dans 100 % des vérifications, et chacun de ses raccourcis mène à une page existante.

## Assumptions

- **Numérotation** : la migration prend le numéro 046 (dernière migration existante : 045), avec un script de retour arrière séparé, comme la feature 021.
- **Cohorte obligatoire et cohérente** : chaque portrait appartient à exactement une cohorte, de type FSE pour un lauréat FSE et SEE pour un étudiant-entrepreneur. Ce choix suit la maquette (sections par cohorte, deux sous-onglets par type) ; un portrait à la fois lauréat FSE et étudiant-entrepreneur correspond à deux fiches.
- **Département en texte libre** : la feuille de route évoquait un lien optionnel vers les secteurs ou programmes ; la description de la feature retient un libellé trilingue libre, plus simple et suffisant pour la carte. Aucun lien vers les secteurs n'est créé.
- **Verbatim en texte simple** : confirmé en clarification ; une citation courte (600 caractères au maximum par langue) stockée en texte simple trilingue ; aucun contenu riche n'est ajouté, donc pas de double colonne affichable / éditable ni d'éditeur modal.
- **Photo facultative** : un portrait peut être publié sans photo (la maquette prévoit un emplacement, l'affichage public gèrera un substitut) ; nom, type, cohorte et projet sont les seuls champs obligatoires.
- **Montant de subvention** : décimal positif en euros, facultatif, non affiché sur la carte de la maquette mais utilisé pour le chiffre « subvention maximale » du bandeau et disponible en admin.
- **Chiffres du bandeau** : calculés à la lecture publique à partir des portraits publiés (nombre de portraits, cohortes représentées, subvention maximale), confirmé en clarification. La feature 024 choisira entre ces chiffres et des clés éditoriales qu'elle créera si les chiffres officiels diffèrent ; aucune clé éditoriale nouvelle n'est créée ici.
- **Réseaux sociaux des partenaires** : hors périmètre (voir Clarifications) ; la lecture publique enrichit avec ce qui existe dans le backoffice Partenaires (nom, logo, description trilingue, site web). Aucun champ de réseau social n'est ajouté, ni aux partenaires ni au rattachement.
- **Un partenaire, une famille** : le rattachement est unique par partenaire (clé sur le partenaire), ce qui évite un même logo dans deux familles.
- **Lien réel vers les partenaires** : contrairement aux références vers la médiathèque (sans contrainte), le rattachement porte une vraie contrainte vers le partenaire avec suppression en cascade, comme demandé, pour garantir « disparaît sans erreur ».
- **Ordre des portraits** : propre à chaque cohorte (voir Clarifications), à la différence des listes globales de la feature 021 ; la lecture publique trie par cohorte puis par cet ordre. Le glisser-déposer n'est actif que sur une liste filtrée sur une seule cohorte, sans autre filtre.
- **Mise en avant** : simple indicateur exposé en public ; il ne modifie pas l'ordre (la feature 024 décidera de son usage, par exemple sur la page d'accueil du pôle).
- **Partenaires inactifs en admin** : restent visibles dans la rubrique avec un badge, pour que l'éditeur comprenne pourquoi ils n'apparaissent pas en public.
- **Correspondance des partenaires initiaux** : par nom, insensible à la casse et tolérante à l'apostrophe typographique (gotcha connu des noms en production) ; la liste des noms testés sera vérifiée en lecture seule sur la base de production avant la migration.
- **Mode d'édition** : pages dédiées (liste, création, édition) pour les portraits, sur le gabarit des cohortes ; une seule page pour les partenaires du pôle car il s'agit d'une table de liaison sans formulaire riche.
- **Textes de l'admin** : en français en dur dans les gabarits, comme le reste du backoffice du pôle ; seuls les libellés partagés de traduction passent par les fichiers de langue.
- **Hors périmètre confirmé** : aucune page publique, aucun import automatique de lauréats, aucune création ni modification de partenaire depuis le pôle, aucune nouvelle permission, aucune clé éditoriale nouvelle.

## Dependencies

- Feature 021 (socle du pôle) : cohortes, permissions « entrepreneuriat », tableau de bord, action « Traduire les champs manquants », point d'extension de suppression de cohorte, gabarits de liste et de formulaire.
- Backoffice Partenaires existant : liste admin avec recherche, état actif, logo et description trilingue.
- Médiathèque existante : sélecteur de média et adresses de téléchargement.
- Service de traduction automatique existant (français → anglais / arabe).
- Journal d'audit existant.
- Feuille de route PEI : la feature 024 (mini-site : alumni, partenaires) consomme les deux lectures publiques livrées ici ; la feature 023 (accueil du pôle) consomme la lecture publique des partenaires.
