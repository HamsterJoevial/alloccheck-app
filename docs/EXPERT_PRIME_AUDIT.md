# AUDIT EXPERT — Prime d'activite (calcul local)

**Date** : 6 avril 2026
**Fichier audite** : `lib/core/services/calcul_local_service.dart`
**Methode** : `_calculerPrimeActivite` (lignes 737-779)
**Sources** : WebSearch systematique — aucune valeur de memoire

---

## 1. Montant forfaitaire base — `_primeBase = 638.28`

| Element | Code | Valeur officielle avril 2026 | Verdict |
|---------|------|------------------------------|---------|
| Forfaitaire personne seule | 638.28 | 638.28 | **CORRECT** |

Sources : Service-Public.fr (actualite A18815), Previssima, Wizbii, Quelles-Aides — tous confirment 638,28 EUR au 1er avril 2026.

---

## 2. Majorations couple/enfants

| Majoration | Code | Valeur officielle | Verdict |
|------------|------|-------------------|---------|
| Couple (+50%) | 0.5 | +50% | **CORRECT** |
| Enfant 1-2 (+30%) | 0.3 | +30% | **CORRECT** |
| Enfant 3+ (+40%) | 0.4 | +40% | **CORRECT** |

Ces pourcentages sont identiques a ceux du RSA et sont confirmes par toutes les sources.

---

## 3. Taux de prise en compte des revenus d'activite — `0.5985`

| Element | Code | Valeur officielle avril 2026 | Verdict |
|---------|------|------------------------------|---------|
| Taux revenus pro | 59.85% | 59.85% | **CORRECT** |

Le taux a ete abaisse de 61% a 59.85% dans le cadre de la reforme d'avril 2026 (Decret n 2026-222). Le code est a jour.

**Note** : Certaines sources anciennes ou non mises a jour affichent encore 61%. Le code applique correctement le nouveau taux.

Sources : economie.gouv.fr, Previssima, aide-sociale.fr

---

## 4. Bonification individuelle

| Element | Code | Valeur officielle avril 2026 | Verdict |
|---------|------|------------------------------|---------|
| Bonification max | 240.63 | 240.63 | **CORRECT** |
| Seuil min (debut bonif) | 709.18 | 709.18 | **CORRECT** |
| Seuil max (bonif plafonnee) | 1658.76 | 1658.76 | **CORRECT** |

La bonification max est passee de 184.27 EUR a 240.63 EUR au 1er avril 2026 (+56.36 EUR). Le seuil max a ete releve a 1658.76 EUR (environ 1.15 SMIC). Le code est a jour.

Sources : CAF.fr (bareme prime activite), Previssima, Wizbii, aide-sociale.fr

**Verification de la formule de bonification** :
```
si revenu < 709.18 : bonification = 0
si revenu >= 709.18 : bonification = ((revenu - 709.18) / (1658.76 - 709.18)) * 240.63
plafonne a 240.63
```
Le code applique exactement cette formule avec `.clamp(0.0, 1.0)`. **CORRECT**.

---

## 5. Formule complete

**Code** :
```
prime = forfaitaire + 0.5985 * revenusActivite + bonification - ressources
```

**Formule officielle** :
```
prime = forfaitaire + 59.85% * revenus_activite + bonification - ressources - forfait_logement
```

| Element | Present dans le code | Verdict |
|---------|---------------------|---------|
| Forfaitaire majore | Oui | CORRECT |
| 59.85% revenus activite | Oui | CORRECT |
| Bonification individuelle | Oui | CORRECT |
| Ressources deduites | Oui | CORRECT |
| **Forfait logement** | **NON** | **BUG CRITIQUE** |

---

## 6. AAH exclue des ressources — art. R844-5 CSS

Le code ne passe pas l'AAH dans les ressources de la prime d'activite (ligne 200 : `_calculerPrimeActivite(situation)` sans parametre `aahMensuel`). **CORRECT**.

Cependant, la situation est plus nuancee que ce que le code implique :
- L'AAH est bien **exclue des ressources** au sens de l'article R844-5 CSS.
- Mais l'AAH est **prise en compte comme revenu professionnel** dans le calcul de la prime d'activite (assimilee a un revenu d'activite pour les travailleurs handicapes).
- Le Senat a vote en decembre 2025 pour maintenir cette prise en compte.

**Le code est correct sur l'exclusion des ressources**, mais pourrait sous-estimer la prime pour les beneficiaires AAH qui travaillent, car l'AAH devrait etre ajoutee cote "revenus d'activite" dans la formule (pas cote ressources). C'est un point complexe qui depend de l'interpretation CAF.

### Autres ressources exclues (art. R844-5 CSS) — non verifiees dans le code

L'article R844-5 liste 26 types de ressources exclues, notamment :
- Prime a la naissance / adoption
- Allocation de rentrée scolaire (ARS)
- Complement de libre choix du mode de garde (CMG)
- AEEH et ses complements
- Majoration pour age des allocations familiales

Le code ne filtre pas explicitement ces ressources car elles ne sont pas saisies dans `totalAutresRevenus`. **OK** si l'interface de saisie ne permet pas de les declarer.

---

## 7. Forfait logement — BUG CRITIQUE

| Situation | Forfait logement a deduire (avril 2026) | Applique dans le code |
|-----------|----------------------------------------|----------------------|
| 1 personne percoit APL/hebergee/proprio | ~77.58 EUR | **NON** |
| 2 personnes | ~155.16 EUR | **NON** |
| 3+ personnes | ~192.02 EUR | **NON** |

**Le forfait logement s'applique a la prime d'activite exactement comme au RSA.** Si le demandeur :
- percoit une aide au logement (APL/ALS/ALF), OU
- est heberge a titre gratuit, OU
- est proprietaire sans charges de logement

...alors un forfait logement est **ajoute aux ressources** (= deduit de la prime).

Le code RSA applique correctement ce forfait (`_calculerRSA` ligne 568-575). Mais `_calculerPrimeActivite` **ne le fait pas du tout**.

**Impact** : Le code **surestime** systematiquement la prime d'activite de 77 a 192 EUR/mois pour tout beneficiaire ayant une aide au logement ou heberge gratuitement.

Sources : aide-sociale.fr ("Forfait logement RSA ou prime activite"), mes-allocs.fr, quelles-aides.fr, ma-prime-activite.fr

---

## 8. Pension alimentaire versee — deductible des ressources ?

| Element | Code | Realite | Verdict |
|---------|------|---------|---------|
| Pension versee deduite des ressources | Oui (ligne 763) | **NON** | **BUG** |

**Les pensions alimentaires versees ne sont PAS deductibles des ressources pour le calcul de la prime d'activite.** Le calcul de la prime d'activite ne tient pas compte des charges que l'allocataire verse a des tiers (loyer, pension, etc.).

En revanche, les pensions alimentaires **recues** sont bien comptees dans les ressources.

Le code RSA deduit correctement la pension versee (art. R262-6 CASF), mais cette deduction ne s'applique **pas** a la prime d'activite.

**Impact** : Le code **surestime** la prime pour les personnes versant une pension alimentaire.

Sources : ma-prime-activite.fr ("Faut-il declarer une pension alimentaire"), CAF.fr (Charente), primeactivite.fr, planete-separation.fr

---

## 9. Conditions d'eligibilite

| Condition | Presente dans le code | Verdict |
|-----------|----------------------|---------|
| Revenus d'activite > 0 | Oui (ligne 739) | CORRECT |
| Age >= 18 ans | **NON** | **MANQUANT** |
| Residence en France >= 9 mois/an | **NON** | Non verifiable (pas de champ) |
| Nationalite / titre de sejour | **NON** | Non verifiable (pas de champ) |

L'absence de verification d'age n'est pas critique si l'app cible des adultes, mais une note dans le disclaimer serait bienvenue. Les conditions de residence et nationalite ne sont pas modelisables dans un simulateur classique.

---

## 10. Majoration parent isole — **ABSENTE DU CODE**

| Element | Valeur officielle avril 2026 | Present dans le code |
|---------|------------------------------|---------------------|
| Majoration isolement base | 128.412% du forfaitaire | **NON** |
| Majoration par enfant | +42.804% du forfaitaire | **NON** |
| Duree | 12 mois sur 18 mois (ou jusqu'aux 3 ans de l'enfant) | **NON** |

**BUG CRITIQUE**. La prime d'activite, comme le RSA, prevoit une majoration pour parent isole. Le code RSA l'implemente (`_rsaMajorationIsolementBase = 1.28412`), mais la methode prime d'activite ne l'applique pas.

Pour un parent isole avec 1 enfant, le forfaitaire majoré serait :
- Base : 638.28 * 1.28412 = ~819.63 EUR (au lieu de 638.28)
- + 1 enfant : 638.28 * 0.42804 = ~273.19 EUR

**Impact** : Le code **sous-estime massivement** la prime d'activite pour les parents isoles. Ecart potentiel de 200 a 500 EUR/mois.

Sources : aide-sociale.fr, mes-allocs.fr, mere-celibataire.fr, quelles-aides.fr, Service-Public.fr

---

## SYNTHESE DES BUGS

| # | Severite | Description | Impact |
|---|----------|-------------|--------|
| 1 | **CRITIQUE** | Forfait logement absent | Surestimation de 77-192 EUR/mois |
| 2 | **CRITIQUE** | Majoration parent isole absente | Sous-estimation de 200-500 EUR/mois pour parents isoles |
| 3 | **MAJEUR** | Pension alimentaire versee deduite a tort | Surestimation pour les payeurs de pension |
| 4 | **MINEUR** | AAH comme revenu pro non modelisee | Sous-estimation possible pour travailleurs handicapes |
| 5 | **INFO** | Pas de verification age >= 18 | Acceptable si cible adulte |

---

## CORRECTIFS RECOMMANDES

### Bug 1 — Forfait logement (CRITIQUE)

Ajouter le parametre `percoitApl` a `_calculerPrimeActivite` et deduire le forfait logement comme dans `_calculerRSA` :

```dart
(double, String) _calculerPrimeActivite(Situation s, {bool percoitApl = false}) {
  // ... calcul existant ...

  // Forfait logement (meme bareme que RSA)
  var forfaitLogement = 0.0;
  if (s.statutLogement == StatutLogement.heberge || s.loyerMensuel == 0 || percoitApl) {
    final nbPersonnes = (s.situationFamiliale == SituationFamiliale.couple ? 2 : 1) + s.nombreEnfants;
    if (nbPersonnes == 1) forfaitLogement = _rsaForfaitLogement1;
    else if (nbPersonnes == 2) forfaitLogement = _rsaForfaitLogement2;
    else forfaitLogement = _rsaForfaitLogement3Plus;
  }

  final prime = forfaitaire + 0.5985 * revenusActivite + bonification - ressources - forfaitLogement;
  // ...
}
```

Et a l'appel (ligne 200) :
```dart
final prime = _calculerPrimeActivite(situation, percoitApl: apl.$1 > 0);
```

### Bug 2 — Majoration parent isole (CRITIQUE)

Ajouter avant le calcul du forfaitaire :

```dart
// Majoration parent isole (art. L844-2 CSS)
if (s.parentIsole) {
  forfaitaire = _primeBase * _rsaMajorationIsolementBase; // 128.412%
  for (var i = 0; i < s.nombreEnfants; i++) {
    forfaitaire += _primeBase * _rsaMajorationIsolementParEnfant; // 42.804%
  }
} else {
  // calcul standard couple/enfants...
}
```

Note : La majoration parent isole est temporaire (12 mois). Le code ne peut pas verifier la duree sans date d'evenement. Mentionner cette limite dans le detail.

### Bug 3 — Pension alimentaire versee (MAJEUR)

Retirer `s.pensionAlimentaireVersee` du calcul des ressources :

```dart
// AVANT (incorrect) :
final ressources = (s.revenuActiviteDemandeur + s.revenuActiviteConjoint
    + s.totalAutresRevenus - s.pensionAlimentaireVersee).clamp(0.0, double.infinity);

// APRES (correct) :
final ressources = s.revenuActiviteDemandeur + s.revenuActiviteConjoint + s.totalAutresRevenus;
```

---

## VALEURS CONFIRMEES CORRECTES

- Montant forfaitaire base : 638.28 EUR **OK**
- Majorations couple/enfants : 50/30/40% **OK**
- Taux revenus activite : 59.85% **OK**
- Bonification max : 240.63 EUR **OK**
- Seuil bonif min : 709.18 EUR **OK**
- Seuil bonif max : 1658.76 EUR **OK**
- AAH exclue des ressources : **OK**

---

## SOURCES

- [Service-Public.fr — Prime d'activite revalorisee avril 2026](https://www.service-public.gouv.fr/particuliers/actualites/A18815)
- [Service-Public.fr — Prime d'activite salarie](https://www.service-public.gouv.fr/particuliers/vosdroits/F2882)
- [Previssima — Nouveaux montants avril 2026](https://www.previssima.fr/actualite/prime-dactivite-quels-sont-les-nouveaux-montants-au-1er-avril-2026.html)
- [aide-sociale.fr — Forfait logement RSA ou prime activite](https://www.aide-sociale.fr/forfait-logement-caf/)
- [aide-sociale.fr — Prime activite majoree isolement](https://www.aide-sociale.fr/prime-activite-majoree-isolement/)
- [aide-sociale.fr — Conditions prime activite](https://www.aide-sociale.fr/conditions-prime-activite/)
- [mes-allocs.fr — Bareme prime activite 2026](https://www.mes-allocs.fr/guides/prime-d-activite/bareme-prime-activite/)
- [mes-allocs.fr — Prime activite majoree isolement montant](https://www.mes-allocs.fr/guides/prime-d-activite/prime-activite-montant/prime-activite-majoree-isolement-montant/)
- [quelles-aides.fr — Montant prime activite](https://quelles-aides.fr/prime-activite/comprendre-prime-activite/montant-prime-activite/)
- [quelles-aides.fr — Prime activite parent isole](https://www.quelles-aides.fr/prime-activite/cas-particuliers-prime-activite/prime-activite-parent-isole/)
- [ma-prime-activite.fr — Pension alimentaire](https://www.ma-prime-activite.fr/pension-alimentaire)
- [ma-prime-activite.fr — Forfait logement APL](https://www.ma-prime-activite.fr/montant-forfaitaire-apl)
- [economie.gouv.fr — Prime d'activite](https://www.economie.gouv.fr/particuliers/vie-en-entreprise/prime-dactivite-pouvez-vous-en-beneficier)
- [CAF.fr — Bareme prime activite](https://www.caf.fr/professionnels/offres-et-services/accompagnement-des-allocataires/bareme-prime-d-activite)
- [Legifrance — Decret 2026-222](https://www.legifrance.gouv.fr/jorf/id/JORFTEXT000053733855)
- [Legifrance — Article R844-5 CSS](https://www.legifrance.gouv.fr/codes/article_lc/LEGIARTI000038929248)
- [handicap.fr — Senat AAH et prime activite](https://informations.handicap.fr/a-senat-l-aah-restera-comptee-dans-la-prime-d-activite-38631.php)
- [CAF.fr — Pension alimentaire et prime activite](https://www.caf.fr/allocataires/caf-de-la-charente/offre-de-service/thematique-libre/les-bons-reflexes-adopter/je-beneficie-de-la-prime-d-activite-ou-du-rsa-et-je-declare-une-pension-alimentaire-aux-services)
