kill $(lsof -i :8080 -t)

agent natif de claude code:
Explore


test cette feature avec `agent-browser --headed`

`claude --dangerously-skip-permissions`

utilise plusieurs sous agents jusqu'à 10 s'il le faut pour comprendre ce projet et complete les element de reponse de ce DAT @docs/architechture_technique.md . Pour les shemats(representations), tu peux juste décrire et je vais générer avec app.diagrams.net
la liste des besoins fonctionnel n'est pas comprete, tu pourras les completer en fonction de ta comprehention

pour les besoins d'exploration tu peux utiliser intelligenmment plusieurs sous agent



j'espere que cela ne posera pas de probleme en production

- Images placeholder : `https://picsum.photos/{w}/{h}`, avatars : `https://i.pravatar.cc/{size}`



Sécuriser le store editorialContent pour le SSR

Ajouter isPageReady au composable useEditorialContent

Ajouter le chargement SSR dans pages/index.vue

Retirer loadContent des composants homepage (Hero, Mission, Formations, History, Partners)

Migrer les pages vers useAsyncData (11 pages)

Migrer AppNavBar vers useLazyAsyncData


La page levée de fond de l'université senghor. 
# La page principale de levée de fond contient des rubrique clés géririques qui concerne l'ensemble de toutes les campages jusqu'à présent: 
- hero section comme pour la page `/actualites`
- Votre contribution sert à(raison),
- Exemples d'engagement, 
- Bénéfice lié à votre contribution, 
- somme total jusqu'à prsent, 
- la liste de tous les contricuteurs des campagnes passées et en cours...
- la campage en cours mis en évidence + campagne passées plus discret ou dans un onglet
- onglet actualités
# Les pages de campagne(appel) contiennent les éléments suivants:
- presentation de la campagne
- raison de la levée de fond
- objectif chiffre cible, chiffre atteint actuellemt
- onglet contributeurs(ceux qui ont participé à la levée de fond + somme de leur comtribution)
- un bouton manifester son interret à contribuer à la levée de font(sera enregistrer dans la base de donnée + envera un email): Mettre en place un outil anti spam(vérificateur de navigateur par exemple).
- Une campage a les statuts suivants: En cours, cloturé
- Médiatheques


J'ai un problème avec @usenghor_nuxt/app/pages/admin/projets/liste/nouveau.vue et usenghor_nuxt/app/pages/admin/projets/liste/[id]/edit.vue . Je vois 'Afficher dans la section levée de fonds (page Stratégie)', non, ce n'est pas correcte, il faut plutot faire en sorte qu'on puisse associer un projet à ue levée de fond(facultatif) dans l'ongle associations, je pense qu'il s'agira de reutiliser la meme logique. Mais attentions, un projet peut avoir plusieurs levée de fond. Un peu faire une levée pendant un période données et une autre pendant une autre periode mais en gardant l'historique
