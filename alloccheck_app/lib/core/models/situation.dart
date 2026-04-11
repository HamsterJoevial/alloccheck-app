// Modèle de situation personnelle pour le calcul des droits CAF

class Situation {
  final StatutConjugal statutConjugal;
  final int nombreEnfants;
  final List<int> agesEnfants;

  // Revenus d'activité
  final SourceRevenuActivite? sourceRevenuDemandeur;
  final double revenuActiviteDemandeur;
  final SourceRevenuActivite? sourceRevenuConjoint;
  final double revenuActiviteConjoint;

  // Autres revenus (checklist)
  final List<AutreRevenu> autresRevenus;

  // Pension alimentaire versée (déductible des ressources — Art. R262-6 CASF)
  final double pensionAlimentaireVersee;
  // Pension alimentaire non versée par l'autre parent (ouvre droit ASF)
  final bool pensionAlimentaireNonPercue;

  // Logement
  final ZoneLogement zoneLogement;
  final double loyerMensuel;
  final StatutLogement statutLogement;
  final bool? logementConventionne; // null=inconnu, true=APL, false=ALS/ALF

  // Handicap demandeur
  final int? tauxHandicap;
  final SituationVie situationVie;
  final bool besoinTiercePersonne;

  // Handicap enfants — AEEH (Art. L541-1 CSS)
  // Index correspond à agesEnfants[i] — 0 = non reconnu, 50 = 50-79%, 80 = ≥80%
  final List<int> tauxHandicapEnfants;

  // Garde et congé parental (CMG, PAJE, PreParE)
  final ModeGarde modeGarde;
  final CongeParental congeParental;
  final bool gardeAlternee;

  // Ce que l'utilisateur perçoit actuellement
  final Map<String, double> montantPercu;

  const Situation({
    required this.statutConjugal,
    required this.nombreEnfants,
    this.agesEnfants = const [],
    this.sourceRevenuDemandeur,
    required this.revenuActiviteDemandeur,
    this.sourceRevenuConjoint,
    this.revenuActiviteConjoint = 0,
    this.autresRevenus = const [],
    this.pensionAlimentaireVersee = 0,
    this.pensionAlimentaireNonPercue = false,
    required this.zoneLogement,
    required this.loyerMensuel,
    required this.statutLogement,
    this.logementConventionne,
    this.tauxHandicap,
    this.situationVie = SituationVie.autonome,
    this.besoinTiercePersonne = false,
    this.tauxHandicapEnfants = const [],
    this.modeGarde = ModeGarde.aucun,
    this.congeParental = CongeParental.aucun,
    this.gardeAlternee = false,
    this.montantPercu = const {},
  });

  /// Dérivé du statut conjugal — rétrocompatibilité avec tous les calculs existants
  SituationFamiliale get situationFamiliale {
    if ([StatutConjugal.marie, StatutConjugal.pacse, StatutConjugal.concubin]
        .contains(statutConjugal)) {
      return SituationFamiliale.couple;
    }
    return SituationFamiliale.seul;
  }

  /// Dérivé automatiquement — plus de saisie manuelle
  bool get parentIsole =>
      situationFamiliale == SituationFamiliale.seul && nombreEnfants > 0;

  /// Vrai si au moins un enfant a un taux MDPH ≥ 50% (éligible AEEH)
  bool get aEnfantHandicape => tauxHandicapEnfants.any((t) => t >= 50);

  /// Total des autres revenus mensuels
  double get totalAutresRevenus =>
      autresRevenus.fold(0, (sum, r) => sum + r.montantMensuel);

  Map<String, dynamic> toJson() => {
        'situation_familiale': situationFamiliale.value,
        'statut_conjugal': statutConjugal.name,
        'nombre_enfants': nombreEnfants,
        'ages_enfants': agesEnfants,
        'parent_isole': parentIsole,
        'revenu_activite_demandeur': revenuActiviteDemandeur,
        'revenu_activite_conjoint': revenuActiviteConjoint,
        'autres_revenus': totalAutresRevenus,
        'pension_alimentaire_versee': pensionAlimentaireVersee,
        'zone_logement': zoneLogement.value,
        'loyer_mensuel': loyerMensuel,
        'statut_logement': statutLogement.value,
        if (tauxHandicap != null) 'taux_handicap': tauxHandicap,
        if (montantPercu.isNotEmpty) 'montant_percu': montantPercu,
      };

  /// Sérialisation complète pour persistence localStorage (PaymentService)
  Map<String, dynamic> toJsonFull() => {
        'sc': statutConjugal.name,
        'ne': nombreEnfants,
        'ae': agesEnfants,
        'srd': sourceRevenuDemandeur?.name,
        'rad': revenuActiviteDemandeur,
        'src': sourceRevenuConjoint?.name,
        'rac': revenuActiviteConjoint,
        'ar': autresRevenus
            .map((r) => {'t': r.type.name, 'm': r.montantMensuel})
            .toList(),
        'pav': pensionAlimentaireVersee,
        'panp': pensionAlimentaireNonPercue,
        'zl': zoneLogement.name,
        'lm': loyerMensuel,
        'sl': statutLogement.name,
        'lc': logementConventionne,
        'th': tauxHandicap,
        'sv': situationVie.name,
        'btp': besoinTiercePersonne,
        'the': tauxHandicapEnfants,
        'mg': modeGarde.name,
        'cp': congeParental.name,
        'ga': gardeAlternee,
        'mp': montantPercu,
      };

  factory Situation.fromJson(Map<String, dynamic> j) {
    // Rétrocompatibilité : si 'sc' absent, dériver depuis l'ancien 'sf'
    StatutConjugal sc;
    if (j.containsKey('sc')) {
      sc = StatutConjugal.values.firstWhere((e) => e.name == j['sc'],
          orElse: () => StatutConjugal.celibataire);
    } else if (j.containsKey('sf')) {
      final sf = j['sf'] as String;
      sc = sf == 'couple' ? StatutConjugal.concubin : StatutConjugal.celibataire;
    } else {
      sc = StatutConjugal.celibataire;
    }

    return Situation(
      statutConjugal: sc,
      nombreEnfants: j['ne'] as int,
      agesEnfants: List<int>.from(j['ae'] ?? []),
      sourceRevenuDemandeur: j['srd'] != null
          ? SourceRevenuActivite.values
              .firstWhere((e) => e.name == j['srd'], orElse: () => SourceRevenuActivite.aucun)
          : null,
      revenuActiviteDemandeur: (j['rad'] as num).toDouble(),
      sourceRevenuConjoint: j['src'] != null
          ? SourceRevenuActivite.values
              .firstWhere((e) => e.name == j['src'], orElse: () => SourceRevenuActivite.aucun)
          : null,
      revenuActiviteConjoint: (j['rac'] as num? ?? 0).toDouble(),
      autresRevenus: (j['ar'] as List<dynamic>? ?? []).map((r) {
        final map = r as Map<String, dynamic>;
        return AutreRevenu(
          type: TypeAutreRevenu.values
              .firstWhere((e) => e.name == map['t'], orElse: () => TypeAutreRevenu.autreRevenu),
          montantMensuel: (map['m'] as num).toDouble(),
        );
      }).toList(),
      pensionAlimentaireVersee: (j['pav'] as num? ?? 0).toDouble(),
      pensionAlimentaireNonPercue: j['panp'] as bool? ?? false,
      zoneLogement: ZoneLogement.values.firstWhere((e) => e.name == j['zl'],
          orElse: () => ZoneLogement.zone2),
      loyerMensuel: (j['lm'] as num).toDouble(),
      statutLogement: StatutLogement.values.firstWhere((e) => e.name == j['sl'],
          orElse: () => StatutLogement.locataire),
      logementConventionne: j['lc'] as bool?,
      tauxHandicap: j['th'] as int?,
      situationVie: j['sv'] != null
          ? SituationVie.values.firstWhere((e) => e.name == j['sv'],
              orElse: () => SituationVie.autonome)
          : SituationVie.autonome,
      besoinTiercePersonne: j['btp'] as bool? ?? false,
      tauxHandicapEnfants: List<int>.from(j['the'] ?? []),
      modeGarde: j['mg'] != null
          ? ModeGarde.values.firstWhere((e) => e.name == j['mg'],
              orElse: () => ModeGarde.aucun)
          : ModeGarde.aucun,
      congeParental: j['cp'] != null
          ? CongeParental.values.firstWhere((e) => e.name == j['cp'],
              orElse: () => CongeParental.aucun)
          : CongeParental.aucun,
      gardeAlternee: j['ga'] as bool? ?? false,
      montantPercu: j['mp'] != null
          ? Map<String, double>.from((j['mp'] as Map)
              .map((k, v) => MapEntry(k as String, (v as num).toDouble())))
          : {},
    );
  }
}

/// Statut conjugal détaillé — détermine les droits spécifiques
enum StatutConjugal {
  celibataire('Célibataire'),
  marie('Marié(e)'),
  pacse('Pacsé(e)'),
  concubin('En concubinage'),
  divorce('Divorcé(e)'),
  separe('Séparé(e)'),
  veuf('Veuf(ve)');

  final String label;
  const StatutConjugal(this.label);
}

/// Situation de vie — conditionne MVA/MTP pour les bénéficiaires AAH
enum SituationVie {
  autonome('Vie autonome (logement personnel)'),
  institution('En institution (foyer, MAS, etc.)'),
  chezParent('Hébergé(e) chez un parent/proche');

  final String label;
  const SituationVie(this.label);
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
  tauxPlein,    // cessation totale — 459.69€ (ou 745.45€ si 3+ enfants)
  tauxDemi,     // temps partiel ≤ 50% — 297.17€
  tauxPartiel,  // temps partiel 50-80% — 171.42€
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
    montantFixe: null,
    saisieRequise: true,
  ),
  ass(
    label: 'ASS (Allocation de Solidarité Spécifique)',
    description: '19,48\u20AC/jour — montant fixe national (avril 2026)',
    icon: '📋',
    montantFixe: 584.40,
    saisieRequise: false,
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
    saisieRequise: true,
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
    montantFixe: 121.17,
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
  final double? montantFixe;
  final bool saisieRequise;
  const TypeAutreRevenu({
    required this.label,
    required this.description,
    required this.icon,
    this.montantFixe,
    required this.saisieRequise,
  });
}
