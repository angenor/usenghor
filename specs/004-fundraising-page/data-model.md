# Data Model: Page Levée de Fonds

**Feature Branch**: `004-fundraising-page`
**Date**: 2026-03-17

## Entities

### Fundraiser (Levée de fonds)

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | UUID | PK, auto-generated | Identifiant unique |
| title | VARCHAR(255) | NOT NULL | Titre (FR par défaut) |
| slug | VARCHAR(255) | UNIQUE, NOT NULL | URL-friendly identifier |
| description_html | TEXT | nullable | Description enrichie (HTML, rendu public) |
| description_md | TEXT | nullable | Description enrichie (Markdown, édition) |
| description_en_html | TEXT | nullable | Description EN (HTML) |
| description_en_md | TEXT | nullable | Description EN (Markdown) |
| description_ar_html | TEXT | nullable | Description AR (HTML) |
| description_ar_md | TEXT | nullable | Description AR (Markdown) |
| cover_image_external_id | UUID | nullable | Référence média (image de couverture) |
| goal_amount | DECIMAL(15,2) | NOT NULL | Objectif financier en EUR |
| status | fundraiser_status | DEFAULT 'draft' | brouillon / en cours / terminée |
| created_at | TIMESTAMPTZ | DEFAULT NOW() | Date de création |
| updated_at | TIMESTAMPTZ | DEFAULT NOW() | Date de modification |

**State Transitions**:
```
draft → active (publication par l'admin)
active → completed (clôture par l'admin)
completed → active (réouverture possible)
```

**Validation Rules**:
- `title` : min 1, max 255 caractères
- `slug` : auto-généré depuis le titre, unique
- `goal_amount` : > 0
- `status` : valeur parmi l'ENUM `fundraiser_status`

---

### FundraiserContributor (Contributeur)

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | UUID | PK, auto-generated | Identifiant unique |
| fundraiser_id | UUID | FK → fundraisers(id) ON DELETE CASCADE, NOT NULL | Levée de fonds associée |
| name | VARCHAR(255) | NOT NULL | Nom du contributeur (FR) |
| name_en | VARCHAR(255) | nullable | Nom EN |
| name_ar | VARCHAR(255) | nullable | Nom AR |
| category | contributor_category | NOT NULL | Catégorie du contributeur |
| amount | DECIMAL(15,2) | NOT NULL, DEFAULT 0 | Montant de la contribution (EUR) |
| logo_external_id | UUID | nullable | Référence média (logo optionnel) |
| display_order | INT | DEFAULT 0 | Ordre d'affichage dans la catégorie |
| created_at | TIMESTAMPTZ | DEFAULT NOW() | Date de création |
| updated_at | TIMESTAMPTZ | DEFAULT NOW() | Date de modification |

**Validation Rules**:
- `name` : min 1, max 255 caractères
- `amount` : >= 0 (0 = contribution non monétaire)
- `category` : valeur parmi `state_organization`, `foundation_philanthropist`, `company`

---

### FundraiserNews (Association Actualité-Levée de fonds)

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| fundraiser_id | UUID | FK → fundraisers(id) ON DELETE CASCADE | Levée de fonds |
| news_id | UUID | NOT NULL | Référence actualité (external_id, pas de FK) |
| display_order | INT | DEFAULT 0 | Ordre d'affichage |
| created_at | TIMESTAMPTZ | DEFAULT NOW() | Date d'association |

**PK**: (fundraiser_id, news_id)

**Validation Rules**:
- Unicité du couple (fundraiser_id, news_id)
- `news_id` doit correspondre à une actualité existante et publiée (vérifié côté applicatif)

---

## ENUM Types

### fundraiser_status
```
'draft'     → Brouillon (non visible côté public)
'active'    → En cours (visible côté public, campagne active)
'completed' → Terminée (visible côté public, campagne clôturée)
```

### contributor_category
```
'state_organization'        → États et organisations internationales
'foundation_philanthropist' → Fondations et philanthropes
'company'                   → Entreprises
```

---

## Computed Values

### total_raised (Somme totale levée)

Calculée dynamiquement : `SUM(fundraiser_contributors.amount) WHERE fundraiser_id = X`

Exposée via :
- Vue SQL ou sous-requête dans le service backend
- Champ calculé dans le schema Pydantic de réponse

### progress_percentage (Pourcentage de progression)

Calculé : `(total_raised / goal_amount) * 100`

Exposé uniquement dans le schema de réponse (pas stocké).

---

## Relationships

```
Fundraiser 1 ──── N FundraiserContributor
Fundraiser N ──── N News (via FundraiserNews junction table)
Fundraiser ──── 1 Media (cover_image, via external_id)
FundraiserContributor ──── 1 Media (logo, via external_id)
```
