# SAVE — AllocCheck

> Checkpoint automatique du 2026-04-07

---

## Contexte de la session

Audit expert approfondi de TOUS les calculs du moteur de simulation. Résultat : 8 calculs sur 12 sont fondamentalement faux. Réécriture complète en cours, ordre d'impact.

---

## Ce qui a été fait ✅

- **APL réécrit** : formule officielle APL = L + C - PP - 5€, avec TF+TL, R0, P0=max(8.5%(L+C), 39.56), plafonds monoparentaux corrigés, seuil 0€ (pas 15€), charges par PAC
- **Bug TL corrigé** : RL en décimal (0-1) au lieu de pourcentage (0-100)
- **4 audits expert lancés et terminés** : RSA, Prime, AF/AAH, Famille (PAJE/CF/PreParE/ARS/CMG)
- **Audit APL expert** : déjà terminé et corrections appliquées
- **Pages légales créées** : politique confidentialité, mentions légales, CGU, consentement handicap, disclaimer N-2
- **Courrier multi-sélection** : checkboxes au lieu de radios, "Tout sélectionner"
- **Section "Aides non réclamées"** : proéminente dans résultats + teaser gratuit
- **MVA/ASF en suggestions** quand conditions presque remplies
- **Garde alternée** corrigée (divorcés/séparés), Step 4 complet (12 aides), validation pension
- **@JS exports conditionnels** : compilation mobile débloquée
- **Site FlowForges** : AllocCheck ajouté homepage + landing (non poussé)
- **Crédits Netlify épuisés** — plus de déploiement possible pour l'instant

## Ce qui est en cours ⏳

- **Réécriture moteur de calcul** — 8 calculs à corriger selon les rapports expert. Ordre : AAH → RSA → Prime → AF → CF/PreParE/PAJE → CMG

## Ce qui est bloqué 🔴

- **Déploiement Netlify** : crédits épuisés. Options : attendre renouvellement mensuel ou migrer vers GitHub Pages

## Prochaines étapes 🎯

1. **AAH** : implémenter abattement revenus d'activité 80%/40% (art. R821-4 CSS). Impact : -539€/mois d'erreur actuelle pour AAH + travail partiel
2. **RSA** : ajouter bonification 62% des revenus d'activité. Actuellement 100% déduit au lieu de 38%
3. **Prime d'activité** : ajouter forfait logement + majoration parent isolé + retirer déduction pension versée
4. **AF** : corriger plafonds (79 980 / 106 604€), montants 3+ enfants (349.06€), majoration 18+ (76.51€)
5. **CF** : corriger montants (198.16/297.27€) + vrais plafonds variables (couple 1rev/2rev/isolé × nb enfants)
6. **PreParE** : corriger montants (459.69/297.17€) + ajouter 3e taux (171.42€) + majorée (745.45€)
7. **PAJE** : corriger plafonds (vrais barèmes couple 1rev/2rev/isolé)
8. **CMG** : réécriture complète (réforme sept 2025 — calcul à l'heure, taux d'effort)
9. Résoudre hébergement (Netlify vs GitHub Pages)
10. Deploy final UNIQUE quand tout validé

## Notes importantes 📝

- **RÈGLE DEPLOY** : UN SEUL deploy par session, jamais prématuré. Tout vérifier localement d'abord.
- Rapports expert dans `docs/` : EXPERT_APL_AUDIT.md, EXPERT_RSA_AUDIT.md, EXPERT_PRIME_AUDIT.md, EXPERT_AF_AAH_AUDIT.md, EXPERT_FAMILLE_AUDIT.md
- Chaque rapport contient le code Dart de correction recommandé
- APL vérifié avec l'exemple officiel : seul Z2 0rev → 306.37€ (exact), AAH Z3 470€ → 288.15€ (exact)
- AAH avant revalorisation avril 2026 = 1 033.32€ (×1.008 = 1 041.59€)
- Apify INTERDIT (feedback mémorisé)
- FlowSocial pour réseaux sociaux (pas encore lancé)
- Site FlowForges : modifications locales non poussées

### Erreurs par calcul (résumé audits)
- **AAH** : abattement 80%/40% absent, distinction RSDAE 50-79% absente
- **RSA** : bonification 62% absente, 2 barèmes forfait logement, coefficient isolé 0.42804
- **Prime** : forfait logement absent, majoration isolé absente, pension versée déduite à tort
- **AF** : plafonds obsolètes (74650→79980), montants 3enf/supp/18+ légèrement faux
- **CF** : montants -25%, plafonds inventés (fixes vs variables)
- **PreParE** : montants faux, 3e taux absent, majorée absente
- **PAJE** : plafonds faux (ne correspondent à rien d'officiel)
- **CMG** : système entier obsolète (réforme sept 2025)
- **ARS** : CORRECT (seul calcul juste)
- **APL** : CORRIGÉ (formule TF+TL officielle)
- **MVA** : OK (mineur : condition complément pension)
- **ASF** : OK (mineur : taux orphelin total manquant)

---

## Fichiers modifiés lors de cette session

- `lib/core/services/calcul_local_service.dart` — APL réécrit (TF+TL+R0+P0), barèmes corrigés, MVA condition APL>0, suggestions MVA/ASF, disclaimer N-2
- `lib/features/letter/screens/letter_screen.dart` — multi-sélection courrier, web_download_bridge
- `lib/features/results/screens/results_screen.dart` — section aides non réclamées, teaser gratuit, web_download_bridge
- `lib/features/simulation/screens/simulation_screen.dart` — garde alternée, Step 4 complet, validation pension, consentement handicap, disclaimer N-2
- `lib/features/legal/screens/privacy_screen.dart` — NOUVEAU
- `lib/features/legal/screens/legal_mentions_screen.dart` — NOUVEAU
- `lib/features/legal/screens/terms_screen.dart` — NOUVEAU
- `lib/core/utils/web_download.dart` + stub + bridge — NOUVEAU
- `lib/core/utils/web_payment.dart` + stub + bridge — NOUVEAU
- `lib/main.dart` — routes légales + liens
- `docs/EXPERT_*.md` — 5 rapports d'audit expert
- `test/calcul_test.dart` — migration statutConjugal

---

*Checkpoint en cours de session — le travail continue. Pour reprendre plus tard : /repriseprojet*
