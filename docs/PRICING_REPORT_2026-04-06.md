# RAPPORT PRICING — AllocCheck v1.0.0
**Date** : 2026-04-06
**Modèle économique** : Freemium one-shot (simulation gratuite, rapport détaillé + courrier = 2,99€ via Stripe Payment Link)
**APIs payantes détectées** : Aucune en production (Claude API présente dans une Edge Function non branchée)
**Hébergement** : Netlify gratuit
**Total** : 5 items (PR0: 1 | PR1: 2 | PR2: 2)

---

## Score de santé financière

| Domaine | Score (/10) | Résumé |
|---|---|---|
| Protection contre les coûts explosifs | 9/10 | Excellent — tout est local, aucun coût variable en production |
| Cohérence de la structure tarifaire | 6/10 | Paywall contournable, constantes incohérentes, prix non affiché dans le code |
| Viabilité globale (simulation) | 8/10 | Rentable dès le premier paiement (coût fixe = 0€), marge 100% hors Stripe |

---

## PR0 — Risques immédiats

### PRICING-001 — Paywall contournable : token hardcodé en clair + vérification client-only
**Fichier** : `alloccheck_app/lib/core/services/payment_service.dart:23`
**Problème** : Le token de déverrouillage `AC2026UNLOCK` est hardcodé en clair dans le code Dart. La vérification est purement côté client (localStorage). N'importe quel utilisateur peut :
1. Lire le token dans le code source (DevTools → Sources)
2. Entrer le code dans le dialogue "Code d'accès"
3. Ou exécuter `localStorage.setItem('flutter.ac_unlocked', 'true')` dans la console

**Impact financier** : Perte de 100% des revenus si le contournement se répand (forums, réseaux sociaux). Sur le scénario nominal : -54€/mois.
**Correction** : Valider le paiement côté serveur. Options :
- Stripe Webhook → Supabase → flag `paid` vérifié par l'app
- Ou a minima : obfusquer le token et le stocker chiffré (protection minimale, insuffisante seule)

**Triage** : À corriger

---

## PR1 — Risques sérieux

### PRICING-002 — Edge Function `generate-letter` avec Claude API sans rate limiting ni paywall
**Fichier** : `supabase/functions/generate-letter/index.ts:120-136`
**Problème** : L'Edge Function est déployable sur Supabase et appelle Claude API (claude-sonnet-4-20250514, max 2000 tokens) sans :
- Rate limiting
- Vérification que l'utilisateur a payé
- Cap d'usage
Actuellement NON appelée par l'app (courrier généré localement), mais si quelqu'un la branche ou la découvre via l'URL Supabase, chaque appel coûte ~0,015€ (3$/MTok input + 15$/MTok output, ~500 tokens par appel).

**Impact financier** : Si branchée sans protection et 1000 appels/jour = ~450€/mois de Claude API.
**Correction** : Soit supprimer l'Edge Function (puisque le courrier est local), soit ajouter avant tout branchement :
1. Vérification du paiement (token/session)
2. Rate limit (max 3 appels/utilisateur/jour)
3. Cap mensuel global (ex: 100€/mois de budget API)

**Triage** : À corriger (supprimer ou protéger avant que quelqu'un ne la branche par inadvertance)

### PRICING-003 — Constantes de prix incohérentes avec le modèle réel
**Fichier** : `alloccheck_app/lib/core/constants/app_constants.dart:24-27`
**Problème** :
- `subscriptionPrice = 3.99` → référence un abonnement qui n'existe pas
- `reportPrice = 0` et `letterPrice = 0` → pas cohérent avec le modèle 2,99€
- Le prix réel (2,99€) n'apparaît nulle part dans les constantes

Ces constantes ne sont pas utilisées dans le code de paiement (le prix est dans le Payment Link Stripe), mais elles pourraient induire en erreur un développeur ou être affichées par erreur dans l'UI.

**Impact financier** : Pas de perte directe, mais risque de confusion lors de la maintenance.
**Correction** : Remplacer par :
```dart
static const double unlockPrice = 2.99; // one-shot Stripe Payment Link
// Supprimer subscriptionPrice, reportPrice, letterPrice
```

**Triage** : À corriger (fix clair)

---

## PR2 — Optimisations recommandées

### PRICING-004 — Supabase importé mais non initialisé (dépendance inutile)
**Fichier** : `alloccheck_app/pubspec.yaml:14`
**Problème** : `supabase_flutter: ^2.9.0` est dans les dépendances mais jamais initialisé (`Supabase.initialize()` absent de `main.dart`). Cela ajoute ~2MB au bundle web sans raison.
**Impact financier** : Bande passante Netlify consommée inutilement (faible, mais principe).
**Correction** : Retirer `supabase_flutter` du pubspec tant qu'il n'est pas utilisé.

**Triage** : Connu/accepté

### PRICING-005 — Prix 2,99€ non affiché avant le redirect Stripe
**Fichier** : `alloccheck_app/lib/features/results/screens/results_screen.dart`
**Problème** : Le CTA "Débloquer" redirige vers Stripe sans afficher le prix dans l'app. L'utilisateur découvre le montant uniquement sur la page Stripe. Cela peut réduire le taux de clic (incertitude) ou augmenter l'abandon sur la page de paiement.
**Correction** : Afficher "2,99€ — paiement unique" directement sur le bouton CTA dans l'app.

**Triage** : Connu/accepté

---

## Simulation financière

```
SIMULATION FINANCIÈRE — AllocCheck
Date : 2026-04-06

Hypothèses :
- Coût API : 0€ (calculs 100% locaux)
- Coût hébergement : 0€ (Netlify free tier)
- Coût Stripe par transaction : ~0,29€ (1,4% + 0,25€)
- Prix : 2,99€
- Revenu net par transaction : 2,70€

─────────────────────────────────────────────────────
SCÉNARIO PESSIMISTE (250 users/mois, 2% conversion)
─────────────────────────────────────────────────────
Utilisateurs actifs     : 250
Utilisateurs payants    : 5

Revenus bruts           : 14,95€
Commission Stripe       : 1,45€
Revenus nets            : 13,50€

Coût APIs/hébergement   : 0€

MARGE NETTE             : 13,50€/mois
Seuil de rentabilité    : 1 utilisateur payant

─────────────────────────────────────────────────────
SCÉNARIO NOMINAL (500 users/mois, 4% conversion)
─────────────────────────────────────────────────────
Utilisateurs actifs     : 500
Utilisateurs payants    : 20

Revenus bruts           : 59,80€
Commission Stripe       : 5,80€
Revenus nets            : 54,00€

Coût APIs/hébergement   : 0€

MARGE NETTE             : 54,00€/mois

─────────────────────────────────────────────────────
SCÉNARIO OPTIMISTE (1 000 users/mois, 6% conversion)
─────────────────────────────────────────────────────
Utilisateurs actifs     : 1 000
Utilisateurs payants    : 60

Revenus bruts           : 179,40€
Commission Stripe       : 17,40€
Revenus nets            : 162,00€

Coût APIs/hébergement   : 0€

MARGE NETTE             : 162,00€/mois

─────────────────────────────────────────────────────
RISQUE IDENTIFIÉ — Scénario catastrophe
─────────────────────────────────────────────────────
Que se passe-t-il si 10 000 utilisateurs utilisent
l'app intensivement ?

Coût API potentiel      : 0€ (tout est local)
Bande passante Netlify  : ~10 000 pages vues
= largement dans le tier gratuit (100 GB/mois)

RISQUE : AUCUN — le modèle est auto-suffisant
par design (zéro coût variable).

Seul risque de dépassement : bande passante Netlify
à partir de ~50 000+ visiteurs/mois
(~19$/mois pour le tier Pro si nécessaire).
```

---

## Points forts identifiés

- **Architecture zéro coût variable** : calculs locaux, PDF locaux, courriers locaux. Le modèle est rentable dès le premier paiement.
- **Valeur perçue très forte** : l'utilisateur voit "X€/an de manque à toucher" → paywall 2,99€. Le ratio valeur/prix est excellent.
- **Pas de dépendance à une API tierce** : aucun risque de facturation surprise, aucune latence réseau sur les fonctions critiques.
- **Stripe Payment Link** : solution de paiement la plus simple possible, pas de backend de paiement à maintenir.
- **One-shot sans abonnement** : pas de churn, pas de gestion de renouvellement, revenus prédictibles.
