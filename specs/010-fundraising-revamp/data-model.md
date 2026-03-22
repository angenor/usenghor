# Data Model: Refonte Page Levée de Fonds

**Branch**: `010-fundraising-revamp` | **Date**: 2026-03-22

## Entités existantes à modifier

### fundraiser_contributors (modification)

Ajout d'un champ :

| Champ | Type | Défaut | Description |
|-------|------|--------|-------------|
| `show_amount_publicly` | BOOLEAN | FALSE | Consentement à l'affichage public du montant |

## Nouvelles entités

### fundraiser_interest_expressions

Enregistrement d'un visiteur manifestant son intérêt pour contribuer à une campagne.

| Champ | Type | Contraintes | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PK, DEFAULT uuid_generate_v4() | Identifiant unique |
| `fundraiser_id` | UUID | FK → fundraisers(id) CASCADE, NOT NULL | Campagne associée |
| `full_name` | VARCHAR(255) | NOT NULL | Nom complet du visiteur |
| `email` | VARCHAR(255) | NOT NULL | Email du visiteur |
| `message` | TEXT | NULL | Message optionnel |
| `status` | ENUM('new', 'contacted') | DEFAULT 'new', NOT NULL | Statut de suivi admin |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Date de création |
| `updated_at` | TIMESTAMPTZ | DEFAULT NOW() | Date de dernière mise à jour |

**Contraintes** :
- UNIQUE(email, fundraiser_id) — un seul enregistrement par email par campagne
- Trigger `updated_at` sur modification
- Index sur `fundraiser_id` et `status` pour le filtrage admin

**Transitions d'état** :
- `new` → `contacted` (action admin manuelle)
- `contacted` → `new` (réinitialisation possible)

### fundraiser_editorial_sections

Sections éditoriales de la page principale (raisons, engagements, bénéfices).

| Champ | Type | Contraintes | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PK, DEFAULT uuid_generate_v4() | Identifiant unique |
| `slug` | VARCHAR(100) | UNIQUE, NOT NULL | Identifiant technique (ex: `contribution-reasons`, `engagement-examples`, `contribution-benefits`) |
| `title_fr` | VARCHAR(255) | NOT NULL | Titre de la section en français |
| `title_en` | VARCHAR(255) | NULL | Titre en anglais |
| `title_ar` | VARCHAR(255) | NULL | Titre en arabe |
| `display_order` | INTEGER | DEFAULT 0 | Ordre d'affichage |
| `is_active` | BOOLEAN | DEFAULT TRUE | Activation/désactivation |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Date de création |
| `updated_at` | TIMESTAMPTZ | DEFAULT NOW() | Date de mise à jour |

### fundraiser_editorial_items

Items structurés au sein d'une section éditoriale.

| Champ | Type | Contraintes | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PK, DEFAULT uuid_generate_v4() | Identifiant unique |
| `section_id` | UUID | FK → fundraiser_editorial_sections(id) CASCADE, NOT NULL | Section parente |
| `icon` | VARCHAR(100) | NOT NULL | Nom de l'icône (ex: classe Heroicons ou emoji) |
| `title_fr` | VARCHAR(255) | NOT NULL | Titre court en français |
| `title_en` | VARCHAR(255) | NULL | Titre en anglais |
| `title_ar` | VARCHAR(255) | NULL | Titre en arabe |
| `description_fr` | TEXT | NOT NULL | Description en français |
| `description_en` | TEXT | NULL | Description en anglais |
| `description_ar` | TEXT | NULL | Description en arabe |
| `display_order` | INTEGER | DEFAULT 0 | Ordre d'affichage dans la section |
| `is_active` | BOOLEAN | DEFAULT TRUE | Activation/désactivation |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Date de création |
| `updated_at` | TIMESTAMPTZ | DEFAULT NOW() | Date de mise à jour |

### fundraiser_media

Table de jonction entre campagnes et médias.

| Champ | Type | Contraintes | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PK, DEFAULT uuid_generate_v4() | Identifiant unique |
| `fundraiser_id` | UUID | FK → fundraisers(id) CASCADE, NOT NULL | Campagne associée |
| `media_external_id` | UUID | NOT NULL | Référence au média (table media) |
| `caption_fr` | VARCHAR(500) | NULL | Légende en français |
| `caption_en` | VARCHAR(500) | NULL | Légende en anglais |
| `caption_ar` | VARCHAR(500) | NULL | Légende en arabe |
| `display_order` | INTEGER | DEFAULT 0 | Ordre d'affichage |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Date de création |

**Contraintes** :
- UNIQUE(fundraiser_id, media_external_id) — un média ne peut être associé qu'une fois par campagne
- Index sur `fundraiser_id`

## Relations

```
fundraisers 1──N fundraiser_contributors (existant)
fundraisers 1──N fundraiser_interest_expressions (nouveau)
fundraisers 1──N fundraiser_media (nouveau)
fundraisers N──N news (via fundraiser_news, existant)
fundraiser_editorial_sections 1──N fundraiser_editorial_items (nouveau)
```

## Données initiales (seed)

3 sections éditoriales prédéfinies :
1. `contribution-reasons` — "Votre contribution sert à"
2. `engagement-examples` — "Exemples d'engagement"
3. `contribution-benefits` — "Bénéfices liés à votre contribution"

Chacune avec 3-4 items d'exemple en français (EN/AR à compléter par l'admin).
