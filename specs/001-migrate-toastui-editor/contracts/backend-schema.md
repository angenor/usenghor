# Contract: Schémas Backend (Pydantic)

## Changements sur les schémas existants

### Pattern de modification

Chaque champ `content: str | None` dans les schémas Pydantic est remplacé par deux champs :

```python
# Avant (EditorJS)
content: str | None = None  # JSON EditorJS OutputData

# Après (TOAST UI)
content_html: str | None = None  # HTML pour le rendu
content_md: str | None = None    # Markdown pour l'édition
```

### Schémas impactés

#### content.py
- `EventCreate`, `EventUpdate`, `EventRead` : `content` → `content_html` + `content_md`
- `NewsCreate`, `NewsUpdate`, `NewsRead` : `content` → `content_html` + `content_md`

#### project.py
- `ProjectBase/Create/Update/Read` : `description` → `description_html` + `description_md`
- `ProjectCallBase/Create/Update/Read` : `description` → `description_html` + `description_md`, `conditions` → `conditions_html` + `conditions_md`

#### academic.py
- `ProgramBase/Create/Update/Read` :
  - `description` → `description_html` + `description_md`
  - `teaching_methods` → `teaching_methods_html` + `teaching_methods_md`
  - `format` → `format_html` + `format_md`
  - `evaluation_methods` → `evaluation_methods_html` + `evaluation_methods_md`

#### organization.py (sectors, services)
- `description` → `description_html` + `description_md`
- `mission` → `mission_html` + `mission_md`

### Endpoints inchangés

Les routes API restent identiques. Seuls les champs dans le body JSON changent de nom et de format (JSON EditorJS → HTML/Markdown strings).

### Endpoint média (inchangé)

```
POST /api/admin/media/        # Upload d'image (multipart/form-data)
GET  /api/public/media/{uuid}/download  # Téléchargement d'image
```
