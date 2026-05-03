# Quickstart — Page FAQ managée dans le backoffice

**Branch**: `019-faq-backoffice` | **Date**: 2026-05-02

Procédure pas-à-pas pour appliquer la feature en local puis en production. Suit l'ordre canonique CLAUDE.md : SQL source + migrations **avant** le code Python/TS.

---

## Prérequis

- Branche locale à jour : `git checkout 019-faq-backoffice && git pull`.
- Docker en marche : `docker ps | grep usenghor_postgres` doit afficher le conteneur local actif.
- Backend Python venv activé : `cd usenghor_backend && source .venv/bin/activate`.
- Frontend Node : `cd usenghor_nuxt && pnpm install` (si dépendances modifiées).

---

## 1. Appliquer la migration SQL en local

```bash
# Depuis la racine du repo
docker exec -i usenghor_postgres psql -U usenghor -d usenghor \
  < usenghor_backend/documentation/modele_de_données/migrations/033_faq.sql
```

Vérifier :

```bash
docker exec -i usenghor_postgres psql -U usenghor -d usenghor -c "\d faq_categories"
docker exec -i usenghor_postgres psql -U usenghor -d usenghor -c "\d faq_entries"
docker exec -i usenghor_postgres psql -U usenghor -d usenghor \
  -c "SELECT code, label_fr FROM faq_categories;"
# attendu : 1 ligne 'general' | 'Général'
```

Rollback de test (à exécuter sur une base jetable) :

```bash
docker exec -i usenghor_postgres psql -U usenghor -d usenghor \
  < usenghor_backend/documentation/modele_de_données/migrations/033_faq_rollback.sql
```

---

## 2. Démarrer le backend

```bash
cd usenghor_backend
uvicorn app.main:app --reload
```

Smoke-tests via Swagger (`http://localhost:8000/api/docs`) :

1. `GET /api/public/faq` → doit renvoyer `{ "categories": [{ "code": "general", "entries": [] }] }`.
2. Se connecter via `POST /api/auth/login` avec les identifiants `ADMIN_EMAIL` / `ADMIN_PASSWORD` (voir `usenghor_backend/.env`).
3. `POST /api/admin/faq/entries` avec un payload de test (catégorie `general`).
4. `PATCH /api/admin/faq/entries/{id}/publish` `{ "is_published": true }`.
5. Re-`GET /api/public/faq` → la nouvelle entrée apparaît.
6. Vérifier `audit_logs` :
   ```bash
   docker exec -i usenghor_postgres psql -U usenghor -d usenghor \
     -c "SELECT action, entity_id, created_at FROM audit_logs WHERE action LIKE 'faq.%' ORDER BY created_at DESC LIMIT 10;"
   ```
   Attendu : `faq.entry.create`, `faq.entry.publish` listés.

---

## 3. Démarrer le frontend

```bash
cd usenghor_nuxt
pnpm dev
```

QA manuelle :

### Public (`http://localhost:3000/faq`)

- [ ] La page se charge avec accordéon. La catégorie `Général` est visible.
- [ ] Cliquer sur une question → la réponse riche se déplie correctement.
- [ ] Bouton « copier le lien » → `localhost:3000/faq#<slug>` est dans le presse-papiers.
- [ ] Recharger avec `localhost:3000/faq#<slug>` → la question est ouverte automatiquement et amenée à l'écran.
- [ ] Champ recherche → la liste se filtre instantanément (sans appel réseau).
- [ ] Switch de langue EN puis AR → contenus traduits, RTL appliqué pour AR, repli silencieux sur FR si traduction manquante.
- [ ] Source HTML (`Cmd+U`) → un `<script type="application/ld+json">` contient un objet `@type: "FAQPage"`.
- [ ] Lighthouse → score Performance > 85 sur mobile 4G simulé.

### Admin (`http://localhost:3000/admin/faq`)

- [ ] Liste des questions visible, badges `Brouillon`/`Publié`.
- [ ] Filtrer par catégorie + statut fonctionne.
- [ ] Créer une question (3 langues, contenu riche TOAST UI, slug auto) → sauvegarde OK.
- [ ] Éditer, modifier le slug d'une question publiée → avertissement affiché.
- [ ] Drag-and-drop pour réordonner → l'ordre persiste après refresh et est reflété côté public.
- [ ] Tenter de supprimer la catégorie `Général` → refus avec message clair.
- [ ] Tenter de supprimer une catégorie non vide → refus.
- [ ] Créer une nouvelle catégorie `admissions` → publier une question dedans → visible publiquement.

---

## 4. Tests automatisés backend

```bash
cd usenghor_backend
pytest tests/ -k faq -v
```

Couverture attendue minimale :

- `tests/integration/test_admin_faq_api.py` : CRUD catégories, CRUD entrées, publish/unpublish, reorder, audit.
- `tests/integration/test_public_faq_api.py` : récupération arborescence, filtrage `is_active`/`is_published`, repli FR.
- `tests/unit/test_faq_slug.py` : génération de slug + résolution de collisions.

---

## 5. Déploiement en production

```bash
# 1) Pousser la branche, créer la PR, merger
git push -u origin 019-faq-backoffice
gh pr create --base main --head 019-faq-backoffice

# 2) Déployer
./deploy.sh update

# 3) Appliquer la migration sur la prod
docker exec -i usenghor_db psql -U usenghor -d usenghor \
  < usenghor_backend/documentation/modele_de_données/migrations/033_faq.sql

# 4) Vérifier
./deploy.sh status
docker exec -i usenghor_db psql -U usenghor -d usenghor \
  -c "SELECT COUNT(*) FROM faq_categories; SELECT COUNT(*) FROM faq_entries;"
```

QA prod :

- [ ] `https://<domaine>/faq` se charge et affiche la catégorie `Général`.
- [ ] `view-source:https://<domaine>/faq` contient le `<script type="application/ld+json">` `FAQPage`.
- [ ] Test Google Rich Results : https://search.google.com/test/rich-results — passer l'URL.
- [ ] Sitemap inclut `/faq` (vérifier `https://<domaine>/sitemap.xml`).

---

## 6. Rollback en cas d'incident

```bash
# Production
docker exec -i usenghor_db psql -U usenghor -d usenghor \
  < usenghor_backend/documentation/modele_de_données/migrations/033_faq_rollback.sql

# Puis revert le code
git revert <merge-sha>
git push origin main
./deploy.sh update
```

Le rollback SQL :
- supprime les tables `faq_entries` puis `faq_categories` (l'ordre est important — FK).
- supprime les triggers et la fonction `set_updated_at()` UNIQUEMENT si non utilisés ailleurs (vérifier avant — la fonction est probablement partagée).

---

## 7. Suivi post-déploiement

- Lancer `/speckit.tasks` puis l'implémentation.
- Activer un suivi sur `audit_logs` (action `LIKE 'faq.%'`) la première semaine.
- Mesurer SC-001 et SC-006 à J+30 et J+90 via les analytics existantes.
