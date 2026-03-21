# Feature Specification: Balises Open Graph pour le partage de liens

**Feature Branch**: `009-og-meta-tags`
**Created**: 2026-03-21
**Status**: Draft
**Input**: User description: "Lorsqu'on partage un lien il faut que les meta OG s'affichent, pour les liens qui n'ont pas d'images, utiliser Dieese_couleur.png par defaut, sinon utiliser l'image de l'article. Faire un rendu professionnel et intelligent."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Partage d'un lien sur les reseaux sociaux (Priority: P1)

Lorsqu'un utilisateur partage un lien du site de l'Universite Senghor sur un reseau social (Facebook, LinkedIn, Twitter/X, WhatsApp, Telegram, etc.), une carte de previsualisation riche s'affiche avec le titre de la page, une description pertinente, et une image representative.

**Why this priority**: C'est le coeur meme de la fonctionnalite. Sans cela, les liens partages apparaissent comme de simples URLs sans contexte visuel, ce qui reduit considerablement l'engagement et la credibilite institutionnelle.

**Independent Test**: Partager n'importe quel lien du site dans un outil de debug OG (ex: Facebook Sharing Debugger, Twitter Card Validator) et verifier que titre, description et image s'affichent correctement.

**Acceptance Scenarios**:

1. **Given** une page publique du site (accueil, a-propos, formations, etc.), **When** un utilisateur partage le lien sur un reseau social, **Then** une carte de previsualisation s'affiche avec le titre de la page, une description, et le logo Dieese comme image par defaut.
2. **Given** une page d'actualite ou d'evenement ayant une image associee, **When** un utilisateur partage le lien, **Then** la carte affiche l'image specifique de l'article au lieu du logo par defaut.
3. **Given** une page de projet ou de formation ayant une image, **When** un utilisateur partage le lien, **Then** l'image du contenu est utilisee dans la previsualisation.

---

### User Story 2 - Coherence multilingue des meta OG (Priority: P2)

Lorsqu'un utilisateur partage un lien dans une version linguistique specifique (francais, anglais, arabe), les metadonnees OG refletent la langue de la page partagee.

**Why this priority**: Le site est trilingue. Les metadonnees doivent correspondre a la langue dans laquelle l'utilisateur consulte la page pour eviter toute confusion.

**Independent Test**: Partager le meme contenu en version francaise, anglaise et arabe et verifier que le titre et la description correspondent a la langue active.

**Acceptance Scenarios**:

1. **Given** une page consultee en francais, **When** le lien est partage, **Then** le titre et la description OG sont en francais.
2. **Given** la meme page consultee en anglais, **When** le lien est partage, **Then** le titre et la description OG sont en anglais.
3. **Given** la meme page consultee en arabe, **When** le lien est partage, **Then** le titre et la description OG sont en arabe.

---

### User Story 3 - Optimisation Twitter/X Cards (Priority: P3)

En plus des balises OG standard, les balises specifiques Twitter Card sont presentes pour un affichage optimal sur Twitter/X.

**Why this priority**: Twitter/X utilise ses propres balises (`twitter:card`, `twitter:title`, etc.) en complement des OG. Cela garantit un rendu optimal sur toutes les plateformes majeures.

**Independent Test**: Valider le lien via le Twitter Card Validator et verifier l'affichage d'une "summary_large_image" card.

**Acceptance Scenarios**:

1. **Given** n'importe quelle page publique, **When** le lien est partage sur Twitter/X, **Then** une carte de type "summary_large_image" s'affiche avec titre, description et image.

---

### Edge Cases

- Que se passe-t-il si une page n'a aucune description renseignee ? → Utiliser une description institutionnelle par defaut ("Universite Senghor - Operateur direct de la Francophonie").
- Que se passe-t-il si l'image associee a un contenu n'est plus disponible ou invalide ? → Retomber sur le logo Dieese par defaut.
- Que se passe-t-il pour les pages admin ? → Aucune balise OG n'est necessaire pour les pages d'administration (non indexables).
- Que se passe-t-il si l'URL est partagee sans chemin de langue explicite ? → La version francaise (langue par defaut) est utilisee pour les meta.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le systeme DOIT inclure les balises `og:title`, `og:description`, `og:image`, `og:url`, `og:type`, et `og:site_name` sur toutes les pages publiques.
- **FR-002**: Le systeme DOIT utiliser l'image `Dieese_couleur.png` comme image OG par defaut pour toutes les pages sans image specifique.
- **FR-003**: Pour les contenus ayant une image associee (actualites, evenements, projets, formations, campus), le systeme DOIT utiliser cette image comme `og:image` a la place de l'image par defaut.
- **FR-004**: Le systeme DOIT inclure les balises Twitter Card (`twitter:card`, `twitter:title`, `twitter:description`, `twitter:image`) en coherence avec les balises OG.
- **FR-005**: Le `og:title` DOIT correspondre au titre de la page dans la langue courante.
- **FR-006**: Le `og:description` DOIT correspondre a la description du contenu dans la langue courante, ou a une description institutionnelle par defaut si aucune n'est disponible.
- **FR-007**: Le `og:image` DOIT pointer vers une URL absolue (incluant le domaine complet).
- **FR-008**: Le `og:image` DOIT respecter les dimensions recommandees (minimum 1200x630 pixels pour un rendu optimal).
- **FR-009**: Le systeme DOIT definir `og:locale` en fonction de la langue active (fr_FR, en_US, ar_SA) et declarer les locales alternatives via `og:locale:alternate`.
- **FR-010**: Les pages admin NE DOIVENT PAS contenir de balises OG (pages non destinees au partage public).

### Key Entities

- **Page publique**: Toute page accessible sans authentification (accueil, formations, actualites, projets, campus, a-propos, etc.) — chacune necessite des metadonnees OG.
- **Contenu avec image**: Actualite, evenement, projet, formation, campus — entites ayant potentiellement une image associee qui doit etre priorisee comme `og:image`.
- **Image par defaut**: Le fichier `Dieese_couleur.png` servant de fallback universel pour `og:image`.

## Assumptions

- Le domaine de production est connu et configurable (variable d'environnement ou configuration) pour generer les URLs absolues des images OG.
- L'image `Dieese_couleur.png` existe deja dans le dossier public et est de qualite suffisante pour servir d'image OG. Si ses dimensions sont inferieures a 1200x630px, une version optimisee pourra etre creee.
- Les pages publiques existantes utilisent deja des composables de meta (ex: `useSeoMeta` ou `useHead`) — la fonctionnalite OG s'integrera dans ce pattern existant.
- Le type OG par defaut est `website` pour les pages generiques et `article` pour les actualites/evenements.
- La description par defaut en francais est : "Universite Senghor - Operateur direct de la Francophonie a Alexandrie, Egypte".

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% des pages publiques affichent une carte de previsualisation complete (titre + description + image) lorsqu'un lien est partage sur Facebook, LinkedIn et Twitter/X.
- **SC-002**: Les pages de contenu avec image propre (actualites, evenements, projets) affichent leur image specifique dans 100% des cas lors du partage.
- **SC-003**: Les previsualisations de liens refletent correctement la langue de la page dans les trois versions linguistiques (FR, EN, AR).
- **SC-004**: Le temps de chargement des pages publiques n'est pas degrade de plus de 100ms par l'ajout des balises meta.
- **SC-005**: Aucune page admin n'expose de balises OG lors d'une inspection des meta-donnees.
