# Data Model: 013-program-partners

**Date**: 2026-03-25

## Entités existantes (pas de modification)

### partners (table existante)
| Champ | Type | Description |
|-------|------|-------------|
| id | VARCHAR (PK) | Identifiant interne |
| external_id | UUID | Identifiant public |
| name | VARCHAR | Nom du partenaire |
| logo_external_id | UUID | Référence média du logo |
| website | VARCHAR | URL du site web |
| type | ENUM | charter_operator, campus_partner, program_partner, project_partner, other |
| active | BOOLEAN | Statut actif/inactif |
| display_order | INT | Ordre d'affichage |

### program_partners (table de jonction existante)
| Champ | Type | Description |
|-------|------|-------------|
| program_id | VARCHAR (FK → programs.id) | Formation associée |
| partner_external_id | VARCHAR | UUID du partenaire |
| partnership_type | VARCHAR(100) | Type de partenariat (optionnel) |

**Clé primaire** : (program_id, partner_external_id)
**Cascade** : DELETE sur program_id

## Nouveaux schémas Pydantic

### ProgramPartnerPublic (nouveau)
Schema pour l'endpoint public, enrichi avec les détails du partenaire.

| Champ | Type | Source |
|-------|------|--------|
| partner_external_id | str | program_partners.partner_external_id |
| name | str | partners.name |
| logo_external_id | str | None | partners.logo_external_id |
| website | str | None | partners.website |
| partner_type | str | partners.type |
| partnership_type | str | None | program_partners.partnership_type |

## Relations

```
Program (1) ←→ (N) ProgramPartner (N) ←→ (1) Partner
```

- Une formation peut avoir 0..N partenaires
- Un partenaire peut être associé à 0..N formations
- L'association porte un type de partenariat optionnel

## Règles de validation

- Un même partenaire ne peut être associé qu'une fois à une formation (contrainte PK)
- Seuls les partenaires actifs (`active = true`) sont retournés par l'endpoint public
- Le `partnership_type` est limité à 100 caractères

## Aucune migration requise

Les tables et colonnes nécessaires existent déjà. Seuls des ajouts côté code (schema Pydantic, endpoint, service enrichi) sont nécessaires.
