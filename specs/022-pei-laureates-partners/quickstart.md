# Quickstart — Validation de bout en bout (022 Lauréats et partenaires du pôle)

Guide de vérification des critères d'acceptation. Contrats : [contracts/](contracts/), modèle : [data-model.md](data-model.md). Prérequis identiques à la feature 021 (backend + frontend lancés, compte admin et compte `editor`). La migration 045 doit être jouée.

## 0. Porte SQL (FR-005)

Présenter [data-model.md](data-model.md) §4–6 au responsable ; **attendre l'accord explicite** avant toute écriture de code.

## 1. Migration rejouable (SC-006, SC-007, FR-004, FR-006)

```bash
cd usenghor_backend/documentation/modele_de_données/migrations
docker exec -i usenghor_postgres psql -U usenghor -d usenghor < 046_pei_laureates_partners.sql
docker exec -i usenghor_postgres psql -U usenghor -d usenghor < 046_pei_laureates_partners.sql   # second passage : aucune erreur
docker exec -i usenghor_postgres psql -U usenghor -d usenghor -Atc "
  SELECT (SELECT count(*) FROM pei_laureates), (SELECT count(*) FROM pei_partners),
         (SELECT count(*) FROM partners),
         (SELECT string_agg(family::text || ':' || display_order, ',' ORDER BY family, display_order) FROM pei_partners);"
```
Attendu : mêmes valeurs après chaque passage ; `count(partners)` inchangé avant / après (aucun partenaire créé) ; `NOTICE` listant les motifs sans correspondance. Sur une base locale contenant « Campus France » ou « AUF », ils apparaissent rattachés à la bonne famille.

Rollback puis rejeu (ordre 046 → 045 vérifié) :
```bash
docker exec -i usenghor_postgres psql -U usenghor -d usenghor < 046_pei_laureates_partners_rollback.sql
docker exec -i usenghor_postgres psql -U usenghor -d usenghor < 046_pei_laureates_partners.sql
```
Schéma neuf : `16_entrepreneurship.sql` seul s'exécute sans erreur après `06_partner.sql` et `02_identity.sql`.

## 2. Tests backend (FR-003, FR-007, FR-015, FR-017, FR-022, FR-026 à FR-029)

```bash
cd usenghor_backend && source .venv/bin/activate
pytest tests/integration/test_admin_pei_laureates_api.py tests/integration/test_admin_pei_partners_api.py \
       tests/integration/test_public_pei_api.py tests/unit/test_entrepreneurship_service.py -v
```
Couvrent : 403 sans permission ; création avec traduction auto (mock) ; 422 cohérence type / cohorte, verbatim > 600, URL invalide, montant négatif ; publish / unpublish + `published_at` ; featured ; reorder par cohorte (liste incomplète → 422) ; changement de cohorte → dernière position ; 409 suppression de cohorte utilisée ; rattachement 201 / 409 ; `available` exclut les rattachés ; reorder par famille ; retrait ; cascade après suppression du partenaire ; public = publiés + cohortes actives, filtre `type`, stats, trois familles, inactifs exclus ; une entrée `AuditLog` par écriture. Les tests PEI de 021 doivent rester verts (`DELETE /cohorts/{id}` sans portrait → 204).

## 3. Parcours éditeur — portraits (User Story 1 — SC-001, SC-002, SC-009)

1. Compte `editor` → barre latérale « Entrepreneuriat (PEI) » : entrées « Lauréats et étudiants-entrepreneurs » et « Partenaires du pôle » présentes, entre « Cohortes » et « Boîte à outils ».
2. `/admin/entrepreneuriat/laureats` → « Nouveau » : type « Lauréat FSE » → le sélecteur de cohorte ne propose que FSE 1 / 2 / 3 ; choisir FSE 1, nom, projet, département « Département Santé », verbatim FR (compteur `n/600`), photo depuis la médiathèque (aperçu), site + vidéo, montant 5000, « Mis en avant ». Enregistrer → redirection vers la page d'édition ; onglets EN / AR remplis ; AR en RTL.
3. Basculer « Publié » → badge « Publié » ; audit `entrepreneurship.laureate.create` puis `.publish`.
4. Créer deux autres portraits FSE 1 ; dans la liste, filtrer « Cohorte = FSE 1 » → poignées actives ; glisser le 3e en 1er → recharger → ordre conservé. Ajouter une recherche → poignées grisées + message. Retirer le filtre cohorte → idem.
5. Ouvrir un portrait, le passer en cohorte FSE 2 → il apparaît en dernier de FSE 2 ; FSE 1 renuméroté (`SELECT full_name, display_order FROM pei_laureates ORDER BY cohort_id, display_order`).
6. Tenter type « Étudiant-entrepreneur » en gardant FSE 2 (via l'API : `PATCH …/laureates/{id}` `{ "type": "student_entrepreneur" }`) → 422 explicite. Saisir `linkedin` sans `https://` → refus sur le champ.
7. `/admin/entrepreneuriat/cohortes` → supprimer FSE 1 → message « Cohorte utilisée par N lauréats ».
8. Compte sans permission `entrepreneurship.*` : entrées absentes, `/admin/entrepreneuriat/laureats` → `/admin/acces-refuse`, `POST …/laureates` → 403 ; compte `editor` sans `entrepreneurship.delete` : boutons de suppression / retrait masqués.

## 4. Lecture publique des portraits (User Story 2 — SC-003)

```bash
curl -s http://localhost:8000/api/public/entrepreneurship/laureates | jq '{groups: [.groups[] | {cohort: .cohort.code, n: (.laureates | length)}], stats}'
curl -s "http://localhost:8000/api/public/entrepreneurship/laureates?type=student_entrepreneur" | jq '.groups | length'
```
Vérifier : portrait dépublié absent ; désactiver FSE 2 (admin cohortes) → groupe FSE 2 absent ; réactiver → présent ; cohorte sans portrait publié absente ; `photo_url` résolue ; `stats.max_grant_amount == "5000.00"` ; `grant_amount` individuel non exposé ; `Cache-Control` présent.

## 5. Partenaires du pôle (User Stories 3, 4 et 6 — SC-004, SC-008)

1. `/admin/entrepreneuriat/partenaires` : trois sections (ordre fixe) ; lien « Ouvrir le backoffice Partenaires » ; aucun formulaire de création.
2. « Rattacher un partenaire » → recherche « campus » → sélectionner, famille « Académiques et institutionnels », valider → apparaît en dernier de la famille (< 30 s). Rouvrir le sélecteur : ce partenaire n'est plus proposé.
3. Rattacher trois partenaires en « Organisations internationales », les réordonner par glisser-déposer → recharger → ordre conservé ; changer la famille de l'un via le `<select>` → dernier de la nouvelle famille.
4. Backoffice Partenaires (`/admin/partenaires`) : désactiver un partenaire rattaché → badge « Inactif » dans le pôle ; supprimer un autre → disparaît du pôle sans erreur (`SELECT count(*) FROM pei_partners` décrémenté).
5. Retirer un partenaire depuis le pôle (confirmation) → absent du pôle, toujours présent dans `/admin/partenaires`.
6. Public :
```bash
curl -s http://localhost:8000/api/public/entrepreneurship/partners | jq 'map({family, n: (.partners | length), names: [.partners[].name]})'
```
Trois familles toujours renvoyées ; partenaire inactif et partenaire supprimé absents ; `logo_url` résolue, `description_en` présente, aucun champ réseau social, aucun UUID de média.
7. Audit : `entrepreneurship.partner.link`, `.update`, `.reorder`, `.unlink` présents (`GET /api/admin/audit-logs?table_name=pei_partners`).

## 6. Tableau de bord (User Story 5 — SC-011)

`/admin/entrepreneuriat` : cartes « Lauréats et étudiants-entrepreneurs » (publiés / total) et « Partenaires du pôle » (actifs / rattachés) cohérentes avec §3 et §5 ; chaque carte mène à sa rubrique ; raccourci « Partenaires (fiches) » ouvre `/admin/partenaires`. Vider `quote_en` d'un portrait en base, lancer « Traduire les champs manquants » → « N lauréats complétés », valeur EN remplie, autres champs intacts ; second lancement → 0.

## 7. Qualité frontend

```bash
cd usenghor_nuxt && pnpm build
```
Build sans erreur TypeScript (types étendus, composable typé). Pas de script `pnpm lint` dans le projet (écart connu, 021).

## 8. Documentation

`CLAUDE.md` : ligne `16_entrepreneurship.sql` complétée (`pei_laureates`, `pei_partners`), « Composants clés » (`components/entrepreneurship/admin/*` : lauréats, partenaires), entrée « Recent Changes » 022 (migration 046, rattachement initial, rollback 046 avant 045).

## Écarts constatés

Validation locale du 2026-09-13 (base `usenghor_postgres`, 58 partenaires) :

- **§1 Migration** : deux passages sans erreur, rollback 046 puis rejeu OK, triggers `update_pei_laureates_updated_at` / `update_pei_partners_updated_at` créés ; `DELETE` d'une cohorte référencée refusé par la FK `pei_laureates_cohort_id_fkey`.
- **Rattachement initial (T046)** : sur la base locale, `AUF` et `OIF` → `international`, **`CCI Côte d'Ivoire` → `support`** (motif `\mCCI\M`) ; aucun partenaire « Réseau Senghor », « Campus France », « CEF », « AFD » (NOTICE émises). Avec deux partenaires de test « Campus France … » et « Agence universitaire de la Francophonie … » : rattachés en `academic` / `international`, `count(partners)` inchangé (60 → 60) ; après déplacement de l'AUF de test en `support` puis rejeu, elle **reste** en `support` (renumérotation contiguë par famille). Suppression des partenaires de test → rattachements supprimés par cascade. À vérifier en production (§9) : le motif `CCI` attrape-t-il bien la chambre de commerce attendue ?
- **Production, lecture seule (T047)** : correspondances `AUF`, `Agence française de développement`, `CCI Côte d'Ivoire` et deux fiches OIF. Motifs conservés ; migration modifiée pour ne rattacher qu'un partenaire par motif (fiche la plus complète). Revalidé en local avec des doublons de test et un rejeu après modification par un éditeur.
- **Base de test pytest** (`usenghor_test`) : l'extension `uuid-ossp` y est absente, la migration 046 échoue ; seuls les deux types ENUM doivent y être créés (les tables sont créées par `create_all`).
- **Traduction automatique** : en local, le traducteur ne répond pas (quota) → `quote_en` / `department_label_en` restent vides à la création, sans bloquer l'enregistrement ; relancer « Traduire les champs manquants » plus tard.
- **Qualité frontend** : `pnpm build` OK ; `nuxi typecheck` inutilisable (dépendance `vue-tsc` absente du projet), vérification de types non effectuée.
- **§3–§6 parcours UI (T050)**, navigateur automatisé sur `pnpm dev` + backend local :
  - Barre latérale : « Lauréats et étudiants-entrepreneurs » et « Partenaires du pôle » entre « Cohortes » et « Boîte à outils » ; tableau de bord à 5 cartes.
  - Formulaire : cohortes filtrées par type (FSE seulement pour un lauréat ; aucune cohorte SEE en local), compteur `n/600`, validation locale des liens (« Adresse web invalide : LinkedIn… »), création → redirection vers l'édition ; publication et mise en avant depuis l'en-tête, audit `create/update/publish/feature`.
  - **Bug corrigé** : `PATCH /laureates/{id}` renvoyait 500 dès qu'un montant était déjà saisi (ancienne valeur `Decimal` non sérialisable dans l'audit). `_jsonable` convertit désormais `Decimal` en chaîne ; test de non-régression ajouté.
  - Liste : poignées grisées + message sans filtre de cohorte ; filtre « FSE 3 » → glisser le 3e en 1er → ordre `0,1,2` en base, audit `reorder {cohort_id, ids}`, ordre conservé au rechargement.
  - Cohortes : suppression de FSE 3 → modale « Cohorte utilisée par 3 lauréats ».
  - Partenaires du pôle : trois sections, sélecteur (recherche « unesco », badge de type), rattachement → « « Unesco » rattaché au pôle. », changement de famille via `<select>` (visible en public), retrait (l'Unesco reste dans `partners`) ; audit `link/update/unlink`.
  - Compte sans permission (utilisateur temporaire rôle `user`, supprimé ensuite) : API 403 sur `/laureates` et `/partners`, `/admin/entrepreneuriat/laureats` → `/admin/acces-refuse`, entrées de barre latérale absentes.
  - Non rejoué dans l'interface (couvert par pytest) : glisser-déposer des partenaires, « Traduire les champs manquants » (traducteur local indisponible). Enregistrement lent en local (~5–10 s) tant que le traducteur ne répond pas.
  - Hors périmètre : le fil d'Ariane admin affiche le slug (« Laureats ») comme pour toutes les pages admin.
  - Données de test supprimées ; base locale revenue à l'état initial.

- **Production (T053, 2026-09-13)** : sauvegarde `backups/backup_usenghor_20260913_165623.sql` (dump complet) ; migration 046 jouée **deux fois** sur `usenghor_db` sans erreur (1er passage `UPDATE 1`, 2e `UPDATE 0`) → `pei_laureates` vide, 4 rattachements (`CCI Côte d'Ivoire` support ; `AUF`, `Agence française de développement`, `Organisation internationale de la Francophonie` international), 79 partenaires inchangés, triggers créés. Code poussé sur `origin/main` (backend `3c3bfe6`, frontend `1065a3b`, parent `3619e3a`). **Reste à faire par un humain** : `./deploy.sh update` (refusé en mode automatique), puis vérifier `docker ps` (uptime récent) et `/admin/entrepreneuriat/partenaires`.

## 9. Production

```bash
# Lecture seule d'abord : vérifier les motifs de rattachement sur les noms réels (apostrophe ’, casse)
docker exec -i usenghor_db psql -U usenghor -d usenghor -Atc "SELECT id, name, active FROM partners WHERE name ~* 'r.seau senghor|campus france|\mCEF\M|\mCCI\M|chambre de commerce|\mAUF\M|agence universitaire|\mAFD\M|agence fran.aise de d|\mOIF\M|organisation internationale de la francophonie';"
./deploy.sh backup
docker exec -i usenghor_db psql -U usenghor -d usenghor < 046_pei_laureates_partners.sql   # 2 fois, sans erreur
```
Puis vérifier §1 en production et corriger à la main (backoffice « Partenaires du pôle ») tout rattachement inattendu produit par un motif trop large.
