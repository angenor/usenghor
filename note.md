kill $(lsof -i :8080 -t)

agent natif de claude code:
Explore


Si vous voulez voir les interactions en temps réel, ajoutez l'option --headed :
`agent-browser --headed` open http://localhost:3000/admin/organisation/secteurs

pour les besoins d'exploration tu peux utiliser intelligenmment plusieurs sous agent



j'espere que cela ne posera pas de probleme en production

- Images placeholder : `https://picsum.photos/{w}/{h}`, avatars : `https://i.pravatar.cc/{size}`



Sécuriser le store editorialContent pour le SSR

Ajouter isPageReady au composable useEditorialContent

Ajouter le chargement SSR dans pages/index.vue

Retirer loadContent des composants homepage (Hero, Mission, Formations, History, Partners)

Migrer les pages vers useAsyncData (11 pages)

Migrer AppNavBar vers useLazyAsyncData


La page projet et levée de fond sont presque les memes. La différance c'est 