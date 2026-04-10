import '../models/situation.dart';
import '../models/droits_result.dart';

// Moteur de calcul des droits CAF — 100% local, zéro réseau
// BARÈMES AU 1ER AVRIL 2026
// Sources :
//   - Décrets n° 2026-220 à 2026-229 du 30 mars 2026 (JO 31/03/2026)
//   - Instruction DSS/2B/2026/46 du 20 mars 2026
//   - Service-Public.fr (actualité du 01/04/2026)
//   - Taux de revalorisation : +0,8%

class CalculLocalService {

  // ============================================================
  // BARÈMES AVRIL 2026 — SOURCES OFFICIELLES
  // ============================================================

  // --- RSA (Décret n° 2026-220, art. L262-2 CASF) ---
  static const double _rsaBase = 651.69; // personne seule sans enfant
  // Majorations : couple = +50%, enfant 1-2 = +30%, enfant 3+ = +40%
  static const double _rsaMajorationCouple = 0.5;
  static const double _rsaMajorationEnfant12 = 0.3;
  static const double _rsaMajorationEnfant3Plus = 0.4;
  // Parent isolé — RSA majoré (art. L262-9 CASF)
  // = 128.412% du montant de base, +42.86% par enfant
  static const double _rsaMajorationIsolementBase = 1.28412; // multiplicateur (pas addition)
  static const double _rsaMajorationIsolementParEnfant = 0.42804; // par enfant (art. R262-4 CASF)
  // Forfait logement (déduit si hébergé ou APL)
  static const double _rsaForfaitLogement1 = 77.58; // 1 personne
  static const double _rsaForfaitLogement2 = 155.16; // 2 personnes
  static const double _rsaForfaitLogement3Plus = 192.02; // 3+ personnes

  // --- PRIME D'ACTIVITÉ (Décret n° 2026-222, art. L841-3 CSS) ---
  static const double _primeBase = 638.28; // montant forfaitaire personne seule
  static const double _primeBonificationMax = 240.63; // bonification individuelle max
  static const double _primeSeuilBonifMin = 709.18; // seuil revenus bonification min
  static const double _primeSeuilBonifMax = 1658.76; // seuil revenus bonification max
  static const double _primeMajorationCouple = 0.5;
  static const double _primeMajorationEnfant12 = 0.3;
  static const double _primeMajorationEnfant3Plus = 0.4;

  // --- APL (art. L841-1 CCH, arrêté 27/09/2019, barèmes 01/10/2025) ---
  //
  // Formule officielle : APL = L + C - PP - 5€
  // PP = P0 + Tp × (R - R0)
  // Tp = TF + TL
  //
  // Loyers plafonds par zone : seul / couple / 1 PAC / supplément par PAC
  // Source : arrêté du 5 septembre 2025
  static const Map<String, List<double>> _aplPlafonds = {
    //           [seul,   couple, 1pac,   supp/pac]
    'zone_1': [333.14, 401.78, 454.10, 65.89],
    'zone_2': [290.34, 355.38, 399.89, 58.21],
    'zone_3': [272.12, 329.88, 369.88, 53.01],
  };

  // Forfait charges : 60.59€ base + 13.74€ par personne à charge
  // Source : arrêté 5 sept 2025 (revalorisation +1.04% IRL)
  static const double _aplChargesBase = 60.59;
  static const double _aplChargesParPac = 13.74;

  // P0 plancher = 39.56€ — mais P0 réel = max(8.5% × (L+C), 39.56)
  // Source : art. D.823-17 CCH, art. 13 arrêté 27/09/2019
  static const double _aplP0Plancher = 39.56;
  static const double _aplP0Taux = 0.085; // 8.5%

  // Déduction forfaitaire de 5€ (depuis oct. 2017, art. D.823-16 al.9 CCH)
  static const double _aplDeduction = 5.0;

  // TF — taux famille (fixe, non revalorisé — art. 14 arrêté 27/09/2019)
  // Source : brochure ministérielle "Éléments de calcul" p.18 Tableau 6
  static const List<double> _aplTF = [
    0.0283,  // personne seule (0 pac)
    0.0315,  // couple (0 pac)
    0.0270,  // 1 pac
    0.0238,  // 2 pac
    0.0201,  // 3 pac
    0.0185,  // 4 pac
    0.0179,  // 5 pac
    0.0173,  // 6 pac
  ];
  static const double _aplTFParPacSupp = -0.0006; // au-delà de 6 pac

  // TL — taux loyer (progressif, basé sur RL = L / LR)
  // LR = loyer plafond Zone II pour la même composition
  // Source : art. 14 arrêté 27/09/2019
  // Si RL < 45% : TL = 0
  // Si 45% ≤ RL < 75% : TL = 0.45% × (RL - 45%)
  // Si RL ≥ 75% : TL = 0.45% × 30% + 0.68% × (RL - 75%)

  // R0 — seuil de ressources par taille du foyer
  // Source : décret 2025-1401, arrêté 30/12/2024 (non revalorisé 2026)
  static const Map<int, double> _aplR0 = {
    1: 5235, 2: 7501, 3: 8947, 4: 9148,
    5: 9498, 6: 9851, 7: 10202, 8: 10554,
  };
  static const double _aplR0ParPersonneSupp = 346.0;

  // --- ALLOCATIONS FAMILIALES (Instruction DSS/2B/2026/46, art. L512-1 CSS) ---
  // BMAF = 478.16€
  static const double _afBase2Enfants = 153.01; // 32% BMAF (art. D521-1 CSS)
  static const double _afBase3Enfants = 349.06; // 73% BMAF
  static const double _afSupplementParEnfant = 196.04; // 41% BMAF
  // Majoration âge = 18+ ans depuis 01/03/2026 — 16% BMAF
  static const double _afMajoration18Plus = 76.51;
  // Plafonds 2026 (revenus N-2) — source aide-sociale.fr, art. D521-1 CSS
  static const double _afPlafondBase1 = 79980; // tranche 1 (2 enfants)
  static const double _afPlafondBase2 = 106604; // tranche 2 (2 enfants)
  static const double _afMajorationPlafondParEnfant = 6664; // par enfant au-delà de 2

  // --- AAH (Décret n° 2026-229, art. L821-1 CSS) ---
  static const double _aahMontantMax = 1041.59;
  // DÉCONJUGALISATION depuis octobre 2023 : seules les ressources
  // du demandeur sont prises en compte (pas celles du conjoint)
  static const double _aahPlafondSeul = 12400.0; // annuel
  static const double _aahPlafondCouple = 18600.0; // annuel (mais déconjugalisé)
  static const double _aahMajorationEnfant = 6200.0; // annuel par enfant

  // ============================================================
  // SOURCES LÉGALES (intégrées dans les détails pour les courriers)
  // ============================================================

  // --- CMG (Complément Mode de Garde — CAF.fr, barèmes 2026) ---
  // Tranches de revenus annuels du foyer
  static const double _cmgSeuil1 = 27017.0;
  static const double _cmgSeuil2 = 47648.0;
  // Montants par mode de garde et par tranche
  static const Map<String, List<double>> _cmgMontants = {
    'assistante_maternelle': [923.0, 461.0, 230.50],
    'creche':                [923.0, 461.0, 230.50],
    'garde_domicile':        [1846.0, 923.0, 461.0],
  };

  // --- PAJE base (art. L531-2 CSS, arrêté 18/12/2025, barèmes avril 2026) ---
  static const double _pajeTauxPlein = 198.16;
  static const double _pajeTauxPartiel = 99.09;
  // Plafonds taux plein — couple 1 revenu (conjoint < 6 306€/an N-2)
  static const double _pajePlafondPlein1Rev1Enf = 31066;
  static const double _pajePlafondPleinParEnfSupp = 6213;
  // Plafonds taux plein — couple 2 revenus / parent isolé
  static const double _pajePlafondPlein2Rev1Enf = 41055;
  // Plafonds taux partiel — couple 1 revenu
  static const double _pajePlafondPartiel1Rev1Enf = 37118;
  // Plafonds taux partiel — couple 2 revenus / parent isolé
  static const double _pajePlafondPartiel2Rev1Enf = 49054;
  // Seuil "2 revenus" : conjoint doit avoir revenu ≥ 6 306€/an
  static const double _pajeSeuilDeuxRevenus = 6306;

  // --- Complément Familial (CAF.fr, barèmes 2026) ---
  // CF — montants avril 2026 (source aide-sociale.fr, EXPERT_FAMILLE_AUDIT)
  static const double _cfMontantMajore = 297.27;  // revenus ≤ seuil majoré
  static const double _cfMontantNormal = 198.16;  // revenus ≤ seuil normal
  // Plafonds 2026 pour 3 enfants (couple 1 revenu) — source quelles-aides.fr
  static const double _cfSeuilMajore = 24459.0;   // couple 1 rev, 3 enfants
  static const double _cfSeuilNormal = 44735.0;   // couple 1 rev, 3 enfants
  static const double _cfMajorationPlafondParEnfant = 5765.0; // par enfant au-delà de 3

  // --- PreParE (CAF.fr, barèmes 2026) ---
  // PreParE — montants avril 2026 (source EXPERT_FAMILLE_AUDIT)
  static const double _prepareTauxPlein = 459.69;  // cessation totale d'activité
  static const double _prepareTauxDemi = 297.17;   // temps partiel ≤ 50%
  static const double _prepareTauxPartiel = 171.42; // temps partiel 50-80%

  static const Map<String, String> sourcesLegales = {
    'rsa': 'Art. L262-2 CASF — Décret n° 2026-220 du 30/03/2026',
    'apl': 'Art. L841-1 CCH — Barèmes 01/10/2025 maintenus 2026',
    'prime_activite': 'Art. L841-3, L844-1 CSS — Décret n° 2026-222 du 30/03/2026',
    'af': 'Art. L512-1 CSS — Instruction DSS/2B/2026/46 du 20/03/2026 — BMAF 478,16€',
    'aah': 'Art. L821-1 CSS — Décret n° 2026-229 du 30/03/2026 — Déconjugalisation oct. 2023',
    'cmg': 'Art. L531-5 CSS — CAF.fr barèmes 2026',
    'paje': 'Art. L531-2 CSS — CAF.fr barèmes 2026',
    'cf': 'Art. L522-1 CSS — CAF.fr barèmes 2026',
    'prepare': 'Art. L531-4 CSS — CAF.fr barèmes 2026',
    'mva': 'Art. L821-1-2 CSS — Décret n° 2026-229 du 30/03/2026',

    'asf': 'Art. L523-1 CSS — Barèmes 01/04/2026',
    'aeeh': 'Art. L541-1 CSS — Décret n° 2026-229 du 30/03/2026',
    'als': 'Art. L831-1 CSS — Arrêté 5 sept. 2025 maintenu 2026',
    'alf': 'Art. L542-1 CSS — Arrêté 5 sept. 2025 maintenu 2026',
  };

  // --- MVA (Art. L821-1-2 CSS) ---
  static const double _mvaMontant = 104.77;

  // NOTE : La Majoration pour Tierce Personne (MTP) liée à l'AAH (Art. L821-1-1 CSS)
  // a été supprimée pour les nouveaux bénéficiaires depuis décembre 2019.
  // Les personnes ayant besoin d'aide humaine relèvent de la PCH (MDPH, hors CAF).
  // → MTP retirée du moteur. Seule la MVA subsiste côté CAF.

  // --- ASF (Art. L523-1 CSS) ---
  static const double _asfMontantParEnfant = 200.78;

  // --- AEEH base (Art. L541-1 CSS, Décret n° 2026-229) ---
  // Montant de base — sans les compléments (6 catégories MDPH, hors périmètre ici)
  static const double _aeehMontantBase = 148.12;

  // --- ALS/ALF (Art. L831-1 et L542-1 CSS — arrêté 5 sept 2025) ---
  // Depuis l'harmonisation de 2018, ALS et APL partagent les mêmes plafonds de loyer.
  // Source : arrêté du 5 septembre 2025, CAF.fr barèmes aides au logement.
  // → On réutilise _aplPlafonds directement dans _calculerALSALF

  // ============================================================
  // CALCUL PRINCIPAL
  // ============================================================

  CalculResponse calculerDroits(Situation situation) {
    // ORDRE DE CALCUL IMPORTANT — les aides interagissent entre elles :
    // 1. AAH d'abord (indépendant)
    // 2. RSA ensuite (AAH comptée comme ressource — art. R262-11 CASF)
    // 3. APL (indépendant, mais déduite du RSA via forfait logement)
    // 4. Prime d'activité (AAH NON comptée comme ressource — art. R844-5 CSS)
    // 5. AF (indépendant)

    // 1. AAH (indépendant)
    final aah = _calculerAAH(situation);
    // 2. Aide au logement : APL si conventionné (défaut), ALS/ALF sinon
    final apl = _calculerAideLogement(situation);
    // 3. MVA (dépend de AAH + aide logement — nécessite aide au logement)
    final mva = _calculerMVA(situation, aahMontant: aah.$1, aplMontant: apl.$1);
    // 4. ASF (indépendant — parent isolé + pension non versée)
    final asf = _calculerASF(situation);
    // 5. AEEH (indépendant — enfant handicapé taux ≥ 50%) — AVANT PAJE (non cumulable)
    final aeeh = _calculerAEEH(situation);
    // 6. AF (indépendant)
    final af = _calculerAF(situation);
    // 6. RSA (AAH = ressource, pension versée déduite — art. R262-11 CASF)
    final rsa = _calculerRSA(situation, aahMensuel: aah.$1, percoitApl: apl.$1 > 0);
    // 7. Prime d'activité (AAH NON ressource, pension versée déduite)
    final prime = _calculerPrimeActivite(situation, percoitApl: apl.$1 > 0);

    // Aides famille
    final cmg = _calculerCMG(situation);
    // PAJE : non cumulable avec AEEH — on passe le montant AEEH pour arbitrage
    final paje = _calculerPAJE(situation, aeehMontant: aeeh.$1);
    final cf = _calculerCF(situation);
    final prepare = _calculerPreParE(situation);
    final ars = _calculerARS(situation);

    final droits = DroitsResult(
      rsa: rsa.$1,
      apl: apl.$1,
      primeActivite: prime.$1,
      af: af.$1,
      aah: aah.$1,
      mva: mva.$1,
      asf: asf.$1,
      aeeh: aeeh.$1,
      cmg: cmg.$1,
      paje: paje.$1,
      cf: cf.$1,
      prepare: prepare.$1,
      ars: ars.$1,
      total: rsa.$1 + apl.$1 + prime.$1 + af.$1 + aah.$1 + mva.$1 + asf.$1 + aeeh.$1 + cmg.$1 + paje.$1 + cf.$1 + prepare.$1 + ars.$1,
      details: {
        'rsa': rsa.$2,
        'apl': apl.$2,
        'prime_activite': prime.$2,
        'af': af.$2,
        'aah': aah.$2,
        'mva': mva.$2,
        'asf': asf.$2,
        'aeeh': aeeh.$2,
        'cmg': cmg.$2,
        'paje': paje.$2,
        'cf': cf.$2,
        'prepare': prepare.$2,
        'ars': ars.$2,
      },
    );

    EcartResult? ecart;
    if (situation.montantPercu.isNotEmpty) {
      ecart = _calculerEcart(droits, situation.montantPercu);
    }

    return CalculResponse(
      droits: droits,
      ecart: ecart,
      disclaimer: 'Calcul basé sur les barèmes officiels au 1er avril 2026 '
          '(Décrets n° 2026-220 à 229 du 30/03/2026, JO 31/03/2026). '
          'Ce calcul est indicatif et peut différer du calcul officiel de la CAF. '
          'Note : les montants versés par votre CAF peuvent refléter les barèmes précédents '
          'si la revalorisation d\'avril 2026 (+0,8%) n\'a pas encore été appliquée à votre dossier.',
      suggestions: _suggestionsAides(situation, droits),
    );
  }

  // ============================================================
  // CMG — Art. L531-5 CSS (porté depuis BudgetBébé)
  // ============================================================

  (double, String) _calculerCMG(Situation s) {
    // CMG réformé en septembre 2025 — l'ancien système forfaitaire est obsolète.
    // Le nouveau calcul est basé sur les heures réelles et un taux d'effort progressif.
    // Sans les données horaires et la grille officielle du taux d'effort,
    // il est impossible de calculer le CMG avec précision.
    // Le CMG est donc renvoyé à 0 avec une explication, et une suggestion est ajoutée.
    if (s.modeGarde == ModeGarde.aucun || s.nombreEnfants == 0) {
      return (0.0, 'CMG : non applicable. [${sourcesLegales['cmg']}]');
    }
    final aEnfantEligible = s.parentIsole
        ? s.agesEnfants.any((a) => a < 12) // < 12 ans pour parent isolé depuis sept. 2025
        : s.agesEnfants.any((a) => a < 6);
    if (!aEnfantEligible) {
      return (0.0, 'CMG : aucun enfant éligible (< 6 ans, ou < 12 ans si parent isolé). '
          '[${sourcesLegales['cmg']}]');
    }

    return (0.0, 'CMG : depuis septembre 2025, le CMG est calculé à l\'heure sur le coût réel de la garde. '
        'Utilisez le simulateur officiel sur caf.fr pour un montant précis. '
        '[${sourcesLegales['cmg']}]');
  }

  // ============================================================
  // AEEH — Allocation d'Éducation de l'Enfant Handicapé
  // Art. L541-1 CSS — Décret n° 2026-229 du 30/03/2026
  // ============================================================

  (double, String) _calculerAEEH(Situation s) {
    if (!s.aEnfantHandicape) {
      return (0.0, 'AEEH : aucun enfant avec handicap reconnu (taux MDPH ≥ 50% requis). [${sourcesLegales['aeeh']}]');
    }

    int enfantsEligibles = 0;
    for (int i = 0; i < s.agesEnfants.length; i++) {
      final age = s.agesEnfants[i];
      final taux = i < s.tauxHandicapEnfants.length ? s.tauxHandicapEnfants[i] : 0;
      if (age < 20 && taux >= 50) {
        enfantsEligibles++;
      }
    }

    if (enfantsEligibles == 0) {
      return (0.0, 'AEEH : aucun enfant éligible (< 20 ans avec taux MDPH ≥ 50%). [${sourcesLegales['aeeh']}]');
    }

    final montant = _aeehMontantBase * enfantsEligibles;
    return (
      montant,
      'AEEH : ${montant.toStringAsFixed(2)}€/mois ($enfantsEligibles enfant(s), taux ≥ 50%, < 20 ans). '
      'Montant de base sans compléments (catégories 1 à 6 MDPH non calculées). '
      '[${sourcesLegales['aeeh']}]'
    );
  }

  // ============================================================
  // PAJE base — Art. L531-2 CSS (porté depuis BudgetBébé)
  // ============================================================

  (double, String) _calculerPAJE(Situation s, {double aeehMontant = 0}) {
    // AEEH non cumulable avec PAJE base (art. L531-2 CSS al. 3)
    // Si un enfant de la famille est couvert par AEEH, PAJE non versée
    if (aeehMontant > 0) {
      return (0.0, 'PAJE : non cumulable avec AEEH (enfant(s) handicapé(s) éligible(s)). [${sourcesLegales['paje']}]');
    }
    final aEnfantMoins3 = s.agesEnfants.any((a) => a < 3);
    if (!aEnfantMoins3 && s.nombreEnfants > 0) {
      return (0.0, 'PAJE : aucun enfant de moins de 3 ans. [${sourcesLegales['paje']}]');
    }
    if (s.nombreEnfants == 0) {
      return (0.0, 'PAJE : aucun enfant. [${sourcesLegales['paje']}]');
    }

    final revenusAnnuels = (s.revenuActiviteDemandeur + s.revenuActiviteConjoint + s.totalAutresRevenus) * 12;
    final estCouple = s.situationFamiliale == SituationFamiliale.couple;

    // Catégorie de plafond : couple 1 rev / couple 2 rev / isolé
    // Couple 2 revenus si conjoint gagne ≥ 6 306€/an (ou revenu mensuel ≥ 525.50€)
    final estDeuxRevenus = estCouple && (s.revenuActiviteConjoint * 12 >= _pajeSeuilDeuxRevenus);
    final estIsole = !estCouple;

    // Plafonds pour 1 enfant (base) puis +6 213€/enfant supplémentaire
    double plafondPlein;
    double plafondPartiel;
    final enfantsSupp = (s.nombreEnfants - 1).clamp(0, double.infinity);

    if (estIsole || estDeuxRevenus) {
      plafondPlein = _pajePlafondPlein2Rev1Enf + enfantsSupp * _pajePlafondPleinParEnfSupp;
      plafondPartiel = _pajePlafondPartiel2Rev1Enf + enfantsSupp * _pajePlafondPleinParEnfSupp;
    } else {
      // Couple 1 revenu
      plafondPlein = _pajePlafondPlein1Rev1Enf + enfantsSupp * _pajePlafondPleinParEnfSupp;
      plafondPartiel = _pajePlafondPartiel1Rev1Enf + enfantsSupp * _pajePlafondPleinParEnfSupp;
    }

    if (revenusAnnuels > plafondPartiel) {
      return (0.0, 'PAJE : revenus (${revenusAnnuels.toStringAsFixed(0)}€/an) > plafond '
          '(${plafondPartiel.toStringAsFixed(0)}€). [${sourcesLegales['paje']}]');
    }

    final montant = revenusAnnuels <= plafondPlein ? _pajeTauxPlein : _pajeTauxPartiel;
    final taux = revenusAnnuels <= plafondPlein ? 'taux plein' : 'taux partiel';
    final categorie = estIsole ? 'isolé' : (estDeuxRevenus ? 'couple 2 rev.' : 'couple 1 rev.');

    return (
      montant,
      'PAJE base : ${montant.toStringAsFixed(2)}€/mois ($taux, $categorie — enfant < 3 ans). '
          '[${sourcesLegales['paje']}]'
    );
  }

  // ============================================================
  // COMPLÉMENT FAMILIAL — Art. L522-1 CSS (porté depuis BudgetBébé)
  // ============================================================

  (double, String) _calculerCF(Situation s) {
    if (s.nombreEnfants < 3) {
      return (0.0, 'CF : 3 enfants minimum requis (${s.nombreEnfants} déclarés). [${sourcesLegales['cf']}]');
    }
    final enfantsEligibles = s.agesEnfants.where((a) => a >= 3 && a <= 21).length;
    if (s.agesEnfants.isNotEmpty && enfantsEligibles < 3) {
      return (0.0, 'CF : 3 enfants entre 3 et 21 ans requis. [${sourcesLegales['cf']}]');
    }

    final revenusAnnuels = (s.revenuActiviteDemandeur + s.revenuActiviteConjoint + s.totalAutresRevenus) * 12;
    final estCouple = s.situationFamiliale == SituationFamiliale.couple;
    final estDeuxRevenus = estCouple && (s.revenuActiviteConjoint * 12 >= _pajeSeuilDeuxRevenus);
    final enfantsSupp = (s.nombreEnfants - 3).clamp(0, double.infinity);

    // Plafonds CF 2026 — varient selon couple 1 rev / 2 rev / isolé + nb enfants
    double plafondMajore;
    double plafondNormal;
    if (!estCouple || estDeuxRevenus) {
      // Couple 2 revenus ou parent isolé
      plafondMajore = 27230 + enfantsSupp * _cfMajorationPlafondParEnfant;
      plafondNormal = 54724 + enfantsSupp * _cfMajorationPlafondParEnfant;
    } else {
      // Couple 1 revenu
      plafondMajore = _cfSeuilMajore + enfantsSupp * _cfMajorationPlafondParEnfant;
      plafondNormal = _cfSeuilNormal + enfantsSupp * _cfMajorationPlafondParEnfant;
    }

    if (revenusAnnuels > plafondNormal) {
      return (0.0, 'CF : revenus (${revenusAnnuels.toStringAsFixed(0)}€/an) > plafond '
          '(${plafondNormal.toStringAsFixed(0)}€). [${sourcesLegales['cf']}]');
    }

    final montantBrut = revenusAnnuels <= plafondMajore ? _cfMontantMajore : _cfMontantNormal;
    final montant = _arrondi(s.gardeAlternee ? montantBrut / 2 : montantBrut);
    final niveau = revenusAnnuels <= plafondMajore ? 'majoré' : 'normal';

    return (
      montant,
      'Complément familial : $montant€/mois ($niveau — ${s.nombreEnfants} enfants). '
          '[${sourcesLegales['cf']}]'
    );
  }

  // ============================================================
  // PreParE — Art. L531-4 CSS (portó depuis BudgetBébé)
  // ============================================================

  (double, String) _calculerPreParE(Situation s) {
    if (s.congeParental == CongeParental.aucun) {
      return (0.0, 'PreParE : aucun congé parental. [${sourcesLegales['prepare']}]');
    }
    if (s.nombreEnfants == 0) {
      return (0.0, 'PreParE : aucun enfant. [${sourcesLegales['prepare']}]');
    }

    final montant = s.congeParental == CongeParental.tauxPlein
        ? _prepareTauxPlein
        : _prepareTauxDemi;
    final type = s.congeParental == CongeParental.tauxPlein
        ? 'taux plein (arrêt complet)'
        : 'taux demi (mi-temps)';

    return (
      montant,
      'PreParE : ${montant.toStringAsFixed(2)}€/mois ($type). '
          '[${sourcesLegales['prepare']}]'
    );
  }

  // ============================================================
  // AIDES MÉCONNUES — suggestions contextuelles
  // ============================================================

  List<AideSuggestion> _suggestionsAides(Situation s, DroitsResult droits) {
    final suggestions = <AideSuggestion>[];

    // Revenus totaux du foyer (incluant aides calculées)
    final revenuMensuel = s.revenuActiviteDemandeur +
        s.revenuActiviteConjoint +
        s.totalAutresRevenus +
        droits.rsa +
        droits.aah;

    // CSS (Complémentaire Santé Solidaire) — si revenus modestes
    // Seuil approximatif 2026 : ~1090€/mois pour 1 pers, ~1600€ pour 2
    final seuilCSS = s.situationFamiliale == SituationFamiliale.couple ? 1600.0 : 1090.0;
    if (revenuMensuel < seuilCSS) {
      suggestions.add(const AideSuggestion(
        titre: 'Complémentaire Santé Solidaire (CSS)',
        description:
            'Mutuelle gratuite ou quasi-gratuite (moins de 1€/mois). Couvre soins, médicaments, dentaire et optique. '
            'Attribuée automatiquement aux bénéficiaires du RSA.',
        source: 'Ameli.fr — ameli.fr/assure/droits-demarches/complementaire-sante-solidaire',
      ));
    }

    // Chèque Énergie — si RSA ou revenus < 10 700€/an (1 pers)
    if (droits.rsa > 0 || revenuMensuel * 12 < 10700) {
      suggestions.add(const AideSuggestion(
        titre: 'Chèque Énergie',
        description:
            'De 48€ à 277€/an pour payer vos factures d\'énergie ou travaux d\'isolation. '
            'Envoyé automatiquement par l\'État selon vos revenus N-2.',
        source: 'chequeenergie.gouv.fr',
      ));
    }

    // PCH — si handicap 80%+
    if (s.tauxHandicap != null && s.tauxHandicap! >= 80) {
      suggestions.add(const AideSuggestion(
        titre: 'PCH — Prestation de Compensation du Handicap',
        description:
            'Aide financière pour compenser les surcoûts liés au handicap : aide humaine à domicile, '
            'aménagement du logement et du véhicule, équipements spéciaux. Non plafonnée par les revenus.',
        source: 'MDPH de votre département',
      ));
    }

    // RQTH — si handicap reconnu
    if (s.tauxHandicap != null && s.tauxHandicap! >= 50) {
      suggestions.add(const AideSuggestion(
        titre: 'RQTH — Reconnaissance Qualité Travailleur Handicapé',
        description:
            'Facilite le maintien dans l\'emploi et l\'accès à la formation. Permet l\'accès à l\'ESAT, '
            'aux aménagements de poste, et à des aides spécifiques de France Travail (AGEFIPH).',
        source: 'MDPH de votre département',
      ));
    }

    // ARS : maintenant dans le moteur de calcul (_calculerARS), pas en suggestion

    // CMG — réformé sept. 2025, calcul à l'heure, non simulable sans données horaires
    final ageLimiteCmg = s.parentIsole ? 12 : 6;
    final enfantsEligiblesCmg = s.agesEnfants.where((a) => a < ageLimiteCmg).length;
    if (enfantsEligiblesCmg > 0 && s.modeGarde != ModeGarde.aucun) {
      suggestions.add(AideSuggestion(
        titre: 'CMG — Complément de Libre Choix du Mode de Garde',
        description:
            'Depuis septembre 2025, le CMG est calculé à l\'heure sur le coût réel de la garde. '
            'Le montant dépend de vos heures de garde et du taux d\'effort de votre foyer. '
            'Simulez votre CMG sur le site officiel caf.fr.',
        source: 'CAF.fr — simulateur CMG : caf.fr/allocataires/mes-services-en-ligne/faire-une-simulation',
      ));
    }

    // FSL — si locataire avec faibles revenus
    if (s.statutLogement == StatutLogement.locataire && revenuMensuel < 1800) {
      suggestions.add(const AideSuggestion(
        titre: 'FSL — Fonds de Solidarité Logement',
        description:
            'Aide départementale non remboursable pour accéder à un logement ou s\'y maintenir : '
            'dépôt de garantie, premier loyer, loyers impayés, factures d\'eau et d\'énergie.',
        source: 'Conseil Départemental de votre département (service Action Sociale)',
      ));
    }

    // Aide alimentaire — si revenus très faibles
    if (revenuMensuel < 900) {
      suggestions.add(const AideSuggestion(
        titre: 'Épiceries sociales et aide alimentaire',
        description:
            'Accès à une épicerie sociale (courses à prix réduits) ou colis alimentaires gratuits. '
            'Réseau ANDES, Banques Alimentaires, Croix-Rouge, Secours Catholique.',
        source: 'CCAS (Centre Communal d\'Action Sociale) de votre commune',
      ));
    }

    // MVA — suggestion si AAH éligible mais conditions MVA pas toutes remplies
    if (droits.mva == 0 && droits.aah > 0 && s.tauxHandicap != null && s.tauxHandicap! >= 80) {
      final raisons = <String>[];
      if (s.revenuActiviteDemandeur > 0) raisons.add('revenus d\'activité déclarés');
      if (s.situationVie != SituationVie.autonome) raisons.add('vie en institution/hébergé');
      if (droits.apl <= 0) raisons.add('pas d\'aide au logement (APL/ALS/ALF)');
      if (droits.aah < _aahMontantMax) raisons.add('AAH non au taux plein');
      suggestions.add(AideSuggestion(
        titre: 'MVA — Majoration pour la Vie Autonome (104,77€/mois)',
        description:
            'Supplément à l\'AAH pour les personnes vivant de manière autonome en logement. '
            '${raisons.isNotEmpty ? 'Condition(s) non remplie(s) actuellement : ${raisons.join(', ')}. ' : ''}'
            'Si votre situation évolue, pensez à en faire la demande.',
        source: 'CAF.fr — demande auprès de votre CAF',
      ));
    }

    // ASF — suggestion si parent isolé mais conditions pas remplies
    if (droits.asf == 0 && s.parentIsole) {
      suggestions.add(const AideSuggestion(
        titre: 'ASF — Allocation de Soutien Familial (200,78€/enfant/mois)',
        description:
            'Versée au parent qui élève seul ses enfants lorsque l\'autre parent ne verse pas '
            'la pension alimentaire. Si votre ex-conjoint ne paie pas, faites la demande.',
        source: 'CAF.fr — demande auprès de votre CAF',
      ));
    }

    // Tarifs sociaux transport — si revenus faibles
    if (revenuMensuel * 12 < 12000) {
      suggestions.add(const AideSuggestion(
        titre: 'Tarifs sociaux transports',
        description:
            'Réductions de 50 à 75% sur le réseau SNCF (carte Avantage Solidarité), '
            'les transports en commun régionaux, et parfois les transports urbains locaux.',
        source: 'Votre région et opérateur de transport local',
      ));
    }

    return suggestions;
  }

  // ============================================================
  // RSA — Art. L262-2 CASF
  // ============================================================

  (double, String) _calculerRSA(Situation s, {double aahMensuel = 0, bool percoitApl = false}) {
    final nbPersonnes = (s.situationFamiliale == SituationFamiliale.couple ? 2 : 1) + s.nombreEnfants;

    // Montant forfaitaire
    var forfaitaire = _rsaBase;
    if (s.situationFamiliale == SituationFamiliale.couple) {
      forfaitaire *= (1 + _rsaMajorationCouple); // 977.54€
    }
    for (var i = 0; i < s.nombreEnfants; i++) {
      forfaitaire += _rsaBase * (i < 2 ? _rsaMajorationEnfant12 : _rsaMajorationEnfant3Plus);
    }

    // Majoration parent isolé — RSA majoré (art. L262-9 CASF)
    // = base × 128.412% + base × 42.86% par enfant
    if (s.parentIsole && s.situationFamiliale == SituationFamiliale.seul && s.nombreEnfants > 0) {
      forfaitaire = _rsaBase * _rsaMajorationIsolementBase;
      for (var i = 0; i < s.nombreEnfants; i++) {
        forfaitaire += _rsaBase * _rsaMajorationIsolementParEnfant;
      }
    }

    // Forfait logement (déduit si hébergé, OU si perçoit APL/ALS/ALF — art. R262-9 CASF)
    var forfaitLogement = 0.0;
    if (s.statutLogement == StatutLogement.heberge || s.loyerMensuel == 0 || percoitApl) {
      if (nbPersonnes == 1) {
        forfaitLogement = _rsaForfaitLogement1;
      } else if (nbPersonnes == 2) {
        forfaitLogement = _rsaForfaitLogement2;
      } else {
        forfaitLogement = _rsaForfaitLogement3Plus;
      }
    }

    // Revenus d'activité (pour la bonification 62%)
    final revenusActivite = s.revenuActiviteDemandeur + s.revenuActiviteConjoint;

    // Ressources totales du foyer :
    // - Revenus d'activité + autres revenus + AAH (art. R262-11 CASF)
    // - Pension alimentaire versée déduite (art. R262-6 CASF)
    final ressources = (revenusActivite + s.totalAutresRevenus + aahMensuel
        - s.pensionAlimentaireVersee).clamp(0.0, double.infinity);

    // RSA = (Forfaitaire + 62% × revenus activité) - Ressources - Forfait logement
    // La bonification 62% encourage la reprise d'activité (art. R262-7 CASF)
    final rsa = (forfaitaire + 0.62 * revenusActivite - ressources - forfaitLogement)
        .clamp(0.0, double.infinity);
    final montant = _arrondi(rsa);

    String detail;
    if (aahMensuel > 0 && montant == 0) {
      detail = 'RSA : non cumulable avec l\'AAH pleine (${aahMensuel.toStringAsFixed(2)}\u20AC). '
          'L\'AAH est comptée comme ressource (art. R262-11 CASF). '
          'Forfaitaire : ${forfaitaire.toStringAsFixed(2)}\u20AC. '
          '[${sourcesLegales['rsa']}]';
    } else if (montant > 0) {
      detail = 'RSA estimé : $montant\u20AC/mois. '
          'Forfaitaire : ${forfaitaire.toStringAsFixed(2)}\u20AC, '
          'ressources : ${ressources.toStringAsFixed(2)}\u20AC'
          '${aahMensuel > 0 ? ' (dont AAH ${aahMensuel.toStringAsFixed(2)}\u20AC)' : ''}. '
          '[${sourcesLegales['rsa']}]';
    } else {
      detail = 'RSA : vos ressources (${ressources.toStringAsFixed(2)}\u20AC) '
          'dépassent le forfaitaire (${forfaitaire.toStringAsFixed(2)}\u20AC). '
          '[${sourcesLegales['rsa']}]';
    }

    return (montant, detail);
  }

  // ============================================================
  // APL — Art. L841-1 CCH
  // ============================================================

  // Délègue vers APL ou ALS/ALF selon le type de logement
  (double, String) _calculerAideLogement(Situation s) {
    if (s.logementConventionne == false) {
      return _calculerALSALF(s);
    }
    // logementConventionne == true ou null → APL (défaut)
    return _calculerAPL(s);
  }

  (double, String) _calculerAPL(Situation s) {
    if (s.statutLogement != StatutLogement.locataire || s.loyerMensuel == 0) {
      return (0.0, 'APL : non éligible (non locataire ou loyer nul). [${sourcesLegales['apl']}]');
    }

    final estCouple = s.situationFamiliale == SituationFamiliale.couple;
    final nbPac = s.nombreEnfants; // personnes à charge = enfants
    final nbFoyer = (estCouple ? 2 : 1) + nbPac; // taille totale du foyer
    final plafonds = _aplPlafonds[s.zoneLogement.value]!;

    // ── L : Loyer plafonné ──
    // Indices : [0]=seul, [1]=couple, [2]=1pac, [3]=supplément
    double loyerPlafond;
    if (nbPac == 0) {
      loyerPlafond = estCouple ? plafonds[1] : plafonds[0];
    } else if (nbPac == 1) {
      loyerPlafond = plafonds[2];
    } else {
      loyerPlafond = plafonds[2] + plafonds[3] * (nbPac - 1);
    }
    final l = s.loyerMensuel.clamp(0.0, loyerPlafond);

    // ── C : Forfait charges (base + 13.74€/pac) ──
    final c = _aplChargesBase + nbPac * _aplChargesParPac;

    // ── R : Ressources annuelles (hors AAH, RSA, prime, bourses — art. R.822-4 CCH) ──
    double autresRevenusEligibles = 0;
    for (final r in s.autresRevenus) {
      if (!r.type.name.startsWith('bourseEchelon')) {
        autresRevenusEligibles += r.montantMensuel;
      }
    }
    final ressourcesMensuelles = (s.revenuActiviteDemandeur +
            s.revenuActiviteConjoint +
            autresRevenusEligibles -
            s.pensionAlimentaireVersee)
        .clamp(0.0, double.infinity);
    final rAnnuel = ressourcesMensuelles * 12;

    // ── R0 : seuil de ressources (décret 2025-1401) ──
    double r0;
    if (nbFoyer <= 8) {
      r0 = _aplR0[nbFoyer]?.toDouble() ?? _aplR0[8]!.toDouble();
    } else {
      r0 = _aplR0[8]! + (nbFoyer - 8) * _aplR0ParPersonneSupp;
    }
    final ressourceBase = (rAnnuel - r0).clamp(0.0, double.infinity);

    // ── TF : taux famille (art. 14 arrêté 27/09/2019) ──
    double tf;
    if (nbPac == 0) {
      tf = estCouple ? _aplTF[1] : _aplTF[0];
    } else if (nbPac + 2 <= _aplTF.length) {
      tf = _aplTF[nbPac + 1]; // index 2=1pac, 3=2pac, etc.
    } else {
      tf = _aplTF.last + (nbPac - 6) * _aplTFParPacSupp;
    }

    // ── TL : taux loyer (progressif, basé sur RL = L / LR) ──
    // LR = loyer plafond Zone II pour la même composition
    final plafondsZone2 = _aplPlafonds['zone_2']!;
    double lr;
    if (nbPac == 0) {
      lr = estCouple ? plafondsZone2[1] : plafondsZone2[0];
    } else if (nbPac == 1) {
      lr = plafondsZone2[2];
    } else {
      lr = plafondsZone2[2] + plafondsZone2[3] * (nbPac - 1);
    }
    // RL = L / LR (ratio décimal, ex: 0.9372 = 93.72%)
    // TL progressif : <0.45 → 0, 0.45-0.75 → 0.0045×(RL-0.45), ≥0.75 → 0.0045×0.30+0.0068×(RL-0.75)
    final rl = lr > 0 ? (l / lr) : 0.0;
    double tl;
    if (rl < 0.45) {
      tl = 0;
    } else if (rl < 0.75) {
      tl = 0.0045 * (rl - 0.45);
    } else {
      tl = 0.0045 * 0.30 + 0.0068 * (rl - 0.75);
    }
    tl = (tl * 1000).round() / 1000; // arrondi 3 décimales

    // ── Tp = TF + TL ──
    final tp = tf + tl;

    // ── P0 = max(8.5% × (L+C), 39.56€) ──
    final p0 = (0.085 * (l + c)).clamp(_aplP0Plancher, double.infinity);

    // ── PP = P0 + Tp × (R - R0) ──
    final pp = p0 + tp * ressourceBase;

    // ── APL = L + C - PP - 5€ ──
    var apl = l + c - pp - _aplDeduction;
    apl = apl.clamp(0.0, double.infinity);

    // APL locatif ordinaire : aucun seuil de non-versement (0€)
    // (ALS/ALF = seuil 10€, mais on calcule ici l'APL)
    final montant = apl > 0 ? _arrondi(apl) : 0.0;

    String detail;
    if (montant > 0) {
      final sousR0 = rAnnuel <= r0;
      detail = 'APL estimée : $montant\u20AC/mois. '
          'L=${l.toStringAsFixed(2)}\u20AC (plafond ${loyerPlafond.toStringAsFixed(2)}\u20AC), '
          'C=${c.toStringAsFixed(2)}\u20AC, '
          'PP=${pp.toStringAsFixed(2)}\u20AC (P0=${p0.toStringAsFixed(2)}\u20AC, Tp=${(tp * 100).toStringAsFixed(2)}%)'
          '${sousR0 ? ' — revenus sous R0, PP minimale' : ''}. '
          '[${sourcesLegales['apl']}]';
    } else {
      detail = 'APL : non éligible. '
          'PP (${pp.toStringAsFixed(2)}\u20AC) ≥ L+C-5 (${(l + c - _aplDeduction).toStringAsFixed(2)}\u20AC). '
          'Revenus : ${rAnnuel.toStringAsFixed(0)}\u20AC/an, R0 : ${r0.toStringAsFixed(0)}\u20AC. '
          '[${sourcesLegales['apl']}]';
    }

    return (montant, detail);
  }

  // ============================================================
  // PRIME D'ACTIVITÉ — Art. L841-3 CSS
  // ============================================================

  (double, String) _calculerPrimeActivite(Situation s, {bool percoitApl = false}) {
    final revenusActivite = s.revenuActiviteDemandeur + s.revenuActiviteConjoint;
    if (revenusActivite == 0) {
      return (0.0, 'Prime d\'activité : non éligible (aucun revenu d\'activité). '
          '[${sourcesLegales['prime_activite']}]');
    }

    final nbPersonnes = (s.situationFamiliale == SituationFamiliale.couple ? 2 : 1) + s.nombreEnfants;

    // Montant forfaitaire majoré
    var forfaitaire = _primeBase;
    if (s.situationFamiliale == SituationFamiliale.couple) {
      forfaitaire *= (1 + _primeMajorationCouple);
    } else if (s.parentIsole && s.nombreEnfants > 0) {
      // Majoration parent isolé (même taux que RSA majoré — art. R844-2 CSS)
      forfaitaire = _primeBase * _rsaMajorationIsolementBase;
      for (var i = 0; i < s.nombreEnfants; i++) {
        forfaitaire += _primeBase * _rsaMajorationIsolementParEnfant;
      }
    } else {
      for (var i = 0; i < s.nombreEnfants; i++) {
        forfaitaire += _primeBase * (i < 2 ? _primeMajorationEnfant12 : _primeMajorationEnfant3Plus);
      }
    }

    // Bonification individuelle (art. L844-1 CSS)
    var bonification = 0.0;
    for (final revenu in [s.revenuActiviteDemandeur, s.revenuActiviteConjoint]) {
      if (revenu >= _primeSeuilBonifMin) {
        final taux = ((revenu - _primeSeuilBonifMin) / (_primeSeuilBonifMax - _primeSeuilBonifMin)).clamp(0.0, 1.0);
        bonification += taux * _primeBonificationMax;
      }
    }

    // Forfait logement (déduit comme pour le RSA si APL ou hébergé)
    var forfaitLogement = 0.0;
    if (s.statutLogement == StatutLogement.heberge || s.loyerMensuel == 0 || percoitApl) {
      if (nbPersonnes == 1) {
        forfaitLogement = _rsaForfaitLogement1;
      } else if (nbPersonnes == 2) {
        forfaitLogement = _rsaForfaitLogement2;
      } else {
        forfaitLogement = _rsaForfaitLogement3Plus;
      }
    }

    // Ressources (pension versée NON déduite pour la prime — art. R844-1 CSS)
    final ressources = revenusActivite + s.totalAutresRevenus;

    // Prime = forfaitaire + 59.85% × revenus activité + bonification - ressources - forfait logement
    final prime = forfaitaire + 0.5985 * revenusActivite + bonification - ressources - forfaitLogement;
    final montant = _arrondi(prime.clamp(0.0, double.infinity));

    final detail = montant > 0
        ? 'Prime d\'activité estimée : $montant\u20AC/mois. '
            'Forfaitaire : ${forfaitaire.toStringAsFixed(2)}\u20AC, '
            'bonification : ${bonification.toStringAsFixed(2)}\u20AC'
            '${forfaitLogement > 0 ? ', forfait logement : -${forfaitLogement.toStringAsFixed(2)}\u20AC' : ''}. '
            '[${sourcesLegales['prime_activite']}]'
        : 'Prime d\'activité : non éligible (ressources trop élevées). '
            '[${sourcesLegales['prime_activite']}]';

    return (montant, detail);
  }

  // ============================================================
  // ALLOCATIONS FAMILIALES — Art. L512-1 CSS
  // ============================================================

  (double, String) _calculerAF(Situation s) {
    if (s.nombreEnfants < 2) {
      return (0.0, 'Allocations familiales : 2 enfants minimum requis. '
          '[${sourcesLegales['af']}]');
    }

    final ressourcesAnnuelles = (s.revenuActiviteDemandeur + s.revenuActiviteConjoint + s.totalAutresRevenus) * 12;

    // Montant de base selon nombre d'enfants
    var montant = 0.0;
    if (s.nombreEnfants == 2) {
      montant = _afBase2Enfants;
    } else if (s.nombreEnfants == 3) {
      montant = _afBase3Enfants;
    } else {
      montant = _afBase3Enfants + _afSupplementParEnfant * (s.nombreEnfants - 3);
    }

    // Majoration âge : 18+ ans depuis 01/03/2026 (anciennement 14+)
    var nb18Plus = 0;
    if (s.agesEnfants.isNotEmpty) {
      nb18Plus = s.agesEnfants.where((age) => age >= 18).length;
      // Pas de majoration pour l'aîné d'une famille de 2 enfants
      if (s.nombreEnfants == 2 && nb18Plus > 0) {
        nb18Plus = (nb18Plus - 1).clamp(0, nb18Plus);
      }
    }
    montant += nb18Plus * _afMajoration18Plus;

    // Modulation selon ressources (plafonds 2026 : base + 7 465€/enfant au-delà de 2)
    final enfantsSupp = (s.nombreEnfants - 2).clamp(0, double.infinity);
    final plafondT1 = _afPlafondBase1 + _afMajorationPlafondParEnfant * enfantsSupp;
    final plafondT2 = _afPlafondBase2 + _afMajorationPlafondParEnfant * enfantsSupp;

    String tranche;
    if (ressourcesAnnuelles > plafondT2) {
      montant /= 4;
      tranche = 'tranche 3 (÷4)';
    } else if (ressourcesAnnuelles > plafondT1) {
      montant /= 2;
      tranche = 'tranche 2 (÷2)';
    } else {
      tranche = 'tranche 1 (plein)';
    }

    final montantFinal = _arrondi(montant);

    return (
      montantFinal,
      montantFinal > 0
          ? 'AF : $montantFinal\u20AC/mois pour ${s.nombreEnfants} enfants ($tranche). '
              'Majoration 18+ : $nb18Plus enfant(s). '
              '[${sourcesLegales['af']}]'
          : 'Allocations familiales : non éligible. [${sourcesLegales['af']}]'
    );
  }

  // ============================================================
  // AAH — Art. L821-1 CSS — DÉCONJUGALISÉE depuis oct. 2023
  // ============================================================

  (double, String) _calculerAAH(Situation s) {
    if (s.tauxHandicap == null || s.tauxHandicap! < 50) {
      return (0.0, 'AAH : taux d\'incapacité < 50%, non éligible. '
          '[${sourcesLegales['aah']}]');
    }

    // DÉCONJUGALISATION : seules les ressources du DEMANDEUR comptent
    // (loi du 16 août 2022, effective oct. 2023)

    // ── Abattement sur revenus d'activité (art. R821-4 CSS) ──
    // 80% d'abattement sur la tranche ≤ 30% SMIC brut
    // 40% d'abattement sur la tranche > 30% SMIC brut
    // SMIC brut mensuel 2026 = 1 823,03€ → 30% = 546,91€ (source : aide-sociale.fr, arrêté 31/12/2025)
    const smicBrut30pct = 546.91;
    final revenuActivite = s.revenuActiviteDemandeur;
    double revenuActiviteRetenu;
    if (revenuActivite <= 0) {
      revenuActiviteRetenu = 0;
    } else if (revenuActivite <= smicBrut30pct) {
      // 80% abattu → seuls 20% retenus
      revenuActiviteRetenu = revenuActivite * 0.20;
    } else {
      // 20% sur première tranche + 60% sur le reste
      revenuActiviteRetenu = smicBrut30pct * 0.20 + (revenuActivite - smicBrut30pct) * 0.60;
    }

    // Autres revenus (non d'activité) : pas d'abattement
    final autresRevenusMensuels = s.totalAutresRevenus;

    final ressourcesMensuellesRetenues = revenuActiviteRetenu + autresRevenusMensuels;
    final ressourcesAnnuelles = ressourcesMensuellesRetenues * 12;

    // Plafond
    var plafond = _aahPlafondSeul + s.nombreEnfants * _aahMajorationEnfant;

    if (ressourcesAnnuelles > plafond) {
      return (0.0, 'AAH : ressources retenues (${ressourcesAnnuelles.toStringAsFixed(0)}\u20AC/an '
          'après abattement) > plafond (${plafond.toStringAsFixed(0)}\u20AC). '
          'Déconjugalisée. [${sourcesLegales['aah']}]');
    }

    // AAH différentielle = max - ressources mensuelles retenues
    final aah = (_aahMontantMax - ressourcesMensuellesRetenues).clamp(0.0, _aahMontantMax);
    final montant = _arrondi(aah);

    String detail;
    if (montant > 0) {
      final abattementInfo = revenuActivite > 0
          ? 'Revenus activité ${revenuActivite.toStringAsFixed(0)}\u20AC → '
              'retenus ${revenuActiviteRetenu.toStringAsFixed(0)}\u20AC (abattement 80%/40%). '
          : '';
      detail = 'AAH : $montant\u20AC/mois (taux ${s.tauxHandicap}%). $abattementInfo'
          'Déconjugalisée oct. 2023. [${sourcesLegales['aah']}]';
    } else {
      detail = 'AAH : non éligible. [${sourcesLegales['aah']}]';
    }

    return (montant, detail);
  }

  // ============================================================
  // ÉCART
  // ============================================================

  // ============================================================
  // ARS — Art. L543-1 CSS — Allocation de Rentrée Scolaire
  // Barèmes août 2025 (en vigueur jusqu'à août 2026 — revalorisation annuelle en août, pas en avril)
  //   403,72€ (6-10 ans) / 424,95€ (11-14 ans) / 440,65€ (15-18 ans)
  // Plafonds RFR 2026 (N-2 = 2024) :
  //   Isolé   : 25 338€ + 5 841€/enfant au-delà du 1er
  //   Couple  : 32 271€ + 5 841€/enfant au-delà du 1er
  // Note : versement annuel en août — affiché en équivalent mensuel (÷ 12)
  // ============================================================

  (double, String) _calculerARS(Situation s) {
    if (s.nombreEnfants == 0 || s.agesEnfants.isEmpty) {
      return (0.0, 'ARS : aucun enfant. [Art. L543-1 CSS]');
    }

    final revenuAnnuel = (s.revenuActiviteDemandeur + s.revenuActiviteConjoint + s.totalAutresRevenus) * 12;
    // Plafonds ARS 2026 — distingue isolé et couple (art. D543-1 CSS)
    final estCouple = s.situationFamiliale == SituationFamiliale.couple;
    final plafondBase = estCouple ? 32271.0 : 25338.0;
    final plafondTotal = plafondBase + (s.nombreEnfants - 1) * 5841.0;

    if (revenuAnnuel > plafondTotal) {
      return (0.0,
          'ARS : revenus au-dessus du plafond (${revenuAnnuel.toStringAsFixed(0)}\u20AC > ${plafondTotal.toStringAsFixed(0)}\u20AC). [Art. L543-1 CSS]');
    }

    double totalAnnuel = 0;
    for (final age in s.agesEnfants) {
      if (age >= 6 && age < 11) {
        totalAnnuel += 403.72;
      } else if (age >= 11 && age < 15) {
        totalAnnuel += 424.95;
      } else if (age >= 15 && age <= 18) {
        totalAnnuel += 440.65;
      }
    }

    if (totalAnnuel == 0) {
      return (0.0, 'ARS : aucun enfant entre 6 et 18 ans. [Art. L543-1 CSS]');
    }

    final mensuel = _arrondi(totalAnnuel / 12);
    return (mensuel,
        'ARS : ${totalAnnuel.toStringAsFixed(0)}\u20AC/an (versé en août) = ${mensuel.toStringAsFixed(2)}\u20AC/mois équivalent. [Art. L543-1 CSS]');
  }

  EcartResult _calculerEcart(DroitsResult droits, Map<String, double> percu) {
    final ecarts = <String, double>{};
    var ecartTotal = 0.0;
    final aidesNonReclamees = <String>[];

    final aides = {
      'rsa': droits.rsa,
      'apl': droits.apl,
      'prime_activite': droits.primeActivite,
      'af': droits.af,
      'aah': droits.aah,
      'cmg': droits.cmg,
      'paje': droits.paje,
      'cf': droits.cf,
      'prepare': droits.prepare,
      'ars': droits.ars,
      'mva': droits.mva,
      'asf': droits.asf,
    };

    for (final entry in aides.entries) {
      final theorique = entry.value;
      final recu = percu[entry.key] ?? 0;
      final diff = theorique - recu;
      ecarts[entry.key] = _arrondi(diff);

      if (diff > 0) {
        ecartTotal += diff;
        if (recu == 0 && theorique > 0) {
          aidesNonReclamees.add(entry.key);
        }
      }
    }

    return EcartResult(
      ecarts: ecarts,
      ecartTotal: _arrondi(ecartTotal),
      aidesNonReclamees: aidesNonReclamees,
    );
  }

  // ============================================================
  // ALS / ALF — Allocation de Logement Sociale / Familiale
  // Art. L831-1 CSS (ALS) — Art. L542-1 CSS (ALF)
  // Logement non conventionné — même formule qu'APL, plafonds différents
  // ============================================================

  (double, String) _calculerALSALF(Situation s) {
    if (s.statutLogement != StatutLogement.locataire || s.loyerMensuel == 0) {
      return (0.0, 'ALS/ALF : non éligible (non locataire ou loyer nul).');
    }

    final estCouple = s.situationFamiliale == SituationFamiliale.couple;
    final nbPac = s.nombreEnfants;
    // ALF : famille avec enfants OU couple marié/pacsé
    // ALS : personnes seules, en concubinage sans enfants
    final estALF = nbPac > 0 ||
        s.statutConjugal == StatutConjugal.marie ||
        s.statutConjugal == StatutConjugal.pacse;
    final typeAide = estALF ? 'ALF' : 'ALS';
    final sourceLeg = estALF ? sourcesLegales['alf']! : sourcesLegales['als']!;

    // Harmonisation 2018 : mêmes plafonds qu'APL
    final plafonds = _aplPlafonds[s.zoneLogement.value]!;
    double loyerPlafond;
    if (nbPac == 0) {
      loyerPlafond = estCouple ? plafonds[1] : plafonds[0];
    } else if (nbPac == 1) {
      loyerPlafond = plafonds[2];
    } else {
      loyerPlafond = plafonds[2] + plafonds[3] * (nbPac - 1);
    }
    final l = s.loyerMensuel.clamp(0.0, loyerPlafond);
    final c = _aplChargesBase + nbPac * _aplChargesParPac;

    double autresRevenusEligibles = 0;
    for (final r in s.autresRevenus) {
      if (!r.type.name.startsWith('bourseEchelon')) autresRevenusEligibles += r.montantMensuel;
    }
    final ressourcesMensuelles = (s.revenuActiviteDemandeur + s.revenuActiviteConjoint +
        autresRevenusEligibles - s.pensionAlimentaireVersee).clamp(0.0, double.infinity);
    final rAnnuel = ressourcesMensuelles * 12;

    final nbFoyer = (estCouple ? 2 : 1) + nbPac;
    double r0;
    if (nbFoyer <= 8) {
      r0 = _aplR0[nbFoyer]?.toDouble() ?? _aplR0[8]!.toDouble();
    } else {
      r0 = _aplR0[8]! + (nbFoyer - 8) * _aplR0ParPersonneSupp;
    }
    final ressourceBase = (rAnnuel - r0).clamp(0.0, double.infinity);

    // TF identique à APL
    double tf;
    if (nbPac == 0) {
      tf = estCouple ? _aplTF[1] : _aplTF[0];
    } else if (nbPac + 2 <= _aplTF.length) {
      tf = _aplTF[nbPac + 1];
    } else {
      tf = _aplTF.last + (nbPac - 6) * _aplTFParPacSupp;
    }

    // TL : référence LR = plafond Zone 2 ALS (pas APL)
    final plafondsAlsZ2 = _aplPlafonds['zone_2']!; // harmonisation 2018 : même référence qu'APL
    double lr;
    if (nbPac == 0) {
      lr = estCouple ? plafondsAlsZ2[1] : plafondsAlsZ2[0];
    } else if (nbPac == 1) {
      lr = plafondsAlsZ2[2];
    } else {
      lr = plafondsAlsZ2[2] + plafondsAlsZ2[3] * (nbPac - 1);
    }
    final rl = lr > 0 ? (l / lr) : 0.0;
    double tl;
    if (rl < 0.45) {
      tl = 0;
    } else if (rl < 0.75) {
      tl = 0.0045 * (rl - 0.45);
    } else {
      tl = 0.0045 * 0.30 + 0.0068 * (rl - 0.75);
    }
    tl = (tl * 1000).round() / 1000;

    final tp = tf + tl;
    final p0 = (0.085 * (l + c)).clamp(_aplP0Plancher, double.infinity);
    final pp = p0 + tp * ressourceBase;
    var aide = l + c - pp - _aplDeduction;
    // Seuil de versement ALS/ALF : 10€ (vs 0€ pour APL)
    final montant = aide >= 10.0 ? _arrondi(aide) : 0.0;

    if (montant > 0) {
      return (montant,
        '$typeAide estimée : $montant\u20AC/mois. '
        'Logement non conventionné. '
        'L=${l.toStringAsFixed(2)}\u20AC (plafond ${loyerPlafond.toStringAsFixed(2)}\u20AC), '
        'C=${c.toStringAsFixed(2)}\u20AC, PP=${pp.toStringAsFixed(2)}\u20AC. '
        '[$sourceLeg]');
    } else {
      return (0.0,
        '$typeAide : non éligible. '
        'PP (${pp.toStringAsFixed(2)}\u20AC) ≥ L+C-5 ou montant < 10\u20AC. [$sourceLeg]');
    }
  }

  // ============================================================
  // MVA — Majoration pour la Vie Autonome
  // Art. L821-1-2 CSS — Décret n° 2026-229
  // ============================================================

  (double, String) _calculerMVA(Situation s, {required double aahMontant, required double aplMontant}) {
    if (s.tauxHandicap == null || s.tauxHandicap! < 80) {
      return (0.0, 'MVA : taux d\'incapacité < 80%. [${sourcesLegales['mva']}]');
    }
    if (aahMontant < _aahMontantMax) {
      return (0.0, 'MVA : AAH non au taux plein (${aahMontant.toStringAsFixed(2)}€ < ${_aahMontantMax}€). [${sourcesLegales['mva']}]');
    }
    if (s.revenuActiviteDemandeur > 0) {
      return (0.0, 'MVA : revenus d\'activité déclarés — non éligible. [${sourcesLegales['mva']}]');
    }
    if (s.situationVie != SituationVie.autonome) {
      return (0.0, 'MVA : vie en institution ou hébergé — non éligible. [${sourcesLegales['mva']}]');
    }
    // Condition : percevoir une aide au logement (APL/ALS/ALF), pas simplement être locataire
    if (aplMontant <= 0) {
      return (0.0, 'MVA : aucune aide au logement perçue — non éligible. '
          'La MVA nécessite de percevoir l\'APL, l\'ALS ou l\'ALF. [${sourcesLegales['mva']}]');
    }

    return (_mvaMontant, 'MVA : ${_mvaMontant}\u20AC/mois — AAH taux plein + vie autonome + aide au logement. [${sourcesLegales['mva']}]');
  }

  // ============================================================
  // ASF — Allocation de Soutien Familial
  // Art. L523-1 CSS — Barèmes 01/04/2026
  // ============================================================

  (double, String) _calculerASF(Situation s) {
    if (!s.parentIsole) {
      return (0.0, 'ASF : non parent isolé. [${sourcesLegales['asf']}]');
    }
    if (s.nombreEnfants == 0) {
      return (0.0, 'ASF : aucun enfant à charge. [${sourcesLegales['asf']}]');
    }

    final estVeuf = s.statutConjugal == StatutConjugal.veuf;
    if (!estVeuf && !s.pensionAlimentaireNonPercue) {
      return (0.0, 'ASF : pension alimentaire perçue ou non applicable. [${sourcesLegales['asf']}]');
    }

    final montant = _arrondi(_asfMontantParEnfant * s.nombreEnfants);
    final raison = estVeuf ? 'orphelin(s)' : 'pension non versée par l\'autre parent';
    return (montant, 'ASF : ${montant.toStringAsFixed(2)}€/mois '
        '(${s.nombreEnfants} enfant(s), $raison). '
        '[${sourcesLegales['asf']}]');
  }

  // ============================================================
  // UTILITAIRES
  // ============================================================

  double _arrondi(double v) => (v * 100).round() / 100;
}
