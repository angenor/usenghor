# Research: Ajouter le type de formation CLOM

**Feature**: 011-add-cloms-formation
**Date**: 2026-03-24

## R1 : Migration ENUM PostgreSQL

**Decision** : Utiliser `ALTER TYPE program_type ADD VALUE 'clom'` dans une migration dédiée.

**Rationale** : PostgreSQL supporte nativement l'ajout de valeurs à un type ENUM existant via `ALTER TYPE ... ADD VALUE`. Cette opération est non-destructive, sans downtime, et ne nécessite pas de recréer la table. La valeur est ajoutée en fin d'ENUM par défaut.

**Alternatives considérées** :
- Recréer l'ENUM complet (DROP + CREATE + ALTER TABLE) — trop risqué, nécessite un verrou exclusif sur la table `programs`
- Utiliser une colonne VARCHAR au lieu d'ENUM — changerait l'architecture existante sans raison

**Note** : `ALTER TYPE ... ADD VALUE` ne peut pas être exécuté dans un bloc de transaction explicite (pas de `BEGIN/COMMIT`). La migration doit être exécutée directement.

## R2 : Valeur interne de l'ENUM

**Decision** : La valeur interne est `clom` (singulier, minuscule), cohérent avec les valeurs existantes (`master`, `doctorate`, `university_diploma`, `certificate`).

**Rationale** : Suit la convention de nommage établie. Le terme « CLOM » est l'acronyme francophone de « Cours en Ligne Ouvert et Massif », équivalent du MOOC anglophone. L'Université Senghor étant francophone, le terme français est approprié comme identifiant interne.

**Alternatives considérées** :
- `mooc` — terme anglophone, incohérent avec le contexte francophone du projet
- `clom_mooc` — redondant, viole la convention de nommage simple

## R3 : Slug URL public

**Decision** : Le slug URL est `cloms` (pluriel), mappé vers `/formations/cloms`.

**Rationale** : Cohérent avec les slugs existants qui utilisent des noms français au pluriel ou des formes descriptives : `masters`, `doctorat`, `diplomes-universitaires`, `certifiantes`.

**Alternatives considérées** :
- `moocs` — terme anglophone, incohérent avec les autres slugs francophones
- `cours-en-ligne` — trop long, ne correspond pas au pattern des autres slugs

## R4 : Identité visuelle (couleur et icône)

**Decision** : Couleur teal/cyan, icône `fa-solid fa-globe`.

**Rationale** : Les couleurs existantes sont : indigo (master), purple (doctorat), emerald (DU), amber (certificat). Le teal/cyan est la couleur disponible la plus distincte visuellement. L'icône globe représente le caractère « ouvert » et « en ligne » des CLOMs.

**Alternatives considérées** :
- `fa-solid fa-wifi` — trop technique, moins universellement compris
- `fa-solid fa-laptop` — pourrait évoquer l'informatique plutôt que l'enseignement en ligne
- Couleur rose/pink — moins associée à l'éducation numérique

## R5 : Traductions trilingues

**Decision** :
- **Français** : « CLOM » (singulier), « CLOMs » (pluriel), description « Cours en Ligne Ouvert et Massif »
- **Anglais** : « MOOC » (singulier), « MOOCs » (pluriel), description « Massive Open Online Course »
- **Arabe** : « مقرر مفتوح عبر الإنترنت » (singulier), « مقررات مفتوحة عبر الإنترنت » (pluriel)

**Rationale** : Utilise les termes académiques standards dans chaque langue. Le terme arabe suit les conventions des universités francophones du Maghreb et du Moyen-Orient.

**Alternatives considérées** :
- Utiliser « MOOC » en français aussi — le projet favorise le français, « CLOM » est le terme officiel francophone
- Translittération « كلوم » en arabe — moins compréhensible que la traduction descriptive
