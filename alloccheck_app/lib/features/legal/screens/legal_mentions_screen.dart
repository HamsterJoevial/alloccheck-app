import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Mentions legales
class LegalMentionsScreen extends StatelessWidget {
  const LegalMentionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final headStyle = Theme.of(context).textTheme.headlineMedium;
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppTheme.textPrimary,
          height: 1.6,
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Mentions legales')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mentions legales', style: headStyle),
            const SizedBox(height: 24),

            _sectionTitle(context, 'Editeur'),
            Text(
              'FLOWFORGES, micro-entreprise\n'
              'Directeur de la publication : Joffrey DESFORGES\n'
              'Email : contact@flowforges.fr\n'
              'Site : flowforges.fr',
              style: bodyStyle,
            ),
            const SizedBox(height: 20),

            _sectionTitle(context, 'Hebergement'),
            Text(
              'Netlify, Inc.\n'
              '44 Montgomery Street, Suite 300\n'
              'San Francisco, CA 94104, USA\n'
              'https://www.netlify.com',
              style: bodyStyle,
            ),
            const SizedBox(height: 20),

            _sectionTitle(context, 'Nature du service'),
            Text(
              'AllocCheck est un outil d\'aide a la comprehension des droits '
              'aux prestations de la Caisse d\'Allocations Familiales (CAF).\n\n'
              'Les calculs effectues sont des estimations basees sur les '
              'baremes officiels publies au Journal Officiel. Ils sont fournis '
              'a titre indicatif et peuvent differer du calcul reel effectue '
              'par la CAF.\n\n'
              'Ce service ne constitue pas un conseil juridique. Il ne se '
              'substitue en aucun cas a une consultation aupres d\'un '
              'professionnel du droit ou de la CAF.',
              style: bodyStyle,
            ),
            const SizedBox(height: 20),

            _sectionTitle(context, 'Propriete intellectuelle'),
            Text(
              'L\'ensemble du contenu de ce site (textes, interface, code) '
              'est la propriete de FLOWFORGES, sauf mention contraire.\n\n'
              'Les baremes de calcul sont issus de sources publiques '
              '(Service-Public.fr, Journal Officiel).',
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
