# Quickstart — Album médiathèque « Gouvernance »

**Feature**: 018-governance-media-album
**Audience**: développeur qui reprend la feature / revue QA / déploiement.

## 1. Prérequis

- Docker Desktop actif.
- Conteneurs locaux du monorepo démarrés :
  ```bash
  cd usenghor_backend && docker compose up -d
  ```
- Backend en cours :
  ```bash
  cd usenghor_backend && source .venv/bin/activate && uvicorn app.main:app --reload
  ```
- Frontend en cours :
  ```bash
  cd usenghor_nuxt && pnpm install && pnpm dev
  ```
- Accès admin défini dans `usenghor_backend/.env` (`ADMIN_EMAIL`, `ADMIN_PASSWORD`).
- Clé éditoriale `governance.foundingTexts.documents` présente en base avec au moins 1 document (vérifiable via Adminer → `editorial_contents`).

## 2. Déploiement de la migration — environnement local

```bash
# À la racine du repo
docker exec -i usenghor_postgres psql -U usenghor -d usenghor \
  < usenghor_backend/documentation/modele_de_données/migrations/032_gouvernance_album.sql
```

**Sortie attendue** :
- `ALTER TABLE` (pour la colonne `thumbnail_url`).
- Un bloc `INSERT 0 N` (N = nombre de documents migrés).
- Des `NOTICE` indiquant le nombre d'items insérés et ignorés.
- `COMMIT`.

**Vérification SQL immédiate** :

```bash
docker exec -i usenghor_postgres psql -U usenghor -d usenghor -c \
  "SELECT a.title, a.slug, a.status, COUNT(am.media_id) AS docs \
   FROM albums a LEFT JOIN album_media am ON am.album_id = a.id \
   WHERE a.slug = 'gouvernance' GROUP BY a.id;"
```

Attendu : 1 ligne, `status = published`, `docs >= 1`.

## 3. Vérification backend (Swagger)

Ouvrir http://localhost:8000/api/docs et exécuter :

- `GET /api/public/albums/by-slug/gouvernance` → 200, payload contenant `media_items` avec les documents migrés.
- `GET /api/public/albums?media_type=document` → l'album `gouvernance` apparaît dans `items` avec un `cover_media.thumbnail_url` non nul (si couverture renseignée).

## 4. Vérification frontend — médiathèque publique

- http://localhost:3000/mediatheque onglet « Tout » : l'album « Gouvernance » figure dans la grille des albums, avec la vignette dérivée du premier document.
- Onglet « Albums » : même album, même vignette.
- Cliquer l'album → redirection sur http://localhost:3000/mediatheque/gouvernance.
- Dans la vue détail, cliquer un PDF → `MediaFilePreviewModal` s'ouvre et affiche le PDF inline.
- Cliquer « Télécharger » sur un média → téléchargement navigateur.

## 5. Vérification frontend — page gouvernance

- http://localhost:3000/a-propos/gouvernance : la section « Textes fondateurs » affiche les flip cards, ordre identique à l'admin.
- Survol / tap : la card se retourne, description et boutons visibles.
- Bouton « Voir » → ouvre le PDF dans un nouvel onglet.
- Bouton « Télécharger » → télécharge le fichier.
- Bouton « Prévisualiser » → ouvre `MediaFilePreviewModal` avec le PDF inline.

### Fallback album vide

1. Temporairement, en base :
   ```sql
   UPDATE albums SET status = 'draft' WHERE slug = 'gouvernance';
   ```
2. Rafraîchir `/a-propos/gouvernance` : la section garde badge + titre + description, la grille est remplacée par un message court (i18n `governance.foundingTexts.emptyState`).
3. Rétablir : `UPDATE albums SET status = 'published' WHERE slug = 'gouvernance';`.

## 6. Vérification trilingue (FR / EN / AR)

- `/fr/a-propos/gouvernance` — libellés d'interface en français, titres/descriptions des documents en français (natif).
- `/en/a-propos/gouvernance` — libellés d'interface en anglais, titres/descriptions des documents **en français tels quels** (confirmation de Q3/A1).
- `/ar/a-propos/gouvernance` — interface en arabe, layout RTL. Titres FR tels quels, pas de casse RTL sur les flip cards.

## 7. Vérification admin

1. Se connecter à http://localhost:3000/admin avec les identifiants admin.
2. Aller sur `Médiathèque → Albums` et ouvrir « Gouvernance ».
3. Cases à vérifier :
   - Ajouter un nouveau PDF → apparaît sur la page publique après rafraîchissement.
   - Réordonner par drag & drop → l'ordre est reflété sur `/a-propos/gouvernance` et `/mediatheque/gouvernance`.
   - Retirer un document → disparaît des deux vues publiques.
   - Modifier la couverture d'un document → met à jour `media.thumbnail_url` → vignette reflétée côté médiathèque.
4. Aller dans `Contenu éditorial → Gouvernance` :
   - Le champ « Documents fondateurs » apparaît **grisé / non éditable** avec une note : « Gestion désormais via la médiathèque — Album Gouvernance » et un lien cliquable vers `/admin/mediatheque/albums`.

## 8. Test d'idempotence

Exécuter une seconde fois la migration :

```bash
docker exec -i usenghor_postgres psql -U usenghor -d usenghor \
  < usenghor_backend/documentation/modele_de_données/migrations/032_gouvernance_album.sql
```

Attendu :
- 0 nouvelle ligne dans `media` (vérifiable par `SELECT COUNT(*) FROM media WHERE type = 'document';`).
- 0 nouvelle ligne dans `album_media`.
- Les valeurs mises à jour (si le JSON source a changé) sont reflétées.

## 9. Test de rollback

```bash
docker exec -i usenghor_postgres psql -U usenghor -d usenghor \
  < usenghor_backend/documentation/modele_de_données/migrations/032_gouvernance_album_rollback.sql
```

Vérifier :

```sql
SELECT * FROM albums WHERE slug = 'gouvernance';            -- 0 ligne
SELECT * FROM media WHERE type = 'document' AND url LIKE '%charte%';  -- 0 ligne si ces URLs venaient de la migration
```

La colonne `thumbnail_url` **reste** sur `media` (enrichissement durable du schéma).

## 10. Déploiement — environnement production

```bash
# Via SSH sur le serveur prod
docker exec -i usenghor_db psql -U usenghor -d usenghor \
  < /path/to/repo/usenghor_backend/documentation/modele_de_données/migrations/032_gouvernance_album.sql
```

Vérifier :
- Swagger prod : `GET /api/public/albums/by-slug/gouvernance` retourne 200 avec `media_items` non vide.
- Site prod : album visible sur la page médiathèque et les flip cards gouvernance fonctionnent.

## 11. Checklist de release

- [ ] Script SQL idempotent exécuté en local avec succès.
- [ ] Script SQL idempotent exécuté une seconde fois sans erreur et sans doublon.
- [ ] Page `/a-propos/gouvernance` OK en FR/EN/AR.
- [ ] Médiathèque publique montre l'album dans les onglets « Tout » et « Albums ».
- [ ] Prévisualisation PDF inline fonctionne (médiathèque + gouvernance).
- [ ] Admin éditorial présente le champ `documents` comme non éditable + note.
- [ ] Admin albums permet les opérations CRUD sur les documents.
- [ ] Script de rollback testé en local, non destructif pour les ajouts admin.
- [ ] Migration jouée en production avec backup préalable.

## 12. Rollback opérationnel

En cas de souci en production :

```bash
# Sur le serveur prod
docker exec -i usenghor_db psql -U usenghor -d usenghor \
  < /path/to/repo/usenghor_backend/documentation/modele_de_données/migrations/032_gouvernance_album_rollback.sql
```

Puis revenir à la page `/a-propos/gouvernance` pour vérifier le fallback vide (ou un redéploiement frontend si la version du code n'est pas compatible avec l'état pré-migration — possible uniquement si on rollback aussi le code).

## 13. Points de contrôle post-release (J+7)

- Aucune erreur serveur liée à `albums/by-slug/gouvernance` (grep logs).
- Aucun ticket utilisateur signalant une régression sur la médiathèque ou la page gouvernance.
- SC-001 à SC-007 validés manuellement.
