# Contrat — Clés éditoriales de la page « Entrepreneuriat » (PEI)

Page front-office `entrepreneurship` (slug `/entrepreneuriat`) dans `usenghor_nuxt/app/composables/editorial-pages-config.ts` ; toutes les clés sont ajoutées au type `ValueSectionKey` (`app/types/api/editorial.ts`) et seedées par `045_entrepreneurship.sql` (`ON CONFLICT (key) DO NOTHING`, catégorie `values`). Une seule valeur par clé (FR) — `editorial_contents` n'est pas multilingue.

| Section (id) | Clé | Type | Valeur initiale (FR) |
|---|---|---|---|
| `entrepreneurship-hero` | `entrepreneurship.hero.badge` | text | Pôle Entrepreneuriat et Innovation |
| | `entrepreneurship.hero.title` | text | Entreprendre à Senghor |
| | `entrepreneurship.hero.slogan` | text | INNOVER. AGIR. TRANSFORMER. |
| | `entrepreneurship.hero.subtitle` | textarea | Le Pôle Entrepreneuriat et Innovation (PEI) accompagne les étudiants et alumni de l'Université Senghor, de l'idée à l'entreprise. |
| | `entrepreneurship.hero.cta1.text` | text | Devenir étudiant-entrepreneur |
| | `entrepreneurship.hero.cta2.text` | text | Découvrir le parcours |
| | `entrepreneurship.hero.slide1.image` | image | *(vide — UUID média à choisir)* |
| | `entrepreneurship.hero.slide2.image` | image | *(vide)* |
| | `entrepreneurship.hero.slide3.image` | image | *(vide)* |
| `entrepreneurship-presentation` | `entrepreneurship.presentation.badge` | text | Présentation du pôle |
| | `entrepreneurship.presentation.title` | text | Une université entrepreneuriale de référence |
| | `entrepreneurship.presentation.content` | html | Créé en 2022 au sein de la Direction du Développement et de l'Entrepreneuriat (DDE), le PEI favorise l'émergence, l'accompagnement et la réussite des initiatives portées par nos étudiants et alumni… (3 paragraphes du cahier des charges) |
| | `entrepreneurship.presentation.link` | text | Historique, vision et missions du pôle |
| `entrepreneurship-stats` | `entrepreneurship.stats.title` | text | Chiffres clés |
| | `entrepreneurship.stats.1.value` / `.label` | text / text | 3 / ans d'existence |
| | `entrepreneurship.stats.2.value` / `.label` | text / text | 3 / événements internationaux |
| | `entrepreneurship.stats.3.value` / `.label` | text / text | 12 / lauréats du FSE |
| | `entrepreneurship.stats.4.value` / `.label` | text / text | 500+ / étudiants et alumni formés |
| `entrepreneurship-activities` | `entrepreneurship.activities.badge` | text | Nos activités |
| | `entrepreneurship.activities.title` | text | Un parcours, de l'idée à l'entreprise |
| | `entrepreneurship.activities.subtitle` | textarea | Le PEI a structuré son intervention autour d'un parcours de croissance complet, conçu pour transformer une simple intuition en une entreprise viable et structurée. |
| | `entrepreneurship.activities.ecosystem.title` | text | Et toute l'année, l'animation de l'écosystème |
| | `entrepreneurship.activities.ecosystem.items` | list | Semaine Senghorienne de l'Entrepreneuriat (2SE)\nHackathons internationaux\nBootcamps\nAfterworks\nSéminaires et webinaires |
| | `entrepreneurship.activities.link` | text | Voir toutes nos activités |
| `entrepreneurship-quote` | `entrepreneurship.quote.text` | textarea | L'accompagnement du Pôle Entrepreneuriat ne s'arrête pas au chèque ou à une reconnaissance académique. C'est tout un écosystème : le mentorat, l'accès au réseau de l'Université et à des espaces de travail et de créativité privilégiés, qui nous ouvre les portes à des investisseurs internationaux. |
| | `entrepreneurship.quote.author` | text | Gaël Gbonsou |
| | `entrepreneurship.quote.role` | text | Directeur du Développement et de l'Entrepreneuriat |
| | `entrepreneurship.quote.image` | image | *(vide)* |
| | `entrepreneurship.impact.text` | textarea | L'impact est déjà tangible : 100 étudiants ont bénéficié d'un accompagnement personnalisé, menant à la distinction de 12 lauréats. Nos actions de sensibilisation ont touché plus de 500 étudiants et alumni, créant une dynamique de réseau durable. |
| | `entrepreneurship.impact.image` | image | *(vide)* |
| `entrepreneurship-cta` | `entrepreneurship.cta.title` | text | Prêt à passer à l'action ? |
| | `entrepreneurship.cta.description` | textarea | Ne laissez pas votre projet dormir dans un tiroir. Entreprendre et étudier à Senghor, c'est possible grâce au statut d'étudiant-entrepreneur. |
| | `entrepreneurship.cta.button` | text | Postuler au statut |
| | `entrepreneurship.contact.email` | text | entrepreneuriat@usenghor.org |
| `entrepreneurship-see` | `entrepreneurship.see.call_slug` | text | *(vide — slug de l'appel à candidatures SEE en cours)* |
| | `entrepreneurship.see.mentor.title` | text | Vous êtes alumni entrepreneur ? |
| | `entrepreneurship.see.mentor.description` | textarea | Rejoignez le réseau des mentors et accompagnez les nouvelles cohortes SEE 1 et SEE 2. |
| | `entrepreneurship.see.mentor.button` | text | Devenir mentor |
| `entrepreneurship-settings` | `entrepreneurship.dde_service_id` | text | UUID du service dont `name ILIKE '%Développement et de l''Entrepreneuriat%'`, sinon vide |

Total : 43 clés. Descriptions de champ (colonne `description` de `PageSectionField`) à rédiger en français dans la config ; `entrepreneurship.dde_service_id` porte la description « Identifiant du service DDE dans l'organigramme (Organisation → Services) ; utilisé par le tableau de bord du pôle et le futur mini-site ».
