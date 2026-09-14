# Contrat — Clés éditoriales (025)

Catégorie `values`, préfixe `entrepreneurship.`, section de la page « Valeurs » : `entrepreneurship-see` (existante). Valeurs initiales : [data-model.md § 4](../data-model.md). Lecture : `page.text('see.…')` (`getRawContent`, trim, `''` si vide — jamais de clé brute).

## Clés existantes réutilisées

| Clé | Origine | Usage |
|---|---|---|
| `entrepreneurship.see.call_slug` | 045 | appel lu par la page |
| `entrepreneurship.contact.email` | 045 | contact e-mail (panneau, CTA) |
| `entrepreneurship.dde_service_id` | 045 | fil d'Ariane |
| `entrepreneurship.see.mentor.*` (3) | 045 | non utilisées ici (page alumni) |

## Clés ajoutées (65)

| Groupe | Clés | Nb | Bloc |
|---|---|---|---|
| Hero | `see.hero.{badge,title,subtitle,image}` | 4 | `PageHero` (badge + « · Appel {année} ») |
| Intro | `see.intro.{eyebrow,title,lead,body}` | 4 | colonne gauche |
| Définition | `see.what.{label,text}` | 2 | encadré sombre |
| Parcours | `see.tracks.{1,2}.{badge,title,text}` | 6 | cartes SEE 1 (bleu) / SEE 2 (rouge) |
| Leviers | `see.levers.{eyebrow,title}`, `see.levers.{1..6}.{icon,title,text}` | 20 | « Pourquoi postuler ? » |
| Candidature | `see.apply.{eyebrow,title,intro}` | 3 | « Suis-je le bon candidat ? » |
| Conditions | `see.conditions.title`, `see.conditions.{1,2,3}` | 4 | carte Conditions (secours si l'appel n'a pas de critères) |
| Jury | `see.jury.title`, `see.jury.{1..4}` | 5 | carte Critères du jury (toujours) |
| Dossier | `see.documents.title`, `see.documents.{1..4}` | 5 | carte Dossier (secours si l'appel n'a pas de pièces) |
| Agenda | `see.agenda.{button,cc_note}` | 2 | panneau agenda ; `cc_note` aussi dans le CTA final |
| Appel clos | `see.closed.{title,text}` | 2 | panneau agenda (états `closed`, `absent`, et texte complémentaire en `upcoming`) |
| FAQ | `see.faq.{eyebrow,title}` | 2 | section FAQ |
| PÉPITE | `see.pepite.{intro,label,url}` | 3 | ligne sous la FAQ |
| CTA final | `see.cta.{title,text,button}` | 3 | `EntrepreneurshipCtaBanner` |

Total : 65. Déclarées dans `editorial-pages-config.ts` (`editorialKeys` + `fields`, libellés « Levier 3 — titre »…) et `ValueSectionKey`. Contrôle : 138 clés `entrepreneurship.*` déclarées après la feature.

## Règles

- Emplacement de liste vide → omis ; liste entièrement vide → carte masquée (sauf conditions / pièces alimentées par l'appel).
- `see.levers.N.icon` : classe Font Awesome (`fa-solid fa-…`) ; invalide → `fa-solid fa-circle-check`.
- `see.hero.image` : identifiant média ; vide → mode motif.
- `see.pepite.url` : HTTP(S) seulement, sinon ligne masquée.
- Copie monolingue (FR affiché dans les trois langues, convention du site).
