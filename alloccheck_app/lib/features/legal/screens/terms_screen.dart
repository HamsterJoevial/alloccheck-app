import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Conditions generales d'utilisation
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final headStyle = Theme.of(context).textTheme.headlineMedium;
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppTheme.textPrimary,
          height: 1.6,
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Conditions generales d\'utilisation')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Conditions generales d\'utilisation', style: headStyle),
            const SizedBox(height: 8),
            Text(
              'Derniere mise a jour : 6 avril 2026',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            // Objet
            _sectionTitle(context, '1. Objet du service'),
            Text(
              'AllocCheck est un outil d\'aide a la comprehension des droits '
              'aux prestations de la Caisse d\'Allocations Familiales (CAF). '
              'Il permet a l\'utilisateur d\'estimer ses droits et de generer '
              'un courrier de contestation en cas d\'ecart.\n\n'
              'Ce service ne se substitue pas a un conseil juridique '
              'professionnel. Les informations fournies sont a titre indicatif.',
              style: bodyStyle,
            ),
            const SizedBox(height: 20),

            // Prix
            _sectionTitle(context, '2. Prix et paiement'),
            Text(
              'La simulation est gratuite et accessible sans inscription.\n\n'
              'L\'acces au rapport detaille et au courrier de contestation '
              'est soumis a un paiement unique de 2,99 euros TTC. Le paiement '
              'est effectue via Stripe. Une fois le paiement valide, l\'acces '
              'est permanent sur l\'appareil utilise.',
              style: bodyStyle,
            ),
            const SizedBox(height: 20),

            // Retractation
            _sectionTitle(context, '3. Droit de retractation'),
            Text(
              'Conformement a l\'article L221-28 du Code de la consommation, '
              'le droit de retractation ne s\'applique pas aux contrats de '
              'fourniture de contenu numerique non fourni sur un support '
              'materiel dont l\'execution a commence avec l\'accord prealable '
              'et expres du consommateur.\n\n'
              'En procedant au paiement, l\'utilisateur accepte que le '
              'contenu numerique (rapport detaille et courrier) lui soit '
              'fourni immediatement et renonce expressement a son droit de '
              'retractation.',
              style: bodyStyle,
            ),
            const SizedBox(height: 20),

            // Limitation de responsabilite
            _sectionTitle(context, '4. Limitation de responsabilite'),
            Text(
              'Les calculs effectues par AllocCheck sont des estimations '
              'basees sur les baremes officiels publies au Journal Officiel. '
              'Ils peuvent differer du calcul reel effectue par la CAF, '
              'notamment en raison de situations particulieres non couvertes '
              'par l\'outil.\n\n'
              'L\'editeur ne saurait etre tenu responsable des ecarts entre '
              'les estimations fournies et les montants reellement verses '
              'par la CAF, ni des consequences de decisions prises sur la '
              'base de ces estimations.',
              style: bodyStyle,
            ),
            const SizedBox(height: 20),

            // Donnees
            _sectionTitle(context, '5. Donnees personnelles'),
            Text(
              'Le traitement des donnees personnelles est decrit dans notre '
              'politique de confidentialite, accessible depuis l\'application.',
              style: bodyStyle,
            ),
            const SizedBox(height: 20),

            // Modifications
            _sectionTitle(context, '6. Modification des CGU'),
            Text(
              'L\'editeur se reserve le droit de modifier les presentes '
              'conditions generales d\'utilisation a tout moment. Les '
              'modifications prennent effet des leur publication dans '
              'l\'application. L\'utilisation du service apres modification '
              'vaut acceptation des nouvelles conditions.',
              style: bodyStyle,
            ),
            const SizedBox(height: 20),

            // Droit applicable
            _sectionTitle(context, '7. Droit applicable et juridiction'),
            Text(
              'Les presentes conditions sont soumises au droit francais. '
              'En cas de litige, et apres tentative de resolution amiable, '
              'les tribunaux de Metz seront seuls competents.',
              style: bodyStyle,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }
}
