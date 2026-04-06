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

  // Garde et congé parental (CMG, PAJE, PreParE)
  final ModeGarde modeGarde;
  final CongeParental congeParental;
  final bool gardeAlternee;

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
    this.modeGarde = ModeGarde.aucun,
    this.congeParental = CongeParental.aucun,
    this.gardeAlternee = false,
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

  /// Sérialisation complète pour persistence localStorage (PaymentService)
  Map<String, dynamic> toJsonFull() => {
        'sf': situationFamiliale.name,
        'ne': nombreEnfants,
        'ae': agesEnfants,
        'pi': parentIsole,
        'srd': sourceRevenuDemandeur?.name,
        'rad': revenuActiviteDemandeur,
        'src': sourceRevenuConjoint?.name,
        'rac': revenuActiviteConjoint,
        'ar': autresRevenus
            .map((r) => {'t': r.type.name, 'm': r.montantMensuel})
            .toList(),
        'zl': zoneLogement.name,
        'lm': loyerMensuel,
        'sl': statutLogement.name,
        'th': tauxHandicap,
        'mg': modeGarde.name,
        'cp': congeParental.name,
        'ga': gardeAlternee,
        'mp': montantPercu,
      };

  factory Situation.fromJson(Map<String, dynamic> j) => Situation(
        situationFamiliale: SituationFamiliale.values
            .firstWhere((e) => e.name == j['sf']),
        nombreEnfants: j['ne'] as int,
        agesEnfants: List<int>.from(j['ae'] ?? []),
        parentIsole: j['pi'] as bool? ?? false,
        sourceRevenuDemandeur: j['srd'] != null
            ? SourceRevenuActivite.values
                .firstWhere((e) => e.name == j['srd'])
            : null,
        revenuActiviteDemandeur: (j['rad'] as num).toDouble(),
        sourceRevenuConjoint: j['src'] != null
            ? SourceRevenuActivite.values
                .firstWhere((e) => e.name == j['src'])
            : null,
        revenuActiviteConjoint: (j['rac'] as num? ?? 0).toDouble(),
        autresRevenus: (j['ar'] as List<dynamic>? ?? []).map((r) {
          final map = r as Map<String, dynamic>;
          return AutreRevenu(
            type: TypeAutreRevenu.values
                .firstWhere((e) => e.name == map['t']),
            montantMensuel: (map['m'] as num).toDouble(),
          );
        }).toList(),
        zoneLogement:
            ZoneLogement.values.firstWhere((e) => e.name == j['zl']),
        loyerMensuel: (j['lm'] as num).toDouble(),
        statutLogement:
            StatutLogement.values.firstWhere((e) => e.name == j['sl']),
        tauxHandicap: j['th'] as int?,
        modeGarde: j['mg'] != null
            ? ModeGarde.values.firstWhere((e) => e.name == j['mg'])
            : ModeGarde.aucun,
        congeParental: j['cp'] != null
            ? CongeParental.values.firstWhere((e) => e.name == j['cp'])
            : CongeParental.aucun,
        gardeAlternee: j['ga'] as bool? ?? false,
        montantPercu: j['mp'] != null
            ? Map<String, double>.from((j['mp'] as Map)
                .map((k, v) => MapEntry(k as String, (v as num).toDouble())))
            : {},
      );
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
enum ModeGarde {
  aucun,
  assistanteMaternelle,
  creche,
  gardeADomicile,
}

enum CongeParental {
  aucun,
  tauxPlein,
  tauxDemi,
}

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
    description: 'Indemnité France Travail — montant sur votre notification',
    icon: '🏢',
    montantFixe: null, // variable selon salaire précédent
    saisieRequise: true,
  ),
  ass(
    label: 'ASS (Allocation de Solidarité Spécifique)',
    description: '18,43\u20AC/jour — montant fixe national',
    icon: '📋',
    montantFixe: 552.90, // 18.43 × 30 jours
    saisieRequise: false, // MONTANT FIXE — pas de saisie
  ),
  pensionRetraite(
    label: 'Pension de retraite',
    description: 'Retraite de base + complémentaire',
    icon: '👴',
    montantFixe: null,
    saisieRequise: true,
  ),
  pensionInvaliditeCat1(
    label: 'Pension d\'invalidité — Catégorie 1',
    description: '30% du salaire moyen des 10 meilleures années — max 1 099,80\u20AC/mois',
    icon: '🏥',
    montantFixe: null,
    saisieRequise: true, // variable selon salaire, mais cadré par le max
  ),
  pensionInvaliditeCat2(
    label: 'Pension d\'invalidité — Catégorie 2',
    description: '50% du salaire moyen des 10 meilleures années — max 1 833,00\u20AC/mois',
    icon: '🏥',
    montantFixe: null,
    saisieRequise: true,
  ),
  pensionInvaliditeCat3(
    label: 'Pension d\'invalidité — Catégorie 3',
    description: 'Cat. 2 + majoration tierce personne — max 3 064,54\u20AC/mois',
    icon: '🏥',
    montantFixe: null,
    saisieRequise: true,
  ),
  pensionAlimentaire(
    label: 'Pension alimentaire reçue',
    description: 'Montant fixé par le juge ou accord amiable',
    icon: '💰',
    montantFixe: null,
    saisieRequise: true,
  ),
  renteAccident(
    label: 'Rente accident du travail / maladie pro',
    description: 'Montant sur votre notification CPAM',
    icon: '⚕️',
    montantFixe: null,
    saisieRequise: true,
  ),
  revenusFonciers(
    label: 'Revenus fonciers (loyers perçus)',
    description: 'Revenus locatifs nets mensuels',
    icon: '🏠',
    montantFixe: null,
    saisieRequise: true,
  ),
  revenusCapitaux(
    label: 'Revenus de capitaux (intérêts, dividendes)',
    description: 'Placements, livrets, actions — montant mensuel moyen',
    icon: '📈',
    montantFixe: null,
    saisieRequise: true,
  ),
  bourseEchelon0(
    label: 'Bourse CROUS — Échelon 0 bis',
    description: '1 454\u20AC/an = 121\u20AC/mois — montant fixe national',
    icon: '🎓',
    montantFixe: 121.17, // 1454/12
    saisieRequise: false,
  ),
  bourseEchelon1(
    label: 'Bourse CROUS — Échelon 1',
    description: '2 163\u20AC/an = 180\u20AC/mois — montant fixe national',
    icon: '🎓',
    montantFixe: 180.25,
    saisieRequise: false,
  ),
  bourseEchelon2(
    label: 'Bourse CROUS — Échelon 2',
    description: '3 071\u20AC/an = 256\u20AC/mois — montant fixe national',
    icon: '🎓',
    montantFixe: 255.92,
    saisieRequise: false,
  ),
  bourseEchelon3(
    label: 'Bourse CROUS — Échelon 3',
    description: '3 931\u20AC/an = 328\u20AC/mois — montant fixe national',
    icon: '🎓',
    montantFixe: 327.58,
    saisieRequise: false,
  ),
  bourseEchelon4(
    label: 'Bourse CROUS — Échelon 4',
    description: '4 789\u20AC/an = 399\u20AC/mois — montant fixe national',
    icon: '🎓',
    montantFixe: 399.08,
    saisieRequise: false,
  ),
  bourseEchelon5(
    label: 'Bourse CROUS — Échelon 5',
    description: '5 551\u20AC/an = 463\u20AC/mois — montant fixe national',
    icon: '🎓',
    montantFixe: 462.58,
    saisieRequise: false,
  ),
  bourseEchelon6(
    label: 'Bourse CROUS — Échelon 6',
    description: '5 880\u20AC/an = 490\u20AC/mois — montant fixe national',
    icon: '🎓',
    montantFixe: 490.00,
    saisieRequise: false,
  ),
  bourseEchelon7(
    label: 'Bourse CROUS — Échelon 7',
    description: '6 335\u20AC/an = 528\u20AC/mois — montant fixe national',
    icon: '🎓',
    montantFixe: 527.92,
    saisieRequise: false,
  ),
  indemnitesJournalieres(
    label: 'Indemnités journalières maladie',
    description: 'Montant sur votre décompte CPAM',
    icon: '🤒',
    montantFixe: null,
    saisieRequise: true,
  ),
  autreRevenu(
    label: 'Autre revenu régulier',
    description: 'Tout autre revenu non listé ci-dessus',
    icon: '📝',
    montantFixe: null,
    saisieRequise: true,
  );

  final String label;
  final String description;
  final String icon;
  final double? montantFixe; // null = montant variable, l'user doit saisir
  final bool saisieRequise; // false = montant fixe connu, on coche et c'est tout
  const TypeAutreRevenu({
    required this.label,
    required this.description,
    required this.icon,
    this.montantFixe,
    required this.saisieRequise,
  });
}
