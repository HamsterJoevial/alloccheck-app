import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/droits_result.dart';
import '../../../core/models/situation.dart';
import '../../../core/services/calcul_local_service.dart';
import '../../../core/services/payment_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/web_download_bridge.dart';

/// Écran de résultats — affiche les droits calculés et l'écart
class ResultsScreen extends StatefulWidget {
  final Situation situation;
  final String simId;

  const ResultsScreen({super.key, required this.situation, required this.simId});

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
    _initScreen();
  }

  Future<void> _initScreen() async {
    await _calculate();
    await _loadUnlockStatus();
  }

  Future<void> _calculate() async {
    try {
      final service = CalculLocalService();
      final response = service.calculerDroits(widget.situation);
      await PaymentService.saveLastSimulation(widget.situation, widget.simId);
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
      // ─── Polices (supportent €, accents, tirets) ───────────────────────────
      final fontRegular = await PdfGoogleFonts.robotoRegular();
      final fontBold = await PdfGoogleFonts.robotoBold();
      final fontItalic = await PdfGoogleFonts.robotoItalic();

      final doc = pw.Document();
      final now = DateTime.now();
      final dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
      final droits = response.droits;
      final ecart = response.ecart;
      final s = widget.situation;

      const green = PdfColor.fromInt(0xFF059669);
      const red = PdfColors.red700;

      final aideKeys = ['rsa', 'apl', 'prime_activite', 'af', 'aah', 'mva', 'asf', 'aeeh', 'cmg', 'paje', 'cf', 'prepare', 'ars'];
      final aidesActives = aideKeys
          .where((k) => _getAideMontant(droits, k) > 0 || (ecart?.ecarts[k] ?? 0) > 0)
          .toList();
      final aidesNonReclamees = aideKeys
          .where((k) => _getAideMontant(droits, k) > 0 && (s.montantPercu[k] ?? 0) == 0)
          .toList();
      // Aides avec écart — pour éviter la duplication en section 3
      final aidesAvecEcart = aideKeys
          .where((k) => (ecart?.ecarts[k] ?? 0) > 0)
          .toSet();

      // Labels lisibles pour les enums
      final zoneLabel = {'zone_1': 'Zone 1 (Paris/IDF)', 'zone_2': 'Zone 2', 'zone_3': 'Zone 3'}[s.zoneLogement.value] ?? s.zoneLogement.value;
      final statutLogLabel = {'locataire': 'Locataire', 'proprietaire': 'Propriétaire', 'heberge': 'Hébergé(e)'}[s.statutLogement.value] ?? s.statutLogement.value;

      // ─── Helpers ───────────────────────────────────────────────────────────
      pw.TextStyle ts(double size, {bool bold = false, bool italic = false, PdfColor? color}) =>
        pw.TextStyle(
          font: bold ? fontBold : (italic ? fontItalic : fontRegular),
          fontSize: size,
          color: color,
        );

      pw.Widget section(String title) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(height: 18),
          pw.Text(title, style: ts(13, bold: true)),
          pw.Divider(color: PdfColors.grey400, thickness: 0.7),
          pw.SizedBox(height: 6),
        ],
      );

      pw.Widget infoRow(String label, String value, {bool bold = false, PdfColor? color}) =>
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                width: 190,
                child: pw.Text(label, style: ts(10, color: PdfColors.grey700)),
              ),
              pw.Expanded(
                child: pw.Text(value, style: ts(10, bold: bold, color: color)),
              ),
            ],
          ),
        );

      pw.Widget aideBlock(String key) {
        final montant = _getAideMontant(droits, key);
        final percu = s.montantPercu[key] ?? 0;
        final ecartMontant = ecart?.ecarts[key] ?? 0;
        final label = AppTheme.aideLabels[key] ?? key;
        final detail = droits.details[key] ?? '';
        final nonReclame = montant > 0 && percu == 0;

        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 12),
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(
              color: ecartMontant > 0 ? PdfColors.red300 : (nonReclame ? PdfColors.orange300 : PdfColors.grey300),
              width: ecartMontant > 0 ? 1.0 : 0.6,
            ),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            color: ecartMontant > 0 ? PdfColors.red50 : PdfColors.white,
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(label, style: ts(11, bold: true)),
                  pw.Row(children: [
                    pw.Text(
                      key == 'ars'
                        ? '${(montant * 12).toStringAsFixed(0)} \u20AC/an (vers\u00e9e en ao\u00fbt)'
                        : '${montant.toStringAsFixed(2)} \u20AC/mois',
                      style: ts(11, bold: true, color: green)),
                    if (ecartMontant > 0) ...[
                      pw.SizedBox(width: 8),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.red700,
                          borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
                        ),
                        child: pw.Text('Ecart : +${ecartMontant.toStringAsFixed(0)} \u20AC',
                          style: ts(9, bold: true, color: PdfColors.white)),
                      ),
                    ],
                    if (nonReclame && ecartMontant == 0) ...[
                      pw.SizedBox(width: 8),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.orange700,
                          borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
                        ),
                        child: pw.Text('Non reclamee',
                          style: ts(9, color: PdfColors.white)),
                      ),
                    ],
                  ]),
                ],
              ),
              if (percu > 0) ...[
                pw.SizedBox(height: 3),
                pw.Text('Montant percu declare : ${percu.toStringAsFixed(2)} \u20AC/mois',
                  style: ts(9.5, color: PdfColors.grey600)),
              ],
              if (detail.isNotEmpty) ...[
                pw.SizedBox(height: 6),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Detail du calcul :', style: ts(9, bold: true, color: PdfColors.grey600)),
                      pw.SizedBox(height: 3),
                      pw.Text(detail, style: ts(9, color: PdfColors.grey800)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      }

      // ─── Situation en clair ────────────────────────────────────────────────
      String enfantsStr = s.nombreEnfants == 0
          ? 'Aucun'
          : '${s.nombreEnfants} enfant(s)'
            + (s.agesEnfants.isNotEmpty ? ' (${s.agesEnfants.map((a) => '$a ans').join(', ')})' : '');

      String logementStr = statutLogLabel;
      if (s.loyerMensuel > 0) logementStr += ' - loyer ${s.loyerMensuel.toStringAsFixed(0)} \u20AC/mois';
      logementStr += ' - $zoneLabel';

      String revenusStr = s.revenuActiviteDemandeur == 0
          ? 'Aucun revenu d\'activité'
          : '${s.revenuActiviteDemandeur.toStringAsFixed(0)} €/mois'
            + (s.sourceRevenuDemandeur != null ? ' (${s.sourceRevenuDemandeur!.label})' : '');

      final autresRev = s.autresRevenus.where((r) => r.montantMensuel > 0).toList();

      // ─── Construction du document ──────────────────────────────────────────
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(50, 45, 50, 45),
          header: (ctx) => pw.Column(children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('AllocCheck', style: ts(16, bold: true, color: green)),
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                  pw.Text('Rapport d\'analyse des droits CAF', style: ts(9, color: PdfColors.grey600)),
                  pw.Text('Genere le $dateStr - Baremes avril 2026', style: ts(9, color: PdfColors.grey600)),
                ]),
              ],
            ),
            pw.Divider(color: PdfColors.grey300, thickness: 0.5),
          ]),
          footer: (ctx) => pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('AllocCheck - alloccheck.flowforges.fr', style: ts(8, color: PdfColors.grey500)),
              pw.Text('Page ${ctx.pageNumber}/${ctx.pagesCount}', style: ts(8, color: PdfColors.grey500)),
            ],
          ),
          build: (context) => [

            // ══ RÉSUMÉ EXÉCUTIF ══════════════════════════════════════════════
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFFECFDF5),
                border: pw.Border.all(color: green, width: 0.8),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Column(children: [
                infoRow('Droits theoriques mensuels estimes :', '${droits.total.toStringAsFixed(2)} \u20AC/mois', bold: true, color: green),
                if (ecart != null && ecart.ecartTotal > 0) ...[
                  pw.SizedBox(height: 4),
                  infoRow('Manque a toucher :', '${ecart.ecartTotal.toStringAsFixed(2)} \u20AC/mois', bold: true, color: red),
                  infoRow('Soit sur 12 mois :', '${(ecart.ecartTotal * 12).toStringAsFixed(0)} \u20AC non percus', bold: false, color: red),
                ] else if (ecart != null) ...[
                  pw.SizedBox(height: 4),
                  infoRow('Statut :', 'Aucun ecart detecte - droits a jour', bold: false, color: green),
                ],
                if (aidesNonReclamees.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  infoRow('Aides non reclamees :', aidesNonReclamees.map((k) => AppTheme.aideLabels[k] ?? k).join(', '), bold: false, color: PdfColors.orange800),
                ],
              ]),
            ),

            // ══ SITUATION DÉCLARÉE ════════════════════════════════════════════
            section('1. Situation declaree'),
            infoRow('Statut conjugal :', s.statutConjugal.label),
            infoRow('Enfants a charge :', enfantsStr),
            if (s.gardeAlternee) infoRow('Mode de garde :', 'Garde alternee'),
            infoRow('Logement :', logementStr),
            if (s.logementConventionne != null)
              infoRow('Logement conventionne :', s.logementConventionne! ? 'Oui (APL)' : 'Non (ALS/ALF)'),
            infoRow('Revenus d\'activite (demandeur) :', revenusStr),
            if (s.situationFamiliale == SituationFamiliale.couple && s.revenuActiviteConjoint > 0)
              infoRow('Revenus d\'activite (conjoint) :', '${s.revenuActiviteConjoint.toStringAsFixed(0)} \u20AC/mois'),
            if (autresRev.isNotEmpty)
              infoRow('Autres revenus :', autresRev.map((r) => '${r.type.label} : ${r.montantMensuel.toStringAsFixed(0)} \u20AC').join(' | ')),
            if (s.pensionAlimentaireVersee > 0)
              infoRow('Pension alimentaire versee :', '${s.pensionAlimentaireVersee.toStringAsFixed(0)} \u20AC/mois (deduite des ressources)'),
            if (s.pensionAlimentaireNonPercue)
              infoRow('Pension non percue :', 'Oui - ouvre droit a l\'ASF'),
            if (s.tauxHandicap != null && s.tauxHandicap! > 0) ...[
              infoRow('Taux d\'incapacite reconnu :', '${s.tauxHandicap}%'),
              infoRow('Situation de vie (handicap) :', s.situationVie.label),
              if (s.besoinTiercePersonne) infoRow('Aide humaine quotidienne :', 'Oui'),
            ],
            if (s.congeParental != CongeParental.aucun)
              infoRow('Conge parental :', s.congeParental == CongeParental.tauxPlein ? 'Temps plein' : 'Mi-temps'),

            // ══ AIDES AVEC ÉCART ══════════════════════════════════════════════
            if (ecart != null && ecart.ecartTotal > 0) ...[
              section('2. Aides avec ecart detecte'),
              pw.Text(
                'Les aides ci-dessous presentent un ecart entre le montant theorique calcule et le montant que vous percevez. Ces calculs sont effectues sur la base des baremes officiels en vigueur (Decrets 2026-220 a 2026-229).',
                style: ts(9.5, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 10),
              ...aideKeys
                .where((k) => (ecart.ecarts[k] ?? 0) > 0)
                .map((k) => aideBlock(k)),
            ],

            // ══ DROITS CALCULÉS — DÉTAIL COMPLET (sans duplication) ══════════
            section('${ecart != null && ecart.ecartTotal > 0 ? "3" : "2"}. Detail complet des droits calcules'),
            pw.Text(
              'Chaque aide est calculee individuellement sur la base de votre situation declaree. Les formules et references legales applicables sont indiquees pour chaque aide.',
              style: ts(9.5, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 10),
            // N'afficher ici QUE les aides sans ecart (les autres sont deja en section 2)
            ...aidesActives.where((k) => !aidesAvecEcart.contains(k)).map((k) => aideBlock(k)),

            // ══ AIDES NON RÉCLAMÉES ═══════════════════════════════════════════
            if (aidesNonReclamees.isNotEmpty) ...[
              section('${ecart != null && ecart.ecartTotal > 0 ? "4" : "3"}. Aides non reclamees'),
              pw.Text(
                'Les aides suivantes semblent dues selon votre profil mais n\'ont pas ete declarees comme percues. Rapprochez-vous de votre CAF pour verifier votre dossier.',
                style: ts(9.5, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 8),
              ...aidesNonReclamees.map((k) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Row(children: [
                  pw.Text('- ${AppTheme.aideLabels[k] ?? k} : ',
                    style: ts(10, bold: true)),
                  pw.Text(
                    k == 'ars'
                      ? '${(_getAideMontant(droits, k) * 12).toStringAsFixed(0)} \u20AC/an (vers\u00e9e en ao\u00fbt)'
                      : '${_getAideMontant(droits, k).toStringAsFixed(2)} \u20AC/mois estim\u00e9s',
                    style: ts(10, color: PdfColors.orange800)),
                ]),
              )),
            ],

            // ══ AIDES MÉCONNUES ════════════════════════════════════════════════
            if (response.suggestions.isNotEmpty) ...[
              section('Aides complementaires selon votre profil'),
              ...response.suggestions.map((sug) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('> ${sug.titre}', style: ts(10.5, bold: true)),
                    pw.Text('  ${sug.description}', style: ts(9.5, color: PdfColors.grey700)),
                    pw.Text('  Contact : ${sug.source}', style: ts(9, color: PdfColors.grey600)),
                  ],
                ),
              )),
            ],

            // ══ SOURCES LÉGALES ════════════════════════════════════════════════
            section('Sources et references legales'),
            pw.Text(
              'Ce rapport est etabli sur la base des baremes officiels en vigueur au 1er avril 2026 (Decrets n 2026-220 a 2026-229 du 30/03/2026). '
              'Les montants sont des estimations - le calcul definitif appartient a la CAF, qui peut tenir compte d\'elements non renseignes dans ce simulateur.\n\n'
              'References applicables a votre simulation :',
              style: ts(9, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 6),
            ...aidesActives.map((k) {
              final detail = droits.details[k] ?? '';
              final refs = RegExp(r'\[([^\]]+)\]').allMatches(detail).map((m) => m.group(1)!).toList();
              if (refs.isEmpty) return pw.SizedBox();
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 3),
                child: pw.Text(
                  '${AppTheme.aideLabels[k] ?? k} : ${refs.join(' - ')}',
                  style: ts(9, color: PdfColors.grey700),
                ),
              );
            }),

            pw.SizedBox(height: 16),
            pw.Divider(color: PdfColors.grey300, thickness: 0.5),
            pw.SizedBox(height: 4),
            pw.Text(
              AppConstants.calculDisclaimer,
              style: ts(8, color: PdfColors.grey500),
            ),
          ],
        ),
      );

      final bytes = await doc.save();
      if (kIsWeb) {
        downloadPdfWeb(bytes, 'rapport_alloccheck_${now.millisecondsSinceEpoch}.pdf');
      } else {
        await Printing.sharePdf(
          bytes: bytes,
          filename: 'rapport_alloccheck_${now.millisecondsSinceEpoch}.pdf',
        );
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
      case 'mva': return droits.mva;
      case 'asf': return droits.asf;
      case 'aeeh': return droits.aeeh;
      default: return 0;
    }
  }

  Future<void> _loadUnlockStatus() async {
    final unlocked = await PaymentService.isUnlockedForSim(widget.simId);
    final justUnlocked = await PaymentService.consumeJustUnlocked();
    if (mounted) {
      setState(() {
        _isUnlocked = unlocked;
        _justUnlocked = justUnlocked;
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
          // Toujours visible : carte teaser (résumé + montants globaux)
          if (hasEcart)
            _buildAlertEcartCard(response.droits, response.ecart!)
          else
            _buildTotalCard(response.droits, response.ecart != null),

          // Teaser aides non réclamées (visible en gratuit)
          if (!_isUnlocked && response.ecart != null && response.ecart!.aidesNonReclamees.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.error.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.new_releases, color: AppTheme.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${response.ecart!.aidesNonReclamees.length} aide(s) que vous ne percevez pas et auxquelles vous avez droit',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // CTA ancré
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

            if (response.ecart != null && response.ecart!.aidesNonReclamees.isNotEmpty) ...[
              _buildAidesNonReclameesSection(response.ecart!.aidesNonReclamees, response.droits),
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

  Widget _buildAidesNonReclameesSection(List<String> aides, DroitsResult droits) {
    return Card(
      color: AppTheme.error.withValues(alpha: 0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.error.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.new_releases, color: AppTheme.error, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Aides non réclamées',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.error,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Vous êtes éligible à ces aides mais ne les percevez pas. Faites-en la demande auprès de votre CAF.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 12),
            ...aides.map((aide) {
              final label = AppTheme.aideLabels[aide] ?? aide;
              final montant = _getAideMontant(droits, aide);
              final icon = AppTheme.aideIcons[aide] ?? Icons.euro;
              final color = AppTheme.aideColors[aide] ?? AppTheme.primary;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: color.withValues(alpha: 0.1),
                      radius: 16,
                      child: Icon(icon, color: color, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                    Text(
                      aide == 'ars'
                        ? '+${(montant * 12).toStringAsFixed(0)} €/an (août)'
                        : '+${montant.toStringAsFixed(0)} €/mois',
                      style: TextStyle(
                        color: AppTheme.error,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
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
            onPressed: () => PaymentService.saveSituationAndOpenStripe(
                widget.situation, widget.simId),
            icon: const Icon(Icons.lock_open),
            label: const Text('Débloquer mon rapport — 0,99 €'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _buildLegalConsentText(),
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
      ],
    );
  }

  Widget _buildLegalConsentText() {
    return Text.rich(
      TextSpan(
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: AppTheme.textSecondary, fontSize: 10),
        children: [
          const TextSpan(text: 'En payant, vous acceptez nos '),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pushNamed('/terms'),
              child: Text(
                'CGU',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: AppTheme.textSecondary,
                      decoration: TextDecoration.underline,
                    ),
              ),
            ),
          ),
          const TextSpan(text: ' et notre '),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pushNamed('/privacy'),
              child: Text(
                'politique de confidentialité',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: AppTheme.textSecondary,
                      decoration: TextDecoration.underline,
                    ),
              ),
            ),
          ),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  // ── EARLY CTA (ancré juste après le chiffre d'écart) ────────────────────

  Widget _buildEarlyCta() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => PaymentService.saveSituationAndOpenStripe(
            widget.situation, widget.simId),
        icon: const Icon(Icons.lock_open, size: 18),
        label: const Text('Voir le rapport complet — 0,99 €'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  // ── BANNIÈRE CONFIRMATION DÉVERROUILLAGE ─────────────────────────────────

  Widget _buildAccessCodeBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline,
              color: AppTheme.secondary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Rapport débloqué — merci pour votre achat !',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.secondary,
                    fontWeight: FontWeight.w700,
                  ),
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
      'mva': droits.mva,
      'asf': droits.asf,
      'aeeh': droits.aeeh,
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
