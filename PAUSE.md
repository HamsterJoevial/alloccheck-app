# SAVE — AllocCheck

> Checkpoint automatique du 2026-04-11

---

## Contexte de la session

Session de corrections QA — implémentation de 20 issues P0/P1/P2 identifiées lors de l'audit du 2026-04-11. Deux batches de commits (QA-013/014/017 puis QA-010/012/019/020/021) après le premier batch (88ca1f7).

---

## Ce qui a été fait ✅

- QA-003 à QA-022 : toutes les issues P1/P2 corrigées (sauf QA-001/002 P0 backend)
- QA-010 : 13 tests PaymentService — 39/39 au total
- QA-012 : 23 accents restaurés dans le PDF
- QA-013 : suppression calcul_service.dart + 5 constantes mortes
- QA-014 : ARS affichée en annuel (€/an août)
- QA-017 : RadioGroup ancêtre — suppression deprecated groupValue/onChanged
- QA-019 : _initScreen atomique — plus de flash écran blanc
- QA-020 : bouton "Modifier" dans l'AppBar de ResultsScreen
- QA-021 : webSaveSituationAndNavigate retourne bool + snackbar localStorage plein

## Ce qui est en cours ⏳

- docs/QA_BACKLOG.md modifié localement (non commité)

## Ce qui est bloqué 🔴

- QA-001 + QA-002 (P0) : token hardcodé + paywall client-side — session dédiée backend requise

## Prochaines étapes 🎯

1. git add docs/QA_BACKLOG.md && git commit -m "docs: QA_BACKLOG mis à jour session 2"
2. flutter build web --release puis deploy.sh
3. Session dédiée QA-001/002 : Supabase Edge Function verify-payment + Stripe Webhook

## Notes importantes 📝

- 39 tests passent, 0 erreurs flutter analyze
- Token AC2026UNLOCK dans payment_service.dart:13 — ne pas supprimer sans backend
- Stripe Payment Link : https://buy.stripe.com/3cI4gycrcbDx0CL6IY7EQ01

---

## Fichiers modifiés lors de cette session

- alloccheck_app/lib/features/results/screens/results_screen.dart
- alloccheck_app/lib/features/simulation/screens/simulation_screen.dart
- alloccheck_app/lib/features/letter/screens/letter_screen.dart
- alloccheck_app/lib/core/services/calcul_local_service.dart
- alloccheck_app/lib/core/services/payment_service.dart
- alloccheck_app/lib/core/utils/web_payment.dart + web_payment_stub.dart
- alloccheck_app/lib/core/models/situation.dart
- alloccheck_app/lib/main.dart
- alloccheck_app/lib/core/theme/app_theme.dart
- alloccheck_app/pubspec.yaml
- alloccheck_app/test/payment_service_test.dart (nouveau)
- docs/QA_BACKLOG.md

---

*Pour reprendre : /repriseprojet*
