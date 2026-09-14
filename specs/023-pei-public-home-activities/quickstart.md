# Quickstart — Validation du mini-site PEI (023)

Guide de validation de bout en bout. Contrats : [contracts/](contracts/), modèle : [data-model.md](data-model.md).

## Prérequis

- Migrations 045 et 046 jouées (données initiales : 5 dispositifs, 3 cohortes, partenaires rattachés) ; « Traduire les champs manquants » lancé.
- Backend : `cd usenghor_backend && docker compose up -d && source .venv/bin/activate && uvicorn app.main:app --reload`.
- Frontend : `cd usenghor_nuxt && pnpm install && pnpm dev` (http://localhost:3000).
- Backoffice : identifiants dans `usenghor_backend/.env` (`ADMIN_EMAIL`, `ADMIN_PASSWORD`).

## 1. Migration 047 (après accord sur le SQL)

```bash
cd usenghor_backend/documentation/modele_de_données/migrations
docker exec -i usenghor_postgres psql -U usenghor -d usenghor < 047_pei_activities_hero_keys.sql
docker exec -i usenghor_postgres psql -U usenghor -d usenghor < 047_pei_activities_hero_keys.sql   # rejeu
docker exec -i usenghor_postgres psql -U usenghor -d usenghor -c "SELECT count(*) FROM editorial_contents WHERE key LIKE 'entrepreneurship.%';"   # attendu : 47
```
Modifier `entrepreneurship.activities.hero.title` dans Admin → Valeurs → Entrepreneuriat, rejouer : la valeur est conservée (SC-011). Rollback (43) puis rejeu : 47 à nouveau.

## 2. Backend — filtre des événements

```bash
cd usenghor_backend && source .venv/bin/activate
pytest tests/integration/test_public_events_service_filter.py -v
curl -s "http://localhost:8000/api/public/events?service_id=<UUID_DDE>&upcoming=true&order=asc&limit=6" | jq '.items[] | {title, start_date}'
curl -s "http://localhost:8000/api/public/events?order=foo" -o /dev/null -w "%{http_code}\n"   # 422
```
`<UUID_DDE>` = `SELECT value FROM editorial_contents WHERE key = 'entrepreneurship.dde_service_id';`.

## 3. Préparation des données (backoffice)

1. Valeurs → Entrepreneuriat : choisir 3 images de slider, la photo de l'auteur et le visuel d'impact, l'image du hero « Nos activités » ; vérifier `dde_service_id`.
2. Contenus → Actualités : au moins 4 actualités publiées rattachées au service DDE.
3. Contenus → Événements : 2 événements publiés à venir + 1 passé rattachés à la DDE.
4. Entrepreneuriat → Partenaires du pôle : au moins un partenaire dans deux familles.

## 4. Accueil `/entrepreneuriat` (US1, SC-001, SC-002)

- `curl -s http://localhost:3000/entrepreneuriat | grep -c "INNOVER"` → ≥ 1 (contenu SSR) ; idem `grep -c "Parcours OSER"`.
- Navigateur : hero (badge, slogan, sous-titre, 2 boutons, 3 points), sous-nav collante (« Présentation » active), présentation + panneau de 4 chiffres, 5 cartes numérotées avec couleur, chips, lien « Voir toutes nos activités », encadré citation, 3 actualités, familles de partenaires, CTA (mailto + bouton).
- Fil d'Ariane : « DDE » mène à la fiche service ; les niveaux « Accueil », « Nous connaître », « Organisation » mènent aux pages existantes.
- « Découvrir le parcours » défile vers `#parcours` ; une carte mène à `/entrepreneuriat/activites#phase-…`.
- Modifier un chiffre clé et un titre de dispositif en backoffice, attendre ≤ 60 s, recharger : valeurs mises à jour.

## 5. « Nos activités » `/entrepreneuriat/activites` (US2)

- 5 blocs de phase + bloc écosystème (chips + 2 événements à venir, le passé absent, tri du plus proche au plus lointain).
- Contenu riche des dispositifs rendu (titres, listes, liens) ; visuels affichés quand présents.
- Ancres : barre de phases → défilement sous la sous-nav ; ouvrir directement `/entrepreneuriat/activites#phase-incubation` → position correcte.
- Dépublier tous les événements DDE → liste masquée, aucune erreur.

## 6. Slider et accessibilité (US3, SC-004)

- Clavier seul : Tab jusqu'aux points, Entrée / Espace change de visuel, ← → Home End fonctionnent, focus visible ; la lecture d'écran annonce « Visuel 2 sur 3 ».
- Survol du hero : le défilement s'arrête ; sortie : il reprend (6 s).
- macOS : Réglages → Accessibilité → Réduire les animations ; recharger : aucun changement automatique en 60 s, changement manuel sans transition.
- Retirer 2 images en backoffice → hero image simple sans points ; retirer la dernière → hero à motif.

## 7. Zéro régression (SC-005)

Captures avant / après (1440 px et 390 px) : `/a-propos`, `/a-propos/strategie`, `/a-propos/histoire`, `/a-propos/gouvernance`, `/a-propos/organisation`, une fiche secteur et une fiche service, `/a-propos/equipe`, `/a-propos/partenaires`, `/nousrejoindre`, `/nousrejoindre/candidature-enseignant`, `/candidatures`, une page `postuler`, `/formations/<type>`, une fiche formation, une fiche projet, un appel de projet (+ page postuler), **et `/actualites`** (carte extraite). Diff visuel nul.

**Résultat (2026-09-13, local, 1440 px)** : comparaison du DOM normalisé (hors attributs `data-v-*` et commentaires) et des dimensions du hero, version d'origine (`git stash`) contre version 023, sur `/a-propos`, `/a-propos/strategie`, `/a-propos/histoire`, `/a-propos/gouvernance`, `/a-propos/organisation`, `/a-propos/equipe`, `/a-propos/partenaires`, `/nousrejoindre`, `/nousrejoindre/candidature-enseignant`, `/candidatures`, fiche service `service-animation-culturelle` et grille « Dernières actualités » de `/actualites` : 11 identiques ; `/a-propos/partenaires` ne diffère que par la disparition des attributs orphelins `badge` / `badge-icon` sur la `<section>` (non rendus). Non couverts : fiches formation, projet et appel de projet (pas de données locales), largeur 390 px.

## 8. Trilingue, RTL, responsive, sombre (US4, SC-006, SC-008)

- `/en/entrepreneuriat`, `/ar/entrepreneuriat` (+ `/activites`) : libellés fixes traduits, aucune clé `pei.` ou `entrepreneurship.` visible, données métier localisées avec repli FR ; en arabe `dir="rtl"`, sous-nav et cartes en miroir, flèches retournées.
- Largeur 390 px : cartes en colonne, sous-nav défilante, slider pleine largeur, `document.documentElement.scrollWidth === innerWidth`.
- Mode sombre : aucune zone blanche imprévue sur les deux pages.

## 9. Sections sans données (SC-007)

Vider `dde_service_id` → actualités / événements masqués, « DDE » non cliquable ; retirer tous les partenaires → section masquée ; désactiver tous les dispositifs → section parcours masquée ; arrêter le backend → page SSR rendue avec les sections disponibles (au moins le layout), aucune erreur 500.

## 10. SEO (SC-009)

- `curl -s http://localhost:3000/entrepreneuriat | grep -oE '<meta property="og:[a-z:_]+" content="[^"]*"'` : title, description, url, image, locale, locale:alternate.
- `curl -s http://localhost:3000/entrepreneuriat | grep -c 'application/ld+json'` → ≥ 5 (2 globaux + 3 de la page) ; valider le JSON extrait sur https://validator.schema.org.
- `curl -s http://localhost:3000/sitemap.xml | grep -c entrepreneuriat` → 6 (2 pages × 3 langues).

## 11. Lighthouse mobile (SC-003)

```bash
cd usenghor_nuxt && pnpm lint && pnpm build && node .output/server/index.mjs &
npx lighthouse http://localhost:3000/entrepreneuriat --preset=perf --form-factor=mobile --only-categories=performance,accessibility --output=json --output-path=/tmp/lh-pei.json
npx lighthouse http://localhost:3000/entrepreneuriat/activites --form-factor=mobile --only-categories=performance,accessibility --output=json --output-path=/tmp/lh-pei-act.json
```
Attendu : performance ≥ 90, accessibilité ≥ 90 sur les deux pages.

**Résultat (2026-09-13)** : non mesuré. Lighthouse n'est pas une dépendance du projet ; en local, `npx -y lighthouse@12` avec le Chromium de Playwright échoue (`NO_FCP` en headless) et le serveur `node .output/server/index.mjs` sans nginx renvoie 404 sur `/api/public/media/*` (images du slider absentes, mesure non représentative). À mesurer sur la préproduction ou la production derrière nginx.

## 12. Documentation

CLAUDE.md : routes publiques `/entrepreneuriat`, `/entrepreneuriat/activites`, `usePublicEntrepreneurshipApi()`, `PageHero` (props `images`, `badge`), `EntrepreneurshipSubNav`, `ActualitesNewsCard`, migration 047 dans « Recent Changes ».
