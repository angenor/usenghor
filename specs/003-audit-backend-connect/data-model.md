# Data Model: Page d'audit admin

**Date**: 2026-03-10

## Entités existantes (pas de modification de schéma)

### audit_logs (existante)

| Champ | Type | Description |
|-------|------|-------------|
| id | UUID (PK) | Identifiant unique |
| user_id | UUID (nullable) | Référence vers l'utilisateur (pas de FK) |
| action | VARCHAR(50) | Type d'action : create, update, delete, login, logout |
| table_name | VARCHAR(100) | Nom de la table affectée |
| record_id | UUID | ID de l'enregistrement affecté |
| old_values | JSONB | Valeurs avant modification |
| new_values | JSONB | Valeurs après modification |
| ip_address | INET | Adresse IP du client |
| user_agent | TEXT | User agent du navigateur |
| created_at | TIMESTAMPTZ | Horodatage de l'événement |

### users (existante, utilisée en jointure)

| Champ utilisé | Type | Description |
|----------------|------|-------------|
| id | UUID (PK) | Identifiant de l'utilisateur |
| name | VARCHAR | Nom complet |
| email | VARCHAR | Adresse email |

## Modifications API (schémas Pydantic)

### Nouveau schéma : AuditLogUserInfo

```python
class AuditLogUserInfo(BaseModel):
    id: str
    name: str
    email: str
```

### Nouveau schéma : AuditLogReadWithUser

Étend `AuditLogRead` avec un champ `user` optionnel pour la liste paginée.

```python
class AuditLogReadWithUser(AuditLogRead):
    user: AuditLogUserInfo | None = None
```

## Relations

- `audit_logs.user_id` → `users.id` (LEFT JOIN, pas de FK en base pour permettre la suppression d'utilisateurs sans perdre l'historique d'audit)

## Flux de données

```
Frontend (page)          Composable             Backend API              Database
───────────────          ──────────             ───────────              ────────
loadData()          →    listAuditLogs()   →    GET /audit-logs     →   SELECT audit_logs
                                                                         LEFT JOIN users
                    ←    enrichLog()       ←    PaginatedResponse   ←   audit_logs + user info
                         (ajoute summary)       <AuditLogReadWithUser>

loadStatistics()    →    getAuditStatistics() → GET /statistics     →   Agrégations SQL
                    ←    statsToUI()       ←    AuditLogStatistics  ←   COUNT GROUP BY

viewLogDetail()     →    getAuditLogById() →    GET /{log_id}       →   SELECT audit_logs
                    ←    enrichLogDetail() ←    AuditLogRead        ←   audit_log record
                         (ajoute changes)
```
