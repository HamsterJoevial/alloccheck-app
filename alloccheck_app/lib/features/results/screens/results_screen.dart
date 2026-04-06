import 'dart:convert';
import 'dart:js_interop';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/constants/app_constants.dart';
import '../../../core/models/droits_result.dart';
import '../../../core/models/situation.dart';
import '../../../core/services/calcul_local_service.dart';
import '../../../core/services/payment_service.dart';
import '../../../core/theme/app_theme.dart';

@JS('document.createElement')
external JSObject _jsCreateElementResult(String tag);

extension _JSObjectResult on JSObject {
  external set href(String value);
  external set download(String value);
  external void click();
}

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
  bool _isUnlocked = false;
  bool _justUnlocked = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _calculate();
    _loadUnlockStatus();
  }

  Future<void> _calculate() async {
    try {
      final service = CalculLocalService();
      final response = service.calculerDroits(widget.situation);
      await PaymentService.saveLastSimulation(widget.situation);
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

  bool _exportingRapportPdf = false;

  Future<void> _generateRapportPdf() async {
    final response = _response;
    if (response == null) return;
    setState(() => _exportingRapportPdf = true);
    try {
      final doc = pw.Document();
      final now = DateTime.now();
      final dateStr =
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
      final droits = response.droits;
      final ecart = response.ecart;

      final aideKeys = ['rsa', 'apl', 'prime_activite', 'af', 'aah', 'cmg', 'paje', 'cf', 'prepare', 'ars'];
      final aidesActives = aideKeys
          .where((k) => _getAideMontant(droits, k) > 0 || (ecart?.ecarts[k] ?? 0) > 0)
          .toList();

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(50, 45, 50, 45),
          build: (context) => [
            // ── En-tête ──────────────────────────────────────────────────
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('AllocCheck', style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: const PdfColor.fromInt(0xFF059669),
                )),
                pw.Text('Rapport du $dateStr', style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                )),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Text('Analyse de vos droits CAF', style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey700,
            )),
            pw.Divider(color: PdfColors.grey300, thickness: 0.5),
            pw.SizedBox(height: 8),

            // ── Résumé ───────────────────────────────────────────────────
            pw.Text('Résumé', style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
            )),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Column(
                children: [
                  _pdfRow('Droits théoriques estimés', '${droits.total.toStringAsFixed(0)} €/mois', bold: true),
                  if (ecart != null && ecart.ecartTotal > 0) ...[
                    pw.SizedBox(height: 4),
                    _pdfRow(
                      'Manque à toucher',
                      '${ecart.ecartTotal.toStringAsFixed(0)} €/mois',
                      bold: true,
                      valueColor: PdfColors.red700,
                    ),
                    pw.SizedBox(height: 4),
                    _pdfRow(
                      'Soit par an',
                      '${(ecart.ecartTotal * 12).toStringAsFixed(0)} €/an',
                      valueColor: PdfColors.red700,
                    ),
                  ] else if (ecart != null) ...[
                    pw.SizedBox(height: 4),
                    _pdfRow('Statut', 'Droits à jour — aucun écart détecté',
                        valueColor: const PdfColor.fromInt(0xFF059669)),
                  ],
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // ── Détail par aide ──────────────────────────────────────────
            pw.Text('Détail par aide', style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
            )),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(2.5),
                1: const pw.FlexColumnWidth(1.5),
                2: const pw.FlexColumnWidth(1.5),
              },
              children: [
                // Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _pdfCell('Aide', header: true),
                    _pdfCell('Montant théorique', header: true),
                    _pdfCell('Écart', header: true),
                  ],
                ),
                // Rows
                ...aidesActives.map((k) {
                  final montant = _getAideMontant(droits, k);
                  final ecartMontant = ecart?.ecarts[k] ?? 0;
                  final label = AppTheme.aideLabels[k] ?? k;
                  return pw.TableRow(children: [
                    _pdfCell(label),
                    _pdfCell('${montant.toStringAsFixed(0)} €'),
                    _pdfCell(
                      ecartMontant > 0 ? '+${ecartMontant.toStringAsFixed(0)} €' : '—',
                      color: ecartMontant > 0 ? PdfColors.red700 : PdfColors.grey600,
                    ),
                  ]);
                }),
              ],
            ),

            if (response.suggestions.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              pw.Text('Aides méconnues selon votre profil', style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
              )),
              pw.SizedBox(height: 8),
              ...response.suggestions.map((s) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('• ${s.titre}', style: pw.TextStyle(
                      fontSize: 10.5,
                      fontWeight: pw.FontWeight.bold,
                    )),
                    pw.Text('  ${s.description}',
                        style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    pw.Text('  Contact : ${s.source}',
                        style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                  ],
                ),
              )),
            ],

            pw.SizedBox(height: 20),
            pw.Divider(color: PdfColors.grey300, thickness: 0.5),
            pw.SizedBox(height: 4),
            pw.Text(
              AppConstants.calculDisclaimer,
              style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600),
            ),
          ],
        ),
      );

      final bytes = await doc.save();
      if (kIsWeb) {
        final base64Str = base64Encode(bytes);
        final dataUrl = 'data:application/pdf;base64,$base64Str';
        final anchor = _jsCreateElementResult('a');
        anchor.href = dataUrl;
        anchor.download = 'rapport_alloccheck.pdf';
        anchor.click();
      } else {
        // ignore: deprecated_member_use
        final _ = bytes; // non utilisé hors web pour l'instant
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur génération PDF : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exportingRapportPdf = false);
    }
  }

  double _getAideMontant(DroitsResult droits, String key) {
    switch (key) {
      case 'rsa': return droits.rsa;
      case 'apl': return droits.apl;
      case 'prime_activite': return droits.primeActivite;
      case 'af': return droits.af;
      case 'aah': return droits.aah;
      case 'cmg': return droits.cmg;
      case 'paje': return droits.paje;
      case 'cf': return droits.cf;
      case 'prepare': return droits.prepare;
      case 'ars': return droits.ars;
      default: return 0;
    }
  }

  pw.Widget _pdfRow(String label, String value, {bool bold = false, PdfColor? valueColor}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(
          fontSize: 10.5,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        )),
        pw.Text(value, style: pw.TextStyle(
          fontSize: 10.5,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: valueColor,
        )),
      ],
    );
  }

  pw.Widget _pdfCell(String text, {bool header = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
        ),
      ),
    );
  }

  Future<void> _loadUnlockStatus() async {
    final unlocked = await PaymentService.isUnlocked();
    final justUnlocked = await PaymentService.consumeJustUnlocked();
    if (mounted) {
      setState(() {
        _isUnlocked = unlocked;
        _justUnlocked = justUnlocked;
      });
    }
  }

  Future<void> _handleCodeUnlock(String code) async {
    final success = await PaymentService.unlockWithCode(code);
    if (!mounted) return;
    if (success) {
      setState(() {
        _isUnlocked = true;
        _justUnlocked = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code invalide. Vérifiez votre code d\'accès.')),
      );
    }
  }

  void _showCodeDialog() {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Code d\'accès'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Votre code (ex : AC2026UNLOCK)',
          ),
          textCapitalization: TextCapitalization.characters,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleCodeUnlock(controller.text);
            },
            child: const Text('Débloquer'),
          ),
        ],
      ),
    );
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
          // Toujours visible : carte teaser (résumé + montants globaux)
          if (hasEcart)
            _buildAlertEcartCard(response.droits, response.ecart!)
          else
            _buildTotalCard(response.droits, response.ecart != null),

          // CTA ancré — visible immédiatement après le chiffre d'écart
          if (!_isUnlocked) ...[
            const SizedBox(height: 16),
            _buildEarlyCta(),
          ],

          const SizedBox(height: 24),

          // Rapport détaillé — paywall si non débloqué
          if (_isUnlocked) ...[
            // Bannière code d'accès (uniquement au premier déverrouillage)
            if (_justUnlocked) ...[
              _buildAccessCodeBanner(),
              const SizedBox(height: 20),
            ],

            Text('Détail par aide', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ..._buildAideCards(response.droits, response.ecart),

            if (response.suggestions.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildSuggestionsSection(response.suggestions),
            ],

            const SizedBox(height: 24),
            _buildDisclaimer(),
            const SizedBox(height: 24),

            // CTA — Contester si écart
            if (hasEcart) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
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
              _buildLetterNote(),
            ],

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _exportingRapportPdf ? null : _generateRapportPdf,
                icon: _exportingRapportPdf
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.picture_as_pdf),
                label: Text(_exportingRapportPdf ? 'Génération...' : 'Télécharger le rapport PDF'),
              ),
            ),
          ] else ...[
            _buildLockedSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Container(
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
    );
  }

  Widget _buildTotalCard(DroitsResult droits, bool hasComparaison) {
    return Card(
      color: AppTheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white70, size: 28),
            const SizedBox(height: 8),
            Text(
              'Vos droits estimés',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              '${droits.total.toStringAsFixed(0)} €/mois',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            if (!hasComparaison) ...[
              const SizedBox(height: 8),
              Text(
                'Comparez avec ce que vous percevez actuellement\npour détecter un écart.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white60),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAlertEcartCard(DroitsResult droits, EcartResult ecart) {
    final totalPercu = droits.total - ecart.ecartTotal;
    final nbConcernees = ecart.ecarts.values.where((v) => v > 0).length;

    return Column(
      children: [
        // Carte alerte principale
        Card(
          color: AppTheme.error.withValues(alpha: 0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppTheme.error.withValues(alpha: 0.4), width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 32),
                const SizedBox(height: 8),
                Text(
                  'Manque à toucher',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${ecart.ecartTotal.toStringAsFixed(0)} €/mois',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: AppTheme.error,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Text(
                  'soit ${(ecart.ecartTotal * 12).toStringAsFixed(0)} €/an',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.error),
                ),
              ],
            ),
          ),
        ),

        // Ligne comparaison
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Actuellement perçu',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              )),
                      const SizedBox(height: 2),
                      Text(
                        '${totalPercu.toStringAsFixed(0)} €/mois',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Droits théoriques',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              )),
                      const SizedBox(height: 2),
                      Text(
                        '${droits.total.toStringAsFixed(0)} €/mois',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        if (nbConcernees > 0) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: AppTheme.warning),
                const SizedBox(width: 8),
                Text(
                  '$nbConcernees aide(s) concernée(s) — voir le rapport complet',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.warning,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── PAYWALL ──────────────────────────────────────────────────────────────

  Widget _buildLockedSection() {
    final s = widget.situation;
    final totalRevenus = s.revenuActiviteDemandeur +
        s.revenuActiviteConjoint +
        s.totalAutresRevenus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Récapitulatif situation saisie
        _buildSituationRecap(s, totalRevenus),

        const SizedBox(height: 20),

        // 2. Aperçu du rapport (fausses cartes + gradient)
        _buildReportPreview(),

        const SizedBox(height: 20),

        // 3. Ce que contient le rapport
        _buildReportContents(),

        const SizedBox(height: 20),

        // 4. CTA
        _buildUnlockCta(),
      ],
    );
  }

  Widget _buildSituationRecap(Situation s, double totalRevenus) {
    String familleLabel = s.situationFamiliale == SituationFamiliale.couple
        ? 'En couple'
        : 'Célibataire';
    if (s.parentIsole) familleLabel += ' · parent isolé';

    String enfantsLabel = s.nombreEnfants == 0
        ? 'Sans enfant'
        : '${s.nombreEnfants} enfant${s.nombreEnfants > 1 ? 's' : ''}';
    if (s.agesEnfants.isNotEmpty) {
      final ages = s.agesEnfants.map((a) => '$a ans').join(', ');
      enfantsLabel += ' ($ages)';
    }

    String logementLabel = s.statutLogement == StatutLogement.locataire
        ? 'Locataire · ${s.loyerMensuel.toStringAsFixed(0)} €/mois'
        : s.statutLogement == StatutLogement.proprietaire
            ? 'Propriétaire'
            : 'Hébergé';

    String zoneLabel = s.zoneLogement == ZoneLogement.zone1
        ? 'Zone 1 (Paris / Île-de-France)'
        : s.zoneLogement == ZoneLogement.zone2
            ? 'Zone 2 (grandes villes)'
            : 'Zone 3 (reste du territoire)';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Votre situation analysée',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 12),
          _buildRecapRow(Icons.person_outline, familleLabel),
          const SizedBox(height: 6),
          _buildRecapRow(Icons.child_friendly_outlined, enfantsLabel),
          const SizedBox(height: 6),
          _buildRecapRow(
            Icons.euro_outlined,
            'Revenus : ${totalRevenus.toStringAsFixed(0)} €/mois',
          ),
          const SizedBox(height: 6),
          _buildRecapRow(Icons.home_outlined, logementLabel),
          const SizedBox(height: 6),
          _buildRecapRow(Icons.location_on_outlined, zoneLabel),
          if (s.tauxHandicap != null && s.tauxHandicap! > 0) ...[
            const SizedBox(height: 6),
            _buildRecapRow(
              Icons.accessibility_new_outlined,
              'Handicap · taux ${s.tauxHandicap}%',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecapRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppTheme.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildReportPreview() {
    return Stack(
      children: [
        Column(
          children: [
            _buildFakeAideCard(),
            const SizedBox(height: 8),
            _buildFakeAideCard(),
            const SizedBox(height: 8),
            _buildFakeAideCard(),
          ],
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.0),
                  Colors.white.withValues(alpha: 0.88),
                  Colors.white,
                ],
              ),
            ),
          ),
        ),
        const Positioned(
          bottom: 8,
          left: 0,
          right: 0,
          child: Center(
            child: Icon(Icons.lock_outline, size: 28, color: AppTheme.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildReportContents() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Le rapport complet comprend',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          _buildReportItem(Icons.list_alt_outlined,
              'Détail aide par aide avec montant exact et base de calcul'),
          _buildReportItem(Icons.warning_amber_outlined,
              'Écarts identifiés — ce qui vous est dû mais non versé'),
          _buildReportItem(Icons.lightbulb_outlined,
              'Aides méconnues correspondant à votre profil'),
          _buildReportItem(Icons.mail_outlined,
              'Courrier de contestation pré-rédigé (références légales incluses)'),
        ],
      ),
    );
  }

  Widget _buildReportItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppTheme.secondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textPrimary,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnlockCta() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () =>
                PaymentService.saveSituationAndOpenStripe(widget.situation),
            icon: const Icon(Icons.lock_open),
            label: const Text('Débloquer mon rapport — 2,99 €'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Signal de confiance
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_outlined, size: 13, color: AppTheme.textSecondary),
            const SizedBox(width: 4),
            Text(
              'Barèmes officiels — Journal Officiel avril 2026',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppTheme.textSecondary, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Paiement unique · Accès permanent sur cet appareil',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _showCodeDialog,
          child: Text(
            'J\'ai déjà un code d\'accès',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.primary,
                  decoration: TextDecoration.underline,
                ),
          ),
        ),
      ],
    );
  }

  // ── EARLY CTA (ancré juste après le chiffre d'écart) ────────────────────

  Widget _buildEarlyCta() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () =>
            PaymentService.saveSituationAndOpenStripe(widget.situation),
        icon: const Icon(Icons.lock_open, size: 18),
        label: const Text('Voir le rapport complet — 2,99 €'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  // ── BANNIÈRE CODE D'ACCÈS (affiché au premier déverrouillage) ────────────

  Widget _buildAccessCodeBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline,
                  color: AppTheme.secondary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Accès débloqué',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.secondary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Notez ce code pour restaurer votre accès sur un autre appareil ou navigateur :',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  PaymentService.accessCode,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: 2,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(
                        ClipboardData(text: PaymentService.accessCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Code copié dans le presse-papier')),
                    );
                  },
                  child: const Icon(Icons.copy_outlined,
                      size: 18, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── NOTE COURRIER (dans le rapport débloqué, après le CTA lettre) ────────

  Widget _buildLetterNote() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.balance_outlined,
              size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Le courrier reprend les références légales applicables à votre situation '
              'et formalise votre demande. La CAF reste souveraine dans son instruction. '
              'En cas de refus : Commission de Recours Amiable (CRA), puis Médiateur de la République. '
              "AllocCheck vous aide dans la démarche — ce n'est pas un conseil juridique.",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    height: 1.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFakeAideCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppTheme.border,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppTheme.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    height: 9,
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 52,
              height: 16,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── RAPPORT COMPLET (unlocked) ───────────────────────────────────────────

  /// Fiabilité du calcul par aide
  Widget _buildConfidenceBadge(String aide) {
    final isApprox = aide == 'apl';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: (isApprox ? AppTheme.warning : AppTheme.secondary).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isApprox ? Icons.info_outline : Icons.check_circle_outline,
            size: 9,
            color: isApprox ? AppTheme.warning : AppTheme.secondary,
          ),
          const SizedBox(width: 2),
          Text(
            isApprox ? 'estimation' : 'fiable',
            style: TextStyle(
              color: isApprox ? AppTheme.warning : AppTheme.secondary,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsSection(List<AideSuggestion> suggestions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.lightbulb_outline, color: AppTheme.warning, size: 20),
            const SizedBox(width: 8),
            Text('Aides à explorer', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Ces aides méconnues peuvent s\'appliquer à votre situation. À vérifier auprès des organismes concernés.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 12),
        ...suggestions.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.titre,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text(s.description,
                          style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.info_outline,
                              size: 12, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              s.source,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.primary,
                                    fontStyle: FontStyle.italic,
                                    fontSize: 11,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            )),
      ],
    );
  }

  List<Widget> _buildAideCards(DroitsResult droits, EcartResult? ecart) {
    final aides = {
      'rsa': droits.rsa,
      'apl': droits.apl,
      'prime_activite': droits.primeActivite,
      'af': droits.af,
      'aah': droits.aah,
      'cmg': droits.cmg,
      'paje': droits.paje,
      'cf': droits.cf,
      'prepare': droits.prepare,
      'ars': droits.ars,
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.1),
                  radius: 20,
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          const SizedBox(width: 6),
                          _buildConfidenceBadge(aide),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        detail,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF666666)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${montant.toStringAsFixed(0)} €',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (ecartMontant > 0) ...[
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (montant == 0 ? AppTheme.error : AppTheme.warning).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          montant == 0 ? 'Non réclamée' : '+${ecartMontant.toStringAsFixed(0)} €',
                          style: TextStyle(
                            color: montant == 0 ? AppTheme.error : AppTheme.warning,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
}
