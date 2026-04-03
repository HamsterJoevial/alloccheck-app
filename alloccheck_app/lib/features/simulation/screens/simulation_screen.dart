import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/situation.dart';
import '../../../core/theme/app_theme.dart';

/// Écran principal de simulation — formulaire multi-étapes
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
  final _revenuDemandeurController = TextEditingController();
  final _revenuConjointController = TextEditingController();
  final _autresRevenusController = TextEditingController();

  // Step 3 — Logement
  ZoneLogement _zoneLogement = ZoneLogement.zone2;
  StatutLogement _statutLogement = StatutLogement.locataire;
  final _loyerController = TextEditingController();

  // Step 4 — Montants perçus (comparaison)
  final _percuRsaController = TextEditingController();
  final _percuAplController = TextEditingController();
  final _percuPrimeController = TextEditingController();
  final _percuAfController = TextEditingController();
  final _percuAahController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _revenuDemandeurController.dispose();
    _revenuConjointController.dispose();
    _autresRevenusController.dispose();
    _loyerController.dispose();
    _percuRsaController.dispose();
    _percuAplController.dispose();
    _percuPrimeController.dispose();
    _percuAfController.dispose();
    _percuAahController.dispose();
    super.dispose();
  }

  void _nextStep() {
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
    final situation = Situation(
      situationFamiliale: _situationFamiliale,
      nombreEnfants: _nombreEnfants,
      agesEnfants: _agesEnfants,
      parentIsole: _parentIsole,
      revenuActiviteDemandeur: double.tryParse(_revenuDemandeurController.text) ?? 0,
      revenuActiviteConjoint: double.tryParse(_revenuConjointController.text) ?? 0,
      autresRevenus: double.tryParse(_autresRevenusController.text) ?? 0,
      zoneLogement: _zoneLogement,
      loyerMensuel: double.tryParse(_loyerController.text) ?? 0,
      statutLogement: _statutLogement,
      montantPercu: {
        if (_percuRsaController.text.isNotEmpty)
          'rsa': double.tryParse(_percuRsaController.text) ?? 0,
        if (_percuAplController.text.isNotEmpty)
          'apl': double.tryParse(_percuAplController.text) ?? 0,
        if (_percuPrimeController.text.isNotEmpty)
          'prime_activite': double.tryParse(_percuPrimeController.text) ?? 0,
        if (_percuAfController.text.isNotEmpty)
          'af': double.tryParse(_percuAfController.text) ?? 0,
        if (_percuAahController.text.isNotEmpty)
          'aah': double.tryParse(_percuAahController.text) ?? 0,
      },
    );

    // Naviguer vers l'écran de résultats avec la situation
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
          // Progress indicator
          _buildProgressBar(),
          // Form pages
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
          // Bottom button
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
              Text(
                'Étape ${_currentStep + 1}/$_totalSteps',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                _stepLabel(_currentStep),
                style: Theme.of(context).textTheme.labelLarge,
              ),
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

  Widget _buildStep1Famille() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Votre situation familiale',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),

          // Situation
          Text('Vous êtes :', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _buildChoiceChips(
            ['Seul(e)', 'En couple'],
            _situationFamiliale == SituationFamiliale.seul ? 0 : 1,
            (index) {
              setState(() {
                _situationFamiliale = index == 0
                    ? SituationFamiliale.seul
                    : SituationFamiliale.couple;
              });
            },
          ),
          const SizedBox(height: 24),

          // Enfants
          Text('Nombre d\'enfants à charge :', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                onPressed: _nombreEnfants > 0
                    ? () => setState(() {
                          _nombreEnfants--;
                          if (_agesEnfants.length > _nombreEnfants) {
                            _agesEnfants.removeLast();
                          }
                        })
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text(
                '$_nombreEnfants',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              IconButton(
                onPressed: () => setState(() {
                  _nombreEnfants++;
                  _agesEnfants.add(0);
                }),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),

          // Parent isolé
          if (_situationFamiliale == SituationFamiliale.seul && _nombreEnfants > 0) ...[
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Parent isolé'),
              subtitle: const Text('Majoration si vous élevez seul(e) vos enfants'),
              value: _parentIsole,
              onChanged: (v) => setState(() => _parentIsole = v),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStep2Revenus() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vos revenus mensuels nets',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Indiquez vos revenus nets mensuels (après impôts)',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),

          _buildMoneyField(
            'Vos revenus d\'activité',
            _revenuDemandeurController,
            hint: 'Ex: 1200',
          ),

          if (_situationFamiliale == SituationFamiliale.couple) ...[
            const SizedBox(height: 16),
            _buildMoneyField(
              'Revenus d\'activité du conjoint',
              _revenuConjointController,
              hint: 'Ex: 900',
            ),
          ],

          const SizedBox(height: 16),
          _buildMoneyField(
            'Autres revenus (pensions, rentes...)',
            _autresRevenusController,
            hint: '0',
            required: false,
          ),
        ],
      ),
    );
  }

  Widget _buildStep3Logement() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Votre logement',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),

          // Statut logement
          Text('Vous êtes :', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _buildChoiceChips(
            ['Locataire', 'Propriétaire', 'Hébergé(e)'],
            _statutLogement.index,
            (index) {
              setState(() {
                _statutLogement = StatutLogement.values[index];
              });
            },
          ),
          const SizedBox(height: 24),

          if (_statutLogement == StatutLogement.locataire) ...[
            _buildMoneyField(
              'Loyer mensuel (hors charges)',
              _loyerController,
              hint: 'Ex: 600',
            ),
            const SizedBox(height: 24),
          ],

          // Zone
          Text('Zone de votre logement :', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _buildChoiceChips(
            ['Zone 1\n(Paris/IDF)', 'Zone 2\n(Grandes villes)', 'Zone 3\n(Reste FR)'],
            _zoneLogement.index,
            (index) {
              setState(() {
                _zoneLogement = ZoneLogement.values[index];
              });
            },
          ),
          const SizedBox(height: 12),
          Text(
            'Zone 1 : Paris et communes limitrophes\n'
            'Zone 2 : Agglomérations > 100 000 hab.\n'
            'Zone 3 : Reste de la France',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStep4Percu() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ce que vous percevez',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Indiquez ce que la CAF vous verse actuellement (laissez vide si vous ne percevez pas cette aide)',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),

          _buildPercuField('RSA', _percuRsaController, AppTheme.aideColors['rsa']!),
          const SizedBox(height: 12),
          _buildPercuField('APL', _percuAplController, AppTheme.aideColors['apl']!),
          const SizedBox(height: 12),
          _buildPercuField('Prime d\'activité', _percuPrimeController, AppTheme.aideColors['prime_activite']!),
          const SizedBox(height: 12),
          _buildPercuField('Allocations familiales', _percuAfController, AppTheme.aideColors['af']!),
          const SizedBox(height: 12),
          _buildPercuField('AAH', _percuAahController, AppTheme.aideColors['aah']!),

          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.warning, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ces montants permettent de comparer avec ce que vous devriez percevoir.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPercuField(String label, TextEditingController controller, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
            decoration: InputDecoration(
              labelText: label,
              hintText: '0',
              suffixText: '€/mois',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMoneyField(
    String label,
    TextEditingController controller, {
    String hint = '0',
    bool required = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: '€/mois',
      ),
    );
  }

  Widget _buildChoiceChips(
    List<String> labels,
    int selectedIndex,
    void Function(int) onSelected,
  ) {
    return Wrap(
      spacing: 8,
      children: List.generate(labels.length, (index) {
        final isSelected = index == selectedIndex;
        return ChoiceChip(
          label: Text(
            labels[index],
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          selected: isSelected,
          selectedColor: AppTheme.primary,
          backgroundColor: AppTheme.surface,
          side: BorderSide(color: isSelected ? AppTheme.primary : AppTheme.border),
          onSelected: (_) => onSelected(index),
        );
      }),
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
