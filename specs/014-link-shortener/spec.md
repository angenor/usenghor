# Feature Specification: Réducteur de liens (backoffice admin)

**Feature Branch**: `014-link-shortener`
**Created**: 2026-03-25
**Status**: Draft
**Input**: User description: "Système de réduction de liens dans le backoffice admin avec génération séquentielle en base 36 et préfixe /r/"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Créer un lien réduit (Priority: P1)

Un administrateur souhaite raccourcir un lien long (ex. une URL de page programme ou événement) pour faciliter le partage. Il saisit l'URL longue dans un formulaire, soumet, et le système lui renvoie le lien court correspondant (ex. `/r/a1b2`).

**Why this priority**: C'est la fonctionnalité principale du système. Sans création de liens, rien d'autre n'est utile.

**Independent Test**: Peut être testé en créant un lien réduit et en vérifiant que le code court et le lien complet sont affichés et copiables.

**Acceptance Scenarios**:

1. **Given** un administrateur connecté au backoffice, **When** il saisit une URL valide et soumet le formulaire, **Then** un lien réduit est créé et affiché avec son identifiant court.
2. **Given** un administrateur qui soumet une URL, **When** l'identifiant est généré, **Then** l'identifiant est composé de 1 à 4 caractères parmi [a-z0-9], généré séquentiellement en base 36.
3. **Given** un administrateur qui soumet un lien, **When** le lien réduit est créé, **Then** le lien complet `/r/{code}` est affiché et copiable en un clic.

---

### User Story 2 - Redirection publique via lien réduit (Priority: P1)

N'importe quel visiteur (authentifié ou non) qui accède à `/r/{code}` est automatiquement redirigé vers l'URL de destination correspondante.

**Why this priority**: Sans la redirection publique, les liens réduits n'ont aucune utilité. C'est le coeur du système, au même niveau que la création.

**Independent Test**: Peut être testé en accédant à `/r/{code}` dans un navigateur et en vérifiant la redirection vers l'URL de destination.

**Acceptance Scenarios**:

1. **Given** un lien réduit `/r/a` existant pointant vers `/programmes/master-administration`, **When** un visiteur accède à `/r/a`, **Then** il est redirigé vers `/programmes/master-administration`.
2. **Given** un code inexistant, **When** un visiteur accède à `/r/xyz9`, **Then** une page d'erreur 404 est affichée.

---

### User Story 3 - Visualiser la liste des liens réduits (Priority: P2)

Un administrateur consulte la liste de tous les liens réduits existants, avec pour chacun : le code court, l'URL complète de destination, et la date de création.

**Why this priority**: La gestion et la visibilité des liens existants sont essentielles mais secondaires par rapport à la création et la redirection.

**Independent Test**: Peut être testé en accédant à la page admin et en vérifiant que tous les liens créés y apparaissent avec les bonnes informations.

**Acceptance Scenarios**:

1. **Given** un administrateur connecté au backoffice, **When** il accède à la page de gestion des liens réduits, **Then** il voit la liste de tous les liens avec leur code court, URL de destination et date de création.
2. **Given** aucun lien réduit existant, **When** l'administrateur accède à la page, **Then** un message indiquant qu'aucun lien n'existe est affiché.

---

### User Story 4 - Supprimer un lien réduit (Priority: P3)

Un administrateur peut supprimer un lien réduit existant. Une fois supprimé, le code court n'est pas réutilisé (le compteur continue de progresser).

**Why this priority**: La suppression est utile pour le nettoyage mais moins critique que la création et la consultation.

**Independent Test**: Peut être testé en supprimant un lien et en vérifiant que l'accès à `/r/{code}` renvoie une 404.

**Acceptance Scenarios**:

1. **Given** un lien réduit existant, **When** l'administrateur clique sur supprimer et confirme, **Then** le lien est supprimé de la liste.
2. **Given** un lien supprimé, **When** un visiteur accède à l'ancien code `/r/{code}`, **Then** une page 404 est affichée.
3. **Given** un lien supprimé, **When** un nouveau lien est créé, **Then** le compteur séquentiel continue sans réutiliser l'ancien code.

---

### Edge Cases

- Que se passe-t-il si l'URL de destination saisie est vide ou invalide ? Le système refuse la création avec un message d'erreur explicite.
- Que se passe-t-il quand le compteur atteint la capacité maximale (36^4 = 1 679 616) ? Le système affiche un message d'erreur indiquant que la limite est atteinte.
- Que se passe-t-il si l'URL de destination est elle-même un lien réduit (`/r/...`) ? Le système refuse la création pour éviter les boucles de redirection.
- Que se passe-t-il si un administrateur crée un lien vers une URL déjà raccourcie ? Le système crée un nouveau lien (plusieurs codes courts peuvent pointer vers la même URL).
- Que se passe-t-il si l'URL de destination pointe vers un domaine externe non autorisé ? Le système refuse la création avec un message indiquant que seuls les domaines de la liste blanche sont acceptés.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT générer des identifiants courts de 1 à 4 caractères composés exclusivement de lettres minuscules (a-z) et chiffres (0-9).
- **FR-002**: La génération des identifiants DOIT être séquentielle via un compteur interne converti en base 36, garantissant l'unicité sans vérification de doublons.
- **FR-003**: Le système DOIT permettre aux administrateurs authentifiés de créer un lien réduit en saisissant une URL de destination.
- **FR-004**: Le système DOIT valider que l'URL de destination n'est pas vide et qu'elle est au format URL valide avant la création.
- **FR-005**: Le système DOIT rejeter la création de liens pointant vers un lien réduit (`/r/...`) pour éviter les boucles de redirection.
- **FR-013**: Le système DOIT accepter uniquement les URLs internes (chemins relatifs ou même domaine) et les URLs externes appartenant à une liste blanche de domaines autorisés, configurable par les administrateurs.
- **FR-014**: Le système DOIT rejeter avec un message d'erreur explicite toute URL pointant vers un domaine externe non présent dans la liste blanche.
- **FR-006**: Le système DOIT rediriger tout visiteur accédant à `/r/{code}` vers l'URL de destination correspondante (redirection HTTP 302).
- **FR-007**: Le système DOIT afficher une page 404 pour les codes courts inexistants ou supprimés.
- **FR-008**: Le système DOIT permettre aux administrateurs de visualiser la liste complète des liens réduits avec : code court, URL de destination, date de création.
- **FR-009**: Le système DOIT permettre aux administrateurs de supprimer un lien réduit existant avec confirmation préalable.
- **FR-010**: Les codes supprimés NE DOIVENT PAS être réutilisés ; le compteur séquentiel continue de progresser.
- **FR-011**: Le système DOIT permettre de copier le lien réduit complet en un clic depuis l'interface admin, au format URL absolue (ex. `https://usenghor-francophonie.org/r/x8ss`).
- **FR-012**: Le système DOIT afficher un message d'erreur lorsque la capacité maximale de 1 679 616 liens est atteinte.

### Key Entities

- **Lien réduit (Short Link)**: Association entre un code court unique et une URL de destination. Attributs clés : code court, URL de destination, date de création, administrateur créateur.
- **Compteur séquentiel**: Valeur entière auto-incrémentée utilisée pour générer le prochain code court en base 36. Persiste indépendamment des suppressions de liens.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Un administrateur peut créer un lien réduit en moins de 10 secondes (saisie de l'URL + clic).
- **SC-002**: La redirection d'un lien réduit s'effectue instantanément (moins de 1 seconde perçue par l'utilisateur).
- **SC-003**: 100% des codes générés sont uniques et ne contiennent que des caractères autorisés [a-z0-9].
- **SC-004**: La liste des liens réduits s'affiche en moins de 2 secondes, même avec plusieurs milliers de liens.
- **SC-005**: La suppression d'un lien rend immédiatement le code inaccessible (redirection cesse).

## Clarifications

### Session 2026-03-25

- Q: Les URLs externes sont-elles autorisées et comment gérer le risque d'open redirect ? → A: URLs internes + liste blanche de domaines externes autorisés (configurable par les admins).
- Q: Quel format pour le lien copié dans le presse-papier ? → A: URL absolue avec le domaine de production (`https://usenghor-francophonie.org/r/{code}`).

## Assumptions

- Seuls les administrateurs authentifiés peuvent créer, visualiser et supprimer des liens réduits. La redirection publique est accessible sans authentification.
- Les URLs de destination peuvent être internes (chemins relatifs ou même domaine) ou externes si le domaine figure dans une liste blanche configurable (protection contre l'open redirect).
- Il n'y a pas de date d'expiration automatique des liens. Ils restent actifs jusqu'à suppression manuelle.
- Aucun compteur de clics ou statistique de visite n'est requis pour cette première version.
- Plusieurs liens réduits peuvent pointer vers la même URL de destination.

## Scope Boundaries

### Inclus

- Création, consultation et suppression de liens réduits (CRUD sans modification).
- Génération séquentielle d'identifiants en base 36.
- Redirection publique via `/r/{code}`.
- Interface admin dans le backoffice existant.

### Exclus

- Modification d'un lien réduit existant (changer l'URL de destination).
- Statistiques de clics / analytics.
- Personnalisation du code court (choix manuel).
- Expiration automatique des liens.
- QR codes associés aux liens réduits.
