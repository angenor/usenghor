# Research: 014-link-shortener

**Date**: 2026-03-25

## Décision 1 : Mécanisme du compteur séquentiel base 36

**Decision**: Utiliser une séquence PostgreSQL (`short_link_counter_seq`) pour le compteur. La conversion en base 36 se fait côté backend (Python).

**Rationale**: Les séquences PostgreSQL sont atomiques, performantes et persistent indépendamment des transactions annulées. Elles garantissent l'unicité sans verrouillage de table. La valeur `nextval()` ne recule jamais, même après suppression d'un lien.

**Alternatives considered**:
- Colonne auto-incrémentée sur la table `short_links` : ne persiste pas après suppression, les gaps ne sont pas garantis monotones.
- Table séparée `short_link_config` avec un compteur : nécessite un verrou explicite pour éviter les race conditions.
- Génération côté Python (en mémoire) : perte de l'état au redémarrage du serveur.

## Décision 2 : Architecture de la redirection `/r/{code}`

**Decision**: Créer un server route Nuxt (`server/routes/r/[code].get.ts`) qui appelle l'API publique backend et renvoie une redirection HTTP 302.

**Rationale**:
- Redirection côté serveur = instantanée (pas de chargement de page côté client).
- Reste dans l'architecture Nuxt existante (pas de modification nginx).
- Le backend expose un endpoint public `GET /api/public/short-links/{code}` qui renvoie l'URL cible (pas de redirect côté backend, pour découpler la logique).

**Alternatives considered**:
- Page Nuxt `/r/[code].vue` avec `navigateTo()` : plus lent (charge le JS client, puis redirige).
- Endpoint FastAPI qui retourne directement un 302 : nécessite une modification nginx pour router `/r/*` vers le backend.
- Middleware Nuxt global : overhead sur toutes les requêtes.

## Décision 3 : Stockage de la liste blanche de domaines

**Decision**: Stocker les domaines autorisés dans une table PostgreSQL `allowed_domains`. L'admin peut gérer cette liste depuis la même page de gestion des liens courts.

**Rationale**: Configurable sans redéploiement. Cohérent avec l'approche "tout en base de données" du projet. Simple à implémenter avec le pattern CRUD existant.

**Alternatives considered**:
- Variable d'environnement : nécessite un redéploiement pour changer.
- Fichier de configuration JSON : idem, moins pratique.
- Hardcodé dans le code : inflexible.

## Décision 4 : Conversion base 36 en Python

**Decision**: Fonction utilitaire Python `int_to_base36(n: int) -> str` utilisant l'alphabet `0123456789abcdefghijklmnopqrstuvwxyz`.

**Rationale**: Simple, déterministe, testable unitairement. Séquence : 0→0, 1→1, ..., 9→9, 10→a, 11→b, ..., 35→z, 36→10, 37→11, etc. Maximum 4 caractères = `zzzz` = 1 679 615 (index 0-based).

**Note**: L'alphabet commence par les chiffres puis les lettres (convention base 36 standard). Le premier lien aura le code `0`, le deuxième `1`, etc.

## Décision 5 : Format de la page admin

**Decision**: Page unique modale (pattern Partners) : `admin/liens-courts/index.vue` avec modales pour création et suppression. Pas de page d'édition séparée (la spec exclut la modification).

**Rationale**: Feature simple (création + liste + suppression). Le pattern modal est utilisé pour les entités simples du projet (partenaires, pays). Pas besoin de routes séparées.
