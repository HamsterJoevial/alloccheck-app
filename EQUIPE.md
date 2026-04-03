# Équipe — AllocCheck

## Orchestrateur

- **Nom** : orchestrateur-auto
- **Modèle** : Opus
- **Rôle** : Coordination du pipeline, décomposition en tâches, validation qualité, décisions d'architecture
- **Prompt** : `.claude/agents/orchestrateur.md`

## Agents spécialisés

### builder-front
- **Modèle** : Sonnet
- **Rôle** : Développement Flutter (app mobile) + Next.js (web app SEO)
- **Périmètre** : `alloccheck_app/`, `alloccheck_web/`
- **Prompt** : `.claude/agents/builder-front.md`

### builder-back
- **Modèle** : Sonnet
- **Rôle** : Backend Supabase, Edge Functions, intégration OpenFisca, génération PDF, Claude API
- **Périmètre** : `supabase/`, scripts de déploiement
- **Prompt** : `.claude/agents/builder-back.md`

### tester
- **Modèle** : Sonnet
- **Rôle** : Tests unitaires calculs droits, tests intégration Edge Functions, tests E2E parcours utilisateur
- **Périmètre** : `**/test/`, `**/tests/`, `**/*_test.dart`, `**/*.test.ts`
- **Prompt** : `.claude/agents/tester.md`

## Estimation coût
- Orchestrateur : usage intensif (Opus) — décisions + coordination
- Builders : 2 × Sonnet — développement parallèle
- Tester : 1 × Sonnet — tests en continu
- Total estimé : modéré à élevé (projet hybride web + mobile)
