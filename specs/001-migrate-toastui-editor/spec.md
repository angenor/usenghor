# Feature Specification: Migration EditorJS vers TOAST UI Editor

**Feature Branch**: `001-migrate-toastui-editor`
**Created**: 2026-03-08
**Status**: Draft
**Input**: User description: "je veux migrer mon éditeur actuel (EditorJS) vers TOAST UI : Editeur de texte"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Édition de contenu riche dans l'administration (Priority: P1)

Un administrateur se connecte au back-office et accède à une page d'édition de contenu (valeurs éditoriales, programmes, appels à candidatures). Il utilise TOAST UI Editor pour rédiger du contenu avec mise en forme (titres, listes, gras, italique, images, tableaux, liens, citations, blocs de code). L'éditeur offre un mode WYSIWYG et un mode Markdown. Le contenu est sauvegardé et récupéré correctement.

**Why this priority**: C'est le coeur de la migration. Sans l'éditeur fonctionnel en administration, aucune autre fonctionnalité n'est utilisable.

**Independent Test**: Ouvrir une page d'administration contenant l'éditeur, saisir du contenu riche (titres, listes, images, tableaux), sauvegarder, recharger la page et vérifier que le contenu est intact.

**Acceptance Scenarios**:

1. **Given** un administrateur sur la page d'édition des valeurs éditoriales, **When** il saisit du texte avec mise en forme (titres H1-H4, listes ordonnées/non ordonnées, gras, italique), **Then** le contenu est affiché correctement dans l'éditeur et sauvegardé sans perte de formatage.
2. **Given** un administrateur utilisant l'éditeur, **When** il insère une image via upload ou URL, **Then** l'image apparaît dans l'éditeur et est correctement sauvegardée.
3. **Given** un administrateur utilisant l'éditeur, **When** il insère un tableau avec fusion de cellules, **Then** le tableau est affiché et sauvegardé avec la structure correcte.
4. **Given** un administrateur utilisant l'éditeur, **When** il bascule entre le mode WYSIWYG et le mode Markdown, **Then** le contenu est conservé sans perte lors du changement de mode.

---

### User Story 2 - Affichage du contenu TOAST UI sur les pages publiques (Priority: P1)

Un visiteur accède à une page publique du site (page de valeurs, programme, appel à candidatures). Le contenu rédigé via TOAST UI Editor est correctement rendu en HTML avec le bon style visuel, le support du dark mode et le traitement des liens externes.

**Why this priority**: L'affichage public est indissociable de l'édition. Les deux doivent fonctionner ensemble pour que la migration soit complète.

**Independent Test**: Créer du contenu via l'éditeur admin, puis vérifier son rendu sur la page publique correspondante en mode clair et sombre.

**Acceptance Scenarios**:

1. **Given** du contenu créé via TOAST UI Editor et sauvegardé, **When** un visiteur accède à la page publique, **Then** le contenu est rendu fidèlement avec la mise en forme correcte (titres, listes, tableaux, images, citations).
2. **Given** du contenu contenant des liens externes, **When** il est affiché sur la page publique, **Then** les liens s'ouvrent dans un nouvel onglet avec les attributs de sécurité appropriés.
3. **Given** un visiteur en mode sombre, **When** il consulte une page avec du contenu riche, **Then** le contenu est correctement stylisé pour le dark mode.

---

### User Story 3 - Support multilingue de l'éditeur (Priority: P1)

Un administrateur édite du contenu trilingue (français, anglais, arabe). L'éditeur supporte les trois langues avec des onglets de sélection. Pour le contenu en arabe, l'éditeur s'adapte au mode RTL (droite à gauche).

**Why this priority**: Le site est trilingue par conception. La migration doit maintenir cette capacité sans régression.

**Independent Test**: Éditer du contenu dans les trois langues, vérifier que l'éditeur bascule correctement entre LTR et RTL pour l'arabe.

**Acceptance Scenarios**:

1. **Given** un administrateur sur un formulaire multilingue, **When** il sélectionne l'onglet arabe, **Then** l'éditeur passe en mode RTL avec la direction de texte de droite à gauche.
2. **Given** du contenu saisi en trois langues, **When** l'administrateur sauvegarde et recharge, **Then** chaque version linguistique est correctement conservée et restituée.

---

### User Story 4 - Migration des contenus existants (Priority: P2)

Les contenus existants créés avec EditorJS (format JSON OutputData) sont convertis pour être compatibles avec TOAST UI Editor. La migration doit être transparente : aucun contenu existant ne doit être perdu ou mal formaté après la migration.

**Why this priority**: Le site est en production avec des contenus existants. Sans migration des données, le nouveau éditeur ne pourra pas afficher correctement l'historique.

**Independent Test**: Prendre un échantillon de contenus EditorJS existants en base de données, exécuter la migration, et vérifier que chaque type de bloc (paragraphe, titre, liste, image, tableau, citation, embed, délimiteur) est correctement converti.

**Acceptance Scenarios**:

1. **Given** un contenu EditorJS avec des blocs paragraphe, titre, et liste, **When** la migration est exécutée, **Then** le contenu est converti au format TOAST UI Editor sans perte de formatage.
2. **Given** un contenu EditorJS avec un tableau utilisant la fusion de cellules (MergeTable), **When** la migration est exécutée, **Then** le tableau est converti avec la structure de fusion préservée.
3. **Given** un contenu EditorJS avec des images et des embeds (YouTube, Vimeo), **When** la migration est exécutée, **Then** les médias sont correctement référencés dans le nouveau format.
4. **Given** un contenu EditorJS avec des listes imbriquées (format v2), **When** la migration est exécutée, **Then** la hiérarchie d'imbrication est préservée dans le format converti.

---

### User Story 5 - Suppression complète d'EditorJS (Priority: P3)

Après validation de la migration, toutes les dépendances EditorJS sont supprimées du projet : composants Vue, composables, plugins personnalisés (MergeTable), types TypeScript, et paquets npm.

**Why this priority**: Le nettoyage vient après la validation fonctionnelle. Il réduit la dette technique mais n'apporte pas de valeur utilisateur directe.

**Independent Test**: Vérifier qu'aucune référence à EditorJS ne subsiste dans le code source et que le build de production réussit sans erreur.

**Acceptance Scenarios**:

1. **Given** la migration complétée et validée, **When** les dépendances EditorJS sont supprimées, **Then** le projet compile sans erreur et aucune page ne fait référence à EditorJS.
2. **Given** les fichiers EditorJS supprimés, **When** un build de production est lancé, **Then** la taille du bundle est réduite par rapport à la version avec EditorJS.

---

### Edge Cases

- Que se passe-t-il si un contenu EditorJS contient un type de bloc non supporté par TOAST UI Editor (ex: checklist custom) ? → Converti vers l'équivalent le plus proche (checklist → liste à puces, MergeTable → tableau HTML standard, embeds → iframe).
- Comment gérer un contenu EditorJS corrompu ou avec un JSON invalide lors de la migration ?
- Que se passe-t-il si l'upload d'image échoue pendant l'édition (timeout, fichier trop volumineux) ?
- Comment l'éditeur se comporte-t-il sur mobile ou tablette en mode tactile ?
- Que se passe-t-il si un administrateur édite du contenu pendant l'exécution de la migration des données existantes ?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT remplacer le composant `EditorJS.vue` par un nouveau composant utilisant TOAST UI Editor avec les mêmes capacités d'édition (titres H1-H4, listes, images, tableaux, citations, embeds, délimiteurs, liens, code inline, surlignage).
- **FR-002**: Le système DOIT fournir un composant de rendu (remplacement de `EditorJSRenderer.vue`) capable d'afficher le contenu produit par TOAST UI Editor sur les pages publiques avec support du dark mode.
- **FR-003**: Le composant wrapper admin (`RichTextEditor.vue`) DOIT conserver le support multilingue avec onglets FR/EN/AR et le passage automatique en mode RTL pour l'arabe.
- **FR-004**: Le système DOIT fournir un mécanisme de migration des contenus existants du format EditorJS OutputData (JSON avec blocs typés) vers le format TOAST UI Editor (HTML ou Markdown).
- **FR-005**: La migration des données DOIT couvrir tous les types de blocs utilisés : paragraph, header, list (nested v2), image, quote, embed (→ iframe HTML), table (MergeTable → tableau standard sans fusion), delimiter, checklist (→ liste à puces), linkTool, inlineCode, marker.
- **FR-006**: Le composable `useEditorJS.ts` DOIT être remplacé par un équivalent adapté au format de données de TOAST UI Editor, en conservant les méthodes `setContent`, `clearContent`, `hasContent`, `getPlainText`, `toJSON`, `fromJSON`.
- **FR-007**: Le système DOIT supporter l'upload d'images via le même mécanisme existant (endpoint backend de gestion des médias).
- **FR-008**: Le système DOIT supporter l'insertion de vidéos embarquées (YouTube, Vimeo) dans l'éditeur.
- **FR-009**: Toutes les pages d'administration utilisant l'éditeur (valeurs éditoriales, programmes, appels à candidatures) DOIVENT fonctionner avec le nouveau composant sans régression.
- **FR-010**: Les liens dans le contenu rendu DOIVENT s'ouvrir dans un nouvel onglet avec les attributs de sécurité appropriés.
- **FR-011**: Après validation complète, toutes les dépendances EditorJS (13 paquets npm, composants, plugin MergeTable, types) DOIVENT être supprimées du projet.
- **FR-012**: Les labels et messages de l'interface de l'éditeur DOIVENT être en français, conformément à la convention du projet.

### Key Entities

- **Contenu éditorial** : Texte riche associé à une page, stocké en base de données. Possède trois versions linguistiques (`*_fr`, `*_en`, `*_ar`). Format de stockage : JSON EditorJS (avant migration) puis double colonne HTML + Markdown par langue (après migration). Le HTML sert au rendu public direct, le Markdown à l'édition et au versionnage.
- **Bloc de contenu** : Unité de contenu dans l'éditeur (paragraphe, titre, liste, image, tableau, etc.). Structure différente entre EditorJS (JSON typé) et TOAST UI (HTML/Markdown).
- **Média** : Image ou vidéo intégrée dans le contenu. Référencé via un identifiant unique et servi par l'endpoint de téléchargement média.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% des pages d'administration utilisant l'éditeur fonctionnent avec TOAST UI Editor sans régression fonctionnelle.
- **SC-002**: 100% des contenus existants en base de données sont migrés et s'affichent correctement sur les pages publiques.
- **SC-003**: Le temps de chargement de l'éditeur reste inférieur à 3 secondes sur une connexion standard.
- **SC-004**: Tous les types de blocs supportés par l'ancienne implémentation (12 types) sont disponibles dans le nouvel éditeur.
- **SC-005**: Le contenu en arabe s'affiche correctement en mode RTL dans l'éditeur et sur les pages publiques.
- **SC-006**: Aucune référence à EditorJS ne subsiste dans le code source après la phase de nettoyage.
- **SC-007**: Le build de production réussit sans erreur après la migration complète.

## Clarifications

### Session 2026-03-08

- Q: Quel format de stockage en base de données pour le contenu TOAST UI ? → A: Les deux (HTML + Markdown) en double colonne pour flexibilité maximale.
- Q: Quelle stratégie de migration des données en production ? → A: Big-bang avec fenêtre de maintenance (backup, script de migration, déploiement, validation en une seule opération).
- Q: Comment gérer les blocs EditorJS sans équivalent natif TOAST UI (checklist, MergeTable, embeds) ? → A: Conversion vers les équivalents les plus proches (checklist → liste à puces, MergeTable → tableau HTML standard, embeds → iframe HTML inline).

## Assumptions

- TOAST UI Editor supporte nativement le mode WYSIWYG et Markdown, ce qui couvre les besoins d'édition actuels.
- Le format de stockage en base de données passera de JSON (OutputData EditorJS) à une double colonne HTML + Markdown par langue (TOAST UI), nécessitant une migration one-shot des données existantes. TOAST UI Editor synchronise nativement les deux formats.
- Les blocs EditorJS sans équivalent natif TOAST UI seront convertis vers les équivalents les plus proches : checklist → liste à puces, MergeTable avec fusion → tableau HTML standard (perte de fusion de cellules), embeds vidéo → iframe HTML inline.
- L'éditeur TOAST UI est compatible avec Nuxt 4 / Vue 3 et le SSR (rendu côté serveur) via un import dynamique côté client.
- Le site étant en production, la migration des données sera réalisée en big-bang lors d'une fenêtre de maintenance planifiée : sauvegarde complète, exécution du script de conversion, déploiement du nouveau code, validation manuelle.
- Les labels de l'interface TOAST UI Editor supportent l'internationalisation pour l'affichage en français.

## Constraints

- Le site est en **production** : la migration doit être planifiée avec une fenêtre de maintenance et une sauvegarde complète de la base de données avant exécution.
- Les conteneurs de production doivent rester opérationnels pendant la préparation. Le déploiement de la migration se fait en une seule opération.
- La convention de nommage des fichiers interdit les accents et caractères spéciaux (problèmes d'encodage SSH/Docker).

## Dependencies

- **TOAST UI Editor** : Paquet npm `@toast-ui/editor` et éventuellement des plugins complémentaires (table, color syntax, etc.).
- **Backend existant** : Les endpoints de gestion des médias et de contenu éditorial restent inchangés côté API. Seul le format de données stocké change.
- **Base de données PostgreSQL** : Script de migration pour convertir les colonnes contenant du JSON EditorJS en HTML/Markdown TOAST UI.
