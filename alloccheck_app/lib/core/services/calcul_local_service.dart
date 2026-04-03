import '../models/situation.dart';
import '../models/droits_result.dart';

/// Moteur de calcul des droits CAF — 100% local, zéro réseau
/// Basé sur les barèmes publics 2026 (Service-Public.fr)
class CalculLocalService {
  // ============================================================
  // BARÈMES 2026 (revalorisés avril 2026)
  // ============================================================

  static const double _smicMensuelNet = 1426.30;

  // --- RSA ---
  static const double _rsaBase = 635.71;
  static const double _rsaMajorationCouple = 0.5;
  static const double _rsaMajorationEnfant12 = 0.3;
  static const double _rsaMajorationEnfant3Plus = 0.4;
  static const double _rsaMajorationIsolementBase = 0.2857;
  static const double _rsaMajorationIsolementEnfant = 0.1428;
  static const double _rsaForfaitLogement1 = 76.28;
  static const double _rsaForfaitLogement2 = 152.57;
  static const double _rsaForfaitLogement3Plus = 188.81;

  // --- Prime d'activité ---
  static const double _primeBase = 622.63;
  static const double _primeBonificationMax = 181.19;
  static const double _primeTauxRevenus = 0.38;

  // --- APL ---
  static const Map<String, Map<int, double>> _aplLoyerPlafond = {
    'zone_1': {1: 319.87, 2: 391.54, 3: 431.60, 4: 472.82, 0: 42.96},
    'zone_2': {1: 278.28, 2: 340.49, 3: 375.97, 4: 411.37, 0: 37.44},
    'zone_3': {1: 260.40, 2: 318.60, 3: 351.71, 4: 384.82, 0: 35.02},
  };
  static const double _aplParticipationBase = 37.87;

  // --- AF ---
  static const double _afBase2Enfants = 148.52;
  static const double _afBase3Enfants = 338.81;
  static const double _afSupplementParEnfant = 190.29;
  static const double _afMajoration14Plus = 74.26;
  static const double _afPlafondBase2 = 74966;
  static const double _afPlafondInter2 = 99922;

  // --- AAH ---
  static const double _aahMontantMax = 1016.05;
  static const double _aahPlafondSeul = 12193.0;
  static const double _aahPlafondCouple = 22069.0;
  static const double _aahMajorationEnfant = 6096.0;

  // ============================================================
  // CALCUL PRINCIPAL
  // ============================================================

  CalculResponse calculerDroits(Situation situation) {
    final rsa = _calculerRSA(situation);
    final apl = _calculerAPL(situation);
    final prime = _calculerPrimeActivite(situation);
    final af = _calculerAF(situation);
    final aah = _calculerAAH(situation);

    final droits = DroitsResult(
      rsa: rsa.$1,
      apl: apl.$1,
      primeActivite: prime.$1,
      af: af.$1,
      aah: aah.$1,
      total: rsa.$1 + apl.$1 + prime.$1 + af.$1 + aah.$1,
      details: {
        'rsa': rsa.$2,
        'apl': apl.$2,
        'prime_activite': prime.$2,
        'af': af.$2,
        'aah': aah.$2,
      },
    );

    EcartResult? ecart;
    if (situation.montantPercu.isNotEmpty) {
      ecart = _calculerEcart(droits, situation.montantPercu);
    }

    return CalculResponse(
      droits: droits,
      ecart: ecart,
      disclaimer: 'Calcul indicatif basé sur les barèmes publics 2026. '
          'Peut différer du calcul officiel de la CAF.',
    );
  }

  // ============================================================
  // RSA
  // ============================================================

  (double, String) _calculerRSA(Situation s) {
    final nbPersonnes = (s.situationFamiliale == SituationFamiliale.couple ? 2 : 1) + s.nombreEnfants;

    var forfaitaire = _rsaBase;
    if (s.situationFamiliale == SituationFamiliale.couple) {
      forfaitaire *= (1 + _rsaMajorationCouple);
    }
    for (var i = 0; i < s.nombreEnfants; i++) {
      forfaitaire += _rsaBase * (i < 2 ? _rsaMajorationEnfant12 : _rsaMajorationEnfant3Plus);
    }

    if (s.parentIsole && s.situationFamiliale == SituationFamiliale.seul && s.nombreEnfants > 0) {
      forfaitaire *= (1 + _rsaMajorationIsolementBase);
      forfaitaire += _rsaBase * _rsaMajorationIsolementEnfant * (s.nombreEnfants - 1);
    }

    var forfaitLogement = 0.0;
    if (s.statutLogement == StatutLogement.heberge || s.loyerMensuel == 0) {
      if (nbPersonnes == 1) {
        forfaitLogement = _rsaForfaitLogement1;
      } else if (nbPersonnes == 2) {
        forfaitLogement = _rsaForfaitLogement2;
      } else {
        forfaitLogement = _rsaForfaitLogement3Plus;
      }
    }

    final ressources = s.revenuActiviteDemandeur + s.revenuActiviteConjoint + s.autresRevenus;
    final rsa = (forfaitaire - ressources - forfaitLogement).clamp(0, double.infinity);
    final montant = (rsa * 100).round() / 100;

    final detail = montant > 0
        ? 'RSA estimé : ${montant.toStringAsFixed(2)}\u20AC/mois. '
            'Forfaitaire : ${forfaitaire.toStringAsFixed(2)}\u20AC, '
            'ressources : ${ressources.toStringAsFixed(2)}\u20AC.'
        : 'Pas éligible au RSA : vos ressources (${ressources.toStringAsFixed(2)}\u20AC) '
            'dépassent le montant forfaitaire (${forfaitaire.toStringAsFixed(2)}\u20AC).';

    return (montant, detail);
  }

  // ============================================================
  // APL
  // ============================================================

  (double, String) _calculerAPL(Situation s) {
    if (s.statutLogement != StatutLogement.locataire || s.loyerMensuel == 0) {
      return (0, 'APL : non éligible (non locataire ou loyer nul).');
    }

    final nbPersonnes = (s.situationFamiliale == SituationFamiliale.couple ? 2 : 1) + s.nombreEnfants;
    final plafonds = _aplLoyerPlafond[s.zoneLogement.value]!;

    double loyerPlafond;
    if (nbPersonnes <= 4) {
      loyerPlafond = plafonds[nbPersonnes]!;
    } else {
      loyerPlafond = plafonds[4]! + plafonds[0]! * (nbPersonnes - 4);
    }
    final loyerRetenu = s.loyerMensuel.clamp(0, loyerPlafond);

    var charge = 56.22;
    if (nbPersonnes >= 2) {
      charge = 112.44 + 31.50 * (nbPersonnes - 2).clamp(0, double.infinity);
    }

    final ressourcesMensuelles = s.revenuActiviteDemandeur + s.revenuActiviteConjoint + s.autresRevenus;
    final ressourcesAnnuelles = ressourcesMensuelles * 12;

    final tauxParticipation = (0.005 + ressourcesAnnuelles / 100000).clamp(0, 0.95);
    final participation = _aplParticipationBase + tauxParticipation * (loyerRetenu + charge);

    var apl = (loyerRetenu + charge) * 0.95 - participation;
    apl = apl.clamp(0, double.infinity);

    // Seuil minimum 15€
    final montant = apl < 15 ? 0.0 : (apl * 100).round() / 100;

    final detail = montant > 0
        ? 'APL estimée : ${montant.toStringAsFixed(2)}\u20AC/mois. '
            'Loyer retenu : ${loyerRetenu.toStringAsFixed(2)}\u20AC '
            '(plafond ${s.zoneLogement.value} : ${loyerPlafond.toStringAsFixed(2)}\u20AC).'
        : 'APL non éligible ou montant < 15\u20AC (seuil de non-versement).';

    return (montant, detail);
  }

  // ============================================================
  // PRIME D'ACTIVITÉ
  // ============================================================

  (double, String) _calculerPrimeActivite(Situation s) {
    final revenusActivite = s.revenuActiviteDemandeur + s.revenuActiviteConjoint;
    if (revenusActivite == 0) {
      return (0, 'Prime d\'activité : non éligible (aucun revenu d\'activité).');
    }

    var forfaitaire = _primeBase;
    if (s.situationFamiliale == SituationFamiliale.couple) {
      forfaitaire *= (1 + 0.5);
    }
    for (var i = 0; i < s.nombreEnfants; i++) {
      forfaitaire += _primeBase * (i < 2 ? 0.3 : 0.4);
    }

    var bonification = 0.0;
    final seuilBonif = 0.5 * _smicMensuelNet;
    for (final revenu in [s.revenuActiviteDemandeur, s.revenuActiviteConjoint]) {
      if (revenu >= seuilBonif) {
        final taux = ((revenu - seuilBonif) / (_smicMensuelNet - seuilBonif)).clamp(0, 1);
        bonification += taux * _primeBonificationMax;
      }
    }

    final ressources = s.revenuActiviteDemandeur + s.revenuActiviteConjoint + s.autresRevenus;
    final prime = forfaitaire + 0.61 * revenusActivite + bonification - ressources - ressources * _primeTauxRevenus;
    final montant = prime.clamp(0, double.infinity);
    final montantFinal = (montant * 100).round() / 100;

    final detail = montantFinal > 0
        ? 'Prime d\'activité estimée : ${montantFinal.toStringAsFixed(2)}\u20AC/mois. '
            'Forfaitaire : ${forfaitaire.toStringAsFixed(2)}\u20AC, bonification : ${bonification.toStringAsFixed(2)}\u20AC.'
        : 'Prime d\'activité : non éligible (ressources trop élevées).';

    return (montantFinal, detail);
  }

  // ============================================================
  // ALLOCATIONS FAMILIALES
  // ============================================================

  (double, String) _calculerAF(Situation s) {
    if (s.nombreEnfants < 2) {
      return (0, 'Allocations familiales : minimum 2 enfants à charge requis.');
    }

    final ressourcesAnnuelles = (s.revenuActiviteDemandeur + s.revenuActiviteConjoint + s.autresRevenus) * 12;

    var montant = 0.0;
    if (s.nombreEnfants == 2) {
      montant = _afBase2Enfants;
    } else if (s.nombreEnfants == 3) {
      montant = _afBase3Enfants;
    } else {
      montant = _afBase3Enfants + _afSupplementParEnfant * (s.nombreEnfants - 3);
    }

    // Majoration 14+
    var nb14Plus = 0;
    if (s.agesEnfants.isNotEmpty) {
      nb14Plus = s.agesEnfants.where((age) => age >= 14).length;
      if (s.nombreEnfants == 2 && nb14Plus > 0) nb14Plus = (nb14Plus - 1).clamp(0, nb14Plus);
    }
    montant += nb14Plus * _afMajoration14Plus;

    // Modulation ressources
    final plafondBase = _afPlafondBase2 + 6105 * (s.nombreEnfants - 2).clamp(0, double.infinity);
    final plafondInter = _afPlafondInter2 + 6105 * (s.nombreEnfants - 2).clamp(0, double.infinity);

    if (ressourcesAnnuelles > plafondInter) {
      montant /= 4;
    } else if (ressourcesAnnuelles > plafondBase) {
      montant /= 2;
    }

    final montantFinal = (montant * 100).round() / 100;

    return (
      montantFinal,
      montantFinal > 0
          ? 'AF estimées : ${montantFinal.toStringAsFixed(2)}\u20AC/mois pour ${s.nombreEnfants} enfants.'
          : 'Allocations familiales : non éligible.'
    );
  }

  // ============================================================
  // AAH
  // ============================================================

  (double, String) _calculerAAH(Situation s) {
    if (s.tauxHandicap == null || s.tauxHandicap! < 50) {
      return (0, 'AAH : taux d\'incapacité < 50%, non éligible.');
    }

    final ressourcesAnnuelles = (s.revenuActiviteDemandeur + s.revenuActiviteConjoint + s.autresRevenus) * 12;
    var plafond = s.situationFamiliale == SituationFamiliale.couple ? _aahPlafondCouple : _aahPlafondSeul;
    plafond += s.nombreEnfants * _aahMajorationEnfant;

    if (ressourcesAnnuelles > plafond) {
      return (0, 'AAH : ressources annuelles (${ressourcesAnnuelles.toStringAsFixed(0)}\u20AC) > plafond (${plafond.toStringAsFixed(0)}\u20AC).');
    }

    final aah = (_aahMontantMax - ressourcesAnnuelles / 12).clamp(0, _aahMontantMax);
    final montant = (aah * 100).round() / 100;

    return (
      montant,
      montant > 0
          ? 'AAH estimée : ${montant.toStringAsFixed(2)}\u20AC/mois (taux handicap ${s.tauxHandicap}%).'
          : 'AAH : non éligible au vu de vos ressources.'
    );
  }

  // ============================================================
  // ÉCART
  // ============================================================

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
    };

    for (final entry in aides.entries) {
      final theorique = entry.value;
      final recu = percu[entry.key] ?? 0;
      final diff = theorique - recu;
      ecarts[entry.key] = (diff * 100).round() / 100;

      if (diff > 0) {
        ecartTotal += diff;
        if (recu == 0 && theorique > 0) {
          aidesNonReclamees.add(entry.key);
        }
      }
    }

    return EcartResult(
      ecarts: ecarts,
      ecartTotal: (ecartTotal * 100).round() / 100,
      aidesNonReclamees: aidesNonReclamees,
    );
  }
}
