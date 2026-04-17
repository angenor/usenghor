# Feature Specification: Ajouter le type de formation CLOM

**Feature Branch**: `011-add-cloms-formation`
**Created**: 2026-03-24
**Status**: Draft
**Input**: User description: "parmi les formations, ajouter un autre type de formation appelé Cloms"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Consultation publique des CLOMs (Priority: P1)

Un visiteur du site souhaite découvrir les formations de type CLOM (Cours en Ligne Ouvert et Massif) proposées par l'Université Senghor. Il accède à la page dédiée via le menu formations ou un lien direct, consulte la liste des CLOMs disponibles, et peut filtrer par campus, durée ou autres critères existants.

**Why this priority** : C'est la fonctionnalité principale — rendre les CLOMs visibles et accessibles au public. Sans cela, le nouveau type de formation n'a aucune utilité.

**Independent Test** : Naviguer vers `/formations/cloms` et vérifier que la page affiche les CLOMs publiés avec leurs informations (titre, description, durée, campus).

**Acceptance Scenarios** :

1. **Given** des CLOMs publiés existent en base, **When** un visiteur accède à `/formations/cloms`, **Then** la liste des CLOMs s'affiche avec leurs informations principales (titre, description, durée, campus).
2. **Given** aucun CLOM publié n'existe, **When** un visiteur accède à `/formations/cloms`, **Then** un message indique qu'aucune formation de ce type n'est disponible.
3. **Given** des CLOMs publiés existent, **When** un visiteur applique un filtre (campus, durée), **Then** seuls les CLOMs correspondant aux critères s'affichent.

---

### User Story 2 - Création et gestion d'un CLOM par un administrateur (Priority: P1)

Un administrateur souhaite créer une nouvelle formation de type CLOM dans le back-office. Il sélectionne le type « CLOM » lors de la création, remplit les champs requis (titre trilingue, description, durée, campus, etc.) et publie la formation. Il peut aussi modifier ou dépublier un CLOM existant.

**Why this priority** : Sans la capacité de créer des CLOMs côté admin, aucun contenu ne peut exister pour la consultation publique. C'est un prérequis fonctionnel.

**Independent Test** : Se connecter à l'interface admin, créer un programme en choisissant le type « CLOM », vérifier qu'il apparaît dans la liste des formations et sur le site public.

**Acceptance Scenarios** :

1. **Given** un administrateur est connecté, **When** il crée un nouveau programme et sélectionne le type « CLOM », **Then** la formation est enregistrée avec le type CLOM et apparaît dans la liste admin.
2. **Given** un CLOM existe en base, **When** l'administrateur le modifie (titre, description, statut de publication), **Then** les modifications sont sauvegardées et reflétées sur le site public.
3. **Given** un administrateur consulte la liste des formations, **When** il filtre par type « CLOM », **Then** seuls les CLOMs s'affichent.

---

### User Story 3 - Navigation et découverte du type CLOM (Priority: P2)

Un visiteur navigue sur le site et découvre le type CLOM dans les menus, filtres et sections dédiées aux formations. Le type CLOM est visuellement distinct (couleur, icône) et intégré de manière cohérente avec les autres types de formations (Master, Doctorat, DU, Certificat).

**Why this priority** : L'intégration dans la navigation et l'identité visuelle améliore l'expérience utilisateur mais n'est pas bloquante pour la fonctionnalité de base.

**Independent Test** : Vérifier que le type CLOM apparaît dans tous les menus, filtres et sélecteurs où les autres types de formation sont affichés, avec une couleur et une icône distinctes.

**Acceptance Scenarios** :

1. **Given** un visiteur est sur la page des formations, **When** il consulte les filtres par type, **Then** « CLOM » apparaît parmi les options disponibles.
2. **Given** le site est affiché en anglais ou en arabe, **When** le type CLOM est affiché, **Then** le libellé est correctement traduit dans la langue active.

---

### User Story 4 - Support trilingue du type CLOM (Priority: P2)

Les libellés, descriptions et contenus associés aux CLOMs sont disponibles dans les trois langues du site (français, anglais, arabe). L'affichage en arabe respecte la direction RTL.

**Why this priority** : Le site est trilingue par conception. Le support des trois langues est nécessaire pour la cohérence globale.

**Independent Test** : Basculer la langue du site en anglais puis en arabe et vérifier que le libellé du type CLOM et les contenus associés s'affichent correctement.

**Acceptance Scenarios** :

1. **Given** le site est en français, **When** le type CLOM est affiché, **Then** il apparaît comme « CLOM » (ou « Cours en Ligne Ouvert et Massif »).
2. **Given** le site est en anglais, **When** le type CLOM est affiché, **Then** il apparaît comme « MOOC » (ou « Massive Open Online Course »).
3. **Given** le site est en arabe, **When** le type CLOM est affiché, **Then** il apparaît avec le libellé arabe approprié en direction RTL.

---

### Edge Cases

- Que se passe-t-il si un administrateur essaie de changer le type d'une formation existante vers CLOM ou depuis CLOM vers un autre type ? Le comportement doit être identique à celui des autres types.
- Comment le système gère-t-il l'URL `/formations/cloms` si le slug est déjà utilisé par un autre contenu ? Le slug doit être réservé comme pour les autres types.
- Que se passe-t-il si les traductions CLOM ne sont pas encore renseignées pour une langue ? Le système utilise le fallback standard (français par défaut).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001** : Le système DOIT proposer « CLOM » comme cinquième type de formation, aux côtés de Master, Doctorat, Diplôme d'Université et Certificat.
- **FR-002** : Le système DOIT permettre aux administrateurs de créer, modifier, publier et dépublier des formations de type CLOM via l'interface d'administration existante.
- **FR-003** : Le système DOIT afficher les CLOMs sur une page publique dédiée accessible via l'URL `/formations/cloms`.
- **FR-004** : Le système DOIT permettre le filtrage par type CLOM dans toutes les interfaces de listing (admin et public).
- **FR-005** : Le système DOIT fournir les libellés du type CLOM dans les trois langues supportées (français, anglais, arabe).
- **FR-006** : Le système DOIT attribuer au type CLOM une identité visuelle distincte (couleur, icône) cohérente avec le design existant des autres types.
- **FR-007** : Le système DOIT intégrer le type CLOM dans l'endpoint API public existant de filtrage par type (`/api/public/programs/by-type/{program_type}`).
- **FR-008** : Un CLOM DOIT supporter tous les champs existants des formations (titre trilingue, description, durée, campus, compétences, débouchés, semestres, cours, partenaires).

### Key Entities

- **Programme (type CLOM)** : Nouvelle valeur de l'énumération existante `program_type`. Représente un Cours en Ligne Ouvert et Massif. Partage la même structure de données que les autres types de formation (champs trilingues, durée, campus, semestres, cours, compétences, débouchés, partenaires, médiathèque).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001** : Un administrateur peut créer un CLOM et le voir apparaître sur le site public en moins de 5 minutes.
- **SC-002** : La page `/formations/cloms` affiche correctement les CLOMs publiés dans les trois langues.
- **SC-003** : Le filtrage par type CLOM fonctionne sur toutes les interfaces (admin, public, API) de manière identique aux quatre autres types existants.
- **SC-004** : Le type CLOM est visuellement identifiable grâce à une couleur et une icône distinctes dans toutes les vues.
- **SC-005** : 100 % des libellés liés au type CLOM sont traduits en français, anglais et arabe.

## Assumptions

- **CLOM** correspond à « Cours en Ligne Ouvert et Massif » (équivalent français de MOOC). Le terme « CLOM » est utilisé en français, « MOOC » en anglais.
- Le type CLOM partage la même structure de données que les autres types de formation. Aucun champ spécifique supplémentaire n'est requis pour cette itération.
- Le champ `field_id` (champ disciplinaire), actuellement utilisé uniquement pour les certificats, n'est pas requis pour les CLOMs (comportement identique aux Masters et Doctorats).
- La migration de la base de données nécessite l'ajout de la valeur `'clom'` à l'ENUM `program_type` existant.
- Le slug URL pour les CLOMs en français est `cloms` (pluriel, cohérent avec `masters`, `doctorat`, `diplomes-universitaires`, `certifiantes`).
