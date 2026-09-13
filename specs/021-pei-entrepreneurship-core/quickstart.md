# Quickstart — Validation de bout en bout (021 Socle PEI)

Guide de vérification manuelle et automatisée des critères d'acceptation. Détails des contrats : [contracts/](contracts/), modèle : [data-model.md](data-model.md).

## Prérequis

```bash
# Backend
cd usenghor_backend && docker compose up -d && source .venv/bin/activate
uvicorn app.main:app --reload            # http://localhost:8000/api/docs

# Frontend
cd usenghor_nuxt && pnpm install && pnpm dev   # http://localhost:3000/admin
```
Identifiants admin : `usenghor_backend/.env` (`ADMIN_EMAIL`, `ADMIN_PASSWORD`). Créer aussi un utilisateur avec le seul rôle `editor` pour les tests de permissions (backoffice → Administration → Utilisateurs).

## 1. Migration rejouable (SC-005, FR-004)

```bash
cd usenghor_backend/documentation/modele_de_données/migrations
docker exec -i usenghor_postgres psql -U usenghor -d usenghor < 045_entrepreneurship.sql
docker exec -i usenghor_postgres psql -U usenghor -d usenghor < 045_entrepreneurship.sql   # second passage : aucune erreur
docker exec -i usenghor_postgres psql -U usenghor -d usenghor -Atc "
  SELECT (SELECT count(*) FROM pei_programs), (SELECT count(*) FROM pei_cohorts),
         (SELECT count(*) FROM permissions WHERE code LIKE 'entrepreneurship.%'),
         (SELECT count(*) FROM editorial_contents WHERE key LIKE 'entrepreneurship.%');"
```
Attendu : `5|3|4|43` après chaque passage. Rollback puis rejeu :
```bash
docker exec -i usenghor_postgres psql -U usenghor -d usenghor < 045_entrepreneurship_rollback.sql
docker exec -i usenghor_postgres psql -U usenghor -d usenghor < 045_entrepreneurship.sql
```
Schéma neuf : `psql -f services/main.sql` sur une base vide doit inclure `16_entrepreneurship.sql` sans erreur.

## 2. Tests backend (FR-007, FR-016, FR-018, FR-019, FR-020)

```bash
cd usenghor_backend && source .venv/bin/activate
pytest tests/integration/test_admin_entrepreneurship_api.py tests/integration/test_public_entrepreneurship_api.py tests/unit/test_entrepreneurship_service.py -v
```
Couvrent : 401/403 sans permission, création avec traduction auto (mock du traducteur), 409 code dupliqué, 422 ressource incohérente, reorder renuméroté 0..n-1, toggle + `published_at`, entrée `AuditLog` par écriture, public = actifs seulement, 404 par code inactif, `translate-missing` idempotent.

## 3. Parcours éditeur (User Story 1 — SC-001, SC-002, SC-008)

1. Se connecter avec le compte `editor` → la section « Entrepreneuriat (PEI) » apparaît dans la barre latérale ; ouvrir `/admin/entrepreneuriat/dispositifs` : 5 dispositifs listés dans l'ordre OSER, SEE, MTI, Senghor'Innov, FSE.
2. « Nouveau dispositif » : renseigner uniquement l'onglet FR (code `test-6`, titre, phase « Écosystème », accroche, contenu riche via l'éditeur modal, chiffre « 10 ateliers », couleur turquoise, visuel choisi dans la médiathèque). Enregistrer → redirection vers la page d'édition ; onglets EN et AR remplis automatiquement ; AR affiché en RTL.
3. Corriger manuellement le titre EN, modifier le titre FR, enregistrer → le titre EN corrigé est conservé.
4. Retour à la liste : glisser `test-6` en 2e position → recharger la page → ordre conservé.
5. Désactiver `test-6` depuis la liste → badge « Inactif » ; `curl http://localhost:8000/api/public/entrepreneurship/programs | jq 'map(.code)'` ne contient pas `test-6` ; `curl -i …/programs/test-6` → 404.
6. Journal d'audit (`/admin/administration/audit` ou `GET /api/admin/audit-logs?table_name=pei_programs`) : une entrée `create`, deux `update`, une `reorder`, une `deactivate`.
7. Se connecter avec un compte sans permission `entrepreneurship.*` (rôle `user`) : la section n'apparaît pas ; `/admin/entrepreneuriat/dispositifs` redirige vers `/admin/acces-refuse` ; `curl -H "Authorization: Bearer <token>" -X POST …/api/admin/entrepreneurship/programs` → 403.

## 4. Cohortes et ressources (User Stories 2 et 3)

- `/admin/entrepreneuriat/cohortes` : créer `see-2026` (type SEE, 2026) ; tentative de doublon `fse-1` → message « Code déjà utilisé ». Désactiver `see-2026` → absent de `GET /api/public/entrepreneurship/cohorts`.
- `/admin/entrepreneuriat/ressources` : créer un « document » sans fichier → refus explicite ; choisir un PDF de la médiathèque → OK ; créer un « lien » avec `pas-une-url` → refus ; publier le document seul → `GET /api/public/entrepreneurship/resources` renvoie 1 élément avec `media_url`. Filtrer par catégorie dans la liste admin.

## 5. Tableau de bord (User Story 4 — SC-006)

`/admin/entrepreneuriat` : compteurs 5/5 dispositifs actifs, 3/3 cohortes, 0/0 ressources (avant §3-4). Cliquer chaque raccourci « Géré ailleurs » : chacun ouvre une page admin existante (aucune 404). Si le service DDE n'existe pas en base locale : bandeau ambre affiché ; le créer dans Organisation → Services puis coller son identifiant dans la clé « Service DDE » (page Valeurs → Entrepreneuriat) → le bandeau disparaît et le nom du service s'affiche.

Action « Traduire les champs manquants » : premier clic → « 5 dispositifs, 3 cohortes, 0 ressource complétés » ; second clic → « 0, 0, 0 » ; entrée d'audit `entrepreneurship.translate_missing`. Vérifier en base : `SELECT code, title_en, title_ar FROM pei_programs;` non vides.

## 6. Page éditoriale (User Story 5)

`/admin/editorial/valeurs` → page « Page Entrepreneuriat (PEI) » : 8 sections, 43 clés, valeurs initiales visibles (slogan « INNOVER. AGIR. TRANSFORMER. », e-mail `entrepreneuriat@usenghor.org`, 4 chiffres). Modifier `entrepreneurship.stats.3.value` en « 15 », rejouer la migration 045 → la valeur « 15 » est conservée. Téléverser une image dans `entrepreneurship.hero.slide1.image` → aperçu affiché.

## 7. Qualité frontend

```bash
cd usenghor_nuxt && pnpm lint && pnpm build
```
Aucune erreur ESLint ; build sans erreur TypeScript (types `ValueSectionKey` étendus, composable typé).

## 8. Documentation

`CLAUDE.md` mis à jour : ligne `16_entrepreneurship.sql` dans le tableau des fichiers SQL, section « Composants clés » (`useEntrepreneurshipApi()`, `components/entrepreneurship/admin/*`, `AdminMediaPicker`), entrée « Recent Changes » 021.

## 9. Production

```bash
./deploy.sh backup
docker exec -i usenghor_db psql -U usenghor -d usenghor < 045_entrepreneurship.sql   # 2 fois, sans erreur
```
Puis lancer « Traduire les champs manquants » depuis le backoffice de production et vérifier §1 (`5|3|4|43`) et que `entrepreneurship.dde_service_id` est renseigné (la DDE existe en production).

## Écarts constatés lors de la validation (2026-09-13)

- **§1 schéma neuf** : `16_entrepreneurship.sql` s'exécute sans erreur, mais `main.sql` échoue déjà en amont sur des fichiers existants (`10_project.sql` : type `call_status` absent ; `13_fundraising.sql`, `14_survey.sql`, `13_short_links.sql` : fonction `update_updated_at_column()` pas encore créée ; `99_functions.sql` : la boucle de triggers s'arrête sur la vue `v_survey_campaigns_with_stats`). Conséquence : sur base neuve via `main.sql`, les triggers `update_pei_*_updated_at` ne sont pas créés ; la migration 045 les crée bien. Problème antérieur à la feature, hors périmètre.
- **§2 suite complète** : 112 tests réussis, 5 échecs dans les tests FAQ (`record_id="bulk"` refusé par la colonne UUID, `MissingGreenlet`), sans lien avec le code PEI ; les 39 tests PEI passent. Les tests FAQ appellent le vrai traducteur Google et épuisent le quota (5 requêtes/s) de l'IP locale.
- **§5 « Traduire les champs manquants »** : ~80 appels séquentiels au traducteur pour les données initiales, au-delà du `proxy_read_timeout` nginx (90 s). Ajout d'un budget de temps de 50 s par appel (`complete: false` → le backoffice relance automatiquement, arrêt si une passe ne complète rien). Validation en conditions réelles tributaire du quota Google (bloqué pendant la session de validation).
- **§7** : le projet n'a pas de script `pnpm lint` (ESLint non configuré pour les `.vue`) ; `pnpm build` réussit.
- **Tableau de bord** : `/admin/organisation/services` ignore `?service_id=` et les albums d'un service se lient depuis sa fenêtre de modification (rappel de convention ajusté). `/admin/editorial/valeurs` n'accepte pas de paramètre de présélection de page.
- **§9 production** : le service s'appelle « Direction du développement et de l’entrepreneuriat » (minuscules, apostrophe typographique ’) ; le motif de résolution de `entrepreneurship.dde_service_id` a été corrigé en `ILIKE '%veloppement et de l_entrepreneuriat%'` avant la mise en production (commit backend `bfbf815`). Migration jouée deux fois en production le 2026-09-13 : `5|3|4|43`, clé DDE renseignée.
