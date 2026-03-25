# Data Model: 014-link-shortener

**Date**: 2026-03-25

## Entités

### short_links

Association entre un code court unique et une URL de destination.

| Champ | Type | Contraintes | Description |
|-------|------|-------------|-------------|
| id | UUID | PK, default uuid_generate_v4() | Identifiant unique |
| code | VARCHAR(4) | UNIQUE, NOT NULL | Code court en base 36 (1-4 caractères, [0-9a-z]) |
| target_url | VARCHAR(2000) | NOT NULL | URL de destination (interne ou domaine autorisé) |
| created_by | UUID | FK → users(id), NULL ON DELETE SET NULL | Administrateur ayant créé le lien |
| created_at | TIMESTAMPTZ | DEFAULT NOW() | Date de création |
| updated_at | TIMESTAMPTZ | DEFAULT NOW() | Date de dernière modification |

**Index** : `idx_short_links_code` sur `code` (lookup par code pour la redirection).

**Séquence** : `short_link_counter_seq` (START 0, INCREMENT 1, MINVALUE 0, MAXVALUE 1679615) — compteur pour la génération séquentielle en base 36.

### allowed_domains

Liste blanche de domaines externes autorisés pour les URLs de destination.

| Champ | Type | Contraintes | Description |
|-------|------|-------------|-------------|
| id | UUID | PK, default uuid_generate_v4() | Identifiant unique |
| domain | VARCHAR(255) | UNIQUE, NOT NULL | Nom de domaine (ex. `google.com`) |
| created_at | TIMESTAMPTZ | DEFAULT NOW() | Date d'ajout |

## Relations

```
users (1) ──── (0..N) short_links     [created_by]
```

Pas de relation entre `short_links` et `allowed_domains` (la validation se fait à la création uniquement).

## Règles de validation

- `code` : exactement la conversion base 36 de la valeur courante de `short_link_counter_seq`. Généré automatiquement, jamais saisi manuellement.
- `target_url` : doit être soit un chemin relatif commençant par `/`, soit une URL absolue dont le domaine figure dans `allowed_domains`.
- Un `target_url` ne doit pas commencer par `/r/` (anti-boucle).
- Plusieurs `short_links` peuvent avoir le même `target_url`.

## Cycle de vie

1. **Création** : `nextval('short_link_counter_seq')` → conversion base 36 → insertion du lien.
2. **Lecture** : lookup par `code` (redirection publique) ou listing paginé (admin).
3. **Suppression** : `DELETE` physique. Le compteur séquentiel ne recule pas.
4. Pas de mise à jour (hors scope).

## Volumétrie

- Capacité maximale : 1 679 616 liens (36^4).
- Usage estimé : quelques centaines de liens sur les premières années.
- La table `allowed_domains` contiendra typiquement < 50 entrées.
