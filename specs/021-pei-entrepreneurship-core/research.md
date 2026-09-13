# Research — 021 Socle PEI (Phase 0)

**Date** : 2026-09-13 · **Spec** : [spec.md](spec.md) · **Sources** : exploration du code par quatre sous-agents (backend FAQ, backend levées de fonds + éditorial, frontend FAQ, frontend éditorial + levées de fonds), lecture directe des fichiers cités.

Chaque entrée : Décision / Justification / Alternatives écartées.

---

## R1. Convention de nommage des colonnes trilingues

**Décision** : convention **additive** — colonne française sans suffixe, variantes `_en` / `_ar` ajoutées ; pour le contenu riche, la langue s'insère avant le format : `content_html`, `content_md`, `content_en_html`, `content_en_md`, `content_ar_html`, `content_ar_md`. Champs simples : `title`, `title_en`, `title_ar`.

**Justification** : la demande impose la réutilisation de `autofill_translations` (backend, `app/services/translation_service.py`) et de `useLocalizedField` (frontend). Les deux calculent le nom du champ traduit à partir de la base FR via `_lang_attr` / `variant` : `title` → `title_en`, `content_html` → `content_en_html`. Une base `title_fr` produirait `title_fr_en` (inexistant). C'est la convention documentée dans `MIGRATION_TRADUCTION_AUTO.md` §2 et appliquée à `services`, `sectors`, `news`, `events`, `partners`, `programs`. La mention `*_fr/*_en/*_ar` de CLAUDE.md décrit la FAQ (qui a dû réécrire sa propre traduction champ par champ pour cette raison).

**Alternatives écartées** :
- `*_fr` + traduction maison comme la FAQ (`_autofill_entry_translations`) : duplique la logique, contredit « via `autofill_translations` », et interdit `useLocalizedField` côté public.
- Adapter `_lang_attr` / `variant` pour reconnaître `_fr` : modifie deux helpers transverses utilisés par 7 domaines, hors périmètre.

**Conséquence** : l'hypothèse « Codes initiaux » de la spec reste valable ; les identifiants de colonnes de la spec (§ Key Entities) sont des noms d'attributs métier, pas des noms de colonnes.

---

## R2. Gabarit backend à copier

**Décision** : copier le domaine FAQ (`app/models/faq.py`, `app/schemas/faq.py`, `app/services/faq_service.py`, `app/routers/admin/faq.py`, `app/routers/public/faq.py`) pour la structure (service classe, `_audit`, `_client_meta`, ordre des routes, exceptions 404/409/422), et le domaine organisation pour la traduction (`_SECTOR_TRANSLATABLE` + `autofill_translations`).

**Justification** : FAQ est le domaine le plus récent, testé (pytest), audité explicitement, avec reorder et toggle. Les levées de fonds n'ont ni reorder, ni toggle, ni audit (absentes du `ROUTE_TO_TABLE` du middleware), ni traduction automatique.

**Détails retenus** :
- Mixins `UUIDMixin`, `TimestampMixin` (`app/models/base.py`), `Base` de `app/database`.
- ENUM PostgreSQL déclarés avec `sqlalchemy.Enum(..., name=..., create_type=False, values_callable=...)`.
- Exceptions : `NotFoundException`, `ConflictException`, `ValidationException` (`app/core/exceptions.py`).
- Dépendances : `DbSession`, `CurrentUser`, `PermissionChecker("entrepreneurship.view")` (`app/core/dependencies.py`).
- Enregistrement : `app/routers/admin/__init__.py` et `app/routers/public/__init__.py` (import + `include_router`), rien dans `main.py`.
- Modèles exportés dans `app/models/__init__.py` (nécessaire aux tests).

---

## R3. Audit

**Décision** : audit **explicite** dans le service via `IdentityService(self.db).create_audit_log(...)` (wrapper `_audit` comme la FAQ), actions en notation pointée : `entrepreneurship.program.create|update|delete|reorder|activate|deactivate`, `entrepreneurship.cohort.*`, `entrepreneurship.resource.create|update|delete|reorder|publish|unpublish`, `entrepreneurship.translate_missing`. `table_name` = nom réel de la table (`pei_programs`, `pei_cohorts`, `pei_resources`). Pour les actions en lot (reorder, translate_missing) : `record_id=None` et `new_values={"ids": [...]}` ou `{"updated": n}`.

**Justification** : le middleware `AuditMiddleware` ne journalise que les routes de son `ROUTE_TO_TABLE` ; ne pas y ajouter `entrepreneurship` évite une double écriture. La colonne `record_id` est de type UUID : la valeur `"bulk"` utilisée par le reorder FAQ n'est pas reprise.

**Alternative écartée** : ajouter `entrepreneurship` au `ROUTE_TO_TABLE` — ne couvre pas le détail des actions (reorder = « update ») et double l'audit explicite.

---

## R4. Réordonnancement (glisser-déposer)

**Décision** : `vue-draggable-plus` (déjà en dépendance, `^0.6.1`, seul usage : `pages/admin/formations/semestres.vue`) avec `VueDraggable tag="tbody" handle=".drag-handle"` dans chaque composant de liste ; `@end` envoie la liste ordonnée. Contrat serveur : `PATCH /api/admin/entrepreneurship/{programs|cohorts|resources}/reorder` avec `{ "ids": [...] }` ; le serveur renumérote `display_order = index` (0..n-1), ce qui garantit la contiguïté (FR-012). Glisser-déposer désactivé quand un filtre ou une recherche est actif (comme `secteurs/index.vue`).

**Justification** : aucun composant réutilisable de réordonnancement n'existe ; la FAQ utilise des boutons ▲▼, les levées de fonds un champ numérique. Le pattern `ids` + renumérotation par index (`OrganizationService.reorder_services`) est plus simple que `items[{id, display_order}]` de la FAQ et satisfait directement la contiguïté.

**Alternatives écartées** : HTML5 drag natif copié-collé dans 7 pages (verbeux, pas de handle, pas d'animation) ; boutons ▲▼ (ne répond pas à « glisser-déposer »).

---

## R5. Sélection de média (visuels et documents)

**Constat** : il n'existe **aucun sélecteur de médiathèque** réutilisable. Les formulaires admin attachent un média soit par téléversement direct (`useMediaApi().uploadMediaVariants` + `MediaImageEditor`, ex. actualités, `AdminEditorialImageField`), soit par saisie brute de l'UUID (levées de fonds).

**Décision** : créer un composant transverse `components/admin/MediaPicker.vue` (`<AdminMediaPicker>`) : modale listant les médias existants via `useMediaApi().listMedia({ type, search, page, limit })`, filtre par type (`image` pour les visuels, `document` pour les ressources), recherche, aperçu par `getMediaUrl(id)`, émission `select(media: MediaRead)`. Un bouton secondaire « Téléverser » dans la modale délègue au téléversement existant (`uploadMedia`) sans nouvel outil. Utilisé par les formulaires dispositif (visuel) et ressource (document). Champ de formulaire associé : aperçu + bouton « Choisir » + bouton « Retirer ».

**Justification** : la spec (FR-013) exige le choix dans la médiathèque et interdit un nouvel outil de téléversement ; le picker sélectionne l'existant et réutilise l'upload existant. Le composant servira aussi aux lauréats (feature 022) et aux partenaires.

**Alternative écartée** : saisie de l'UUID (levées de fonds) — inutilisable par un éditeur.

---

## R6. Identification du service DDE

**Constat** : la table `services` (`04_organization.sql`) n'a **pas de colonne `slug`** ; elle a `id` UUID, `name` (FR), `name_en`, `name_ar`, `sigle`. Les listes admin actualités / événements n'acceptent pas de filtre par service dans l'URL.

**Décision** : la clé éditoriale devient **`entrepreneurship.dde_service_id`** (UUID du service, `value_type = 'text'`), prérenseignée par la migration :
```sql
INSERT INTO editorial_contents (key, value, value_type, category_id, description)
SELECT 'entrepreneurship.dde_service_id',
       COALESCE((SELECT id::text FROM services WHERE name ILIKE '%Développement et de l''Entrepreneuriat%' ORDER BY created_at LIMIT 1), ''),
       'text', (SELECT id FROM editorial_categories WHERE code = 'values'),
       'Identifiant du service DDE (organigramme) auquel sont rattachés actualités, événements et albums du PÔLE'
ON CONFLICT (key) DO NOTHING;
```
Le tableau de bord lit la clé ; si vide → avertissement ; sinon les raccourcis ouvrent `/admin/contenus/actualites`, `/admin/contenus/evenements` (listes complètes, aucun filtre supporté aujourd'hui) et `/admin/organisation/services` avec `?service_id=<uuid>` (paramètre ignoré s'il n'est pas supporté, prêt pour la feature 023). Le nom du service est affiché sur le tableau de bord via `GET /api/public/services/{id}` pour confirmer la cible.

**Justification** : la clarification Q3 parlait de « slug » en supposant qu'il existait ; l'UUID est l'identifiant stable disponible. La spec est corrigée en conséquence (FR-017b, FR-021, FR-022, Clarifications).

---

## R7. Page éditoriale « Entrepreneuriat »

**Constat** : `editorial_contents` est mono-valeur (`key`, `value TEXT`, `value_type ∈ text|number|json|html|markdown`) et **non multilingue** ; le repli se fait sur i18n. Les clés sont créées à la volée par la page « Valeurs » ; les types de champ disponibles : `text`, `textarea`, `number`, `html` (édité dans un `<textarea>`, pas de WYSIWYG), `image` (UUID média, upload via `AdminEditorialImageField`), `file`, `list`, `gallery`, `documents`, `countries`, `navitems`. Les chiffres clés du site vivent en `stats_*` (store `keyFigures`, liste codée en dur) + libellés par page.

**Décision** :
- Nouvelle entrée `frontOfficePages` : `{ id: 'entrepreneurship', name: 'Page Entrepreneuriat (PEI)', slug: '/entrepreneuriat', icon: 'lightbulb', sections: entrepreneurshipPageSections }`.
- Chiffres clés : **4 couples de clés `text`** propres à la page (`entrepreneurship.stats.N.value` / `.label`), tous éditables dans « Valeurs », sans toucher au store `keyFigures` (les valeurs PEI sont des textes du type « 500+ », non numériques).
- Slider : 3 champs `image` (`entrepreneurship.hero.slide1..3.image`).
- Présentation riche : type `html` (une seule valeur, FR). Le futur mini-site (023) l'affichera via `RichTextRenderer`.
- Ajout des clés au type `ValueSectionKey` (`app/types/api/editorial.ts`) — obligatoire pour typer `editorialKeys`.
- Migration de seed : `INSERT ... ON CONFLICT (key) DO NOTHING`, catégorie `values`, format des migrations 011/040. Les clés `image` sont seedées vides (`''`) pour apparaître comme « Non défini ».

**Alternatives écartées** : stocker les chiffres en `stats_*` (nécessite d'éditer la liste `PREDEFINED_KEY_FIGURES` et impose des entiers) ; type `json` unique pour les 4 chiffres (non éditable dans « Valeurs »).

---

## R8. Traduction automatique et action « Traduire les champs manquants »

**Décision** :
- À la création : `await autofill_translations(obj, _PROGRAM_TRANSLATABLE)` avant `db.add`. À la modification : application des changements puis `autofill_translations(obj, fields)` (force=False → ne remplit que les vides, préserve les corrections manuelles). Listes : programmes `title, tagline, highlight (text)`, `content_html (html)`, `content_md (text)` ; cohortes `label, focus (text)`, `summary_html (html)`, `summary_md (text)` ; ressources `title, description, category (text)`.
- Action en lot : `POST /api/admin/entrepreneurship/translate-missing` (permission `entrepreneurship.edit`), itère les trois tables, appelle `autofill_translations(force=False)`, compte les objets modifiés (comparaison avant/après), commit, audit `entrepreneurship.translate_missing`, réponse `{ programs: n, cohorts: n, resources: n }`. Rejouable : second appel → 0.
- Boutons « Traduire » de prévisualisation dans les formulaires (convention `POST .../translate` sans persistance, clés i18n `adminTranslate.*`) : **inclus**, un endpoint par entité (`/programs/translate`, `/cohorts/translate`, `/resources/translate`), déclaré avant `/{id}`.

**Justification** : `autofill_translations` est non bloquant (avale les erreurs réseau) → cas limite « traduction indisponible » couvert sans code. Le comptage avant/après est nécessaire car le helper ne renvoie rien.

---

## R9. Lecture publique et URL des médias

**Décision** : routeur `app/routers/public/entrepreneurship.py`, préfixe `/entrepreneurship`, `Cache-Control: public, max-age=60, stale-while-revalidate=300` (comme FAQ). Réponses avec les trois langues (le front applique `useLocalizedField`). URL de média via `resolve_media_url(Media)` de `app/core/media_utils.py` après `outerjoin(Media, X.cover_image_external_id == Media.id)` (gère `is_external_url`), champ de sortie `cover_image_url` / `media_url` ; l'UUID brut n'est pas exposé en public. Routes : `GET /programs`, `GET /programs/{code}`, `GET /cohorts`, `GET /cohorts/{code}`, `GET /resources`. Filtre `active IS TRUE` / `is_published IS TRUE`, tri `display_order, created_at`.

---

## R10. Permissions et protection des routes admin

**Décision** :
- Migration : `INSERT INTO permissions (code, name_fr, description, category)` codes `entrepreneurship.view|create|edit|delete`, catégorie `entrepreneurship`, `ON CONFLICT (code) DO NOTHING` ; attribution `FROM roles r, permissions p WHERE r.code IN ('super_admin', 'admin', 'editor') AND p.code IN (...) ON CONFLICT DO NOTHING`. Même bloc ajouté dans `99_data_init.sql` (base neuve).
- Frontend : entrée `useAdminSidebar.ts` (section avec 4 enfants) **et** entrée `ROUTE_PERMISSIONS['/admin/entrepreneuriat'] = ['entrepreneurship.view']` dans `usePermissions.ts` (le middleware global `admin-auth.global.ts` ne protège que les routes listées ; la FAQ a oublié cette entrée).
- Le rôle `admin` est inclus en plus de `super_admin` et `editor` (pratique de la migration 043 ; `super_admin` contourne de toute façon la vérification).

---

## R11. Libellés du backoffice

**Décision** : libellés **français codés en dur** dans les pages et composants (convention de 90 % du backoffice : dashboard, levées de fonds, actualités, organisation, éditorial), sauf le bouton « Traduire » qui réutilise `adminTranslate.*`. Pas de fichier i18n `entrepreneurship.json` pour l'admin.

**Justification** : la FAQ est la seule exception i18n ; CLAUDE.md impose le français avec accents ; aucune exigence d'admin multilingue dans la spec. Économise ~120 clés × 3 langues.

---

## R12. Structure des pages admin

**Décision** (clarification Q2) : pages dédiées, gabarit FAQ « pages minces + composants » :
- `pages/admin/entrepreneuriat/index.vue` (tableau de bord), `dispositifs/{index,nouveau,[id]}.vue`, `cohortes/{index,nouveau,[id]}.vue`, `ressources/{index,nouveau,[id]}.vue` ; `definePageMeta({ layout: 'admin' })`.
- Composants `components/entrepreneurship/admin/{ProgramList,ProgramForm,CohortList,CohortForm,ResourceList,ResourceForm,DashboardCards}.vue` (auto-import `EntrepreneurshipAdmin*`).
- Contenu riche : `<AdminRichTextEditor mode="modal">` avec les 6 v-model (md/html × fr/en/ar) — porte les onglets de langue ; champs simples trilingues : trois `<input>` (AR en `dir="rtl"`) groupés sous un sélecteur d'onglet FR/EN/AR local au formulaire (petit composant `LangTabs` interne au dossier, la FAQ affiche les 3 langues côte à côte).
- Confirmations de suppression : modale `<Teleport to="body">` (levées de fonds) plutôt que `window.confirm` ; erreurs : bandeau inline.
- Sélecteurs d'enum : `<select>` natif + tableaux `xxxOptions`/`xxxLabels`/`xxxColors` exportés du composable (convention projet).
- Couleur : pastilles radio (5 couleurs nommées → classes Tailwind), `<span :class>`; aucun `input[type=color]`.

---

## R13. Tests

**Décision** : backend `pytest` (base `usenghor_test`, fixtures `authenticated_client`, `admin_role` + fixture locale `entrepreneurship_permissions`), fichiers `tests/integration/test_admin_entrepreneurship_api.py`, `tests/integration/test_public_entrepreneurship_api.py`, `tests/unit/test_entrepreneurship_service.py` (validation ressources, renumérotation). Frontend : aucune infrastructure de test n'existe (vitest installé mais non configuré) → validation manuelle via quickstart + `pnpm lint` + `pnpm build`. Ne pas introduire la config vitest dans cette feature (hors périmètre).

---

## R14. Rejeu de la migration et rollback

**Décision** : `045_entrepreneurship.sql` : `BEGIN; ... COMMIT;`, types ENUM via `DO $$ ... EXCEPTION WHEN duplicate_object THEN NULL END $$`, `CREATE TABLE IF NOT EXISTS`, index `IF NOT EXISTS`, triggers `updated_at` gardés par `IF NOT EXISTS (SELECT 1 FROM pg_trigger ...)`, seeds `ON CONFLICT (code|key) DO NOTHING`. `045_entrepreneurship_rollback.sql` : `DROP TABLE IF EXISTS` (3 tables), `DROP TYPE IF EXISTS` (3 types), suppression des `role_permissions` puis `permissions`, suppression des clés `editorial_contents` `entrepreneurship.%` (et leur historique par cascade). Vérification SC-005 : exécuter deux fois puis comparer `COUNT(*)`.
