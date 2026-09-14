# Contrat — Clés éditoriales de la page « Entrepreneuriat » (ajouts 023)

Complète [editorial-keys.md](../../021-pei-entrepreneurship-core/contracts/editorial-keys.md) (43 clés — l'en-tête de 045 fait foi). Page front-office `entrepreneurship`, `app/composables/editorial-pages-config.ts`, section **`entrepreneurship-activities`** ; union `ValueSectionKey` (`app/types/api/editorial.ts`) ; migration `047_pei_activities_hero_keys.sql` (catégorie `values`, `value_type = 'text'`, `ON CONFLICT (key) DO NOTHING`).

| Clé | Type admin | Valeur initiale (FR) | Description (config) |
|---|---|---|---|
| `entrepreneurship.activities.hero.badge` | text | Nos activités | Badge du hero de la page « Nos activités » |
| `entrepreneurship.activities.hero.title` | text | Un parcours, de l'idée à l'entreprise | Titre du hero de la page « Nos activités » |
| `entrepreneurship.activities.hero.subtitle` | textarea | Le PEI a structuré son intervention autour d'un parcours de croissance complet, conçu pour transformer une simple intuition en une entreprise viable et structurée. | Sous-titre du hero de la page « Nos activités » |
| `entrepreneurship.activities.hero.image` | image | *(vide)* | Image de fond du hero (médiathèque) ; vide = hero à motif |

Total après 023 : **47 clés**. Ajout dans `fields` de la section (mêmes conventions : `key` = `editorialKey`, `editable: true`, `defaultValue`).

## Lecture par les pages (clés existantes utilisées)

| Page | Clés lues | Usage |
|---|---|---|
| `/entrepreneuriat` | `hero.{badge,title,slogan,subtitle,cta1.text,cta2.text,slide1..3.image}` | hero : badge = `hero.badge` (seedé « Pôle Entrepreneuriat et Innovation », la maquette montre « Entreprendre à Senghor » — modifiable en backoffice), H1 = `hero.slogan`, boutons = `cta1` / `cta2` ; `hero.title` sert au `<title>` et au JSON-LD |
| | `presentation.{badge,title,content,link}` | section présentation (`content` via `getHtmlContent`) |
| | `stats.{title,1..4.value,1..4.label}` | panneau de chiffres |
| | `activities.{badge,title,subtitle,ecosystem.title,ecosystem.items,link}` | section parcours |
| | `quote.{text,author,role,image}`, `impact.{text,image}` | encadré citation |
| | `cta.{title,description,button}`, `contact.email` | appel à l'action |
| | `dde_service_id` | fil d'Ariane, actualités |
| `/entrepreneuriat/activites` | `activities.hero.{badge,title,subtitle,image}` | hero |
| | `activities.{ecosystem.title,ecosystem.items}` | bloc écosystème |
| | `dde_service_id` | fil d'Ariane, événements |

Toutes lues avec `getRawContent` (pas de repli i18n → pas de clé brute) ; blocs masqués si valeur vide (spec FR-023).
