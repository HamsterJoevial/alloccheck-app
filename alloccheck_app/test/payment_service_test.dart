import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alloccheck_app/core/services/payment_service.dart';
import 'package:alloccheck_app/core/models/situation.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PaymentService — isUnlockedForSim', () {
    test('retourne false si aucun unlock enregistré', () async {
      final result = await PaymentService.isUnlockedForSim('sim_001');
      expect(result, isFalse);
    });

    test('retourne true uniquement pour le simId débloqué', () async {
      SharedPreferences.setMockInitialValues({
        'ac_unlocked_sim': 'sim_001',
      });
      expect(await PaymentService.isUnlockedForSim('sim_001'), isTrue);
      expect(await PaymentService.isUnlockedForSim('sim_002'), isFalse);
    });

    test('retourne false si simId différent de celui stocké', () async {
      SharedPreferences.setMockInitialValues({
        'ac_unlocked_sim': 'sim_abc',
      });
      expect(await PaymentService.isUnlockedForSim('sim_xyz'), isFalse);
    });
  });

  group('PaymentService — checkUrlAndUnlock', () {
    test('débloque et retourne un simId quand le token est valide', () async {
      SharedPreferences.setMockInitialValues({
        'ac_pending_sim': 'sim_pending_123',
      });
      final simId = await PaymentService.checkUrlAndUnlock(
          urlToken: 'AC2026UNLOCK');
      expect(simId, equals('sim_pending_123'));

      // Vérifie que l'unlock est bien persisté
      expect(await PaymentService.isUnlockedForSim('sim_pending_123'), isTrue);
    });

    test('retourne null et nettoie le pending quand le token est absent', () async {
      SharedPreferences.setMockInitialValues({
        'ac_pending_sim': 'sim_orphan',
      });
      final simId = await PaymentService.checkUrlAndUnlock(urlToken: null);
      expect(simId, isNull);

      // Le pending doit être nettoyé
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('ac_pending_sim'), isNull);
    });

    test('retourne null quand le token est invalide', () async {
      final simId = await PaymentService.checkUrlAndUnlock(
          urlToken: 'MAUVAIS_TOKEN');
      expect(simId, isNull);
    });

    test('marque justUnlocked après un déverrouillage', () async {
      SharedPreferences.setMockInitialValues({
        'ac_pending_sim': 'sim_001',
      });
      await PaymentService.checkUrlAndUnlock(urlToken: 'AC2026UNLOCK');
      expect(await PaymentService.consumeJustUnlocked(), isTrue);
      // Consommé une seule fois
      expect(await PaymentService.consumeJustUnlocked(), isFalse);
    });

    test('génère un simId de secours si pas de pending au retour Stripe', () async {
      // Pas de pending_sim en storage
      final simId = await PaymentService.checkUrlAndUnlock(
          urlToken: 'AC2026UNLOCK');
      expect(simId, isNotNull);
      expect(simId!.isNotEmpty, isTrue);
    });
  });

  group('PaymentService — saveLastSimulation / getLastSimulation', () {
    test('sauvegarde et restaure une situation', () async {
      final situation = Situation(
        statutConjugal: StatutConjugal.celibataire,
        nombreEnfants: 0,
        agesEnfants: [],
        revenuActiviteDemandeur: 1200,
        revenuActiviteConjoint: 0,
        autresRevenus: [],
        loyerMensuel: 500,
        zoneLogement: ZoneLogement.zone2,
        statutLogement: StatutLogement.locataire,
      );

      await PaymentService.saveLastSimulation(situation, 'sim_save_test');

      final restored = await PaymentService.getLastSimulation();
      expect(restored, isNotNull);
      expect(restored!.revenuActiviteDemandeur, equals(1200));
      expect(restored.loyerMensuel, equals(500));

      final simId = await PaymentService.getLastSimulationSimId();
      expect(simId, equals('sim_save_test'));

      final date = await PaymentService.getLastSimulationDate();
      expect(date, isNotNull);
      expect(date!.difference(DateTime.now()).inSeconds.abs(), lessThan(5));
    });

    test('retourne null si aucune simulation sauvegardée', () async {
      expect(await PaymentService.getLastSimulation(), isNull);
      expect(await PaymentService.getLastSimulationDate(), isNull);
      expect(await PaymentService.getLastSimulationSimId(), isNull);
    });

    test('retourne null et nettoie si le JSON est corrompu', () async {
      SharedPreferences.setMockInitialValues({
        'ac_last_simulation': 'NOT_VALID_JSON{{{',
      });
      expect(await PaymentService.getLastSimulation(), isNull);
      // La clé corrompue doit avoir été supprimée
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('ac_last_simulation'), isNull);
    });
  });

  group('PaymentService — getSavedSituation', () {
    test('retourne null si aucune situation sauvegardée', () async {
      expect(await PaymentService.getSavedSituation(), isNull);
    });

    test('retourne null et nettoie si le JSON est corrompu', () async {
      SharedPreferences.setMockInitialValues({
        'ac_saved_situation': '}{INVALID',
      });
      expect(await PaymentService.getSavedSituation(), isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('ac_saved_situation'), isNull);
    });
  });
}
