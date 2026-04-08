# Audit Expert RSA -- AllocCheck

**Date** : 6 avril 2026
**Fichier audite** : `lib/core/services/calcul_local_service.dart`
**Methode** : `_calculerRSA`
**Bareme reference** : 1er avril 2026 (Decret n 2026-220 du 30/03/2026)

---

## Synthese

| # | Parametre | Statut | Severite |
|---|-----------|--------|----------|
| 1 | Montant forfaitaire base | CORRECT | - |
| 2 | Majoration couple +50% | CORRECT | - |
| 3 | Majoration enfant 1-2 +30% | CORRECT | - |
| 4 | Majoration enfant 3+ +40% | CORRECT | - |
| 5 | RSA majore -- base 128.412% | CORRECT | - |
| 6 | RSA majore -- par enfant | ERREUR | Haute |
| 7 | Forfait logement (APL) | CORRECT | - |
| 8 | Forfait logement (heberge/proprio) | ERREUR | Moyenne |
| 9 | Conditions forfait logement | APPROXIMATION | Moyenne |
| 10 | Bonification 62% revenus activite | ERREUR | CRITIQUE |
| 11 | AAH comptee comme ressource | CORRECT | - |
| 12 | Pension versee deduite | CORRECT | - |
| 13 | Neutralisation des ressources | ABSENTE | Moyenne |

---

## Detail par parametre

### 1. Montant forfaitaire base

- **Valeur dans l'app** : 651.69 EUR
- **Valeur officielle** : 651.69 EUR
- **Source** : Decret n 2026-220 du 30/03/2026 (JO 31/03/2026) -- revalorisation +0.8% depuis 646.52 EUR
- **Statut** : CORRECT

---

### 2. Majorations couple / enfants

- **Valeur dans l'app** : couple +50%, enfant 1-2 +30%, enfant 3+ +40%
- **Valeur officielle** : couple +50%, chaque personne supplementaire +30%, a partir du 3e enfant +40%
- **Source** : Art. R262-2 CASF -- "Le montant forfaitaire applicable a un foyer compose d'une seule personne est majore de 50 % lorsque le foyer comporte deux personnes. Ce montant est ensuite majore de 30 % pour chaque personne supplementaire presente au foyer [...] la majoration [...] est portee a 40 % a partir de la troisieme personne."
- **Lien** : https://www.legifrance.gouv.fr/codes/article_lc/LEGIARTI000033979137
- **Statut** : CORRECT

---

### 3. RSA majore -- base isolement (128.412%)

- **Valeur dans l'app** : `_rsaMajorationIsolementBase = 1.28412`
- **Valeur officielle** : 128.412% du montant forfaitaire pour personne seule
- **Source** : Art. R262-4 CASF -- "le montant majore est egal a 128,412 % du montant forfaitaire mentionne a l'article L. 262-2 applicable a un foyer compose d'une seule personne"
- **Lien** : https://www.legifrance.gouv.fr/codes/article_lc/LEGIARTI000051258532
- **Statut** : CORRECT

---

### 4. RSA majore -- par enfant

- **Valeur dans l'app** : `_rsaMajorationIsolementParEnfant = 0.4286` (42.86%)
- **Valeur officielle** : 42.804% du montant forfaitaire pour personne seule
- **Source** : Art. R262-4 CASF -- "un supplement egal a 42,804 % du montant forfaitaire applicable a un foyer compose d'une seule personne est ajoute" pour chaque enfant a charge
- **Lien** : https://www.legifrance.gouv.fr/codes/article_lc/LEGIARTI000051258532
- **Statut** : ERREUR

**Impact** : ecart de 0.056 points de pourcentage par enfant, soit ~0.37 EUR/mois/enfant (651.69 x 0.00056). Faible en montant absolu mais incorrect en droit.

**Correction Dart** :
```dart
// AVANT (ERREUR)
static const double _rsaMajorationIsolementParEnfant = 0.4286; // par enfant

// APRES (CORRECT)
static const double _rsaMajorationIsolementParEnfant = 0.42804; // par enfant — art. R262-4 CASF
```

---

### 5. Forfait logement -- beneficiaires aide au logement (APL/ALS/ALF)

- **Valeur dans l'app** : 77.58 EUR (1p), 155.16 EUR (2p), 192.02 EUR (3p+)
- **Valeur officielle** : 77.58 EUR (12% de 646.52 arrondi -- revalorise), 155.16 EUR (16%), 192.02 EUR (16.5%)
- **Source** : Art. R262-9 CASF, baremes aide-sociale.fr confirmes pour avril 2026
- **Lien** : https://www.aide-sociale.fr/forfait-logement-caf/
- **Statut** : CORRECT pour les beneficiaires d'aide au logement

---

### 6. Forfait logement -- heberges / proprietaires (sans aide logement)

- **Valeur dans l'app** : utilise le MEME bareme que pour les beneficiaires APL (77.58 / 155.16 / 192.02)
- **Valeur officielle** : bareme different pour heberges/proprietaires sans aide logement :
  - 1 personne : 77.58 EUR (12% -- identique)
  - 2 personnes : 135.77 EUR (14% du forfaitaire couple)
  - 3+ personnes : 162.92 EUR (14% du forfaitaire 3 personnes)
- **Source** : Art. R262-9 et R262-10 CASF -- deux baremes distincts selon que le beneficiaire percoit ou non une aide au logement
- **Lien** : https://www.aide-sociale.fr/forfait-logement-caf/
- **Statut** : ERREUR

**Impact** : Pour un couple heberge sans APL, l'app deduit 155.16 EUR au lieu de 135.77 EUR, soit un RSA sous-estime de 19.39 EUR/mois. Pour 3+ personnes : 192.02 au lieu de 162.92, ecart de 29.10 EUR/mois.

**Correction Dart** :
```dart
// AVANT (un seul bareme)
static const double _rsaForfaitLogement1 = 77.58;
static const double _rsaForfaitLogement2 = 155.16;
static const double _rsaForfaitLogement3Plus = 192.02;

// APRES (deux baremes distincts)
// Forfait logement — beneficiaires aide au logement (APL/ALS/ALF)
// Art. R262-9 CASF — 12% / 16% / 16.5% du forfaitaire
static const double _rsaForfaitLogementApl1 = 77.58;
static const double _rsaForfaitLogementApl2 = 155.16;
static const double _rsaForfaitLogementApl3Plus = 192.02;

// Forfait logement — heberges ou proprietaires (sans aide logement)
// Art. R262-10 CASF — 12% / 14% / 14% du forfaitaire
static const double _rsaForfaitLogementHeberge1 = 77.58;
static const double _rsaForfaitLogementHeberge2 = 135.77;
static const double _rsaForfaitLogementHeberge3Plus = 162.92;
```

Et dans `_calculerRSA` :
```dart
// AVANT
if (s.statutLogement == StatutLogement.heberge || s.loyerMensuel == 0 || percoitApl) {
  if (nbPersonnes == 1) {
    forfaitLogement = _rsaForfaitLogement1;
  } else if (nbPersonnes == 2) {
    forfaitLogement = _rsaForfaitLogement2;
  } else {
    forfaitLogement = _rsaForfaitLogement3Plus;
  }
}

// APRES
if (percoitApl) {
  // Bareme beneficiaires aide au logement (art. R262-9 CASF)
  if (nbPersonnes == 1) {
    forfaitLogement = _rsaForfaitLogementApl1;
  } else if (nbPersonnes == 2) {
    forfaitLogement = _rsaForfaitLogementApl2;
  } else {
    forfaitLogement = _rsaForfaitLogementApl3Plus;
  }
} else if (s.statutLogement == StatutLogement.heberge || s.loyerMensuel == 0) {
  // Bareme heberges/proprietaires sans aide logement (art. R262-10 CASF)
  if (nbPersonnes == 1) {
    forfaitLogement = _rsaForfaitLogementHeberge1;
  } else if (nbPersonnes == 2) {
    forfaitLogement = _rsaForfaitLogementHeberge2;
  } else {
    forfaitLogement = _rsaForfaitLogementHeberge3Plus;
  }
}
```

---

### 7. Conditions d'application du forfait logement

- **Dans l'app** : heberge OU loyer=0 OU percoit APL
- **Officiel** : le forfait logement s'applique dans deux cas distincts :
  1. Le beneficiaire percoit une aide au logement (APL, ALS, ALF) -- art. R262-9
  2. Le beneficiaire est heberge a titre gratuit OU est proprietaire sans pret -- art. R262-10
- **Source** : Art. R262-9 et R262-10 CASF
- **Statut** : APPROXIMATION

**Probleme** : le code regroupe les deux cas dans une seule condition avec un seul bareme. Cela fonctionne pour 1 personne (meme montant) mais est faux pour 2+ personnes (voir point 6). De plus, la condition `loyerMensuel == 0` ne couvre pas le cas du proprietaire avec un pret rembourse (qui devrait aussi declencher le forfait heberge).

---

### 8. Bonification 62% des revenus d'activite -- ERREUR CRITIQUE

- **Dans l'app** : ABSENTE. Le code fait `forfaitaire - ressources - forfaitLogement` ou les ressources incluent 100% des revenus d'activite.
- **Formule officielle** : RSA = (Montant forfaitaire + 62% x revenus d'activite) - Ressources totales du foyer - Forfait logement
- **Source** : Art. L262-2 CASF + Art. R262-1 CASF -- "La fraction des revenus professionnels des membres du foyer mentionnee au 1 de l'article L. 262-2 est egale a 62 %"
- **Liens** :
  - https://www.legifrance.gouv.fr/codes/article_lc/LEGIARTI000031694448
  - https://www.aide-sociale.fr/montants-rsa/
- **Statut** : ERREUR CRITIQUE

**Explication de la formule officielle** :

Le RSA se calcule ainsi :
```
Revenu garanti = Montant forfaitaire + 62% x revenus professionnels
RSA verse = Revenu garanti - Ressources du foyer - Forfait logement
```

Ou "Ressources du foyer" = revenus d'activite + autres revenus + AAH + pensions recues - pensions versees.

Autrement dit :
```
RSA = Forfaitaire + 0.62 x Rev_activite - (Rev_activite + Autres_revenus + AAH - Pension_versee) - Forfait_logement
RSA = Forfaitaire - 0.38 x Rev_activite - Autres_revenus - AAH + Pension_versee - Forfait_logement
```

**Impact** : Pour une personne seule avec 600 EUR de revenus d'activite :
- Code actuel : 651.69 - 600 - 77.58 = -25.89 -> 0 EUR (pas de RSA)
- Calcul correct : 651.69 + (0.62 x 600) - 600 - 77.58 = 651.69 + 372 - 600 - 77.58 = 346.11 EUR

L'app prive l'utilisateur de 346.11 EUR/mois dans cet exemple. C'est l'erreur la plus grave de l'audit.

**Correction Dart** :
```dart
// AVANT (ERREUR -- 100% des revenus deduits)
final ressourcesActivite = s.revenuActiviteDemandeur + s.revenuActiviteConjoint + s.totalAutresRevenus;
final ressources = (ressourcesActivite + aahMensuel - s.pensionAlimentaireVersee).clamp(0.0, double.infinity);
final rsa = (forfaitaire - ressources - forfaitLogement).clamp(0.0, double.infinity);

// APRES (CORRECT -- formule officielle art. L262-2 + R262-1 CASF)
final revenusActivite = s.revenuActiviteDemandeur + s.revenuActiviteConjoint;
final autresRessources = s.totalAutresRevenus + aahMensuel - s.pensionAlimentaireVersee;
final ressourcesTotales = (revenusActivite + autresRessources).clamp(0.0, double.infinity);

// Revenu garanti = forfaitaire + 62% des revenus d'activite
final revenuGaranti = forfaitaire + 0.62 * revenusActivite;

// RSA = revenu garanti - ressources totales - forfait logement
final rsa = (revenuGaranti - ressourcesTotales - forfaitLogement).clamp(0.0, double.infinity);
```

---

### 9. AAH comptee comme ressource

- **Dans l'app** : oui, `aahMensuel` est ajoute aux ressources
- **Officiel** : l'AAH est comptee dans les ressources pour le calcul du RSA. Le RSA est un minimum social "differentiel" : on deduit toutes les ressources, y compris l'AAH.
- **Source** : Art. R262-6 a R262-11 CASF. L'AAH n'est pas dans la liste des ressources exclues (art. R262-11).
- **Lien** : https://www.aide-sociale.fr/cumul-aah-rsa/
- **Statut** : CORRECT

**Precision non-cumul RSA + AAH** : En pratique, l'AAH (1041.59 EUR) etant superieure au RSA forfaitaire (651.69 EUR pour personne seule), le RSA tombe a 0 EUR pour un beneficiaire AAH a taux plein. Le code gere ce cas correctement (le clamp a 0 produit le bon resultat).

---

### 10. Pension alimentaire versee

- **Dans l'app** : deduite des ressources (`- s.pensionAlimentaireVersee`)
- **Officiel** : les pensions alimentaires versees sont deduites des ressources du foyer
- **Source** : Art. R262-6 CASF -- les charges deductibles incluent les pensions alimentaires versees
- **Lien** : https://www.legifrance.gouv.fr/codes/article_lc/LEGIARTI000020526203
- **Statut** : CORRECT

---

### 11. Neutralisation des ressources (art. R262-13 CASF)

- **Dans l'app** : NON IMPLEMENTEE
- **Officiel** : Art. R262-13 CASF prevoit que ni les revenus professionnels ni les allocations chomage ne sont comptes lorsqu'il est etabli que la perception de ces revenus est interrompue de maniere certaine et que la personne ne peut pretendre a un revenu de remplacement. Les revenus non professionnels peuvent etre neutralises jusqu'a un maximum de 550 EUR/mois.
- **Source** : Art. R262-13 CASF
- **Lien** : https://www.legifrance.gouv.fr/codes/article_lc/LEGIARTI000051679692
- **Statut** : ABSENTE

**Impact** : Pour une personne qui vient de perdre son emploi et n'a pas encore de droits chomage, la CAF neutralise les anciens revenus. L'app ne pourra pas reproduire ce comportement, mais c'est un cas specifique difficile a modeliser dans un simulateur. Recommandation : ajouter un champ "perte recente d'emploi sans indemnisation" et neutraliser les revenus professionnels le cas echeant.

---

## Erreurs a corriger par priorite

### Priorite 1 -- CRITIQUE
**Bonification 62% des revenus d'activite** (point 8) : La formule RSA est fondamentalement incorrecte. Les revenus d'activite sont deduits a 100% au lieu de 38%. Tout beneficiaire RSA avec des revenus d'activite aura un montant RSA largement sous-estime.

### Priorite 2 -- HAUTE
**Coefficient RSA majore par enfant** (point 4) : 0.4286 -> 0.42804. Erreur d'arrondi sur un coefficient reglementaire.

### Priorite 3 -- MOYENNE
**Deux baremes de forfait logement** (points 6-7) : Distinguer beneficiaires aide logement (12%/16%/16.5%) et heberges/proprietaires (12%/14%/14%).

### Priorite 4 -- BASSE
**Neutralisation des ressources** (point 11) : Cas specifique, amelioration fonctionnelle.

---

## Sources

- [Decret n 2026-220 du 30 mars 2026 -- Legifrance](https://www.legifrance.gouv.fr/jorf/id/JORFTEXT000053733826)
- [Art. R262-2 CASF -- majorations couple/enfants](https://www.legifrance.gouv.fr/codes/article_lc/LEGIARTI000033979137)
- [Art. R262-4 CASF -- RSA majore coefficients](https://www.legifrance.gouv.fr/codes/article_lc/LEGIARTI000051258532)
- [Art. R262-1 CASF -- fraction 62% revenus](https://www.legifrance.gouv.fr/codes/article_lc/LEGIARTI000031694448)
- [Art. L262-9 CASF -- conditions parent isole](https://www.legifrance.gouv.fr/codes/article_lc/LEGIARTI000031087746)
- [Art. R262-13 CASF -- neutralisation](https://www.legifrance.gouv.fr/codes/article_lc/LEGIARTI000051679692)
- [Forfait logement RSA 2026 -- aide-sociale.fr](https://www.aide-sociale.fr/forfait-logement-caf/)
- [Montant RSA 2026 -- aide-sociale.fr](https://www.aide-sociale.fr/montants-rsa/)
- [Cumul AAH et RSA -- aide-sociale.fr](https://www.aide-sociale.fr/cumul-aah-rsa/)
- [Bareme RSA -- CAF](https://www.caf.fr/professionnels/offres-et-services/accompagnement-des-allocataires/bareme-revenu-de-solidarite-active)
