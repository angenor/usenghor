# Phase 1 — Data Model: Page FAQ managée dans le backoffice

**Branch**: `019-faq-backoffice` | **Date**: 2026-05-02

Schéma PostgreSQL 16 cible. Convention du projet : double colonne `*_html` + `*_md` pour les champs riches, triple colonne `*_fr` / `*_en` / `*_ar` pour les champs trilingues, `TIMESTAMPTZ` pour les dates (UTC, ISO 8601), `uuid_generate_v4()` (extension `uuid-ossp`) pour les PK.

---

## Entités

### `faq_categories`

| Colonne          | Type                       | Contraintes / Notes |
|------------------|----------------------------|---------------------|
| `id`             | `UUID`                     | PK, `DEFAULT uuid_generate_v4()` |
| `code`           | `VARCHAR(60)`              | UNIQUE NOT NULL ; ex. `general`, `admissions`, `vie-etudiante`. Pattern `[a-z0-9_-]+`. Sert de référence stable interne. |
| `label_fr`       | `VARCHAR(120)`             | NOT NULL |
| `label_en`       | `VARCHAR(120)`             | NULL (repli FR si vide) |
| `label_ar`       | `VARCHAR(120)`             | NULL (repli FR si vide) |
| `description_fr` | `TEXT`                     | NULL |
| `description_en` | `TEXT`                     | NULL |
| `description_ar` | `TEXT`                     | NULL |
| `display_order`  | `INTEGER`                  | NOT NULL DEFAULT 0 |
| `is_active`      | `BOOLEAN`                  | NOT NULL DEFAULT TRUE ; une catégorie inactive cache toutes ses entrées du public mais reste éditable |
| `created_at`     | `TIMESTAMPTZ`              | NOT NULL DEFAULT NOW() |
| `updated_at`     | `TIMESTAMPTZ`              | NOT NULL DEFAULT NOW() ; mis à jour par trigger |

**Index** :
- `idx_faq_categories_active_order` sur `(is_active, display_order)` (lecture publique).

**Règles métier** :
- Catégorie « Général » seedée à l'initialisation (`code='general'`, `label_fr='Général'`, `display_order=0`, `is_active=TRUE`). Non supprimable.
- Suppression d'une catégorie refusée si au moins une `faq_entries.category_id` la référence (FK `ON DELETE RESTRICT`).

---

### `faq_entries`

| Colonne           | Type            | Contraintes / Notes |
|-------------------|-----------------|---------------------|
| `id`              | `UUID`          | PK, `DEFAULT uuid_generate_v4()` |
| `category_id`     | `UUID`          | NOT NULL, FK → `faq_categories(id)` ON DELETE RESTRICT |
| `slug`            | `VARCHAR(160)`  | UNIQUE NOT NULL ; pattern `[a-z0-9-]+` ; généré depuis `question_fr` à la création, éditable |
| `question_fr`     | `VARCHAR(300)`  | NOT NULL ; texte court non riche |
| `question_en`     | `VARCHAR(300)`  | NULL (repli FR public) |
| `question_ar`     | `VARCHAR(300)`  | NULL (repli FR public) |
| `answer_fr_md`    | `TEXT`          | NOT NULL ; source Markdown TOAST UI |
| `answer_fr_html`  | `TEXT`          | NOT NULL ; HTML rendu et assaini |
| `answer_en_md`    | `TEXT`          | NULL |
| `answer_en_html`  | `TEXT`          | NULL |
| `answer_ar_md`    | `TEXT`          | NULL |
| `answer_ar_html`  | `TEXT`          | NULL |
| `is_published`    | `BOOLEAN`       | NOT NULL DEFAULT FALSE |
| `published_at`    | `TIMESTAMPTZ`   | NULL ; positionné automatiquement quand `is_published` passe à TRUE pour la première fois |
| `display_order`   | `INTEGER`       | NOT NULL DEFAULT 0 ; ordre dans la catégorie |
| `created_at`      | `TIMESTAMPTZ`   | NOT NULL DEFAULT NOW() |
| `updated_at`      | `TIMESTAMPTZ`   | NOT NULL DEFAULT NOW() ; mis à jour par trigger |
| `created_by`      | `UUID`          | NULL, FK → `users(id)` ON DELETE SET NULL |
| `updated_by`      | `UUID`          | NULL, FK → `users(id)` ON DELETE SET NULL |

**Index** :
- `idx_faq_entries_category_order` sur `(category_id, display_order)` (lecture publique groupée).
- `idx_faq_entries_published` sur `(is_published)` partiel `WHERE is_published = TRUE` (lecture publique).
- Unicité du `slug` déjà imposée par la contrainte `UNIQUE` — utilisée pour la résolution d'ancres.

**Contraintes** :
- `CHECK (slug ~ '^[a-z0-9][a-z0-9-]*[a-z0-9]$' OR slug ~ '^[a-z0-9]$')` — slug valide URL.
- `CHECK (LENGTH(question_fr) >= 3)` — éviter les questions vides accidentelles.

**Règles métier** :
- Lors d'un `INSERT` admin, si `slug` est omis, le service le calcule depuis `question_fr` (translit ASCII, lower, `[^a-z0-9-]` → `-`, troncature 120) et résout les collisions avec un suffixe `-2`, `-3`…
- `published_at` est positionné par le service uniquement à la première transition `FALSE → TRUE` ; il n'est pas réinitialisé lors d'une dépublication suivie d'une republication (l'historique reste).
- Le repli silencieux (D5) s'applique au sérialiseur public uniquement : si `question_<lang>` ou `answer_<lang>_html` est `NULL` ou vide, on retourne la valeur FR.

---

## Relations

```
faq_categories (1) ────< (n) faq_entries
       │                        │
       │                        ├──> users (created_by, updated_by, ON DELETE SET NULL)
       │                        │
       └─────────────────── ON DELETE RESTRICT
```

`audit_logs` (table existante) référence indirectement `faq_categories.id` et `faq_entries.id` via son champ `entity_id` polymorphe (pas de FK formelle, déjà la convention du projet).

---

## Lifecycle d'une entrée

```
[création — draft]
       │  is_published = FALSE
       │  published_at = NULL
       ▼
[édition libre — draft]
       │  is_published reste FALSE
       ▼
[publication]
       │  is_published = TRUE
       │  published_at = NOW() (si NULL)
       │  → visible côté public
       ▼
[édition publiée]
       │  is_published reste TRUE
       │  published_at inchangé
       ▼
[dépublication]
       │  is_published = FALSE
       │  published_at conservé (mémoire de la 1ʳᵉ publi)
       ▼
[suppression]
       │  audit_logs faq.entry.delete écrit
       │  ligne supprimée définitivement (pas de soft delete pour cette feature)
```

---

## Catégorie par défaut (seed)

Insertion idempotente dans `99_data_init.sql` :

```sql
INSERT INTO faq_categories (code, label_fr, label_en, label_ar, display_order, is_active)
VALUES ('general', 'Général', 'General', 'عام', 0, TRUE)
ON CONFLICT (code) DO NOTHING;
```

---

## Triggers requis

- `trg_faq_categories_set_updated_at` : `BEFORE UPDATE` → `NEW.updated_at = NOW()`.
- `trg_faq_entries_set_updated_at` : idem.
- (Réutiliser la fonction `set_updated_at()` existante dans `99_functions.sql` si elle existe ; sinon la créer.)

---

## Validation côté Pydantic (résumé, détails dans contracts/)

- **FaqCategoryCreate / FaqCategoryUpdate** : `label_fr` requis (>= 1 char, <= 120) ; `label_en`, `label_ar` optionnels ; `code` validé contre `^[a-z0-9_-]+$` ; `display_order` >= 0.
- **FaqEntryCreate / FaqEntryUpdate** : `category_id` requis (UUID), `question_fr` requis (>= 3, <= 300), `answer_fr_md` requis (>= 1) et `answer_fr_html` requis ; champs EN/AR optionnels ; `slug` optionnel (généré par défaut), validé contre `^[a-z0-9][a-z0-9-]*$` si fourni.
- **FaqEntryPublish** : payload `{ is_published: bool }`.
- **ReorderRequest** : `[{ id: UUID, display_order: int }]`.

---

## Volumes attendus

| Métrique | Valeur cible |
|----------|--------------|
| Catégories | 5 à 15 |
| Questions totales | 5 à 150 |
| Taille moyenne d'une réponse HTML | ~2 KB |
| Charge `/api/public/faq` | < 1 req/s en moyenne, peak 50 req/s |
| Latence p95 endpoint public | < 200 ms |
