# Contrat — Clés éditoriales « Entrepreneuriat » (024)

Page éditoriale `entrepreneurship` (Admin → Valeurs → Entrepreneuriat), catégorie `values`, une valeur FR par clé (convention monolingue, 023 Q1). Lecture via `useEditorialContent('entrepreneurship').getRawContent(key)` (jamais de clé brute affichée).

## Clés ajoutées (26, migration 048)

| Section (`id`) | Clé | Type de champ | Valeur initiale FR |
|---|---|---|---|
| `entrepreneurship-alumni` | `entrepreneurship.alumni.hero.badge` | text | Portraits et témoignages |
| | `entrepreneurship.alumni.hero.title` | text | Nos alumni et lauréats |
| | `entrepreneurship.alumni.hero.subtitle` | textarea | Ils sont passés de l'idée au projet, puis du projet à l'entreprise. Découvrez les lauréats du Fonds de Soutien à l'Entrepreneuriat et les étudiants-entrepreneurs de Senghor. |
| | `entrepreneurship.alumni.hero.image` | image | *(vide)* |
| | `entrepreneurship.alumni.stats.1.value` / `.label` | text / text | 15 / projets financés depuis 2023 |
| | `entrepreneurship.alumni.stats.2.value` / `.label` | text / text | 5 000 € / de subvention d'amorçage maximum |
| | `entrepreneurship.alumni.stats.3.value` / `.label` | text / text | 3 / cohortes, dont les alumni sont mentors |
| | `entrepreneurship.alumni.fse.badge` / `.title` | text / text | Lauréats FSE / Portraits de lauréats et témoignages |
| | `entrepreneurship.alumni.see.badge` / `.title` | text / text | Étudiants entrepreneurs / Portraits d'étudiants-entrepreneurs |
| `entrepreneurship-partners-page` | `entrepreneurship.partners.hero.{badge,title,subtitle,image}` | text / text / textarea / image | Nos partenaires / Un écosystème d'appui / Institutions académiques, organisations d'appui et organisations internationales : les partenaires qui accompagnent le Pôle Entrepreneuriat et Innovation. / *(vide)* |
| `entrepreneurship-resources` | `entrepreneurship.resources.hero.{badge,title,subtitle,image}` | idem | Nos ressources / Médiathèque et boîte à outils / Revivez les temps forts du pôle en images et retrouvez guides, formulaires et liens utiles pour structurer votre projet. / *(vide)* |
| `entrepreneurship-news` | `entrepreneurship.news.hero.{badge,title,subtitle,image}` | idem | Actualités / La vie du pôle / Actualités, événements et temps forts du Pôle Entrepreneuriat et Innovation. / *(vide)* |

En base, `value_type = 'text'` pour toutes (comme 047) ; le type de champ (`textarea`, `image`) est porté par la configuration frontend.

## Clés existantes réutilisées

| Clé | Page | Usage |
|---|---|---|
| `entrepreneurship.dde_service_id` | toutes | fil d'Ariane (lien DDE), albums (ressources), filtre actualités / événements |
| `entrepreneurship.contact.email` | alumni | destinataire du bouton « Devenir mentor » (`mailto:`) |
| `entrepreneurship.see.mentor.title` / `.description` / `.button` | alumni | encart « Devenir mentor » |
| `entrepreneurship.hero.title` | toutes | nom du pôle dans le JSON-LD `Organization` |

## Clés lues par page

- **alumni** : `alumni.hero.*`, `alumni.stats.*`, `alumni.fse.*`, `alumni.see.*`, `see.mentor.*`, `contact.email`, `dde_service_id`, `hero.title`.
- **partenaires** : `partners.hero.*`, `dde_service_id`, `hero.title`.
- **ressources** : `resources.hero.*`, `dde_service_id`, `hero.title`.
- **actualités** : `news.hero.*`, `dde_service_id`, `hero.title`.

Repli quand une clé est vide : titre du hero → `t('pei.seo.<page>Title')` ; badge / sous-titre / image → omis ; chiffres / titres de section → bloc masqué.
