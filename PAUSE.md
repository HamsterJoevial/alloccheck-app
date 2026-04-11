# SAVE — AllocCheck

> Checkpoint automatique du 2026-04-11

---

## Contexte de la session

Session de restructuration complète du moteur de simulation AllocCheck : suppression MTP, correction barèmes ARS, correction plafonds ARS, implémentation AEEH (Phase 2).

---

## Ce qui a été fait ✅

- **Suppression MTP** : retirée de 6 fichiers — supprimée pour nouveaux bénéficiaires AAH depuis déc. 2019
- **Correction SMIC** : seuil abattement AAH corrigé à 546.91€ (était 546.20€)
- **Correction barèmes ARS** : 403.72€/424.95€/440.65€ (barèmes août 2025 — ARS non revalorisée en avril)
- **Correction plafonds ARS** : différenciés isolé (25 338€) / couple (32 271€) + 5 841€/enfant supplémentaire
- **Phase 1 complète** : StatutConjugal (7 options), SituationVie, MVA (104.77€), ASF (200.78€/enfant), ALS/ALF, pension alimentaire versée/non percue, logementConventionne
- **Phase 2 — AEEH** : 148.12€/mois/enfant, taux ≥ 50%, < 20 ans, non cumulable PAJE, UI per-child dans formulaire
- **Tests** : 15/15 passent — P13 (1 enfant 70%), P14 (2 ans 60% → AEEH > PAJE), P15 (2 enfants dont 1 handicapé)
- **Déployé** : alloccheck.flowforges.fr (GitHub Pages, commit a559dd6)

## Ce qui est en cours ⏳

- Aucun

## Ce qui est bloqué 🔴

- Aucun

## Prochaines étapes 🎯

1. **Rapport PDF** : ajouter AEEH dans le tableau PDF (`results_screen.dart _generateRapportPdf`)
2. **Lettre de contestation** : ajouter références légales AEEH dans `letter_screen.dart`
3. **Phase 3 — UX dynamique** (session dédiée) : formulaire adaptatif, tooltips, brouillon SharedPreferences
4. **AEEH compléments MDPH** (si demandé) : catégories 1-6, actuellement seul le montant de base calculé

## Notes importantes 📝

- Barèmes avril 2026 : Décrets 2026-220 à 229, BMAF 478.16€, +0.8%
- ARS revalorisée en AOÛT uniquement — barèmes août 2025 en vigueur jusqu'août 2026
- AEEH : montant de base 148.12€ uniquement (compléments MDPH hors périmètre)
- PAJE non cumulable AEEH : règle art. L531-2 CSS al. 3
- MTP définitivement supprimée — PCH (MDPH) est le dispositif applicable
- Deploy : rsync build/web/ vers /tmp/gh-pages-deploy/ puis push

---

## Fichiers modifiés lors de cette session

- `lib/core/models/situation.dart`
- `lib/core/models/droits_result.dart`
- `lib/core/theme/app_theme.dart`
- `lib/core/services/calcul_local_service.dart`
- `lib/features/results/screens/results_screen.dart`
- `lib/features/simulation/screens/simulation_screen.dart`
- `test/profils_test.dart`

---

*Checkpoint en cours de session — le travail continue. Pour reprendre plus tard : /repriseprojet*
