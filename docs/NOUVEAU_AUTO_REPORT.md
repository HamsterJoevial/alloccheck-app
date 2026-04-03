# Rapport /nouveau_auto — AllocCheck
*Date : 2026-04-03*

## Idée
Tu sais enfin ce que la CAF te doit vraiment. En 3 minutes, tu vérifies tes droits et tu contestes si ça colle pas.
(IDEE-066, score 26/30, validée /ideeapp Session 11)

## Nom
AllocCheck

## Stack
- **Mobile** : Flutter 3.x (iOS + Android)
- **Web** : Next.js 16 (SSR, SEO)
- **Backend** : Supabase (Auth, PostgreSQL, Edge Functions)
- **Calcul** : Formules barèmes CAF 2026 en TypeScript (inspiré OpenFisca)
- **IA** : Claude API (génération courriers contestation)
- **Monétisation** : RevenueCat (mobile) + Stripe (web)

## Construction
- Milestones : 1/4 complétée (MVP simulation + résultats)
- Fichiers créés : ~100 (Flutter app + Supabase backend + Next.js scaffold)
- Tests : 1 test widget (home screen) — PASS

### Ce qui est construit
- App Flutter complète : home screen + formulaire 4 étapes + écran résultats
- Backend : schema DB (profiles, simulations, letters, subscriptions) avec RLS
- Edge Function `calculate-rights` : calcul RSA, APL, Prime activité, AF, AAH
- Edge Function `generate-letter` : génération courrier via Claude API
- Theme Material 3 personnalisé (bleu institutionnel + vert succès)
- Info.plist iOS avec ITSAppUsesNonExemptEncryption

### Ce qui reste
- Site web Next.js (pages SEO, simulateur web)
- Écran génération courrier (Flutter)
- Dashboard historique
- Intégration RevenueCat + Supabase Auth
- Génération PDF rapport

## Audits
Pas encore lancés — à faire via `/repriseprojet` ou manuellement.

## Quality Gate : REVIEW
Le MVP Flutter compile et les tests passent. Les fonctionnalités core (calcul + contestation) sont implémentées côté backend. Reste le wiring complet + web + monétisation.

## Actions manuelles : 25+
Voir docs/MANUAL_ACTIONS.md
