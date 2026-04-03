// Modèle de situation personnelle pour le calcul des droits CAF

class Situation {
  final SituationFamiliale situationFamiliale;
  final int nombreEnfants;
  final List<int> agesEnfants;
  final bool parentIsole;

  // Revenus d'activité
  final SourceRevenuActivite? sourceRevenuDemandeur;
  final double revenuActiviteDemandeur;
  final SourceRevenuActivite? sourceRevenuConjoint;
  final double revenuActiviteConjoint;

  // Autres revenus (checklist)
  final List<AutreRevenu> autresRevenus;

  // Logement
  final ZoneLogement zoneLogement;
  final double loyerMensuel;
  final StatutLogement statutLogement;

  // Handicap
  final int? tauxHandicap;

  // Ce que l'utilisateur perçoit actuellement
  final Map<String, double> montantPercu;

  const Situation({
    required this.situationFamiliale,
    required this.nombreEnfants,
    this.agesEnfants = const [],
    this.parentIsole = false,
    this.sourceRevenuDemandeur,
    required this.revenuActiviteDemandeur,
    this.sourceRevenuConjoint,
    this.revenuActiviteConjoint = 0,
    this.autresRevenus = const [],
    required this.zoneLogement,
    required this.loyerMensuel,
    required this.statutLogement,
    this.tauxHandicap,
    this.montantPercu = const {},
  });

  /// Total des autres revenus mensuels
  double get totalAutresRevenus =>
      autresRevenus.fold(0, (sum, r) => sum + r.montantMensuel);

  Map<String, dynamic> toJson() => {
        'situation_familiale': situationFamiliale.value,
        'nombre_enfants': nombreEnfants,
        'ages_enfants': agesEnfants,
        'parent_isole': parentIsole,
        'revenu_activite_demandeur': revenuActiviteDemandeur,
        'revenu_activite_conjoint': revenuActiviteConjoint,
        'autres_revenus': totalAutresRevenus,
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

/// Source du revenu d'activité principal
enum SourceRevenuActivite {
  salarie('Salarié(e)'),
  independant('Indépendant / Auto-entrepreneur'),
  interimaire('Intérimaire'),
  fonctionnaire('Fonctionnaire'),
  aucun('Aucun revenu d\'activité');

  final String label;
  const SourceRevenuActivite(this.label);
}

/// Type de revenu "autre" — checklist exhaustive
class AutreRevenu {
  final TypeAutreRevenu type;
  final double montantMensuel;

  const AutreRevenu({required this.type, required this.montantMensuel});
}

enum TypeAutreRevenu {
  chomage(
    label: 'Allocation chômage (ARE)',
    description: 'Indemnité Pôle Emploi / France Travail',
    icon: '🏢',
    montantTypique: 1028, // moyenne ARE 2026
  ),
  ass(
    label: 'ASS (Allocation de Solidarité Spécifique)',
    description: 'Après épuisement des droits chômage',
    icon: '📋',
    montantTypique: 552, // 18.43€/jour × 30
  ),
  pensionRetraite(
    label: 'Pension de retraite',
    description: 'Retraite de base + complémentaire',
    icon: '👴',
    montantTypique: null,
  ),
  pensionInvalidite(
    label: 'Pension d\'invalidité',
    description: 'Catégorie 1, 2 ou 3',
    icon: '🏥',
    montantTypique: null,
  ),
  pensionAlimentaire(
    label: 'Pension alimentaire reçue',
    description: 'Versée par l\'ex-conjoint',
    icon: '💰',
    montantTypique: null,
  ),
  renteAccident(
    label: 'Rente accident du travail / maladie pro',
    description: 'Versée par la CPAM',
    icon: '⚕️',
    montantTypique: null,
  ),
  revenusFonciers(
    label: 'Revenus fonciers (loyers perçus)',
    description: 'Revenus locatifs nets',
    icon: '🏠',
    montantTypique: null,
  ),
  revenusCapitaux(
    label: 'Revenus de capitaux (intérêts, dividendes)',
    description: 'Placements, livrets, actions',
    icon: '📈',
    montantTypique: null,
  ),
  bourseEtudiante(
    label: 'Bourse étudiante',
    description: 'Bourse sur critères sociaux (CROUS)',
    icon: '🎓',
    montantTypique: null,
  ),
  indemnitesJournalieres(
    label: 'Indemnités journalières maladie',
    description: 'Arrêt maladie (CPAM)',
    icon: '🤒',
    montantTypique: null,
  ),
  autreRevenu(
    label: 'Autre revenu',
    description: 'Tout autre revenu régulier non listé',
    icon: '📝',
    montantTypique: null,
  );

  final String label;
  final String description;
  final String icon;
  final double? montantTypique;
  const TypeAutreRevenu({
    required this.label,
    required this.description,
    required this.icon,
    this.montantTypique,
  });
}
