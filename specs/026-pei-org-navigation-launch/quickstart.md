# Quickstart — validation de la feature 026

Chaque bloc renvoie aux exigences de [spec.md](spec.md). Détails : [data-model.md](data-model.md), [contracts/api.md](contracts/api.md), [contracts/frontend.md](contracts/frontend.md). Consigner la date et le résultat sous chaque bloc.

## 0. Prérequis et captures de référence (avant tout code)

```bash
cd usenghor_backend && docker compose up -d && source .venv/bin/activate && uvicorn app.main:app --reload   # :8000
cd usenghor_nuxt && NODE_OPTIONS=--max-old-space-size=8192 pnpm dev --port 3001                           # NUXT_INTERNAL_API_BASE=http://localhost:8000
```

Captures **avant** la feature (1440 px et 390 px, clair ; FR et AR) :
- `/a-propos/organisation` ;
- une fiche secteur, une fiche service sans pôle ;
- `/entrepreneuriat` et `/entrepreneuriat/activites` ;
- menu « Plus » ouvert, pied de page ;
- reprise de T039 (023) : une fiche formation, une fiche projet, une fiche appel.

Garder aussi le JSON de `GET /api/public/sectors/with-services`, `GET /api/public/services` et du plan du site (`/__sitemap__/urls` ou `/sitemap.xml`).

> **Résultat § 0 (2026-09-15)** : JSON de référence `with-services`, `services` et plan du site gardés (scratchpad). Captures avant prises sur une copie de travail du frontend à `HEAD` (même backend, même base), 1440 et 390 px, clair, FR + AR : organigramme, fiche secteur `sec-tes`, fiche service sans pôle, fiche DDE, `/entrepreneuriat`, `/entrepreneuriat/activites`, fiches formation / projet / appel (FR). Comparaison par DOM normalisé du contenu (attributs `data-v-*`, commentaires et états d'animation retirés), les pixels variant dans la barre de navigation entre les deux copies (badge de version, outils de dev).

## 1. Base locale : DDE de test, puis migration 050 (FR-010, SC-008)

La base locale n'a pas de DDE (research C8). Créer la donnée de test, **hors migration** :

```sql
INSERT INTO services (id, sector_id, name, sigle, color, display_order)
SELECT 'aaaaaaaa-0000-4000-8000-0000000000dd', id, 'Direction du développement et de l’entrepreneuriat', 'DDE', '#1d4ed8', 2
FROM sectors WHERE code = 'SEC-TES';
```

Puis, deux fois :

```bash
docker exec -i usenghor_postgres psql -U usenghor -d usenghor < usenghor_backend/documentation/modele_de_données/migrations/050_services_parent_landing.sql
```

**Attendu** :
- passage 1 : `PEI : pôle créé`, `Menu : entrée du pôle ajoutée`, `INSERT 0 1` ;
- passage 2 : `déjà présent` ×2, `INSERT 0 0`.

Contrôle :

```sql
SELECT (SELECT count(*) FROM services WHERE sigle = 'PEI') AS pei,
       (SELECT count(*) FROM services WHERE parent_id IS NOT NULL) AS poles,
       (SELECT jsonb_array_length(value::jsonb) FROM editorial_contents WHERE key = 'navbar.secondary.about.children') AS menu,
       (SELECT count(*) FROM short_links WHERE code = 'pei') AS lien;   -- 1 | 1 | n+1 | 1, identiques après le 2e passage
```

> **Résultat (2026-09-15)** : DDE de test créée (`aaaaaaaa-…dd`, `SEC-TES`, apostrophe ’). Passage 1 : `PEI : pôle créé (5e1c0050-…e1ab) sous la DDE`, `Menu : entrée du pôle ajoutée (sort_order 5)`, `INSERT 0 1`. Passage 2 : `pôle déjà présent`, `entrée du pôle déjà présente`, `INSERT 0 0`. Comptes `1 | 1 | 5 | 1` identiques. Rollback ×2 : pôle supprimé, menu revenu à ses 4 entrées identiques, lien et colonnes retirés ; second passage sans erreur (NOTICE « does not exist, skipping »). Rejeu après rollback : pôle recréé, entrée rajoutée, `1 | 1 | 5 | 1`.

## 2. Règles de hiérarchie en base (FR-002, FR-003)

Dans `BEGIN; … ROLLBACK;`, chaque requête doit échouer avec le message du trigger ou de la contrainte (data-model § 6) :
- auto-référence ;
- rattachement à un pôle ;
- rattachement de la DDE ;
- parent d'un autre secteur ;
- changement de secteur de la DDE ;
- `landing_path = '//x'`.

Le rattachement valide d'un service de `SEC-TES` à la DDE, lui, passe.

> **Résultat (2026-09-15)**, en `BEGIN … ROLLBACK` : auto-référence → `services_parent_not_self` ; rattachement au PEI → « Le service parent est lui-même un pôle (un seul niveau) » ; rattachement de la DDE → « Ce service a 1 pôle(s) : il ne peut pas être rattaché » ; parent d'un autre secteur (SAC → DDE) → « Le service parent doit appartenir au même secteur » ; changement de secteur de la DDE → « Déplacez ou détachez d'abord ses 1 pôle(s) » ; `landing_path='//x'` → `services_landing_path_format`. Rattachement valide de « test servi 3 » accepté ; suppression de la DDE → `parent_id` du PEI à NULL.

## 3. Tests backend (FR-002 à FR-008, FR-022, correctif C1)

```bash
cd usenghor_backend && TEST_DATABASE_URL=postgresql+asyncpg://usenghor:usenghor_secret@localhost:5432/usenghor_test \
  pytest tests/integration/test_services_hierarchy.py -v
pytest -m "not slow" -q   # non-régression (les 5 tests FAQ liés au vrai traducteur échouent d'office — mémoire projet)
```

**Attendu** : tous les cas de research R15 passent, dont « un service inactif existe toujours après `GET /with-services` et `GET /sectors/{code}` ». Vérifier que ce test **échoue** sur le code d'avant la correction (stash).

> **Résultat (2026-09-15)** : `test_services_hierarchy.py` → **15 passed** (base de test : structure 050 appliquée, colonnes + trigger). Le test de régression C1 **échoue sur le code d'origine** (copie de travail à `HEAD` : « le service inactif a été supprimé par une lecture publique ») et passe après correctif. Suite complète : **173 passed, 5 failed** — les 5 échecs sont les tests FAQ connus liés au vrai traducteur (`test_admin_faq_categories_api` ×4, `test_admin_faq_entries_api::test_each_mutation_creates_audit_log`), aucun autre échec. Remarque : l'`AuditMiddleware` écrit dans la base de développement pendant les tests (comportement préexistant).

## 4. Backoffice (US2, FR-012 à FR-015)

`/admin/organisation/services` :
1. La liste montre le PEI en retrait sous la DDE, avec la pastille « Pôle de DDE ». La recherche « PEI » affiche le pôle seul, avec sa pastille. Le glisser-déposer est impossible sur la ligne du pôle.
2. Éditer « test servi 3 » :
   - le sélecteur « Service parent » propose « Aucun » et la DDE (secteur `SEC-TES`), mais ni le PEI ni le service lui-même ;
   - le rattacher, enregistrer → il apparaît sous la DDE.
3. Éditer la DDE : le sélecteur est désactivé (« Ce service a 2 pôle(s) »). Changer son secteur → bandeau d'erreur 409 dans la modale, rien d'enregistré.
4. Page dédiée : `en/entrepreneuriat`, `//x`, `/en/x`, `/r/pei` → refusés immédiatement. Valeur vidée → enregistrée NULL.
5. Appels directs (`curl` avec jeton) reproduisant les refus du § 2 → 409 / 422 avec le `detail` du contrat.
6. Suppression d'un service qui a des pôles → la modale avertit ; après suppression, les pôles sont de premier niveau. *(Sur une copie dupliquée, pas sur la DDE.)*
7. `/admin/organisation/services/{id DDE}` : l'onglet Informations liste ses pôles ; celui du PEI montre le parent et la page dédiée.
8. Audit :

   ```sql
   SELECT action, record_id, old_values->>'parent_id', new_values->>'parent_id', new_values->>'landing_path'
   FROM audit_logs WHERE table_name = 'services' ORDER BY created_at DESC LIMIT 5;
   ```

   Une entrée par création, modification ou suppression, avec les deux champs (FR-008, SC-009).

> **Résultat (2026-09-15)**, navigateur piloté (Playwright) :
> 1. Liste groupée : PEI en retrait sous la DDE, pastille « Pôle de DDE », sans poignée de glisser-déposer.
> 2. « test servi 3 » : options « Aucun », « DDE — Direction… », « test seri 2 » (ni lui-même ni le PEI) ; rattachement enregistré (`parent_id` en base), affiché « Pôle de DDE » au rechargement. L'enregistrement prend quelques secondes (traduction automatique du nom sans EN/AR).
> 3. DDE : sélecteur désactivé (« Ce service a N pôle(s) … ») ; changement de secteur → bandeau `role="alert"` « Déplacez ou détachez d'abord ses 2 pôle(s) », rien d'enregistré.
> 4. Page dédiée `/en/x` → message immédiat et bouton Enregistrer désactivé ; refus API couverts par les tests (`en/x`, `//x`, `/en/x`, `/ar`, `/r/pei`, `/a b`, `/x?y`, `/x#y` → 422 ; `"  "` → NULL).
> 5. Appels directs : couverts par `test_admin_hierarchy_refusals` (409 / 422, `detail` exact, rien d'enregistré).
> 6. Modale de suppression de la DDE : « Ses 1 pôle(s) deviendront des services de premier niveau du secteur. » (annulée ; détachement réel vérifié par le test `DELETE` et en SQL § 2).
> 7. `[id].vue` du PEI : « Service parent » (lien vers la DDE), « Page dédiée » `/entrepreneuriat`.
> 8. Audit : `update | 804356cd-… | (vide) | aaaaaaaa-…dd` pour le rattachement, une entrée, sans doublon ; le refus 409 ne crée pas d'entrée.
> « test servi 3 » a ensuite été détaché.

## 5. Public : organigramme et fiches (US1, FR-016 à FR-019, SC-001, SC-002)

1. `/a-propos/organisation` (FR, EN, AR ; 1440 et 390 px ; clair et sombre) :
   - carte PEI sous la DDE, en retrait, avec liseré, en miroir en AR ;
   - la carte PEI mène à `/entrepreneuriat`, `/en/entrepreneuriat`, `/ar/entrepreneuriat` ;
   - le PEI n'est pas dans la grille du secteur.
2. Désactiver la DDE → pôle absent de l'organigramme. Le recharger plusieurs fois, puis **vérifier que la DDE existe toujours** en base (C1). Réactiver.
3. Fiche DDE, onglet Présentation : bloc « Pôles » avec la carte PEI → mini-site.
4. Fiche PEI (`/a-propos/organisation/service/pole-entrepreneuriat-et-innovation`) : lien « Pôle de DDE » et bouton « Voir la page dédiée ».
5. Fiche secteur `SEC-TES`, onglet Services : ligne « + 1 pôle » sous la DDE.
6. Captures **après** vs § 0 pour les fiches et les cartes sans pôle : aucune différence (SC-002). `diff` du JSON `/services` : seuls `parent_id` et `landing_path` sont ajoutés.

> **Résultat (2026-09-15)** :
> 1. Organigramme FR / AR, 1440 / 390 px, clair et sombre : carte PEI sous la DDE, liseré `border-s` (à droite en AR), flèche inversée en RTL, nom localisé ; PEI absent de la grille du secteur ; lien `/entrepreneuriat`, `/ar/entrepreneuriat`.
> 2. DDE désactivée → pôle absent, DDE toujours en base après lectures répétées (test `test_inactive_parent_hides_poles_without_deleting`).
> 3. Fiche DDE : section « Pôles » / « الأقطاب » avec la carte PEI → page dédiée.
> 4. Fiche PEI : lien « Pôle de DDE » et bouton « Voir la page dédiée ».
> 5. Fiche secteur : ligne « + 1 pôle » sous la DDE.
> 6. DOM normalisé avant / après : cartes et fiches **sans pôle strictement identiques** (secteur, service sans pôle, formation, projet, appel), seules différences = lien « Entreprendre à Senghor » du pied de page, libellé arabe de l'entrée de menu, bloc du pôle. Un premier passage a révélé des attributs `service="[object Object]"` sur les cartes (props de `createReusableTemplate` héritées) : corrigé par `inheritAttrs: false`, DOM de nouveau identique. Écart visuel attendu : dans une rangée de la grille qui contient un service avec pôles, les cartes voisines s'étirent à la hauteur de la rangée (comportement de grille existant). `diff` JSON : services existants identiques hors `parent_id` / `landing_path` (et `children` dans `with-services`).

## 6. Menu, pied de page, lien court (US3, FR-020 à FR-022, SC-004, SC-005)

1. Menu « Plus » › Nous connaître (FR / EN / AR, bureau et mobile) : dernière entrée « Entreprendre à Senghor » / « Entrepreneurship at Senghor » / « ريادة الأعمال في سنغور », icône fusée, lien localisé. Les autres entrées sont inchangées dans les trois langues.
2. Changer de langue sans recharger → le libellé suit.
3. Backoffice › Pages éditoriales › Barre de navigation › « Nous connaître » :
   - l'entrée du pôle montre ses trois libellés ;
   - ajouter un libellé anglais à « Notre histoire », enregistrer → visible en EN, FR inchangé ;
   - supprimer l'entrée du pôle, puis rejouer la 050 → rajoutée une fois, avec les autres entrées intactes.
4. Pied de page (trois langues) : « Entreprendre à Senghor » après « Gouvernance », lien localisé.
5. `curl -sI http://localhost:3001/r/pei` et `/r/PEI` → `302`, `location: /entrepreneuriat`. Le lien apparaît dans `/admin/liens-courts`.
6. Génération qui saute les codes pris : couvert par le test du § 3.

> **Résultat (2026-09-15)** :
> 1. Menu « Plus » bureau : dernière entrée de « Nous connaître » = « Entreprendre à Senghor » / « Entrepreneurship at Senghor » / « ريادة الأعمال في سنغور », liens `/entrepreneuriat`, `/en/…`, `/ar/…` ; autres entrées inchangées. Mobile (390 px) : même libellé et lien localisé par langue.
> 2. Changement de langue : libellé calculé par `navChildLabel` à chaque rendu (réactif sur `locale`).
> 3. `label_en` « Our story (test) » ajouté à « Notre histoire » → visible en EN seulement, FR et AR inchangés ; retiré ensuite. Entrée du pôle supprimée puis 050 rejouée → rajoutée une fois en fin de liste, autres entrées intactes. (Éditeur `NavItemsField` : champs « Libellé (anglais) / (arabe) » ajoutés, compilation vérifiée ; saisie par l'interface non rejouée.)
> 4. Pied de page : « Entreprendre à Senghor » après « Gouvernance » en FR / EN / AR, lien localisé, une occurrence visible dans la bonne langue et aucune dans les autres.
> 5. `curl -sI localhost:3001/r/pei` et `/r/PEI` → `302`, `location: /entrepreneuriat` ; `GET /api/admin/short-links?search=pei` → `pei → /entrepreneuriat`.
> 6. `test_create_short_link_skips_taken_code` : compteur 32 921 + code `pei` existant → code `int_to_base36(32923)`.

## 7. Fil d'Ariane (US4, FR-023 à FR-025, SC-007)

1. Les sept pages `/entrepreneuriat[/activites|/alumni|/partenaires|/ressources|/actualites|/statut-etudiant-entrepreneur]` × FR / EN / AR :
   - fil « Accueil › Nous connaître › Organisation › DDE › Pôle Entrepreneuriat et Innovation (› rubrique) » ;
   - chaque niveau autre que le dernier est un lien valide, et le dernier est la page courante.
2. `curl -s …/entrepreneuriat/activites | grep -o '"@type":"BreadcrumbList".*'` : mêmes niveaux et mêmes URLs localisées.
3. Détacher le PEI de la DDE → niveau DDE résolu par la clé (en local, renseigner la clé avec l'identifiant de la DDE de test). Clé vidée et pôle détaché → niveau DDE omis, sans erreur. Rétablir.
4. `grep -rn "pei.breadcrumb.dde" app/pages app/composables` → une seule occurrence (`usePeiPage.ts`).

> **Résultat (2026-09-15)** :
> 1. JSON-LD `BreadcrumbList` des sept pages (FR, EN, AR échantillonnés) : « Accueil › Nous connaître › Notre organisation › DDE › Pôle Entrepreneuriat et Innovation (› rubrique) » ; EN « Home › About › Our Organization › DDE › Entrepreneurship and Innovation Hub › Our alumni » ; AR identique en arabe. DDE résolue par le parent du pôle (clé locale vide).
> 2. Données structurées et fil visible construits depuis le même `breadcrumb` partagé.
> 3. Pôle détaché + clé vide → niveau DDE omis sans erreur ; pôle détaché + clé renseignée → « DDE » résolu par la clé ; état rétabli.
> 4. `grep "pei.breadcrumb.dde"` dans `app/pages` et `app/composables` → une seule occurrence (`usePeiPage.ts`).

## 8. Plan du site (US5, FR-026, SC-006)

```bash
curl -s http://localhost:3001/sitemap.xml > /tmp/sm.xml   # ou les sous-plans par langue
grep -o '<loc>[^<]*organisation/[^<]*</loc>' /tmp/sm.xml | sed 's/<[^>]*>//g' | sort -u | while read u; do
  printf '%s %s\n' "$(curl -s -o /dev/null -w '%{http_code}' "$u")" "$u"; done | sort | uniq -c -w3
grep -c 'entrepreneuriat' /tmp/sm.xml   # 7 pages × 3 langues présentes
```

**Attendu** :
- 100 % des URLs d'organisation en `200` ;
- aucune `secteurs/` ni `services/` ;
- chaque service et pôle actif présent une fois par langue ;
- les sept pages du mini-site présentes.

> **Résultat (2026-09-15)** : 21 URLs d'organisation (2 secteurs actifs + 5 services / pôles actifs, × FR / EN / AR) → **21 × 200** ; aucune `secteurs/` ni `services/` ; chaque service et pôle une fois par langue. Les URLs dynamiques de la source n'étaient émises qu'en français (`autoI18n` ne les déclinait pas) : ajout de `_i18nTransform: true` sur les entrées d'organisation. Sept pages `/entrepreneuriat*` présentes en FR, EN et AR (21 URLs). Avant : 0 fiche service émise et secteurs en `secteurs/{CODE}`.

## 9. Build et non-régression

`cd usenghor_nuxt && NODE_OPTIONS=--max-old-space-size=8192 pnpm build`. Aucune erreur, et aucun `WARN` de collision d'auto-import sur les nouveaux noms.

Captures après vs § 0 pour toutes les pages listées, T039 compris (fiches formation, projet, appel à 1440 et 390 px). Consigner le résultat, et cocher T039 (023) s'il est conforme.

> **Résultat (2026-09-15)** : `NODE_OPTIONS=--max-old-space-size=8192 pnpm build` → « Build complete! », aucune erreur, aucun `WARN` de collision sur `getServiceLink`, `usePeiBreadcrumb`, `navChildLabel`, `slugifyServiceName`, `orderHierarchically`, `ServiceRelativePublic`, `ServicePublicWithChildren`. Non-régression : voir § 5.6 ; fiches formation, projet et appel à 1440 et 390 px → DOM identique hors lien ajouté au pied de page → T039 (023) coché.

## 10. Mise en ligne (US6, FR-027, FR-028) — **chaque étape attend un accord explicite**

| # | Action | Commande | Attendu / preuve |
|---|---|---|---|
| a | Commit + push des 3 dépôts | `git -C usenghor_backend push origin main` ; `git -C usenghor_nuxt push origin main` ; `git push origin main` | `git status` propre, `origin/main` à jour |
| b | Sauvegarde | `./deploy.sh backup` | fichier de sauvegarde daté |
| c | Contrôle en lecture seule | `ssh … docker exec -i -e PGOPTIONS="-c default_transaction_read_only=on" usenghor_db psql …` avec les requêtes de research C4 / C5 | clé DDE → `72eca1c4-…` ; motif → 1 ligne ; 138 clés `entrepreneurship.*` ; 4 catégories `see-*` ; clés hero 047 ; `pei` libre ; colonnes absentes. Tout écart → arrêt et signalement (aucun rejeu 045–049 sans raison) |
| d | Migration 050 ×2 | `docker exec -i usenghor_db psql -U usenghor -d usenghor < …/050_services_parent_landing.sql` (fichier copié via `scp` ou dépôt tiré) | NOTICE du § 1 ; `pei | poles | menu | lien` = `1 | 1 | 5 | 1`, identiques après le 2e passage |
| e | Déploiement | `./deploy.sh update` (intègre déjà `up -d --build --force-recreate backend frontend db`) | conteneurs `usenghor_frontend` et `usenghor_backend` recréés (`docker ps` : uptime récent) ; build frontend réussi (sinon `docker buildx history logs`) |
| f | Contrôles production | § 5.1, 5.3, 5.4, 6.1, 6.4, 6.5, 7.1, 8 sur `https://<domaine>` ; permissions : `SELECT r.code, count(*) … LIKE 'entrepreneurship.%'` → `super_admin`, `admin`, `editor` = 4 | compte rendu par point |
| g | Traduire les champs manquants | backoffice `/admin/entrepreneuriat` → bouton | compteurs consignés ; pages EN / AR du pôle sans champ vide |
| h | Lighthouse mobile derrière nginx | `npx -y lighthouse@12 https://<domaine>/entrepreneuriat --form-factor=mobile --only-categories=performance,accessibility --output=json` ; idem `/entrepreneuriat/activites`, `/entrepreneuriat/statut-etudiant-entrepreneur` et une page de référence (`/a-propos/organisation`) | accessibilité ≥ 90 ; écart de performance consigné (référence : mémoire « Lighthouse prod ≈ 65–80 ») |
| i | Clôture | cocher T071 (021 ; preuves research C5 + suivi du 2026-09-13), T051 (023 ; preuves C5 + pages en ligne), T048 (023 ; étape h), T039 (023 ; § 9) — ou laisser ouvert avec la raison ; noter `pei_resources = 0` en production pour l'équipe | tâches mises à jour |
| j | Documentation | CLAUDE.md (colonnes `services`, trigger, `OrganigrammeSection`, fiche service, `usePeiBreadcrumb`, menu `label_en/label_ar`, pied de page, `/r/pei`, plan du site, correctif C1, 050 et ordre des rollbacks) ; roadmap PEI (026 livrée) ; mémoire projet (correctif C1, trigger, libellés de menu trilingues) | commit docs |

**Rollback en cas d'incident** : `050_services_parent_landing_rollback.sql` (avant tout rollback 049 → 045), puis redéploiement du commit précédent.
