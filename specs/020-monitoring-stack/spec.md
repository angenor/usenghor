# Feature Specification: Socle de monitoring technique (système + conteneurs)

**Feature Branch**: `020-monitoring-stack`
**Created**: 2026-05-15
**Status**: Draft
**Input**: User description: "Mettre en place le socle d'une stack de monitoring technique pour le projet Usenghor (monorepo Nuxt 4 + FastAPI + PostgreSQL 16 + Nginx, déployé via Docker Compose sur un VPS). Cette première itération couvre uniquement la collecte des métriques système et conteneurs, sans instrumentation applicative."

## Clarifications

### Session 2026-05-15

- Q: Politique de redémarrage automatique des conteneurs de monitoring (après crash ou reboot machine) ? → A: `unless-stopped` (redémarre auto, respecte un arrêt manuel via `./deploy.sh monitoring down`).
- Q: Protection contre les attaques par force brute sur `monitoring.<DOMAINE>` en production ? → A: Rate limiting Nginx au niveau du sous-domaine (defense in depth en complément de la protection native de l'interface).
- Q: Budget disque maximal pour le stockage de la rétention 30 jours des métriques ? → A: ~5 GB (compact, suffisant pour la stack actuelle — à réviser quand les futures cibles applicatives seront ajoutées).
- Q: Stratégie de versionnage des images Docker (Prometheus, Grafana, node-exporter, cAdvisor) ? → A: Versions semver figées (ex: `prom/prometheus:v2.55.1`) — reproductibilité et mises à jour contrôlées via commit Git.
- Q: Politique de comptes Grafana (sign-up public et mode anonyme) ? → A: Sign-up public désactivé, mode anonyme désactivé, un seul compte admin unique provisionné via variables d'environnement.

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Surveiller la santé du VPS hôte en un coup d'œil (Priority: P1)

L'administrateur technique du projet Usenghor veut savoir, à tout moment, dans quel état se trouve le VPS qui héberge le site (CPU saturé ? RAM bientôt pleine ? disque en passe d'être plein ? charge réseau anormale ?). Il ouvre une interface de visualisation, s'authentifie, et trouve immédiatement un tableau de bord système qui affiche ces informations sans configuration préalable.

**Why this priority**: Sans cette visibilité, aucune décision technique éclairée n'est possible (faut-il redémarrer un service ? faut-il agrandir le VPS ? faut-il nettoyer un volume ?). C'est la **valeur minimale** que doit livrer cette itération : voir l'état du serveur. Tous les autres apports (dashboards conteneurs, alertes futures, instrumentation applicative) supposent que cette base fonctionne.

**Independent Test**: Démarrer la stack en local, se connecter à l'interface, observer un tableau de bord système qui affiche les valeurs réelles de CPU, RAM, disque et réseau du poste de travail ou du VPS. La présence de chiffres cohérents (non nuls, mis à jour automatiquement) suffit à valider la valeur livrée.

**Acceptance Scenarios**:

1. **Given** la stack de monitoring est démarrée et l'utilisateur dispose des identifiants administrateurs, **When** il ouvre l'URL locale de l'interface et se connecte, **Then** un tableau de bord système s'affiche automatiquement avec des graphiques mis à jour montrant CPU, RAM, disque, réseau et load average de la machine hôte.
2. **Given** la stack tourne depuis plusieurs minutes, **When** l'administrateur revient sur le tableau de bord, **Then** il voit un historique continu des métriques sur la fenêtre temporelle proposée (sans trous, sans données « 0 » non justifiées).
3. **Given** l'administrateur sélectionne une période d'observation plus longue (ex. dernières 24h), **When** la stack a accumulé des données depuis cette période, **Then** l'historique demandé s'affiche correctement.

---

### User Story 2 — Identifier le conteneur Docker qui consomme (Priority: P2)

Quand le VPS rame, l'administrateur veut savoir **quel conteneur** est responsable (frontend Nuxt ? backend FastAPI ? base PostgreSQL ? Nginx ?). Il ouvre un second tableau de bord, dédié aux conteneurs, et y voit la consommation CPU, RAM, I/O disque et réseau par conteneur, sans configuration manuelle.

**Why this priority**: Cette information est complémentaire à la P1 et devient indispensable dès qu'un incident survient. Sans elle, l'administrateur sait que « ça consomme », mais pas où chercher. Elle ne bloque pas la mise en route de la P1 mais doit être livrée dans la même itération.

**Independent Test**: Démarrer la stack pendant que les services applicatifs tournent (frontend, backend, base), ouvrir le tableau de bord conteneurs, vérifier que chaque conteneur est listé avec ses métriques propres.

**Acceptance Scenarios**:

1. **Given** la stack de monitoring et les services applicatifs sont démarrés, **When** l'administrateur ouvre le tableau de bord conteneurs, **Then** il voit la liste des conteneurs en cours d'exécution avec leur consommation CPU, RAM, I/O disque et trafic réseau, mise à jour automatiquement.
2. **Given** un conteneur applicatif est redémarré ou tombe, **When** l'administrateur consulte le tableau de bord, **Then** la chute puis la reprise des métriques sont visibles dans l'historique.

---

### User Story 3 — Sécuriser l'accès aux dashboards en production (Priority: P2)

L'administrateur veut accéder aux dashboards depuis n'importe où via Internet, mais sans exposer ces données techniques sensibles au monde entier. L'interface doit donc être (1) accessible via un sous-domaine HTTPS dédié, (2) protégée par une authentification obligatoire, et (3) les collecteurs internes ne doivent JAMAIS être joignables depuis l'extérieur.

**Why this priority**: Sans cette sécurité, la mise en production est impossible. Cependant, en environnement local, ce besoin n'existe pas — c'est pourquoi la P3 reste prioritaire mais distincte de la P1.

**Independent Test**: En production, ouvrir `https://monitoring.<DOMAINE>` depuis un navigateur externe au VPS, observer la redirection HTTPS et la page de connexion. Tenter d'accéder au port du collecteur de métriques depuis l'extérieur du VPS, vérifier que la connexion échoue.

**Acceptance Scenarios**:

1. **Given** la stack est déployée en production et le DNS pointe vers le VPS, **When** un utilisateur visite `https://monitoring.<DOMAINE>`, **Then** il est servi en HTTPS avec un certificat valide et atterrit sur une page de connexion.
2. **Given** un utilisateur sans identifiants visite l'URL, **When** il tente d'accéder à un tableau de bord, **Then** l'accès est refusé tant qu'il n'a pas saisi un identifiant et un mot de passe valides.
3. **Given** la stack tourne en production, **When** un tiers tente de joindre directement le port du collecteur de métriques (par exemple `http://<IP-VPS>:9090`) depuis Internet, **Then** la connexion échoue (port non exposé publiquement).

---

### User Story 4 — Conserver et restaurer l'historique des métriques (Priority: P3)

L'administrateur veut que l'historique des métriques survive aux redémarrages (conteneurs, machine, mises à jour d'images), tout en imposant une rétention raisonnable (30 jours) pour ne pas saturer le disque. Il veut aussi pouvoir sauvegarder cet historique et la configuration de l'interface, et les restaurer en cas d'incident.

**Why this priority**: Sans persistance, redémarrer la stack repart de zéro et perd toute valeur historique. La rétention 30 jours est un compromis entre utilité et coût disque. La procédure backup/restore est nécessaire mais peut être documentée même si elle n'est pas automatisée dans cette itération.

**Independent Test**: Démarrer la stack, laisser collecter quelques minutes, redémarrer les conteneurs, vérifier que l'historique précédent est toujours présent. Suivre la procédure documentée de sauvegarde, supprimer les volumes, suivre la procédure de restauration, vérifier que les données sont retrouvées.

**Acceptance Scenarios**:

1. **Given** la stack tourne depuis plusieurs heures et a accumulé un historique, **When** l'administrateur arrête puis redémarre les conteneurs de monitoring, **Then** l'historique précédent est intégralement accessible après redémarrage.
2. **Given** la stack tourne depuis plus de 30 jours, **When** l'administrateur consulte les métriques, **Then** seules les données des 30 derniers jours sont présentes, les plus anciennes ayant été purgées automatiquement.
3. **Given** une procédure de sauvegarde est documentée, **When** l'administrateur l'exécute, puis supprime les volumes, puis exécute la procédure de restauration, **Then** l'historique et la configuration de l'interface sont retrouvés à l'identique.

---

### User Story 5 — Opérer la stack via le script de déploiement existant (Priority: P3)

L'équipe technique pilote déjà le projet via un script `deploy.sh` (commandes `deploy`, `update`, `status`, `logs`, etc.). Pour rester cohérent et éviter de mémoriser un second outil, l'administrateur veut piloter la stack de monitoring via ce même script.

**Why this priority**: Apporte de la cohérence opérationnelle et réduit le risque d'erreur humaine, mais n'est pas bloquant techniquement (les commandes Docker Compose natives marchent aussi). Bonus de qualité de vie, donc P3.

**Independent Test**: Exécuter `./deploy.sh monitoring up`, vérifier que les 4 services démarrent. Exécuter `./deploy.sh monitoring status`, lire un retour clair sur l'état. Exécuter `./deploy.sh monitoring logs`, lire les logs agrégés. Exécuter `./deploy.sh monitoring down`, vérifier l'arrêt propre.

**Acceptance Scenarios**:

1. **Given** la stack est arrêtée, **When** l'administrateur exécute `./deploy.sh monitoring up`, **Then** les 4 services de monitoring démarrent et le script confirme leur état actif.
2. **Given** la stack tourne, **When** l'administrateur exécute `./deploy.sh monitoring status`, **Then** le script affiche sans ambiguïté l'état (actif / arrêté) de chacun des 4 services.
3. **Given** la stack tourne, **When** l'administrateur exécute `./deploy.sh monitoring logs`, **Then** les logs récents des services de monitoring s'affichent.
4. **Given** la stack tourne, **When** l'administrateur exécute `./deploy.sh monitoring down`, **Then** les 4 services sont arrêtés proprement sans perte des volumes persistants.

---

### Edge Cases

- **Identifiants administrateurs absents ou vides** : si les variables d'environnement requises ne sont pas définies au démarrage, la stack doit refuser de démarrer plutôt que d'exposer une interface sans mot de passe ou avec un mot de passe par défaut connu.
- **Saturation du volume de métriques** : avant d'atteindre la limite disque, la rétention 30 jours doit purger automatiquement les données les plus anciennes ; une métrique de saturation reste néanmoins visible sur le dashboard système.
- **Conflit de port en local** : si `3001` (interface) ou `9090` (collecteur) sont déjà occupés, l'administrateur doit pouvoir lever le conflit via une variable d'environnement ou un message d'erreur explicite, sans patch dans le code.
- **Redémarrage du démon Docker** : la stack et les volumes persistants doivent survivre à un redémarrage du démon Docker ou de la machine hôte.
- **Renouvellement du certificat HTTPS en production** : le sous-domaine monitoring doit suivre le même mécanisme automatique de renouvellement que les autres domaines du projet, sans intervention spécifique.
- **Mise à jour des images des outils de monitoring** : un changement de version d'image ne doit pas casser les tableaux de bord préfaits ni effacer l'historique des métriques.
- **Ajout futur de cibles applicatives** : la stack rejoint le réseau Docker principal du projet pour que les futures itérations (instrumentation FastAPI, exporters PostgreSQL/Nginx) puissent ajouter des cibles sans reconfiguration réseau.
- **Mémoire VPS limitée** : la consommation cumulée de la stack doit rester sous le budget annoncé même en cas d'accumulation longue de données.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001** : Le système DOIT s'exécuter dans un environnement isolé (profil de composition dédié ou fichier de composition séparé) qui ne démarre PAS automatiquement avec les services applicatifs du projet.
- **FR-002** : Le système DOIT collecter en continu les métriques système de la machine hôte : utilisation CPU (globale et par cœur), utilisation mémoire (RAM et swap), espace disque (par point de montage), trafic réseau (par interface), charge moyenne (load average).
- **FR-003** : Le système DOIT collecter en continu les métriques de chaque conteneur Docker en cours d'exécution sur la machine hôte : utilisation CPU, utilisation mémoire, I/O disque (lecture/écriture), trafic réseau (entrée/sortie).
- **FR-004** : Le système DOIT conserver l'historique des métriques pendant exactement 30 jours puis purger automatiquement les données plus anciennes.
- **FR-005** : Le système DOIT persister l'historique des métriques et la configuration de l'interface dans des volumes durables qui survivent aux redémarrages de conteneurs et de la machine hôte.
- **FR-006** : L'accès à l'interface de visualisation DOIT exiger une authentification par identifiant et mot de passe ; aucune navigation anonyme NE DOIT être possible.
- **FR-007** : Les identifiants administrateurs de l'interface DOIVENT être configurables exclusivement via variables d'environnement et NE DOIVENT JAMAIS apparaître en clair dans les fichiers versionnés (code, configuration de référence).
- **FR-008** : Si les variables d'environnement d'identifiants administrateurs sont absentes ou vides au démarrage, la stack DOIT refuser de démarrer ou indiquer une erreur explicite plutôt que d'exposer une interface non protégée.
- **FR-009** : En environnement de production, l'accès à l'interface DOIT être servi en HTTPS avec un certificat valide reconnu par les navigateurs courants.
- **FR-010** : Le collecteur de métriques et les exporters (système, conteneurs) NE DOIVENT être joignables que depuis le réseau Docker interne ; aucun de ces composants NE DOIT exposer de port accessible depuis Internet ou depuis l'hôte en production.
- **FR-011** : En environnement local de développement, l'interface de visualisation DOIT être accessible sur `http://localhost:3001`.
- **FR-012** : En environnement de production, l'interface de visualisation DOIT être accessible via un sous-domaine dédié de la forme `monitoring.<DOMAINE>`, configurable via variable d'environnement.
- **FR-013** : Au premier lancement et sans intervention manuelle, l'interface DOIT charger automatiquement (1) la source de données pointant vers le collecteur de métriques, (2) un tableau de bord prêt à l'emploi pour les métriques système et (3) un tableau de bord prêt à l'emploi pour les métriques conteneurs.
- **FR-014** : Les administrateurs DOIVENT pouvoir piloter la stack via le script `deploy.sh` existant avec au minimum les sous-commandes : `monitoring up`, `monitoring down`, `monitoring logs`, `monitoring status`.
- **FR-015** : La consommation mémoire totale de la stack de monitoring NE DOIT PAS dépasser 600 MB en fonctionnement nominal (collecte active sans pic de requêtes).
- **FR-016** : Une procédure documentée DOIT permettre la sauvegarde et la restauration des volumes contenant l'historique des métriques et la configuration de l'interface.
- **FR-017** : La stack DOIT rejoindre le réseau Docker principal du projet pour permettre, dans les itérations suivantes, le scraping de services applicatifs (frontend, backend, base, reverse proxy) sans reconfiguration réseau.
- **FR-018** : Une documentation française DOIT couvrir : (a) l'installation locale étape par étape, (b) l'installation sur VPS étape par étape, (c) la procédure d'accès aux tableaux de bord, (d) la procédure de sauvegarde / restauration des volumes.
- **FR-019** : La documentation DOIT permettre à un développeur découvrant la stack pour la première fois de la mettre en route et d'atteindre les tableaux de bord en moins de 15 minutes (installation locale).
- **FR-020** : Aucune modification du code applicatif (frontend Nuxt, backend FastAPI) NE DOIT être nécessaire dans cette itération.
- **FR-021** : Le fichier de référence des variables d'environnement (`.env.example`) DOIT être mis à jour pour inclure les variables : nom d'utilisateur administrateur de l'interface, mot de passe administrateur de l'interface, sous-domaine de monitoring.
- **FR-022** : Les tableaux de bord préfaits affichés DOIVENT couvrir au minimum les besoins listés en FR-002 (système) et FR-003 (conteneurs), avec des valeurs réelles et des graphiques mis à jour automatiquement.
- **FR-023** : Tous les conteneurs de la stack de monitoring DOIVENT être configurés avec la politique de redémarrage `unless-stopped` : ils redémarrent automatiquement après un crash ou un reboot du démon Docker / de la machine hôte, mais respectent un arrêt manuel explicite (`./deploy.sh monitoring down` ou `docker compose down`).
- **FR-024** : En production, la configuration Nginx du sous-domaine `monitoring.<DOMAINE>` DOIT appliquer un rate limiting par adresse IP cliente (à titre indicatif : ordre de grandeur 30 requêtes / minute / IP sur l'ensemble du sous-domaine, et plus restrictif sur les routes d'authentification), en complément des protections natives de l'interface (verrouillage de compte après plusieurs échecs).
- **FR-025** : Le stockage de la rétention 30 jours des métriques DOIT respecter un budget disque cible d'environ 5 GB. Le système DOIT (a) signaler via un graphique du tableau de bord système la consommation effective du volume, et (b) ne pas dépasser ce budget en fonctionnement nominal avec le périmètre actuel (node-exporter + cAdvisor uniquement). Ce budget sera révisé dans les itérations suivantes lors de l'ajout de cibles applicatives.
- **FR-026** : Toutes les images Docker de la stack de monitoring DOIVENT être référencées par une version semver explicite (par exemple `prom/prometheus:v2.55.1`) — l'usage de `latest` ou d'un tag majeur seul (`:v2`) est interdit. Toute montée de version DOIT passer par une modification explicite, versionnée dans Git et documentée dans le changelog du projet.
- **FR-027** : La configuration de l'interface de visualisation DOIT explicitement (a) désactiver l'inscription publique (aucun visiteur ne peut créer un compte), (b) désactiver le mode visiteur anonyme (aucun dashboard accessible sans authentification), et (c) provisionner un unique compte administrateur dont les identifiants proviennent exclusivement des variables d'environnement définies en FR-007 et FR-021.

### Key Entities

- **Métrique système** : mesure horodatée de l'état de la machine hôte (CPU, RAM, disque, réseau, load), associée à un type de ressource et éventuellement à un identifiant de sous-ressource (interface réseau, point de montage, cœur CPU).
- **Métrique conteneur** : mesure horodatée de l'état d'un conteneur Docker (CPU, RAM, I/O, réseau), associée au nom du conteneur et à son image.
- **Tableau de bord** : vue préfabriquée et provisionnée automatiquement, regroupant un ensemble cohérent de métriques pour un usage donné (système ou conteneurs).
- **Source de données** : référence configurée vers le collecteur de métriques, utilisée par les tableaux de bord pour requêter l'historique.
- **Compte administrateur** : utilisateur autorisé à se connecter à l'interface ; ses identifiants proviennent exclusivement de variables d'environnement.
- **Volume de persistance** : zone de stockage durable contenant (a) l'historique 30 jours des métriques, ou (b) la configuration et les préférences de l'interface (utilisateurs, dashboards créés à la main, datasources). Deux volumes distincts au minimum.
- **Profil de monitoring** : ensemble logique des services de monitoring activable / désactivable indépendamment des services applicatifs.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001** : Au lancement de la stack en local, 100% des 4 services (collecteur, interface, exporter système, exporter conteneurs) atteignent l'état actif sans intervention manuelle.
- **SC-002** : Après authentification, les deux tableaux de bord (système et conteneurs) s'affichent automatiquement avec des données réelles, sans qu'aucune source de données ni dashboard n'ait été configuré à la main.
- **SC-003** : Une métrique capturée est visible dans l'interface en moins de 30 secondes après sa capture.
- **SC-004** : Aucun accès anonyme à l'interface n'est possible : 100% des sessions exigent une authentification valide.
- **SC-005** : En production, 100% du trafic vers le sous-domaine de monitoring est servi en HTTPS avec un certificat reconnu (aucun avertissement navigateur).
- **SC-006** : En production, une tentative d'accès direct au port du collecteur de métriques depuis l'extérieur du VPS échoue (timeout ou connexion refusée).
- **SC-007** : Sur une période d'observation de 24h en charge nominale, la consommation mémoire cumulée de la stack reste sous 600 MB.
- **SC-008** : Au-delà de 30 jours d'exécution continue, les métriques plus anciennes que 30 jours ne sont plus disponibles à la consultation (purge automatique effective).
- **SC-009** : Un nouveau développeur, équipé uniquement de la documentation française fournie, peut démarrer la stack en local et atteindre un tableau de bord avec données réelles en moins de 15 minutes.
- **SC-010** : La procédure documentée de sauvegarde / restauration permet, après suppression complète des volumes puis restauration, de retrouver l'historique des métriques et la configuration de l'interface à l'identique.
- **SC-011** : Les sous-commandes `monitoring up`, `monitoring down`, `monitoring logs`, `monitoring status` du script de déploiement renvoient un résultat clair et cohérent avec l'état effectif des services.
- **SC-012** : Aucune ligne du code applicatif (frontend Nuxt, backend FastAPI) n'est modifiée dans le cadre de cette itération (vérifiable par diff).
- **SC-013** : Après redémarrage du démon Docker ou de la machine hôte, l'historique des métriques antérieur est intégralement retrouvé.
- **SC-014** : 100% des conteneurs de monitoring se relancent automatiquement après un crash ou un reboot du démon Docker (politique `unless-stopped` effective), tout en respectant un arrêt manuel via `./deploy.sh monitoring down`.
- **SC-015** : Sur le sous-domaine de production, 100% des requêtes au-delà du seuil de rate limiting défini reçoivent une réponse HTTP de limitation (par exemple 429), vérifiable par test de charge ciblé.
- **SC-016** : La consommation effective du volume de métriques après 30 jours d'exécution continue avec le périmètre actuel (node-exporter + cAdvisor) reste sous le budget de 5 GB et est visible sur le tableau de bord système.
- **SC-017** : 100% des images Docker du `docker-compose.monitoring.yml` portent une version semver explicite (vérifiable par grep ; aucun `:latest` toléré).
- **SC-018** : Une tentative d'inscription publique ou d'accès anonyme à un dashboard en production échoue (page de connexion exigée, aucun formulaire d'inscription visible).

## Assumptions

- Le projet est déjà déployé sur le VPS avec Docker Compose, Nginx et un mécanisme automatique de renouvellement de certificats (Let's Encrypt) fonctionnels.
- Un enregistrement DNS pour le sous-domaine `monitoring.<DOMAINE>` peut être ajouté et pointe vers l'adresse IP du VPS.
- Le réseau Docker principal du projet existe déjà et permet d'attacher des services additionnels.
- Le VPS dispose d'au moins 1 GB de RAM disponible après les services applicatifs pour héberger la stack monitoring.
- L'administrateur dispose des droits suffisants (root ou sudo) pour modifier le script de déploiement et la configuration du reverse proxy en production.
- Les ports `9090` (collecteur de métriques) et `3001` (interface de visualisation) sont libres en environnement local.
- L'usage des tableaux de bord publics préfaits (ID 1860 « Node Exporter Full » et ID 193 « Docker / cAdvisor » ou équivalent récent) est acceptable et leur licence est compatible avec le projet.
- La procédure de sauvegarde / restauration peut être manuelle et documentée dans cette itération ; une automatisation pourra venir dans une itération ultérieure si besoin.
- La fréquence d'échantillonnage par défaut du collecteur (intervalle court de l'ordre de quelques secondes à quelques dizaines de secondes) est acceptable pour les besoins d'observation actuels.
- Un seul compte administrateur d'interface est suffisant pour cette itération ; la gestion multi-utilisateurs viendra plus tard si nécessaire (cf. FR-027).
- La rétention 30 jours et le budget RAM ~600 MB sont compatibles avec la taille typique d'un VPS hébergeant le projet.

## Out of Scope

Les éléments suivants sont explicitement **hors périmètre** de cette itération et feront l'objet de spécifications ultérieures :

- Instrumentation applicative du backend FastAPI (métriques HTTP, latences, erreurs).
- Exporters spécialisés pour Nginx et PostgreSQL.
- Gestion d'alertes et notifications (email, Slack, etc.).
- Centralisation des logs.
- Tracing distribué.
- Gestion multi-utilisateurs et rôles fins dans l'interface de visualisation.
- Automatisation de la sauvegarde des volumes (la procédure documentée manuelle suffit ici).
- Métriques métiers / fonctionnelles (nombre d'inscriptions, taux d'erreur applicatif, etc.).
