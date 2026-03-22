# Research: Refonte Page Levée de Fonds

**Branch**: `010-fundraising-revamp` | **Date**: 2026-03-22

## R1: Anti-spam sans CAPTCHA externe

**Decision**: Mécanisme anti-spam combiné côté client (honeypot + challenge JS + délai minimum)

**Rationale**: La spec exige un "vérificateur de navigateur" plutôt qu'un CAPTCHA externe. Une approche multi-couches côté client offre une bonne protection sans dépendance tierce ni friction UX :
- **Honeypot** : champ caché en CSS, invisible pour l'utilisateur mais rempli par les bots → rejet immédiat si rempli
- **Challenge JS** : token généré côté client avec timestamp + hash → vérifié côté serveur → prouve que le navigateur exécute du JS
- **Délai minimum** : rejet si le formulaire est soumis en moins de 3 secondes après l'ouverture → les bots soumettent instantanément

**Alternatives considered**:
- reCAPTCHA/hCaptcha : dépendance externe, friction UX, problèmes RGPD → rejeté
- Turnstile (Cloudflare) : gratuit mais dépendance externe → rejeté par la spec
- Question mathématique : UX pauvre, facile à contourner → rejeté

## R2: Stockage des sections éditoriales structurées

**Decision**: Nouvelle table `fundraiser_editorial_sections` avec items dans `fundraiser_editorial_items`

**Rationale**: La table `editorial_contents` existante stocke du contenu rich text libre (HTML/MD). Les sections de la page levée de fonds nécessitent des items structurés (icône + titre + description). Deux tables dédiées permettent :
- Typage fort des items (icône, titre trilingue, description trilingue)
- Ordre d'affichage contrôlable par l'admin
- Séparation claire des 3 sections (raisons, engagements, bénéfices)

**Alternatives considered**:
- Réutiliser `editorial_contents` avec JSON dans un champ : perte de typage, requêtes complexes → rejeté
- Stocker en JSON dans la config : non éditable via admin → rejeté
- Fichiers i18n statiques : non éditables dynamiquement → rejeté

## R3: Export CSV des manifestations d'intérêt

**Decision**: Endpoint admin dédié utilisant `StreamingResponse` avec `csv.writer` + `io.StringIO`

**Rationale**: Pattern déjà utilisé dans le projet pour l'export des audit logs (`/routers/admin/audit_logs.py`) et des réponses de sondages (`/routers/admin/surveys.py`). Réutiliser ce pattern assure la cohérence.

**Alternatives considered**:
- Export Excel (openpyxl) : dépendance supplémentaire, CSV suffit → rejeté
- Export côté frontend : pas fiable pour gros volumes → rejeté

## R4: Médiathèque de campagne

**Decision**: Table de jonction `fundraiser_media` reliant `fundraisers` à `media` existant

**Rationale**: Le système de médias centralisé (`media` table + `/api/public/media/{uuid}/download`) est déjà en place. Une table de jonction simple permet d'associer plusieurs médias à une campagne avec un ordre d'affichage, sans dupliquer le stockage.

**Alternatives considered**:
- Champ JSON array d'UUIDs dans `fundraisers` : pas de contrainte d'intégrité, tri complexe → rejeté
- Nouveau système de galerie indépendant : over-engineering → rejeté

## R5: Consentement d'affichage du montant contributeur

**Decision**: Ajout d'un champ booléen `show_amount_publicly` (défaut: false) sur `fundraiser_contributors`

**Rationale**: Solution la plus simple. L'admin coche/décoche lors de la saisie du contributeur. Le endpoint public filtre le montant en fonction de ce flag.

**Alternatives considered**:
- Système de consentement par le contributeur lui-même (email + lien) : trop complexe pour cette phase → rejeté
- Montant toujours masqué avec uniquement le total visible : ne correspond pas à la clarification → rejeté

## R6: Manifestation d'intérêt — modèle de données

**Decision**: Nouvelle table `fundraiser_interest_expressions` avec contrainte UNIQUE(email, fundraiser_id) et statut de suivi

**Rationale**:
- Anti-doublon via contrainte UNIQUE en base (INSERT ON CONFLICT UPDATE)
- Statuts `new` et `contacted` pour le workflow admin
- Pas de lien avec la table `users` (visiteurs anonymes)
- Email de confirmation via le service email existant (Jinja2 template)

**Alternatives considered**:
- Table `applications` existante : sémantique différente (candidatures académiques) → rejeté
- Table `newsletter_subscribers` : champs et workflow incompatibles → rejeté
