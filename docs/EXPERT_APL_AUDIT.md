# AUDIT EXPERT — Calcul APL dans AllocCheck

**Date** : 2026-04-06
**Fichier audite** : `alloccheck_app/lib/core/services/calcul_local_service.dart`
**Methode** : verification croisee avec la brochure officielle du Ministere du Logement "Les aides personnelles au logement — Elements de calcul" (edition avril 2024) et les arretes de revalorisation octobre 2025.

---

## VERDICT GLOBAL : CALCUL APL NON FIABLE — ERREURS STRUCTURELLES MAJEURES

Le moteur de calcul APL contient **3 erreurs structurelles critiques** qui rendent le resultat mathematiquement faux dans la quasi-totalite des cas. Le calcul ne peut pas etre commercialise en l'etat.

---

## 1. Formule principale

### Rappel de la formule officielle

```
APL = L + C - Pp
Pp = P0 + Tp * (R - R0)
Tp = TF + TL
```

Source : Article D.823-16 du CCH, Arrete du 27 septembre 2019, Brochure ministerielle p.14

### Ce que fait le code (lignes 625-634)

```dart
final tp = (ressourceBase / 25000.0).clamp(0.0, 0.95);
final pp = _aplP0 + tp * (l + c);
var apl = l + c - pp - _aplDeduction;
```

### Analyse

- **Valeur dans l'app** : `APL = L + C - [P0 + Tp*(L+C)] - 5`
- **Valeur officielle** : `APL = L + C - [P0 + Tp*(R-R0)] - 5`
- **Source** : Brochure ministerielle "Elements de calcul" p.14, Article D.823-17 du CCH
- **Statut** : **ERREUR CRITIQUE**
- **Impact** : La participation personnelle (Pp) est calculee sur la base du loyer au lieu des ressources. Cela produit des resultats completement errones dans TOUS les cas ou R != R0.

---

## 2. Taux de participation Tp

### 2.1 Formule du Tp

- **Valeur dans l'app** : `Tp = (R - R0) / 25000` plafonne a 0.95
- **Valeur officielle** : `Tp = TF + TL` (deux composantes distinctes)
- **Source** : Article 14 de l'arrete du 27 septembre 2019, Brochure ministerielle p.18
- **Statut** : **ERREUR CRITIQUE — FORMULE INVENTEE**
- **Detail** : Le diviseur "25000" n'existe dans aucun texte officiel. C'est une approximation lineaire qui ne correspond pas au calcul reel.

### 2.2 Composante TF (taux famille)

TF est un pourcentage fixe selon la composition du menage beneficiaire :

| Composition | TF officiel (arrete 2019) |
|---|---|
| Personne seule | 2,83 % |
| Couple sans personne a charge | 3,15 % |
| Personne seule ou couple + 1 pac | 2,70 % |
| + 2 pac | 2,38 % |
| + 3 pac | 2,01 % |
| + 4 pac | 1,85 % |
| + 5 pac | 1,79 % |
| + 6 pac | 1,73 % |
| Par pac supplementaire | - 0,06 point |

- **Valeur dans l'app** : Inexistant — le code n'a aucune table TF
- **Source** : Brochure ministerielle p.18 (Tableau 6)
- **Statut** : **ERREUR CRITIQUE — PARAMETRE MANQUANT**

### 2.3 Composante TL (taux loyer)

TL depend du rapport RL = L / LR, ou LR est le loyer de reference (= loyer plafond de la zone II pour la meme composition familiale).

Calcul progressif :
- Si RL < 45% : TL = 0%
- Si 45% <= RL < 75% : TL = 0,45% * (RL - 45%)
- Si RL >= 75% : TL = 0,45% * 30% + 0,68% * (RL - 75%)

TL est arrondi a la troisieme decimale.

- **Valeur dans l'app** : Inexistant — le code n'a aucun calcul de TL
- **Source** : Article 14 de l'arrete du 27 septembre 2019, Brochure ministerielle p.18
- **Statut** : **ERREUR CRITIQUE — PARAMETRE MANQUANT**

---

## 3. Participation personnelle minimale P0

- **Valeur dans l'app** : `P0 = 39.56` (constante fixe)
- **Valeur officielle** : `P0 = max(8,5% * (L + C), 39,56 EUR)` depuis le 1er octobre 2025
- **Source** : Article D.823-17 du CCH, Article 13 de l'arrete du 27 sept 2019, Brochure ministerielle p.17
- **Statut** : **ERREUR**
- **Detail** : Pour les loyers eleves, P0 devrait etre 8,5% de (L+C). Exemple : si L=454€ et C=84€, alors 8,5%*538 = 45,73€ > 39,56€, donc P0 devrait etre 45,73€ et non 39,56€.
- **Historique des valeurs** :
  - 01/10/2023 : 37,91 EUR (brochure 2024)
  - 01/10/2024 : 38,78 EUR (revalorisation +2,47% IRL)
  - 01/10/2025 : 39,56 EUR (revalorisation +1,04% IRL) — valeur dans le code = CORRECT pour le montant plancher

---

## 4. Loyer plafond (L)

### Valeurs dans l'app (oct 2025)

| Zone | 1 pers (seul) | 2 pers (couple) | 3 pers (1 pac) | Supp/pers |
|---|---|---|---|---|
| Zone 1 | 333,14 | 401,78 | 454,10 | 65,89 |
| Zone 2 | 290,34 | 355,38 | 399,89 | 58,21 |
| Zone 3 | 272,12 | 329,88 | 369,88 | 53,01 |

### Valeurs officielles (oct 2025, arrete du 5 septembre 2025)

Confirmees par aide-sociale.fr et service-public.fr pour les montants au 1er octobre 2025 (revalorisation +1,04% IRL sur les montants oct 2024).

Les montants dans le code correspondent aux montants oct 2025 publies par les sources de reference.

- **Statut** : **CORRECT** (les montants numeriques sont bons)

### Probleme de structure

Le code indexe par "nombre de personnes" (1, 2, 3) avec 0 = supplement. Or, la brochure officielle distingue :
- **Personne seule** (0 pac)
- **Couple** (0 pac)
- **Personne seule ou couple + 1 pac**
- **+ 2 pac**, **+ 3 pac**, etc.

Le code traite `nbPersonnes = 1` comme personne seule et `nbPersonnes = 2` comme couple OU personne seule + 1 enfant, ce qui est **ambigu**. Une personne seule + 1 enfant devrait utiliser le plafond "1 pac" (454,10€ zone 1), pas le plafond "couple" (401,78€ zone 1).

En fait, en relisant le code ligne 586-595 :
```dart
final nbPersonnes = (couple ? 2 : 1) + nombreEnfants;
if (nbPersonnes <= 3) loyerPlafond = plafonds[nbPersonnes]!;
```
- Personne seule sans enfant : nbPersonnes=1 -> plafond[1] = 333,14 CORRECT
- Couple sans enfant : nbPersonnes=2 -> plafond[2] = 401,78 CORRECT
- Personne seule + 1 enfant : nbPersonnes=2 -> plafond[2] = 401,78 **ERREUR** (devrait etre 454,10)
- Couple + 1 enfant : nbPersonnes=3 -> plafond[3] = 454,10 CORRECT

- **Statut** : **ERREUR** pour les familles monoparentales
- **Impact** : Une personne seule avec 1 enfant se voit appliquer le plafond "couple" au lieu du plafond "1 pac", ce qui reduit son APL.

---

## 5. Forfait charges (C)

- **Valeur dans l'app** : `C = 60,59 + nombreEnfants * 13,74`
- **Valeur officielle** (brochure p.16, Tableau 4, cas general) :
  - Personne seule ou couple sans pac : 58,08 EUR (au 01/10/2023)
  - + 1 pac : 71,25 EUR
  - + 2 pac : 84,42 EUR
  - + 3 pac : 97,59 EUR
  - Par pac supplementaire : + 13,17 EUR

**Apres revalorisation oct 2025 (+1,04% sur oct 2024)** :
  - Base (0 pac) : environ 60,59 EUR
  - + 1 pac : environ 74,33 EUR -> donc l'increment est environ 13,74 EUR

Le forfait charges n'est PAS "base + N*increment". Le tableau officiel montre des montants specifiques par pallier, avec un increment different pour les premiers palliers vs les suivants. Neanmoins, l'approximation dans le code semble produire des montants proches apres revalorisation oct 2025.

**Probleme** : Le conjoint n'est pas traite. Un couple sans enfant devrait avoir le meme forfait charge qu'une personne seule (58,08€ base 2024). Le code applique `0 enfants * 13,74 = 0` supplementaire, ce qui donne 60,59€ pour tout le monde sans enfant. C'est correct : la base s'applique a "personne seule OU couple sans pac".

- **Statut** : **APPROXIMATION ACCEPTABLE** (ecart < 1€ dans la plupart des cas)
- **Remarque** : Le forfait charges en colocation est different (29,03€ base pour personne seule en colocation) — non gere.

---

## 6. R0 (abattement forfaitaire)

### Valeurs dans l'app

| Taille foyer | R0 app | R0 officiel 2024 | R0 officiel 2025/2026 |
|---|---|---|---|
| 1 (seul) | 5 235 | 5 186 | 5 235 |
| 2 (couple ou 1pac) | 7 501 | 7 430 | 7 501 |
| 3 (2pac) | 8 947 | 8 862 | 8 947 |
| 4 | 9 148 | 9 061 | 9 148 |
| 5 | 9 498 | 9 408 | 9 498 |
| 6 | 9 851 | 9 758 | 9 851 |
| 7 | 10 202 | 10 105 | 10 202 |
| 8 | 10 554 | 10 454 | 10 554 |
| Supp | +346 | +343 | +346 |

Les valeurs dans l'app correspondent aux valeurs 2025/2026 (R0 2024 revalorise de 4,80% en janv 2024, puis regele en 2025 et 2026 selon les arretes).

- **Source** : Arrete du 30 decembre 2024, confirme par aide-sociale.fr et toutsurmesfinances.com
- **Statut** : **CORRECT**

---

## 7. Deduction forfaitaire de 5 EUR

- **Valeur dans l'app** : 5,00 EUR
- **Valeur officielle** : 5 EUR (art. D.823-16 al.9 du CCH, art. 11 arrete 27 sept 2019)
- **Source** : Brochure ministerielle p.20 (section 3.1.5.2)
- **Statut** : **CORRECT**
- **Detail** : En vigueur depuis octobre 2017. Toujours applicable en 2026. Non revalorise (montant fixe par arrete).

---

## 8. Seuil de non-versement

- **Valeur dans l'app** : 15 EUR
- **Valeur officielle** :
  - **APL en locatif ordinaire : 0 EUR** (pas de seuil de versement)
  - AL (ALS/ALF) : 10 EUR
- **Source** : Brochure ministerielle p.21 (section 3.1.5.4) : "Ce montant est de 10 EUR pour les AL et de 0 EUR pour l'APL en locatif ordinaire."
- **Statut** : **ERREUR**
- **Impact** : Le code ne verse pas les APL entre 0 et 15€, alors qu'en realite toute APL > 0€ devrait etre versee. Cela exclut a tort des beneficiaires.

---

## 9. Ressources prises en compte

### Ce que fait le code (lignes 600-615)

Le code prend en compte :
- Revenus d'activite du demandeur et du conjoint
- "Autres revenus" (hors bourses)
- Pension alimentaire versee deduite

### Ce que dit la brochure officielle (section 5)

Les ressources R = revenus nets categoriels retenus pour l'impot sur le revenu (art. R.822-4 CCH), sur les 12 derniers mois glissants (depuis janv. 2021).

**Inclus** :
- Salaires, traitements (apres abattement 10% ou frais reels)
- Pensions de retraite
- Allocations chomage
- Revenus fonciers
- BIC/BNC/BA pour independants
- Pensions alimentaires recues (periode N-1)
- Revenus du patrimoine > 30 000€ (3% des capitaux, 50% valeur locative immobilier)

**Exclus** :
- RSA : **neutralise** (les revenus des beneficiaires RSA sont neutralises, art. R.822-15)
- AAH : **NON exclue** des ressources en tant que telles (l'AAH est un revenu imposable depuis 2019... MAIS en pratique, les beneficiaires AAH a taux plein ont generalement des ressources nulles ou tres faibles, et l'AAH n'est pas soumise a l'IR. La brochure precise que c'est le revenu net categoriel pour l'IR qui est pris en compte.)
- Prime d'activite : **non imposable** donc exclue de facto
- Bourses etudiantes non imposables : **exclues** (forfait etudiant applique)
- Prestations familiales (AF, PAJE, etc.) : **non imposables** donc exclues

**Charges deductibles** (art. R.822-4) :
- Pensions alimentaires versees : **oui, deductibles** CORRECT dans le code
- Abattement personnes agees/invalides

### Analyse du code

Le code semble traiter les revenus de maniere simplifiee (revenus mensuels * 12) au lieu d'utiliser le revenu net categoriel fiscal. C'est une approximation inherente a un simulateur qui ne dispose pas des donnees fiscales.

- **Statut** : **APPROXIMATION SIGNIFICATIVE**
- **Remarque** : L'exclusion des bourses est correcte. L'exclusion implicite de l'AAH et du RSA (non renseignes dans les "revenus d'activite") est un choix acceptable si l'interface ne les inclut pas. Mais cela depend de la facon dont l'utilisateur renseigne ses revenus.

---

## 10. Cas speciaux non geres

### 10.1 Colocation

- **Regle officielle** : Les plafonds de loyer sont reduits a **75%** des plafonds personne seule (brochure p.16, tableau 3). Le forfait charges est aussi different (29,03€ base au 01/10/2023).
- **Dans l'app** : Non gere
- **Statut** : **MANQUANT**

### 10.2 Etudiants

- **Regle officielle** : Forfait de ressources fixe applique (8 600€ non boursier / 6 900€ boursier en locatif ordinaire, au 01/01/2025). Les ressources reelles sont remplacees par ce forfait.
- **Dans l'app** : Non gere
- **Statut** : **MANQUANT**

### 10.3 APL vs ALS vs ALF

- **Regle officielle** : Le bareme est identique en locatif ordinaire depuis 2001, mais le seuil de non-versement differe (0€ APL vs 10€ AL). La distinction importe pour la RLS et d'autres aspects.
- **Dans l'app** : Pas de distinction, tout est calcule comme "APL"
- **Statut** : **APPROXIMATION** (impact faible car baremes identiques, mais seuil de versement faux)

### 10.4 Patrimoine > 30 000 EUR

- **Regle officielle** : Si patrimoine financier + immobilier (hors residence principale) > 30 000€, un revenu fictif est ajoute (3% des capitaux, 50% valeur locative immobilier bati, 80% terrains non batis). Exception : beneficiaires AAH/AEEH exclus de cette regle.
- **Dans l'app** : Non gere
- **Statut** : **MANQUANT**

### 10.5 Degressivite pour loyer excessif

- **Regle officielle** : Si le loyer reel depasse un seuil (cd * plafond), l'aide est progressivement reduite. Coefficients : Zone I cd=3,4 cs=4 ; Zone II cd=2,5 cs=3,1 ; Zone III cd=2,5 cs=3,1. Exception : pas appliquee aux beneficiaires AAH/AEEH.
- **Dans l'app** : Non gere
- **Statut** : **MANQUANT** (impact nul pour les loyers normaux, mais les loyers eleves produisent un resultat faux)

### 10.6 CRDS

- **Regle officielle** : Une CRDS de 0,5% est prelevee sur le montant de l'aide (arrondie au centime inferieur).
- **Dans l'app** : Non geree
- **Statut** : **MANQUANT** (impact faible : ~1-2€/mois)

### 10.7 Location meublee

- **Regle officielle** : Le loyer pris en compte = 2/3 du loyer effectivement paye (art. D.842-2 CCH).
- **Dans l'app** : Non gere
- **Statut** : **MANQUANT**

### 10.8 Sous-location

- **Regle officielle** : Seul le loyer residuel (apres deduction du loyer du sous-locataire) est pris en compte.
- **Dans l'app** : Non gere
- **Statut** : **MANQUANT**

---

## 11. Exemple de verification manuelle

### Parametres

- Personne seule, zone 3, loyer 470€, AAH 80%, aucun revenu d'activite, code postal 57240

### Calcul selon le code de l'app

D'apres le code :
- nbPersonnes = 1
- Zone 3, plafond = 272,12€
- L = min(470, 272.12) = 272,12€
- C = 60,59 + 0*13,74 = 60,59€
- Ressources mensuelles = 0 (pas de revenu d'activite, AAH exclue des revenus d'activite)
- Ressources annuelles = 0
- R0 = 5235
- ressourceBase = max(0 - 5235, 0) = 0
- Tp = 0/25000 = 0
- PP = 39,56 + 0*(272,12+60,59) = 39,56€
- APL = 272,12 + 60,59 - 39,56 - 5 = 288,15€

**Resultat app : 288,15€** (correspond a ce qu'annonce Joffrey)

### Calcul selon la formule officielle

- L = min(470, 272,12) = 272,12€
- C = 60,59€ (personne seule, 0 pac — montant oct 2025)
- P0 = max(8,5% * (272,12 + 60,59), 39,56) = max(28,28, 39,56) = 39,56€
- R = 0 (beneficiaire AAH, revenus d'activite nuls, AAH non imposable)
- R0 = 5 235€
- R - R0 = 0 - 5235 = negatif, donc (R - R0) = 0 (plancher)
- TF = 2,83% (personne seule)
- RL = L/LR = 272,12 / 329,88 = 0,8249 = 82,49%
  (LR = loyer plafond zone II pour personne seule = apres revalorisation oct 2025, environ 290,34€... mais la brochure dit LR = plafond Zone II pour la meme composition)

Attention : LR = plafond de loyer Zone II pour la composition correspondante.
Personne seule zone II oct 2025 = 290,34€

- RL = 272,12 / 290,34 = 93,72%
- TL = 0,45% * (75% - 45%) + 0,68% * (93,72% - 75%)
- TL = 0,45% * 30% + 0,68% * 18,72%
- TL = 0,135% + 0,127% = 0,262%
- TL arrondi 3 decimales = 0,262%
- Tp = TF + TL = 2,83% + 0,262% = 3,092%
- Pp = P0 + Tp * (R - R0) = 39,56 + 3,092% * 0 = 39,56€
- APL = L + C - Pp = 272,12 + 60,59 - 39,56 = 293,15€
- Deduction 5€ : 293,15 - 5 = 288,15€
- CRDS : 0,5% * 288,15 = 1,44€
- APL nette : 288,15 - 1,44 = 286,71€, arrondie a l'euro inferieur = **286€**

### Comparaison

| | App | Calcul officiel |
|---|---|---|
| Avant CRDS | 288,15€ | 288,15€ |
| Apres CRDS | N/A (pas geree) | 286€ |

**Dans ce cas precis**, les deux formules donnent le meme resultat avant CRDS car R=0 (donc R-R0 est negatif dans les deux cas, Tp*0=0). L'erreur de formule du Tp ne se manifeste pas quand les ressources sont nulles.

**MAIS** : pour toute personne ayant des ressources > R0, les resultats divergent massivement. Par exemple, avec R=15 000€/an :
- App : Tp = (15000-5235)/25000 = 0.3906, PP = 39.56 + 0.3906*(272+60.59) = 169.47€, APL = 272.12+60.59-169.47-5 = 158.24€
- Officiel : Tp = 2.83%+0.262% = 3.092%, PP = 39.56 + 3.092%*(15000-5235) = 39.56+302.09 = 341.65€, APL = 272.12+60.59-341.65-5 = negatif = 0€

**Ecart : 158€ vs 0€ — le code surestime massivement l'APL pour les personnes ayant des revenus.**

---

## SYNTHESE DES ERREURS

### Corrections obligatoires (bloquantes pour commercialisation)

| # | Parametre | Nature | Impact |
|---|---|---|---|
| 1 | **Formule PP** | PP = P0 + Tp*(L+C) au lieu de P0 + Tp*(R-R0) | **CRITIQUE** — faux pour tout R > 0 |
| 2 | **Formule Tp** | Tp = (R-R0)/25000 au lieu de TF + TL | **CRITIQUE** — formule inventee |
| 3 | **Table TF manquante** | Aucune table TF par composition familiale | **CRITIQUE** — Tp impossible a calculer |
| 4 | **Calcul TL manquant** | Aucun calcul de TL (RL, LR, tranches) | **CRITIQUE** — Tp impossible a calculer |
| 5 | **P0 simplifie** | Constante fixe au lieu de max(8.5%*(L+C), 39.56) | **ERREUR** — impact sur loyers eleves |
| 6 | **Seuil non-versement** | 15€ au lieu de 0€ (APL locatif ordinaire) | **ERREUR** — exclut des beneficiaires |
| 7 | **Plafond loyer monoparentaux** | Pers. seule + 1 enfant -> plafond "couple" au lieu de "1 pac" | **ERREUR** — sous-estime l'APL |

### Cas non geres (ameliorations recommandees)

| # | Cas | Impact |
|---|---|---|
| 8 | Colocation (plafonds -25%) | Surestime l'APL des colocataires |
| 9 | Etudiants (forfait ressources) | Calcul potentiellement faux |
| 10 | Patrimoine > 30 000€ | Surestime l'APL des menages aises |
| 11 | Degressivite loyer excessif | Surestime l'APL pour loyers tres eleves |
| 12 | CRDS (0,5%) | Surestime d'environ 1-2€/mois |
| 13 | Location meublee (2/3 loyer) | Surestime le loyer pris en compte |
| 14 | Distinction APL/ALS/ALF | Seuil de versement different |

### Corrections de code a apporter

#### Correction 1 : Implementer Tp = TF + TL

```dart
// Table TF (valeurs fixes, non revalorisees — arrete 27 sept 2019)
static const Map<String, double> _aplTF = {
  'seul_0': 0.0283,      // personne seule
  'couple_0': 0.0315,     // couple sans pac
  'pac_1': 0.0270,        // 1 personne a charge
  'pac_2': 0.0238,        // 2 pac
  'pac_3': 0.0201,        // 3 pac
  'pac_4': 0.0185,        // 4 pac
  'pac_5': 0.0179,        // 5 pac
  'pac_6': 0.0173,        // 6 pac
};
static const double _aplTFParPacSupp = -0.0006; // par pac au-dela de 6

// LR = loyer plafond Zone II pour la meme composition
// (utilise le tableau _aplLoyerPlafond['zone_2'])

double _calculerTF(bool estCouple, int nbEnfants) {
  if (nbEnfants == 0) return estCouple ? 0.0315 : 0.0283;
  if (nbEnfants <= 6) {
    return [0.0270, 0.0238, 0.0201, 0.0185, 0.0179, 0.0173][nbEnfants - 1];
  }
  return 0.0173 + (nbEnfants - 6) * (-0.0006);
}

double _calculerTL(double l, double lr) {
  final rl = (l / lr * 100); // en pourcentage
  final rlArrondi = (rl * 100).round() / 100; // arrondi 2 decimales
  double tl;
  if (rlArrondi < 45) {
    tl = 0;
  } else if (rlArrondi < 75) {
    tl = 0.0045 * (rlArrondi - 45);
  } else {
    tl = 0.0045 * 30 + 0.0068 * (rlArrondi - 75);
  }
  // Arrondi 3 decimales (en pourcentage)
  return (tl * 1000).round() / 1000;
}
```

#### Correction 2 : Formule PP corrigee

```dart
// P0 = max(8.5% * (L + C), 39.56)
final p0 = max(0.085 * (l + c), _aplP0);

// Tp = TF + TL
final estCouple = s.situationFamiliale == SituationFamiliale.couple;
final tf = _calculerTF(estCouple, s.nombreEnfants);
final lr = _aplLoyerPlafond['zone_2']![_indexPlafond(estCouple, s.nombreEnfants)]!;
final tl = _calculerTL(l, lr);
final tp = tf + tl;

// PP = P0 + Tp * max(R - R0, 0)
final pp = p0 + tp * ressourceBase; // ressourceBase = max(R - R0, 0)

// APL = L + C - PP - 5
var apl = l + c - pp - _aplDeduction;
```

#### Correction 3 : Seuil de non-versement

```dart
// APL locatif ordinaire : pas de seuil (0€)
// AL (ALS/ALF) : seuil 10€
final montant = apl <= 0 ? 0.0 : _arrondi(apl);
```

#### Correction 4 : Plafond loyer pour monoparentaux

Restructurer le tableau _aplLoyerPlafond pour distinguer :
- Colonne 0 : personne seule (0 pac)
- Colonne 1 : couple (0 pac)
- Colonne 2 : 1 pac (seul ou couple)
- Colonne 3+ : 2 pac, 3 pac, etc.

---

## Sources consultees

- [Brochure ministerielle "Les aides personnelles au logement — Elements de calcul" (edition avril 2024)](https://www.ecologie.gouv.fr/sites/default/files/documents/Brochure-bareme-2024-APL.pdf) — **SOURCE PRINCIPALE**
- [Arrete du 27 septembre 2019 relatif au calcul des aides personnelles au logement](https://www.legifrance.gouv.fr/loda/id/JORFTEXT000039160329)
- [Arrete du 5 septembre 2025 (revalorisation oct 2025)](https://www.legifrance.gouv.fr/jorf/id/JORFTEXT000052212770)
- [Arrete du 30 decembre 2024 (R0 et forfaits etudiants 2025)](https://www.legifrance.gouv.fr/jorf/id/JORFTEXT000050873291)
- [Service-Public.fr — Plafonds de ressources APL 2025](https://www.service-public.fr/particuliers/actualites/A17979)
- [aide-sociale.fr — Montant APL 2026](https://www.aide-sociale.fr/montant-apl/)
- [toutsurmesfinances.com — APL 2026](https://www.toutsurmesfinances.com/immobilier/calcul-simulation-criteres-ce-qu-il-faut-savoir-sur-les-apl.html)

---

## Conclusion

Le calcul APL dans AllocCheck est **structurellement faux** en raison d'une formule de participation personnelle inventee (`Tp = ressources/25000` au lieu de `Tp = TF + TL`). Cette erreur produit des resultats corrects uniquement dans le cas limite ou les ressources sont nulles ou inferieures a R0 (cas typique des beneficiaires AAH a taux plein sans autre revenu).

Pour tout utilisateur ayant des revenus (meme modestes), le calcul est faux, potentiellement de plusieurs centaines d'euros par mois. **Ce moteur ne peut pas etre commercialise en l'etat sans un risque juridique et reputationnel majeur.**

La correction necessite une reecriture de la fonction `_calculerAPL` avec implementation des composantes TF et TL conformement a l'arrete du 27 septembre 2019.
