import 'dart:convert';
import 'dart:js_interop';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/droits_result.dart';
import '../../../core/models/situation.dart';
import '../../../core/theme/app_theme.dart';

@JS('document.createElement')
external JSObject _jsCreateElement(String tag);

extension on JSObject {
  external set href(String value);
  external set download(String value);
  external void click();
}

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
  final _numAllocataireController = TextEditingController();
  final _adresseCafController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _refCourrierController = TextEditingController();

  bool get _canGenerate => _selectedAide != null;

  @override
  void dispose() {
    _nomController.dispose();
    _adresseController.dispose();
    _departementController.dispose();
    _numAllocataireController.dispose();
    _adresseCafController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    _refCourrierController.dispose();
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

            // Référence dossier CAF
            Text('Référence dossier :', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _numAllocataireController,
              decoration: InputDecoration(
                labelText: 'Numéro allocataire CAF',
                hintText: '7 chiffres sur votre attestation',
                helperText: 'Recommandé — permet à la CAF de retrouver votre dossier',
                helperStyle: TextStyle(color: AppTheme.primary, fontSize: 11),
                prefixIcon: const Icon(Icons.badge_outlined, size: 20),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            if (_letterType == 'saisine_cra') ...[
              TextFormField(
                controller: _refCourrierController,
                decoration: const InputDecoration(
                  labelText: 'Référence courrier CAF (optionnel)',
                  hintText: 'Ex: réf. 2026-xxxxx mentionnée sur le refus',
                  prefixIcon: Icon(Icons.tag, size: 20),
                ),
              ),
              const SizedBox(height: 12),
            ],

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
            const SizedBox(height: 12),
            TextFormField(
              controller: _adresseCafController,
              decoration: InputDecoration(
                labelText: 'Adresse postale de votre CAF',
                hintText: 'Ex: 12 rue de la Paix, 75001 Paris',
                helperText: 'Trouvez l\'adresse sur caf.fr → "Ma CAF" → votre département',
                helperStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _telephoneController,
                    decoration: const InputDecoration(
                      labelText: 'Téléphone (optionnel)',
                      prefixIcon: Icon(Icons.phone_outlined, size: 20),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email (optionnel)',
                      prefixIcon: Icon(Icons.email_outlined, size: 20),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
              ],
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
                onPressed: _canGenerate ? _generateLetter : null,
                icon: const Icon(Icons.description),
                label: const Text('Générer le courrier'),
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
    final lettre = _buildLetterText();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _LetterPreviewScreen(texte: lettre),
      ),
    );
  }

  String _buildLetterText() {
    final aide = _selectedAide!;
    final aideLabel = AppTheme.aideLabels[aide] ?? aide;
    final ecartMensuel = widget.ecart.ecarts[aide] ?? 0;
    final ecartAnnuel = ecartMensuel * 12;
    final montantTheorique = aide == 'rsa'
        ? widget.droits.rsa
        : aide == 'apl'
            ? widget.droits.apl
            : aide == 'prime_activite'
                ? widget.droits.primeActivite
                : aide == 'af'
                    ? widget.droits.af
                    : widget.droits.aah;
    final montantPercu = montantTheorique - ecartMensuel;

    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final dep = _departementController.text.isNotEmpty
        ? _departementController.text
        : '[votre département]';
    final adresseCaf = _adresseCafController.text.isNotEmpty
        ? _adresseCafController.text
        : '[adresse de votre CAF]';
    final nom = _nomController.text.isNotEmpty ? _nomController.text : '[Votre nom]';
    final adresse = _adresseController.text.isNotEmpty
        ? _adresseController.text
        : '[votre adresse]';
    final numAlloc = _numAllocataireController.text.isNotEmpty
        ? _numAllocataireController.text
        : '___________________';
    final tel = _telephoneController.text.isNotEmpty
        ? '\nTél. : ${_telephoneController.text}'
        : '';
    final email = _emailController.text.isNotEmpty
        ? '\nEmail : ${_emailController.text}'
        : '';
    final refCourrier = _refCourrierController.text.isNotEmpty
        ? '\nRéférence courrier CAF : ${_refCourrierController.text}'
        : '';

    final isCRA = _letterType == 'saisine_cra';

    // Références légales par aide
    final refsLegales = {
      'rsa': 'art. L262-2 du Code de l\'Action Sociale et des Familles (CASF), '
          'Décret n° 2026-220 du 30/03/2026',
      'apl': 'art. L841-1 du Code de la Construction et de l\'Habitation (CCH)',
      'prime_activite': 'art. L841-3 et L844-1 du Code de la Sécurité Sociale (CSS), '
          'Décret n° 2026-222 du 30/03/2026',
      'af': 'art. L512-1 du Code de la Sécurité Sociale (CSS), '
          'Instruction DSS/2B/2026/46 du 20/03/2026',
      'aah': 'art. L821-1 du Code de la Sécurité Sociale (CSS), '
          'Décret n° 2026-229 du 30/03/2026',
    };
    final ref = refsLegales[aide] ?? 'barèmes officiels 2026';

    final objet = isCRA
        ? 'Objet : Saisine de la Commission de Recours Amiable — $aideLabel'
        : 'Objet : Demande de réexamen de mes droits — $aideLabel';

    final intro = isCRA
        ? 'Suite à l\'absence de réponse à ma réclamation gracieuse (ou à son refus), '
            'je saisie la Commission de Recours Amiable conformément aux articles R142-1 à R142-8 '
            'du Code de la Sécurité Sociale.'
        : 'Je me permets de vous contacter au sujet du versement de $aideLabel '
            'dont je bénéficie (ou auquel je pense avoir droit).';

    final corps =
        'Sur la base des barèmes officiels en vigueur au 1er avril 2026 ($ref), '
        'le montant théorique de $aideLabel auquel j\'ai droit s\'élève à '
        '${montantTheorique.toStringAsFixed(2)}\u20AC/mois.\n\n'
        'Or, le montant actuellement versé est de ${montantPercu.toStringAsFixed(2)}\u20AC/mois, '
        'soit un écart de ${ecartMensuel.toStringAsFixed(2)}\u20AC/mois '
        '(${ecartAnnuel.toStringAsFixed(0)}\u20AC/an).\n\n'
        'Je vous demande donc de bien vouloir :\n'
        '1. Réexaminer le calcul de mes droits à $aideLabel ;\n'
        '2. Corriger le montant versé à compter du prochain versement ;\n'
        '3. Procéder, le cas échéant, au rappel des sommes dues.';

    return '''$nom
$adresse$tel$email

CAF du $dep
$adresseCaf
Service des prestations

$dateStr

$objet
Numéro allocataire : $numAlloc$refCourrier

Madame, Monsieur,

$intro

$corps

Je reste à votre disposition pour tout complément d\'information et vous transmettrai tout justificatif utile à l\'instruction de ma demande.

Dans l\'attente de votre réponse, je vous prie d\'agréer, Madame, Monsieur, l\'expression de mes salutations distinguées.

$nom
Le $dateStr''';
  }
}

/// Écran de prévisualisation du courrier
class _LetterPreviewScreen extends StatefulWidget {
  final String texte;

  const _LetterPreviewScreen({required this.texte});

  @override
  State<_LetterPreviewScreen> createState() => _LetterPreviewScreenState();
}

class _LetterPreviewScreenState extends State<_LetterPreviewScreen> {
  bool _exportingPdf = false;

  Future<void> _exportPdf() async {
    setState(() => _exportingPdf = true);
    try {
      final doc = pw.Document();

      // Découper par blocs (double saut de ligne) pour respecter la structure du courrier
      final blocks = widget.texte.split('\n\n');

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(65, 55, 65, 55),
          build: (context) {
            final widgets = <pw.Widget>[];

            for (var i = 0; i < blocks.length; i++) {
              final block = blocks[i].trim();
              if (block.isEmpty) continue;

              final lines = block.split('\n');
              final firstLine = lines.first.trim();

              final isDate = RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(firstLine);
              final isRecipient = firstLine.startsWith('CAF du ');
              final isObjet = firstLine.startsWith('Objet :');
              final isGreeting = block.trim() == 'Madame, Monsieur,';
              final isSender = i == 0;
              final isSignature = i == blocks.length - 1;

              pw.Widget blockWidget;

              if (isSender) {
                // Expéditeur — haut gauche, taille légèrement réduite
                blockWidget = pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: lines.map((l) => pw.Text(
                    l, style: const pw.TextStyle(fontSize: 10),
                  )).toList(),
                );
              } else if (isRecipient) {
                // Destinataire — aligné à droite
                blockWidget = pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: lines.map((l) => pw.Text(
                      l, style: const pw.TextStyle(fontSize: 10),
                    )).toList(),
                  ),
                );
              } else if (isDate) {
                // Date — alignée à droite
                blockWidget = pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(block, style: const pw.TextStyle(fontSize: 10)),
                );
              } else if (isObjet) {
                // Objet + numéro allocataire — première ligne en gras
                blockWidget = pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: lines.map((l) => pw.Text(
                    l,
                    style: pw.TextStyle(
                      fontSize: 10.5,
                      fontWeight: l == firstLine ? pw.FontWeight.bold : pw.FontWeight.normal,
                    ),
                  )).toList(),
                );
              } else if (isGreeting) {
                blockWidget = pw.Text(block,
                    style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold));
              } else if (isSignature) {
                blockWidget = pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: lines.map((l) => pw.Text(
                    l, style: const pw.TextStyle(fontSize: 10.5),
                  )).toList(),
                );
              } else {
                // Corps — paragraphe justifié
                blockWidget = pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: lines.map((l) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 2),
                    child: pw.Text(
                      l.isEmpty ? ' ' : l,
                      style: pw.TextStyle(fontSize: 10.5, lineSpacing: 2),
                    ),
                  )).toList(),
                );
              }

              widgets.add(blockWidget);
              widgets.add(pw.SizedBox(height: 14));
            }

            if (widgets.isNotEmpty) widgets.removeLast();
            return widgets;
          },
        ),
      );

      final bytes = await doc.save();
      if (kIsWeb) {
        final base64Str = base64Encode(bytes);
        final dataUrl = 'data:application/pdf;base64,$base64Str';
        final anchor = _jsCreateElement('a');
        anchor.href = dataUrl;
        anchor.download = 'courrier_caf_alloccheck.pdf';
        anchor.click();
      } else {
        await Printing.sharePdf(
          bytes: bytes,
          filename: 'courrier_caf_alloccheck.pdf',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la génération : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Votre courrier'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copier le texte',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: widget.texte));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Courrier copié dans le presse-papiers'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Bannière info
          Container(
            width: double.infinity,
            color: AppTheme.primary.withValues(alpha: 0.08),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: AppTheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Complétez les zones ___ avant d\'envoyer. Envoyez en recommandé avec AR.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppTheme.primary),
                  ),
                ),
              ],
            ),
          ),

          // Texte du courrier
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SelectableText(
                  widget.texte,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    height: 1.6,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
            ),
          ),

          // CTA bas
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: widget.texte));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copié !')),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copier'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _exportingPdf ? null : _exportPdf,
                      icon: _exportingPdf
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.picture_as_pdf, size: 18),
                      label: Text(_exportingPdf ? 'Génération...' : 'Exporter PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
