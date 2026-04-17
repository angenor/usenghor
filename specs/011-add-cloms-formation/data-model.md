# Data Model: Ajouter le type de formation CLOM

**Feature**: 011-add-cloms-formation
**Date**: 2026-03-24

## Modification du type ENUM existant

### Type `program_type` (PostgreSQL)

**Avant** :
```
ENUM('master', 'doctorate', 'university_diploma', 'certificate')
```

**Après** :
```
ENUM('master', 'doctorate', 'university_diploma', 'certificate', 'clom')
```

### Migration SQL requise

Fichier : `029_add_clom_program_type.sql`

```sql
-- Migration 029 : Ajout du type CLOM à l'énumération program_type
-- IMPORTANT : ALTER TYPE ... ADD VALUE ne peut pas être dans un bloc transactionnel
ALTER TYPE program_type ADD VALUE 'clom';
```

## Entités impactées

### Table `programs` (existante, aucune modification de structure)

La table `programs` utilise déjà la colonne `type program_type NOT NULL` avec un index `idx_programs_type`. L'ajout de la valeur `clom` à l'ENUM permet automatiquement de créer des programmes de type CLOM.

**Colonnes pertinentes** (inchangées) :

| Colonne | Type | Description |
|---------|------|-------------|
| `type` | `program_type NOT NULL` | Type de programme (master, doctorate, university_diploma, certificate, **clom**) |
| `field_id` | `UUID NULL` | Champ disciplinaire — NULL pour les CLOMs (comme masters/doctorats) |

### Comportement du `field_id` pour les CLOMs

Le champ `field_id` est actuellement utilisé uniquement pour les `certificate`. Pour les CLOMs, il reste `NULL` (même comportement que `master` et `doctorate`).

## Modèle Python (SQLAlchemy)

### Enum `ProgramType`

**Avant** :
```python
class ProgramType(str, enum.Enum):
    MASTER = "master"
    DOCTORATE = "doctorate"
    UNIVERSITY_DIPLOMA = "university_diploma"
    CERTIFICATE = "certificate"
```

**Après** :
```python
class ProgramType(str, enum.Enum):
    MASTER = "master"
    DOCTORATE = "doctorate"
    UNIVERSITY_DIPLOMA = "university_diploma"
    CERTIFICATE = "certificate"
    CLOM = "clom"
```

## Type TypeScript (Frontend)

**Avant** :
```typescript
export type ProgramType = 'master' | 'doctorate' | 'university_diploma' | 'certificate'
```

**Après** :
```typescript
export type ProgramType = 'master' | 'doctorate' | 'university_diploma' | 'certificate' | 'clom'
```

## Relations et contraintes

Aucune nouvelle relation ni contrainte. Le type CLOM utilise exactement les mêmes tables de jointure que les autres types :

- `program_campuses` — association programme ↔ campus
- `program_partners` — association programme ↔ partenaires
- `program_career_opportunities` — débouchés
- `program_skills` — compétences visées
- `program_semesters` → `program_courses` — structure académique
- `program_media_library` — médiathèque

## Validation

- Un programme de type `clom` DOIT respecter les mêmes contraintes NOT NULL que les autres types
- Le `field_id` est optionnel (NULL) pour les CLOMs
- Les champs trilingues (`*_fr`, `*_en`, `*_ar`) suivent les mêmes règles de validation
