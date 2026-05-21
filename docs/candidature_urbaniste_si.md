# De développeur fullstack à urbaniste SI — valoriser l'expérience Usenghor

> Document support pour candidature à un poste d'**urbaniste en système d'information**.
> Référentiel : projet Usenghor (Université Senghor, Alexandrie) — voir [`architechture_technique.md`](./architechture_technique.md).
> Version : 1.0 — 2026-05-18

---

## Préambule — Le métier d'urbaniste SI

L'**urbaniste SI** est responsable de :

- cartographier le SI existant et cible ;
- découper le SI en **zones / quartiers / îlots / blocs** cohérents ;
- garantir l'**alignement stratégique** entre métier et technique ;
- définir les **règles d'urbanisme** (couplage faible, réutilisation, interopérabilité, standardisation) ;
- piloter la **trajectoire d'évolution** du SI (schéma directeur, roadmap, ADR) ;
- formaliser et tenir à jour les livrables d'architecture (DAT, POS, vues métier / fonctionnelle / applicative / technique / données).

Le projet Usenghor coche **presque toutes les cases** d'un cas d'école d'urbanisation. Voici comment le valoriser.

---

## 1. Pratique des 4 vues du cadre d'urbanisme

Le DAT produit pour Usenghor est littéralement structuré selon le cadre canonique de l'urbanisme SI (Longépé / Club Urba-EA) :

| Vue d'urbanisme | Ce qui a été fait sur Usenghor |
|-----------------|--------------------------------|
| **Vue métier / fonctionnelle** | 6 grands domaines fonctionnels (Présence, Académique, Vie de l'université, Engagement, Sécurité, Plateforme), parcours utilisateurs, acteurs |
| **Vue applicative** | Découpage en briques (Nuxt SSR, FastAPI, PostgreSQL, Nginx, monitoring), 23+38 routers publics/admin, 16 services SQL |
| **Vue technique / infrastructure** | VPS, Docker, réseau, reverse-proxy, monitoring, TLS, sauvegardes |
| **Vue données** | Modèle PostgreSQL en 16 sous-domaines, audit, trilinguisme, contenu riche |

> **Argument candidature** :
> *« J'ai produit et tenu à jour le Dossier d'Architecture Technique du SI, en distinguant explicitement les vues fonctionnelle, applicative, infrastructure et données, avec ADR documentées. »*

---

## 2. Application des principes fondamentaux d'urbanisation

- **Découpage en zones / quartiers / blocs** : 16 services SQL isolés, routers publics vs admin, composables frontend par feature.
- **Couplage faible** : choix explicite (AD-10) de **références UUID inter-services** plutôt que de FK transversales — c'est exactement la doctrine d'un urbaniste qui prépare la migration future vers microservices.
- **Réutilisation** : 81 composables Nuxt, `EmailService` unique, abstraction `storage_type: local|s3`.
- **Standardisation** : pattern `*_html` + `*_md` systématique sur 11 tables ; trilinguisme `*_fr/*_en/*_ar` uniforme.
- **Séparation des préoccupations** : public/admin, frontend/backend, applicatif/monitoring sur réseaux Docker distincts.

> **Argument** :
> *« J'ai défini et appliqué des règles d'urbanisme transverses (nommage, trilinguisme, contenu riche, audit) sur l'ensemble du SI. »*

---

## 3. Gestion de la trajectoire et de la gouvernance

- **20 specs versionnées** (`specs/001` à `specs/020`) avec `spec.md`, `plan.md`, `tasks.md` — posture *roadmap d'urbanisation* avec jalons traçables.
- **ADR** (Architecture Decision Records) — 18 décisions formalisées avec justification.
- **RACI** projet et opérations défini.
- **Conformité & audit** : table `audit_logs` JSONB avec IP / user-agent, RBAC granulaire — sujets typiquement portés par un urbaniste pour la conformité RGPD / sécurité.

> **Argument** :
> *« J'ai piloté une roadmap d'évolution incrémentale du SI (20 incréments fonctionnels en ~18 mois) tout en garantissant la cohérence du socle. »*

---

## 4. Traduire le métier en architecture

C'est **le cœur du métier** d'urbaniste : pas juste designer du code, mais comprendre les enjeux métiers (rectorat, communication, formations, partenariats internationaux, levées de fonds) et les transformer en blocs SI cohérents.

> **Argument** :
> *« J'ai converti des besoins métiers hétérogènes (académique, communication, partenariats, candidatures internationales) en un SI unifié, trilingue, gouverné par RBAC. »*

---

## 5. Maîtrise des standards et de l'interopérabilité

- **API REST** documentée OpenAPI (FastAPI auto-génère Swagger).
- **JWT / OAuth-like** pour l'authentification.
- **Standards web** : Schema.org, hreflang, Open Graph, sitemap, JSON-LD.
- **Observabilité standard** : Prometheus / Grafana — l'urbaniste pousse souvent à standardiser la supervision.

---

## 6. Lucidité sur la dette technique

Dans le DAT, rien n'a été caché :

- l'**absence de CI/CD** (R-03),
- le **SPOF VPS** (R-08),
- l'**absence de monitoring applicatif** (R-13),
- l'**absence de tâches planifiées**.

C'est exactement la posture d'un urbaniste : **lucidité sur la cible vs l'existant**, identification des écarts, plan de rattrapage.

> **Argument** :
> *« Je cartographie également les écarts entre l'architecture actuelle et la cible, avec un registre de risques et un plan de remédiation priorisé. »*

---

## 7. Points à mettre en avant dans la candidature

Pour un poste d'urbaniste SI, structurer CV / lettre autour de **4 angles** :

1. **Vision d'ensemble**
   *« Architecte d'un SI institutionnel trilingue couvrant 16 domaines métiers, du contenu éditorial à la levée de fonds, du RBAC à la médiathèque. »*

2. **Méthode et formalisation**
   *« Production et maintenance d'un DAT structuré selon le cadre d'urbanisme classique (4 vues + ADR + RACI + risques). »*

3. **Règles d'urbanisme transverses**
   *« Définition et application de règles transverses : couplage faible inter-domaines (UUID externes), trilinguisme, contenu riche, audit, sécurité défense-en-profondeur. »*

4. **Trajectoire**
   *« Pilotage incrémental — 20 incréments fonctionnels documentés, ADR, plan de remédiation des risques. »*

---

## 8. Compétences à compléter pour un profil urbaniste « senior »

| Compétence attendue | Comment combler |
|---------------------|-----------------|
| **TOGAF / Praxeme / cadre formel** | Lire le résumé TOGAF ADM ; la pratique est déjà là, il manque le vocabulaire officiel |
| **Plans d'Occupation des Sols (POS)** | Refaire la cartographie fonctionnelle sous forme de **POS à 3 niveaux** (zones / quartiers / îlots) plutôt qu'en simple liste |
| **EA tooling** | Mentionner l'aisance avec diagrams.net ; se familiariser avec Aris, Mega, Modelio ou ArchiMate |
| **ArchiMate** | Pour les schémas, utiliser les notations ArchiMate (acteurs, processus, services applicatifs, composants, nodes) → le DAT devient « language officiel » |
| **Schéma directeur** | Reformuler la liste des 20 specs comme un **schéma directeur 3 ans** avec axes stratégiques |

---

## 9. Tableau de correspondance compétences → preuves Usenghor

| Compétence urbaniste SI | Preuve concrète sur Usenghor |
|-------------------------|------------------------------|
| Cartographie SI multi-vues | DAT 12 sections (`architechture_technique.md`) |
| Découpage modulaire | 16 services SQL + routers publics/admin + composables par feature |
| Couplage faible | UUID externes inter-services (AD-10), abstraction storage (AD-11) |
| Règles d'urbanisme | Trilinguisme uniforme, pattern `*_html`/`*_md`, audit JSONB systématique |
| Gouvernance des données | RBAC granulaire, `audit_logs` JSONB (IP, UA, old/new) |
| Sécurité défense-en-profondeur | TLS, HSTS, JWT, rate-limit Nginx, isolation réseau Docker, secrets `openssl rand` |
| Observabilité | Spec 020 — Prometheus + Grafana + node-exporter + cAdvisor |
| Gestion de trajectoire | 20 specs versionnées, ADR, RACI, registre de risques |
| Interopérabilité & standards | REST/OpenAPI, JWT, Schema.org, hreflang, JSON-LD, Open Graph |
| Conformité & traçabilité | Audit complet, tokens RGPD-friendly (désinscription newsletter) |
| Pilotage de l'exploitation | `deploy.sh` unifié (setup, deploy, update, ssl, backup, monitoring) |
| Documentation continue | DAT, ADR, specs, CLAUDE.md, mémoires projet à jour |

---

## 10. Phrase d'accroche pour CV / lettre

> *« Au cours du projet Usenghor, j'ai assumé de facto le rôle d'urbaniste : cartographie en 16 domaines métiers et 4 vues d'architecture, définition de règles transverses (couplage faible, trilinguisme, audit, sécurité), pilotage d'une trajectoire de 20 incréments documentés par ADR, et formalisation d'un Dossier d'Architecture Technique incluant risques, RACI et plan de remédiation. »*

---

## 11. Prochaines étapes suggérées

Pour renforcer le dossier de candidature :

1. **Produire un POS (Plan d'Occupation des Sols)** à 3 niveaux (zones / quartiers / îlots) à partir des 16 domaines existants.
2. **Reformuler le DAT en notation ArchiMate** pour parler le langage officiel des recruteurs urbanistes SI.
3. **Construire un schéma directeur 3 ans** synthétisant la trajectoire passée (specs 001 → 020) et la cible future (CI/CD, monitoring applicatif, haute disponibilité, S3, microservices).
4. **Préparer 2-3 cas concrets** à raconter en entretien :
   - le découpage en services SQL avec couplage faible (UUID externes) ;
   - la mise en place du monitoring isolé (spec 020) sans exposition publique ;
   - la stratégie de trilinguisme + contenu riche appliquée uniformément.

---

*Fin du document.*
