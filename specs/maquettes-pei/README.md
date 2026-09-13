# Maquettes — Pôle Entrepreneuriat et Innovation (PEI)

Maquettes de référence du mini-site « Entreprendre à Senghor », utilisées par les prompts de
`specs/roadmap-pei-entrepreneuriat.md`. Version éditable en ligne (canvas) :
https://claude.ai/code/artifact/43435b8e-2b26-4512-9a0e-37da522d8611

| Planche | Rendu (1440 px) | Source HTML | Utilisée par |
|---------|-----------------|-------------|--------------|
| Arborescence et données | `arborescence.png` | `arborescence.html` | 021, 026 (structure, tables, rattachement) |
| Accueil du pôle (Présentation) | `accueil.png` | `accueil.html` | 023 (hero slider, sous-navigation, présentation, parcours, encadré, actualités, partenaires, CTA) |
| Entreprendre et étudier (SEE) | `statut-etudiant-entrepreneur.png` | `statut-etudiant-entrepreneur.html` | 025 |
| Nos alumni (Lauréats FSE) | `alumni.png` | `alumni.html` | 024 (portraits, cohortes, bandeau de chiffres) |

## Comment lire ces fichiers

- Les **PNG** sont des captures pleine page : elles fixent la hiérarchie des sections, leur ordre et
  leur densité. C'est la référence visuelle.
- Les **HTML** sont des maquettes statiques autonomes (ouvrables dans un navigateur, images à côté).
  Ils donnent les valeurs exactes utilisées : couleurs (`#2b4bbf` brand-blue-500, `#f32525`
  brand-red-500, `#0e1840` brand-blue-900…), tailles de police, rayons, espacements. Ce ne sont **pas**
  des composants à copier : le site les implémente en Vue + Tailwind avec les composants existants
  (`PageHero`, layout par défaut, `RichTextRenderer`, `SectionStats`, cartes de `OrganizationOrganigrammeSection`…).
- Les éléments entre crochets (`[Nom du lauréat]`, `[date]`) et les zones hachurées « Photo : … » sont
  des emplacements à remplir par le backoffice, pas du contenu à reproduire.
- Les trois actualités de l'accueil sont des exemples tirés du cahier des charges ; en production la
  section lit les actualités liées à la DDE.
- Les textes proviennent du cahier des charges (`Communication - cahier de charges Page EI.pdf`) ; ils
  sont seedés dans les clés éditoriales et les tables du pôle, jamais codés en dur dans les pages.

## Écarts assumés entre maquette et implémentation

- Le hero et le pied de page sont dessinés pour donner le rendu d'ensemble ; l'implémentation réutilise
  `PageHero` (étendu avec une prop `images[]` pour le slider) et `AppFooter` via le layout par défaut.
- Les icônes de la maquette sont des SVG inline ; le site utilise Font Awesome.
- Le mode sombre n'est pas dessiné ; appliquer les classes `dark:` du site comme sur les pages voisines.
- La version mobile (390 px) n'est pas dessinée ; les sections passent en une colonne, la
  sous-navigation devient défilante horizontalement (comme `SectionAboutTabsNav`).
