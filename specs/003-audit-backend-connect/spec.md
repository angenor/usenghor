# Feature Specification: Page d'audit admin connectée au backend

**Feature Branch**: `003-audit-backend-connect`
**Created**: 2026-03-10
**Status**: Draft
**Input**: User description: "Implémenter le contenu de la page audit admin pour qu'elle soit fonctionnelle, connectée au backend"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Consulter le journal d'audit paginé (Priority: P1)

Un administrateur accède à la page d'audit et voit la liste des événements récents (créations, modifications, suppressions, connexions, déconnexions) avec pagination serveur. Chaque ligne affiche la date, l'utilisateur, l'action, la table concernée, un résumé et l'adresse IP.

**Why this priority**: C'est la fonctionnalité principale de la page - sans elle, aucune autre fonctionnalité n'a de sens.

**Independent Test**: Peut être testé en accédant à la page d'audit et en vérifiant que les données proviennent du backend (pas de mock), avec navigation entre les pages.

**Acceptance Scenarios**:

1. **Given** un administrateur authentifié avec la permission `admin.audit`, **When** il accède à la page d'audit, **Then** il voit les 20 derniers événements avec les colonnes date, utilisateur, action, table, résumé et IP.
2. **Given** plus de 20 événements existent, **When** l'administrateur navigue vers la page 2, **Then** les 20 événements suivants s'affichent et le compteur de pages se met à jour.
3. **Given** aucun événement n'existe, **When** l'administrateur accède à la page, **Then** un message "Aucun événement trouvé" s'affiche.

---

### User Story 2 - Filtrer les événements d'audit (Priority: P1)

L'administrateur peut filtrer les événements par recherche textuelle, type d'action, table, utilisateur, plage de dates et adresse IP. Les filtres sont combinables et la liste se met à jour automatiquement.

**Why this priority**: Le filtrage est essentiel pour exploiter un journal d'audit - sans lui, trouver un événement spécifique parmi des centaines est impossible.

**Independent Test**: Peut être testé en appliquant différents filtres et en vérifiant que seuls les résultats correspondants apparaissent.

**Acceptance Scenarios**:

1. **Given** des événements de types variés, **When** l'administrateur sélectionne l'action "Création", **Then** seuls les événements de création s'affichent.
2. **Given** des filtres actifs, **When** l'administrateur clique sur "Réinitialiser", **Then** tous les filtres sont vidés et la liste complète réapparaît.
3. **Given** un filtre par plage de dates, **When** l'administrateur choisit une période, **Then** seuls les événements de cette période s'affichent.

---

### User Story 3 - Voir le détail d'un événement (Priority: P2)

L'administrateur peut cliquer sur un événement pour voir son détail complet dans une modale : informations de l'utilisateur, action, table, ID d'enregistrement, adresse IP, navigateur, résumé, et les modifications champ par champ (avant/après).

**Why this priority**: Le détail est nécessaire pour comprendre précisément ce qui a changé, mais la liste et les filtres sont prioritaires.

**Independent Test**: Peut être testé en cliquant sur un événement de type "modification" et en vérifiant l'affichage des valeurs avant/après.

**Acceptance Scenarios**:

1. **Given** un événement de type "update" dans la liste, **When** l'administrateur clique sur le bouton "Voir le détail", **Then** une modale affiche les modifications champ par champ avec les valeurs avant/après.
2. **Given** un événement de type "login", **When** l'administrateur voit le détail, **Then** la modale affiche un message indiquant un événement de connexion (pas de modifications de champs).
3. **Given** la modale de détail ouverte, **When** l'administrateur clique en dehors ou sur "Fermer", **Then** la modale se ferme.

---

### User Story 4 - Consulter les statistiques d'audit (Priority: P3)

L'administrateur peut afficher un panneau de statistiques montrant le nombre total d'événements, la répartition par type d'action et les tables les plus actives.

**Why this priority**: Les statistiques apportent une vue d'ensemble utile mais non indispensable au fonctionnement de base.

**Independent Test**: Peut être testé en ouvrant le panneau statistiques et en vérifiant la cohérence des chiffres avec les données réelles.

**Acceptance Scenarios**:

1. **Given** des événements existants, **When** l'administrateur clique sur "Statistiques", **Then** le panneau affiche le total, les compteurs par action et les tables les plus actives.
2. **Given** aucun événement, **When** l'administrateur ouvre les statistiques, **Then** tous les compteurs affichent 0 et un message "Aucune donnée" apparaît pour les tables.

---

### Edge Cases

- Que se passe-t-il si l'utilisateur n'a pas la permission `admin.audit` ? L'accès est refusé par le backend (erreur 403).
- Que se passe-t-il si le backend est indisponible ? Un message d'erreur explicite s'affiche à l'utilisateur.
- Que se passe-t-il si un utilisateur référencé dans un log a été supprimé ? L'UUID tronqué s'affiche à la place du nom.
- Que se passe-t-il si les valeurs old_values/new_values sont null ? Le détail affiche "-" ou un message adapté.
- Que se passe-t-il si la recherche ne retourne aucun résultat ? Le tableau affiche "Aucun événement trouvé".

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT charger les événements d'audit depuis le backend avec pagination serveur (20 éléments par page par défaut).
- **FR-002**: Le système DOIT enrichir chaque log avec un résumé lisible et les informations utilisateur disponibles (nom, email).
- **FR-003**: Le système DOIT permettre le filtrage côté serveur par : recherche textuelle, action, table, utilisateur, plage de dates, adresse IP.
- **FR-004**: Le système DOIT recharger les données automatiquement quand un filtre change, en revenant à la page 1.
- **FR-005**: Le système DOIT afficher le détail d'un événement dans une modale avec les modifications champ par champ (comparaison avant/après colorée).
- **FR-006**: Le système DOIT charger et afficher les statistiques d'audit (total, par action, tables les plus actives).
- **FR-007**: Le système DOIT afficher un indicateur de chargement pendant les requêtes et un message d'erreur en cas d'échec.
- **FR-008**: Le système DOIT formater les dates en français, les adresses IP et les user agents de manière lisible.

### Key Entities

- **AuditLog**: Enregistrement d'une action dans le système (action, table, record_id, anciennes/nouvelles valeurs, adresse IP, user agent, utilisateur, horodatage).
- **AuditStatistics**: Agrégation des événements par action, par table, par utilisateur et par jour.
- **User**: Utilisateur associé à un événement (nom, email) - peut être absent si le compte a été supprimé.

## Assumptions

- Le backend est déjà opérationnel avec tous les endpoints d'audit (`/api/admin/audit-logs`, `/api/admin/audit-logs/statistics`, `/api/admin/audit-logs/{log_id}`).
- Le composable `useAuditApi()` fournit déjà toutes les méthodes nécessaires pour appeler le backend.
- Les types TypeScript (`AuditLogRead`, `AuditLogWithUser`, `AuditLogDetail`, etc.) sont déjà définis.
- La page Vue existante contient déjà le template HTML complet - seule la connexion au backend réel est nécessaire.
- L'authentification JWT est gérée par le composable `useApi()` sous-jacent.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'administrateur peut consulter la liste des événements d'audit avec des données réelles du backend en moins de 3 secondes.
- **SC-002**: L'administrateur peut filtrer les événements et obtenir des résultats correspondants en moins de 2 secondes.
- **SC-003**: L'administrateur peut voir le détail complet d'un événement incluant les modifications champ par champ.
- **SC-004**: Les statistiques reflètent fidèlement les données stockées en base de données.
- **SC-005**: La page gère gracieusement les erreurs réseau et les cas limites (données manquantes, utilisateur supprimé).
