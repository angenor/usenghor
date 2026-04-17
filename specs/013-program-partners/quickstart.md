# Quickstart: 013-program-partners

**Date**: 2026-03-25

## Prérequis

- Docker (PostgreSQL local via `docker-compose`)
- Node.js + pnpm (frontend)
- Python 3.14 + venv (backend)

## Setup

```bash
# Backend
cd usenghor_backend
docker compose up -d
source .venv/bin/activate
uvicorn app.main:app --reload  # http://localhost:8000

# Frontend
cd usenghor_nuxt
pnpm install
pnpm dev  # http://localhost:3000
```

## Vérification de l'infrastructure existante

```bash
# Vérifier que la table program_partners existe
docker exec -i usenghor_postgres psql -U usenghor -d usenghor -c "\d program_partners"

# Vérifier les endpoints admin existants
curl -s http://localhost:8000/api/docs | grep partners
```

## Test de la feature

### Admin (après implémentation)
1. Se connecter à l'admin : http://localhost:3000/admin
2. Naviguer vers Formations > Programmes
3. Éditer une formation existante
4. Scroller vers la section "Partenaires"
5. Rechercher et ajouter un partenaire
6. Sauvegarder et vérifier la persistance

### Public (après implémentation)
1. Ouvrir la page publique d'une formation avec partenaires
2. Vérifier l'affichage des logos et noms sous le contenu
3. Cliquer sur un partenaire pour vérifier la redirection

### API (après implémentation)
```bash
# Endpoint public
curl http://localhost:8000/api/public/programs/{slug}/partners
```

## Fichiers clés à modifier

| Fichier | Modification |
|---------|-------------|
| `usenghor_backend/app/schemas/academic.py` | Ajouter `ProgramPartnerPublic` |
| `usenghor_backend/app/routers/public/programs.py` | Ajouter endpoint `/{slug}/partners` |
| `usenghor_backend/app/services/academic_service.py` | Ajouter méthode enrichie |
| `usenghor_nuxt/app/composables/useProgramsApi.ts` | Ajouter méthodes partner |
| `usenghor_nuxt/app/composables/usePublicProgramsApi.ts` | Ajouter `getProgramPartners` |
| `usenghor_nuxt/app/pages/admin/formations/programmes/[id]/edit.vue` | Section partenaires |
| `usenghor_nuxt/app/pages/admin/formations/programmes/nouveau.vue` | Section partenaires |
| `usenghor_nuxt/app/pages/formations/[type]/[slug].vue` | Affichage partenaires |
| `usenghor_nuxt/app/components/formations/ProgramPartners.vue` | Nouveau composant public |
