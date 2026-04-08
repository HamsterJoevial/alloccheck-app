import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'core/theme/app_theme.dart';
import 'core/models/situation.dart';
import 'core/models/droits_result.dart';
import 'core/services/payment_service.dart';
import 'features/simulation/screens/simulation_screen.dart';
import 'features/results/screens/results_screen.dart';
import 'features/letter/screens/letter_screen.dart';
import 'features/legal/screens/privacy_screen.dart';
import 'features/legal/screens/legal_mentions_screen.dart';
import 'features/legal/screens/terms_screen.dart';

/// Token Stripe capturé avant tout initialisation Flutter (avant réécriture URL).
String? _stripeReturnToken;

void main() {
  if (kIsWeb) {
    _stripeReturnToken = Uri.base.queryParameters['paid'];
    usePathUrlStrategy();
  }
  runApp(const AllocCheckApp());
}

class AllocCheckApp extends StatelessWidget {
  const AllocCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AllocCheck',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/simulation':
            return MaterialPageRoute(
              builder: (_) => const SimulationScreen(),
            );
          case '/results':
            final situation = settings.arguments as Situation;
            return MaterialPageRoute(
              builder: (_) => ResultsScreen(situation: situation),
            );
          case '/letter':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => LetterScreen(
                situation: args['situation'] as Situation,
                droits: args['droits'] as DroitsResult,
                ecart: args['ecart'] as EcartResult,
              ),
            );
          case '/privacy':
            return MaterialPageRoute(
              builder: (_) => const PrivacyScreen(),
            );
          case '/legal':
            return MaterialPageRoute(
              builder: (_) => const LegalMentionsScreen(),
            );
          case '/terms':
            return MaterialPageRoute(
              builder: (_) => const TermsScreen(),
            );
          default:
            return MaterialPageRoute(
              builder: (_) => const HomeScreen(),
            );
        }
      },
    );
  }
}

/// Écran d'accueil
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Situation? _lastSimulation;
  DateTime? _lastSimulationDate;

  @override
  void initState() {
    super.initState();
    _checkPaymentReturn();
    _loadLastSimulation();
  }

  /// Détecte le retour depuis Stripe (?paid=TOKEN) et restaure la simulation.
  Future<void> _checkPaymentReturn() async {
    final justUnlocked = await PaymentService.checkUrlAndUnlock(
      urlToken: _stripeReturnToken,
    );
    _stripeReturnToken = null; // consommé
    if (!justUnlocked) return;

    final situation = await PaymentService.getSavedSituation();
    if (!mounted) return;

    if (situation == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Accès débloqué ! Lancez une simulation pour voir votre rapport complet.'),
          duration: Duration(seconds: 5),
          backgroundColor: Color(0xFF059669),
        ),
      );
      return;
    }

    await PaymentService.clearSavedSituation();
    if (!mounted) return;
    Navigator.of(context).pushNamed('/results', arguments: situation);
  }

  Future<void> _loadLastSimulation() async {
    final sim = await PaymentService.getLastSimulation();
    final date = await PaymentService.getLastSimulationDate();
    if (mounted) {
      setState(() {
        _lastSimulation = sim;
        _lastSimulationDate = date;
      });
    }
  }

  void _resumeLastSimulation() {
    if (_lastSimulation == null) return;
    Navigator.of(context).pushNamed('/results', arguments: _lastSimulation);
  }

  String _formatRelativeDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    if (diff.inDays == 1) return 'hier';
    return 'il y a ${diff.inDays} jours';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              // Logo / Header
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.verified_user,
                  size: 40,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'AllocCheck',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Vérifiez vos droits CAF\nen 3 minutes',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStat(context, '10 Mrd\u20AC', 'de droits non\nréclamés/an'),
                  _buildStat(context, '8%', 'd\'erreurs dans\nles calculs CAF'),
                  _buildStat(context, '13,5M', 'de foyers\nallocataires'),
                ],
              ),

              const Spacer(),

              // Reprendre la dernière simulation
              if (_lastSimulation != null && _lastSimulationDate != null) ...[
                InkWell(
                  onTap: _resumeLastSimulation,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.history, size: 18, color: AppTheme.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reprendre votre dernière simulation',
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      color: AppTheme.primary,
                                    ),
                              ),
                              Text(
                                _formatRelativeDate(_lastSimulationDate!),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, size: 18, color: AppTheme.primary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // CTA
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pushNamed('/simulation'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  child: Text(_lastSimulation != null ? 'Nouvelle simulation' : 'Vérifier vos droits'),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Gratuit — Sans inscription',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Outil d\'aide à la compréhension de vos droits.\nNe constitue pas un conseil juridique.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 10),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pushNamed('/legal'),
                    child: Text(
                      'Mentions légales',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 10,
                            color: AppTheme.textSecondary,
                            decoration: TextDecoration.underline,
                          ),
                    ),
                  ),
                  Text(
                    ' · ',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pushNamed('/terms'),
                    child: Text(
                      'CGU',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 10,
                            color: AppTheme.textSecondary,
                            decoration: TextDecoration.underline,
                          ),
                    ),
                  ),
                  Text(
                    ' · ',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pushNamed('/privacy'),
                    child: Text(
                      'Confidentialité',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 10,
                            color: AppTheme.textSecondary,
                            decoration: TextDecoration.underline,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
