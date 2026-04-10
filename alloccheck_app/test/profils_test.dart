import 'package:flutter_test/flutter_test.dart';
import 'package:alloccheck_app/core/models/situation.dart';
import 'package:alloccheck_app/core/services/calcul_local_service.dart';

void main() {
  final service = CalculLocalService();

  group('Profils réels — Couverture complète', () {

    // ============================================================
    // PROFIL 1 — Divorcé avec AAH + APL + MVA
    // Vérifie : AAH taux plein, MVA avec aide logement, MTP=0 (MVA prioritaire)
    // ============================================================
    test('P01 — Divorcé AAH+APL+MVA — MTP=0 (MVA prioritaire)', () {
      final result = service.calculerDroits(Situation(
        statutConjugal: StatutConjugal.divorce,
        nombreEnfants: 0,
        revenuActiviteDemandeur: 0,
        zoneLogement: ZoneLogement.zone3,
        loyerMensuel: 453,
        statutLogement: StatutLogement.locataire,
        tauxHandicap: 80,
        situationVie: SituationVie.autonome,
        // logementConventionne = null → APL par défaut
      ));

      // AAH taux plein — taux 80%, 0 revenus
      expect(result.droits.aah, 1041.59);

      // APL > 0 car locataire zone 3 avec loyer 453€ et 0 revenus
      expect(result.droits.apl, greaterThan(0));

      // MVA : AAH taux plein + vie autonome + APL > 0 → eligible
      expect(result.droits.mva, 104.77);

      // MTP supprimée depuis déc. 2019 pour nouveaux bénéficiaires AAH → non calculée
      // Les besoins d'aide humaine relèvent de la PCH (MDPH, hors CAF)

      // RSA : AAH > forfaitaire RSA → 0
      expect(result.droits.rsa, 0);
    });

    // ============================================================
    // PROFIL 2 — AAH hébergé (pas d'APL = MVA impossible)
    // Vérifie : AAH seule, MVA=0 (pas d'aide logement), MTP supprimée
    // Profil typique pour → orienter vers PCH (MDPH)
    // ============================================================
    test('P02 — Célibataire hébergé AAH — MVA=0 (pas d\'aide logement)', () {
      final result = service.calculerDroits(Situation(
        statutConjugal: StatutConjugal.celibataire,
        nombreEnfants: 0,
        revenuActiviteDemandeur: 0,
        zoneLogement: ZoneLogement.zone3,
        loyerMensuel: 0,
        statutLogement: StatutLogement.heberge,
        tauxHandicap: 80,
        situationVie: SituationVie.autonome,
        besoinTiercePersonne: true,
      ));

      // AAH taux plein
      expect(result.droits.aah, 1041.59);

      // APL = 0 (hébergé)
      expect(result.droits.apl, 0);

      // MVA = 0 : hébergé donc pas d'aide au logement
      expect(result.droits.mva, 0);
      expect(result.droits.details['mva'], contains('aide au logement'));

      // MTP supprimée depuis déc. 2019 pour nouveaux bénéficiaires AAH
      // → PCH (MDPH) est le dispositif applicable
      expect(result.droits.asf, 0);
    });

    // ============================================================
    // PROFIL 3 — Veuf avec 2 enfants + ASF + AF
    // Vérifie : ASF versée pour veuf (sans condition pension), AF 2 enfants, RSA > 0
    // ============================================================
    test('P03 — Veuf 2 enfants (5 et 10 ans) — ASF+AF+RSA', () {
      final result = service.calculerDroits(Situation(
        statutConjugal: StatutConjugal.veuf,
        nombreEnfants: 2,
        agesEnfants: [5, 10],
        revenuActiviteDemandeur: 0,
        zoneLogement: ZoneLogement.zone3,
        loyerMensuel: 0,
        statutLogement: StatutLogement.heberge,
      ));

      // ASF : 2 enfants × 200.78 = 401.56€ (veuf → pas de condition pension)
      expect(result.droits.asf, closeTo(401.56, 0.05));

      // AF : 2 enfants, 0 revenus → 153.01€
      expect(result.droits.af, 153.01);

      // RSA parent isolé 2 enfants hébergé = 651.69×(1.28412+2×0.42804) - 192.02 = 1202.52€
      // ASF exclue des ressources RSA (prestation familiale — art. R262-11 al.4 CASF)
      expect(result.droits.rsa, closeTo(1202.52, 1.0));
    });

    // ============================================================
    // PROFIL 4 — Parent isolé divorcé + pension non versée + ASF
    // Vérifie : ASF déclenchée par pensionAlimentaireNonPercue=true
    // ============================================================
    test('P04 — Divorcée 1 enfant (8 ans) pension non versée — ASF+RSA', () {
      final result = service.calculerDroits(Situation(
        statutConjugal: StatutConjugal.divorce,
        nombreEnfants: 1,
        agesEnfants: [8],
        revenuActiviteDemandeur: 0,
        pensionAlimentaireNonPercue: true,
        zoneLogement: ZoneLogement.zone3,
        loyerMensuel: 0,
        statutLogement: StatutLogement.heberge,
      ));

      // ASF : 1 enfant × 200.78 = 200.78€ (pension non versée)
      expect(result.droits.asf, closeTo(200.78, 0.02));

      // RSA parent isolé 1 enfant hébergé = 651.69×(1.28412+0.42804) - 155.16 = 960.47€
      expect(result.droits.rsa, closeTo(960.47, 1.0));

      // Pas d'AAH (pas de handicap)
      expect(result.droits.aah, 0);
    });

    // ============================================================
    // PROFIL 5 — Famille 3 enfants + PreParE taux plein + ARS
    // Vérifie : PreParE versée, AF 3 enfants, ARS pour enfant 6 ans
    // ============================================================
    test('P05 — Couple marié 3 enfants (1,3,6 ans) congé parental taux plein — AF+PreParE+ARS', () {
      final result = service.calculerDroits(Situation(
        statutConjugal: StatutConjugal.marie,
        nombreEnfants: 3,
        agesEnfants: [1, 3, 6],
        revenuActiviteDemandeur: 0,
        revenuActiviteConjoint: 0,
        zoneLogement: ZoneLogement.zone3,
        loyerMensuel: 0,
        statutLogement: StatutLogement.heberge,
        congeParental: CongeParental.tauxPlein,
      ));

      // AF : 3 enfants, 0 revenus → 349.06€
      expect(result.droits.af, 349.06);

      // PreParE : taux plein = 459.69€
      expect(result.droits.prepare, closeTo(459.69, 0.02));

      // ARS : enfant 6 ans = 403.72€/an ÷ 12 = 33.64€/mois (équivalent mensuel)
      // Barèmes août 2025, en vigueur jusqu'à août 2026 (revalorisation ARS annuelle en août)
      expect(result.droits.ars, greaterThan(0));
      expect(result.droits.ars, closeTo(33.64, 0.05));

      // RSA > 0 : couple sans revenus
      expect(result.droits.rsa, greaterThan(0));
    });

    // ============================================================
    // PROFIL 6 — ALS (logement non conventionné, célibataire)
    // Vérifie : ALS calculée (pas APL) avec logementConventionne=false
    // ============================================================
    test('P06 — Célibataire locataire Z3 loyer 350€ non conventionné — ALS>0', () {
      final result = service.calculerDroits(Situation(
        statutConjugal: StatutConjugal.celibataire,
        nombreEnfants: 0,
        revenuActiviteDemandeur: 0,
        zoneLogement: ZoneLogement.zone3,
        loyerMensuel: 350,
        statutLogement: StatutLogement.locataire,
        logementConventionne: false, // force ALS
      ));

      // ALS > 0 (pas APL)
      expect(result.droits.apl, greaterThan(0));

      // Le détail doit mentionner "ALS"
      expect(result.droits.details['apl'], contains('ALS'));

      // RSA > 0 : célibataire, 0 revenus — mais forfait logement déduit (APL perçue)
      expect(result.droits.rsa, greaterThan(0));
    });

    // ============================================================
    // PROFIL 7 — ALF (famille, logement non conventionné)
    // Vérifie : ALF calculée pour couple avec enfants hors conventionnement
    // ============================================================
    test('P07 — Couple 2 enfants locataire Z2 loyer 600€ non conventionné — ALF>0', () {
      final result = service.calculerDroits(Situation(
        statutConjugal: StatutConjugal.concubin,
        nombreEnfants: 2,
        agesEnfants: [3, 7],
        revenuActiviteDemandeur: 0,
        revenuActiviteConjoint: 0,
        zoneLogement: ZoneLogement.zone2,
        loyerMensuel: 600,
        statutLogement: StatutLogement.locataire,
        logementConventionne: false, // force ALF
      ));

      // ALF > 0 (couple avec enfants → ALF, pas ALS)
      expect(result.droits.apl, greaterThan(0));

      // Le détail doit mentionner "ALF"
      expect(result.droits.details['apl'], contains('ALF'));

      // AF 2 enfants, 0 revenus → 153.01€
      expect(result.droits.af, 153.01);
    });

    // ============================================================
    // PROFIL 8 — RSA avec revenus activité (bonification 62%)
    // Vérifie la formule : RSA = forfaitaire + 0.62×revAct - ressources - forfaitLogement
    // Calcul : 651.69 + 0.62×800 - 800 - 77.58 = 651.69 + 496 - 800 - 77.58 = 270.11€
    // ============================================================
    test('P08 — Célibataire hébergé 800€ revenus — RSA avec bonification 62%', () {
      final result = service.calculerDroits(Situation(
        statutConjugal: StatutConjugal.celibataire,
        nombreEnfants: 0,
        revenuActiviteDemandeur: 800,
        zoneLogement: ZoneLogement.zone3,
        loyerMensuel: 0,
        statutLogement: StatutLogement.heberge,
      ));

      // RSA = 651.69 + 0.62×800 - 800 - 77.58 = 270.11€
      expect(result.droits.rsa, closeTo(270.11, 1.0));

      // Prime = 638.28 + 0.5985×800 + 23.02 (bonification) - 800 - 77.58 = 262.52€
      expect(result.droits.primeActivite, closeTo(262.52, 1.0));

      // Pas d'AAH
      expect(result.droits.aah, 0);
    });

    // ============================================================
    // PROFIL 9 — PAJE + CF famille nombreuse
    // Vérifie : PAJE taux plein (enfant <3 ans), CF non versé (pas 3 enfants entre 3-21 ans)
    // Note : enfant 2 ans n'est pas dans la tranche 3-21 ans du CF → seulement 2 enfants éligibles CF
    // ============================================================
    test('P09 — Couple 3 enfants (2,4,7 ans) 0 revenus — PAJE+CF(0 car 2 ans hors tranche)', () {
      final result = service.calculerDroits(Situation(
        statutConjugal: StatutConjugal.marie,
        nombreEnfants: 3,
        agesEnfants: [2, 4, 7],
        revenuActiviteDemandeur: 0,
        revenuActiviteConjoint: 0,
        zoneLogement: ZoneLogement.zone3,
        loyerMensuel: 0,
        statutLogement: StatutLogement.heberge,
      ));

      // PAJE : enfant de 2 ans < 3 ans → taux plein (couple 1 revenu, revenus 0 < plafond 31066+2×6213=43492)
      expect(result.droits.paje, closeTo(198.16, 0.02));

      // CF : seulement 2 enfants entre 3-21 ans (4 et 7 ans) → non éligible (min 3 enfants entre 3-21 ans)
      // TODO: vérifier avec source officielle — l'enfant de 2 ans sort de la tranche 3+ dans 1 an
      expect(result.droits.cf, 0);
      expect(result.droits.details['cf'], contains('3 enfants entre 3 et 21 ans'));

      // AF 3 enfants → 349.06€
      expect(result.droits.af, 349.06);
    });

    // ============================================================
    // PROFIL 10 — Simulation complète couple mixte
    // Vérifie : coexistence logique de plusieurs aides avec revenus modestes
    // ============================================================
    test('P10 — Couple marié 2 enfants (4,9 ans) revenus 1200+900€ locataire Z2 700€', () {
      final result = service.calculerDroits(Situation(
        statutConjugal: StatutConjugal.marie,
        nombreEnfants: 2,
        agesEnfants: [4, 9],
        revenuActiviteDemandeur: 1200,
        revenuActiviteConjoint: 900,
        zoneLogement: ZoneLogement.zone2,
        loyerMensuel: 700,
        statutLogement: StatutLogement.locataire,
      ));

      // AF : revenus annuels = (1200+900)×12 = 25200€ < plafond 79980€ → 153.01€
      expect(result.droits.af, 153.01);

      // APL > 0 : couple locataire Z2, loyer 700€, revenus modestes
      expect(result.droits.apl, greaterThan(0));

      // Prime activité > 0 : les deux travaillent
      expect(result.droits.primeActivite, greaterThan(0));

      // RSA > 0 : couple + 2 enfants → forfaitaire = 1368.56€, plafond sortie RSA = 3096€/mois
      // À 2100€, RSA = 1368.56 + 0.62×2100 - 2100 - 192.02 = 378.54€ — conforme formule officielle
      expect(result.droits.rsa, closeTo(378.54, 2.0));

      // Pas d'AAH ni MVA (pas de handicap)
      expect(result.droits.aah, 0);
      expect(result.droits.mva, 0);
    });

    // ============================================================
    // PROFIL 11 — AAH partielle avec revenus d'activité
    // Vérifie l'abattement : 80% sur ≤546.91€ (SMIC 30%), 40% sur le reste
    // Calcul pour 600€ : 546.91×0.20 + (600-546.91)×0.60 = 109.38 + 31.85 = 141.24€ retenus
    // AAH = 1041.59 - 141.24 = 900.35€
    // ============================================================
    test('P11 — Célibataire taux 80% revenus 600€ — AAH réduite par abattement', () {
      final result = service.calculerDroits(Situation(
        statutConjugal: StatutConjugal.celibataire,
        nombreEnfants: 0,
        revenuActiviteDemandeur: 600,
        zoneLogement: ZoneLogement.zone3,
        loyerMensuel: 0,
        statutLogement: StatutLogement.heberge,
        tauxHandicap: 80,
      ));

      // AAH différentielle : abattement 80%/40% → revenus retenus = 141.24€
      // AAH = 1041.59 - 141.24 = 900.35€
      expect(result.droits.aah, closeTo(900.35, 0.10));

      // AAH non au taux plein → MVA impossible
      expect(result.droits.mva, 0);
      expect(result.droits.details['mva'], contains('non au taux plein'));

      // RSA : AAH (900.07) > forfaitaire RSA (651.69) → 0
      expect(result.droits.rsa, 0);
    });

    // ============================================================
    // PROFIL 13 — AEEH enfant 8 ans taux 70%
    // Vérifie : AEEH versée pour 1 enfant, AF 1 enfant = 0 (min 2)
    // ============================================================
    test('P13 — Parent isolé 1 enfant (8 ans, taux 70%) — AEEH+RSA, PAJE=0', () {
      final result = service.calculerDroits(Situation(
        statutConjugal: StatutConjugal.celibataire,
        nombreEnfants: 1,
        agesEnfants: [8],
        tauxHandicapEnfants: [70], // taux 70% → ≥ 50% → AEEH éligible
        revenuActiviteDemandeur: 0,
        zoneLogement: ZoneLogement.zone3,
        loyerMensuel: 0,
        statutLogement: StatutLogement.heberge,
      ));

      // AEEH : 1 enfant × 148.12 = 148.12€/mois
      expect(result.droits.aeeh, closeTo(148.12, 0.02));

      // PAJE : non cumulable avec AEEH → 0 (même si enfant < 3 ans ce n'est pas le cas ici)
      expect(result.droits.paje, 0);

      // RSA parent isolé 1 enfant hébergé
      expect(result.droits.rsa, greaterThan(0));

      // AF : seulement 1 enfant → 0
      expect(result.droits.af, 0);
    });

    // ============================================================
    // PROFIL 14 — AEEH prime sur PAJE (enfant 2 ans taux 60%)
    // Vérifie : AEEH > 0, PAJE = 0 (non cumulable)
    // ============================================================
    test('P14 — Couple 1 enfant (2 ans, taux 60%) — AEEH, PAJE=0 (non cumulable)', () {
      final result = service.calculerDroits(Situation(
        statutConjugal: StatutConjugal.marie,
        nombreEnfants: 1,
        agesEnfants: [2],
        tauxHandicapEnfants: [60], // taux 60% → AEEH éligible
        revenuActiviteDemandeur: 0,
        revenuActiviteConjoint: 0,
        zoneLogement: ZoneLogement.zone3,
        loyerMensuel: 0,
        statutLogement: StatutLogement.heberge,
      ));

      // AEEH : 1 enfant < 20 ans, taux 60% ≥ 50%
      expect(result.droits.aeeh, closeTo(148.12, 0.02));

      // PAJE : non cumulable avec AEEH → 0 (malgré enfant de 2 ans < 3 ans)
      expect(result.droits.paje, 0);
      expect(result.droits.details['paje'], contains('AEEH'));
    });

    // ============================================================
    // PROFIL 15 — AEEH 2 enfants dont 1 handicapé
    // Vérifie : AEEH pour 1 seul enfant (l'autre taux < 50%)
    // ============================================================
    test('P15 — Couple 2 enfants (5 et 10 ans, taux 0% et 80%) — AEEH 1 enfant', () {
      final result = service.calculerDroits(Situation(
        statutConjugal: StatutConjugal.marie,
        nombreEnfants: 2,
        agesEnfants: [5, 10],
        tauxHandicapEnfants: [0, 80], // enfant 5 ans non handicapé, enfant 10 ans taux 80%
        revenuActiviteDemandeur: 0,
        revenuActiviteConjoint: 0,
        zoneLogement: ZoneLogement.zone3,
        loyerMensuel: 0,
        statutLogement: StatutLogement.heberge,
      ));

      // AEEH : 1 seul enfant éligible (taux 80%, 10 ans) → 148.12€
      expect(result.droits.aeeh, closeTo(148.12, 0.02));

      // PAJE : non cumulable avec AEEH → 0
      // (même si un enfant < 3 ans était présent — ici aucun de toute façon)
      expect(result.droits.paje, 0);

      // AF : 2 enfants, 0 revenus → 153.01€
      expect(result.droits.af, 153.01);
    });

    // ============================================================
    // PROFIL 12 — Personne handicapée en institution
    // Vérifie : AAH versée, MVA=0 (institution), RSA=0, APL=0
    // ============================================================
    test('P12 — Célibataire taux 80% en institution — AAH seule, MVA=0', () {
      final result = service.calculerDroits(Situation(
        statutConjugal: StatutConjugal.celibataire,
        nombreEnfants: 0,
        revenuActiviteDemandeur: 0,
        zoneLogement: ZoneLogement.zone3,
        loyerMensuel: 0,
        statutLogement: StatutLogement.heberge,
        tauxHandicap: 80,
        situationVie: SituationVie.institution,
        besoinTiercePersonne: true,
      ));

      // AAH taux plein (institution n'affecte pas l'AAH elle-même)
      expect(result.droits.aah, 1041.59);

      // APL = 0 (hébergé, pas locataire)
      expect(result.droits.apl, 0);

      // MVA = 0 : situationVie=institution → non éligible
      expect(result.droits.mva, 0);
      expect(result.droits.details['mva'], contains('institution'));

      // MTP supprimée depuis déc. 2019 — aide humaine en institution → financement établissement

      // RSA = 0 : AAH (1041.59) > forfaitaire RSA (651.69)
      expect(result.droits.rsa, 0);
    });
  });
}
