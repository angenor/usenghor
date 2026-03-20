# Data Model: 008-survey-campaigns

**Date**: 2026-03-20 | **Branch**: `008-survey-campaigns`

## Nouveau type ENUM

### `survey_campaign_status`

```sql
CREATE TYPE survey_campaign_status AS ENUM ('draft', 'active', 'paused', 'closed');
```

Python mirror :
```python
class SurveyCampaignStatus(str, enum.Enum):
    DRAFT = "draft"
    ACTIVE = "active"
    PAUSED = "paused"
    CLOSED = "closed"
```

## Tables

### `survey_campaigns`

Campagne de sondage/formulaire. Appartient à un utilisateur créateur.

| Colonne | Type | Contraintes | Description |
|---------|------|-------------|-------------|
| `id` | `UUID` | PK, default uuid_generate_v4() | Identifiant unique |
| `slug` | `VARCHAR(100)` | UNIQUE, NOT NULL, INDEX | Identifiant URL-friendly pour le lien public |
| `title_fr` | `VARCHAR(255)` | NOT NULL | Titre en français |
| `title_en` | `VARCHAR(255)` | | Titre en anglais |
| `title_ar` | `VARCHAR(255)` | | Titre en arabe |
| `description_fr` | `TEXT` | | Description en français |
| `description_en` | `TEXT` | | Description en anglais |
| `description_ar` | `TEXT` | | Description en arabe |
| `survey_json` | `JSONB` | NOT NULL, DEFAULT '{}' | Définition du formulaire au format SurveyJS |
| `status` | `survey_campaign_status` | NOT NULL, DEFAULT 'draft' | Statut du cycle de vie |
| `confirmation_email_enabled` | `BOOLEAN` | NOT NULL, DEFAULT false | Email de confirmation au répondant |
| `closes_at` | `TIMESTAMPTZ` | | Date de clôture automatique |
| `created_by` | `UUID` | NOT NULL, FK → users(id) | Utilisateur créateur |
| `created_at` | `TIMESTAMPTZ` | NOT NULL, DEFAULT now() | Date de création |
| `updated_at` | `TIMESTAMPTZ` | NOT NULL, DEFAULT now() | Date de mise à jour |

**Index** : `idx_survey_campaigns_created_by` sur `created_by` (filtrage par gestionnaire).
**Index** : `idx_survey_campaigns_status` sur `status`.

**Transitions d'état** :
```
draft → active      (publication)
active → paused     (mise en pause)
active → closed     (clôture manuelle ou automatique)
paused → active     (reprise)
paused → closed     (clôture)
closed → (terminal) (pas de retour possible)
```

### `survey_responses`

Soumission individuelle d'un répondant.

| Colonne | Type | Contraintes | Description |
|---------|------|-------------|-------------|
| `id` | `UUID` | PK, default uuid_generate_v4() | Identifiant unique |
| `campaign_id` | `UUID` | NOT NULL, FK → survey_campaigns(id) ON DELETE CASCADE | Campagne associée |
| `response_data` | `JSONB` | NOT NULL | Données de réponse `{ questionName: value }` |
| `ip_address` | `INET` | | Adresse IP du répondant (rate limiting) |
| `session_id` | `VARCHAR(64)` | | Identifiant de session (dédoublonnage) |
| `submitted_at` | `TIMESTAMPTZ` | NOT NULL, DEFAULT now() | Date de soumission |

**Index** : `idx_survey_responses_campaign_id` sur `campaign_id`.
**Index** : `idx_survey_responses_ip_address` sur `ip_address` (rate limiting).
**Contrainte unique** : `uq_survey_responses_session` sur `(campaign_id, session_id)` pour empêcher les doublons par session.

### `survey_associations`

Lien polymorphe entre une campagne et un élément du site.

| Colonne | Type | Contraintes | Description |
|---------|------|-------------|-------------|
| `id` | `UUID` | PK, default uuid_generate_v4() | Identifiant unique |
| `campaign_id` | `UUID` | NOT NULL, FK → survey_campaigns(id) ON DELETE CASCADE | Campagne |
| `entity_type` | `VARCHAR(50)` | NOT NULL | Type d'entité cible (`event`, `application_call`, `program`) |
| `entity_id` | `UUID` | NOT NULL | Identifiant de l'entité cible |
| `created_at` | `TIMESTAMPTZ` | NOT NULL, DEFAULT now() | Date de création |

**Contrainte unique** : `uq_survey_associations` sur `(campaign_id, entity_type, entity_id)`.
**Index** : `idx_survey_associations_entity` sur `(entity_type, entity_id)` (recherche inverse : quelles campagnes sont liées à cet événement ?).

## Relations

```
users (1) ──────── (N) survey_campaigns     (created_by)
survey_campaigns (1) ── (N) survey_responses    (campaign_id, CASCADE)
survey_campaigns (1) ── (N) survey_associations (campaign_id, CASCADE)
```

## Permission

Ajout dans `99_data_init.sql` :

```sql
INSERT INTO permissions (id, code, name_fr, name_en, name_ar, description, category)
VALUES (
    uuid_generate_v4(),
    'survey.manage',
    'Gérer les campagnes de sondage',
    'Manage survey campaigns',
    'إدارة حملات الاستبيان',
    'Créer, modifier, supprimer et consulter les campagnes de sondage et leurs réponses',
    'survey'
);
```

## Vue agrégée (optionnelle)

```sql
CREATE OR REPLACE VIEW v_survey_campaigns_with_stats AS
SELECT
    sc.*,
    COUNT(sr.id) AS response_count,
    MAX(sr.submitted_at) AS last_response_at
FROM survey_campaigns sc
LEFT JOIN survey_responses sr ON sr.campaign_id = sc.id
GROUP BY sc.id;
```

## Fichier SQL

Nouveau fichier : `13_survey.sql` (ajouté dans `main.sql` via `\i`).
Migration : `usenghor_backend/documentation/modele_de_données/migrations/009_survey_campaigns.sql`.
