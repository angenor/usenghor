# Migration — Traduction automatique FR → EN/AR du contenu dynamique

> **But** : permettre que le contenu saisi par les admins (actualités, programmes,
> projets, etc.) soit automatiquement traduit en anglais et en arabe **une seule
> fois à l'écriture**, puis **stocké en base** (jamais retraduit à la lecture).
>
> **État** : le **pilote FAQ est livré et fonctionnel** (voir §3). Ce document
> décrit la procédure utilisée et liste **tous les autres modules à migrer** lors
> de sessions ultérieures.
>
> ⚠️ Les numéros de ligne ci-dessous sont **indicatifs** (relevés le 2026-06-07).
> Le code bouge : revérifier `file:line` au moment d'exécuter chaque étape.

---

## 1. Contexte & état actuel

La traduction de l'**interface** (i18n statique `@nuxtjs/i18n`) fonctionne. Mais le
**contenu dynamique** issu de la base n'était pas traduit, car **la plupart des
tables sont monolingues en base** : il n'y a aucune colonne où ranger la traduction.

| Déjà trilingue en base ✅ | Monolingue ❌ (à migrer) |
|---|---|
| `faq_entries`, `faq_categories` | `news`, `events`, `tags` |
| `fundraisers` (+ médias / sections) | `programs`, `program_semesters`, `program_courses` |
| `surveys` | `application_calls` (+ 4 sous-tables) |
| `countries` | `sectors`, `services` (+ objectives/achievements/projects) |
| | `campuses` |
| | `projects`, `project_categories`, `project_calls` |
| | `partners` |

Côté frontend, **3 patterns de lecture** coexistent (à harmoniser, cf §3.7) :
- **FAQ** (le modèle cible) : le backend renvoie les 3 langues, le front choisit selon `locale.value`, repli FR.
- **News/Events/Programs/…** : le backend renvoie un champ unique → affiché tel quel.
- **Fundraising** : envoie `?lang=` au backend.

---

## 2. Décision de nommage des colonnes (À RESPECTER)

On adopte la **convention additive** (celle de `fundraisers`) :

- La **colonne existante reste la version française** (pas de renommage).
- On **ajoute** les variantes `_en` et `_ar`.
- Pour les champs **rich text** (paire `*_html` + `*_md`), le suffixe de langue
  s'insère **avant** `_html`/`_md`.

| Champ existant (FR) | Colonnes à AJOUTER |
|---|---|
| `content_html`, `content_md` | `content_en_html`, `content_en_md`, `content_ar_html`, `content_ar_md` |
| `name` | `name_en`, `name_ar` |
| `description` (texte simple) | `description_en`, `description_ar` |

**Pourquoi cette convention plutôt que `_fr`/`_en`/`_ar` explicite (style FAQ) :**
1. Migration **purement additive** (`ALTER TABLE … ADD COLUMN`) → pas de renommage, pas de backfill, risque minimal en prod.
2. La lecture FR existante (backend + frontend) **ne change pas**.
3. Les **types frontend de `news` sont déjà pré-câblés** dans cette convention
   (`content_en_html`, `content_ar_html`… dans `usenghor_nuxt/app/types/news.ts`).

> **Note** : `faq_entries` utilise le style `_fr` explicite (exception historique).
> Pour toutes les **nouvelles** migrations, on standardise sur l'additif ci-dessus.
> Le service de traduction (§4) est agnostique au nommage.

**Ne jamais traduire** : `slug`, `code`, `sigle` (acronyme), identifiants/références
externes (`*_external_id`), statuts/enums, dates, montants, coordonnées (email,
téléphone, site web), `position` (rôle interne d'équipe). Les **noms propres** de
partenaires se traduisent rarement → voir §6.

---

## 3. Procédure de référence (recette réutilisable) — telle qu'appliquée au pilote FAQ

Voici **exactement la démarche utilisée** pour la FAQ, généralisée pour être
rejouée sur chaque module. Le pilote FAQ sert d'exemple concret de bout en bout.

### 3.0 — Socle (fait une seule fois, déjà livré)
- `usenghor_backend/requirements.txt` : `deep-translator>=1.11.4`, `beautifulsoup4>=4.12.0`.
- `usenghor_backend/app/config.py` : flags `auto_translate_enabled` (bool, défaut `True`) et `auto_translate_source` (`"fr"`).
- `usenghor_backend/app/services/translation_service.py` : **module réutilisable tel quel** (voir §4).

### 3.1 — Migration SQL (additive)
`ALTER TABLE … ADD COLUMN` pour les variantes `_en`/`_ar` (toutes `NULL` par défaut).
Exemple (events) :
```sql
ALTER TABLE events
  ADD COLUMN IF NOT EXISTS content_en_html TEXT,
  ADD COLUMN IF NOT EXISTS content_en_md   TEXT,
  ADD COLUMN IF NOT EXISTS content_ar_html TEXT,
  ADD COLUMN IF NOT EXISTS content_ar_md   TEXT;
```
> Mettre à jour la **source de vérité** SQL (`documentation/modele_de_données/services/*.sql`)
> ET appliquer une migration `documentation/modele_de_données/migrations/00X_*.sql`.
> Appliquer en local (`usenghor_postgres`) puis en prod (`usenghor_db`).

### 3.2 — Modèle SQLAlchemy
Ajouter les colonnes `Mapped[str | None]` correspondantes dans le modèle.
(FAQ : déjà trilingue, rien à faire — pour les autres modules voir §5.)

### 3.3 — Schémas Pydantic
Ajouter les champs `*_en` / `*_ar` (optionnels, `None` par défaut) dans les classes
`*Base` (→ propagé à Create), `*Update`, et les schémas de lecture **publics**
(`*Public` / `*Read`) pour qu'ils soient renvoyés au frontend.

### 3.4 — Hook de remplissage auto dans le service
Au `create` **et** au `update`, remplir les champs `_en`/`_ar` **vides** depuis la
source FR. **Échec non bloquant** : si la traduction échoue, on sauvegarde quand même.

Concrètement, pour FAQ (`usenghor_backend/app/services/faq_service.py`) :
- méthode `_autofill_entry_translations(entry, *, force=False)` appelée dans
  `create_entry` (avant `flush`) et `update_entry` (après application des changements).
- `force=False` = ne touche que les champs vides → **préserve les corrections manuelles**.

**Version généralisée recommandée** pour les modules en nommage additif — un helper
réutilisable (à placer p.ex. dans `translation_service.py`) :
```python
def _lang_attr(base: str, lang: str) -> str:
    """content_html -> content_en_html ; title -> title_en"""
    for suffix in ("_html", "_md"):
        if base.endswith(suffix):
            return f"{base[:-len(suffix)]}_{lang}{suffix}"
    return f"{base}_{lang}"

async def autofill_translations(obj, fields, *, force=False, langs=("en", "ar")):
    """fields = liste de (base_attr, kind) ; kind ∈ {"text", "html"}."""
    for base, kind in fields:
        src = getattr(obj, base, None)
        if not src:
            continue
        translate = translate_html if kind == "html" else translate_text
        for lang in langs:
            target = _lang_attr(base, lang)
            if force or not getattr(obj, target, None):
                value = await translate(src, lang)
                if value:
                    setattr(obj, target, value)
```
Exemple d'appel (events) :
```python
await autofill_translations(event, [("content_html", "html"), ("content_md", "text")])
```

### 3.5 — Endpoint de traduction sans persistance (pour le bouton)
Endpoint `POST …/translate` qui prend les champs FR et renvoie les traductions
EN/AR **sans écrire en base** — sert au bouton « Traduire » du formulaire admin
(prévisualisation + correction avant sauvegarde). Permission de lecture suffisante.

FAQ : `POST /api/admin/faq/entries/translate` (router `routers/admin/faq.py`),
méthode `FaqService.translate_fields()`, schémas `FaqTranslateRequest` /
`FaqTranslateResponse`. ⚠️ Déclarer la route **statique** AVANT la route dynamique
`/{id}` (ordre des routes FastAPI).

### 3.6 — Frontend : composable + bouton
- Composable admin : ajouter `translateEntry(payload)` (FAQ : `useFaqApi.ts`).
- Formulaire admin : bouton **« Traduire FR → EN/AR »** qui appelle l'endpoint et
  **remplit les champs EN/AR éditables** (donc corrigeables), puis l'admin enregistre.
  (FAQ : `components/faq/admin/EntryForm.vue`.)
- ⚠️ Si le champ rich text passe par `ToastUIEditor`, la mise à jour programmatique
  de `model-value` est bien reprise par l'éditeur (watch → `setMarkdown`, vérifié).
- i18n : ajouter les clés `translate`, `translating`, `translateHint`,
  `translateSuccess`, `translateError`, `translateNeedsFr` dans `fr/`, `en/`, `ar/`.

### 3.7 — Frontend : lecture publique (harmonisation)
Standardiser sur le **pattern FAQ** : le backend renvoie les 3 langues, le front
choisit selon la locale avec **repli FR**. Créer **un helper partagé** (recommandé,
n'existe pas encore) pour éviter de redupliquer la logique partout :
```ts
// composables/useLocalizedField.ts
export function useLocalizedField() {
  const { locale } = useI18n()
  return function localized<T extends Record<string, any>>(obj: T, base: string): string {
    const lang = locale.value
    if (lang === 'en') return obj[`${base}_en`] || obj[base] || ''
    if (lang === 'ar') return obj[`${base}_ar`] || obj[base] || ''
    return obj[base] || ''
  }
}
// usage : localized(news, 'content_html')
```
Côté backend, on peut au choix renvoyer les 3 langues (simple, cf FAQ) ou appliquer
un repli serveur via une fonction type `_coalesce(obj.x_en, obj.x)` (cf
`faq_service._serialize_entry_public`). Préférer le repli **FR** systématique.

### 3.8 — Vérification
- Backend : `python -m py_compile` des fichiers modifiés + test d'import du service.
- Traduction réelle : nécessite un accès réseau sortant vers `translate.google.com`.
- Frontend : `pnpm lint` + validité JSON des fichiers i18n.

---

## 4. Composant central déjà livré : `translation_service.py`

`usenghor_backend/app/services/translation_service.py` — **réutilisable tel quel**,
aucune modif nécessaire pour les autres modules.

- `translate_text(text, target, source="fr") -> str | None` : texte court.
- `translate_html(html, target, source="fr") -> str | None` : traduit **uniquement
  les nœuds texte** via BeautifulSoup → **préserve les balises** du rich text TOAST UI.
- `SUPPORTED_TARGETS = ("en", "ar")`.
- **Async** (`asyncio.to_thread`, deep-translator est synchrone) et **échec
  silencieux** (log warning + `None` → la sauvegarde réussit toujours, le repli FR
  couvre l'affichage).

**Limite connue** : la traduction par nœud texte rend une phrase coupée par une
balise inline (`<strong>` au milieu) un peu maladroite (« une **réponse** importante »
→ « a **answer** important »). La structure et les liens ne sont jamais perdus, et
l'admin corrige via le champ éditable. Option future : traduire par bloc.

---

## 5. Modules à migrer — tableau de synthèse

Nommage additif (§2). « rich » = paire `*_html`+`*_md` (donc 4 colonnes/langue ×2 =
… en fait 2 colonnes × 2 langues = `_en_html`,`_en_md`,`_ar_html`,`_ar_md`).

| # | Table | Champs à traduire (base) | Type | Compl. | Priorité |
|---|---|---|---|---|---|
| 1 | `tags` | `name`, `description` | court + simple | **S** | 1 (valide le pattern) |
| 2 | `news` | `content` (rich) ; *recommandé* `title`, `summary` | rich (+court) | **M** | 2 (types front déjà prêts) |
| 3 | `events` | `content` (rich) ; *recommandé* `title`, `description` | rich (+court) | **M** | 2 |
| 4 | `partners` | `description` ; `name` → voir §6 | simple | **S** | 3 |
| 5 | `project_categories` | `name`, `description` | court + simple | **S** | 3 |
| 6 | `projects` | `summary` (rich), `description` (rich) ; `title` | rich (+court) | **M** | 3 |
| 7 | `project_calls` | `description` (rich), `conditions` (rich) ; `title` | rich (+court) | **M** | 3 |
| 8 | `sectors` | `description` (rich), `mission` (rich) ; `name` | rich (+court) | **M** | 4 |
| 9 | `services` | `description` (rich), `mission` (rich) ; `name` | rich (+court) | **M** | 4 |
| 10 | `service_objectives` | `title`, `description` (rich) | court + rich | **M** | 4 |
| 11 | `service_achievements` | `title`, `description` (rich) | court + rich | **M** | 4 |
| 12 | `service_projects` | `title`, `description` (rich) | court + rich | **M** | 4 |
| 13 | `campuses` | `description` (rich) ; `name` ; (`address` opt.) | rich (+court) | **M** | 5 |
| 14 | `application_calls` | `description` (rich), `target_audience` (rich) ; `title` | rich (+court) | **M** | 5 |
| 15 | `call_eligibility_criteria` | `criterion` | simple | **S** | 5 |
| 16 | `call_coverage` | `item`, `description` | court + simple | **S** | 5 |
| 17 | `call_required_documents` | `document_name`, `description` | court + simple | **S** | 5 |
| 18 | `call_schedule` | `step`, `description` | court + simple | **S** | 5 |
| 19 | `programs` | `description`/`teaching_methods`/`format`/`evaluation_methods` (rich), `required_degree` ; `objectives`/`target_audience` (JSONB, §6) ; `title`/`subtitle` | rich + JSONB | **L** | 6 |
| 20 | `program_semesters` | `title` | court | **S** | 6 |
| 21 | `program_courses` | `title`, `description` | court + simple | **S** | 6 |

**Hors périmètre** : `editorial_contents` (déjà couvert par i18n, §6) ;
`service_team` / `campus_team` (`position` = rôle interne) ; tables de liaison
(`news_tags`, `*_media_library`, `campus_partners`…).

---

## 5bis. Fiches par module (pointeurs fichiers)

> Pour chaque table : SQL (source de vérité), modèle, schémas, service, router, et
> côté frontend (type, composable public, page de lecture, formulaire admin).

### Domaine CONTENT — `news`, `events`, `tags`
- **SQL** : `usenghor_backend/documentation/modele_de_données/services/09_content.sql`
  - `news` (≈L107-137), `events` (≈L22-63), `tags` (≈L98-105)
- **Modèle** : `usenghor_backend/app/models/content.py` — `News` (≈L204), `Event` (≈L76), `Tag` (≈L57)
- **Schémas** : `usenghor_backend/app/schemas/content.py` — `NewsBase/Create/Update/Public`, `EventBase/Update/Public`, `TagBase/Update`
- **Service** : `usenghor_backend/app/services/content_service.py` — `create_news`/`update_news` (≈L713/752), `create_event`/`update_event` (≈L239/250), `create_tag`/`update_tag` (≈L88/104). ⚠️ étendre aussi `duplicate_news`/`duplicate_event` et `enrich_news_with_names`.
- **Routers** : `usenghor_backend/app/routers/admin/news.py`, `events.py`, `tags.py`
- **Frontend types** : `usenghor_nuxt/app/types/news.ts` — **`content_en_html`/`content_ar_html`… DÉJÀ présents** ; `TagRead` à étendre.
- **Composables publics** : `usePublicNewsApi.ts`, `usePublicEventsApi.ts`
- **Pages lecture** : `pages/actualites/[slug].vue` (`content_html`), `pages/actualites/evenements/[id].vue`
- **Formulaires admin** : `pages/admin/contenus/actualites/nouveau.vue` (state EN/AR `contentMdEn/Ar`, `contentHtmlEn/Ar` **déjà présent** → reste à brancher au payload), `…/evenements/nouveau.vue` (idem), `…/etiquettes/index.vue` (à étendre).

### Domaine PROJECT / PARTNER — `projects`, `project_categories`, `project_calls`, `partners`
- **SQL** : `…/services/10_project.sql` (`project_categories` ≈L20, `projects` ≈L29, `project_calls` ≈L80) ; `06_partner.sql` (`partners` ≈L18)
- **Modèles** : `app/models/project.py` (`ProjectCategory`, `Project`, `ProjectCall`), `app/models/partner.py` (`Partner`)
- **Schémas** : `app/schemas/project.py`, `app/schemas/partner.py`
- **Services** : `app/services/project_service.py`, `app/services/partner_service.py`
- **Routers** : `app/routers/admin/institutional_projects.py`, `app/routers/admin/partners.py`
- **Frontend** : `types/api/projects.ts`, `types/api/partners.ts` ; `usePublicProjectsApi.ts`/`useProjectsApi.ts` (`transformToDisplay`) ; pages `pages/projets/…`, `pages/admin/projets/liste/nouveau.vue`, `pages/admin/partenaires/index.vue`

### Domaine ORGANIZATION / CAMPUS — `sectors`, `services`(+sous-tables), `campuses`
- **SQL** : `…/services/04_organization.sql` (`sectors` ≈L19, `services` ≈L40, `service_objectives` ≈L64, `service_achievements` ≈L74, `service_projects` ≈L87) ; `05_campus.sql` (`campuses` ≈L16)
- **Modèles** : `app/models/organization.py` (`Sector` ≈L28, `Service` ≈L57, objectives/achievements/projects ≈L113/132/160), `app/models/campus.py` (`Campus` ≈L18)
- **Schémas** : `app/schemas/organization.py`, `app/schemas/campus.py`
- **Services** : `app/services/organization_service.py`, `app/services/campus_service.py`
- **Routers** : `app/routers/admin/sectors.py`, `services.py` (sous-tables via `/{service_id}/objectives|achievements|projects`), `campuses.py`
- **Frontend** : `usePublicOrganizationApi.ts`, `usePublicCampusApi.ts` ; pages `a-propos/organisation/[type]/[slug].vue` (lit `name`, `description_html`, `mission_html`, et `objective.title`/`achievement.title`/`project.title`), `a-propos/partenaires/campus/[slug].vue` ; formulaires `admin/organisation/…`, `admin/campus/liste/{nouveau,[id]/edit}.vue` (state `description_md/html` déjà présent, monolingue)

### Domaine ACADEMIC / APPLICATION — `programs`, `program_semesters`, `program_courses`, `application_calls`(+sous-tables)
- **SQL** : `…/services/07_academic.sql` (`programs` ≈L59, `program_semesters` ≈L108, `program_courses` ≈L121) ; `08_application.sql` (`application_calls` ≈L29, sous-tables `call_eligibility_criteria` ≈L82, `call_coverage` ≈L90, `call_required_documents` ≈L99, `call_schedule` ≈L110)
- **Modèles** : `app/models/academic.py` (`Program` ≈L55, `ProgramSemester` ≈L207, `ProgramCourse` ≈L231), `app/models/application.py` (`ApplicationCall` ≈L92, sous-tables ≈L180+)
- **Schémas** : `app/schemas/academic.py`, `app/schemas/application.py`
- **Services** : `app/services/academic_service.py`, `app/services/application_service.py` (⚠️ la recherche filtre sur `description_html` → adapter, §6)
- **Routers** : `app/routers/admin/programs.py`, `program_semesters.py` (cours via `/{semester_id}/courses`), `application_calls.py`
- **Frontend** : `types/api/programs.ts`, `types/api/application-calls.ts` ; `usePublicProgramsApi.ts`, `usePublicCallsApi.ts` ; pages `formations/[type]/[slug].vue` (+ `components/programs/ProgramTabs.vue`), `actualites/appels/[slug].vue` (+ `components/cards/CardCall.vue` qui gère **déjà** `title_en`/`title_ar` sur mock) ; formulaires `admin/formations/programmes/nouveau.vue`, `admin/formations/semestres.vue`, `admin/candidatures/appels/nouveau.vue`

---

## 6. Cas particuliers

- **`editorial_contents` → NE PAS migrer.** Système clé/valeur (`key`, `value`,
  `value_type`) déjà couvert côté frontend par `composables/useEditorialContent.ts`
  (repli automatique sur i18n selon la locale). Si on veut un jour y injecter des
  traductions, le faire **via les clés existantes**, sans toucher au schéma.
- **Champs JSONB (`programs.objectives`, `programs.target_audience`)** : ce sont des
  **listes**. Ajouter `objectives_en`/`objectives_ar` (JSONB) et traduire **chaque
  élément** du tableau (boucle sur `translate_text`), pas le JSON brut.
- **Noms propres de partenaires (`partners.name`)** : souvent **ne pas traduire**
  (raison sociale). Par défaut, ne traduire que `description`. Traduire `name`
  seulement si le métier le demande (ex. « Ministère de… » / « Ministry of… »).
- **Sigles / acronymes (`services.sigle`)** : laisser en FR par défaut.
- **Slugs** : toujours basés sur le FR, **jamais traduits** (stabilité des URL).
- **Endpoints de recherche** : certains filtrent sur la colonne FR (ex.
  `application_service` cherche dans `description_html`, FAQ cherche `question_fr`).
  Décider si la recherche doit couvrir les 3 langues (sinon une recherche en arabe
  ne trouvera rien). Hors périmètre strict de la traduction, mais à garder en tête.

---

## 7. Ordre de déploiement recommandé

1. **`tags`** (S) — le plus simple, valide la chaîne complète sur du texte court.
2. **`news`** puis **`events`** (M) — fort impact public, **types frontend déjà prêts**.
3. **`partners`**, **`project_categories`** (S), puis **`projects`**, **`project_calls`** (M).
4. **`sectors`**, **`services`** + sous-tables (M).
5. **`campuses`**, **`application_calls`** + sous-tables (M/S).
6. **`programs`** (L, cas JSONB), **`program_semesters`**, **`program_courses`** (S).

À chaque module : suivre la recette §3 (SQL → modèle → schémas → hook service →
endpoint translate → frontend → i18n → lecture publique) et tester (§3.8).

---

## 8. Checklist par table (à copier pour chaque migration)

```
[ ] SQL : ALTER TABLE … ADD COLUMN _en/_ar (NULL) — additif (§2)
[ ] SQL : mettre à jour la source de vérité services/*.sql
[ ] SQL : créer migrations/00X_<table>_i18n.sql + appliquer local puis prod
[ ] Modèle SQLAlchemy : ajouter les colonnes Mapped[str | None]
[ ] Schémas Pydantic : *Base/*Update + schémas Public/Read (champs optionnels)
[ ] Service : appeler autofill_translations() dans create + update (vides seulement)
[ ] Service : étendre les éventuels duplicate_*/enrich_*
[ ] Router : endpoint POST …/translate (route statique AVANT /{id})
[ ] Frontend types : ajouter _en/_ar
[ ] Composable admin : translate<X>()
[ ] Formulaire admin : bouton « Traduire FR → EN/AR » qui remplit les champs
[ ] i18n : clés translate* dans fr/ en/ ar
[ ] Lecture publique : localized() + repli FR (harmoniser sur le pattern FAQ)
[ ] Tests : py_compile + import service ; pnpm lint ; JSON i18n valides
```

---

## 9. Déploiement & exploitation

- **Dépendances** : `pip install -r requirements.txt` en local **et rebuild de
  l'image `usenghor_backend`** en prod (sinon `ModuleNotFoundError: deep_translator`).
- **Réseau sortant** : le conteneur backend doit pouvoir joindre
  `https://translate.google.com` (HTTPS sortant). Le sandbox de dev le bloque parfois
  → le service dégrade proprement (warning + champ laissé vide, repli FR à l'affichage).
- **Coût** : nul (deep-translator utilise l'endpoint web gratuit de Google). Le
  remplissage n'a lieu qu'à l'écriture et est stocké → pas d'appel à la lecture.
  Limites : pas de SLA, throttling possible sous forte charge ; si volume important,
  envisager l'API officielle Google Cloud Translation (changement isolé dans
  `translation_service.py`).
- **Désactivation d'urgence** : `auto_translate_enabled=false` dans le `.env` backend
  → toutes les fonctions renvoient `None` (aucune traduction, repli FR partout).

---

## 10. Référence — fichiers du pilote FAQ (exemple complet à copier)

- Backend : `app/services/translation_service.py` (nouveau, réutilisable),
  `app/services/faq_service.py` (`_autofill_entry_translations`, `translate_fields`,
  hooks create/update), `app/routers/admin/faq.py` (`POST /entries/translate`),
  `app/schemas/faq.py` (`FaqTranslateRequest`/`Response`), `app/config.py`,
  `requirements.txt`.
- Frontend : `app/composables/useFaqApi.ts` (`translateEntry`),
  `app/components/faq/admin/EntryForm.vue` (bouton), `app/types/api/faq.ts`,
  `i18n/locales/{fr,en,ar}/faq.json` (clés `translate*`).
```
