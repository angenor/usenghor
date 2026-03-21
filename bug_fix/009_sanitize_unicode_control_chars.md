# Bug 009 — Caractères cassés dans les titres sur mobile

## Problème

Les titres d'événements affichaient des `�` (blocs cassés) sur navigateurs mobiles, causés par des caractères de contrôle ASCII (`\x03` ETX) introduits par copier-coller depuis des sources externes.

## Correction

1. **Utilitaire frontend** (`app/utils/sanitizeText.ts`) : remplace les caractères de contrôle et espaces Unicode exotiques par des espaces normaux — auto-importé par Nuxt.
2. **Composables** (`usePublicEventsApi.ts`, `usePublicNewsApi.ts`) : nettoyage appliqué dans les fonctions `transform*ForDisplay`.
3. **Backend** (`schemas/content.py`) : validateur Pydantic `sanitize_unicode_spaces` sur les schémas Event et News (création + mise à jour).
4. **Migration SQL** (`026_sanitize_unicode_spaces.sql`) : nettoyage des données existantes — 4 événements corrigés en production.
