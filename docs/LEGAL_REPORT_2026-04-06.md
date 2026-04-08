# RAPPORT LEGAL -- AllocCheck v1.0.0
**Date** : 2026-04-06
**Marches cibles** : France / EU
**Methode** : Revue statique par 3 agents specialises (RGPD, documents legaux, consentement)
**Total** : 9 items (L0: 3 | L1: 4 | L2: 2)

> RAPPEL : Ce rapport est un outil d'aide a la conformite, pas un avis juridique.
> Pour toute decision engageante, consulter un avocat specialise en droit numerique.

---

## Score de conformite

| Domaine | Score (/10) | Resume |
|---|---|---|
| Collecte de donnees RGPD | 3/10 | Donnees sensibles collectees (handicap, revenus, pension) sans base legale formalisee, aucune politique de confidentialite |
| Documents legaux | 1/10 | Aucun document legal accessible dans l'app (ni CGU, ni politique de confidentialite, ni mentions legales) |
| Mecanismes de consentement | 4/10 | Pas de tracking/cookies tiers, mais aucun consentement explicite pour le stockage local de donnees sensibles |

---

## L0 -- Violations manifestes (a corriger avant toute publication)

### LEGAL-001 -- Aucune politique de confidentialite accessible
**Texte** : RGPD Art. 13 / Art. 14 (information des personnes concernees)
**Fichier** : `alloccheck_app/lib/main.dart` (ecran d'accueil -- aucun lien)
**Probleme** : L'app collecte des donnees personnelles sensibles (situation familiale, revenus, taux de handicap, pension alimentaire, composition familiale) mais aucune politique de confidentialite n'est accessible depuis l'app. Aucun lien, aucune page, aucune mention.
**Risque** : Violation directe du RGPD Art. 13. Amende CNIL possible (jusqu'a 4% du CA ou 20M EUR). Mise en demeure probable en cas de plainte utilisateur.
**Correction** : Creer une politique de confidentialite (redigee par un professionnel) et l'afficher via un lien accessible depuis le footer de chaque ecran ou au minimum depuis l'ecran d'accueil et l'ecran de simulation. URL a ajouter aussi dans la page Stripe.
**Statut** : A corriger

### LEGAL-002 -- Aucune mention legale (identite de l'editeur)
**Texte** : LCEN Art. 6 III (Loi pour la Confiance dans l'Economie Numerique)
**Fichier** : Aucun fichier ne contient d'informations sur l'editeur
**Probleme** : L'app web ne contient aucune mention legale : pas de nom d'editeur, pas de numero SIRET, pas d'adresse, pas de contact, pas d'hebergeur. Obligatoire pour tout service en ligne edite en France.
**Risque** : Contravention de 5e classe (amende 1500 EUR par infraction). Impossible de faire valoir des droits contractuels sans identite editeur.
**Correction** : Ajouter un ecran ou une section "Mentions legales" avec : nom/raison sociale, adresse, SIRET, email de contact, hebergeur (nom + adresse). Lien accessible depuis toutes les pages.
**Statut** : A corriger

### LEGAL-003 -- Donnees de sante collectees sans base legale renforcee
**Texte** : RGPD Art. 9 (traitement des categories particulieres de donnees)
**Fichier** : `alloccheck_app/lib/core/models/situation.dart:29` (`tauxHandicap`, `besoinTiercePersonne`, `situationVie`)
**Probleme** : Le taux de handicap est une donnee de sante au sens du RGPD Art. 9. Ces donnees beneficient d'une protection renforcee et ne peuvent etre traitees que sous conditions strictes (consentement explicite Art. 9.2.a, ou interet public Art. 9.2.g). Actuellement, aucun consentement explicite n'est recueilli, et aucune base legale n'est documentee.
**Risque** : Traitement illicite de donnees sensibles. Sanction CNIL aggravee. Le taux de handicap + la situation de vie + le besoin de tierce personne constituent un profil medical detaille.
**Correction** : (1) Documenter la base legale (consentement explicite le plus adapte ici). (2) Ajouter un consentement explicite et granulaire avant la collecte du taux de handicap avec explication claire de la finalite. (3) Permettre de refuser sans bloquer les autres calculs. (4) Mentionner explicitement ce traitement dans la politique de confidentialite.
**Statut** : A corriger

---

## L1 -- Risques serieux

### LEGAL-004 -- Aucun mecanisme de suppression des donnees (droit a l'oubli)
**Texte** : RGPD Art. 17 (droit a l'effacement)
**Fichier** : `alloccheck_app/lib/core/services/payment_service.dart`
**Probleme** : Les donnees de simulation (revenus, situation familiale, handicap) sont stockees en localStorage (`SharedPreferences`) via `saveLastSimulation()` et `saveSituationAndOpenStripe()`. Aucun bouton ou mecanisme ne permet a l'utilisateur de supprimer ses donnees. La methode `clearSavedSituation()` existe mais n'est appelee que dans le flux de retour Stripe, pas a la demande de l'utilisateur.
**Risque** : Non-respect du droit a l'effacement. Plainte CNIL possible.
**Correction** : Ajouter un bouton "Supprimer mes donnees" dans les parametres ou le footer, qui appelle `SharedPreferences.clear()` pour toutes les cles `ac_*` et confirme la suppression a l'utilisateur.
**Statut** : A corriger

### LEGAL-005 -- Aucunes CGU / Conditions Generales d'Utilisation
**Texte** : Code de la consommation Art. L111-1 / RGPD Art. 6.1.b (base legale contractuelle)
**Fichier** : Aucun
**Probleme** : L'app propose un service payant (Stripe Payment Link a 2.99 EUR) sans CGU. L'utilisateur paie sans avoir accepte de conditions contractuelles. Aucun cadre legal pour le service fourni (simulation, courrier de contestation).
**Risque** : Litige consommateur sans protection contractuelle. Le disclaimer "ne constitue pas un conseil juridique" n'a aucune valeur sans CGU acceptees. Risque accru vu que l'app genere des courriers de contestation a destination de la CAF.
**Correction** : Rediger des CGU (avec un professionnel) couvrant : nature du service (simulation indicative), limitations de responsabilite, droit de retractation (14 jours), modalites de paiement. Afficher et faire accepter explicitement avant le premier paiement.
**Statut** : A corriger

### LEGAL-006 -- Donnees sensibles stockees en clair dans localStorage
**Texte** : RGPD Art. 32 (securite du traitement)
**Fichier** : `alloccheck_app/lib/core/services/payment_service.dart:73-83`
**Probleme** : La situation complete de l'utilisateur (revenus, handicap, pension alimentaire, composition familiale) est serialisee en JSON et stockee en clair dans le localStorage du navigateur (`_jsLocalStorageSetItem`). Le CLAUDE.md du projet mentionne "Chiffrement AES-256 pour revenus et composition familiale en DB" mais cote client, aucun chiffrement n'est applique.
**Risque** : Tout script tiers ou extension navigateur peut lire ces donnees. Sur un ordinateur partage, l'utilisateur suivant peut acceder aux donnees sensibles. Le localStorage n'est pas un stockage securise.
**Correction** : (1) Minimiser les donnees stockees localement (ne garder que l'ID de session, pas les donnees brutes). (2) Si le stockage local est necessaire : chiffrer les donnees avant ecriture. (3) Ajouter un nettoyage automatique apres X heures/jours.
**Statut** : A corriger

### LEGAL-007 -- Absence d'information sur le transfert de donnees hors EU (Stripe)
**Texte** : RGPD Art. 44-49 (transferts vers pays tiers)
**Fichier** : `alloccheck_app/lib/core/services/payment_service.dart:28` (lien Stripe)
**Probleme** : Le paiement passe par Stripe (siege US). Lorsque l'utilisateur clique sur le lien de paiement, ses donnees de paiement sont traitees par Stripe Inc. aux Etats-Unis. Aucune information n'est fournie a l'utilisateur sur ce transfert. Note : la situation de simulation est sauvegardee localement avant le redirect, donc seules les donnees de paiement vont chez Stripe (pas les donnees de simulation).
**Risque** : Non-information sur les transferts hors EU. Stripe dispose de clauses contractuelles types (SCCs) mais l'utilisateur doit en etre informe.
**Correction** : Mentionner dans la politique de confidentialite : (1) que le paiement est traite par Stripe Inc., (2) que Stripe est certifie DPF (Data Privacy Framework) et utilise des SCCs, (3) lien vers la politique de confidentialite de Stripe.
**Statut** : Connu/accepte (a traiter dans la politique de confidentialite globale -- LEGAL-001)

---

## L2 -- Bonnes pratiques manquantes

### LEGAL-008 -- Pas de duree de retention definie pour les donnees locales
**Texte** : RGPD Art. 5.1.e (limitation de la conservation)
**Fichier** : `alloccheck_app/lib/core/services/payment_service.dart:110-113`
**Probleme** : Les donnees de la derniere simulation (`ac_last_simulation`) sont conservees indefiniment dans le localStorage. Aucun TTL ni nettoyage automatique n'est implemente. Les donnees incluent des informations sensibles (revenus, handicap).
**Risque** : Non-conformite au principe de minimisation de la conservation. Faible risque pratique car localStorage est local, mais mauvaise pratique.
**Correction** : Ajouter une expiration automatique (ex: 30 jours) via le timestamp deja stocke (`ac_last_simulation_ts`). Verifier au demarrage et supprimer si expire.
**Statut** : Connu/accepte

### LEGAL-009 -- Disclaimer juridique insuffisant et peu visible
**Texte** : Directive 2005/29/CE (pratiques commerciales deloyales) / Deontologie
**Fichier** : `alloccheck_app/lib/main.dart:247-249` (fontSize: 10)
**Probleme** : Le disclaimer "Outil d'aide a la comprehension de vos droits. Ne constitue pas un conseil juridique." est affiche en taille 10px sur l'ecran d'accueil, peu lisible. Il n'est pas repete sur l'ecran de simulation ni sur l'ecran de resultats (ou l'utilisateur prend des decisions). Le courrier de contestation est genere sans rappel visible que l'utilisateur en assume la responsabilite.
**Risque** : En cas de litige, un disclaimer si discret pourrait ne pas etre considere comme une information suffisante. L'app genere des courriers officiels pour la CAF — la frontiere avec le conseil juridique est mince.
**Correction** : (1) Augmenter la taille du disclaimer (min 12px). (2) Repeter le disclaimer sur les ecrans de resultats et de courrier. (3) Sur l'ecran de courrier : ajouter une case a cocher "Je comprends que ce courrier est un modele que je dois adapter et dont j'assume la responsabilite."
**Statut** : Connu/accepte

---

## Checklist manuelle pre-publication

> Ces points ne peuvent pas etre verifies depuis le code source.

- [ ] Politique de confidentialite redigee par un professionnel et a jour
- [ ] CGU redigees par un professionnel
- [ ] Mentions legales completes (editeur, SIRET, hebergeur)
- [ ] Registre des traitements tenu a jour (RGPD Art. 30)
- [ ] Accord de traitement des donnees (DPA) signe avec Stripe
- [ ] DPA signe avec Supabase (si utilise en prod)
- [ ] Procedure de reponse aux demandes d'acces/suppression documentee
- [ ] Droit de retractation de 14 jours informe et implemente (vente en ligne)
- [ ] URL de politique de confidentialite renseignee sur la page Stripe Payment Link
- [ ] Conformite LCEN verifiee pour le site web (mentions legales obligatoires)
- [ ] Base legale du traitement des donnees de sante (handicap) formalisee et documentee

---

## Points conformes identifies

- Aucun SDK de tracking ou analytics integre — pas de collecte de donnees comportementales
- Aucune permission systeme demandee (pas de camera, micro, localisation, contacts)
- Pas d'identifiant publicitaire (IDFA/GAID) utilise
- Les calculs sont effectues localement (CalculLocalService) — les donnees ne transitent pas systematiquement par un serveur distant
- Disclaimer present sur l'ecran d'accueil (meme si insuffisant)
- Le stockage de la situation est local (localStorage navigateur) — pas d'envoi automatique a un backend
- Supabase n'est pas connecte/actif (URL par defaut "your-project.supabase.co") — aucune donnee ne part vers un backend pour l'instant
- L'app ne collecte ni email, ni nom, ni adresse dans le parcours de simulation (uniquement dans le courrier de contestation, a l'initiative de l'utilisateur)
