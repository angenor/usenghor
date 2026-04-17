# API Contracts: 013-program-partners

**Date**: 2026-03-25

## Endpoints existants (admin - pas de modification)

### GET /api/admin/programs/{program_id}/partners
**Auth**: JWT + `programs.view`
**Response**: `list[ProgramPartnerRead]`

### POST /api/admin/programs/{program_id}/partners
**Auth**: JWT + `programs.edit`
**Body**: `ProgramPartnerCreate` (`partner_external_id: str`, `partnership_type: str | None`)
**Response**: `ProgramPartnerRead`
**Erreurs**: 409 si doublon

### PUT /api/admin/programs/{program_id}/partners/{partner_id}
**Auth**: JWT + `programs.edit`
**Body**: `ProgramPartnerUpdate` (`partnership_type: str | None`)
**Response**: `ProgramPartnerRead`

### DELETE /api/admin/programs/{program_id}/partners/{partner_id}
**Auth**: JWT + `programs.edit`
**Response**: `MessageResponse`

---

## Nouvel endpoint (public)

### GET /api/public/programs/{slug}/partners

**Auth**: Aucune (public)
**Description**: Retourne les partenaires actifs associés à une formation, enrichis avec les détails du partenaire (nom, logo, site web).

**Path params**:
| Param | Type | Description |
|-------|------|-------------|
| slug | string | Slug de la formation |

**Response** (200): `list[ProgramPartnerPublic]`

```json
[
  {
    "partner_external_id": "uuid-string",
    "name": "Université Paris-Saclay",
    "logo_external_id": "uuid-media",
    "website": "https://www.universite-paris-saclay.fr",
    "partner_type": "program_partner",
    "partnership_type": "Co-diplomation"
  }
]
```

**Filtrage**: Seuls les partenaires avec `active = true` sont retournés.

**Erreurs**:
| Code | Description |
|------|-------------|
| 404 | Formation non trouvée (slug invalide) |

---

## Frontend composable methods (nouveaux)

### useProgramsApi() - Ajouts

```typescript
// Lister les partenaires associés à un programme (admin)
listProgramPartners(programId: string): Promise<ProgramPartnerRead[]>

// Ajouter un partenaire à un programme
addPartnerToProgram(programId: string, data: { partner_external_id: string, partnership_type?: string }): Promise<ProgramPartnerRead>

// Retirer un partenaire d'un programme
removePartnerFromProgram(programId: string, partnerExternalId: string): Promise<void>
```

### usePublicProgramsApi() - Ajout

```typescript
// Récupérer les partenaires publics d'une formation
getProgramPartners(slug: string): Promise<ProgramPartnerPublic[]>
```
