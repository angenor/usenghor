# Research: Page d'audit admin connectée au backend

**Date**: 2026-03-10

## R1: Pagination count avec filtres

**Decision**: Modifier `paginate()` pour compter les enregistrements en utilisant la requête filtrée au lieu de compter toute la table.

**Rationale**: La fonction actuelle utilise `select(func.count()).select_from(model_class)` qui ignore les filtres. Avec des filtres actifs, le total affiché sera incorrect (ex: filtre "create" montre 5 résultats mais le total affiche 500). La solution standard SQLAlchemy est d'utiliser `select(func.count()).select_from(query.subquery())`.

**Alternatives considered**:
- Passer les filtres séparément à `paginate()` : trop invasif, nécessite de modifier toutes les signatures
- Utiliser `.with_only_columns(func.count())` : peut avoir des effets de bord avec les jointures
- **Retenu** : `select(func.count()).select_from(query.subquery())` — approche standard, pas de modification d'API

## R2: Enrichissement des logs avec données utilisateur

**Decision**: Modifier le endpoint `list_audit_logs` pour faire un LEFT JOIN avec la table `users` et inclure les informations utilisateur (nom, email) dans la réponse.

**Rationale**: Le frontend affiche `log.user.name` dans le template. Sans jointure, seul l'UUID tronqué est visible. La jointure est préférable au chargement côté frontend (N+1 requêtes, complexité).

**Alternatives considered**:
- Charger les utilisateurs côté frontend via un second appel API : crée des appels N+1, complexe
- Ajouter un champ `user` au schéma `AuditLogRead` : nécessite une modification du schéma Pydantic
- Créer un nouveau schéma `AuditLogReadWithUser` pour la liste : séparation propre des responsabilités
- **Retenu** : Nouveau schéma `AuditLogReadWithUser` avec `user` optionnel, endpoint de liste utilise ce schéma

## R3: Données de test (seed)

**Decision**: Utiliser le script de seed existant (`usenghor_backend/scripts/seed_audit_logs.py`) pour peupler la base de données avec des données de test réalistes.

**Rationale**: Le script existe déjà avec 40+ entrées réalistes. Il suffit de l'exécuter.

**Alternatives considered**:
- Créer des données manuellement via l'interface d'admin : trop lent
- Utiliser un fichier SQL : le script Python est plus flexible avec les UUIDs et dates aléatoires
