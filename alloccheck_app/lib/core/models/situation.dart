/// Modèle de situation personnelle pour le calcul des droits CAF
class Situation {
  final SituationFamiliale situationFamiliale;
  final int nombreEnfants;
  final List<int> agesEnfants;
  final bool parentIsole;

  final double revenuActiviteDemandeur;
  final double revenuActiviteConjoint;
  final double autresRevenus;

  final ZoneLogement zoneLogement;
  final double loyerMensuel;
  final StatutLogement statutLogement;

  final int? tauxHandicap;

  final Map<String, double> montantPercu;

  const Situation({
    required this.situationFamiliale,
    required this.nombreEnfants,
    this.agesEnfants = const [],
    this.parentIsole = false,
    required this.revenuActiviteDemandeur,
    this.revenuActiviteConjoint = 0,
    this.autresRevenus = 0,
    required this.zoneLogement,
    required this.loyerMensuel,
    required this.statutLogement,
    this.tauxHandicap,
    this.montantPercu = const {},
  });

  Map<String, dynamic> toJson() => {
        'situation_familiale': situationFamiliale.value,
        'nombre_enfants': nombreEnfants,
        'ages_enfants': agesEnfants,
        'parent_isole': parentIsole,
        'revenu_activite_demandeur': revenuActiviteDemandeur,
        'revenu_activite_conjoint': revenuActiviteConjoint,
        'autres_revenus': autresRevenus,
        'zone_logement': zoneLogement.value,
        'loyer_mensuel': loyerMensuel,
        'statut_logement': statutLogement.value,
        if (tauxHandicap != null) 'taux_handicap': tauxHandicap,
        if (montantPercu.isNotEmpty) 'montant_percu': montantPercu,
      };
}

enum SituationFamiliale {
  seul('seul'),
  couple('couple');

  final String value;
  const SituationFamiliale(this.value);
}

enum ZoneLogement {
  zone1('zone_1'),
  zone2('zone_2'),
  zone3('zone_3');

  final String value;
  const ZoneLogement(this.value);
}

enum StatutLogement {
  locataire('locataire'),
  proprietaire('proprietaire'),
  heberge('heberge');

  final String value;
  const StatutLogement(this.value);
}
