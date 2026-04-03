/// Constantes de l'application AllocCheck
class AppConstants {
  AppConstants._();

  static const String appName = 'AllocCheck';
  static const String appTagline = 'Vérifie tes droits CAF';

  // Supabase — à configurer via .env
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-project.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your-anon-key',
  );

  // Edge Functions
  static const String calculateRightsFunction = 'calculate-rights';
  static const String generateLetterFunction = 'generate-letter';
  static const String generatePdfFunction = 'generate-pdf';

  // Pricing
  static const double reportPrice = 4.99;
  static const double letterPrice = 4.99;
  static const double subscriptionPrice = 3.99;

  // Disclaimers
  static const String calculDisclaimer =
      'Calcul indicatif basé sur les barèmes publics 2026. '
      'Peut différer du calcul officiel de la CAF.';

  static const String letterDisclaimer =
      'Ce courrier est un modèle à adapter à votre situation personnelle. '
      'Il ne constitue pas un conseil juridique.';

  static const String generalDisclaimer =
      'AllocCheck est un outil d\'aide à la compréhension de vos droits. '
      'Il ne constitue pas un conseil juridique.';
}
