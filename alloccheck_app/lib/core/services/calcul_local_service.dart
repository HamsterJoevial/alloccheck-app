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
  // Parent isolé : +128.57% base, +14.28% par enfant suppl.
  static const double _rsaMajorationIsolementBase = 0.5; // = couple rate for parent isolé
  static const double _rsaMajorationIsolementParEnfant = 0.4; // par enfant
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

  // --- APL (art. L841-1 CCH, barèmes 01/10/2025 gelés 2026) ---
  // Loyers plafonds par zone et par nombre de personnes
  static const Map<String, Map<int, double>> _aplLoyerPlafond = {
    'zone_1': {1: 333.14, 2: 401.78, 3: 454.10, 0: 65.89}, // 0 = supplément par pers.
    'zone_2': {1: 290.34, 2: 355.38, 3: 399.89, 0: 58.21},
    'zone_3': {1: 272.12, 2: 329.88, 3: 369.88, 0: 53.01},
  };
  static const double _aplChargesForfaitaires = 60.59; // montant unique 2026
  static const double _aplParticipationBase = 37.87;
  static const double _aplSeuilMinimum = 15.0; // en dessous = pas versé

  // --- ALLOCATIONS FAMILIALES (Instruction DSS/2B/2026/46, art. L512-1 CSS) ---
  // BMAF = 478.16€
  static const double _afBase2Enfants = 153.01; // 31.95% BMAF
  static const double _afBase3Enfants = 350.79; // 73.36% BMAF
  static const double _afSupplementParEnfant = 197.77; // 41.41% BMAF
  // ATTENTION : majoration âge = 18+ ans depuis 01/03/2026 (plus 14+)
  static const double _afMajoration18Plus = 75.53; // tranche 1 max
  // Plafonds de ressources (revenu net catégoriel N-2), revalorisés +1.8% au 01/01/2026
  static const double _afPlafondTranche1_2enfants = 78565; // montant plein
  static const double _afPlafondTranche2_2enfants = 104719; // montant divisé par 2
  // Au-delà tranche 2 : montant divisé par 4
  static const double _afSupplementPlafondParEnfant = 6105; // par enfant au-delà de 2

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

  // --- PAJE base (CAF.fr, barèmes 2026) ---
  static const double _pajeTauxPlein = 185.54;
  static const double _pajeTauxPartiel = 92.77;
  // Plafonds annuels couple (1 enfant → +, index = nombreEnfants-1 capped)
  static const List<double> _pajePlafondCouple = [43681, 52958, 62234];
  static const double _pajePlafondCoupleParEnfantSupp = 9277;
  // Plafonds annuels isolé
  static const List<double> _pajePlafondIsole = [34681, 43957, 53234];
  static const double _pajePlafondIsoleParEnfantSupp = 9277;

  // --- Complément Familial (CAF.fr, barèmes 2026) ---
  static const double _cfMontantMajore = 260.57;  // revenus ≤ 25 000€/an
  static const double _cfMontantNormal = 173.71;  // revenus ≤ 43 000€/an
  static const double _cfSeuilMajore = 25000.0;
  static const double _cfSeuilNormal = 43000.0;

  // --- PreParE (CAF.fr, barèmes 2026) ---
  static const double _prepareTauxPlein = 396.01;
  static const double _prepareTauxDemi = 256.01;

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
  };

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

    final aah = _calculerAAH(situation);
    final apl = _calculerAPL(situation);
    final af = _calculerAF(situation);

    // RSA : l'AAH est une ressource (art. R262-11 CASF)
    final rsa = _calculerRSA(situation, aahMensuel: aah.$1, percoitApl: apl.$1 > 0);

    final prime = _calculerPrimeActivite(situation);

    // Aides famille (portées depuis BudgetBébé)
    final cmg = _calculerCMG(situation);
    final paje = _calculerPAJE(situation);
    final cf = _calculerCF(situation);
    final prepare = _calculerPreParE(situation);
    final ars = _calculerARS(situation);

    final droits = DroitsResult(
      rsa: rsa.$1,
      apl: apl.$1,
      primeActivite: prime.$1,
      af: af.$1,
      aah: aah.$1,
      cmg: cmg.$1,
      paje: paje.$1,
      cf: cf.$1,
      prepare: prepare.$1,
      ars: ars.$1,
      total: rsa.$1 + apl.$1 + prime.$1 + af.$1 + aah.$1 + cmg.$1 + paje.$1 + cf.$1 + prepare.$1 + ars.$1,
      details: {
        'rsa': rsa.$2,
        'apl': apl.$2,
        'prime_activite': prime.$2,
        'af': af.$2,
        'aah': aah.$2,
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
          'Ce calcul est indicatif et peut différer du calcul officiel de la CAF.',
      suggestions: _suggestionsAides(situation, droits),
    );
  }

  // ============================================================
  // CMG — Art. L531-5 CSS (porté depuis BudgetBébé)
  // ============================================================

  (double, String) _calculerCMG(Situation s) {
    if (s.modeGarde == ModeGarde.aucun) {
      return (0.0, 'CMG : aucun mode de garde renseigné. [${sourcesLegales['cmg']}]');
    }
    // Éligible uniquement si au moins un enfant < 6 ans
    final aEnfantMoins6 = s.agesEnfants.any((a) => a < 6);
    if (!aEnfantMoins6 && s.nombreEnfants > 0) {
      return (0.0, 'CMG : aucun enfant de moins de 6 ans. [${sourcesLegales['cmg']}]');
    }
    if (s.nombreEnfants == 0) {
      return (0.0, 'CMG : aucun enfant. [${sourcesLegales['cmg']}]');
    }

    final revenusAnnuels = (s.revenuActiviteDemandeur + s.revenuActiviteConjoint + s.totalAutresRevenus) * 12;
    final key = s.modeGarde == ModeGarde.assistanteMaternelle
        ? 'assistante_maternelle'
        : s.modeGarde == ModeGarde.creche
            ? 'creche'
            : 'garde_domicile';

    final tranches = _cmgMontants[key]!;
    double montantBrut;
    String tranche;
    if (revenusAnnuels <= _cmgSeuil1) {
      montantBrut = tranches[0];
      tranche = 'tranche 1 (≤ ${_cmgSeuil1.toStringAsFixed(0)}€/an)';
    } else if (revenusAnnuels <= _cmgSeuil2) {
      montantBrut = tranches[1];
      tranche = 'tranche 2 (≤ ${_cmgSeuil2.toStringAsFixed(0)}€/an)';
    } else {
      montantBrut = tranches[2];
      tranche = 'tranche 3 (> ${_cmgSeuil2.toStringAsFixed(0)}€/an)';
    }

    final montant = _arrondi(s.gardeAlternee ? montantBrut / 2 : montantBrut);
    final modeLabel = s.modeGarde == ModeGarde.assistanteMaternelle
        ? 'assistante maternelle'
        : s.modeGarde == ModeGarde.creche
            ? 'crèche'
            : 'garde à domicile';

    return (
      montant,
      'CMG ($modeLabel) : $montant€/mois — $tranche'
          '${s.gardeAlternee ? ' (garde alternée ÷2)' : ''}. '
          '[${sourcesLegales['cmg']}]'
    );
  }

  // ============================================================
  // PAJE base — Art. L531-2 CSS (porté depuis BudgetBébé)
  // ============================================================

  (double, String) _calculerPAJE(Situation s) {
    final aEnfantMoins3 = s.agesEnfants.any((a) => a < 3);
    if (!aEnfantMoins3 && s.nombreEnfants > 0) {
      return (0.0, 'PAJE : aucun enfant de moins de 3 ans. [${sourcesLegales['paje']}]');
    }
    if (s.nombreEnfants == 0) {
      return (0.0, 'PAJE : aucun enfant. [${sourcesLegales['paje']}]');
    }

    final revenusAnnuels = (s.revenuActiviteDemandeur + s.revenuActiviteConjoint + s.totalAutresRevenus) * 12;
    final isole = s.situationFamiliale == SituationFamiliale.seul;
    final plafonds = isole ? _pajePlafondIsole : _pajePlafondCouple;
    final suppParEnfant = isole ? _pajePlafondIsoleParEnfantSupp : _pajePlafondCoupleParEnfantSupp;

    final idx = (s.nombreEnfants - 1).clamp(0, plafonds.length - 1);
    final plafondBase = plafonds[idx];
    final extraEnfants = s.nombreEnfants > plafonds.length ? (s.nombreEnfants - plafonds.length) * suppParEnfant : 0.0;
    final plafond = plafondBase + extraEnfants;

    if (revenusAnnuels > plafond * 2) {
      return (0.0, 'PAJE : revenus (${revenusAnnuels.toStringAsFixed(0)}€/an) > 2× plafond. [${sourcesLegales['paje']}]');
    }

    final montant = revenusAnnuels <= plafond ? _pajeTauxPlein : _pajeTauxPartiel;
    final taux = revenusAnnuels <= plafond ? 'taux plein' : 'taux partiel';

    return (
      montant,
      'PAJE base : ${montant.toStringAsFixed(2)}€/mois ($taux — enfant < 3 ans). '
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
    // Tous les enfants doivent avoir entre 3 et 21 ans
    final enfantsEligibles = s.agesEnfants.where((a) => a >= 3 && a <= 21).length;
    if (s.agesEnfants.isNotEmpty && enfantsEligibles < 3) {
      return (0.0, 'CF : 3 enfants entre 3 et 21 ans requis. [${sourcesLegales['cf']}]');
    }

    final revenusAnnuels = (s.revenuActiviteDemandeur + s.revenuActiviteConjoint + s.totalAutresRevenus) * 12;

    if (revenusAnnuels > _cfSeuilNormal) {
      return (0.0, 'CF : revenus > plafond (${_cfSeuilNormal.toStringAsFixed(0)}€/an). [${sourcesLegales['cf']}]');
    }

    final montantBrut = revenusAnnuels <= _cfSeuilMajore ? _cfMontantMajore : _cfMontantNormal;
    final montant = _arrondi(s.gardeAlternee ? montantBrut / 2 : montantBrut);
    final niveau = revenusAnnuels <= _cfSeuilMajore ? 'majoré' : 'normal';

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

    // CMG — si enfant < 6 ans
    final enfantsMoins6 = s.agesEnfants.where((a) => a < 6).length;
    if (enfantsMoins6 > 0) {
      suggestions.add(AideSuggestion(
        titre: 'CMG — Complément Mode de Garde',
        description:
            '${enfantsMoins6 > 1 ? '$enfantsMoins6 enfants < 6 ans. ' : ''}'
            'Aide pour garde par assistante maternelle, crèche ou garde à domicile. '
            'Jusqu\'à 1 842€/mois selon la solution de garde et vos revenus.',
        source: 'CAF.fr — à demander directement sur votre espace allocataire',
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

    // Majoration parent isolé (art. L262-9 CASF)
    if (s.parentIsole && s.situationFamiliale == SituationFamiliale.seul && s.nombreEnfants > 0) {
      forfaitaire = _rsaBase * (1 + _rsaMajorationIsolementBase);
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

    // Ressources du foyer :
    // - Revenus d'activité + autres revenus
    // - AAH comptée comme ressource (art. R262-11 CASF) → NON-CUMUL RSA + AAH
    final ressourcesActivite = s.revenuActiviteDemandeur + s.revenuActiviteConjoint + s.totalAutresRevenus;
    final ressources = ressourcesActivite + aahMensuel;

    // RSA = forfaitaire - ressources - forfait logement
    final rsa = (forfaitaire - ressources - forfaitLogement).clamp(0.0, double.infinity);
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

  (double, String) _calculerAPL(Situation s) {
    if (s.statutLogement != StatutLogement.locataire || s.loyerMensuel == 0) {
      return (0.0, 'APL : non éligible (non locataire ou loyer nul). [${sourcesLegales['apl']}]');
    }

    final nbPersonnes = (s.situationFamiliale == SituationFamiliale.couple ? 2 : 1) + s.nombreEnfants;
    final plafonds = _aplLoyerPlafond[s.zoneLogement.value]!;

    // Loyer plafonné selon zone et composition
    double loyerPlafond;
    if (nbPersonnes <= 3) {
      loyerPlafond = plafonds[nbPersonnes]!;
    } else {
      loyerPlafond = plafonds[3]! + plafonds[0]! * (nbPersonnes - 3);
    }
    final loyerRetenu = s.loyerMensuel.clamp(0.0, loyerPlafond);

    // Charges forfaitaires
    final charges = _aplChargesForfaitaires;

    // Ressources
    final ressourcesMensuelles = s.revenuActiviteDemandeur + s.revenuActiviteConjoint + s.totalAutresRevenus;
    final ressourcesAnnuelles = ressourcesMensuelles * 12;

    // Calcul simplifié : APL = (loyer retenu + charges) × taux - participation personnelle
    final tauxParticipation = (0.005 + ressourcesAnnuelles / 100000).clamp(0.0, 0.95);
    final participation = _aplParticipationBase + tauxParticipation * (loyerRetenu + charges);
    var apl = (loyerRetenu + charges) * 0.95 - participation;
    apl = apl.clamp(0.0, double.infinity);

    // Seuil minimum
    final montant = apl < _aplSeuilMinimum ? 0.0 : _arrondi(apl);

    final detail = montant > 0
        ? 'APL estimée : $montant\u20AC/mois. '
            'Loyer retenu : ${loyerRetenu.toStringAsFixed(2)}\u20AC '
            '(plafond ${s.zoneLogement.value} : ${loyerPlafond.toStringAsFixed(2)}\u20AC). '
            '[${sourcesLegales['apl']}]'
        : 'APL : montant < ${_aplSeuilMinimum.toStringAsFixed(0)}\u20AC (seuil non-versement) '
            'ou non éligible. [${sourcesLegales['apl']}]';

    return (montant, detail);
  }

  // ============================================================
  // PRIME D'ACTIVITÉ — Art. L841-3 CSS
  // ============================================================

  (double, String) _calculerPrimeActivite(Situation s) {
    final revenusActivite = s.revenuActiviteDemandeur + s.revenuActiviteConjoint;
    if (revenusActivite == 0) {
      return (0.0, 'Prime d\'activité : non éligible (aucun revenu d\'activité). '
          '[${sourcesLegales['prime_activite']}]');
    }

    // Montant forfaitaire majoré
    var forfaitaire = _primeBase;
    if (s.situationFamiliale == SituationFamiliale.couple) {
      forfaitaire *= (1 + _primeMajorationCouple);
    }
    for (var i = 0; i < s.nombreEnfants; i++) {
      forfaitaire += _primeBase * (i < 2 ? _primeMajorationEnfant12 : _primeMajorationEnfant3Plus);
    }

    // Bonification individuelle (art. L844-1 CSS)
    var bonification = 0.0;
    for (final revenu in [s.revenuActiviteDemandeur, s.revenuActiviteConjoint]) {
      if (revenu >= _primeSeuilBonifMin) {
        final taux = ((revenu - _primeSeuilBonifMin) / (_primeSeuilBonifMax - _primeSeuilBonifMin)).clamp(0.0, 1.0);
        bonification += taux * _primeBonificationMax;
      }
    }

    // Ressources prises en compte (38% forfait, art. R844-1 CSS)
    final ressources = s.revenuActiviteDemandeur + s.revenuActiviteConjoint + s.totalAutresRevenus;

    // Prime = forfaitaire + 61% revenus activité + bonification - ressources
    final prime = forfaitaire + 0.61 * revenusActivite + bonification - ressources;
    final montant = _arrondi(prime.clamp(0.0, double.infinity));

    final detail = montant > 0
        ? 'Prime d\'activité estimée : $montant\u20AC/mois. '
            'Forfaitaire : ${forfaitaire.toStringAsFixed(2)}\u20AC, '
            'bonification : ${bonification.toStringAsFixed(2)}\u20AC. '
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

    // Modulation selon ressources (plafonds 2026)
    final plafondT1 = _afPlafondTranche1_2enfants + _afSupplementPlafondParEnfant * (s.nombreEnfants - 2).clamp(0, double.infinity);
    final plafondT2 = _afPlafondTranche2_2enfants + _afSupplementPlafondParEnfant * (s.nombreEnfants - 2).clamp(0, double.infinity);

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
    // (pas celles du conjoint — loi du 16 août 2022, effective oct. 2023)
    final ressourcesAnnuellesDemandeur = (s.revenuActiviteDemandeur + s.totalAutresRevenus) * 12;

    // Plafond selon situation (le plafond couple reste pour le calcul mais
    // seules les ressources du demandeur sont comparées)
    var plafond = _aahPlafondSeul;
    plafond += s.nombreEnfants * _aahMajorationEnfant;

    if (ressourcesAnnuellesDemandeur > plafond) {
      return (0.0, 'AAH : ressources annuelles du demandeur '
          '(${ressourcesAnnuellesDemandeur.toStringAsFixed(0)}\u20AC) '
          '> plafond (${plafond.toStringAsFixed(0)}\u20AC). '
          'Note : déconjugalisation — revenus du conjoint non pris en compte. '
          '[${sourcesLegales['aah']}]');
    }

    // AAH = montant max - ressources mensuelles du demandeur
    final aah = (_aahMontantMax - ressourcesAnnuellesDemandeur / 12).clamp(0.0, _aahMontantMax);
    final montant = _arrondi(aah);

    return (
      montant,
      montant > 0
          ? 'AAH : $montant\u20AC/mois (taux ${s.tauxHandicap}%, '
              'montant max ${_aahMontantMax.toStringAsFixed(2)}\u20AC). '
              'Déconjugalisée depuis oct. 2023. '
              '[${sourcesLegales['aah']}]'
          : 'AAH : non éligible au vu de vos ressources. '
              '[${sourcesLegales['aah']}]'
    );
  }

  // ============================================================
  // ÉCART
  // ============================================================

  // ============================================================
  // ARS — Art. L543-1 CSS — Allocation de Rentrée Scolaire
  // Barèmes 2026 : 403,72€ (6-10 ans) / 424,95€ (11-14 ans) / 440,65€ (15-18 ans)
  // Plafonds RFR 2026 : 25 336€ (isolé 1 enfant) / 32 267€ (couple 1 enfant) +8 153€/enfant
  // Note : versement annuel en août — affiché en équivalent mensuel (÷ 12)
  // ============================================================

  (double, String) _calculerARS(Situation s) {
    if (s.nombreEnfants == 0 || s.agesEnfants.isEmpty) {
      return (0.0, 'ARS : aucun enfant. [Art. L543-1 CSS]');
    }

    final revenuAnnuel = (s.revenuActiviteDemandeur + s.revenuActiviteConjoint + s.totalAutresRevenus) * 12;
    final plafondBase = s.parentIsole ? 25336.0 : 32267.0;
    final plafondTotal = plafondBase + (s.nombreEnfants - 1) * 8153.0;

    if (revenuAnnuel > plafondTotal) {
      return (0.0,
          'ARS : revenus au-dessus du plafond (${revenuAnnuel.toStringAsFixed(0)}€ > ${plafondTotal.toStringAsFixed(0)}€). [Art. L543-1 CSS]');
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
        'ARS : ${totalAnnuel.toStringAsFixed(0)}€/an (versé en août) = ${mensuel.toStringAsFixed(0)}€/mois équivalent. [Art. L543-1 CSS]');
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
  // UTILITAIRES
  // ============================================================

  double _arrondi(double v) => (v * 100).round() / 100;
}
