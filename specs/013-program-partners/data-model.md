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
| display_order | INT | Ordre d'affichage (ajouté par la migration 041) |

**Clé primaire** : (program_id, partner_external_id)
**Cascade** : DELETE sur program_id
**Index** : `idx_program_partners_program_order (program_id, display_order)`

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
| display_order | int | program_partners.display_order |

## Relations

```
Program (1) ←→ (N) ProgramPartner (N) ←→ (1) Partner
```

- Une formation peut avoir 0..N partenaires
- Un partenaire peut être associé à 0..N formations
- L'association porte un type de partenariat optionnel et un ordre d'affichage

## Règles de validation

- Un même partenaire ne peut être associé qu'une fois à une formation (contrainte PK)
- Seuls les partenaires actifs (`active = true`) sont retournés par l'endpoint public
- Le `partnership_type` est limité à 100 caractères
- Un nouveau partenaire est ajouté en fin de liste (`MAX(display_order) + 1`)

## Migration 041 — ordre d'affichage

La version initiale de cette feature ne nécessitait aucune migration. L'ajout du
réordonnancement des partenaires dans le backoffice a introduit la colonne
`display_order` sur `program_partners` :

- `migrations/041_program_partners_display_order.sql` (+ rollback)
- Initialisation des associations existantes par ordre alphabétique du partenaire
- Tri appliqué côté serveur sur les endpoints admin et public
- Endpoint `PUT /api/admin/programs/{program_id}/partners/reorder` — corps `{ "partner_ids": [...] }`,
  déclaré **avant** `/{program_id}/partners/{partner_id}` pour ne pas être capturé par la route dynamique
