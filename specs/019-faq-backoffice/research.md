# Phase 0 — Research: Page FAQ managée dans le backoffice

**Branch**: `019-faq-backoffice` | **Date**: 2026-05-02

Toutes les NEEDS CLARIFICATION du Technical Context ont été résolues lors de `/speckit.clarify` (Q1–Q5, voir spec.md § Clarifications). Cette phase consolide les choix techniques restants pour aligner l'implémentation sur les conventions existantes du projet.

---

## D1 — Schéma SQL : table unique vs deux tables

**Decision**: Deux tables distinctes : `faq_categories` (1) ←→ (n) `faq_entries`.

**Rationale**:
- Permet la gestion indépendante de l'ordre des catégories vs l'ordre des entrées dans une catégorie (FR-012).
- Aligne avec la modélisation des autres ressources éditoriales du projet (`projects` + `project_categories`, `editorial_contents` + `editorial_categories`).
- Facilite l'implémentation de FR-014 (refus de suppression d'une catégorie non vide) via FK `ON DELETE RESTRICT`.
- Permet une catégorie par défaut « Général » seedée dans `99_data_init.sql`.

**Alternatives considered**:
- Table unique avec colonne `category_label_*` dénormalisée → rejetée car renommer une catégorie deviendrait un `UPDATE` massif et l'ordre des catégories ne pourrait pas être stable.
- Stocker la FAQ dans `editorial_contents` (JSONB) → rejetée car la feature 018 a justement migré dans l'autre sens (de JSON vers tables dédiées) ; régression contre-productive.

---

## D2 — Stockage du contenu riche multilingue

**Decision**: Pour la réponse, six colonnes par entrée : `answer_fr_md`, `answer_fr_html`, `answer_en_md`, `answer_en_html`, `answer_ar_md`, `answer_ar_html`. Pour la question (texte court non riche), trois colonnes : `question_fr`, `question_en`, `question_ar`.

**Rationale**:
- Cohérent avec la convention CLAUDE.md « double colonne `*_html` + `*_md` pour chaque champ de contenu riche ».
- Évite toute table d'attache (les autres entités du projet n'utilisent pas non plus de jointure pour les langues).
- La question est un texte court (typiquement < 200 caractères) → texte simple, pas Markdown.

**Alternatives considered**:
- Stocker uniquement le Markdown et reconvertir à la volée → rejeté (perf, dépendance Python pour le rendu HTML, divergence avec les autres tables).
- Stocker uniquement le HTML et perdre le Markdown source → rejeté (perte d'info, l'éditeur a besoin du MD pour réouvrir).

---

## D3 — Slug de l'entrée FAQ (ancre URL — Q4)

**Decision**: Colonne `slug VARCHAR(160) NOT NULL UNIQUE` sur `faq_entries`. Génération automatique à la création depuis `question_fr` (transliteration Unicode → ASCII, lower-case, espaces → `-`, suppression caractères non `[a-z0-9-]`, troncature à 120 caractères, suffixe `-2`, `-3`… si collision). Champ éditable manuellement par l'admin.

**Rationale**:
- FR-004a requiert une ancre stable et partageable.
- L'unicité globale (et non par catégorie) simplifie les ancres `/faq#<slug>` indépendantes du chemin de catégorie.
- La génération automatique respecte la convention CLAUDE.md sur le nommage `[a-z0-9_-]`.

**Alternatives considered**:
- Slug = ID UUID → rejeté (URL imbuvable, mauvais pour SEO et partage).
- Unicité par catégorie + URL `/faq/<categorie>/<slug>` → rejeté en Q4 (option B refusée), conserve la simplicité d'une seule page.

---

## D4 — Endpoint public : un seul appel ou plusieurs

**Decision**: Un seul endpoint `GET /api/public/faq` retournant `{ categories: [{ id, label_*, description_*, display_order, entries: [{ id, slug, question_*, answer_*, display_order }] }] }`. Filtrage côté serveur sur `is_active=true` (catégorie) ET `is_published=true` (entrée). Pas de paramètre de pagination.

**Rationale**:
- La recherche est purement client (Q2) → tout doit être disponible en une fois pour rester instantanée.
- Volume max anticipé (~150 questions × ~3 langues × HTML moyen ~2 KB) ≈ 1 Mo non compressé ; gzip ramène à ~150–250 Ko.
- Cohérent avec l'endpoint public `/api/public/albums/by-slug/{slug}` qui charge tout l'album d'un coup.

**Alternatives considered**:
- Endpoints séparés `/categories` et `/entries?category_id=X` → rejeté (N+1 côté client, complexité accrue, recherche transversale impossible sans tout charger).
- Pagination → rejeté (incompatible avec recherche client temps réel, et le volume reste raisonnable).

---

## D5 — Repli silencieux FR (Q5) : où est-il appliqué ?

**Decision**: Appliqué côté backend dans le sérialiseur public uniquement : si `question_<lang>` ou `answer_<lang>_html` est `NULL` ou vide, copier la valeur FR dans le champ correspondant avant retour. Le frontend reçoit donc toujours un contenu non vide pour les trois langues, ce qui simplifie le code Vue et le rendu JSON-LD.

**Rationale**:
- Source unique de la logique de fallback → moins de divergence entre langues ou entre composants.
- Le JSON-LD `FAQPage` (D7) est généré à partir des mêmes données → naturellement cohérent.
- Ne s'applique PAS aux endpoints admin (l'admin doit voir les vrais champs vides pour savoir quoi traduire).

**Alternatives considered**:
- Repli côté frontend uniquement → rejeté (logique dupliquée, risque que JSON-LD diffère de l'affichage).
- Renvoyer un drapeau `is_fallback: true` → rejeté (Q5 valide explicitement le repli silencieux, sans signal visible).

---

## D6 — Authentification & permission (Q1)

**Decision**: Routeur admin protégé par la dépendance/permission existante utilisée par les modules `news` et `events`. Vérification au démarrage de l'implémentation : grep dans `usenghor_backend/app/routers/admin/news.py` et `events.py` pour relever le nom exact de la dépendance/permission, puis le réutiliser strictement à l'identique dans `routers/admin/faq.py`.

**Rationale**:
- Q1 a tranché : pas de nouvelle permission, on réutilise celle déjà attribuée aux éditeurs de news/events.
- Garantit qu'aucun changement de configuration de rôle/permission n'est nécessaire pour la mise en prod.

**Alternatives considered**:
- Créer `faq:manage` → rejeté en Q1 (option C refusée).
- Restreindre au super-admin → rejeté en Q1 (option A refusée).

---

## D7 — Injection JSON-LD `FAQPage` (Q3)

**Decision**: Côté `pages/faq.vue`, utiliser `useHead({ script: [{ type: 'application/ld+json', innerHTML: JSON.stringify(faqPageJsonLd) }] })` au montage SSR. Le JSON-LD inclut uniquement les questions visibles dans la langue active (après application du fallback du backend). Mise à jour côté client si la langue change (Nuxt re-render). Limiter la longueur du `text` à ~5000 caractères (recommandation Google) avec troncature signalée par `…` au-delà.

**Rationale**:
- `useHead` injecte côté serveur (vérifiable via "View Source") → indispensable pour les crawlers.
- Une seule structure `FAQPage` par page (Google ne traite pas plusieurs).
- Cohérent avec la feature 009-og-meta-tags qui utilise `useSeoMeta` / `useHead` pour les métadonnées sociales.

**Alternatives considered**:
- Calculer le JSON-LD côté API et le retourner brut → rejeté (couplage serveur ↔ format SEO, alors que c'est purement une préoccupation de présentation).
- Plusieurs `FAQPage` par catégorie → rejeté (non-conforme aux guidelines Google).

---

## D8 — Audit logs : granularité

**Decision**: Tracer dans `audit_logs` les actions suivantes (action / entité / entity_id / acteur / payload diff) :
- `faq.category.create`, `faq.category.update`, `faq.category.delete`, `faq.category.reorder`
- `faq.entry.create`, `faq.entry.update`, `faq.entry.delete`, `faq.entry.publish`, `faq.entry.unpublish`, `faq.entry.reorder`

L'écriture s'effectue dans le service (`faq_service.py`) après commit de la transaction métier, en réutilisant le helper d'audit existant (à identifier dans `app/services/audit_service.py` ou équivalent — recensement à faire avant l'implémentation).

**Rationale**:
- Couvre intégralement FR-015.
- Granularité par action permet la reconstruction de l'historique éditorial.

**Alternatives considered**:
- Trigger SQL générique → rejeté (perte du contexte utilisateur authentifié, et le projet utilise déjà un service Python pour les autres audits).
- Tracer uniquement create/delete → rejeté (FR-015 exige aussi update et changements de statut).

---

## Synthèse

| ID  | Sujet | Décision condensée |
|-----|-------|---------------------|
| D1  | Schéma | 2 tables : `faq_categories`, `faq_entries` |
| D2  | Multilingue riche | 6 colonnes réponse + 3 colonnes question |
| D3  | Slug | `slug` UNIQUE généré depuis `question_fr` |
| D4  | API publique | endpoint unique `GET /api/public/faq` |
| D5  | Repli FR | côté backend dans sérialiseur public |
| D6  | Permission | permission existante de gestion de contenu (réutilisée) |
| D7  | JSON-LD | `useHead` SSR, `FAQPage` unique |
| D8  | Audit | 10 actions tracées via service existant |

Aucune NEEDS CLARIFICATION ne reste. La phase 1 (data-model + contracts + quickstart) peut commencer.
