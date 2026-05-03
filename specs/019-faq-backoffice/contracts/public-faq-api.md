# Contract — Public FAQ API

**Branch**: `019-faq-backoffice` | **Date**: 2026-05-02

Endpoint public, lecture seule, sans authentification. Suit la convention `/api/public/*` du projet. Consommé par `usePublicFaqApi.ts` côté Nuxt. Implémenté dans `usenghor_backend/app/routers/public/faq.py`.

---

## `GET /api/public/faq`

Récupère l'arborescence complète des catégories actives et leurs entrées publiées, prête à être rendue par la page `/faq`.

### Request

- **Méthode** : `GET`
- **Authentification** : aucune.
- **Query params** : aucun (pas de pagination, pas de filtrage serveur — recherche client, voir D4).
- **Headers** : standards (Accept-Language honoré pour la cohérence si pertinent, mais le payload contient TOUTES les langues).

### Response — `200 OK`

```json
{
  "categories": [
    {
      "id": "11111111-1111-1111-1111-111111111111",
      "code": "general",
      "label_fr": "Général",
      "label_en": "General",
      "label_ar": "عام",
      "description_fr": null,
      "description_en": null,
      "description_ar": null,
      "display_order": 0,
      "entries": [
        {
          "id": "22222222-2222-2222-2222-222222222222",
          "slug": "comment-postuler",
          "question_fr": "Comment postuler à l'Université Senghor ?",
          "question_en": "How do I apply to Senghor University?",
          "question_ar": "كيف أتقدم بطلب إلى جامعة سنغور؟",
          "answer_fr_html": "<p>La procédure d'admission débute en …</p>",
          "answer_en_html": "<p>The admission process begins …</p>",
          "answer_ar_html": "<p>تبدأ عملية القبول …</p>",
          "display_order": 0,
          "published_at": "2026-05-02T14:32:11Z"
        }
      ]
    }
  ]
}
```

### Règles métier appliquées par le serveur

1. **Filtrage** : seules les `faq_categories` avec `is_active = TRUE` sont incluses. Au sein de chaque catégorie, seules les `faq_entries` avec `is_published = TRUE` sont incluses.
2. **Tri** : catégories triées par `display_order ASC, label_fr ASC` ; entrées triées par `display_order ASC, published_at ASC`.
3. **Repli silencieux FR (D5, Q5)** :
   - Si `question_<lang>` est `NULL` ou vide, retourne la valeur de `question_fr`.
   - Si `answer_<lang>_html` est `NULL` ou vide, retourne la valeur de `answer_fr_html`.
   - Le client reçoit toujours un contenu non vide pour FR/EN/AR.
4. **Markdown source non exposé** : les colonnes `answer_*_md` ne sont JAMAIS retournées sur cet endpoint (économie de bande passante, l'éditeur n'est pas requis côté public).
5. **Catégorie sans entrée publiée** : la catégorie est tout de même retournée avec `entries: []` si elle est active. Le frontend décide de l'afficher ou non.

### Codes d'erreur

- `200 OK` : succès, même si la liste est vide (`{ "categories": [] }`).
- `500 Internal Server Error` : erreur inattendue serveur. Format d'erreur standard du projet : `{ "detail": "string" }`.

### Cache

- Header `Cache-Control: public, max-age=60, stale-while-revalidate=300` (cohérent avec SC-004 « visible en moins de 60 secondes »).
- ETag basé sur `MAX(updated_at)` des deux tables (optionnel — à valider par mesure).

### Performance attendue

- p95 latence < 200 ms (mesuré sans cache HTTP, avec ~150 entrées).
- Payload non compressé < 1 Mo, compressé < 250 Ko avec gzip.

---

## TypeScript types (à générer dans `app/types/api/faq.ts`)

```ts
export interface FaqEntryPublic {
  id: string;          // UUID
  slug: string;
  question_fr: string;
  question_en: string;
  question_ar: string;
  answer_fr_html: string;
  answer_en_html: string;
  answer_ar_html: string;
  display_order: number;
  published_at: string; // ISO 8601
}

export interface FaqCategoryPublic {
  id: string;
  code: string;
  label_fr: string;
  label_en: string;
  label_ar: string;
  description_fr: string | null;
  description_en: string | null;
  description_ar: string | null;
  display_order: number;
  entries: FaqEntryPublic[];
}

export interface FaqTreePublic {
  categories: FaqCategoryPublic[];
}
```

---

## JSON-LD `FAQPage` dérivé (D7, côté frontend)

Le frontend transforme `FaqTreePublic` en JSON-LD à injecter via `useHead` :

```ts
const localized = (e: FaqEntryPublic, lang: 'fr' | 'en' | 'ar') => ({
  '@type': 'Question',
  name: e[`question_${lang}`],
  acceptedAnswer: {
    '@type': 'Answer',
    text: stripHtmlAndTruncate(e[`answer_${lang}_html`], 5000),
  },
});

useHead({
  script: [
    {
      type: 'application/ld+json',
      innerHTML: JSON.stringify({
        '@context': 'https://schema.org',
        '@type': 'FAQPage',
        mainEntity: tree.categories.flatMap((c) =>
          c.entries.map((e) => localized(e, currentLang.value))
        ),
      }),
    },
  ],
});
```
