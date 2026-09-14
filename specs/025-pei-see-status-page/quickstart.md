# Quickstart — Validation de la page SEE (025)

Contrats : [contracts/](contracts/) · modèle et SQL : [data-model.md](data-model.md) · décisions : [research.md](research.md).

## Prérequis

- Migrations 045 → 048 jouées ; features 023 / 024 fonctionnelles en local.
- Backend : `cd usenghor_backend && docker compose up -d && source .venv/bin/activate && uvicorn app.main:app --reload`.
- Frontend : `cd usenghor_nuxt && pnpm dev` (si le port 3000 est pris : autre port + `NUXT_INTERNAL_API_BASE`, heap 8 Go).
- Admin : identifiants dans `usenghor_backend/.env`.
- **Avant tout changement** : captures 1440 px et 390 px de `/faq`, `/actualites/appels/<un slug>`, `/entrepreneuriat/alumni` ; `curl -s localhost:3000/faq | grep -o '<script type="application/ld+json">[^<]*FAQPage[^<]*' > /tmp/faq-jsonld-avant.txt` (via `git stash` si le code a déjà changé).

## 1. Migration 049 (après accord — FR-025, SC-009)

```bash
M=usenghor_backend/documentation/modele_de_données/migrations
docker exec -i usenghor_postgres psql -v ON_ERROR_STOP=1 -U usenghor -d usenghor < $M/049_pei_see_page.sql
docker exec -i usenghor_postgres psql -v ON_ERROR_STOP=1 -U usenghor -d usenghor < $M/049_pei_see_page.sql   # rejeu : INSERT 0 0 ×3
docker exec usenghor_postgres psql -U usenghor -d usenghor -tAc "SELECT (SELECT count(*) FROM editorial_contents WHERE key LIKE 'entrepreneurship.%'), (SELECT count(*) FROM faq_categories WHERE code LIKE 'see-%'), (SELECT count(*) FROM faq_entries WHERE slug LIKE 'see-%'), (SELECT count(*) FROM faq_entries WHERE slug LIKE 'see-%' AND is_published)"
# attendu en local : 138|4|8|2
```

Modifier `see.levers.4.title` (Valeurs) et une réponse FAQ, rejouer : valeurs conservées. Rollback → `73|0|0|0` ; rejeu → `138|4|8|2`.

## 2. Backend (SC-007)

```bash
cd usenghor_backend && source .venv/bin/activate
pytest tests/integration/test_public_faq_api.py -v          # nouveaux cas préfixe + non-régression (les cas dépendant du vrai traducteur peuvent échouer : gotcha quota)
curl -s 'localhost:8000/api/public/faq' | jq '[.categories[].code]'                       # toutes les catégories actives, forme inchangée
curl -s 'localhost:8000/api/public/faq?category_prefix=see-' | jq '[.categories[] | {code, n: (.entries|length)}]'   # 4 catégories see-*, 2 entrées
curl -s -o /dev/null -w '%{http_code}\n' 'localhost:8000/api/public/faq?category_prefix=SEE%25'   # 422
```

Admin → Entrepreneuriat (PEI) → « Traduire les champs manquants » : message incluant « 2 questions FAQ » ; `question_en` / `answer_ar_html` des deux entrées publiées remplis ; brouillons non traduits.

## 3. Cas d'appel (US1, US3, SC-003)

Créer en backoffice un appel `training` publié, calendrier de 6 étapes (dont une le jour de la date limite), 3 critères, 4 pièces ; renseigner son slug dans `see.call_slug`. Pour chaque ligne, modifier l'appel puis ouvrir `/entrepreneuriat/statut-etudiant-entrepreneur` :

| # | Réglage | Attendu (badge agenda · bouton panneau · bouton CTA · badge hero) | HTTP |
|---|---|---|---|
| 1 | `ongoing`, date limite future, formulaire interne | Appel ouvert · → `/candidatures/postuler/<slug>` · idem · « … · Appel 2026 » | 200 |
| 2 | idem + `external_form_url` | Appel ouvert · nouvel onglet externe · idem | 200 |
| 3 | `ongoing`, sans URL, `use_internal_form = false` | Appel ouvert · « Écrire au pôle » (mailto) · mailto | 200 |
| 4 | `upcoming`, `opening_date` renseignée | Appel à venir · « Ouverture … le … » + mailto · mailto | 200 |
| 5 | `closed` | Appel clos · message « appel clos » + mailto, frise visible · mailto | 200 |
| 6 | `ongoing`, date limite passée | comme 5 | 200 |
| 7 | appel dépublié / slug inexistant / clé vide | message « appel clos », pas de frise · mailto · badge hero sans année | 200 |

Vérifier aussi : étape du jour de la date limite en pastille rouge ; sans correspondance, ligne « Date limite de soumission » insérée ; conditions et pièces = celles de l'appel ; vider les critères de l'appel → conditions éditoriales ; cas 7 → conditions et pièces éditoriales. `curl -s -o /dev/null -w '%{http_code}' localhost:3000/entrepreneuriat/statut-etudiant-entrepreneur` → 200 dans tous les cas.

## 4. Guide éditorial (US4, SC-010)

Admin → Valeurs → Entrepreneuriat → « Statut Étudiant-Entrepreneur » : 69 champs. Modifier le titre et l'icône (`fa-solid fa-bolt`) du levier 4, vider `see.conditions.2` (avec un appel sans critères), vider `see.pepite.url` puis la renseigner : rechargement → rendu conforme ; icône `fa-foo` → icône neutre ; aucune clé brute.

## 5. FAQ (US2, SC-004, SC-005)

- Page SEE : 2 groupes (« Généralités », « Avantages et aménagements ») et 2 questions ; ouvrir les deux simultanément ; aucune barre de recherche.
- Compléter et publier « Mon idée sera-t-elle protégée ? » → groupe « Confidentialité » visible au rechargement (≤ 60 s), sans redéploiement.
- `…/statut-etudiant-entrepreneur#see-statut-payant` → question dépliée et visible sous la sous-navigation.
- Données structurées : `curl -s localhost:3000/entrepreneuriat/statut-etudiant-entrepreneur | grep -c '"FAQPage"'` → 1 ; validateur schema.org : FAQPage (questions SEE publiées seulement), BreadcrumbList, WebPage, Organization valides. Dépublier toutes les entrées SEE → section FAQ et FAQPage absentes.
- `/faq` : groupes SEE publiés visibles après les catégories existantes ; recherche, filtre, ancres OK ; `diff` du JSON-LD avant / après = seules les questions SEE ajoutées ; aucune réponse « Réponse à rédiger… » visible nulle part.

## 6. Sous-navigation et cadre (SC-001)

- Liens hero et CTA de `/entrepreneuriat` et bouton de la sous-nav → page 200 en FR, EN, AR.
- Sur la page SEE : aucun onglet `aria-current`, bouton rouge `aria-current="page"` avec halo ; sur `/entrepreneuriat/alumni` : bouton sans halo.
- Fil d'Ariane : Accueil › Nous connaître › Organisation › DDE › Pôle Entrepreneuriat et Innovation › Entreprendre et étudier.

## 7. Agenda collant (FR-012, SC-006)

1440 px : défiler la section « Suis-je le bon candidat ? » → panneau visible sous la sous-nav, sans chevauchement, libéré en fin de section. 1023 px et 390 px : panneau dans le flux après le dossier.

## 8. Langues, RTL, mobile, sombre (US5, SC-008)

`/en/…` et `/ar/…` à 1440 et 390 px, clair et sombre : libellés fixes traduits ; `dir="rtl"` ; frise, grilles, flèches en miroir ; aucune barre de défilement horizontale (`document.documentElement.scrollWidth <= innerWidth`) ; FAQ en anglais avec repli FR pour les entrées non traduites. Lighthouse mobile (FR) : accessibilité ≥ 90, performance comparable à `/entrepreneuriat/alumni`.

## 9. SEO et sitemap

`curl -s localhost:3000/__sitemap__/urls | grep statut-etudiant-entrepreneur` (ou `/sitemap.xml`) → 3 langues ; balises `og:title`, `og:description`, `og:url`, `og:locale` présentes dans le HTML SSR ; contenu principal (titre hero, intro, agenda, questions) présent dans `curl` sans JavaScript.

## 10. Non-régression (FR-031, SC-007)

Captures après : `/faq` (hors groupes SEE), `/actualites/appels/<slug>`, `/candidatures/postuler/<slug>`, `/entrepreneuriat/alumni` (bandeau CTA mentor identique) identiques. `cd usenghor_nuxt && NODE_OPTIONS=--max-old-space-size=8192 pnpm build` sans erreur ni WARN de collision d'auto-import.

## 11. Documentation

CLAUDE.md : composants clés (`EntrepreneurshipSeeAgenda`, variantes `FaqAccordion` et `CtaBanner`, filtre `category_prefix`, convention `see-*`), Recent Changes (025, migration 049), `usePeiPage` (rubrique `see`). Roadmap : feature 025 marquée livrée.
