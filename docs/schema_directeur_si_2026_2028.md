# Schéma directeur SI — Université Senghor 2026 → 2028

> Document d'urbanisme stratégique — trajectoire à 3 ans.
> Référentiels associés : [`architechture_technique.md`](./architechture_technique.md), [`pos_si_usenghor.md`](./pos_si_usenghor.md), [`archimate_si_usenghor.md`](./archimate_si_usenghor.md).
> Version : 1.0 — 2026-05-18

---

## 1. Préambule

Le présent schéma directeur formalise la **trajectoire d'évolution** du SI de l'Université Senghor sur la période **2026 – 2028**, en s'appuyant sur :

- l'**existant** documenté (DAT + POS 5 zones, ~16 services SQL, 20 incréments fonctionnels livrés depuis 2025) ;
- les **risques** identifiés (R-01 à R-13 du DAT) ;
- les **principes d'urbanisme** (couplage faible, mutualisation, sécurité défense-en-profondeur, sobriété).

Il vise à transformer un SI fonctionnel mais **mono-VPS, non automatisé, sans monitoring applicatif** en un SI **résilient, automatisé, observable de bout en bout** sans rupture de service.

---

## 2. Vision & ambitions stratégiques

> **Vision 2028** : « Faire du SI de l'Université Senghor une plateforme numérique de référence pour les universités francophones internationales : trilingue, observable, hautement disponible, et conforme aux standards de gouvernance des données. »

### 4 ambitions

1. **Industrialisation** — automatiser le cycle de vie (CI/CD, tests, déploiement, sauvegardes).
2. **Résilience** — supprimer le SPOF, garantir 99,9 % de disponibilité.
3. **Observabilité de bout en bout** — métriques applicatives, alerting, traçabilité.
4. **Évolutivité contrôlée** — préparer la montée en charge (rentrées universitaires, campagnes médiatiques) et l'ouverture éventuelle à des microservices ciblés.

---

## 3. Trajectoire passée (synthèse 2025 – mi-2026)

### Trois plateaus livrés

| Plateau | Période | Thème dominant | Specs |
|---------|---------|----------------|-------|
| **P0 — Socle initial** | 2025 S1 | Édition, VPS, identité | 001 (TOAST UI), 002 (modal), 003 (audit), 005 (VPS+SMTP), 006 (reset) |
| **P1 — Engagement & contenu** | 2025 S2 – 2026 S1 | Communauté, contenus riches | 004 / 010 (fundraising), 007 (décor), 008 (surveys), 009 (OG), 012 (médias news/events), 014 (links), 015 / 016 / 018 (médiathèque), 017 (couleurs), 019 (FAQ) |
| **P2 — Observabilité (en cours)** | 2026 S2 | Monitoring système & conteneurs | 020 (monitoring stack) |

### Capitalisation

- Modèle de données stabilisé sur **16 services SQL** avec règles d'urbanisme (trilinguisme, contenu riche, audit).
- Plateforme déployable d'un trait par `./deploy.sh`.
- Authentification + RBAC + audit complets.
- 20 incréments livrés ; aucune régression majeure rapportée.

---

## 4. Évaluation de l'existant (gap analysis)

| Axe | Existant | Cible 2028 | Écart |
|-----|----------|------------|:-----:|
| CI/CD | Aucun, déploiement manuel SSH | Pipeline GitHub Actions (build + tests + déploiement webhook) | ●●● |
| Tests automatisés | Partiels (Vitest, Playwright, Pytest installés) | Couverture ≥ 70 %, CI bloquant sur PR | ●● |
| Haute disponibilité | VPS unique (SPOF) | Réplique chaude ou failover régional | ●●● |
| Monitoring applicatif | Métriques système + conteneurs (spec 020) | + `/metrics` FastAPI + alertmanager + SLOs | ●● |
| Stockage médias | Filesystem local | S3-compatible + CDN | ●● |
| Tâches planifiées | Aucune | Celery (ou APScheduler) + Redis | ●● |
| Architecture | Monolithe modulaire | Monolithe + microservices ciblés (médias, sondages) | ● |
| Gouvernance données / RGPD | Audit JSONB | + Politique rétention, anonymisation, DPO outillé | ●● |
| Sauvegardes | Manuelles (`./deploy.sh backup`) | Automatisées + off-site + tests de restauration trimestriels | ●●● |
| Sécurité | TLS, JWT, RBAC, rate-limit | + WAF (ModSecurity / Cloudflare), scan dépendances, rotation secrets périodique | ●● |
| Documentation | DAT, POS, ArchiMate, ADR | + Schéma directeur (ce doc) + procédures opérationnelles formalisées | ● |

---

## 5. Plateaus cibles (architecture-cible incrémentale)

### Plateau **P3 — Industrialisation** (2026 S2 → 2027 S1)

> **Thème** : Automatiser ce qui est encore manuel et fragile.

**Work packages**

| WP | Description | Effort | Bénéfice |
|----|-------------|:------:|----------|
| WP-3.1 | Pipeline CI GitHub Actions (lint + tests Vitest / Playwright / Pytest) | M | Détection régressions |
| WP-3.2 | Pipeline CD (build images → push registry → webhook deploy sur VPS) | M | Déploiement reproductible |
| WP-3.3 | Couverture tests backend ≥ 70 % | L | Confiance technique |
| WP-3.4 | Couverture tests frontend ≥ 60 % | L | Confiance UX |
| WP-3.5 | Sauvegardes automatisées (cron quotidien BDD + hebdo médias) | S | Continuité |
| WP-3.6 | Politique rotation secrets (90 j) | S | Sécurité |
| WP-3.7 | Scan automatisé des dépendances (Dependabot / Renovate) | S | Sécurité |
| WP-3.8 | Documentation runbooks d'exploitation | S | Transmission |

**Capabilities renforcées** : C-05 Exploitation.

---

### Plateau **P4 — Observabilité applicative & alerting** (2027 S1 → S2)

> **Thème** : Voir et anticiper, pas seulement réagir.

**Work packages**

| WP | Description | Effort | Bénéfice |
|----|-------------|:------:|----------|
| WP-4.1 | Endpoint `/metrics` FastAPI (prometheus_client) | S | Latence + taux erreur |
| WP-4.2 | Instrumentation Nuxt (Web Vitals → Prometheus) | M | UX mesurée |
| WP-4.3 | Alertmanager + canaux (e-mail / Slack / SMS) | S | Réactivité |
| WP-4.4 | Définition de SLO/SLI (dispo 99,9 %, P95 < 500 ms) | S | Contrat de service |
| WP-4.5 | Dashboards Grafana applicatifs (par service, par locale) | M | Pilotage |
| WP-4.6 | Logs centralisés (Loki ou OpenSearch) | M | Forensic |
| WP-4.7 | Tracing distribué (OpenTelemetry) | M | Debug end-to-end |

**Capabilities renforcées** : C-05 Exploitation, C-04 Gouvernance.

---

### Plateau **P5 — Résilience & haute disponibilité** (2027 S2 → 2028 S1)

> **Thème** : Supprimer le SPOF, lisser les pics.

**Work packages**

| WP | Description | Effort | Bénéfice |
|----|-------------|:------:|----------|
| WP-5.1 | CDN devant le frontend (Cloudflare Free / Pro) | S | Latence + protection DDoS |
| WP-5.2 | Stockage médias migré S3-compatible (Backblaze B2 ou Scaleway) | M | Découplage VPS |
| WP-5.3 | Second VPS en passive hot-standby + réplication PostgreSQL streaming | L | Disponibilité 99,9 % |
| WP-5.4 | Bascule DNS automatisée (failover) | M | RTO < 5 min |
| WP-5.5 | Tests de restauration trimestriels documentés | S | Confiance |
| WP-5.6 | WAF (ModSecurity ou Cloudflare WAF) | S | Sécurité |
| WP-5.7 | Plan de continuité d'activité (PCA) formalisé | S | Conformité |

**Capabilities renforcées** : C-05 Exploitation, transverse.

---

### Plateau **P6 — Extensibilité & gouvernance données** (2028 S1 → S2)

> **Thème** : Préparer la montée en charge et la conformité RGPD avancée.

**Work packages**

| WP | Description | Effort | Bénéfice |
|----|-------------|:------:|----------|
| WP-6.1 | Tâches planifiées (Celery + Redis ou APScheduler) — envois newsletter, exports, relances | M | Industrialisation comm. |
| WP-6.2 | Extraction du service médiathèque en microservice (option) | L | Scalabilité ciblée |
| WP-6.3 | Extraction du service sondages en microservice (option) | L | Isolation pics |
| WP-6.4 | Politique de rétention RGPD (logs > 1 an → anonymisation) | S | Conformité |
| WP-6.5 | Outillage DPO (export données utilisateur, droit à l'oubli) | M | Conformité |
| WP-6.6 | API publique versionnée (`/api/v1/`, `/api/v2/`) | M | Interopérabilité |
| WP-6.7 | Marketplace de contenus avec autres universités OIF | L | Stratégie |

**Capabilities renforcées** : C-02, C-03, C-04.

---

## 6. Roadmap macro

```
2026 S2          2027 S1          2027 S2          2028 S1          2028 S2
────────────────────────────────────────────────────────────────────────────
P2 monitoring    │                                                         
                 │
P3 INDUSTRIALISATION ───────────────►
                                     │
                                     P4 OBSERVABILITÉ APPLICATIVE ─────────►
                                                                           │
                                                                           P5 RÉSILIENCE ──────►
                                                                                                │
                                                                                                P6 EXTENSIBILITÉ ─►
```

> Recouvrement contrôlé : chaque plateau peut chevaucher légèrement le suivant pour absorber les ajustements.

---

## 7. Indicateurs de pilotage (KPI / OKR)

| Axe | KPI | Cible 2028 |
|-----|-----|-----------|
| Disponibilité | Uptime mensuel | ≥ 99,9 % |
| Performance | P95 page d'accueil (LCP) | < 2,0 s |
| Performance | P95 API publique | < 250 ms |
| Sécurité | Vulnérabilités critiques ouvertes | 0 |
| Sécurité | Délai patch CVE high | < 7 jours |
| Qualité | Couverture tests backend | ≥ 70 % |
| Qualité | Couverture tests frontend | ≥ 60 % |
| Qualité | Régressions détectées en prod / trimestre | < 2 |
| Sauvegardes | Tests de restauration réussis | 100 % (4 / an) |
| Adoption | Candidatures soumises / an | +30 % vs 2025 |
| Engagement | Abonnés newsletter actifs | +50 % vs 2025 |
| Multilinguisme | Pages indexées par locale | ≥ 95 % de la cible |

---

## 8. Budget indicatif (3 ans)

> Estimations à raffiner avec la DSI ; OSS privilégié partout où possible.

| Poste | 2026 | 2027 | 2028 | Total 3 ans |
|-------|------|------|------|-------------|
| VPS principal (idem actuel) | 600 € | 600 € | 600 € | 1 800 € |
| VPS secondaire (P5) | — | — | 600 € | 600 € |
| CDN Cloudflare Pro (P5) | — | — | 240 € | 240 € |
| Stockage S3-compatible (P5) | — | 60 € | 120 € | 180 € |
| Backups off-site | 80 € | 80 € | 80 € | 240 € |
| DNS managé | 0 € | 0 € | 0 € | 0 € |
| SMTP transactionnel (volume) | 0 € | 100 € | 200 € | 300 € |
| Licences logicielles | 0 € | 0 € | 0 € | 0 € |
| **Total infrastructure** | **680 €** | **840 €** | **1 840 €** | **3 360 €** |
| Charge humaine (cadrage uniquement) | À cadrer | À cadrer | À cadrer | À cadrer |

Le poste dominant restera la **charge humaine** (développement, DevOps, urbanisme).

---

## 9. Gouvernance du schéma directeur

### Comité de pilotage SI

- **Sponsor** : Rectorat
- **Pilote** : DSI / Lead architecte
- **Membres** : Direction Communication, Direction Académique, RSSI
- **Cadence** : 1 fois / trimestre — revue de l'avancement des plateaus + arbitrage roadmap

### Comité technique d'architecture (CTA)

- **Pilote** : Lead architecte / urbaniste SI
- **Membres** : leads dev frontend, backend, DevOps
- **Cadence** : 1 fois / mois — instruction des ADR, revue des principes d'urbanisme

### Production des livrables d'urbanisme

| Livrable | Responsable | Fréquence de mise à jour |
|----------|-------------|--------------------------|
| DAT | Lead architecte | À chaque changement structurel |
| POS | Urbaniste SI | À chaque nouveau service SQL ou nouvelle zone |
| Vues ArchiMate | Urbaniste SI | Annuelle |
| Schéma directeur | Urbaniste SI + DSI | Annuelle (revue glissante) |
| ADR | CTA | À chaque décision majeure |
| Registre des risques | RSSI + Lead architecte | Trimestrielle |

---

## 10. Conditions de réussite

1. **Sponsorship explicite** du rectorat sur l'industrialisation (P3) — sinon dette technique stagnante.
2. **Charge humaine sanctuarisée** : au minimum 1 ETP dev + 0,3 ETP DevOps stables sur la période.
3. **Pas de gel de fonctionnalités** : la roadmap métier (Z1 à Z4) continue en parallèle, le schéma directeur sert le métier sans le bloquer.
4. **Documentation continue** : chaque plateau livre un addendum DAT + ADR.
5. **Tests de restauration trimestriels** : seul moyen de garantir que les sauvegardes sont réellement exploitables.

---

## 11. Risques de mise en œuvre

| Risque | Sévérité | Mitigation |
|--------|:--------:|------------|
| Dérive budgétaire P5 (HA) | Élevée | Étudier d'abord une simple sauvegarde géo-redondante avant la réplication chaude |
| Départ de l'architecte principal | Élevée | Documentation systémique (DAT, ADR, runbooks) ; pair programming |
| Décalage roadmap métier vs urbanisme | Moyenne | Comité de pilotage trimestriel arbitre |
| Microservices prématurés (P6) | Moyenne | Critères d'extraction explicites (trafic + équipe dédiée) avant d'extraire |
| Saturation cognitive (trop de plateaus en parallèle) | Moyenne | Limiter à 2 plateaus actifs simultanément |

---

## 12. Synthèse exécutive

| Quoi | Quand | Pourquoi |
|------|-------|----------|
| **P2** Monitoring système & conteneurs | En cours (2026 S2) | Voir l'état de la plateforme |
| **P3** Industrialisation (CI/CD, tests, backups auto) | 2026 S2 → 2027 S1 | Supprimer les opérations manuelles |
| **P4** Observabilité applicative + alerting | 2027 S1 → S2 | Mesurer, alerter, tenir SLO |
| **P5** Haute disponibilité + CDN + S3 + WAF | 2027 S2 → 2028 S1 | Supprimer le SPOF |
| **P6** Extensibilité + tâches planifiées + RGPD avancé | 2028 S1 → S2 | Préparer l'échelle et la conformité |

---

## 13. En quoi ce schéma directeur prouve la posture urbaniste

- **Vision long terme** alignée sur le métier.
- **Trajectoire jalonée en plateaus** (concept ArchiMate `Implementation & Migration`).
- **KPI mesurables** rattachés à chaque axe.
- **Gouvernance formalisée** (comité de pilotage + CTA).
- **Lucidité budgétaire** et **registre de risques** projet.
- **Continuité** avec les livrables d'urbanisme produits en amont (DAT, POS, ArchiMate, ADR).

> *« Au-delà du développement, j'ai formalisé pour Usenghor un schéma directeur SI 3 ans articulé en 4 plateaus successifs (industrialisation, observabilité, résilience, extensibilité), assorti d'un budget, de KPI et d'une gouvernance — apportant à la DSI une trajectoire d'urbanisation explicite. »*

---

*Fin du document.*
