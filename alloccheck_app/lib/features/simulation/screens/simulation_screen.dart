import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool _showResumeBanner = false;
  Timer? _saveTimer;

  bool get _hasEnfants => _nombreEnfants > 0;
  int get _totalSteps => _hasEnfants ? 5 : 4;

  int _stepOf(String s) {
    switch (s) {
      case 'famille': return 0;
      case 'enfants': return _hasEnfants ? 1 : -1;
      case 'revenus': return _hasEnfants ? 2 : 1;
      case 'logement': return _hasEnfants ? 3 : 2;
      case 'percu': return _hasEnfants ? 4 : 3;
      default: return 0;
    }
  }

  // Step 1 — Situation familiale
  StatutConjugal _statutConjugal = StatutConjugal.celibataire;
  int _nombreEnfants = 0;
  final List<int> _agesEnfants = [];
  bool _versePension = false;
  bool _recoitPension = false;
  bool _pensionNonPercue = false;
  final _pensionVerseeController = TextEditingController();
  final _pensionRecueController = TextEditingController();
  SituationVie _situationVie = SituationVie.autonome;
  bool _besoinTiercePersonne = false;

  bool get _isCouple => [StatutConjugal.marie, StatutConjugal.pacse, StatutConjugal.concubin].contains(_statutConjugal);

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
  final _codePostalController = TextEditingController();
  bool _logementConventionne = true;

  // Garde et congé parental
  ModeGarde _modeGarde = ModeGarde.aucun;
  CongeParental _congeParental = CongeParental.aucun;
  bool _gardeAlternee = false;

  // Handicap demandeur
  bool _aHandicap = false;
  int _tauxHandicap = 80;

  // Handicap enfants — AEEH
  bool _aEnfantHandicap = false;
  final List<int> _tauxHandicapEnfants = [];

  // Step 4 — Montants perçus (comparaison)
  bool _percevaitAAH = false; // case spéciale si handicap coché
  final Map<String, bool> _percuActifs = {
    'rsa': false,
    'apl': false,
    'prime_activite': false,
    'af': false,
    'aah': false,
    'cmg': false,
    'paje': false,
    'cf': false,
    'prepare': false,
    'ars': false,
    'mva': false,
    'asf': false,
    'aeeh': false,
  };
  final Map<String, TextEditingController> _percuControllers = {
    'rsa': TextEditingController(),
    'apl': TextEditingController(),
    'prime_activite': TextEditingController(),
    'af': TextEditingController(),
    'aah': TextEditingController(),
    'cmg': TextEditingController(),
    'paje': TextEditingController(),
    'cf': TextEditingController(),
    'prepare': TextEditingController(),
    'ars': TextEditingController(),
    'mva': TextEditingController(),
    'asf': TextEditingController(),
    'aeeh': TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _pageController.dispose();
    _revenuDemandeurController.dispose();
    _revenuConjointController.dispose();
    _loyerController.dispose();
    _codePostalController.dispose();
    _pensionVerseeController.dispose();
    _pensionRecueController.dispose();
    for (final c in _autresRevenusControllers.values) {
      c.dispose();
    }
    for (final c in _percuControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ============================================================
  // DRAFT — SharedPreferences
  // ============================================================

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 800), _saveDraft);
  }

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final data = <String, dynamic>{
      'statutConjugal': _statutConjugal.name,
      'nombreEnfants': _nombreEnfants,
      'agesEnfants': _agesEnfants,
      'versePension': _versePension,
      'recoitPension': _recoitPension,
      'pensionNonPercue': _pensionNonPercue,
      'pensionVersee': _pensionVerseeController.text,
      'pensionRecue': _pensionRecueController.text,
      'situationVie': _situationVie.name,
      'besoinTiercePersonne': _besoinTiercePersonne,
      'sourceRevenuDemandeur': _sourceRevenuDemandeur.name,
      'revenuDemandeur': _revenuDemandeurController.text,
      'sourceRevenuConjoint': _sourceRevenuConjoint.name,
      'revenuConjoint': _revenuConjointController.text,
      'zoneLogement': _zoneLogement.name,
      'statutLogement': _statutLogement.name,
      'loyer': _loyerController.text,
      'codePostal': _codePostalController.text,
      'logementConventionne': _logementConventionne,
      'modeGarde': _modeGarde.name,
      'congeParental': _congeParental.name,
      'gardeAlternee': _gardeAlternee,
      'aHandicap': _aHandicap,
      'tauxHandicap': _tauxHandicap,
      'percevaitAAH': _percevaitAAH,
      'aEnfantHandicap': _aEnfantHandicap,
      'tauxHandicapEnfants': _tauxHandicapEnfants,
      'autresRevenusActifs': _autresRevenusActifs.map((k, v) => MapEntry(k.name, v)),
      'autresRevenus': _autresRevenusControllers.map((k, v) => MapEntry(k.name, v.text)),
      'percuActifs': Map<String, dynamic>.from(_percuActifs),
      'percuMontants': _percuControllers.map((k, v) => MapEntry(k, v.text)),
    };
    await prefs.setString('sim_draft_v3', jsonEncode(data));
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('sim_draft_v3');
    if (raw == null || raw.isEmpty) return;
    try {
      jsonDecode(raw); // validate JSON
      if (mounted) setState(() => _showResumeBanner = true);
    } catch (_) {
      // Draft corrupt — ignore
    }
  }

  Future<void> _applyDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('sim_draft_v3');
    if (raw == null) return;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      setState(() {
        _statutConjugal = StatutConjugal.values.firstWhere(
          (e) => e.name == data['statutConjugal'], orElse: () => StatutConjugal.celibataire);
        _nombreEnfants = _intOf(data['nombreEnfants'], 0);
        final ages = (data['agesEnfants'] as List?)?.map((e) => _intOf(e, 5)).toList() ?? [];
        _agesEnfants..clear()..addAll(ages);
        _versePension = data['versePension'] as bool? ?? false;
        _recoitPension = data['recoitPension'] as bool? ?? false;
        _pensionNonPercue = data['pensionNonPercue'] as bool? ?? false;
        _pensionVerseeController.text = data['pensionVersee'] as String? ?? '';
        _pensionRecueController.text = data['pensionRecue'] as String? ?? '';
        _situationVie = SituationVie.values.firstWhere(
          (e) => e.name == data['situationVie'], orElse: () => SituationVie.autonome);
        _besoinTiercePersonne = data['besoinTiercePersonne'] as bool? ?? false;
        _sourceRevenuDemandeur = SourceRevenuActivite.values.firstWhere(
          (e) => e.name == data['sourceRevenuDemandeur'], orElse: () => SourceRevenuActivite.aucun);
        _revenuDemandeurController.text = data['revenuDemandeur'] as String? ?? '';
        _sourceRevenuConjoint = SourceRevenuActivite.values.firstWhere(
          (e) => e.name == data['sourceRevenuConjoint'], orElse: () => SourceRevenuActivite.aucun);
        _revenuConjointController.text = data['revenuConjoint'] as String? ?? '';
        _zoneLogement = ZoneLogement.values.firstWhere(
          (e) => e.name == data['zoneLogement'], orElse: () => ZoneLogement.zone2);
        _statutLogement = StatutLogement.values.firstWhere(
          (e) => e.name == data['statutLogement'], orElse: () => StatutLogement.locataire);
        _loyerController.text = data['loyer'] as String? ?? '';
        _codePostalController.text = data['codePostal'] as String? ?? '';
        _logementConventionne = data['logementConventionne'] as bool? ?? true;
        _modeGarde = ModeGarde.values.firstWhere(
          (e) => e.name == data['modeGarde'], orElse: () => ModeGarde.aucun);
        _congeParental = CongeParental.values.firstWhere(
          (e) => e.name == data['congeParental'], orElse: () => CongeParental.aucun);
        _gardeAlternee = data['gardeAlternee'] as bool? ?? false;
        _aHandicap = data['aHandicap'] as bool? ?? false;
        _tauxHandicap = _intOf(data['tauxHandicap'], 80);
        _percevaitAAH = data['percevaitAAH'] as bool? ?? false;
        _aEnfantHandicap = data['aEnfantHandicap'] as bool? ?? false;
        final thEnfants = (data['tauxHandicapEnfants'] as List?)?.map((e) => _intOf(e, 0)).toList() ?? [];
        _tauxHandicapEnfants..clear()..addAll(thEnfants);
        final autresActifs = data['autresRevenusActifs'] as Map?;
        if (autresActifs != null) {
          for (final type in TypeAutreRevenu.values) {
            _autresRevenusActifs[type] = autresActifs[type.name] as bool? ?? false;
          }
        }
        final autresMontants = data['autresRevenus'] as Map?;
        if (autresMontants != null) {
          for (final type in TypeAutreRevenu.values) {
            _autresRevenusControllers[type]!.text = autresMontants[type.name] as String? ?? '';
          }
        }
        final percuActifs = data['percuActifs'] as Map?;
        if (percuActifs != null) {
          for (final key in _percuActifs.keys) {
            _percuActifs[key] = percuActifs[key] as bool? ?? false;
          }
        }
        final percuMontants = data['percuMontants'] as Map?;
        if (percuMontants != null) {
          for (final key in _percuControllers.keys) {
            _percuControllers[key]!.text = percuMontants[key] as String? ?? '';
          }
        }
        _showResumeBanner = false;
      });
    } catch (_) {
      // Draft corrupt — silently ignore
    }
  }

  int _intOf(dynamic v, int def) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    return def;
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sim_draft_v2');
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
    if (_currentStep == _stepOf('famille')) {
      return null; // pension moved to enfants step
    }
    if (_currentStep == _stepOf('enfants') && _hasEnfants) {
      if (_versePension) {
        final montant = double.tryParse(_pensionVerseeController.text.replaceAll(',', '.')) ?? 0;
        if (montant <= 0) return 'Indiquez le montant de la pension alimentaire versée.';
      }
      if (_recoitPension) {
        final montant = double.tryParse(_pensionRecueController.text.replaceAll(',', '.')) ?? 0;
        if (montant <= 0) return 'Indiquez le montant de la pension alimentaire reçue.';
      }
      return null;
    }
    if (_currentStep == _stepOf('revenus')) {
      if (_sourceRevenuDemandeur != SourceRevenuActivite.aucun) {
        final revenu = double.tryParse(_revenuDemandeurController.text.replaceAll(',', '.')) ?? 0;
        if (revenu <= 0) return 'Indiquez votre revenu mensuel net.';
      }
      for (final entry in _autresRevenusActifs.entries) {
        if (entry.value && entry.key.saisieRequise) {
          final montant = double.tryParse(
              _autresRevenusControllers[entry.key]!.text.replaceAll(',', '.')) ?? 0;
          if (montant <= 0) return 'Indiquez le montant pour "${entry.key.label}".';
        }
      }
      return null;
    }
    if (_currentStep == _stepOf('logement')) {
      if (_statutLogement == StatutLogement.locataire) {
        final loyer = double.tryParse(_loyerController.text.replaceAll(',', '.')) ?? 0;
        if (loyer <= 0) return 'Indiquez votre loyer mensuel.';
      }
      return null;
    }
    if (_currentStep == _stepOf('percu')) {
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
    }
    return null;
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

  Future<void> _submitSimulation() async {
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

    // Pension alimentaire reçue (déclarée en Step 1 pour divorcé/séparé)
    if (_recoitPension) {
      final montantRecue = double.tryParse(
              _pensionRecueController.text.replaceAll(',', '.')) ?? 0;
      if (montantRecue > 0) {
        autresRevenus.add(AutreRevenu(
          type: TypeAutreRevenu.pensionAlimentaire,
          montantMensuel: montantRecue,
        ));
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
    // AAH : si l'utilisateur déclare la percevoir, on marque avec le barème max
    // L'écart sera 0 (percé >= théorique dans tous les cas)
    if (_aHandicap && _percevaitAAH) {
      montantPercu['aah'] = 1041.59; // barème max AAH 2026 — Décret n° 2026-229
    }

    final situation = Situation(
      statutConjugal: _statutConjugal,
      nombreEnfants: _nombreEnfants,
      agesEnfants: _agesEnfants,
      sourceRevenuDemandeur: _sourceRevenuDemandeur,
      revenuActiviteDemandeur:
          double.tryParse(_revenuDemandeurController.text.replaceAll(',', '.')) ?? 0,
      sourceRevenuConjoint: _sourceRevenuConjoint,
      revenuActiviteConjoint:
          double.tryParse(_revenuConjointController.text.replaceAll(',', '.')) ?? 0,
      autresRevenus: autresRevenus,
      pensionAlimentaireVersee: _versePension ? (double.tryParse(_pensionVerseeController.text.replaceAll(',', '.')) ?? 0) : 0,
      pensionAlimentaireNonPercue: _pensionNonPercue,
      zoneLogement: _zoneLogement,
      loyerMensuel: double.tryParse(_loyerController.text.replaceAll(',', '.')) ?? 0,
      statutLogement: _statutLogement,
      logementConventionne: _logementConventionne,
      tauxHandicap: _aHandicap ? _tauxHandicap : null,
      situationVie: _situationVie,
      besoinTiercePersonne: _besoinTiercePersonne,
      tauxHandicapEnfants: _aEnfantHandicap ? List<int>.from(_tauxHandicapEnfants) : const [],
      modeGarde: _modeGarde,
      congeParental: _congeParental,
      gardeAlternee: _gardeAlternee,
      montantPercu: montantPercu,
    );

    final simId = DateTime.now().millisecondsSinceEpoch.toString();
    await _clearDraft();
    Navigator.of(context).pushNamed('/results', arguments: {
      'situation': situation,
      'simId': simId,
    });
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
          if (_showResumeBanner) _buildResumeBanner(),
          _buildProgressBar(),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _totalSteps,
              itemBuilder: (context, step) => _buildPageContent(step),
            ),
          ),
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildResumeBanner() {
    return MaterialBanner(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      content: const Text('Vous avez une simulation en cours.'),
      leading: const Icon(Icons.restore, color: AppTheme.primary),
      backgroundColor: AppTheme.primary.withValues(alpha: 0.08),
      actions: [
        TextButton(
          onPressed: () {
            setState(() => _showResumeBanner = false);
            _clearDraft();
          },
          child: const Text('Effacer'),
        ),
        TextButton(
          onPressed: _applyDraft,
          child: const Text('Reprendre', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _buildPageContent(int step) {
    if (step == 0) return _buildStep0Famille();
    if (_hasEnfants && step == 1) return _buildStep1Enfants();
    if (step == _stepOf('revenus')) return _buildStep2Revenus();
    if (step == _stepOf('logement')) return _buildStep3Logement();
    return _buildStep4Percu();
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
    if (step == 0) return 'Famille';
    if (_hasEnfants && step == 1) return 'Enfants';
    if (step == _stepOf('revenus')) return 'Revenus';
    if (step == _stepOf('logement')) return 'Logement';
    if (step == _stepOf('percu')) return 'Ce que je perçois';
    return '';
  }

  // ============================================================
  // STEP 0 — FAMILLE (allégé)
  // ============================================================

  Widget _buildStep0Famille() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Votre situation familiale',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 24),

          // Statut conjugal
          _buildSectionTitle('Votre statut :',
              tooltip: 'Détermine le calcul du RSA, APL et aides familiales.'),
          const SizedBox(height: 8),
          _buildRadioList<StatutConjugal>(
            items: StatutConjugal.values,
            value: _statutConjugal,
            labelBuilder: (v) => v.label,
            onChanged: (v) {
              setState(() => _statutConjugal = v);
              _scheduleSave();
            },
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
                while (_tauxHandicapEnfants.length < v) { _tauxHandicapEnfants.add(0); }
                while (_tauxHandicapEnfants.length > v) { _tauxHandicapEnfants.removeLast(); }
              });
              _scheduleSave();
            },
          ),

          // Veuf(ve) — info pension de réversion
          if (_statutConjugal == StatutConjugal.veuf) ...[
            const SizedBox(height: 16),
            _buildInfoBox('Vous pouvez déclarer une pension de réversion dans la section "Autres revenus" (étape suivante).'),
          ],

          // Handicap adulte
          const SizedBox(height: 24),
          _buildCheckTile(
            'Situation de handicap',
            'Taux d\'incapacité reconnu par la MDPH',
            _aHandicap,
            (v) {
              setState(() {
                _aHandicap = v;
                if (!v) _percevaitAAH = false;
              });
              _scheduleSave();
            },
          ),
          if (_aHandicap) ...[
            const SizedBox(height: 12),
            _buildInfoBox(
              'Le taux d\'incapacité est une donnée de santé protégée (RGPD Art. 9). '
              'En cochant cette case, vous consentez à son utilisation pour le calcul de vos droits. '
              'Cette donnée reste sur votre appareil et n\'est jamais transmise.',
            ),
            const SizedBox(height: 12),
            _buildSectionTitle('Taux d\'incapacité :',
                tooltip: 'Déterminé par la MDPH. 50-79% : AAH sous conditions. 80%+ : AAH taux plein (1 041,59€).'),
            const SizedBox(height: 8),
            _buildRadioList<int>(
              items: const [50, 80],
              value: _tauxHandicap >= 80 ? 80 : 50,
              labelBuilder: (v) => v == 50
                  ? 'Entre 50% et 79% (AAH sous conditions)'
                  : '80% ou plus (AAH pleine)',
              onChanged: (v) {
                setState(() => _tauxHandicap = v);
                _scheduleSave();
              },
            ),
            const SizedBox(height: 12),
            _buildCheckTile(
              'Je perçois déjà l\'AAH',
              'L\'AAH est calculée automatiquement — cochez si vous la touchez déjà',
              _percevaitAAH,
              (v) {
                setState(() => _percevaitAAH = v);
                _scheduleSave();
              },
            ),
            if (_tauxHandicap >= 80) ...[
              const SizedBox(height: 16),
              _buildSectionTitle('Votre situation de vie',
                  tooltip: 'MVA (104,77€/mois) : AAH taux plein + locataire. Non versée en institution.'),
              const SizedBox(height: 8),
              _buildRadioList<SituationVie>(
                items: SituationVie.values,
                value: _situationVie,
                labelBuilder: (v) => v.label,
                onChanged: (v) {
                  setState(() => _situationVie = v);
                  _scheduleSave();
                },
              ),
              if (_situationVie == SituationVie.autonome) ...[
                const SizedBox(height: 8),
                _buildCheckTile(
                  'Besoin d\'une aide humaine au quotidien',
                  'Tierce personne pour les actes essentiels',
                  _besoinTiercePersonne,
                  (v) {
                    setState(() => _besoinTiercePersonne = v);
                    _scheduleSave();
                  },
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }

  // ============================================================
  // STEP 1 — ENFANTS (conditionnel, uniquement si _hasEnfants)
  // ============================================================

  Widget _buildStep1Enfants() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vos enfants',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 24),

          // Âge de chaque enfant
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
                  onChanged: (v) {
                    setState(() => _agesEnfants[i] = v);
                    _scheduleSave();
                  },
                ),
              ],
            ),
          )),

          // Handicap enfant(s) — AEEH
          const SizedBox(height: 24),
          _buildCheckTile(
            'Un ou plusieurs enfants ont un handicap reconnu (MDPH)',
            'Taux d\'incapacité reconnu par la MDPH — ouvre droit à l\'AEEH (148,12€/mois/enfant)',
            _aEnfantHandicap,
            (v) {
              setState(() {
                _aEnfantHandicap = v;
                if (!v) {
                  for (int i = 0; i < _tauxHandicapEnfants.length; i++) {
                    _tauxHandicapEnfants[i] = 0;
                  }
                }
              });
              _scheduleSave();
            },
          ),
          if (_aEnfantHandicap) ...[
            const SizedBox(height: 8),
            _buildInfoBox(
              'L\'AEEH (Allocation d\'Éducation de l\'Enfant Handicapé) est versée '
              'pour chaque enfant de moins de 20 ans avec un taux MDPH ≥ 50%. '
              'Elle n\'est pas cumulable avec la PAJE.',
            ),
            const SizedBox(height: 12),
            ...List.generate(_nombreEnfants, (i) {
              while (_tauxHandicapEnfants.length <= i) { _tauxHandicapEnfants.add(0); }
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Enfant ${i + 1} (${_agesEnfants[i]} ans) — Taux MDPH :',
                        tooltip: 'AEEH : 148,12€/mois/enfant < 20 ans avec taux ≥ 50%. Non cumulable avec PAJE.'),
                    const SizedBox(height: 6),
                    _buildRadioList<int>(
                      items: const [0, 50, 80],
                      value: _tauxHandicapEnfants[i],
                      labelBuilder: (v) => v == 0
                          ? 'Non reconnu ou < 50%'
                          : v == 50
                              ? 'Entre 50% et 79%'
                              : '80% ou plus',
                      onChanged: (v) {
                        setState(() => _tauxHandicapEnfants[i] = v);
                        _scheduleSave();
                      },
                    ),
                  ],
                ),
              );
            }),
          ],

          // Pension alimentaire (divorcé / séparé)
          if ([StatutConjugal.divorce, StatutConjugal.separe].contains(_statutConjugal)) ...[
            const SizedBox(height: 24),
            _buildSectionTitle('Pension alimentaire',
                tooltip: 'Déductible de vos ressources pour RSA, APL et Prime d\'activité.'),
            const SizedBox(height: 8),
            _buildCheckTile(
              'Je verse une pension alimentaire',
              'Montant que vous payez chaque mois à votre ex-conjoint(e)',
              _versePension,
              (v) {
                setState(() => _versePension = v);
                _scheduleSave();
              },
            ),
            if (_versePension) ...[
              const SizedBox(height: 8),
              _buildMoneyField(
                'Montant mensuel versé',
                _pensionVerseeController,
                hint: 'ex : 350',
              ),
            ],
            const SizedBox(height: 8),
            _buildCheckTile(
              'Je reçois une pension alimentaire',
              'Montant versé par votre ex-conjoint(e)',
              _recoitPension,
              (v) {
                setState(() => _recoitPension = v);
                _scheduleSave();
              },
            ),
            if (_recoitPension) ...[
              const SizedBox(height: 8),
              _buildMoneyField(
                'Montant mensuel reçu',
                _pensionRecueController,
                hint: 'ex : 350',
              ),
            ],
            if (!_recoitPension) ...[
              const SizedBox(height: 8),
              _buildCheckTile(
                'Je ne reçois pas la pension qui m\'est due',
                'L\'autre parent devrait verser une pension mais ne la verse pas',
                _pensionNonPercue,
                (v) {
                  setState(() => _pensionNonPercue = v);
                  _scheduleSave();
                },
              ),
              if (_pensionNonPercue)
                _buildInfoBox('Droit à l\'ASF : 200,78€/mois/enfant si l\'autre parent ne verse pas.'),
            ],
          ],

          // Mode de garde (si enfant < 6 ans)
          if (_agesEnfants.any((a) => a < 6)) ...[
            const SizedBox(height: 24),
            _buildSectionTitle('Mode de garde (enfant < 6 ans) :',
                tooltip: 'CMG calculé à l\'heure depuis sept. 2025. Simulateur officiel sur caf.fr.'),
            const SizedBox(height: 8),
            _buildRadioList<ModeGarde>(
              items: ModeGarde.values,
              value: _modeGarde,
              labelBuilder: (v) {
                switch (v) {
                  case ModeGarde.aucun: return 'Aucun / parent présent';
                  case ModeGarde.assistanteMaternelle: return 'Assistante maternelle agréée';
                  case ModeGarde.creche: return 'Crèche collective';
                  case ModeGarde.gardeADomicile: return 'Garde à domicile';
                }
              },
              onChanged: (v) {
                setState(() => _modeGarde = v);
                _scheduleSave();
              },
            ),
            const SizedBox(height: 12),
            _buildSectionTitle('Congé parental :'),
            const SizedBox(height: 8),
            _buildRadioList<CongeParental>(
              items: CongeParental.values,
              value: _congeParental,
              labelBuilder: (v) {
                switch (v) {
                  case CongeParental.aucun: return 'Pas de congé parental';
                  case CongeParental.tauxPlein: return 'Arrêt complet — 459,69€/mois (745,45€ si 3+ enfants)';
                  case CongeParental.tauxDemi: return 'Temps partiel ≤ 50% — 297,17€/mois';
                  case CongeParental.tauxPartiel: return 'Temps partiel 50-80% — 171,42€/mois';
                }
              },
              onChanged: (v) {
                setState(() => _congeParental = v);
                _scheduleSave();
              },
            ),
          ],

          // Garde alternée (divorcé/séparé)
          if ([StatutConjugal.divorce, StatutConjugal.separe].contains(_statutConjugal)) ...[
            const SizedBox(height: 12),
            _buildCheckTile(
              'Garde alternée',
              'Enfant(s) en résidence alternée (divise certaines aides par 2)',
              _gardeAlternee,
              (v) {
                setState(() => _gardeAlternee = v);
                _scheduleSave();
              },
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
          const SizedBox(height: 16),
          _buildInfoBox(
            'Important : la CAF calcule généralement vos droits sur les revenus de l\'année N-2 '
            '(déclarés aux impôts). Les montants saisis ici sont vos revenus actuels — '
            'un écart avec les versements CAF peut être normal.',
          ),
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
          if (_isCouple) ...[
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
          if (_tauxHandicapEnfants.any((t) => t >= 50)) ...[
            _buildInfoBox(
              'L\'AEEH est calculée automatiquement à partir des taux MDPH des enfants. '
              'Ne la ressaisissez pas ici.',
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
      // Pension alimentaire reçue : déjà déclarée en Step 1 pour divorcé/séparé
      if (type == TypeAutreRevenu.pensionAlimentaire && _recoitPension) {
        return false;
      }

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
          _buildSectionTitle('Code postal de votre commune :',
              tooltip: 'Zone 1 : Paris + petite couronne. Zone 2 : grande couronne + agglomérations. Zone 3 : reste.'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _codePostalController,
            keyboardType: TextInputType.number,
            maxLength: 5,
            decoration: const InputDecoration(
              hintText: 'Ex : 57000, 75001, 69003…',
              prefixIcon: Icon(Icons.location_on_outlined),
              counterText: '',
            ),
            onChanged: (val) {
              if (val.length == 5) {
                final zone = _zoneFromCodePostal(val);
                setState(() => _zoneLogement = zone);
              }
            },
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.map_outlined, size: 16, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Zone détectée : ${_zoneLabelCourt(_zoneLogement)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),

          if (_statutLogement == StatutLogement.locataire) ...[
            const SizedBox(height: 16),
            _buildCheckTile(
              'Logement conventionné CAF',
              'HLM ou convention avec la CAF. Si vous ne savez pas, laissez coché. Signé entre le propriétaire et l\'État/CAF — vérifiable sur le bail.',
              _logementConventionne,
              (v) => setState(() => _logementConventionne = v),
            ),
          ],
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

          // Info ARS si enfants 6-18 ans
          if (_agesEnfants.any((a) => a >= 6 && a <= 18)) ...[
            _buildSectionTitle('Aide à la rentrée scolaire (ARS) :',
                tooltip: 'Versée en août pour les 6-18 ans sous conditions de ressources.'),
            const SizedBox(height: 8),
          ],

          // Filtrer les aides selon le contexte
          // AAH : si handicap coché en étape 1, l'app la calcule — pas besoin de la saisir ici
          // AF : si < 2 enfants, pas éligible
          ..._percuActifs.entries.where((entry) {
            if (entry.key == 'aah' && _aHandicap) return false;
            if (entry.key == 'af' && _nombreEnfants < 2) return false;
            if (entry.key == 'cmg' && !(_agesEnfants.any((a) => a < 6) && _modeGarde != ModeGarde.aucun)) return false;
            if (entry.key == 'paje' && !_agesEnfants.any((a) => a < 3)) return false;
            if (entry.key == 'cf' && !(_nombreEnfants >= 3 && _agesEnfants.any((a) => a >= 3 && a <= 21))) return false;
            if (entry.key == 'prepare' && _congeParental == CongeParental.aucun) return false;
            if (entry.key == 'ars' && !_agesEnfants.any((a) => a >= 6 && a <= 18)) return false;
            if (entry.key == 'mva' && !(_aHandicap && _tauxHandicap >= 80)) return false;
            if (entry.key == 'asf' && !(!_isCouple && _nombreEnfants > 0)) return false;
            if (entry.key == 'aeeh' && !_tauxHandicapEnfants.any((t) => t >= 50)) return false;
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

          const SizedBox(height: 8),
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

  /// Mapping code postal → zone APL (source : Arrêté du 01/01/2020 mis à jour)
  /// Zone 1 : Paris (75) + petite couronne (92, 93, 94)
  /// Zone 2 : grandes agglomérations > 100 000 hab.
  /// Zone 3 : reste de la France
  ZoneLogement _zoneFromCodePostal(String cp) {
    if (cp.length < 2) return ZoneLogement.zone3;
    final dep = cp.substring(0, 2);

    // Zone 1 : Paris + petite couronne
    if (dep == '75' || dep == '92' || dep == '93' || dep == '94') {
      return ZoneLogement.zone1;
    }

    // Zone 2 : grande couronne + grandes agglomérations
    // Départements entièrement Zone 2 : 77, 78, 91, 95
    if (dep == '77' || dep == '78' || dep == '91' || dep == '95') {
      return ZoneLogement.zone2;
    }

    // Départements dont la quasi-totalité est Zone 2 (métropoles dominantes)
    const zone2Deps = {
      '06', // Nice + côte
      '13', // Marseille / Aix-en-Provence
      '31', // Toulouse
      '33', // Bordeaux
      '34', // Montpellier
      '35', // Rennes
      '38', // Grenoble
      '44', // Nantes
      '59', // Lille / Roubaix / Valenciennes / Dunkerque
      '67', // Strasbourg
      '69', // Lyon / Villeurbanne
    };
    if (zone2Deps.contains(dep)) return ZoneLogement.zone2;

    // DOM 3 chiffres
    if (cp.startsWith('972') || cp.startsWith('974')) return ZoneLogement.zone2;

    // Agglomérations Zone 2 détectées par code postal précis
    // (départements dont seule la ville-centre est Zone 2)
    const zone2CP = {
      // Tours (37)
      '37000', '37100', '37200',
      // Dijon (21)
      '21000', '21100', '21240',
      // Reims (51)
      '51100', '51430', '51200',
      // Nancy (54)
      '54000', '54100', '54130', '54140', '54180', '54500', '54600',
      // Metz (57) — pas tout le 57
      '57000', '57050', '57070', '57078',
      // Thionville (57)
      '57100', '57130',
      // Lens-Béthune (62)
      '62300', '62400', '62700',
      // Compiègne (60)
      '60200',
      // Clermont-Ferrand (63)
      '63000', '63100', '63170', '63800',
      // Mulhouse (68)
      '68100', '68200', '68390',
      // Annecy (74)
      '74000', '74100', '74370', '74960',
      // Rouen (76)
      '76000', '76100', '76130', '76300',
      // Le Havre (76)
      '76600', '76620',
      // Amiens (80)
      '80000', '80090', '80080', '80440',
      // Toulon (83)
      '83000', '83100', '83200', '83500',
      // Avignon (84)
      '84000', '84140', '84300',
      // La Roche-sur-Yon (85)
      '85000',
      // Orléans (45)
      '45000', '45100', '45140', '45160',
      // Angers (49)
      '49000', '49100', '49130',
      // Brest (29)
      '29200',
      // Caen (14)
      '14000', '14100', '14200',
      // Poitiers (86)
      '86000', '86280',
      // Limoges (87)
      '87000', '87100', '87280',
      // Laon (02)
      '02000',
      // Charleville-Mézières (08)
      '08000',
    };
    if (zone2CP.contains(cp)) return ZoneLogement.zone2;

    // Tout le reste : Zone 3
    return ZoneLogement.zone3;
  }

  String _zoneLabelCourt(ZoneLogement zone) {
    switch (zone) {
      case ZoneLogement.zone1: return 'Zone 1 (Paris / petite couronne)';
      case ZoneLogement.zone2: return 'Zone 2 (grande agglomération)';
      case ZoneLogement.zone3: return 'Zone 3 (reste de la France)';
    }
  }

  Widget _buildSectionTitle(String text, {String? tooltip}) {
    if (tooltip == null) {
      return Text(text, style: Theme.of(context).textTheme.titleMedium);
    }
    return Row(
      children: [
        Expanded(child: Text(text, style: Theme.of(context).textTheme.titleMedium)),
        GestureDetector(
          onTap: () => _showTooltip(text, tooltip),
          child: const Icon(Icons.help_outline, size: 16, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  void _showTooltip(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: Theme.of(context).textTheme.titleSmall),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
