# Contrat — API publique `/api/public/entrepreneurship` (ajouts 022)

Sans authentification, lecture seule, `Cache-Control: public, max-age=60, stale-while-revalidate=300` (helper `_cache` de 021). Les trois langues sont renvoyées (repli FR côté front via `useLocalizedField`). Aucun UUID de média : `photo_url` et `logo_url` résolus par `resolve_media_url`. Routes statiques `/laureates` et `/partners` déclarées avant les routes dynamiques `/{code}` existantes.

## GET /laureates → `PeiLaureatesPublic`

Query : `type=fse_laureate|student_entrepreneur` (optionnel).

Portraits **publiés** dont la cohorte est **active**, groupés par cohorte (ordre `pei_cohorts.display_order`), portraits triés par `display_order` dans la cohorte. Les cohortes sans portrait publié (après filtre) sont omises. `stats` calculés sur le même jeu.

```json
{
  "groups": [
    {
      "cohort": {
        "id": "uuid", "code": "fse-1", "type": "fse", "year": 2023,
        "label": "FSE 1 · Lancement 2023", "label_en": "…", "label_ar": "…",
        "focus": "Preuve de concept", "focus_en": "…", "focus_ar": "…",
        "summary_html": "…", "summary_en_html": "…", "summary_ar_html": "…",
        "display_order": 2
      },
      "laureates": [
        {
          "id": "uuid", "type": "fse_laureate",
          "full_name": "…", "project_name": "…",
          "department_label": "Département Santé", "department_label_en": "…", "department_label_ar": "…",
          "quote": "« Grâce au FSE 1… »", "quote_en": "…", "quote_ar": "",
          "photo_url": "/api/public/media/…/download",
          "website_url": "https://…", "linkedin_url": null, "instagram_url": null,
          "facebook_url": null, "video_url": "https://…",
          "is_featured": true,
          "cohort_label": "FSE 1 · Lancement 2023", "cohort_label_en": "…", "cohort_label_ar": "…",
          "display_order": 0
        }
      ]
    }
  ],
  "stats": { "laureates": 15, "cohorts": 3, "max_grant_amount": "5000.00" }
}
```

Non exposés : `grant_amount` individuel, `published_at`, auteurs. `cohort_label*` répète le libellé de la cohorte pour le badge de la carte. `max_grant_amount` : chaîne décimale ou `null` si aucun montant saisi.

## GET /partners → `PeiPartnerFamilyPublic[]`

Toujours **trois** groupes dans l'ordre fixe `academic`, `support`, `international` (liste vide si aucun partenaire). Partenaires rattachés dont `partners.active = TRUE`, triés par `display_order`. Un partenaire supprimé du backoffice Partenaires n'a plus de rattachement (cascade) : aucune erreur.

```json
[
  { "family": "academic",
    "partners": [
      { "id": "uuid", "name": "Campus France",
        "description": "…", "description_en": "…", "description_ar": "…",
        "website": "https://…", "logo_url": "/api/public/media/…/download",
        "type": "other", "display_order": 0 }
    ] },
  { "family": "support", "partners": [] },
  { "family": "international", "partners": [ … ] }
]
```

Aucun réseau social (clarification Q2). `logo_url` est `null` si le partenaire n'a pas de logo ou si le média n'existe plus.
