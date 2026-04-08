# Audit prestations sociales -- AllocCheck
*Date : 06/04/2026*
*Fichier audite : `alloccheck_app/lib/core/services/calcul_local_service.dart`*

## Resume

- **12 aides calculees**, **8 erreurs/inexactitudes trouvees**, **4 aides manquantes** calculables
- Bareme declare "avril 2026" mais plusieurs montants sont obsoletes (non revalorise 0.8%)
- La reforme Prime d'activite avril 2026 (taux 59.85% au lieu de 61%) n'est PAS appliquee
- L'ASF est fortement sous-evalue (164.96 EUR vs 200.78 EUR officiel)
- L'ARS utilise les montants 2024 (non revalorise depuis 2 revalorisations)
- Les plafonds AF sont incorrects (anciens baremes)

---

## Verification des baremes

### Montants de base

| Aide | Montant dans l'app | Montant officiel avril 2026 | Statut | Source |
|------|-------------------|---------------------------|--------|--------|
| RSA base (seul) | 651.69 EUR | 651.69 EUR | OK | [Decret 2026-220](https://www.legifrance.gouv.fr/jorf/id/JORFTEXT000053733826) |
| AAH max | 1 041.59 EUR | 1 041.59 EUR | OK | [Decret 2026-229](https://www.legifrance.gouv.fr/jorf/id/JORFTEXT000053734356) |
| Prime base | 638.28 EUR | 638.28 EUR | OK | [Decret 2026-222](https://www.legifrance.gouv.fr/jorf/id/JORFTEXT000053733855) |
| MVA | 104.77 EUR | 104.77 EUR | OK | [Service-Public.fr](https://www.service-public.fr/particuliers/vosdroits/F12903) |
| ASF/enfant | **164.96 EUR** | **200.78 EUR** | **ERREUR** | [CAF.fr](https://www.caf.fr/allocataires/droits-et-prestations/s-informer-sur-les-aides/solidarite-et-insertion/l-allocation-de-soutien-familial-asf) |
| BMAF (AF) | 478.16 EUR (implicite) | 478.16 EUR | OK | [Service-Public.fr](https://www.service-public.fr/particuliers/actualites/A15599) |
| PAJE taux plein | **185.54 EUR** | **198.16 EUR** | **ERREUR** | [aide-sociale.fr](https://www.aide-sociale.fr/allocation-base-caf/) |
| PAJE taux partiel | **92.77 EUR** | **99.09 EUR** | **ERREUR** | [aide-sociale.fr](https://www.aide-sociale.fr/allocation-base-caf/) |
| PreParE taux plein | **396.01 EUR** | **428.71 EUR** | **ERREUR** | [CAF.fr](https://caf.fr/professionnels/offres-et-services/accompagnement-des-allocataires/bareme-prestation-partagee-d-education-de-l-enfant) |
| PreParE taux demi | **256.01 EUR** | **277.14 EUR** | **ERREUR** | [CAF.fr](https://caf.fr/professionnels/offres-et-services/accompagnement-des-allocataires/bareme-prestation-partagee-d-education-de-l-enfant) |
| ASS journaliere | **18.43 EUR (552.90/mois)** | **19.48 EUR (584.40/mois)** | **ERREUR** | [Decret 2026-219](https://www.legifrance.gouv.fr/jorf/id/JORFTEXT000053733811) |
| ARS 6-10 ans | **403.72 EUR** | **426.87 EUR** | **ERREUR** | [Service-Public.fr](https://www.service-public.gouv.fr/particuliers/actualites/A16342) |
| ARS 11-14 ans | **424.95 EUR** | **450.41 EUR** | **ERREUR** | [Service-Public.fr](https://www.service-public.gouv.fr/particuliers/actualites/A16342) |
| ARS 15-18 ans | **440.65 EUR** | **466.02 EUR** | **ERREUR** | [Service-Public.fr](https://www.service-public.gouv.fr/particuliers/actualites/A16342) |
| Bonif. prime max | 240.63 EUR | 240.63 EUR | OK | [CAF Bareme](https://www.caf.fr/professionnels/offres-et-services/accompagnement-des-allocataires/bareme-prime-d-activite) |
| Seuil bonif. min | 709.18 EUR | 709.18 EUR | OK | [CAF Bareme](https://www.caf.fr/professionnels/offres-et-services/accompagnement-des-allocataires/bareme-prime-d-activite) |
| Seuil bonif. max | 1 658.76 EUR | 1 658.76 EUR | OK | [CAF Bareme](https://www.caf.fr/professionnels/offres-et-services/accompagnement-des-allocataires/bareme-prime-d-activite) |

### Forfaits logement RSA

| Config | Montant app | Montant officiel | Statut | Note |
|--------|------------|-----------------|--------|------|
| 1 personne | 77.58 EUR | ~78.20 EUR (12% de 651.69) | A VERIFIER | Ecart de 0.62 EUR -- le forfait officiel est 12% du montant forfaitaire |
| 2 personnes | 155.16 EUR | ~156.27 EUR (16% de 977.54) | A VERIFIER | Ecart possible selon l'arrondi |
| 3+ personnes | 192.02 EUR | ~192.11 EUR (16.5% de plafond 3p) | QUASI OK | Ecart negligeable |

> **Note** : les forfaits logement sont definis reglementairement comme un pourcentage du montant forfaitaire RSA. Les ecarts suggerent que les forfaits dans l'app n'ont pas ete recalcules pour le bareme avril 2026.

### Plafonds AF

| Parametre | Valeur app | Valeur officielle 2026 | Statut |
|-----------|-----------|----------------------|--------|
| Plafond T1 (2 enf.) | 78 565 EUR | **74 650 + 7 465 = 82 115 EUR** | **ERREUR** |
| Plafond T2 (2 enf.) | 104 719 EUR | **104 469 + 7 465 = 111 934 EUR** | **ERREUR** |
| Supp./enfant | 6 105 EUR | **7 465 EUR** | **ERREUR** |

> **Analyse** : Les plafonds dans l'app correspondent a un ancien bareme (probablement 2024). Le nouveau bareme est un plafond de base + majoration par enfant, pas un plafond pour 2 enfants + supplement. La structure du calcul doit etre revue.

### Plafonds Complement Familial

| Parametre | Valeur app | Valeur officielle 2026 | Statut |
|-----------|-----------|----------------------|--------|
| Seuil majore | 25 000 EUR | **~22 410 EUR** (couple 3 enf. : 13 918 + majorations) | **A REVOIR** |
| Seuil normal | 43 000 EUR | **~47 600 EUR** (couple 3 enf. : 27 835 + majorations) | **A REVOIR** |

> **Analyse** : Les plafonds CF dans l'app sont des approximations qui ne correspondent pas aux plafonds officiels 2026. Le CF a des plafonds qui varient selon le nombre d'enfants et la situation familiale (couple/isole, biactivite). L'app utilise un seuil fixe.

---

## Verification des formules

### RSA -- Art. L262-2 CASF

**Structure du calcul** : globalement correcte (forfaitaire - ressources - forfait logement).

**Majorations** :
- Couple : +50% -- OK
- Enfant 1-2 : +30% chacun -- OK
- Enfant 3+ : +40% chacun -- OK

**Parent isole** :
- L'app utilise `_rsaMajorationIsolementBase = 0.5` et `_rsaMajorationIsolementParEnfant = 0.4`
- Le RSA majore officiel = 128.412% du montant de base (soit 836.85 EUR pour 0 enfant, +42.86% de 651.69 par enfant)
- **PROBLEME** : l'app calcule `base * (1 + 0.5) = 977.54` pour parent isole sans enfant, mais le RSA majore officiel est 836.85 EUR (651.69 * 1.28412). L'app semble confondre majoration couple et majoration isolement.
- **Impact** : SURESTIMATION du RSA majore de ~141 EUR/mois pour parent isole avec 1 enfant.

**Forfait logement** : correctement applique si heberge OU si APL percue. OK.

**Pension alimentaire versee** : correctement deduite des ressources. OK.

### APL -- Art. L841-1 CCH

**Formule simplifiee** : l'app utilise un calcul approximatif (taux de participation lineaire). La formule reelle de l'APL est beaucoup plus complexe (R° = 0.0, D° = ..., avec des tables de participation personnelle).

- L'approximation donne un ordre de grandeur mais peut diverger significativement du calcul reel.
- Les loyers plafond semblent correspondre au bareme octobre 2025 maintenu en 2026, ce qui est correct.
- **Charges forfaitaires** : 60.59 EUR -- a verifier, peut avoir ete revalorise.
- **Seuil minimum** : 15 EUR -- OK (le seuil officiel est bien de 15 EUR).

**Verdict** : formule simplifiee acceptable pour une estimation, mais l'ecart peut etre significatif.

### Prime d'activite -- Art. L841-3 CSS

**ERREUR MAJEURE** : le taux de prise en compte des revenus d'activite est de **61%** dans l'app, mais il a ete abaisse a **59.85%** au 1er avril 2026 (reforme decret 2026-222).

- **Impact** : surestimation systematique de la prime d'activite.
- **Formule dans l'app** : `forfaitaire + 0.61 * revenusActivite + bonification - ressources`
- **Formule officielle 2026** : `forfaitaire + 0.5985 * revenusActivite + bonification - ressources`

**Autres points** :
- Majorations couple/enfants : OK (identiques au RSA)
- Bonification individuelle : OK (seuils et max corrects)
- AAH non comptee comme ressource : OK (art. R844-5 CSS)
- Pension alimentaire versee deduite : OK

### Allocations familiales -- Art. L512-1 CSS

**Montants de base** :
- 2 enfants : 153.01 EUR (32% BMAF) -- a verifier finement, mais proche
- 3 enfants : 350.79 EUR (73.36% BMAF) -- OK par rapport a la BMAF
- Supplement/enfant supp. : 197.77 EUR -- OK

**Majoration age** :
- L'app utilise 18+ ans depuis 01/03/2026 -- **Correct** (decret 2026-138 du 27/02/2026)
- Pas de majoration pour l'aine de 2 enfants -- **Correct**
- Montant majoration : 75.53 EUR -- correspond a la tranche 1

**Plafonds** : voir section baremes -- **ERREUR** sur les plafonds de ressources.

### AAH -- Art. L821-1 CSS

**Deconjugalisation** : correctement implementee. Seules les ressources du demandeur sont prises en compte. OK.

**Plafonds** :
- Seul : 12 400 EUR/an -- a verifier precisement. Le plafond officiel est d'environ 12 x AAH max = 12 499 EUR/an pour une personne seule.
- L'app utilise `_aahPlafondSeul = 12400` -- le plafond reel devrait etre revu.
- Majoration/enfant : 6 200 EUR/an -- a verifier (demi-plafond).

**Calcul** : `AAH max - ressources mensuelles` -- formule simplifiee. Le calcul reel de l'AAH differentielle est base sur un abattement des ressources (pas une simple soustraction). Il y a un abattement de 80% sur les revenus d'activite, un abattement de 20% sur les revenus d'activite au-dela d'un certain seuil, etc.

**Verdict** : formule approximative.

### MVA -- Art. L821-1-2 CSS

**Conditions** :
- Taux >= 80% : OK
- AAH au taux plein : OK
- Pas de revenu d'activite : OK
- Vie autonome (pas en institution) : OK
- Locataire : **PARTIELLEMENT CORRECT** -- la condition est d'avoir un logement independant pour lequel on percoit une aide au logement (APL/ALS/ALF), pas simplement d'etre locataire. Un proprietaire avec APL accession pourrait aussi y avoir droit.

**Montant** : 104.77 EUR -- OK.

### ASF -- Art. L523-1 CSS

**Montant** : **ERREUR GRAVE** -- 164.96 EUR dans l'app vs 200.78 EUR officiel.
- L'ASF a ete revalorisee de +50% en novembre 2022, puis revalorisee annuellement.
- Le montant dans l'app semble etre un ancien montant pre-2022 revalorise insuffisamment.

**Conditions** :
- Parent isole : OK
- Veuf ou pension non percue : OK
- **MANQUE** : l'ASF peut aussi etre versee a un enfant recueilli (267.63 EUR/enfant), mais ce cas est marginal.

### CMG -- Art. L531-5 CSS

**REFORME SEPTEMBRE 2025** : Le CMG a ete profondement reforme au 01/09/2025. Le nouveau calcul prend en compte un pourcentage des frais reels de garde, plus un forfait fixe par tranche. L'app utilise l'ancien systeme de montants forfaitaires par tranche.

- Les montants dans l'app (923/461/230.50 EUR) ne correspondent plus au systeme actuel.
- Le nouveau CMG utilise des taux de prise en charge (jusqu'a 85% des couts) avec un minimum de 15% restant a charge (supprime depuis sept. 2025).
- Le CMG est desormais etendu jusqu'a 12 ans pour les familles monoparentales.

**Impact** : le calcul CMG est **obsolete** depuis la reforme de septembre 2025.

### PAJE base -- Art. L531-2 CSS

- Montants : **ERREUR** -- 185.54/92.77 EUR au lieu de 198.16/99.09 EUR
- Plafonds : a revoir (les plafonds dans l'app semblent anciens)

### Complement Familial -- Art. L522-1 CSS

- Montants : 260.57/173.71 EUR -- les montants semblent bas. Avec BMAF 478.16 EUR, le CF majore = 41.65% BMAF = 199.15 EUR et le CF normal = 36.96% BMAF = 176.73 EUR, ou des baremes plus complexes.
- **Plafonds** : approximatifs, ne correspondent pas aux plafonds officiels.

### PreParE -- Art. L531-4 CSS

- Montants : **ERREUR** -- 396.01/256.01 EUR au lieu de 428.71/277.14 EUR
- Ces montants semblent etre ceux de 2023 ou 2024.

### ARS -- Art. L543-1 CSS

- Montants : **ERREUR** -- 403.72/424.95/440.65 EUR (baremes 2024) vs 426.87/450.41/466.02 EUR (avril 2026)
- Plafonds ARS :
  - App : 25 336 EUR (isole), 32 267 EUR (couple) -- **ERREUR** pour 2026 : 22 274 EUR + 6 682/enfant
  - La structure est differente : le plafond officiel est un montant unique + majoration/enfant, pas separe isole/couple

### ASS (dans TypeAutreRevenu)

- Montant fixe : 552.90 EUR/mois (18.43 EUR/jour) -- **ERREUR** -- le montant est de 19.48 EUR/jour = 584.40 EUR/mois depuis avril 2026.

---

## Interactions entre aides

### Correctement implementees

| Interaction | Implementation | Statut |
|------------|---------------|--------|
| AAH comptee comme ressource RSA | `aahMensuel` ajoute aux ressources RSA | OK |
| AAH NON comptee pour Prime activite | Non incluse dans ressources prime | OK |
| APL declenche forfait logement RSA | `percoitApl` teste pour appliquer forfait | OK |
| Pension versee deduite du RSA | `pensionAlimentaireVersee` soustraite | OK |
| Pension versee deduite de l'APL | Soustraite des ressources APL | OK |
| Pension versee deduite de la prime | Soustraite des ressources prime | OK |

### Manquantes ou incorrectes

| Interaction | Probleme | Impact |
|------------|---------|--------|
| RSA + ASF | L'ASF n'est pas incluse comme ressource RSA alors qu'elle devrait l'etre (art. R262-11 CASF) | Surestimation RSA |
| APL + ASF | L'ASF n'est pas incluse comme ressource APL | Surestimation APL |
| MVA + AAH | La MVA exige de percevoir une aide au logement, pas simplement d'etre locataire | Eligibilite trop large |
| PreParE + Prime activite | PreParE = arret d'activite, donc normalement pas de prime d'activite. Pas de garde-fou | Possible double comptage |
| CF + PAJE | Le CF n'est verse que si aucun enfant < 3 ans dans le foyer (sauf si PAJE AB non percue). L'app ne verifie pas ce non-cumul | Possible surestimation |

---

## Aides manquantes

### Calculables avec les donnees actuelles

| Aide | Montant indicatif | Donnees necessaires | Deja collectees ? |
|------|-------------------|--------------------|--------------------|
| **AEEH** (Allocation Education Enfant Handicape) | 151.80 EUR/mois base + complements | `tauxHandicap` + `agesEnfants` (enfant < 20 ans avec handicap >= 50%) | PARTIELLEMENT -- il faudrait savoir si le handicap concerne le demandeur ou un enfant |
| **ALS/ALF** (Allocation Logement Sociale/Familiale) | Variable | `logementConventionne` est deja collecte mais pas utilise | OUI -- le champ existe mais est ignore |
| **Prime naissance PAJE** | ~1 066.30 EUR (one-shot) | Grossesse/naissance recente | NON -- pas de donnee "enceinte" ou "naissance recente" |
| **MTP** (Majoration Tierce Personne) | ~1 170 EUR/mois | `besoinTiercePersonne` est collecte mais pas utilise dans le calcul | OUI -- le champ existe mais est ignore |

### Non calculables sans donnees supplementaires

| Aide | Raison | Suggestion |
|------|--------|------------|
| CSS (Complementaire Sante Solidaire) | Calcul complexe dependant du regime, de la composition detaillee | Garder en suggestion |
| Cheque Energie | Envoye automatiquement, pas de demande possible | Garder en suggestion |
| PCH | Decision MDPH, pas calculable | Garder en suggestion |
| AJPA (Allocation Journaliere Proche Aidant) | Pas de donnee aidant | Ajouter en suggestion |
| ASI (Allocation Supplementaire Invalidite) | Pas de donnee invalidite specifique | Ajouter en suggestion si pension invalidite declaree |

---

## Erreurs identifiees -- classees par impact

### CRITIQUE (impact > 30 EUR/mois sur le montant final)

| # | Erreur | Aide | Impact estime | Correction |
|---|--------|------|--------------|------------|
| 1 | **ASF sous-evalue** : 164.96 au lieu de 200.78 EUR/enfant | ASF | -35.82 EUR/enfant/mois | Mettre a jour `_asfMontantParEnfant = 200.78` |
| 2 | **Prime activite taux 61% au lieu de 59.85%** | Prime | Surestimation variable (5-20 EUR/mois selon revenus) | Changer `0.61` en `0.5985` |
| 3 | **PAJE obsolete** : 185.54 au lieu de 198.16 EUR | PAJE | -12.62 EUR/mois | Mettre a jour les montants |
| 4 | **PreParE obsolete** : 396.01 au lieu de 428.71 EUR | PreParE | -32.70 EUR/mois | Mettre a jour les montants |
| 5 | **ARS obsolete** : montants 2024 au lieu de 2026 | ARS | -23 a -25 EUR/an par enfant | Mettre a jour les 3 tranches |
| 6 | **CMG reforme** : ancien systeme forfaitaire | CMG | Variable, potentiellement important | Reimplementer selon reforme sept. 2025 |
| 7 | **RSA parent isole** : majoration incorrecte | RSA | +141 EUR/mois surestimation | Corriger les taux de majoration isolement |

### MAJEUR (impact sur l'eligibilite)

| # | Erreur | Aide | Impact | Correction |
|---|--------|------|--------|------------|
| 8 | **Plafonds AF incorrects** | AF | Fausse eligibilite/ineligibilite | Mettre a jour plafonds 2026 (74 650 + 7 465/enfant) |
| 9 | **Plafonds CF approximatifs** | CF | Fausse eligibilite | Revoir avec plafonds officiels 2026 |
| 10 | **ASS montant fixe obsolete** | Modele | Impact indirect sur calculs | 19.48 EUR/jour = 584.40 EUR/mois |
| 11 | **ARS plafonds incorrects** | ARS | Fausse eligibilite | 22 274 + 6 682/enfant |

### MINEUR (precision)

| # | Erreur | Aide | Impact | Correction |
|---|--------|------|--------|------------|
| 12 | **ALS/ALF non distinguees** | APL | Pas d'impact direct si meme calcul | Le champ `logementConventionne` est collecte mais ignore |
| 13 | **Forfaits logement RSA** : legers ecarts | RSA | < 1 EUR/mois | Recalculer en % du forfaitaire |
| 14 | **MVA condition locataire** trop restrictive | MVA | Quelques cas manques | Verifier aide au logement, pas juste statut locataire |
| 15 | **MTP non calculee** | N/A | Donnee collectee mais pas utilisee | Ajouter le calcul |

---

## Recommandations

### Priorite 1 -- Corrections urgentes (baremes faux)

1. **Mettre a jour l'ASF** : `_asfMontantParEnfant = 200.78`
2. **Mettre a jour le taux Prime activite** : `0.61` -> `0.5985`
3. **Mettre a jour PAJE** : `_pajeTauxPlein = 198.16`, `_pajeTauxPartiel = 99.09`
4. **Mettre a jour PreParE** : `_prepareTauxPlein = 428.71`, `_prepareTauxDemi = 277.14`
5. **Mettre a jour ARS** : `403.72 -> 426.87`, `424.95 -> 450.41`, `440.65 -> 466.02`
6. **Mettre a jour ASS** : `552.90 -> 584.40` (dans `TypeAutreRevenu.ass`)
7. **Corriger les plafonds AF** : plafond de base 74 650 EUR + 7 465 EUR/enfant au-dela de 2
8. **Corriger le RSA parent isole** : majoration isolement = 128.412% de la base (pas +50% comme couple)

### Priorite 2 -- Corrections importantes (formules)

9. **Corriger les plafonds ARS** : 22 274 EUR + 6 682 EUR/enfant
10. **Revoir les plafonds CF** avec les vrais baremes 2026
11. **Revoir les plafonds PAJE** avec les vrais baremes 2026
12. **Ajouter interaction ASF -> ressources RSA/APL**
13. **Ajouter non-cumul CF + PAJE base** (si enfant < 3 ans)

### Priorite 3 -- Ameliorations

14. **Reforme CMG** : le systeme de montants forfaitaires par tranche est obsolete depuis sept. 2025. A reimplementer selon le nouveau modele (% des frais reels).
15. **Ajouter l'AEEH** : les donnees handicap sont collectees, un enfant < 20 ans avec taux >= 50% devrait declencher le calcul.
16. **Utiliser `logementConventionne`** : distinguer APL (conventionne) vs ALS/ALF (non conventionne) pour l'information affichee.
17. **Ajouter la MTP** : le champ `besoinTiercePersonne` est collecte mais jamais exploite.
18. **Corriger MVA** : la condition devrait etre "percoit une aide au logement" et non simplement "est locataire".

---

## Sources principales

- [Decret 2026-220 RSA](https://www.legifrance.gouv.fr/jorf/id/JORFTEXT000053733826)
- [Decret 2026-222 Prime activite](https://www.legifrance.gouv.fr/jorf/id/JORFTEXT000053733855)
- [Decret 2026-229 AAH](https://www.legifrance.gouv.fr/jorf/id/JORFTEXT000053734356)
- [Decret 2026-219 ASS](https://www.legifrance.gouv.fr/jorf/id/JORFTEXT000053733811)
- [Arrete plafonds AF 2026](https://www.legifrance.gouv.fr/jorf/id/JORFTEXT000053165980)
- [Arrete plafonds CF 2026](https://www.legifrance.gouv.fr/jorf/id/JORFTEXT000053166082)
- [CAF Bareme AF](https://www.caf.fr/professionnels/offres-et-services/accompagnement-des-allocataires/bareme-allocations-familiales)
- [CAF Bareme Prime activite](https://www.caf.fr/professionnels/offres-et-services/accompagnement-des-allocataires/bareme-prime-d-activite)
- [CAF Bareme CMG](https://www.caf.fr/professionnels/offres-et-services/accompagnement-des-allocataires/bareme-complement-de-mode-de-garde)
- [CAF ASF](https://www.caf.fr/allocataires/droits-et-prestations/s-informer-sur-les-aides/solidarite-et-insertion/l-allocation-de-soutien-familial-asf)
- [Service-Public.fr Revalorisation avril 2026](https://www.service-public.fr/particuliers/actualites/A15599)
- [Service-Public.fr ARS 2026](https://www.service-public.gouv.fr/particuliers/actualites/A16342)
- [Service-Public.fr MVA](https://www.service-public.fr/particuliers/vosdroits/F12903)
