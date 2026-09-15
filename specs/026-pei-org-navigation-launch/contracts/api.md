# Contrat API — 026

Tous les changements sont **additifs**, sauf un : `SectorPublicWithServices.services` ne contient plus les pôles au premier niveau (FR-005). Aucun endpoint, aucune permission ni aucun en-tête de cache n'est ajouté.

## 1. Schémas (`app/schemas/organization.py`)

```python
LANDING_PATH_RE = r"^/(?!/)(?!(?:en|ar)(?:/|$))(?!r/)[^\s?#]*$"

class ServiceBase(BaseModel):
    ...                                   # existant
    parent_id: str | None = None
    landing_path: str | None = Field(None, max_length=255)
    # field_validator("landing_path", mode="before") : str.strip() ; "" → None ; regex LANDING_PATH_RE sinon 422
    # « La page dédiée doit être un chemin interne du site commençant par / (ex. /entrepreneuriat), sans préfixe de langue »

class ServiceCreate(ServiceBase): ...     # hérite
class ServiceUpdate(BaseModel):           # + parent_id: str | None = None ; landing_path (même validateur)
class ServiceRead(ServiceBase): ...       # expose parent_id, landing_path
class ServiceWithDetails(ServiceRead): ...

class ServicePublic(BaseModel):           # + parent_id: str | None ; landing_path: str | None
class ServiceRelativePublic(BaseModel):   # NOUVEAU — from_attributes
    id: str; name: str; name_en: str | None; name_ar: str | None
    sigle: str | None; color: str | None; landing_path: str | None; display_order: int
class ServicePublicWithChildren(ServicePublic):   # NOUVEAU
    children: list[ServicePublic] = []
class SectorPublicWithServices(SectorPublic):
    services: list[ServicePublicWithChildren] = []  # premier niveau seulement

# routers/public/services.py
class ServicePublicWithDetailsEnriched(ServicePublic):
    ...                                   # existant
    parent: ServiceRelativePublic | None = None      # parent ACTIF seulement
    children: list[ServiceRelativePublic] = []       # pôles actifs, (display_order, name)
```

Dans `ServiceUpdate`, `parent_id: null` explicite détache le service (`model_dump(exclude_unset=True)` conserve le `None` envoyé). Un champ absent ne change rien.

## 2. Admin — `/api/admin/services`

| Endpoint | Changement |
|---|---|
| `GET ""` | éléments `ServiceRead` + `parent_id`, `landing_path` |
| `GET /{id}` | `ServiceWithDetails` + `parent_id`, `landing_path` |
| `POST ""` | accepte `parent_id`, `landing_path` ; validation hiérarchique |
| `PUT /{id}` | idem ; validation avec l'état fusionné (valeurs envoyées, sinon valeurs actuelles) |
| `POST /{id}/duplicate` | copie `parent_id`, pas `landing_path` |
| `DELETE /{id}` | inchangé (le `SET NULL` détache les pôles) |
| `PUT /reorder`, `POST /{id}/toggle-active` | inchangés |

**Validation** (`OrganizationService._validate_hierarchy(service_id, sector_id, parent_id)`), appelée par `create_service` et `update_service` avant l'écriture :

| Condition | Code | `detail` |
|---|---|---|
| `parent_id` n'est pas un UUID ou désigne un service inexistant | 422 | « Service parent introuvable » |
| `parent_id == service_id` | 422 | « Un service ne peut pas être son propre parent » |
| le parent a un `parent_id` | 409 | « Le service parent est lui-même un pôle : un seul niveau est autorisé » |
| le service a N pôles et reçoit un parent | 409 | « Ce service a N pôle(s) : il ne peut pas être rattaché » |
| `parent.sector_id IS DISTINCT FROM sector_id` | 409 | « Le service parent doit appartenir au même secteur » |
| le service a N pôles et `sector_id` change | 409 | « Déplacez ou détachez d'abord ses N pôle(s) » |
| `DBAPIError` SQLSTATE `23514` au `flush` (course, trigger) | 409 | message du trigger |

Audit : `AuditMiddleware`, sans changement.

## 3. Public

### 3.1 `GET /api/public/sectors/with-services` et `GET /api/public/sectors/{code}`

Pour chaque secteur actif, `services` = services **actifs de premier niveau** triés par `(display_order, name)`, chacun avec `children` = pôles actifs triés. Un pôle dont le parent est inactif n'apparaît pas. **Aucune mutation de `Sector.services`** : réponse construite en schémas (correctif C1).

```json
[{ "id": "…", "code": "SEC-REC", "name": "Rectorat", "…": "…",
   "services": [
     { "id": "72eca1c4-…", "name": "Direction du développement et de l’entrepreneuriat", "sigle": "DDE",
       "parent_id": null, "landing_path": null, "…": "…",
       "children": [
         { "id": "5e1c0050-0000-4000-8000-00000000e1ab", "name": "Pôle Entrepreneuriat et Innovation",
           "sigle": "PEI", "parent_id": "72eca1c4-…", "landing_path": "/entrepreneuriat", "…": "…" } ] },
     { "id": "…", "sigle": "DRE", "parent_id": null, "landing_path": null, "children": [] } ] }]
```

### 3.2 `GET /api/public/services[?sector_id=]`

Inchangé : liste à plat de **tous** les services actifs, pôles compris, avec `parent_id` et `landing_path`. `findServiceBySlug`, `getServiceUrl`, le plan du site et le fil d'Ariane PEI s'appuient dessus.

### 3.3 `GET /api/public/services/{id}`

Ajout de `parent` (`ServiceRelativePublic`, `null` si le service n'a pas de parent ou si le parent est inactif) et de `children` (pôles actifs).

### 3.4 `GET /api/public/short-links/{code}` et `/r/{code}`

Inchangés. `pei` → `{ "target_url": "/entrepreneuriat" }`, puis redirection 302 par `server/routes/r/[code].get.ts`.

## 4. Liens courts — `ShortLinkService.create_short_link`

- Jusqu'à 20 tirages `nextval('short_link_counter_seq')`. Un code est retenu dès que `int_to_base36(counter)` est absent de `short_links`.
- Au-delà de 20 tirages : `ValidationException("Impossible de générer un code court libre, réessayez")`.
- Le message « Capacité maximale atteinte » est réservé à `counter > MAX_COUNTER`, ou à une séquence épuisée (erreur de `nextval` réellement due à `MAXVALUE`). Les autres exceptions remontent.
