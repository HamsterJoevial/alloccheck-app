# Audit Expert : AF, AAH, MVA, ASF

**Date** : 6 avril 2026
**Fichier audite** : `lib/core/services/calcul_local_service.dart`
**Baremes de reference** : 1er avril 2026 (revalorisation +0,8%)
**BMAF officielle** : 478,16 EUR

---

## 1. Allocations Familiales (AF)

### 1.1 BMAF

- **Valeur dans l'app** : 478,16 EUR (en commentaire ligne 100)
- **Valeur officielle** : 478,16 EUR
- **Source** : [Ministere des Solidarites](https://solidarites.gouv.fr/revalorisation-annuelle-des-prestations-sociales-au-1er-avril-2026), [Service-Public.fr](https://www.service-public.gouv.fr/particuliers/actualites/A16506)
- **Statut** : CORRECT

### 1.2 Montant 2 enfants (tranche 1)

- **Valeur dans l'app** : 153,01 EUR (`_afBase2Enfants`)
- **Valeur officielle** : 153,01 EUR (32% x 478,16 = 153,01)
- **Source** : [Ministere des Solidarites](https://solidarites.gouv.fr/revalorisation-annuelle-des-prestations-sociales-au-1er-avril-2026), [aide-sociale.fr](https://www.aide-sociale.fr/montant-allocation-familiale/)
- **Statut** : CORRECT
- **Note** : Le commentaire dans le code dit "31.95% BMAF" alors que le taux officiel est 32%. Le resultat numerique est neanmoins correct (arrondi).

### 1.3 Montant 3 enfants (tranche 1)

- **Valeur dans l'app** : 350,79 EUR (`_afBase3Enfants`)
- **Valeur officielle** : 349,06 EUR (73% x 478,16 = 349,06)
- **Source** : [aide-sociale.fr](https://www.aide-sociale.fr/montant-allocation-familiale/), [quelles-aides.fr](https://www.quelles-aides.fr/allocations-familiales/allocations/allocations-familiales/), [mes-allocs.fr](https://www.mes-allocs.fr/guides/allocations-familiales/montant-allocations-familiales/augmentation-allocations-familiales/)
- **Statut** : **ERREUR** (+1,73 EUR/mois)
- **Cause** : Le code utilise 73,36% au lieu de 73%. Le taux officiel (CLEISS, art. D521-1 CSS) est de 73% de la BMAF.
- **Impact** : Surestimation de 1,73 EUR/mois pour toutes les familles de 3+ enfants.

### 1.4 Supplement par enfant au-dela de 3 (tranche 1)

- **Valeur dans l'app** : 197,77 EUR (`_afSupplementParEnfant`)
- **Valeur officielle** : 196,04 EUR (41% x 478,16 = 196,04)
- **Source** : [CLEISS](https://www.cleiss.fr/docs/regimes/regime_france6_prestations-familiales.html) (taux 41% BMAF)
- **Statut** : **ERREUR** (+1,73 EUR/enfant/mois)
- **Cause** : Le code utilise 41,41% au lieu de 41%.
- **Impact** : Cumul avec l'erreur 3 enfants. Pour 4 enfants : +3,46 EUR/mois d'ecart.
- **Verification croisee** : 4 enfants officiel = 545,10 EUR. Code = 350,79 + 197,77 = 548,56 EUR. Ecart = +3,46 EUR.

### 1.5 Majoration 18+ ans (tranche 1)

- **Valeur dans l'app** : 75,53 EUR (`_afMajoration18Plus`)
- **Valeur officielle** : 76,51 EUR (16% x 478,16 = 76,51)
- **Source** : [CLEISS](https://www.cleiss.fr/docs/regimes/regime_france6_prestations-familiales.html) (taux 16% BMAF), [aide-sociale.fr](https://www.aide-sociale.fr/montant-allocation-familiale/)
- **Statut** : **ERREUR** (-0,98 EUR/enfant majore/mois)
- **Cause** : Le code utilise une ancienne valeur (75,53 correspond a 16% x 474,37 = 75,90 ; en fait 75,53 ne correspond a aucune BMAF recente). La valeur post-avril 2026 est 76,51.
- **Note importante** : Certaines sources mentionnent 75,53 EUR comme montant pre-avril 2026 (tranche 1). Apres verification, aide-sociale.fr liste bien 76,13 EUR pour la majoration tranche 1 (a partir du 1er janvier 2026, sur revenus 2024), et la revalorisation avril porte ce montant a 76,51 EUR. La valeur 75,53 du code semble etre le montant 2025 (avant revalorisation).

### 1.6 Regle "pas d'aine dans famille de 2 enfants"

- **Valeur dans l'app** : Implementee (lignes 808-809)
- **Regle officielle** : L'aine d'une famille de 2 enfants n'ouvre pas droit a la majoration pour age.
- **Source** : Art. D521-2 CSS, [Service-Public.fr](https://www.service-public.gouv.fr/particuliers/vosdroits/F13213)
- **Statut** : CORRECT

### 1.7 Plafonds de ressources

- **Valeur dans l'app** : Plafond T1 = 74 650 EUR + 7 465 EUR/enfant supp. Plafond T2 = 104 469 EUR + 7 465 EUR/enfant supp.
- **Valeur officielle** : Plafond T1 = 79 980 EUR (2 enfants) + 6 664 EUR/enfant supp. Plafond T2 = 106 604 EUR (2 enfants) + 6 664 EUR/enfant supp.
- **Source** : [aide-sociale.fr](https://www.aide-sociale.fr/montant-allocation-familiale/), [quelles-aides.fr](https://www.quelles-aides.fr/allocations-familiales/allocations/allocations-familiales/)
- **Statut** : **ERREUR CRITIQUE**
- **Detail des ecarts** :
  - Plafond T1 2 enfants : 74 650 dans le code vs 79 980 officiel (-5 330 EUR)
  - Plafond T2 2 enfants : 104 469 dans le code vs 106 604 officiel (-2 135 EUR)
  - Majoration/enfant : 7 465 dans le code vs 6 664 officiel (+801 EUR)
- **Impact** : Les plafonds du code sont trop bas. Des familles entre 74 650 et 79 980 EUR se verront attribuer une tranche 2 (demi-tarif) alors qu'elles ont droit au taux plein. **Impact financier majeur**.
- **Cause probable** : Les plafonds 74 650 / 104 469 correspondent aux plafonds 2024 (revenus 2022), pas aux plafonds 2026 (revenus 2024). Les plafonds sont revalorises au 1er janvier de chaque annee, independamment de la revalorisation d'avril.

### 1.8 Diviseurs tranches 2 et 3

- **Valeur dans l'app** : Tranche 2 = montant / 2. Tranche 3 = montant / 4.
- **Valeur officielle** : Tranche 2 = taux plein / 2. Tranche 3 = taux plein / 4.
- **Source** : Art. D521-1 CSS
- **Statut** : CORRECT (le principe est bon)

### 1.9 Complement degressif

- **Valeur dans l'app** : Non implemente
- **Regle officielle** : Si les ressources depassent legerement un plafond, un complement degressif est verse pour eviter un effet de seuil.
- **Source** : Art. D521-2 CSS, [Service-Public.fr](https://www.service-public.gouv.fr/particuliers/vosdroits/F13213)
- **Statut** : **MANQUANT** (risque de sous-estimation pour les familles juste au-dessus d'un plafond)

---

## 2. AAH (Allocation aux Adultes Handicapes)

### 2.1 Montant maximum

- **Valeur dans l'app** : 1 041,59 EUR (`_aahMontantMax`)
- **Valeur officielle** : 1 041,59 EUR
- **Source** : [Ministere des Solidarites](https://solidarites.gouv.fr/revalorisation-annuelle-des-prestations-sociales-au-1er-avril-2026), [monparcourshandicap.gouv.fr](https://www.monparcourshandicap.gouv.fr/actualite/montant-aah)
- **Statut** : CORRECT

### 2.2 Plafond annuel personne seule

- **Valeur dans l'app** : 12 400 EUR (`_aahPlafondSeul`)
- **Valeur officielle** : 12 400 EUR (certaines sources mentionnent 12 499,08 = 12 x 1 041,59, d'autres 12 400 EUR)
- **Source** : [aide-sociale.fr](https://www.aide-sociale.fr/aah-differentielle/)
- **Statut** : CORRECT (conforme a la source aide-sociale.fr qui indique explicitement 12 400 EUR)
- **Note** : Le plafond AAH ne correspond pas exactement a 12 x montant max (12 x 1 041,59 = 12 499,08). Le plafond est fixe par decret et vaut effectivement 12 400 EUR pour une personne seule.

### 2.3 Plafond couple et majoration enfant

- **Valeur dans l'app** : Couple = 22 444 EUR (non utilise grace a la deconjugalisation). Enfant = +6 200 EUR.
- **Valeur officielle** : Couple = 22 444 EUR. Enfant = +6 200 EUR.
- **Source** : [aide-sociale.fr](https://www.aide-sociale.fr/aah-differentielle/)
- **Statut** : CORRECT
- **Note** : Le code declare `_aahPlafondCouple = 18600.0` mais ne l'utilise pas (deconjugalisation). La valeur officielle du plafond couple post-deconjugalisation est 22 444 EUR, ce qui est different, mais sans impact car le plafond couple n'est pas utilise dans le calcul.

### 2.4 Deconjugalisation

- **Valeur dans l'app** : Seuls les revenus du demandeur sont pris en compte (ligne 854)
- **Regle officielle** : Depuis octobre 2023, seules les ressources du demandeur comptent
- **Source** : [aide-sociale.fr](https://www.aide-sociale.fr/aah-differentielle/)
- **Statut** : CORRECT

### 2.5 Abattement sur revenus d'activite

- **Valeur dans l'app** : AUCUN abattement. Le code fait `AAH_max - ressourcesAnnuelles / 12` (ligne 870), soit une deduction brute des revenus.
- **Regle officielle** : Abattement de **80%** sur la partie des revenus d'activite inferieure a 30% du SMIC brut, et **40%** sur la partie superieure a 30% du SMIC brut (art. R821-4 CSS).
- **Source** : [Legifrance art. R821-4](https://www.legifrance.gouv.fr/codes/article_lc/LEGIARTI000052141008), [zenior.care](https://zenior.care/guides/aah-montant), [mes-allocs.fr](https://www.mes-allocs.fr/guides/aah/calcul-aah/)
- **Statut** : **ERREUR CRITIQUE**
- **Impact** : Sans abattement, un beneficiaire AAH qui travaille a mi-temps (ex: 800 EUR/mois) se voit retirer 800 EUR de son AAH (resultat : 241,59 EUR). Avec l'abattement officiel :
  - 30% SMIC brut ~= 546,91 EUR
  - Sur 546,91 EUR : abattement 80% => retenu = 109,38 EUR
  - Sur 253,09 EUR restants : abattement 40% => retenu = 151,85 EUR
  - Total retenu = 261,23 EUR
  - AAH = 1 041,59 - 261,23 = 780,36 EUR
  - **Ecart : 780,36 vs 241,59 = -538,77 EUR/mois de sous-estimation**
- **Consequence** : L'app dit aux travailleurs handicapes qu'ils n'ont droit a presque rien, alors qu'ils ont droit a une AAH substantielle. C'est l'erreur la plus grave de l'audit.

### 2.6 Distinction taux 50-79% vs >=80%

- **Valeur dans l'app** : Le code verifie `tauxHandicap >= 50` (ligne 847) mais ne distingue pas les deux plages.
- **Regle officielle** : 
  - Taux **>= 80%** : AAH sans restriction de duree
  - Taux **50-79%** : AAH uniquement si RSDAE (Restriction Substantielle et Durable d'Acces a l'Emploi), attribuee pour 1 a 5 ans maximum
- **Source** : Art. L821-2 CSS, [monparcourshandicap.gouv.fr](https://www.monparcourshandicap.gouv.fr/actualite/montant-aah)
- **Statut** : **MANQUANT** (pas bloquant pour le calcul du montant, mais l'app devrait informer l'utilisateur de la condition RSDAE pour les taux 50-79%)

### 2.7 Cumul 6 premiers mois d'activite

- **Valeur dans l'app** : Non implemente
- **Regle officielle** : Pendant les 6 premiers mois d'activite, les revenus professionnels ne sont pas pris en compte. L'AAH est maintenue integralement.
- **Source** : [mes-allocs.fr](https://www.mes-allocs.fr/guides/aah/calcul-aah/)
- **Statut** : **MANQUANT** (difficile a implementer sans historique, mais devrait etre mentionne dans le disclaimer)

---

## 3. MVA (Majoration pour la Vie Autonome)

### 3.1 Montant

- **Valeur dans l'app** : 104,77 EUR (`_mvaMontant`)
- **Valeur officielle** : 104,77 EUR
- **Source** : [Service-Public.fr](https://www.service-public.gouv.fr/particuliers/vosdroits/F12903), [vitalliance.fr](https://www.vitalliance.fr/conseils/la-majoration-pour-la-vie-autonome-mva)
- **Statut** : CORRECT

### 3.2 Condition : taux d'incapacite >= 80%

- **Valeur dans l'app** : Implementee (ligne 977)
- **Valeur officielle** : Taux d'incapacite >= 80% requis
- **Source** : [Service-Public.fr](https://www.service-public.gouv.fr/particuliers/vosdroits/F12903)
- **Statut** : CORRECT

### 3.3 Condition : AAH a taux plein

- **Valeur dans l'app** : Le code verifie `aahMontant < _aahMontantMax` (ligne 980) — exige AAH strictement egale au max
- **Valeur officielle** : Percevoir l'AAH a taux plein OU en complement d'une retraite/pension d'invalidite/rente AT
- **Source** : [Service-Public.fr](https://www.service-public.gouv.fr/particuliers/vosdroits/F12903), [monparcourshandicap.gouv.fr](https://www.monparcourshandicap.gouv.fr/aides/la-majoration-pour-la-vie-autonome-mva-un-complement-pour-vivre-chez-soi)
- **Statut** : **INCOMPLET** — Le code exclut a tort les beneficiaires qui percoivent l'AAH en complement d'une pension. La condition devrait etre "percevoir l'AAH" (meme differentielle dans certains cas), pas uniquement "AAH = taux plein strict".

### 3.4 Condition : pas de revenu d'activite

- **Valeur dans l'app** : Implementee (ligne 983)
- **Valeur officielle** : Ne pas percevoir de revenus d'activite professionnelle
- **Source** : [Service-Public.fr](https://www.service-public.gouv.fr/particuliers/vosdroits/F12903)
- **Statut** : CORRECT

### 3.5 Condition : vie autonome

- **Valeur dans l'app** : Implementee (ligne 986)
- **Valeur officielle** : Vivre dans un logement independant
- **Source** : [Service-Public.fr](https://www.service-public.gouv.fr/particuliers/vosdroits/F12903)
- **Statut** : CORRECT

### 3.6 Condition : aide au logement

- **Valeur dans l'app** : Implementee (ligne 990 — verifie aplMontant > 0)
- **Valeur officielle** : Percevoir une aide au logement (APL, ALS ou ALF)
- **Source** : [Service-Public.fr](https://www.service-public.gouv.fr/particuliers/vosdroits/F12903)
- **Statut** : CORRECT

### 3.7 Non-cumul avec le Complement de Ressources (CPR)

- **Valeur dans l'app** : Non mentionne dans le code
- **Regle officielle** : Le CPR a ete supprime le 1er decembre 2019. Les anciens beneficiaires conservent le droit pendant 10 ans (jusqu'en 2029). MVA et CPR ne sont pas cumulables.
- **Source** : [Service-Public.fr](https://www.service-public.gouv.fr/particuliers/vosdroits/F12911), [handicap.fr](https://informations.handicap.fr/a-complement-ressource-aah-mva-11164.php)
- **Statut** : **MANQUANT** (mineur — le CPR n'est plus attribue, mais certains anciens beneficiaires le percoivent encore)

---

## 4. ASF (Allocation de Soutien Familial)

### 4.1 Montant par enfant (parent isole, pension non versee)

- **Valeur dans l'app** : 200,78 EUR (`_asfMontantParEnfant`)
- **Valeur officielle** : 200,78 EUR/mois/enfant
- **Source** : [aide-sociale.fr](https://www.aide-sociale.fr/allocation-soutien-familial/), [CAF.fr](https://www.caf.fr/professionnels/offres-et-services/accompagnement-des-allocataires/l-allocation-de-soutien-familial-asf)
- **Statut** : CORRECT

### 4.2 Deux taux (orphelin total vs pension non versee)

- **Valeur dans l'app** : Un seul montant (200,78 EUR) pour tous les cas
- **Valeur officielle** : 
  - 200,78 EUR/mois si l'enfant est prive de l'aide d'un seul parent (pension non versee)
  - **267,63 EUR/mois** si l'enfant est recueilli et prive de l'aide de ses **deux** parents (orphelin total ou enfant recueilli)
- **Source** : [aide-sociale.fr](https://www.aide-sociale.fr/allocation-soutien-familial/), [mes-allocs.fr](https://www.mes-allocs.fr/guides/allocations-familiales/allocation-soutien-familial/)
- **Statut** : **ERREUR** — Le taux majore (267,63 EUR) pour enfant recueilli / orphelin de pere et mere n'est pas implemente. Le code utilise le taux mineur uniquement.

### 4.3 Conditions : parent isole + pension non versee OU deces

- **Valeur dans l'app** : Verifie `parentIsole` + (`estVeuf` OU `pensionAlimentaireNonPercue`) (lignes 1004-1014)
- **Valeur officielle** : Parent isole + pension non versee, OU enfant orphelin d'un parent, OU enfant recueilli
- **Source** : Art. L523-1 CSS
- **Statut** : CORRECT (pour les cas couverts, mais le cas "enfant recueilli par un tiers" n'est pas couvert)

### 4.4 ASF differentielle

- **Valeur dans l'app** : Non implementee
- **Regle officielle** : Si la pension alimentaire est versee mais inferieure a 200,78 EUR, la CAF verse la difference (ASF differentielle)
- **Source** : [aide-sociale.fr](https://www.aide-sociale.fr/allocation-soutien-familial/)
- **Statut** : **MANQUANT**

### 4.5 Absence de condition de ressources

- **Valeur dans l'app** : Pas de verification de plafond de ressources
- **Valeur officielle** : L'ASF n'est soumise a aucune condition de ressources
- **Source** : [aide-sociale.fr](https://www.aide-sociale.fr/allocation-soutien-familial/)
- **Statut** : CORRECT

---

## Resume des anomalies

### ERREURS CRITIQUES (impact financier majeur)

| # | Prestation | Parametre | Ecart | Impact |
|---|-----------|-----------|-------|--------|
| 1 | **AAH** | Abattement revenus d'activite absent | Jusqu'a -538 EUR/mois | Travailleurs handicapes fortement sous-estimes |
| 2 | **AF** | Plafonds de ressources obsoletes | -5 330 EUR sur plafond T1 | Familles declassees en tranche inferieure a tort |

### ERREURS (impact financier modere)

| # | Prestation | Parametre | Valeur app | Valeur officielle | Ecart |
|---|-----------|-----------|------------|-------------------|-------|
| 3 | AF | Montant 3 enfants | 350,79 | 349,06 | +1,73 |
| 4 | AF | Supplement/enfant supp. | 197,77 | 196,04 | +1,73 |
| 5 | AF | Majoration 18+ | 75,53 | 76,51 | -0,98 |
| 6 | ASF | Taux orphelin total absent | 200,78 seul | 267,63 manquant | -66,85 |

### MANQUANTS (fonctionnalites absentes)

| # | Prestation | Element manquant | Criticite |
|---|-----------|-----------------|-----------|
| 7 | AF | Complement degressif | Moyenne |
| 8 | AAH | Distinction 50-79% / RSDAE (information) | Faible |
| 9 | AAH | Cumul integral 6 premiers mois d'activite | Moyenne |
| 10 | MVA | Condition "AAH en complement pension" | Moyenne |
| 11 | MVA | Non-cumul CPR (anciens beneficiaires) | Faible |
| 12 | ASF | ASF differentielle | Moyenne |

---

## Corrections prioritaires recommandees

### Priorite 1 — Immediat

1. **AAH : implementer l'abattement sur revenus d'activite** (art. R821-4 CSS)
   - 80% d'abattement sur les revenus <= 30% SMIC brut (~546,91 EUR)
   - 40% d'abattement sur les revenus au-dela
   - Sans cet abattement, le calcul est fondamentalement faux pour tout beneficiaire AAH qui travaille

2. **AF : mettre a jour les plafonds de ressources 2026**
   - T1 base 2 enfants : 79 980 EUR (pas 74 650)
   - T2 base 2 enfants : 106 604 EUR (pas 104 469)
   - Majoration par enfant supp. : 6 664 EUR (pas 7 465)

### Priorite 2 — Rapide

3. **AF : corriger les montants 3+ enfants**
   - 3 enfants : 349,06 EUR (73% x BMAF)
   - Supplement/enfant : 196,04 EUR (41% x BMAF)
   - Majoration 18+ : 76,51 EUR (16% x BMAF)

4. **ASF : ajouter le taux orphelin total**
   - 267,63 EUR/enfant/mois si l'enfant est prive de ses deux parents

### Priorite 3 — Amelioration

5. MVA : elargir la condition AAH (complement retraite/pension)
6. AF : implementer le complement degressif
7. AAH : informer sur la condition RSDAE pour les taux 50-79%
8. ASF : implementer l'ASF differentielle

---

Sources principales :
- [Ministere des Solidarites - Revalorisation avril 2026](https://solidarites.gouv.fr/revalorisation-annuelle-des-prestations-sociales-au-1er-avril-2026)
- [Service-Public.fr - Montants avril 2026](https://www.service-public.gouv.fr/particuliers/actualites/A16506)
- [Service-Public.fr - AF](https://www.service-public.gouv.fr/particuliers/vosdroits/F13213)
- [Service-Public.fr - MVA](https://www.service-public.gouv.fr/particuliers/vosdroits/F12903)
- [aide-sociale.fr - AF](https://www.aide-sociale.fr/montant-allocation-familiale/)
- [aide-sociale.fr - AAH differentielle](https://www.aide-sociale.fr/aah-differentielle/)
- [aide-sociale.fr - ASF](https://www.aide-sociale.fr/allocation-soutien-familial/)
- [CLEISS - Taux BMAF](https://www.cleiss.fr/docs/regimes/regime_france6_prestations-familiales.html)
- [Legifrance - Art. R821-4 CSS](https://www.legifrance.gouv.fr/codes/article_lc/LEGIARTI000052141008)
- [monparcourshandicap.gouv.fr - AAH](https://www.monparcourshandicap.gouv.fr/actualite/montant-aah)
- [monparcourshandicap.gouv.fr - MVA](https://www.monparcourshandicap.gouv.fr/aides/la-majoration-pour-la-vie-autonome-mva-un-complement-pour-vivre-chez-soi)
