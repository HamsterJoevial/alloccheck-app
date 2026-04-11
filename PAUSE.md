# SAVE — AllocCheck

> Checkpoint automatique du 2026-04-11

---

## Contexte de la session

Session de corrections barèmes (PreParE taux partiel + majorée) + UX dynamique Phase 3 (brouillon SharedPreferences, étapes conditionnelles, tooltips) + corrections sécurité partielles (SEC-001/004).

---

## Ce qui a été fait ✅

- **Phase 3 UX dynamique** : brouillon auto SharedPreferences (`sim_draft_v2`), banner reprendre/effacer, étapes conditionnelles (4→5 si enfants), 10 tooltips contextuel sur les champs
- **PreParE taux partiel (50-80%)** : ajout `CongeParental.tauxPartiel` (171.42€) dans enum + calcul + radio list UI
- **PreParE majorée** : 3+ enfants + cessation totale → 745.45€/mois (`_prepareMajoree`)
- **Tests** : 17/17 passent — P05 mis à jour (745.45€), P16 (PreParE majorée), P17 (tauxPartiel 171.42€)
- **SEC-004** : hint text `'Votre code (ex : AC2026UNLOCK)'` → `'Code reçu par email après paiement'`
- **SEC-001 partiel** : bouton "J'ai déjà un code d'accès" + méthodes `_showCodeDialog`/`_handleCodeUnlock` supprimés
- **SEC-003/006** : déjà OK dans `main.dart` (l.120 `clearSavedSituation()` après restauration)
- **Déployé** : alloccheck.flowforges.fr (GitHub Pages, commit 4fc2eaa)

## Ce qui est en cours ⏳

- Aucun

## Ce qui est bloqué 🔴

- **SEC-001/002 full fix** : impossible sans backend — token `AC2026UNLOCK` hardcodé dans `payment_service.dart:13`. Accessible par décompilation JS mais plus exposé dans l'UI. Nécessite Supabase Edge Function `validate-token` + Stripe Webhook.

## Prochaines étapes 🎯

1. **Backend sécurité** (session dédiée) : Supabase Edge Function `validate-token` + Stripe Webhook → remplacer le token hardcodé
2. **Audit** : `/qa-team` ou `/security-team` pour état global post-corrections
3. **Soumission App Store** : builds iOS/Android pas encore lancées

## Notes importantes 📝

- 17/17 tests — `flutter test test/profils_test.dart`
- 0 erreurs `flutter analyze` (warnings pré-existants uniquement)
- Token `AC2026UNLOCK` dans `lib/core/services/payment_service.dart:13` — ne plus exposer dans l'UI, fix complet = backend
- Barèmes avril 2026 : BMAF 478.16€, +0.8% — CF/PAJE/CMG/PreParE à jour
- ARS : barèmes août 2025 en vigueur jusqu'août 2026 (non revalorisée en avril)
- AEEH : 148.12€/mois/enfant, taux ≥ 50%, < 20 ans, non cumulable PAJE
- Deploy : `rsync build/web/ gh-pages/ --delete --exclude='.git'` puis `git push origin main:gh-pages`

---

## Fichiers modifiés lors de cette session

- `lib/core/models/situation.dart` — enum CongeParental + tauxPartiel
- `lib/core/services/calcul_local_service.dart` — `_calculerPreParE` + PreParE majorée
- `lib/features/simulation/screens/simulation_screen.dart` — Phase 3 UX + radio list congé parental
- `lib/features/results/screens/results_screen.dart` — SEC-004 hint text + SEC-001 suppression code dialog
- `test/profils_test.dart` — P05 mis à jour, P16 + P17 ajoutés

---

*Checkpoint en cours de session — le travail continue. Pour reprendre plus tard : /repriseprojet*
