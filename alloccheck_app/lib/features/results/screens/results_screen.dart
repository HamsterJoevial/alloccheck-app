import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/droits_result.dart';
import '../../../core/models/situation.dart';
import '../../../core/services/calcul_service.dart';
import '../../../core/theme/app_theme.dart';

/// Écran de résultats — affiche les droits calculés et l'écart
class ResultsScreen extends StatefulWidget {
  final Situation situation;

  const ResultsScreen({super.key, required this.situation});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  CalculResponse? _response;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  Future<void> _calculate() async {
    try {
      final service = CalculService();
      final response = await service.calculerDroits(widget.situation);
      setState(() {
        _response = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vos droits'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildResults(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
            const SizedBox(height: 16),
            Text('Erreur de calcul', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(_error!, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _calculate();
              },
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    final response = _response!;
    final hasEcart = response.ecart != null && response.ecart!.hasEcart;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total card
          _buildTotalCard(response.droits),

          if (hasEcart) ...[
            const SizedBox(height: 16),
            _buildEcartCard(response.ecart!),
          ],

          const SizedBox(height: 24),

          // Détail par aide
          Text('Détail par aide', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ..._buildAideCards(response.droits, response.ecart),

          const SizedBox(height: 24),

          // Disclaimer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppConstants.calculDisclaimer,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // CTA — Contester si écart
          if (hasEcart) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Navigate to letter generation
                  Navigator.of(context).pushNamed('/letter', arguments: {
                    'situation': widget.situation,
                    'droits': response.droits,
                    'ecart': response.ecart,
                  });
                },
                icon: const Icon(Icons.mail_outline),
                label: const Text('Contester — Générer un courrier'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '${AppConstants.letterPrice}€ par courrier',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],

          // CTA — Rapport PDF
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: Generate PDF report
              },
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Télécharger le rapport PDF'),
            ),
          ),
          Center(
            child: Text(
              '${AppConstants.reportPrice}€',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard(DroitsResult droits) {
    return Card(
      color: AppTheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Vos droits estimés',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              '${droits.total.toStringAsFixed(2)} €/mois',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEcartCard(EcartResult ecart) {
    return Card(
      color: AppTheme.error.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.error.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 32),
            const SizedBox(height: 8),
            Text(
              'Vous pourriez toucher',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              '+${ecart.ecartTotal.toStringAsFixed(2)} €/mois',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.error,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            Text(
              'soit ${(ecart.ecartTotal * 12).toStringAsFixed(0)} €/an',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.error),
            ),
            if (ecart.hasAidesNonReclamees) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${ecart.aidesNonReclamees.length} aide(s) non réclamée(s)',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.warning),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAideCards(DroitsResult droits, EcartResult? ecart) {
    final aides = {
      'rsa': droits.rsa,
      'apl': droits.apl,
      'prime_activite': droits.primeActivite,
      'af': droits.af,
      'aah': droits.aah,
    };

    return aides.entries.where((e) => e.value > 0 || (ecart?.ecarts[e.key] ?? 0) != 0).map((entry) {
      final aide = entry.key;
      final montant = entry.value;
      final ecartMontant = ecart?.ecarts[aide] ?? 0;
      final color = AppTheme.aideColors[aide] ?? AppTheme.primary;
      final label = AppTheme.aideLabels[aide] ?? aide;
      final icon = AppTheme.aideIcons[aide] ?? Icons.euro;
      final detail = droits.details[aide] ?? '';

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(icon, color: color, size: 20),
            ),
            title: Text(label),
            subtitle: Text(
              detail,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${montant.toStringAsFixed(0)} €',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (ecartMontant > 0)
                  Text(
                    '+${ecartMontant.toStringAsFixed(0)} €',
                    style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
}
