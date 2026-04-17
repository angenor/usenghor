# Feature Specification: Ajout direct de fichiers dans la médiathèque (sans album)

**Feature Branch**: `016-mediatheque-direct-upload`
**Created**: 2026-04-11
**Status**: Draft
**Input**: User description: "on veut pouvoir ajouter des fichiers directement dans la médiatheque, ca ne marche pas actuellement, seul les ajout à travers des album fonctionne. On doit pouvoir ajouter dans passer par un album"

## Clarifications

### Session 2026-04-12

- Q: Comportement lors de la fermeture de la fenêtre pendant un téléversement en cours ? → A: Demander confirmation ; si confirmé, annuler proprement les téléversements en cours ; sinon, la fenêtre reste ouverte.
- Q: Sort du champ « URL externe » actuellement présent dans la fenêtre d'ajout ? → A: Le retirer complètement dans le cadre de cette feature.
- Q: Stratégie de téléversement multi-fichiers et limite de concurrence ? → A: Parallèle avec limite de 5 téléversements simultanés ; les fichiers supplémentaires attendent en file.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Téléverser un ou plusieurs fichiers directement dans la médiathèque (Priority: P1)

Un administrateur ouvre l'onglet « Fichiers » de la médiathèque et clique sur « Ajouter des fichiers ». Une fenêtre d'ajout s'ouvre. Il sélectionne un ou plusieurs fichiers depuis son appareil (ou les glisse-dépose dans la zone prévue), lance le téléversement et voit les fichiers apparaître dans la liste de la médiathèque une fois l'opération terminée — sans avoir eu besoin de créer ou d'ouvrir un album.

**Why this priority**: C'est le coeur du problème signalé. Aujourd'hui, la seule façon de téléverser un média est de passer par la page d'un album. Les fichiers « libres » (logos réutilisables, documents ponctuels, visuels utilisés ailleurs dans le site) deviennent impossibles à ajouter sans créer un album factice. Sans cette correction, la médiathèque ne remplit pas son rôle de bibliothèque centrale de fichiers.

**Independent Test**: Un administrateur connecté se rend sur `/admin/mediatheque`, clique sur « Ajouter des fichiers », sélectionne deux images depuis son disque, lance le téléversement et constate que les deux nouveaux fichiers apparaissent en tête de la grille de l'onglet « Fichiers », téléchargeables et modifiables, sans qu'aucun album n'ait été créé ni ouvert.

**Acceptance Scenarios**:

1. **Given** un administrateur sur l'onglet « Fichiers » de `/admin/mediatheque`, **When** il clique sur « Ajouter des fichiers », **Then** une fenêtre d'ajout s'affiche avec une zone de sélection fonctionnelle.
2. **Given** la fenêtre d'ajout ouverte, **When** l'administrateur sélectionne un fichier via le sélecteur natif du navigateur, **Then** le téléversement démarre et un indicateur de progression s'affiche pour ce fichier.
3. **Given** la fenêtre d'ajout ouverte, **When** l'administrateur glisse-dépose plusieurs fichiers dans la zone prévue, **Then** tous les fichiers sont mis en file et jusqu'à 5 sont téléversés en parallèle, les suivants démarrant au fur et à mesure que des emplacements se libèrent.
4. **Given** un téléversement en cours, **When** il se termine avec succès, **Then** le fichier apparaît immédiatement dans la grille « Fichiers » sans rafraîchissement manuel et les compteurs (total, par type) sont mis à jour.
5. **Given** plusieurs fichiers en file, **When** l'un échoue (type non supporté, taille dépassée, erreur réseau), **Then** les autres continuent, le fichier en erreur est signalé avec un message explicite et peut être réessayé ou retiré de la file.
6. **Given** des fichiers téléversés directement dans la médiathèque, **When** l'administrateur les sélectionne, **Then** il peut les associer ultérieurement à un ou plusieurs albums via l'action « Ajouter à un album » existante.
7. **Given** la fenêtre d'ajout ouverte avec des téléversements terminés, **When** l'administrateur clique sur « Fermer », **Then** la fenêtre se ferme et les fichiers restent visibles dans la grille.

---

### User Story 2 - Validation et retour utilisateur pendant le téléversement (Priority: P2)

Pendant qu'il téléverse des fichiers, l'administrateur voit l'état de chaque fichier (en attente, en cours, terminé, en erreur) et comprend immédiatement ce qui s'est bien passé et ce qui a échoué.

**Why this priority**: Sans feedback clair, un administrateur qui téléverse dix fichiers ne sait pas si deux ont échoué silencieusement. Essentiel pour éviter la perte de confiance dans l'outil et pour permettre une correction rapide.

**Independent Test**: Un administrateur sélectionne cinq fichiers dont un dépasse la limite de taille autorisée. Il voit quatre fichiers marqués « Terminé » et un fichier marqué « Erreur : taille dépassée », et un message récapitulatif « 4 sur 5 fichiers ajoutés ».

**Acceptance Scenarios**:

1. **Given** un téléversement multi-fichiers en cours, **When** chaque fichier progresse, **Then** son état individuel est visible (icône, barre de progression ou pourcentage).
2. **Given** un fichier dont le type n'est pas supporté, **When** il est ajouté à la file, **Then** il est rejeté avant téléversement avec un message indiquant les types acceptés.
3. **Given** un fichier dont la taille dépasse la limite, **When** il est ajouté à la file, **Then** il est rejeté avec un message indiquant la taille maximale.
4. **Given** une panne réseau pendant un téléversement, **When** l'erreur survient, **Then** le fichier concerné est marqué en erreur sans bloquer les autres et un bouton « Réessayer » est proposé.
5. **Given** tous les téléversements terminés, **When** au moins un a échoué, **Then** un récapitulatif clair indique le nombre de réussites et d'échecs.

---

### Edge Cases

- Que se passe-t-il si l'administrateur ferme la fenêtre d'ajout pendant un téléversement en cours ? Une confirmation explicite est demandée (« Des fichiers sont en cours d'envoi, voulez-vous annuler ? »). Si l'utilisateur confirme, les téléversements en cours sont annulés proprement ; les téléversements déjà terminés restent acquis. Si l'utilisateur refuse, la fenêtre reste ouverte et les téléversements se poursuivent.
- Que se passe-t-il si un fichier identique (même nom, même contenu) est téléversé deux fois ? Le système accepte les deux (chaque média est identifié individuellement) — pas de déduplication silencieuse.
- Que se passe-t-il si l'administrateur navigue vers une autre page pendant un téléversement ? Comportement attendu : l'utilisateur est averti des fichiers non terminés avant de quitter la page.
- Que se passe-t-il pour un fichier audio/vidéo volumineux ? Le téléversement doit afficher une progression et ne pas paraître figé.
- Que se passe-t-il si l'administrateur n'a pas les permissions nécessaires ? Le bouton d'ajout doit être masqué ou désactivé, ou l'erreur doit être affichée proprement.
- Le champ « URL externe » déjà présent dans la fenêtre est retiré dans le cadre de cette feature (cf. FR-014). La correction ne concerne que l'ajout de fichiers locaux.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: La fenêtre d'ajout de fichiers accessible depuis l'onglet « Fichiers » de la médiathèque DOIT permettre la sélection d'un ou plusieurs fichiers depuis le disque de l'utilisateur via un sélecteur natif.
- **FR-002**: La fenêtre d'ajout DOIT permettre le glisser-déposer d'un ou plusieurs fichiers dans sa zone dédiée.
- **FR-003**: Les fichiers sélectionnés DOIVENT être effectivement téléversés et enregistrés comme des médias de la bibliothèque, sans qu'un album soit requis à aucun moment du processus.
- **FR-004**: Le système DOIT afficher l'état de chaque fichier pendant le téléversement (en attente, en cours avec progression, terminé, en erreur).
- **FR-005**: Le système DOIT valider côté interface le type et la taille des fichiers avant envoi et afficher un message clair en cas de rejet, sans bloquer les autres fichiers de la file.
- **FR-006**: Les médias téléversés directement DOIVENT apparaître immédiatement dans la grille de l'onglet « Fichiers » sans rechargement manuel de la page.
- **FR-007**: Les compteurs de l'onglet « Fichiers » (nombre total, nombre par type) DOIVENT être mis à jour automatiquement après un téléversement réussi.
- **FR-008**: Les médias téléversés directement DOIVENT être utilisables avec toutes les actions existantes de la médiathèque : aperçu, édition des métadonnées, téléchargement, suppression, association à un ou plusieurs albums a posteriori, sélection groupée.
- **FR-009**: En cas d'échec partiel d'un téléversement multi-fichiers, le système DOIT présenter un récapitulatif (nombre de réussites / nombre d'échecs) et permettre à l'utilisateur de réessayer les fichiers en erreur.
- **FR-010**: Le système DOIT respecter les permissions existantes : seul un utilisateur autorisé à gérer la médiathèque peut accéder à l'action d'ajout direct.
- **FR-011**: Les types de fichiers acceptés (images, vidéos, documents, audios) et la taille maximale DOIVENT être cohérents avec ceux déjà utilisés pour l'ajout via album.
- **FR-012**: La fenêtre d'ajout DOIT rester cohérente visuellement et fonctionnellement avec le reste de l'interface admin (mode sombre, responsive, accessibilité clavier, fermeture par Échap et clic extérieur).
- **FR-013**: Lorsque l'utilisateur tente de fermer la fenêtre (bouton fermer, Échap, clic extérieur) alors qu'au moins un téléversement est en cours, le système DOIT afficher une demande de confirmation. Si l'utilisateur confirme, les téléversements en cours DOIVENT être annulés proprement et la fenêtre fermée ; sinon, la fenêtre DOIT rester ouverte et les téléversements se poursuivre. Les fichiers déjà téléversés avec succès restent acquis dans tous les cas.
- **FR-014**: Le champ « URL externe » actuellement présent dans la fenêtre d'ajout DOIT être retiré de l'interface dans le cadre de cette feature. Aucune trace visuelle ne DOIT subsister (champ, bouton, libellé).
- **FR-015**: Les téléversements multi-fichiers DOIVENT être effectués en parallèle avec une limite stricte de 5 téléversements simultanés. Les fichiers au-delà de cette limite DOIVENT être placés en file d'attente et démarrer automatiquement dès qu'un emplacement se libère.

### Key Entities *(include if feature involves data)*

- **Média (existant)** : Fichier individuel (image, vidéo, audio, document) avec ses métadonnées. N'est lié à aucune collection obligatoire — un média peut exister indépendamment de tout album et être associé à zéro, un ou plusieurs albums.
- **Album (existant)** : Collection ordonnée de médias. Utilisé comme regroupement thématique facultatif. L'ajout d'un média à la médiathèque n'implique plus la création ou la sélection d'un album.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% des tentatives d'ajout de fichiers depuis la fenêtre « Ajouter des fichiers » de la médiathèque aboutissent à l'enregistrement effectif des fichiers compatibles — alors qu'aujourd'hui ce taux est de 0%.
- **SC-002**: Un administrateur peut téléverser et voir apparaître jusqu'à 10 fichiers en une seule opération sans avoir à créer ni ouvrir d'album au préalable.
- **SC-003**: Pour tout téléversement multi-fichiers, l'administrateur peut identifier en moins de 5 secondes quels fichiers ont réussi et quels fichiers ont échoué grâce au récapitulatif affiché.
- **SC-004**: Le temps nécessaire pour ajouter un fichier unique à la médiathèque passe de « impossible sans créer un album » à « moins de 15 secondes depuis l'ouverture de la fenêtre ».
- **SC-005**: Aucune régression : tous les parcours existants d'ajout de médias à un album depuis la page d'un album continuent de fonctionner à l'identique.

## Assumptions

- Les capacités de téléversement côté serveur (point d'entrée backend, stockage, génération de variants, types MIME acceptés, taille maximale) existent déjà et sont utilisées avec succès par la page de détail d'un album. Cette fonctionnalité réutilise le même mécanisme côté serveur — aucune modification de l'API ni de la base de données n'est attendue.
- Les permissions pour gérer les médias existent déjà et s'appliquent telles quelles à l'ajout direct.
- Le champ « Ajouter une URL externe » actuellement présent dans la fenêtre est retiré (cf. FR-014). S'il devait revenir un jour, ce serait dans une feature dédiée avec son propre support backend.
- Le stockage direct (sans album) est déjà supporté par le modèle de données : un média est associé à un album via une table de liaison facultative. Aucune migration n'est nécessaire pour permettre l'existence de médias « orphelins » — c'est le comportement natif.
- L'interface d'ajout reprend les composants et conventions visuelles existants du projet (mode sombre, i18n, responsive) sans introduction de nouveau framework ou de nouvelle dépendance.
