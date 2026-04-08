import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Politique de confidentialite — RGPD
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final headStyle = Theme.of(context).textTheme.headlineMedium;
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppTheme.textPrimary,
          height: 1.6,
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Politique de confidentialite')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Politique de confidentialite', style: headStyle),
            const SizedBox(height: 8),
            Text(
              'Derniere mise a jour : 6 avril 2026',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            // Responsable
            _sectionTitle(context, '1. Responsable du traitement'),
            Text(
              'FLOWFORGES, micro-entreprise\n'
              'Email : contact@flowforges.fr\n'
              'Site : flowforges.fr',
              style: bodyStyle,
            ),
            const SizedBox(height: 20),

            // Donnees collectees
            _sectionTitle(context, '2. Donnees collectees'),
            Text(
              'AllocCheck collecte les informations suivantes, saisies '
              'volontairement par l\'utilisateur :\n\n'
              '- Situation familiale (statut conjugal, nombre et age des enfants)\n'
              '- Revenus mensuels nets et autres ressources\n'
              '- Pension alimentaire (versee ou recue)\n'
              '- Situation de logement (statut, loyer, zone, code postal)\n'
              '- Taux d\'incapacite (donnee de sante au sens de l\'article 9 du RGPD)\n\n'
              'Aucun numero d\'allocataire CAF n\'est collecte.',
              style: bodyStyle,
            ),
            const SizedBox(height: 20),

            // Base legale
            _sectionTitle(context, '3. Base legale du traitement'),
            Text(
              'Le traitement des donnees repose sur le consentement explicite '
              'de l\'utilisateur (article 6.1.a du RGPD).\n\n'
              'Le taux d\'incapacite etant une donnee de sante, sa collecte '
              'repose sur le consentement specifique prevu a l\'article 9.2.a '
              'du RGPD. Ce consentement est recueilli de maniere distincte '
              'avant la saisie de cette donnee.',
              style: bodyStyle,
            ),
            const SizedBox(height: 20),

            // Finalite
            _sectionTitle(context, '4. Finalite du traitement'),
            Text(
              'Les donnees sont utilisees exclusivement pour :\n\n'
              '- Calculer une estimation de vos droits aux prestations CAF\n'
              '- Generer un courrier de contestation personnalise en cas d\'ecart',
              style: bodyStyle,
            ),
            const SizedBox(height: 20),

            // Stockage
            _sectionTitle(context, '5. Stockage des donnees'),
            Text(
              'Toutes les donnees saisies sont stockees localement dans le '
              'navigateur de l\'utilisateur (localStorage). Aucune donnee '
              'personnelle n\'est transmise a un serveur, une base de donnees '
              'ou un service tiers.\n\n'
              'AllocCheck ne dispose d\'aucun backend. Les calculs sont '
              'effectues integralement sur l\'appareil de l\'utilisateur.',
              style: bodyStyle,
            ),
            const SizedBox(height: 20),

            // Transferts
            _sectionTitle(context, '6. Transferts de donnees'),
            Text(
              'Aucune donnee personnelle n\'est transferee a un tiers.\n\n'
              'Le paiement est gere par Stripe. Lorsque l\'utilisateur clique '
              'sur le bouton de paiement, il est redirige vers stripe.com. '
              'AllocCheck ne collecte ni ne stocke aucune donnee bancaire. '
              'Le traitement du paiement est soumis a la politique de '
              'confidentialite de Stripe (https://stripe.com/fr/privacy).',
              style: bodyStyle,
            ),
            const SizedBox(height: 20),

            // Duree
            _sectionTitle(context, '7. Duree de conservation'),
            Text(
              'Les donnees restent dans le localStorage du navigateur tant que '
              'l\'utilisateur ne les supprime pas manuellement (en effacant '
              'les donnees de navigation ou via les outils du navigateur).',
              style: bodyStyle,
            ),
            const SizedBox(height: 20),

            // Droits
            _sectionTitle(context, '8. Vos droits'),
            Text(
              'Conformement au RGPD, vous disposez des droits suivants :\n\n'
              '- Droit d\'acces : consulter les donnees vous concernant\n'
              '- Droit de rectification : modifier vos donnees a tout moment '
              'en relancant une simulation\n'
              '- Droit a l\'effacement : supprimer vos donnees en effacant '
              'les donnees de navigation de votre navigateur\n'
              '- Droit a la portabilite : vos donnees etant stockees '
              'localement, vous en avez deja le controle total\n'
              '- Droit d\'opposition : vous pouvez cesser d\'utiliser le '
              'service a tout moment\n\n'
              'Pour exercer vos droits ou pour toute question, contactez-nous '
              'a l\'adresse : contact@flowforges.fr',
              style: bodyStyle,
            ),
            const SizedBox(height: 20),

            // Cookies
            _sectionTitle(context, '9. Cookies et traceurs'),
            Text(
              'AllocCheck n\'utilise aucun cookie tiers, aucun outil de '
              'tracking et aucun service d\'analytics.\n\n'
              'Le localStorage du navigateur est utilise uniquement pour '
              'la persistence des donnees saisies par l\'utilisateur et '
              'le statut de paiement. Il ne constitue pas un cookie au sens '
              'de la directive ePrivacy.',
              style: bodyStyle,
            ),
            const SizedBox(height: 20),

            // Donnees de sante
            _sectionTitle(context, '10. Donnees de sante'),
            Text(
              'Le taux d\'incapacite est une donnee de sante au sens de '
              'l\'article 9 du RGPD. Sa collecte est soumise au consentement '
              'explicite de l\'utilisateur, recueilli avant la saisie.\n\n'
              'Cette donnee est traitee exclusivement sur l\'appareil de '
              'l\'utilisateur pour le calcul des droits a l\'AAH et a la MVA. '
              'Elle n\'est jamais transmise a un tiers, un serveur ou un '
              'service externe.',
              style: bodyStyle,
            ),
            const SizedBox(height: 20),

            // Contact DPO
            _sectionTitle(context, '11. Contact'),
            Text(
              'Pour toute question relative a la protection de vos donnees :\n\n'
              'FLOWFORGES\n'
              'Email : contact@flowforges.fr',
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
