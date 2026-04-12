# Quickstart — Validation manuelle de la feature

**Feature**: `016-mediatheque-direct-upload`
**Date**: 2026-04-12
**Audience** : développeur ou QA qui vérifie la feature sur un environnement local ou préproduction.

Ce document remplace (à défaut) la suite automatisée absente. Chaque scénario couvre un ou plusieurs critères de succès (SC-00x) et des exigences fonctionnelles (FR-0xx).

---

## Pré-requis

1. Backend démarré :

   ```bash
   cd usenghor_backend
   docker compose up -d
   source .venv/bin/activate
   uvicorn app.main:app --reload
   ```

2. Frontend démarré :

   ```bash
   cd usenghor_nuxt
   pnpm install
   pnpm dev
   ```

3. Se connecter à http://localhost:3000 avec les identifiants admin (voir `usenghor_backend/.env` → `ADMIN_EMAIL` / `ADMIN_PASSWORD`).

4. Préparer des fichiers de test :
   - `small.jpg` — image 500 Ko
   - `medium.pdf` — PDF 5 Mo
   - `big.mp4` — vidéo 40 Mo (< 50 Mo)
   - `too-big.mp4` — vidéo > 50 Mo
   - `script.exe` — type rejeté
   - Un dossier de 10 images pour le test de concurrence

---

## Scénario 1 — Parcours heureux simple (FR-001, FR-003, FR-006, FR-007, SC-001, SC-004)

1. Aller sur http://localhost:3000/admin/mediatheque
2. S'assurer d'être sur l'onglet **Fichiers**
3. Noter le compteur total (ex. « 42 »)
4. Cliquer sur **Ajouter des fichiers**
5. Cliquer **Parcourir**, sélectionner `small.jpg`
6. **Attendu** :
   - Le fichier apparaît dans la liste de la modale avec statut « En cours… »
   - Quelques secondes plus tard, statut « Terminé »
   - Le fichier apparaît en tête de la grille de l'onglet Fichiers
   - Le compteur total passe de 42 à 43
   - Aucun album n'a été créé (onglet Albums inchangé)
7. Cliquer **Fermer**

✅ SC-001 validé si le fichier est bien enregistré.
✅ SC-004 validé si l'opération prend < 15 secondes.

---

## Scénario 2 — Téléversement multiple avec drag & drop (FR-002, FR-004, FR-015, SC-002)

1. Ouvrir la modale d'ajout
2. Glisser-déposer 10 images depuis le Finder/Explorer dans la zone dropzone
3. **Attendu** :
   - Les 10 fichiers apparaissent dans la liste de la modale
   - Ouvrir DevTools → onglet Network, filtrer sur `upload`
   - **Au plus 5 requêtes** `POST /api/admin/media/upload` en parallèle à tout instant
   - Les 5 suivantes démarrent progressivement à mesure que les premières finissent
   - Chaque fichier affiche son statut individuel (En cours → Terminé)
4. À la fin, la grille affiche les 10 nouveaux fichiers en tête
5. Le compteur passe de N à N+10

✅ SC-002 validé.
✅ FR-015 validé si le pool est bien plafonné à 5.

---

## Scénario 3 — Validation type de fichier (FR-005, FR-011)

1. Ouvrir la modale
2. Sélectionner `script.exe`
3. **Attendu** :
   - Le fichier est **rejeté immédiatement** (statut « Rejeté » ou pas ajouté à la liste)
   - Un message clair s'affiche : « Type de fichier non supporté »
   - Aucune requête réseau n'est envoyée

---

## Scénario 4 — Validation taille (FR-005, FR-011)

1. Ouvrir la modale
2. Sélectionner `too-big.mp4` (> 50 Mo)
3. **Attendu** :
   - Rejet immédiat, message « Fichier trop volumineux (max 50 Mo) »
   - Aucune requête réseau

---

## Scénario 5 — Échec partiel et récapitulatif (FR-009, SC-003)

1. Ouvrir la modale
2. Sélectionner 5 fichiers : 4 valides + 1 `too-big.mp4`
3. **Attendu** :
   - Les 4 valides sont téléversés avec succès
   - Le fichier trop gros reste en état « Rejeté »
   - Un récapitulatif s'affiche : « 4 sur 5 fichiers ajoutés »
   - Les 4 réussites apparaissent dans la grille

✅ SC-003 validé si le récapitulatif est lisible en moins de 5 secondes.

---

## Scénario 6 — Échec réseau et retry (FR-009)

1. Ouvrir DevTools → onglet Network → Throttling **Offline**
2. Ouvrir la modale, sélectionner 2 fichiers
3. **Attendu** : les 2 fichiers passent en état « Erreur » avec un bouton « Réessayer »
4. Repasser Network en **Online**
5. Cliquer **Réessayer** sur un fichier
6. **Attendu** : le fichier se téléverse correctement, passe à « Terminé » et apparaît dans la grille

---

## Scénario 7 — Annulation à la fermeture (FR-013)

1. Ouvrir la modale
2. Sélectionner 5 gros fichiers (`big.mp4` × 5) pour avoir du temps
3. Les uploads démarrent
4. Pendant qu'ils sont en cours, cliquer **Fermer** (ou Échap, ou clic extérieur)
5. **Attendu** :
   - Une boîte de confirmation apparaît : « Des fichiers sont en cours d'envoi, voulez-vous annuler ? »
   - Cliquer **Annuler** (= conserver les uploads) → la modale reste ouverte, les uploads continuent
6. Refermer, cette fois confirmer l'annulation
7. **Attendu** :
   - Les requêtes en cours sont interrompues (Network → requêtes annulées)
   - La modale se ferme
   - Les fichiers déjà téléversés avant l'annulation sont présents dans la grille
   - Ceux qui étaient en cours ne sont PAS apparus

✅ Edge case « fermeture pendant upload » validé.

---

## Scénario 8 — Association a posteriori à un album (FR-008)

1. Téléverser 3 fichiers directement (Scénario 1 × 3 ou Scénario 2 light)
2. Dans la grille, sélectionner les 3 fichiers (checkboxes)
3. Cliquer **Ajouter à un album**
4. Choisir un album existant → Confirmer
5. **Attendu** : les 3 fichiers sont associés à l'album, visibles dans la page dudit album

✅ FR-008 validé : un média téléversé direct reste entièrement compatible avec les parcours existants.

---

## Scénario 9 — Non-régression page album (SC-005)

1. Aller sur `/admin/mediatheque/albums/{id-existant}`
2. Cliquer sur le bouton d'ajout de fichiers de la page album (pas celui de la médiathèque)
3. Téléverser 2 fichiers
4. **Attendu** : comportement identique à avant la feature (barre de progression simulée, ajout réussi, fichiers associés à l'album)

✅ SC-005 validé si rien n'a changé dans ce parcours.

---

## Scénario 10 — i18n, dark mode, RTL (FR-012)

1. Basculer la langue en **Anglais** → vérifier que tous les libellés de la modale sont traduits
2. Basculer en **Arabe** → vérifier que la mise en page est en RTL (zone de drop alignée à droite, ordre des éléments miroir)
3. Basculer en **dark mode** → vérifier que la modale a les bonnes couleurs sombres
4. Tester avec clavier seul :
   - Tab pour naviguer entre les boutons
   - Entrée pour activer **Parcourir**
   - Échap pour fermer (avec confirmation si upload en cours)

---

## Scénario 11 — URL externe retirée (FR-014)

1. Ouvrir la modale d'ajout
2. **Attendu** : **aucun champ « URL externe »** visible, aucun bouton de ce type, aucun libellé lié
3. Chercher via DevTools Elements Inspector : aucun résidu DOM

---

## Checklist de sortie

- [ ] Tous les scénarios 1–11 passent
- [ ] Aucune erreur dans la console navigateur
- [ ] Aucune erreur 5xx dans les logs backend
- [ ] Les compteurs de la grille sont cohérents avec la base (`SELECT COUNT(*) FROM media`)
- [ ] Lighthouse / axe accessibility : aucune régression sur la page `/admin/mediatheque`
- [ ] Le diff final ne touche **aucun fichier** de `usenghor_backend/`
- [ ] Le diff final ne touche **aucun fichier** dans `usenghor_nuxt/app/pages/admin/mediatheque/albums/`
