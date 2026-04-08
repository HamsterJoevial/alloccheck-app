# Audit Expert -- Prestations Familiales (PAJE, CF, PreParE, ARS, CMG)

**Date** : 6 avril 2026
**Fichier audite** : `lib/core/services/calcul_local_service.dart`
**Methode** : verification par WebSearch systematique, zero memoire

---

## 1. PAJE -- Allocation de base

### Montants

| Element | Code | Reel avril 2026 | Verdict |
|---------|------|-----------------|---------|
| Taux plein | 198.16 | 198.16 | OK |
| Taux partiel | 99.09 | 99.08-99.09 | OK (arrondi acceptable) |

**Note** : Certaines sources mentionnent 198.36 / 99.18 apres revalorisation +0.8% au 1er avril 2026. Cependant la majorite des sources (Service-Public.fr, aide-sociale.fr) confirment 198.16 / 99.08-99.09. Le code est correct.

Sources : [Service-Public.fr](https://www.service-public.gouv.fr/particuliers/vosdroits/F2552), [aide-sociale.fr](https://www.aide-sociale.fr/allocation-base-caf/), [droit-finances.commentcamarche.com](https://droit-finances.commentcamarche.com/vie-pratique/guide-vie-pratique/2935-allocation-de-base-paje-de-la-caf-montant/)

### Plafonds de ressources -- ERREUR MAJEURE

**Le code utilise des plafonds simplifies qui ne correspondent PAS aux plafonds officiels.**

Les plafonds PAJE reels dependent de 3 categories :
- Couple avec 1 seul revenu
- Couple avec 2 revenus (chacun >= 6 306 EUR en N-2)
- Parent isole

Le code ne distingue que couple/isole, pas "couple 1 revenu" vs "couple 2 revenus".

| Situation | Enfants | Code (couple) | Reel couple 1 rev | Reel couple 2 rev / isole |
|-----------|---------|---------------|--------------------|-----------------------------|
| 1 enfant | 1 | 43 681 | ~31 066 (taux plein) | ~41 055 |
| 2 enfants | 2 | 52 958 | ~37 118 (?) | ~49 054 (?) |
| 3 enfants | 3 | 62 234 | non verifie | non verifie |

Les valeurs du code (43 681, 52 958, 62 234) ne correspondent a aucune des colonnes officielles connues. Les plafonds Service-Public.fr pour couple 1 revenu / 1 enfant sont autour de 31 066 EUR (taux plein) et 37 118 EUR (taux partiel). Les valeurs du code sont bien trop elevees.

De meme, les plafonds "isole" du code (34 681, 43 957, 53 234) ne correspondent pas aux plafonds officiels pour parent isole (~41 055 EUR pour 1 enfant taux plein).

**Impact** : le code accorde la PAJE a des familles qui ne devraient pas la recevoir (plafonds trop hauts).

### Logique de calcul -- ERREUR

Le code utilise `plafond * 2` comme seuil de non-eligibilite et `plafond` comme seuil entre taux plein et taux partiel. La realite est differente :
- Il existe 2 plafonds distincts (un pour taux plein, un pour taux partiel)
- Au-dela du plafond taux partiel = pas d'allocation
- Ce n'est PAS un rapport de 2x entre les deux

### Correction requise

```dart
// PAJE -- Les plafonds dependent de 3 categories :
// - Couple 1 revenu (seuil activite < 6306 EUR pour le 2e membre)
// - Couple 2 revenus / Parent isole (meme colonne)
// Revenus N-2 (2024 pour 2026)
//
// Source : Arrete du 18 decembre 2025, Service-Public.fr F2552
//
// Plafonds taux plein :
//   Couple 1 rev : 31 066 (1 enf), 37 279 (2 enf), 43 492 (3 enf), +6 213/enf supp
//   Couple 2 rev / isole : 41 055 (1 enf), 47 268 (2 enf), 53 481 (3 enf), +6 213/enf supp
//
// Plafonds taux partiel :
//   Couple 1 rev : 37 118 (1 enf), ...
//   Couple 2 rev / isole : 49 054 (1 enf), ...
//
// IMPORTANT : ces plafonds doivent etre verifies sur le site officiel
// service-public.gouv.fr/particuliers/vosdroits/F2552 avant publication.
// Les montants ci-dessus sont des approximations issues de sources secondaires.
//
// Le code actuel doit etre refactorise pour :
// 1. Distinguer couple 1 revenu / couple 2 revenus (seuil 6306 EUR)
// 2. Utiliser 2 plafonds distincts (taux plein / taux partiel) au lieu de plafond * 2
// 3. Utiliser les vrais plafonds de l'arrete du 18/12/2025
```

**Severite : CRITIQUE** -- Les plafonds sont faux, les calculs d'eligibilite sont donc faux.

---

## 2. Complement Familial (CF)

### Montants -- ERREUR MAJEURE

| Element | Code | Reel avril 2026 | Ecart |
|---------|------|-----------------|-------|
| Montant majore | 260.57 | **297.27** | -36.70 EUR/mois |
| Montant normal | 173.71 | **198.16** | -24.45 EUR/mois |

Les montants du code sont ceux d'avant avril 2025 environ. Les montants corrects au 1er avril 2026 (BMAF 478.16 EUR, +0.8%) sont :
- CF base = 41.65% x BMAF = 198.16 EUR/mois (officiel confirme par plusieurs sources)
- CF majore = 62.18% x BMAF = 297.27 EUR/mois (officiel confirme)

Sources : [droit-finances.commentcamarche.com](https://droit-finances.commentcamarche.com/vie-pratique/guide-vie-pratique/2955-complement-familial-montant-et-plafonds/), [aide-sociale.fr](https://www.aide-sociale.fr/complement-familial/), [Service-Public.fr](https://www.service-public.gouv.fr/particuliers/actualites/A16506)

### Plafonds -- ERREUR MAJEURE

| Element | Code | Reel 2026 | Probleme |
|---------|------|-----------|----------|
| Seuil majore | 25 000 | ~21 820 (couple 1 rev, 3 enf) / ~27 230 (couple 2 rev/isole) | Approximation grossiere |
| Seuil normal | 43 000 | ~44 735 (couple 1 rev, 3 enf) / ~54 724 (couple 2 rev/isole) | Approximation |

Le code utilise des seuils fixes (25 000 et 43 000) qui ne tiennent pas compte de :
1. La distinction couple 1 revenu / couple 2 revenus / parent isole
2. Le nombre d'enfants au-dela de 3 (majoration ~7 456 EUR par enfant supplementaire)
3. Les vrais plafonds officiels de l'arrete du 18/12/2025

### Correction requise

```dart
// --- Complement Familial (Art. L522-1 CSS, bareme avril 2026) ---
static const double _cfMontantMajore = 297.27;  // 62.18% BMAF
static const double _cfMontantNormal = 198.16;  // 41.65% BMAF

// Plafonds CF 2026 (revenus N-2 = 2024) pour 3 enfants :
//   Couple 1 revenu :  plafond majore = ~21 820, plafond normal = ~44 735
//   Couple 2 revenus / isole : plafond majore = ~27 230, plafond normal = ~54 724
//   Majoration par enfant supplementaire : ~7 456
//
// IMPORTANT : comme pour la PAJE, le code doit :
// 1. Distinguer couple 1 rev / couple 2 rev / isole
// 2. Prendre en compte le nombre d'enfants pour les plafonds
// 3. Utiliser les vrais plafonds officiels

// La logique actuelle avec seuils fixes 25000/43000 est FAUSSE.
```

**Severite : CRITIQUE** -- Montants sous-evalues de ~25%, plafonds faux.

---

## 3. PreParE

### Montants -- ERREUR MAJEURE

| Element | Code | Reel avril 2026 | Ecart |
|---------|------|-----------------|-------|
| Taux plein (cessation totale) | 428.71 | **459.69** (brut) / ~456.06 (net CRDS) | -27 a -30 EUR |
| Taux demi (mi-temps) | 277.14 | **297.17** (temps partiel <= 50%) | -20 EUR |

Les montants du code datent probablement d'avant la revalorisation d'avril 2025 ou 2026.

### Taux manquant -- ERREUR STRUCTURELLE

Le code ne gere que 2 niveaux (taux plein / taux demi). La realite comporte **3 niveaux** :

| Niveau d'activite | Montant avril 2026 | Dans le code ? |
|---|---|---|
| Cessation totale (0%) | 459.69 EUR (brut) / ~456.06 EUR (net) | OUI mais montant faux |
| Temps partiel <= 50% | 297.17 EUR | OUI mais montant faux |
| Temps partiel 50-80% | **171.42 EUR** | **NON -- ABSENT** |

### Fonctionnalites manquantes

1. **PreParE majoree** : 745.45 EUR/mois pour familles 3+ enfants avec cessation totale -- absente du code
2. **Condition d'activite anterieure** : 8 trimestres de cotisations valides dans les 2/4/5 ans selon le rang de l'enfant -- non verifiee
3. **Duree maximale** selon le rang de l'enfant :
   - 1er enfant : 6 mois par parent (max 12 mois a 2)
   - 2e enfant : 24 mois par parent jusqu'aux 3 ans
   - 3e enfant et + : 48 mois (PreParE majoree possible)
   -- non geree

Sources : [Service-Public.fr](https://www.service-public.gouv.fr/particuliers/vosdroits/F32485), [aide-sociale.fr](https://www.aide-sociale.fr/caf-prepare/), [mes-allocs.fr](https://www.mes-allocs.fr/guides/allocations-familiales/paje/prepare-caf/), [droit-finances.commentcamarche.com](https://droit-finances.commentcamarche.com/vie-pratique/guide-vie-pratique/2939-prepare-condition-et-montant-de-l-aide-au-conge-parental/)

### Correction requise

```dart
// --- PreParE (Art. L531-4 CSS, bareme avril 2026) ---
// 3 taux selon le niveau d'activite :
static const double _prepareCessationTotale = 459.69;    // brut, avant CRDS
static const double _prepareTempsPartiel50 = 297.17;     // activite <= 50%
static const double _prepareTempsPartiel80 = 171.42;     // activite 50-80%
// PreParE majoree (3+ enfants, cessation totale) :
static const double _prepareMajoree = 745.45;

// L'enum CongeParental doit etre etendu :
// enum CongeParental { aucun, cessationTotale, tempsPartiel50, tempsPartiel80 }
```

**Severite : CRITIQUE** -- Montants faux + taux manquant + PreParE majoree absente.

---

## 4. ARS (Allocation de Rentree Scolaire)

### Montants -- OK

| Tranche d'age | Code | Reel 2026 | Verdict |
|---------------|------|-----------|---------|
| 6-10 ans | 426.87 | 426.87 | OK |
| 11-14 ans | 450.41 | 450.41 | OK |
| 15-18 ans | 466.02 | 466.02 | OK |

Sources : [Service-Public.fr](https://www.service-public.gouv.fr/particuliers/actualites/A16342), [demarchesadministratives.fr](https://demarchesadministratives.fr/actualites/allocation-de-rentree-scolaire-2026-quels-sont-les-nouveaux-montants-de-ars)

### Plafonds -- ERREUR PARTIELLE

| Element | Code | Reel 2026 | Verdict |
|---------|------|-----------|---------|
| Base | 22 274 | 22 274 | OK |
| Par enfant | 6 682 | 6 682 | OK |

Le calcul du code : `22274 + nombreEnfants * 6682` est **structurellement different** du calcul officiel.

Selon Service-Public.fr, les plafonds sont :
- 1 enfant : 28 956 EUR (= 22 274 + 6 682)
- 2 enfants : 35 638 EUR (= 22 274 + 2 * 6 682)
- 3 enfants : 42 320 EUR (= 22 274 + 3 * 6 682)

Le code fait `22274 + nombreEnfants * 6682`, ce qui donne les memes valeurs. **C'est correct.**

### Point important -- pas d'erreur mais incomplet

Le plafond ARS est **identique** quelle que soit la situation familiale (couple ou isole). Le code ne distingue pas, ce qui est correct.

Cependant, le code ne gere pas l'**ARS differentielle** (versement degressif en cas de leger depassement du plafond). Ce n'est pas bloquant mais c'est une fonctionnalite manquante.

**Severite : MINEURE** -- Montants OK, plafonds OK, ARS differentielle manquante.

---

## 5. CMG -- ERREUR CRITIQUE / OBSOLETE

### Le CMG tel que code est OBSOLETE depuis septembre 2025

La reforme du CMG entree en vigueur le 1er septembre 2025 change **fondamentalement** le mode de calcul :

| Aspect | Ancien systeme (dans le code) | Nouveau systeme (sept. 2025+) |
|--------|-------------------------------|-------------------------------|
| Calcul | Montants forfaitaires par tranche | % du cout reel horaire |
| Tranches | 3 tranches fixes (27 017 / 47 648) | Bareme progressif sur revenus mensuels |
| Heures | Non prises en compte | Chaque heure comptee |
| Tarif reference | N/A | 4.91 EUR/h (ass. mat.), 10.50 EUR/h (garde dom.) |
| Minimum a charge | 15% du cout | Supprime |
| Age limite | < 6 ans | < 6 ans (< 12 ans pour parent isole) |
| Garde alternee | Division par 2 | Chaque parent peut toucher le CMG |

### Nouveau calcul (simplifie)

```
CMG = heures_garde * tarif_reference * (1 - taux_effort)
```

Ou le taux d'effort depend des revenus mensuels du foyer (plancher 635 EUR/mois, plafond 8 500 EUR/mois) et de la composition familiale.

Si le tarif reel differe du tarif de reference :
```
taux_effort_reel = taux_effort_bareme * tarif_reel / tarif_reference
```

Sources : [Service-Public.fr](https://www.service-public.gouv.fr/particuliers/actualites/A18360), [CAF.fr](https://www.caf.fr/allocataires/actualites/actualites-nationales/reforme-du-cmg-une-aide-plus-adaptee-pour-les-familles), [Urssaf.fr](https://www.urssaf.fr/accueil/actualites/evolution-cmg-ce-qui-va-changer.html), [franceemploidomicile.fr](https://www.franceemploidomicile.fr/actualite/cmg-calcul-cout-parents-2/)

### Correction requise

Le calcul CMG actuel doit etre **entierement reecrit**. Le nouveau systeme necessite :
1. Les heures de garde mensuelles (nouveau champ dans Situation)
2. Le cout horaire reel de la garde
3. Le bareme du taux d'effort (grille officielle CAF)
4. Les tarifs de reference 2026 (4.91 EUR/h ass. mat., 10.50 EUR/h garde domicile)
5. L'extension a 12 ans pour les familles monoparentales

```dart
// --- CMG REFORME SEPT. 2025 (Art. L531-5 CSS modifie) ---
// Le CMG n'est plus forfaitaire. Il est calcule a l'heure.
//
// Donnees necessaires (a ajouter dans Situation) :
//   - heuresGardeMensuelles : int
//   - coutHoraireGarde : double
//
// Tarifs de reference 2026 :
static const double _cmgTarifRefAssistanteMaternelle = 4.91; // EUR/heure
static const double _cmgTarifRefGardeDomicile = 10.50;       // EUR/heure
//
// Le taux d'effort depend d'un bareme officiel CAF base sur :
//   - revenus mensuels nets (plancher 635 EUR, plafond 8 500 EUR)
//   - nombre d'enfants a charge
//
// Age limite : < 6 ans (< 12 ans si parent isole depuis sept. 2025)
//
// Formule :
//   CMG = heures * tarif_ref * (1 - taux_effort_ajuste)
//   taux_effort_ajuste = taux_effort_bareme * cout_reel / tarif_ref
//
// NOTE : le bareme complet du taux d'effort doit etre recupere
// depuis la documentation officielle CAF ou l'instruction DSS.
```

**Severite : CRITIQUE** -- Systeme entierement obsolete, calcul fondamentalement different.

---

## Resume des erreurs

| Prestation | Severite | Erreurs |
|------------|----------|---------|
| PAJE | CRITIQUE | Plafonds completement faux (ne correspondent a aucun bareme officiel), pas de distinction couple 1 rev / 2 rev |
| CF | CRITIQUE | Montants sous-evalues (~25%), plafonds fixes au lieu de modulaires |
| PreParE | CRITIQUE | Montants faux (-27 a -30 EUR), 3e taux absent (50-80%), PreParE majoree absente |
| ARS | MINEURE | Montants et plafonds OK, ARS differentielle manquante |
| CMG | CRITIQUE | Systeme entierement obsolete (reforme sept. 2025), doit etre reecrit |

### Priorite de correction

1. **CMG** -- Le plus urgent, le calcul est fondamentalement faux depuis 7 mois
2. **CF** -- Montants faux de ~25%, impacte toutes les familles 3+ enfants
3. **PreParE** -- Montants faux + taux manquant
4. **PAJE** -- Plafonds faux, risque de faux positifs
5. **ARS** -- Correct, amelioration optionnelle (ARS differentielle)

### Donnees supplementaires necessaires dans le modele Situation

Pour corriger correctement ces prestations, le modele `Situation` doit etre enrichi :
- `coupleDeuxRevenus: bool` (ou calcul automatique si revenu conjoint >= 6 306 EUR)
- `heuresGardeMensuelles: int` (pour le nouveau CMG)
- `coutHoraireGarde: double` (pour le nouveau CMG)
- Etendre `CongeParental` avec un 3e niveau (temps partiel 50-80%)
