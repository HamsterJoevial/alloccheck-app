import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/droits_result.dart';
import '../../../core/models/situation.dart';
import '../../../core/theme/app_theme.dart';

/// Écran de génération de courrier de contestation
class LetterScreen extends StatefulWidget {
  final Situation situation;
  final DroitsResult droits;
  final EcartResult ecart;

  const LetterScreen({
    super.key,
    required this.situation,
    required this.droits,
    required this.ecart,
  });

  @override
  State<LetterScreen> createState() => _LetterScreenState();
}

class _LetterScreenState extends State<LetterScreen> {
  String? _selectedAide;
  String _letterType = 'reclamation_gracieuse';

  // Infos pour le courrier
  final _nomController = TextEditingController();
  final _adresseController = TextEditingController();
  final _departementController = TextEditingController();

  @override
  void dispose() {
    _nomController.dispose();
    _adresseController.dispose();
    _departementController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Filtrer les aides avec un écart positif
    final aidesContestables = widget.ecart.ecarts.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(title: const Text('Contester')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Générer un courrier de contestation',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Choisissez l\'aide à contester et le type de recours.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            // Choix de l'aide à contester
            Text('Aide à contester :', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...aidesContestables.map((entry) {
              final aide = entry.key;
              final ecart = entry.value;
              final label = AppTheme.aideLabels[aide] ?? aide;
              final color = AppTheme.aideColors[aide] ?? AppTheme.primary;
              final icon = AppTheme.aideIcons[aide] ?? Icons.euro;
              final isSelected = _selectedAide == aide;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? color : AppTheme.border,
                    width: isSelected ? 2 : 1,
                  ),
                  color: isSelected ? color.withValues(alpha: 0.05) : null,
                ),
                child: RadioListTile<String>(
                  value: aide,
                  groupValue: _selectedAide,
                  onChanged: (v) => setState(() => _selectedAide = v),
                  title: Row(
                    children: [
                      Icon(icon, color: color, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(label)),
                      Text(
                        '+${ecart.toStringAsFixed(2)}\u20AC/mois',
                        style: TextStyle(
                          color: AppTheme.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text('soit ${(ecart * 12).toStringAsFixed(0)}\u20AC/an manquants'),
                  activeColor: color,
                ),
              );
            }),

            const SizedBox(height: 24),

            // Type de recours
            Text('Type de recours :', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _buildRecoursTile(
              'reclamation_gracieuse',
              'Réclamation gracieuse',
              'Premier recours — courrier à votre CAF demandant un réexamen. '
                  'Délai de réponse : 2 mois.',
            ),
            const SizedBox(height: 8),
            _buildRecoursTile(
              'saisine_cra',
              'Saisine de la CRA',
              'Commission de Recours Amiable — si la réclamation gracieuse '
                  'a été refusée ou sans réponse sous 2 mois. '
                  'Art. R142-1 à R142-8 CSS.',
            ),

            const SizedBox(height: 24),

            // Informations personnelles pour le courrier
            Text('Vos coordonnées :', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nomController,
              decoration: const InputDecoration(labelText: 'Nom complet'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _adresseController,
              decoration: const InputDecoration(labelText: 'Adresse postale'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _departementController,
              decoration: const InputDecoration(
                labelText: 'Département de votre CAF',
                hintText: 'Ex: Moselle, Paris, Rhône...',
              ),
            ),

            const SizedBox(height: 24),

            // Disclaimer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.gavel, size: 16, color: AppTheme.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppConstants.letterDisclaimer,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // CTA
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectedAide != null && _nomController.text.isNotEmpty
                    ? _generateLetter
                    : null,
                icon: const Icon(Icons.description),
                label: Text('Générer le courrier — ${AppConstants.letterPrice}\u20AC'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
              ),
            ),

            const SizedBox(height: 8),
            Center(
              child: Text(
                'Le courrier sera généré en PDF, prêt à envoyer.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecoursTile(String value, String title, String description) {
    final isSelected = _letterType == value;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppTheme.primary : AppTheme.border,
        ),
        color: isSelected ? AppTheme.primary.withValues(alpha: 0.05) : null,
      ),
      child: RadioListTile<String>(
        value: value,
        groupValue: _letterType,
        onChanged: (v) => setState(() => _letterType = v!),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(description, style: const TextStyle(fontSize: 12)),
        activeColor: AppTheme.primary,
      ),
    );
  }

  void _generateLetter() {
    // TODO: Intégrer Claude API via Supabase Edge Function
    // Pour l'instant, afficher un message de confirmation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Courrier en préparation'),
        content: Text(
          'Le courrier de ${_letterType == 'reclamation_gracieuse' ? 'réclamation gracieuse' : 'saisine CRA'} '
          'pour ${AppTheme.aideLabels[_selectedAide]} sera généré.\n\n'
          'Écart contesté : +${widget.ecart.ecarts[_selectedAide]?.toStringAsFixed(2)}\u20AC/mois\n'
          'soit ${((widget.ecart.ecarts[_selectedAide] ?? 0) * 12).toStringAsFixed(0)}\u20AC/an.\n\n'
          'Cette fonctionnalité nécessite la connexion au backend (Supabase + Claude API).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }
}
