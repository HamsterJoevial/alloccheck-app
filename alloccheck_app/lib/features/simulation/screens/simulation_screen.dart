import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/situation.dart';
import '../../../core/theme/app_theme.dart';

/// Écran principal de simulation — formulaire multi-étapes
/// Principe : maximum de choix à cocher, minimum de saisie libre.
/// On ne demande que ce que l'État ne peut pas connaître.
class SimulationScreen extends StatefulWidget {
  const SimulationScreen({super.key});

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  static const int _totalSteps = 4;

  // Step 1 — Situation familiale
  SituationFamiliale _situationFamiliale = SituationFamiliale.seul;
  int _nombreEnfants = 0;
  bool _parentIsole = false;
  final List<int> _agesEnfants = [];

  // Step 2 — Revenus
  SourceRevenuActivite _sourceRevenuDemandeur = SourceRevenuActivite.aucun;
  final _revenuDemandeurController = TextEditingController();
  SourceRevenuActivite _sourceRevenuConjoint = SourceRevenuActivite.aucun;
  final _revenuConjointController = TextEditingController();

  // Autres revenus — checklist
  final Map<TypeAutreRevenu, bool> _autresRevenusActifs = {
    for (final type in TypeAutreRevenu.values) type: false,
  };
  final Map<TypeAutreRevenu, TextEditingController> _autresRevenusControllers = {
    for (final type in TypeAutreRevenu.values) type: TextEditingController(),
  };

  // Step 3 — Logement
  ZoneLogement _zoneLogement = ZoneLogement.zone2;
  StatutLogement _statutLogement = StatutLogement.locataire;
  final _loyerController = TextEditingController();

  // Handicap
  bool _aHandicap = false;
  int _tauxHandicap = 80;

  // Step 4 — Montants perçus (comparaison)
  final Map<String, bool> _percuActifs = {
    'rsa': false,
    'apl': false,
    'prime_activite': false,
    'af': false,
    'aah': false,
  };
  final Map<String, TextEditingController> _percuControllers = {
    'rsa': TextEditingController(),
    'apl': TextEditingController(),
    'prime_activite': TextEditingController(),
    'af': TextEditingController(),
    'aah': TextEditingController(),
  };

  @override
  void dispose() {
    _pageController.dispose();
    _revenuDemandeurController.dispose();
    _revenuConjointController.dispose();
    _loyerController.dispose();
    for (final c in _autresRevenusControllers.values) {
      c.dispose();
    }
    for (final c in _percuControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _nextStep() {
    // Validation avant changement d'étape
    final error = _validateCurrentStep();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      _submitSimulation();
    }
  }

  String? _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Famille — toujours valide (défauts OK)
        return null;
      case 1: // Revenus
        if (_sourceRevenuDemandeur != SourceRevenuActivite.aucun) {
          final revenu = double.tryParse(_revenuDemandeurController.text.replaceAll(',', '.')) ?? 0;
          if (revenu <= 0) {
            return 'Indiquez votre revenu mensuel net.';
          }
        }
        // Vérifier que les autres revenus cochés ont un montant saisi (si saisie requise)
        for (final entry in _autresRevenusActifs.entries) {
          if (entry.value && entry.key.saisieRequise) {
            final montant = double.tryParse(
                _autresRevenusControllers[entry.key]!.text.replaceAll(',', '.')) ?? 0;
            if (montant <= 0) {
              return 'Indiquez le montant pour "${entry.key.label}".';
            }
          }
        }
        return null;
      case 2: // Logement
        if (_statutLogement == StatutLogement.locataire) {
          final loyer = double.tryParse(_loyerController.text.replaceAll(',', '.')) ?? 0;
          if (loyer <= 0) {
            return 'Indiquez votre loyer mensuel.';
          }
        }
        return null;
      case 3: // Perçu — toujours valide (rien coché = OK)
        for (final entry in _percuActifs.entries) {
          if (entry.value) {
            final montant = double.tryParse(
                _percuControllers[entry.key]!.text.replaceAll(',', '.')) ?? 0;
            if (montant <= 0) {
              return 'Indiquez le montant perçu pour ${AppTheme.aideLabels[entry.key]}.';
            }
          }
        }
        return null;
      default:
        return null;
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  void _submitSimulation() {
    // Construire la liste des autres revenus cochés
    final autresRevenus = <AutreRevenu>[];
    for (final entry in _autresRevenusActifs.entries) {
      if (entry.value) {
        // Montant fixe = barème national, sinon saisie utilisateur
        final montant = entry.key.montantFixe ??
            (double.tryParse(
                    _autresRevenusControllers[entry.key]!.text.replaceAll(',', '.')) ??
                0);
        if (montant > 0) {
          autresRevenus.add(AutreRevenu(type: entry.key, montantMensuel: montant));
        }
      }
    }

    // Construire les montants perçus
    final montantPercu = <String, double>{};
    for (final entry in _percuActifs.entries) {
      if (entry.value) {
        final montant = double.tryParse(
                _percuControllers[entry.key]!.text.replaceAll(',', '.')) ??
            0;
        montantPercu[entry.key] = montant;
      }
    }

    final situation = Situation(
      situationFamiliale: _situationFamiliale,
      nombreEnfants: _nombreEnfants,
      agesEnfants: _agesEnfants,
      parentIsole: _parentIsole,
      sourceRevenuDemandeur: _sourceRevenuDemandeur,
      revenuActiviteDemandeur:
          double.tryParse(_revenuDemandeurController.text.replaceAll(',', '.')) ?? 0,
      sourceRevenuConjoint: _sourceRevenuConjoint,
      revenuActiviteConjoint:
          double.tryParse(_revenuConjointController.text.replaceAll(',', '.')) ?? 0,
      autresRevenus: autresRevenus,
      zoneLogement: _zoneLogement,
      loyerMensuel: double.tryParse(_loyerController.text.replaceAll(',', '.')) ?? 0,
      statutLogement: _statutLogement,
      tauxHandicap: _aHandicap ? _tauxHandicap : null,
      montantPercu: montantPercu,
    );

    Navigator.of(context).pushNamed('/results', arguments: situation);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ma simulation'),
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousStep,
              )
            : null,
      ),
      body: Column(
        children: [
          _buildProgressBar(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1Famille(),
                _buildStep2Revenus(),
                _buildStep3Logement(),
                _buildStep4Percu(),
              ],
            ),
          ),
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Étape ${_currentStep + 1}/$_totalSteps',
                  style: Theme.of(context).textTheme.bodyMedium),
              Text(_stepLabel(_currentStep),
                  style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_currentStep + 1) / _totalSteps,
            backgroundColor: AppTheme.border,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  String _stepLabel(int step) {
    switch (step) {
      case 0: return 'Famille';
      case 1: return 'Revenus';
      case 2: return 'Logement';
      case 3: return 'Ce que je perçois';
      default: return '';
    }
  }

  // ============================================================
  // STEP 1 — FAMILLE
  // ============================================================

  Widget _buildStep1Famille() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Votre situation familiale',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 24),

          // Situation
          _buildSectionTitle('Vous êtes :'),
          const SizedBox(height: 8),
          _buildRadioList<SituationFamiliale>(
            items: SituationFamiliale.values,
            value: _situationFamiliale,
            labelBuilder: (v) => v == SituationFamiliale.seul ? 'Seul(e)' : 'En couple',
            onChanged: (v) => setState(() => _situationFamiliale = v),
          ),
          const SizedBox(height: 24),

          // Enfants
          _buildSectionTitle('Enfants à charge :'),
          const SizedBox(height: 8),
          _buildCounter(
            value: _nombreEnfants,
            onChanged: (v) {
              setState(() {
                _nombreEnfants = v;
                while (_agesEnfants.length < v) { _agesEnfants.add(5); }
                while (_agesEnfants.length > v) { _agesEnfants.removeLast(); }
              });
            },
          ),

          // Âge des enfants (pour majoration AF 14+)
          if (_nombreEnfants > 0) ...[
            const SizedBox(height: 16),
            _buildSectionTitle('Âge de chaque enfant :'),
            const SizedBox(height: 8),
            ...List.generate(_nombreEnfants, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text('Enfant ${i + 1} :', style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(width: 12),
                  _buildAgeSelector(
                    value: _agesEnfants[i],
                    onChanged: (v) => setState(() => _agesEnfants[i] = v),
                  ),
                ],
              ),
            )),
          ],

          // Parent isolé
          if (_situationFamiliale == SituationFamiliale.seul && _nombreEnfants > 0) ...[
            const SizedBox(height: 16),
            _buildCheckTile(
              'Parent isolé',
              'Vous élevez seul(e) vos enfants (majoration RSA)',
              _parentIsole,
              (v) => setState(() => _parentIsole = v),
            ),
          ],

          // Handicap
          const SizedBox(height: 24),
          _buildCheckTile(
            'Situation de handicap',
            'Taux d\'incapacité reconnu par la MDPH',
            _aHandicap,
            (v) => setState(() => _aHandicap = v),
          ),
          if (_aHandicap) ...[
            const SizedBox(height: 12),
            _buildSectionTitle('Taux d\'incapacité :'),
            const SizedBox(height: 8),
            _buildRadioList<int>(
              items: const [50, 80],
              value: _tauxHandicap >= 80 ? 80 : 50,
              labelBuilder: (v) => v == 50
                  ? 'Entre 50% et 79% (AAH sous conditions)'
                  : '80% ou plus (AAH pleine)',
              onChanged: (v) => setState(() => _tauxHandicap = v),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // STEP 2 — REVENUS (checklist)
  // ============================================================

  Widget _buildStep2Revenus() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vos revenus mensuels',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text('Montants nets, après impôts',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),

          // Revenu d'activité demandeur
          _buildSectionTitle('Votre source de revenus principale :'),
          const SizedBox(height: 8),
          _buildRadioList<SourceRevenuActivite>(
            items: SourceRevenuActivite.values,
            value: _sourceRevenuDemandeur,
            labelBuilder: (v) => v.label,
            onChanged: (v) => setState(() => _sourceRevenuDemandeur = v),
          ),

          if (_sourceRevenuDemandeur != SourceRevenuActivite.aucun) ...[
            const SizedBox(height: 12),
            _buildMoneyField('Montant net mensuel', _revenuDemandeurController),
          ],

          // Revenu conjoint
          if (_situationFamiliale == SituationFamiliale.couple) ...[
            const SizedBox(height: 24),
            _buildSectionTitle('Source de revenus du conjoint :'),
            const SizedBox(height: 8),
            _buildRadioList<SourceRevenuActivite>(
              items: SourceRevenuActivite.values,
              value: _sourceRevenuConjoint,
              labelBuilder: (v) => v.label,
              onChanged: (v) => setState(() => _sourceRevenuConjoint = v),
            ),

            if (_sourceRevenuConjoint != SourceRevenuActivite.aucun) ...[
              const SizedBox(height: 12),
              _buildMoneyField('Montant net mensuel conjoint', _revenuConjointController),
            ],
          ],

          // Autres revenus — CHECKLIST
          const SizedBox(height: 24),
          _buildSectionTitle('Autres revenus (cochez ceux qui s\'appliquent) :'),
          const SizedBox(height: 8),

          // Info : les aides calculées automatiquement ne sont pas ici
          if (_aHandicap) ...[
            _buildInfoBox(
              'L\'AAH est calculée automatiquement à partir de votre taux '
              'de handicap et vos ressources. Ne la ressaisissez pas ici.',
            ),
            const SizedBox(height: 12),
          ],

          ..._filteredAutresRevenus().map((type) => _buildAutreRevenuTile(type)),
        ],
      ),
    );
  }

  /// Filtre les autres revenus selon le contexte déjà saisi
  List<TypeAutreRevenu> _filteredAutresRevenus() {
    return TypeAutreRevenu.values.where((type) {
      // Pension d'invalidité : nécessite un historique d'emploi
      // Ne pas montrer si aucun revenu d'activité sélectionné
      if ((type == TypeAutreRevenu.pensionInvaliditeCat1 ||
              type == TypeAutreRevenu.pensionInvaliditeCat2 ||
              type == TypeAutreRevenu.pensionInvaliditeCat3) &&
          _sourceRevenuDemandeur == SourceRevenuActivite.aucun) {
        return false;
      }

      // Bourse étudiante : ne montrer qu'un seul échelon à la fois
      // On les montre tous et l'user coche celui qui correspond
      // Mais on les masque si la personne est en couple avec enfants (peu probable étudiant)

      // ASS : ne pas montrer si la personne a un emploi (ARE et ASS sont exclusifs)
      if (type == TypeAutreRevenu.ass &&
          _sourceRevenuDemandeur != SourceRevenuActivite.aucun) {
        return false;
      }

      // Pension retraite : ne pas montrer si < 60 ans implicitement
      // (on n'a pas l'âge, donc on montre toujours)

      return true;
    }).toList();
  }

  Widget _buildAutreRevenuTile(TypeAutreRevenu type) {
    final isActive = _autresRevenusActifs[type]!;
    final controller = _autresRevenusControllers[type]!;

    return Column(
      children: [
        _buildCheckTile(
          '${type.icon}  ${type.label}',
          type.montantFixe != null
              ? '${type.description} — ${type.montantFixe!.toStringAsFixed(2)}\u20AC/mois'
              : type.description,
          isActive,
          (v) {
            setState(() {
              _autresRevenusActifs[type] = v;
              // Si montant fixe connu, on pré-remplit automatiquement
              if (v && type.montantFixe != null) {
                controller.text = type.montantFixe!.toStringAsFixed(2);
              }
            });
          },
        ),
        // Champ montant UNIQUEMENT si saisie requise (montant variable)
        if (isActive && type.saisieRequise) ...[
          Padding(
            padding: const EdgeInsets.only(left: 48, right: 16, bottom: 12),
            child: _buildMoneyField(
              'Montant mensuel',
              controller,
            ),
          ),
        ],
        // Si montant fixe, afficher un badge de confirmation
        if (isActive && !type.saisieRequise) ...[
          Padding(
            padding: const EdgeInsets.only(left: 48, right: 16, bottom: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppTheme.secondary, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${type.montantFixe!.toStringAsFixed(2)}\u20AC/mois — barème national',
                    style: TextStyle(
                      color: AppTheme.secondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ============================================================
  // STEP 3 — LOGEMENT
  // ============================================================

  Widget _buildStep3Logement() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Votre logement',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 24),

          _buildSectionTitle('Vous êtes :'),
          const SizedBox(height: 8),
          _buildRadioList<StatutLogement>(
            items: StatutLogement.values,
            value: _statutLogement,
            labelBuilder: (v) {
              switch (v) {
                case StatutLogement.locataire: return 'Locataire';
                case StatutLogement.proprietaire: return 'Propriétaire (pas d\'APL)';
                case StatutLogement.heberge: return 'Hébergé(e) gratuitement';
              }
            },
            onChanged: (v) => setState(() => _statutLogement = v),
          ),

          if (_statutLogement == StatutLogement.locataire) ...[
            const SizedBox(height: 16),
            _buildMoneyField('Loyer mensuel hors charges', _loyerController),
          ],

          const SizedBox(height: 24),
          _buildSectionTitle('Zone de votre commune :'),
          const SizedBox(height: 8),
          _buildRadioList<ZoneLogement>(
            items: ZoneLogement.values,
            value: _zoneLogement,
            labelBuilder: (v) {
              switch (v) {
                case ZoneLogement.zone1: return 'Zone 1 — Paris et communes limitrophes';
                case ZoneLogement.zone2: return 'Zone 2 — Agglomérations > 100 000 hab.';
                case ZoneLogement.zone3: return 'Zone 3 — Reste de la France';
              }
            },
            onChanged: (v) => setState(() => _zoneLogement = v),
          ),

          const SizedBox(height: 16),
          _buildInfoBox(
            'En cas de doute sur votre zone, sélectionnez Zone 3 (la plus courante). '
            'Vous pouvez vérifier sur Service-Public.fr avec votre code postal.',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 4 — CE QUE JE PERÇOIS (checklist)
  // ============================================================

  Widget _buildStep4Percu() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ce que la CAF vous verse',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text('Cochez les aides que vous percevez actuellement et indiquez le montant',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),

          // Filtrer les aides selon le contexte
          // AAH : si handicap coché en étape 1, l'app la calcule — pas besoin de la saisir ici
          // AF : si < 2 enfants, pas éligible
          ..._percuActifs.entries.where((entry) {
            if (entry.key == 'aah' && _aHandicap) return false; // calculée auto
            if (entry.key == 'af' && _nombreEnfants < 2) return false; // pas éligible
            return true;
          }).map((entry) {
            final aide = entry.key;
            final isActive = entry.value;
            final color = AppTheme.aideColors[aide] ?? AppTheme.primary;
            final label = AppTheme.aideLabels[aide] ?? aide;
            final icon = AppTheme.aideIcons[aide] ?? Icons.euro;
            final controller = _percuControllers[aide]!;

            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive ? color.withValues(alpha: 0.5) : AppTheme.border,
                    ),
                    color: isActive ? color.withValues(alpha: 0.05) : null,
                  ),
                  child: CheckboxListTile(
                    value: isActive,
                    onChanged: (v) => setState(() => _percuActifs[aide] = v ?? false),
                    title: Row(
                      children: [
                        Icon(icon, color: color, size: 20),
                        const SizedBox(width: 8),
                        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: color,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                if (isActive) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 48, right: 16, bottom: 12),
                    child: _buildMoneyField('Montant reçu / mois', controller),
                  ),
                ],
              ],
            );
          }),

          const SizedBox(height: 16),
          if (_aHandicap) ...[
            _buildInfoBox(
              'L\'AAH est calculée automatiquement à partir de votre taux '
              'de handicap. Elle n\'apparaît pas ici.',
            ),
            const SizedBox(height: 8),
          ],
          _buildInfoBox(
            'Si vous ne percevez aucune aide, laissez tout décoché. '
            'AllocCheck vous dira si vous y avez droit.',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COMPOSANTS RÉUTILISABLES
  // ============================================================

  Widget _buildSectionTitle(String text) {
    return Text(text, style: Theme.of(context).textTheme.titleMedium);
  }

  Widget _buildRadioList<T>({
    required List<T> items,
    required T value,
    required String Function(T) labelBuilder,
    required void Function(T) onChanged,
  }) {
    return Column(
      children: items.map((item) {
        final isSelected = item == value;
        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primary : AppTheme.border,
            ),
            color: isSelected ? AppTheme.primary.withValues(alpha: 0.05) : null,
          ),
          child: RadioListTile<T>(
            value: item,
            groupValue: value,
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
            title: Text(
              labelBuilder(item),
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            activeColor: AppTheme.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCheckTile(
    String title,
    String subtitle,
    bool value,
    void Function(bool) onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? AppTheme.primary : AppTheme.border,
        ),
        color: value ? AppTheme.primary.withValues(alpha: 0.05) : null,
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: (v) => onChanged(v ?? false),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: AppTheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildCounter({required int value, required void Function(int) onChanged}) {
    return Row(
      children: [
        _buildCounterButton(Icons.remove, value > 0, () => onChanged(value - 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text('$value', style: Theme.of(context).textTheme.headlineMedium),
        ),
        _buildCounterButton(Icons.add, value < 10, () => onChanged(value + 1)),
      ],
    );
  }

  Widget _buildCounterButton(IconData icon, bool enabled, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: enabled ? AppTheme.primary : AppTheme.border),
      ),
      child: IconButton(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon, color: enabled ? AppTheme.primary : AppTheme.textSecondary),
      ),
    );
  }

  Widget _buildAgeSelector({required int value, required void Function(int) onChanged}) {
    return DropdownButton<int>(
      value: value.clamp(0, 25),
      items: List.generate(26, (i) => DropdownMenuItem(
        value: i,
        child: Text('$i ans'),
      )),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  Widget _buildMoneyField(String label, TextEditingController controller, {String? hint}) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint ?? '0',
        suffixText: '\u20AC/mois',
      ),
    );
  }

  Widget _buildInfoBox(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppTheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    final isLastStep = _currentStep == _totalSteps - 1;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _nextStep,
            child: Text(isLastStep ? 'Calculer mes droits' : 'Continuer'),
          ),
        ),
      ),
    );
  }
}
