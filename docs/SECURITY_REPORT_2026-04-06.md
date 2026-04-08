# RAPPORT SECURITE — AllocCheck v1.0.0

**Date** : 2026-04-06
**Stack** : Flutter Web (Dart + dart:js_interop), deploye Netlify (alloccheck.flowforges.fr)
**Methode** : Analyse statique + revue de code par 10 agents specialises
**Total** : 8 findings (S0: 2 | S1: 2 | S2: 2 | S3: 2)
**Modele IAP** : Oui — Stripe Payment Link 2,99€, deblocage unique

---

## Score de risque global

| Domaine | Score (/10) | Resume |
|---|---|---|
| Protection IAP / Anti-piratage | 2/10 | Bypass trivial du paywall via localStorage |
| Secrets & Credentials | 3/10 | Token de deblocage en dur dans le code source |
| Stockage local | 4/10 | Donnees sensibles en clair dans localStorage |
| Securite reseau | 8/10 | HTTPS uniquement, pas d'HTTP en clair |
| Authentification | N/A | Pas d'auth utilisateur (anonyme) |
| Resistance au reverse engineering | 3/10 | Code Dart/JS non obfusque, token lisible |
| Permissions & surface d'attaque | 9/10 | Surface minimale, web-only |
| Detection device compromis | N/A | Non applicable (web) |
| Validation des entrees | 7/10 | Validation basique presente, pas de backend SQL |
| Dependances & supply chain | 7/10 | Dependances majeures a jour, lock file present |
| **Score global** | **5/10** | **Paywall trivialement contournable, donnees sensibles non protegees** |

---

## Resultats analyse statique automatisee

| Check | Resultat |
|---|---|
| Secrets en clair detectes | 1 trouve (token AC2026UNLOCK) |
| URLs HTTP non chiffrees | OK — aucune |
| Dependances obsoletes | OK |
| Obfuscation release | Non verifiable (web) |

---

## S0 — Critiques (a corriger avant toute publication)

### SEC-001 — Token de deblocage Stripe en dur dans le code source

**Vecteur** : N'importe qui peut ouvrir les DevTools du navigateur, chercher "AC2026UNLOCK" dans le JS compile, puis acceder a `alloccheck.flowforges.fr?paid=AC2026UNLOCK` pour debloquer le rapport complet sans payer.
**Fichier** : `lib/core/services/payment_service.dart:23`
**Code** : `static const _validToken = 'AC2026UNLOCK';`
**Impact** : Bypass complet du paywall — 0€ de revenu. Le token est aussi affiche en hint dans l'UI (results_screen.dart:334).
**Correction** : Generer un token unique par transaction cote serveur (Stripe webhook -> Supabase). Le retour Stripe devrait contenir un `session_id` verifie server-side, pas un token statique.

---

### SEC-002 — Paywall contournable via localStorage

**Vecteur** : Ouvrir la console JS du navigateur, taper `localStorage.setItem('flutter.ac_unlocked', 'true')`, recharger la page. Acces complet au rapport sans payer.
**Fichier** : `lib/core/services/payment_service.dart:33-46`
**Code** : `isUnlocked()` lit un simple booleen SharedPreferences (`ac_unlocked`). `checkUrlAndUnlock()` ecrit `true` sans verification serveur.
**Impact** : Bypass complet du paywall en 5 secondes, sans aucune competence technique.
**Correction** : Verifier le statut de paiement cote serveur (Stripe Checkout Session -> endpoint Supabase qui retourne un token signe/JWT). Ne jamais se fier a un booleen local pour le paywall.

---

## S1 — Eleves (a corriger rapidement)

### SEC-003 — Donnees personnelles sensibles stockees en clair dans localStorage

**Vecteur** : Les donnees de simulation (revenus, composition familiale, situation de handicap, numero allocataire) sont stockees en JSON en clair dans localStorage sous les cles `flutter.ac_saved_situation` et `flutter.ac_last_simulation`. N'importe quelle extension navigateur, script XSS ou personne ayant acces physique a l'ordinateur peut lire ces donnees.
**Fichier** : `lib/core/services/payment_service.dart:72-87` (saveSituationAndOpenStripe), `110-113` (saveLastSimulation)
**Code** : `_jsLocalStorageSetItem('flutter.$_situationKey', jsonStr)` avec `jsonStr = jsonEncode(situation.toJsonFull())` contenant revenus, handicap, pension, etc.
**Impact** : Fuite de donnees financieres et medicales (handicap, pension invalidite). Risque RGPD Art. 9 (donnees de sante).
**Correction** : (1) chiffrer les donnees avec une cle derivee avant stockage, (2) supprimer les donnees apres usage (la simulation sauvegardee devrait etre temporaire), (3) ne pas stocker le numero allocataire localement.

---

### SEC-004 — Code de deblocage expose dans l'UI (hint text)

**Vecteur** : Le hint text du champ de saisie du code affiche le token exact : `'Votre code (ex : AC2026UNLOCK)'`. L'utilisateur n'a meme pas besoin des DevTools — le code est visible dans l'interface.
**Fichier** : `lib/features/results/screens/results_screen.dart:334`
**Code** : `hintText: 'Votre code (ex : AC2026UNLOCK)'`
**Impact** : Bypass du paywall sans aucun outil technique, visible par tous les utilisateurs.
**Correction** : Retirer le token du hint text. Utiliser un placeholder generique (`'Votre code d'acces'`). Le code de deblocage devrait etre unique par achat (genere par Stripe webhook).

---

## S2 — Moderes (planifier)

### SEC-005 — Stripe Payment Link sans verification de session

**Vecteur** : Le flux de paiement utilise un Stripe Payment Link statique avec un parametre `?paid=AC2026UNLOCK` en `success_url`. Il n'y a aucune verification Stripe Checkout Session server-side. Un utilisateur peut partager le lien de retour (`alloccheck.flowforges.fr?paid=AC2026UNLOCK`) sans jamais avoir paye.
**Fichier** : `lib/core/services/payment_service.dart:28`
**Code** : `static const _stripePaymentLink = 'https://buy.stripe.com/...'` avec retour sur `?paid=AC2026UNLOCK`
**Impact** : Le lien de retour post-paiement peut etre partage et utilise par quiconque. Perte de revenus.
**Correction** : Migrer vers Stripe Checkout Session avec webhook server-side. Le `success_url` devrait contenir un `{CHECKOUT_SESSION_ID}` verifie par une Edge Function Supabase.

---

### SEC-006 — Donnees de simulation non nettoyees apres usage

**Vecteur** : `getSavedSituation()` restaure la simulation mais `clearSavedSituation()` n'est appele que dans un seul chemin (`_checkPaymentReturn` dans HomeScreen). Si l'utilisateur navigue differemment ou si le retour Stripe echoue, les donnees restent indefiniment dans localStorage.
**Fichier** : `lib/main.dart:104` (seul endroit ou `clearSavedSituation` est appele)
**Code** : `await PaymentService.clearSavedSituation()` — un seul call path
**Impact** : Donnees personnelles (revenus, handicap) persistent indefiniment dans le navigateur.
**Correction** : Ajouter un `clearSavedSituation()` systematique apres restauration dans tous les chemins, et un nettoyage automatique apres 24h (TTL).

---

## S3 — Renforcements (backlog securite)

### SEC-007 — Pas de Content Security Policy (CSP)

**Vecteur** : L'index.html ne definit aucune CSP. Sur Netlify, sans headers configures, l'app est vulnerable aux injections de scripts tiers (XSS via extensions, ads injectees par FAI/proxy).
**Fichier** : `web/index.html`
**Code** : Aucune balise `<meta http-equiv="Content-Security-Policy">` ni configuration `_headers` Netlify.
**Impact** : Risque XSS — un script injecte pourrait lire localStorage (donnees personnelles + token de deblocage).
**Correction** : Ajouter un fichier `_headers` Netlify ou une meta CSP dans index.html.

---

### SEC-008 — Supabase credentials dans le code source (valeurs par defaut placeholder)

**Vecteur** : Les constantes Supabase utilisent `String.fromEnvironment` avec des valeurs par defaut placeholder. Si le build est lance sans les variables d'environnement, l'app utilisera ces placeholders. Pas exploitable en l'etat mais le pattern est risque pour le futur.
**Fichier** : `lib/core/constants/app_constants.dart:9-16`
**Code** : `defaultValue: 'https://your-project.supabase.co'` et `defaultValue: 'your-anon-key'`
**Impact** : Faible actuellement (Supabase non cable). Risque futur si des vrais credentials sont mis en default.
**Correction** : Ne pas mettre de `defaultValue` — laisser vide et faire echouer explicitement si non configure.

---

## Checklist de test de securite manuelle

### Protection paywall
- [ ] Ouvrir DevTools > Console > `localStorage.setItem('flutter.ac_unlocked', 'true')` > recharger — le rapport complet est-il accessible ?
- [ ] Naviguer vers `alloccheck.flowforges.fr?paid=AC2026UNLOCK` directement — le rapport est-il debloque ?
- [ ] Partager le lien Stripe success_url avec un autre navigateur — le deblocage fonctionne-t-il sans paiement ?
- [ ] Saisir "AC2026UNLOCK" dans le champ code d'acces — le deblocage fonctionne-t-il ?

### Stockage et donnees au repos
- [ ] Faire une simulation > DevTools > Application > localStorage — les donnees sont-elles lisibles en clair ?
- [ ] Verifier que les donnees de simulation sont supprimees apres usage
- [ ] Verifier qu'aucun numero allocataire n'est stocke dans localStorage

### Securite reseau
- [ ] Verifier que le Stripe Payment Link utilise HTTPS
- [ ] Verifier les headers HTTP de alloccheck.flowforges.fr (CSP, X-Frame-Options, etc.)

### Resistance au reverse engineering
- [ ] Chercher "AC2026UNLOCK" dans le fichier JS compile (main.dart.js) — est-il en clair ?
- [ ] Chercher "ac_unlocked" dans le JS compile — la cle localStorage est-elle visible ?

---

## Points forts — protections deja en place
- Aucune URL HTTP non chiffree — tout est HTTPS
- Pas d'auth utilisateur (pas de tokens JWT a proteger)
- Calcul 100% local (pas d'appels reseau pour les calculs — zero surface d'attaque reseau)
- Validation des entrees sur chaque etape du formulaire
- Supabase non cable donc pas de surface d'attaque backend
- pubspec.lock present dans le repo (reproductibilite)
- Disclaimer juridique correct et present
