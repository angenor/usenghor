# Quickstart — Validation des rubriques alumni, partenaires, ressources, actualités (024)

Guide de validation de bout en bout. Contrats : [contracts/](contracts/), modèle : [data-model.md](data-model.md), décisions : [research.md](research.md).

## Prérequis

- Migrations 045 → 047 jouées ; features 021–023 déployées en local (accueil `/entrepreneuriat` et `/entrepreneuriat/activites` fonctionnels).
- Backend : `cd usenghor_backend && docker compose up -d && source .venv/bin/activate && uvicorn app.main:app --reload`.
- Frontend : `cd usenghor_nuxt && pnpm install && pnpm dev` (http://localhost:3000 ; si le port est pris, autre port + `NUXT_INTERNAL_API_BASE`).
- Backoffice : identifiants dans `usenghor_backend/.env` (`ADMIN_EMAIL`, `ADMIN_PASSWORD`).

## 1. Migration 048 (après accord sur le SQL — FR-024, SC-010)

```bash
cd usenghor_backend/documentation/modele_de_données/migrations
docker exec -i usenghor_postgres psql -U usenghor -d usenghor < 048_pei_public_pages_keys.sql
docker exec -i usenghor_postgres psql -U usenghor -d usenghor < 048_pei_public_pages_keys.sql   # rejeu : 0 erreur
docker exec -i usenghor_postgres psql -U usenghor -d usenghor -c "SELECT count(*) FROM editorial_contents WHERE key LIKE 'entrepreneurship.%';"   # attendu : 74 (48 + 26)
```

Modifier `entrepreneurship.alumni.stats.1.value` dans Admin → Valeurs → Entrepreneuriat → « Nos alumni », rejouer : la valeur est conservée. Rollback (`…_rollback.sql`) → 48 ; rejeu → 74.

## 2. Non-régression backend (aucun changement attendu)

```bash
cd usenghor_backend && source .venv/bin/activate
pytest tests/integration/test_public_entrepreneurship_api.py tests/integration/test_public_events_service_filter.py -v
```

Note : les tests FAQ appellent le vrai traducteur (quota) ; ne lancer que les fichiers ci-dessus.

## 3. Préparation des données (backoffice)

1. Entrepreneuriat → Cohortes : 3 cohortes FSE actives (focus et bilan renseignés sur au moins une), 1 cohorte SEE active.
2. Entrepreneuriat → Lauréats : ≥ 6 portraits FSE publiés répartis sur les 3 cohortes (dont 1 **mis en avant** placé en dernière position de sa cohorte, 1 avec verbatim + site + vidéo, 1 sans photo), ≥ 2 étudiants-entrepreneurs publiés, 1 portrait **dépublié**.
3. Entrepreneuriat → Partenaires du pôle : partenaires dans 2 familles (1 sans logo, 1 sans site web, 1 **inactif** dans Partenaires).
4. Entrepreneuriat → Ressources : 2 catégories (« Financement », « Juridique »), 1 document (PDF de la médiathèque), 1 lien, 1 vidéo YouTube, 1 ressource **sans catégorie**, 1 **dépubliée**.
5. Organisation → service DDE → Médiathèque : 2 albums (photos + 1 vidéo hébergée), 1 album vide.
6. Contenus → Actualités : ≥ 15 actualités publiées rattachées à la DDE (dont **1 rattachée à la fois à la DDE et à un autre service**) + 2 d'un autre service seulement. Contenus → Événements : 3 à venir + 5 passés rattachés à la DDE (dont 1 **commencé hier et se terminant demain**) + 1 d'un autre service ; pour tester les lots, prévoir en option 12 événements à venir.
7. Valeurs → Entrepreneuriat : vérifier `dde_service_id`, `contact.email`, l'encart mentor ; choisir (ou laisser vide) les images des quatre heros.

## 4. `/entrepreneuriat/alumni` (US1, SC-001–SC-003)

- SSR : `curl -s http://localhost:3000/entrepreneuriat/alumni | grep -c "Portraits de lauréats"` → ≥ 1 ; `curl -s "http://localhost:3000/entrepreneuriat/alumni?type=student_entrepreneur" | grep -c "aria-current"` → l'onglet SEE est actif dans le HTML initial.
- Navigateur : hero (badge « Portraits et témoignages », titre, sous-titre, fil d'Ariane 6 niveaux avec « DDE » cliquable), sous-nav « Nos alumni » active, 2 pilules, bandeau 3 chiffres (compteur animé sur « 15 » et « 3 », « 5 000 € » tel quel), titre de section, 3 sections de cohorte dans l'ordre du backoffice (titre, année · focus, badge, bilan), portraits : le **mis en avant** est premier de sa cohorte, verbatim en italique, exactement les icônes des liens renseignés (nouvel onglet), substitut pour le portrait sans photo.
- Cliquer « Étudiants entrepreneurs » : adresse `?type=student_entrepreneur` sans rechargement, retour arrière du navigateur → onglet FSE. `?type=foo` → onglet FSE, aucune erreur.
- Dépublier un portrait, attendre ≤ 60 s, recharger : disparu ; dépublier tous les portraits d'une cohorte : la section disparaît ; dépublier tous les SEE : onglet SEE → état vide propre, onglets toujours visibles.
- Vider `alumni.stats.2.value` : 2 chiffres ; vider les 3 : bandeau masqué. Vider `contact.email` : encart mentor masqué. « Devenir mentor » ouvre le client de messagerie avec l'adresse du pôle.

## 5. `/entrepreneuriat/partenaires` (US2)

- 2 familles seulement, ordre fixe, intitulés traduits ; cartes : logo ou nom, description, lien « Visiter le site » (nouvel onglet) seulement si site web ; partenaire inactif absent ; désactiver le dernier d'une famille → famille disparue ; aucun partenaire → état vide.
- `/entrepreneuriat` : section « Un écosystème d'appui » **inchangée** (variante logos) ; `/a-propos/partenaires` inchangée.

## 6. `/entrepreneuriat/ressources` (US3, SC-004)

- Bloc « Médiathèque » : 2 cartes d'album (l'album vide absent) ; ouvrir → visionneuse (grille, filtre « Vidéos », lecture de la vidéo hébergée, fermeture).
- Bloc « Boîte à outils » : groupes « Financement », « Juridique », puis « Autres ressources » ; la ressource dépubliée absente ; « Télécharger » → le PDF se télécharge (`?download=1`) ; « Ouvrir » → nouvel onglet ; carte vidéo avec vignette YouTube → nouvel onglet YouTube.
- Vider `dde_service_id` : bloc Médiathèque masqué, boîte à outils toujours là ; dépublier toutes les ressources **et** retirer les albums : état vide de page.
- `/mediatheque` et la fiche du service DDE (onglet médiathèque) inchangées.

## 7. `/entrepreneuriat/actualites` (US4)

- SSR : `curl -s http://localhost:3000/entrepreneuriat/actualites | grep -o 'href="/actualites/[^"]*"' | sort -u | wc -l` → 12 (premier lot).
- Navigateur : 12 cartes identiques à celles de `/actualites` (comparer une même actualité côte à côte), aucune actualité d'un autre service, l'actualité multi-services présente **une seule fois** ; « Voir plus » → 3 cartes de plus, puis bouton disparu.
- Événements : « Événements à venir » (3, du plus proche au plus lointain) puis « Événements passés » (5, du plus récent au plus ancien, l'événement commencé hier classé ici et nulle part ailleurs), chaque entrée → fiche existante ; retirer tous les passés → sous-bloc masqué ; tout retirer (actualités + événements) → état vide.
- Lots d'événements (option 12 à venir) : « À venir » affiche 10 puis « Voir plus » → 12 ; « Passés » affiche ses 5 dès le premier lot (aucun futur ne s'y glisse).
- `/actualites` : capture avant / après identique (1440 px, 390 px).

## 8. Trilingue et RTL (US5, SC-007)

- Ouvrir les 4 pages en `/en/…` et `/ar/…` : libellés fixes traduits (pilules, titres de blocs, boutons, états vides, `aria-label` des icônes), aucune clé `pei.` visible, données trilingues dans la langue (repli FR pour un portrait sans département EN), copie éditoriale en FR.
- Arabe : `dir="rtl"`, pilules / bandeau / cartes / icônes en miroir, séparateurs du bandeau corrects (`rtl:divide-x-reverse`).

## 9. Responsive et sombre (SC-008)

- 390 px : grilles en 1 colonne, pilules et sous-nav défilantes, bandeau empilé, aucun défilement horizontal (`document.documentElement.scrollWidth === window.innerWidth`).
- Mode sombre : cartes, bandeau, encart mentor, états vides lisibles ; pas de zone blanche non prévue (logos de partenaires restent sur fond blanc volontaire).
- Lighthouse mobile ≥ 90 performance / accessibilité sur les 4 pages.

## 10. SEO (SC-009)

- `curl -s http://localhost:3000/sitemap.xml | grep -c "entrepreneuriat/"` → ≥ 18 (6 pages × 3 langues).
- `curl -s http://localhost:3000/entrepreneuriat/ressources | grep -o '<meta property="og:[^>]*>'` → title, description, url, image (si hero image), locale, locale:alternate.
- JSON-LD : extraire les 3 scripts `application/ld+json` (`Organization`, `CollectionPage`, `BreadcrumbList` à 6 éléments) et les valider (validator.schema.org).
- Alumni : `og:url` contient `?type=student_entrepreneur` sur l'onglet SEE.

## 11. Build et non-régression (SC-006, SC-011)

```bash
cd usenghor_nuxt && NODE_OPTIONS=--max-old-space-size=8192 pnpm build
```

Captures avant / après (1440 px et 390 px) : `/actualites`, `/a-propos/partenaires`, `/entrepreneuriat`. Inventaire des routes : exactement 4 pages nouvelles sous `app/pages/entrepreneuriat/`, aucune page d'article / événement / album / partenaire.

**Résultat (2026-09-14, local)** : `nuxi build` OK (heap 8 Go, copie isolée) ; doublon d'auto-import `cohortTypeForLaureateType` détecté puis supprimé (réutilisation de la table de `useEntrepreneurshipApi`) ; sitemap de production : 6 URL `entrepreneuriat` par langue (18) ; `pytest` non-régression 10/10. Pages : `index.vue`, `activites.vue` + `alumni.vue`, `partenaires.vue`, `ressources.vue`, `actualites.vue` (4 nouvelles). Rendu contrôlé avec un jeu de test temporaire (supprimé) : 390 px sans défilement horizontal, sombre, RTL, 0 erreur JS. Captures avant / après (serveur de dev, modifications mises de côté par `git stash` le temps des captures « avant ») de `/actualites`, `/a-propos/partenaires` et `/entrepreneuriat` à 1440 et 390 px : identiques au pixel près, hors badge de temps de Nuxt DevTools.

## 12. Documentation

CLAUDE.md : routes `/entrepreneuriat/{alumni,partenaires,ressources,actualites}`, composable `usePeiPage`, composants `PillTabs`, `CohortSection`, `LaureateCard`, `ResourceCard`, `EmptyState`, variantes `StatsPanel` / `PartnerFamilies` / `CtaBanner` / `EventList`, migration 048 (26 clés, 73 clés `entrepreneurship.*`), entrée « Recent Changes » 024.

## 13. Production (SC-010)

Après `git push origin main` (frontend et backend) et `./deploy.sh update` (avec `--force-recreate` si les conteneurs ne sont pas recréés) :

```bash
docker exec -i usenghor_db psql -U usenghor -d usenghor < usenghor_backend/documentation/modele_de_données/migrations/048_pei_public_pages_keys.sql
docker exec -i usenghor_db psql -U usenghor -d usenghor < usenghor_backend/documentation/modele_de_données/migrations/048_pei_public_pages_keys.sql   # rejeu : 0 erreur
docker exec -i usenghor_db psql -U usenghor -d usenghor -c "SELECT count(*) FROM editorial_contents WHERE key LIKE 'entrepreneurship.%';"   # +26 par rapport à l'état antérieur
```

Puis ouvrir les quatre pages publiques : heros renseignés, sous-nav sans rubrique « introuvable ». Consigner ici le compte obtenu et la date.
