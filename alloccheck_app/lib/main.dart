import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/models/situation.dart';
import 'features/simulation/screens/simulation_screen.dart';
import 'features/results/screens/results_screen.dart';

void main() {
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
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
                'Vérifie tes droits CAF\nen 3 minutes',
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

              // CTA
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pushNamed('/simulation'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  child: const Text('Vérifier mes droits'),
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
