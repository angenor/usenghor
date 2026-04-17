# Feature Specification: Album médiathèque « Gouvernance » pour les textes fondateurs

**Feature Branch**: `018-governance-media-album`
**Created**: 2026-04-16
**Status**: Draft
**Input**: User description: "Migrer les documents fondateurs de la page gouvernance vers un vrai album BDD Gouvernance, exposé dans la médiathèque publique."

## Clarifications

### Session 2026-04-16

- Q: Comment identifier les items (album + documents) créés par la migration pour garantir idempotence (FR-005) et rollback ciblé (FR-006, A3) ? → A: Reconnaissance par l'URL du fichier source (`file_url`) — comparaison simple, sans nouveau schéma.
- Q: Sur `/a-propos/gouvernance`, que fait-on si l'album « Gouvernance » est absent, dépublié ou vide ? → A: Conserver badge + titre + description d'intro, remplacer uniquement la grille par un message discret (ex. « Les documents seront bientôt disponibles »).
- Q: Comment afficher les titres et descriptions des documents (stockés en français uniquement) quand le visiteur navigue en EN ou AR ? → A: Afficher les libellés FR tels quels, sans marqueur ni traduction automatique.
- Q: D'où vient la vignette de l'album « Gouvernance » dans la grille `/mediatheque` ? → A: Dérivée automatiquement de la couverture du premier document de l'album (selon `sort_order`).
- Q: Comment stocker et afficher l'année associée à un document fondateur ? → A: Année brute (ex. `2015`) stockée dans `credits`, affichée à la fois dans les flip cards de gouvernance et dans la vue album médiathèque, contextualisée via i18n côté frontend.

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Un visiteur découvre les textes fondateurs dans la médiathèque (Priority: P1)

Un visiteur qui parcourt la médiathèque publique `/mediatheque` voit un album « Gouvernance » aux côtés des autres albums. Il l'ouvre, y trouve tous les textes fondateurs (chartes, conventions, statuts), peut prévisualiser chaque PDF en ligne et le télécharger.

**Why this priority**: C'est la valeur principale de la fonctionnalité : faire exister les documents institutionnels à un second endroit canonique (la médiathèque) pour les rendre découvrables par des visiteurs qui ne passent pas par la page gouvernance.

**Independent Test**: Accessible via `/mediatheque` directement, sans dépendre de la page gouvernance. Le test consiste à ouvrir l'URL, cliquer sur l'album « Gouvernance », vérifier que chaque document s'affiche avec sa couverture et s'ouvre correctement.

**Acceptance Scenarios**:

1. **Given** la migration a été exécutée et au moins un document fondateur existait, **When** un visiteur ouvre `/mediatheque` dans l'onglet « Tout », **Then** l'album « Gouvernance » apparaît parmi les albums listés avec une couverture représentative et un compteur de documents.
2. **Given** la migration a été exécutée, **When** un visiteur ouvre `/mediatheque` dans l'onglet « Albums », **Then** l'album « Gouvernance » apparaît également dans cette vue filtrée.
3. **Given** l'album « Gouvernance » est publié, **When** un visiteur clique sur l'album, **Then** il arrive sur `/mediatheque/gouvernance` et voit la liste de tous les documents avec titre, description courte et couverture.
4. **Given** un document PDF est affiché dans la vue album, **When** le visiteur clique sur « Prévisualiser », **Then** le PDF s'ouvre dans une visionneuse intégrée sans quitter la page.
5. **Given** un document PDF est affiché dans la vue album, **When** le visiteur clique sur « Télécharger », **Then** le navigateur démarre le téléchargement du fichier d'origine.

---

### User Story 2 — La page gouvernance continue d'afficher les textes fondateurs en flip cards (Priority: P1)

Un visiteur qui consulte `/a-propos/gouvernance` voit toujours la section « Textes fondateurs » présentée sous forme de flip cards (couverture au recto, détails au verso), exactement comme avant la migration. Les boutons « Voir », « Télécharger » et « Prévisualiser » fonctionnent et pointent vers les documents migrés.

**Why this priority**: La page gouvernance est la destination principale historique des utilisateurs qui cherchent ces documents. Aucune régression visuelle ou fonctionnelle ne doit être perçue côté public, quelle que soit la source des données.

**Independent Test**: Ouvrir `/a-propos/gouvernance`, faire défiler jusqu'à la section « Textes fondateurs », vérifier que chaque card se retourne, que les actions fonctionnent, et comparer l'ordre d'affichage avec celui défini côté admin.

**Acceptance Scenarios**:

1. **Given** l'album « Gouvernance » contient N documents, **When** un visiteur ouvre `/a-propos/gouvernance`, **Then** la section « Textes fondateurs » affiche exactement N flip cards dans l'ordre configuré par l'administrateur.
2. **Given** un document possède une couverture, **When** la card est au repos, **Then** la couverture est visible au recto ; **When** la card est retournée (hover ou tap mobile), **Then** le titre et la description s'affichent au verso.
3. **Given** un document n'a pas de couverture, **When** la card est affichée, **Then** un visuel de repli cohérent avec l'identité visuelle s'affiche à la place.
4. **Given** un visiteur clique sur « Prévisualiser » depuis une card, **When** l'action est déclenchée, **Then** une visionneuse PDF s'ouvre en modale sans quitter la page gouvernance.
5. **Given** l'album « Gouvernance » est vide ou n'existe pas, **When** un visiteur ouvre `/a-propos/gouvernance`, **Then** la section « Textes fondateurs » affiche un état vide discret (message court) sans erreur technique visible.
6. **Given** la page est consultée en français, anglais ou arabe, **When** la section « Textes fondateurs » s'affiche, **Then** la mise en page reste cohérente (RTL en arabe) et les contenus documentaires (titres/descriptions en français) restent lisibles sans casser la traduction d'interface.

---

### User Story 3 — Un administrateur gère les documents via l'interface albums (Priority: P2)

Un administrateur connecté ouvre `/admin/mediatheque/albums/{id}` de l'album « Gouvernance » et peut ajouter un nouveau document, retirer un document, changer sa couverture, réordonner la liste et modifier les métadonnées (titre, description, crédits). Les changements se reflètent immédiatement sur `/mediatheque` et `/a-propos/gouvernance`.

**Why this priority**: C'est la conséquence éditoriale de la migration. L'équipe doit disposer d'un point de gestion unique, plus ergonomique qu'un blob JSON, pour tenir la liste des textes fondateurs à jour.

**Independent Test**: Se connecter en admin, ouvrir l'album « Gouvernance », effectuer chacune des opérations (ajouter/retirer/réordonner/modifier métadonnées), puis vérifier côté public que le changement apparaît.

**Acceptance Scenarios**:

1. **Given** un admin est sur la page de l'album « Gouvernance », **When** il ajoute un nouveau document PDF avec titre/description/couverture, **Then** ce document apparaît dans l'album publié et dans la page `/a-propos/gouvernance` après rafraîchissement.
2. **Given** un document existe dans l'album, **When** l'admin change son ordre par glisser-déposer ou par édition du rang, **Then** l'ordre d'affichage public reflète ce changement sur les deux pages (médiathèque + gouvernance).
3. **Given** un document existe, **When** l'admin le retire de l'album, **Then** il disparaît de `/mediatheque/gouvernance` et de `/a-propos/gouvernance`.
4. **Given** un admin modifie la couverture d'un document, **When** il enregistre, **Then** la nouvelle couverture s'affiche dans les flip cards de gouvernance et dans les vignettes de la médiathèque.

---

### User Story 4 — Le champ JSON éditorial historique est retiré de l'édition (Priority: P2)

Un administrateur qui ouvre l'édition de la page éditoriale « Gouvernance » ne voit plus de champ éditable pour gérer la liste des documents fondateurs sous forme de JSON. À la place, une note lui indique que cette gestion se fait désormais via la médiathèque, avec un lien direct vers l'album.

**Why this priority**: Garantit la source de vérité unique. Empêche la création de doublons ou d'incohérences entre deux emplacements de gestion. Les champs texte non liés (badge, titre, description de section) restent éditables là où ils sont.

**Independent Test**: Ouvrir l'admin éditorial de la page gouvernance, vérifier qu'aucun champ éditable « documents fondateurs » n'apparaît, et que la note de redirection est présente et cliquable.

**Acceptance Scenarios**:

1. **Given** un admin ouvre l'éditeur de la page éditoriale « Gouvernance », **When** il consulte la section des champs éditables, **Then** le champ `governance.foundingTexts.documents` n'est plus présent comme champ modifiable.
2. **Given** l'admin est dans l'éditeur éditorial, **When** il cherche à gérer la liste des documents, **Then** il voit une indication claire pointant vers l'album médiathèque « Gouvernance ».
3. **Given** l'admin modifie les champs texte (`badge`, `title`, `description`) de la section, **When** il enregistre, **Then** ces champs restent éditables et leur valeur continue de s'afficher côté public sans régression.

---

### Edge Cases

- **Album introuvable ou dépublié** sur la page `/a-propos/gouvernance` → badge + titre + description d'intro conservés, grille remplacée par un message court ; pas d'erreur visible à l'utilisateur, journalisation côté serveur.
- **Document sans couverture** → visuel de repli cohérent utilisé sur les flip cards ET dans la médiathèque.
- **Document sans description** → recto/verso des flip cards et fiches médiathèque restent lisibles (pas de zones vides disgracieuses).
- **Document sans année** → le champ année n'apparaît pas (pas de « undefined » ni de crochets vides).
- **Migration ré-exécutée** → aucune duplication (items existants conservés tels quels ou mis à jour, pas de doublons dans l'album).
- **Données éditoriales JSON absentes ou vides** au moment de la migration → l'album est créé vide, sans erreur ; l'admin peut alors y ajouter manuellement les documents.
- **Rollback exécuté après ajout manuel en admin** → la procédure de rollback ne doit pas effacer silencieusement des documents ajoutés après la migration ; elle doit préserver les ajouts (voir Assumption A3).
- **Navigation en arabe (RTL)** → l'album et les flip cards s'affichent correctement en RTL ; contenu documentaire en français accepté sans casser l'interface.
- **Fichier PDF introuvable** (lien brisé, fichier supprimé) → bouton « Prévisualiser » affiche un message d'erreur clair sans bloquer la page ; « Télécharger » renvoie l'erreur HTTP standard.
- **Synchronisation entre les deux pages publiques** → une mise à jour côté admin se propage aux deux vues publiques (médiathèque et gouvernance) au prochain rafraîchissement.

## Requirements *(mandatory)*

### Functional Requirements

#### Migration des données

- **FR-001**: Le système DOIT fournir un script de migration qui crée en base un album nommé « Gouvernance » avec le slug `gouvernance`, le statut « publié », et une description courte explicitant qu'il s'agit des textes fondateurs de l'université.
- **FR-002**: Le script de migration DOIT lire la liste des documents fondateurs actuellement stockée comme contenu éditorial (clé `governance.foundingTexts.documents`) et transformer chaque entrée en document médiathèque.
- **FR-003**: Chaque document médiathèque créé DOIT être lié à l'album « Gouvernance » en respectant l'ordre d'affichage (`sort_order`) présent dans les données sources.
- **FR-004**: Chaque document DOIT conserver ses attributs d'origine : titre, description, URL du fichier PDF, URL de la couverture, taille du fichier. Si une année est renseignée dans les données source, elle DOIT être stockée telle quelle (valeur brute, ex. `2015`) dans le champ `credits` du média et DOIT être affichée à la fois dans les flip cards de `/a-propos/gouvernance` et dans la vue détail de l'album médiathèque. La contextualisation (préfixe « Adoptée en », « Adopted », etc.) DOIT être assurée côté frontend via les fichiers i18n, pas stockée en base.
- **FR-005**: Le script DOIT être idempotent : son exécution répétée NE DOIT PAS créer de doublons d'album ni de doublons de documents déjà migrés. L'identification d'un doublon se fait par comparaison de l'URL du fichier source (`file_url`) : un document dont l'URL existe déjà en base n'est pas réinséré.
- **FR-006**: Le système DOIT fournir un script de rollback qui retire l'album « Gouvernance » et uniquement les documents dont l'URL source correspond à celles présentes dans les données éditoriales d'origine au moment de la migration. Les documents ajoutés ultérieurement via l'interface admin (URLs différentes) DOIVENT être préservés (voir Assumption A3).
- **FR-007**: Les scripts de migration et de rollback DOIVENT s'exécuter de manière identique en environnement local et en production.

#### Exposition dans la médiathèque publique

- **FR-008**: L'album « Gouvernance » publié DOIT apparaître dans la liste des albums de la médiathèque publique, dans l'onglet « Tout » et dans l'onglet « Albums ». Sa vignette dans la grille DOIT être dérivée automatiquement de la couverture du premier document de l'album (selon l'ordre défini dans l'album). Si aucun document n'a de couverture, le fallback générique albums de la médiathèque s'applique.
- **FR-009**: L'accès à l'album via son slug `gouvernance` DOIT ouvrir la page détail correspondante listant tous les documents, chacun avec son titre, sa description, sa couverture, un bouton de prévisualisation inline et un bouton de téléchargement.
- **FR-010**: La prévisualisation d'un document PDF DOIT se faire via une visionneuse intégrée à la page (modale ou panneau) sans quitter la médiathèque.

#### Page publique gouvernance

- **FR-011**: La page `/a-propos/gouvernance` DOIT charger la section « Textes fondateurs » à partir de l'album médiathèque « Gouvernance » et non plus depuis le contenu éditorial JSON.
- **FR-012**: L'affichage des textes fondateurs sur la page gouvernance DOIT conserver sa présentation en flip cards avec couverture au recto et détails au verso.
- **FR-013**: Chaque flip card DOIT proposer au minimum les actions « Voir », « Télécharger » et « Prévisualiser » (cette dernière via une visionneuse PDF intégrée).
- **FR-014**: L'ordre d'affichage des flip cards DOIT refléter l'ordre défini dans l'album.
- **FR-015**: Si l'album est absent, dépublié ou vide, la page DOIT conserver le bandeau haut de section (badge, titre, description d'intro) et remplacer uniquement la grille de flip cards par un message discret (ex. « Les documents seront bientôt disponibles »). Aucune erreur technique ne DOIT être visible et la mise en page NE DOIT PAS présenter de zone vide disgracieuse.

#### Administration

- **FR-016**: Un administrateur DOIT pouvoir ajouter, modifier, retirer et réordonner les documents de l'album « Gouvernance » via l'interface admin existante de gestion d'album médiathèque.
- **FR-017**: Un administrateur DOIT pouvoir modifier la couverture d'un document via la même interface.
- **FR-018**: L'interface d'édition de la page éditoriale « Gouvernance » NE DOIT PLUS présenter le champ `governance.foundingTexts.documents` comme champ éditable.
- **FR-019**: L'interface d'édition éditoriale DOIT indiquer clairement à l'administrateur où gérer désormais les documents fondateurs (mention et renvoi vers la médiathèque admin).
- **FR-020**: Les autres champs texte de la section « Textes fondateurs » (badge, titre, description d'intro) DOIVENT rester éditables via l'interface éditoriale.

#### Trilinguisme et qualité

- **FR-021**: La page `/a-propos/gouvernance` DOIT rester fonctionnelle et sans régression visuelle dans les trois langues (français, anglais, arabe avec RTL). Les titres et descriptions des documents fondateurs (stockés uniquement en français pour cette itération) DOIVENT être affichés tels quels en EN et AR, sans marqueur de langue ni traduction automatique. Seuls les libellés d'interface (boutons « Voir », « Télécharger », « Prévisualiser », message d'état vide, etc.) DOIVENT être traduits.
- **FR-022**: Le système NE DOIT PAS introduire de régression sur les autres albums ni sur les fichiers directs déjà exposés dans `/mediatheque`.
- **FR-023**: Aucun nouvel endpoint d'API public N'EST requis ; la feature DOIT s'appuyer sur les endpoints publics albums existants.

### Key Entities *(include if feature involves data)*

- **Album « Gouvernance »** : groupe logique publié dans la médiathèque, identifié par un slug stable (`gouvernance`), porteur d'un titre d'affichage, d'une description courte et d'un statut de publication. Contient zéro ou plusieurs documents, ordonnés.
- **Document fondateur (média de type document)** : un texte institutionnel (charte, convention, statut) au format PDF, caractérisé par un titre, une description, un fichier PDF téléchargeable, une couverture optionnelle, une taille de fichier, et une mention éventuelle d'année (ex : année d'adoption). Est rattaché à l'album « Gouvernance » avec une position (ordre d'affichage).
- **Contenu éditorial de la page gouvernance** : bloc de texte non-liste (badge, titre, description d'intro de la section) qui reste géré via l'outil éditorial. Ne contient plus la liste de documents après migration.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Après exécution de la migration en local, 100 % des documents fondateurs présents dans les données éditoriales d'origine sont visibles dans l'album « Gouvernance » de `/mediatheque/gouvernance`, avec le même ordre et les mêmes métadonnées (titre, description, couverture).
- **SC-002**: Un visiteur peut ouvrir un PDF fondateur en prévisualisation en moins de 2 clics depuis la médiathèque publique et en moins de 2 clics depuis la page gouvernance.
- **SC-003**: La page `/a-propos/gouvernance` continue de rendre la section « Textes fondateurs » sans erreur visible dans les trois langues (FR, EN, AR).
- **SC-004**: La migration peut être exécutée deux fois de suite sans créer d'entrée dupliquée (album unique, documents uniques) — vérifié par comparaison de l'état avant/après deuxième exécution.
- **SC-005**: Un administrateur peut ajouter, retirer, renommer ou réordonner un document via l'interface admin de l'album et constater le changement sur les deux pages publiques en moins de 30 secondes (sous réserve du temps de rafraîchissement côté client).
- **SC-006**: Aucun ticket de régression n'est ouvert sur la médiathèque publique ou sur la page gouvernance dans les 7 jours suivant la mise en production.
- **SC-007**: Le champ JSON éditorial `governance.foundingTexts.documents` n'est plus présenté comme éditable dans l'interface d'administration éditoriale (vérifiable par inspection de l'UI admin).

## Assumptions

- **A1 — Contenu trilingue des documents** : les documents fondateurs n'ont historiquement qu'un titre et une description en français. Pour cette itération, on conserve un seul libellé par document (français), affiché tel quel y compris en EN et AR. Seuls les libellés d'interface autour des documents (boutons, état vide, intitulés d'actions) sont traduits via les fichiers i18n existants. Une future itération pourra introduire des champs multilingues côté médiathèque si le besoin est confirmé.
- **A2 — Format des documents** : tous les documents fondateurs actuels sont des PDF. La migration suppose ce format par défaut. Si de futurs documents arrivent dans d'autres formats, l'interface admin permettra de les gérer sans modifier cette spécification.
- **A3 — Rollback partiel** : le script de rollback identifie les items à supprimer par leur URL de fichier source (`file_url`), égale à celle présente dans les données éditoriales au moment de la migration. Les documents ajoutés manuellement après migration (URLs différentes) sont préservés, et l'album n'est supprimé que s'il est vide ou ne contient plus que des items migrés. Cette décision évite toute perte de données accidentelle et ne nécessite aucune migration de schéma additionnelle.
- **A4 — Aucun changement d'API** : les endpoints publics existants fournissent déjà tous les champs nécessaires (titre, description, URL fichier, URL vignette, taille, crédits). Aucune extension de contrat n'est prévue.
- **A5 — URLs des fichiers PDF et couvertures** : les fichiers référencés par les documents fondateurs actuels restent accessibles aux mêmes URL après migration (aucune ré-upload requise).
- **A6 — Conservation du JSON éditorial** : la clé `governance.foundingTexts.documents` peut rester stockée en base (pour historique / rollback) mais n'est plus utilisée côté public et n'est plus éditable côté admin. Elle pourra être nettoyée lors d'une itération ultérieure.
- **A7 — Déploiement** : la migration est exécutée manuellement (commande documentée), d'abord en local puis en production, dans le même ordre que les autres migrations du projet.

## Dependencies

- Schéma BDD existant avec les tables d'albums, de médias et d'association album/média opérationnelles.
- Endpoints publics albums déjà fonctionnels (liste, détail par slug).
- Interface admin de gestion d'album médiathèque déjà fonctionnelle (ajout/retrait/réordonnancement de médias).
- Composant de prévisualisation PDF inline déjà disponible côté frontend.
- Données éditoriales actuelles (clé `governance.foundingTexts.documents`) accessibles en lecture au moment de la migration.

## Out of Scope

- Traduction des titres et descriptions des documents fondateurs en anglais et arabe (traitée dans une future itération, voir A1).
- Refonte visuelle des flip cards de la page gouvernance (conservation de l'apparence actuelle).
- Ajout de nouveaux types de médias (vidéo, image haute définition) dans l'album gouvernance.
- Création de nouveaux endpoints API ou de nouveaux composants de médiathèque publics.
- Purge de la clé éditoriale `governance.foundingTexts.documents` dans la base (peut être faite ultérieurement).
- Historique / versioning des documents fondateurs.
