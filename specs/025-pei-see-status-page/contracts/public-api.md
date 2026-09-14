# Contrat — Lectures publiques (025)

Une seule évolution d'API : paramètre optionnel sur la FAQ publique. Aucune route nouvelle. Lectures appelées depuis le SSR via `useApiBase()` + `$fetch` (aucune lecture admin).

## 1. `GET /api/public/faq` — paramètre additif `category_prefix`

| Paramètre | Type | Obligatoire | Validation | Effet |
|---|---|---|---|---|
| `category_prefix` | string | non | `^[a-z0-9_-]{1,60}$`, sinon **422** | ne renvoie que les catégories actives dont `code` commence par la valeur (comparaison littérale, `_` et `%` échappés) |

- **Sans paramètre** : requête, tri, filtres et forme de réponse **strictement identiques** à l'existant (019) — rétrocompatibilité.
- **Avec paramètre** : même forme `FaqTreePublic` ; catégories actives filtrées, triées `display_order`, `label_fr` ; entrées publiées seulement, triées `display_order`, `published_at` ; repli FR ; les catégories sans entrée publiée restent présentes avec `entries: []` (règle existante — la page SEE les masque).
- En-tête : `Cache-Control: public, max-age=60, stale-while-revalidate=300` (inchangé).

Exemple :

```http
GET /api/public/faq?category_prefix=see-
200 OK
{
  "categories": [
    { "id": "…", "code": "see-general", "label_fr": "Généralités", "label_en": "General information", "label_ar": "معلومات عامة",
      "description_fr": null, "description_en": null, "description_ar": null, "display_order": 10,
      "entries": [
        { "id": "…", "slug": "see-statut-payant", "question_fr": "Le statut est-il payant ?", "question_en": "…", "question_ar": "…",
          "answer_fr_html": "<p>Non, l'obtention du statut est gratuite pour les étudiants en cours de cursus.</p>",
          "answer_en_html": "…", "answer_ar_html": "…", "display_order": 0, "published_at": "2026-09-14T…Z" }
      ] },
    { "code": "see-avantages", "…": "…" },
    { "code": "see-engagement", "entries": [] },
    { "code": "see-confidentialite", "entries": [] }
  ]
}

GET /api/public/faq?category_prefix=SEE%   → 422
```

Composable : `usePublicFaqApi().getTree(options?: { categoryPrefix?: string })` — sans option, URL inchangée.

Tests (`tests/integration/test_public_faq_api.py`) : préfixe → seules les catégories correspondantes ; catégorie inactive exclue ; entrée non publiée exclue ; `_` littéral (préfixe `see_` ne capture pas `seex…`) ; sans paramètre → toutes les catégories actives ; préfixe invalide → 422.

## 2. `GET /api/public/application-calls/{slug}` — inchangé, consommé

- Réponse `ApplicationCallPublicWithDetails` (champs utilisés : [data-model.md § 1.1](../data-model.md)).
- **404** si introuvable **ou** non publié → absorbé côté page (`catch → null`, état `absent`, page 200).
- Aucun appel à `/apply` depuis la page. Composable : `usePublicCallsApi().getCallBySlug(slug)`.

## 3. Lectures déjà utilisées par le cadre de page (inchangées)

- Éditorial : `useEditorialContent('entrepreneurship')` (clés `entrepreneurship.*`).
- Service DDE : `usePublicOrganizationApi().getServiceById(dde_service_id)` (fil d'Ariane).

## 4. Admin — `POST /api/admin/entrepreneurship/translate-missing` (additif)

- Permission inchangée (`entrepreneurship.edit`), audit inchangé (`entrepreneurship.translate_missing`).
- Réponse `PeiTranslateMissingResponse` + `faq_see: int = 0` : nombre d'entrées FAQ **publiées** des catégories `see-*` dont au moins un champ EN/AR vide a été rempli (champs vides seulement, budget de temps partagé, `complete` inchangé).
- Client : `pages/admin/entrepreneuriat/index.vue` cumule `faq_see` et l'ajoute au message (« N question(s) FAQ »), et l'inclut dans le test « passe sans progrès ».
