import 'package:flutter_test/flutter_test.dart';
import 'package:alloccheck_app/core/models/situation.dart';
import 'package:alloccheck_app/core/services/calcul_local_service.dart';

void main() {
  final service = CalculLocalService();

  group('Barèmes avril 2026 — Décrets 2026-220 à 229', () {

    test('AAH 80%+ sans revenus = 1041.59€, RSA = 0 (non cumulable)', () {
      final result = service.calculerDroits(Situation(
        situationFamiliale: SituationFamiliale.seul,
        nombreEnfants: 0,
        revenuActiviteDemandeur: 0,
        zoneLogement: ZoneLogement.zone3,
        loyerMensuel: 0,
        statutLogement: StatutLogement.heberge,
        tauxHandicap: 80,
      ));

      expect(result.droits.aah, 1041.59);
      // RSA = 0 car AAH (1041.59) > forfaitaire RSA (651.69)
      expect(result.droits.rsa, 0);
      expect(result.droits.details['rsa'], contains('non cumulable'));
      expect(result.droits.details['rsa'], contains('R262-11'));
      expect(result.droits.details['aah'], contains('Déconjugalisée'));
    });

    test('AAH déconjugalisation — revenus conjoint ignorés', () {
      final result = service.calculerDroits(Situation(
        situationFamiliale: SituationFamiliale.couple,
        nombreEnfants: 0,
        revenuActiviteDemandeur: 0,
        revenuActiviteConjoint: 2000, // conjoint gagne 2000€ — ne doit PAS impacter l'AAH
        zoneLogement: ZoneLogement.zone3,
        loyerMensuel: 0,
        statutLogement: StatutLogement.heberge,
        tauxHandicap: 80,
      ));

      // AAH doit rester au max car seul le revenu du demandeur (0) compte
      expect(result.droits.aah, 1041.59);
    });

    test('RSA seul hébergé sans revenus SANS AAH = 651.69 - 77.58 = 574.11€', () {
      final result = service.calculerDroits(Situation(
        situationFamiliale: SituationFamiliale.seul,
        nombreEnfants: 0,
        revenuActiviteDemandeur: 0,
        zoneLogement: ZoneLogement.zone3,
        loyerMensuel: 0,
        statutLogement: StatutLogement.heberge,
        // PAS de handicap = pas d'AAH = RSA plein
      ));

      expect(result.droits.rsa, 574.11);
      expect(result.droits.aah, 0);
    });

    test('RSA couple sans enfants sans revenus hébergés', () {
      final result = service.calculerDroits(Situation(
        situationFamiliale: SituationFamiliale.couple,
        nombreEnfants: 0,
        revenuActiviteDemandeur: 0,
        zoneLogement: ZoneLogement.zone3,
        loyerMensuel: 0,
        statutLogement: StatutLogement.heberge,
      ));

      // couple = 651.69 × 1.5 = 977.535 → 977.54 - forfait 2 pers (155.16) = 822.38
      expect(result.droits.rsa, closeTo(822.38, 0.02));
    });

    test('Prime activité SMIC = bonification maximale', () {
      final result = service.calculerDroits(Situation(
        situationFamiliale: SituationFamiliale.seul,
        nombreEnfants: 0,
        revenuActiviteDemandeur: 1426.30, // SMIC net
        zoneLogement: ZoneLogement.zone2,
        loyerMensuel: 500,
        statutLogement: StatutLogement.locataire,
      ));

      // La prime d'activité pour un SMIC seul devrait être > 0
      expect(result.droits.primeActivite, greaterThan(0));
      expect(result.droits.details['prime_activite'], contains('Décret'));
    });

    test('AF 2 enfants sans revenus = 153.01€', () {
      final result = service.calculerDroits(Situation(
        situationFamiliale: SituationFamiliale.couple,
        nombreEnfants: 2,
        agesEnfants: [5, 8],
        revenuActiviteDemandeur: 0,
        zoneLogement: ZoneLogement.zone3,
        loyerMensuel: 0,
        statutLogement: StatutLogement.heberge,
      ));

      expect(result.droits.af, 153.01);
    });

    test('AF majoration 18+ (pas 14+) depuis mars 2026', () {
      // Enfant de 15 ans = PAS de majoration (ancien barème était 14+, nouveau = 18+)
      final result15 = service.calculerDroits(Situation(
        situationFamiliale: SituationFamiliale.couple,
        nombreEnfants: 3,
        agesEnfants: [5, 10, 15],
        revenuActiviteDemandeur: 0,
        zoneLogement: ZoneLogement.zone3,
        loyerMensuel: 0,
        statutLogement: StatutLogement.heberge,
      ));

      // Enfant de 19 ans = majoration
      final result19 = service.calculerDroits(Situation(
        situationFamiliale: SituationFamiliale.couple,
        nombreEnfants: 3,
        agesEnfants: [5, 10, 19],
        revenuActiviteDemandeur: 0,
        zoneLogement: ZoneLogement.zone3,
        loyerMensuel: 0,
        statutLogement: StatutLogement.heberge,
      ));

      // La différence doit être la majoration 18+
      expect(result19.droits.af - result15.droits.af, closeTo(75.53, 0.01));
    });

    test('Sources légales présentes dans chaque détail', () {
      final result = service.calculerDroits(Situation(
        situationFamiliale: SituationFamiliale.seul,
        nombreEnfants: 0,
        revenuActiviteDemandeur: 0,
        zoneLogement: ZoneLogement.zone3,
        loyerMensuel: 0,
        statutLogement: StatutLogement.heberge,
        tauxHandicap: 80,
      ));

      expect(result.droits.details['rsa'], contains('Décret'));
      expect(result.droits.details['aah'], contains('L821-1'));
      expect(result.disclaimer, contains('2026-220'));
    });
  });
}
