# RAPPORT STORE — AllocCheck v1.0.0+1
**Date** : 2026-04-06
**Cibles** : iOS + Android (builds prevus — actuellement web-only Netlify)
**Methode** : Revue de configuration par 3 agents specialises (iOS, Android, Commun)
**Total** : 8 items (ST0: 3 | ST1: 3 | ST2: 2)

---

## Score de conformite

| Store | Score (/10) | Resume |
|---|---|---|
| App Store (iOS) | 4/10 | Paiement Stripe interdit sur iOS natif, Privacy Manifest manquant, CFBundleName incorrect |
| Google Play (Android) | 6/10 | Signing release non configure, android:label incorrect, pas de permission INTERNET en main |

---

## ST0 — Rejets certains (a corriger avant toute soumission)

### STORE-001 — Paiement via Stripe Payment Link interdit sur iOS natif
**Store** : iOS
**Fichier** : `lib/core/services/payment_service.dart:28`
**Probleme** : L'app redirige vers un Stripe Payment Link externe (`https://buy.stripe.com/...`) pour debloquer du contenu in-app (rapport + lettre). Sur iOS natif, Apple exige que tout achat de contenu numerique consomme dans l'app passe par le systeme IAP d'Apple (App Store Review Guideline 3.1.1). Stripe est autorise uniquement pour des biens/services physiques ou consommes hors de l'app.
**Impact** : Rejet automatique — violation de la guideline 3.1.1 (In-App Purchase Required).
**Correction** : Pour le build iOS, implementer StoreKit/RevenueCat pour le deblocage a 2,99 EUR. Stripe peut rester pour la version web. Alternative : proposer l'app iOS en gratuit sans paywall (simulation + rapport gratuits) et monetiser uniquement via le web.
**Triage** : A corriger

### STORE-002 — Privacy Manifest (PrivacyInfo.xcprivacy) absent
**Store** : iOS
**Fichier** : `ios/Runner/` (fichier manquant)
**Probleme** : Depuis mai 2024, Apple exige un Privacy Manifest pour toute app soumise a l'App Store. L'app utilise `shared_preferences` (UserDefaults), `url_launcher`, `google_fonts` (reseau) — ces APIs sont des "required reason APIs" (NSPrivacyAccessedAPITypes). Aucun fichier `PrivacyInfo.xcprivacy` n'est present.
**Impact** : Rejet automatique — App Store Review exige le Privacy Manifest depuis le 1er mai 2024.
**Correction** : Creer `ios/Runner/PrivacyInfo.xcprivacy` declarant : NSPrivacyAccessedAPICategoryUserDefaults (raison CA92.1 — app functionality), NSPrivacyAccessedAPICategorySystemBootTime si applicable. Declarer NSPrivacyCollectedDataTypes si des donnees sont collectees. Ajouter le fichier au target Runner dans Xcode.
**Triage** : A corriger

### STORE-003 — Signing release non configure (Android)
**Store** : Android
**Fichier** : `android/app/build.gradle.kts:35`
**Probleme** : Le bloc `release` utilise `signingConfigs.getByName("debug")`. Google Play refuse les APK/AAB signes avec la cle de debug.
**Impact** : Rejet automatique — impossible d'uploader sur Google Play Console.
**Correction** : Configurer un keystore de release (`upload-keystore.jks`), creer un `key.properties`, et referencer `signingConfigs.create("release")` dans le build.gradle.kts.
**Triage** : A corriger

---

## ST1 — Rejets probables

### STORE-004 — Politique de confidentialite inaccessible depuis l'app
**Store** : Les deux
**Fichier** : `lib/main.dart` (aucun lien privacy detecte)
**Probleme** : Aucun lien vers une politique de confidentialite n'est visible dans l'app. L'app collecte des donnees financieres sensibles (revenus, composition familiale, situation de handicap). Apple (guideline 5.1.1) et Google (User Data Policy) exigent un lien accessible depuis l'app ET depuis les fiches store.
**Impact** : Rejet probable — donnees sensibles collectees sans politique de confidentialite visible.
**Correction** : Ajouter un lien "Politique de confidentialite" dans l'ecran d'accueil (footer) et/ou dans un tiroir "A propos". Rediger et heberger la politique sur une URL publique (ex: `https://alloccheck.flowforges.fr/privacy`).
**Triage** : A corriger (fix clair)

### STORE-005 — CFBundleName affiche "alloccheck_app" au lieu du nom produit
**Store** : iOS
**Fichier** : `ios/Runner/Info.plist:20`
**Probleme** : `CFBundleName` vaut `alloccheck_app` (nom technique) au lieu de `AllocCheck`. Ce nom apparait dans certains contextes systeme (Spotlight, partage). `CFBundleDisplayName` est correctement a `AllocCheck`, mais la coherence est attendue.
**Impact** : Pas un rejet automatique mais le reviewer peut le signaler ; cela denote un manque de finition.
**Correction** : Remplacer `<string>alloccheck_app</string>` par `<string>AllocCheck</string>` dans Info.plist.
**Triage** : A corriger (fix clair)

### STORE-006 — android:label affiche "alloccheck_app" au lieu du nom produit
**Store** : Android
**Fichier** : `android/app/src/main/AndroidManifest.xml:3`
**Probleme** : `android:label="alloccheck_app"` — le nom affiche sous l'icone sera "alloccheck_app" au lieu de "AllocCheck".
**Impact** : Rejet probable — nom d'app non professionnel visible par les utilisateurs et les reviewers.
**Correction** : Remplacer par `android:label="AllocCheck"`.
**Triage** : A corriger (fix clair)

---

## ST2 — Points de vigilance

### STORE-007 — Icones d'app par defaut (Flutter placeholder)
**Store** : Les deux
**Fichier** : `android/app/src/main/res/mipmap-*/ic_launcher.png` + `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
**Probleme** : Les icones sont les icones Flutter par defaut. Les deux stores rejettent parfois les apps avec des icones placeholder ou non distinctives.
**Impact** : Risque de rejet si le reviewer considere l'icone comme un placeholder. Mauvaise premiere impression sur la fiche store.
**Correction** : Generer une icone personnalisee pour AllocCheck et la deployer via `flutter_launcher_icons` ou manuellement dans les dossiers concernes.
**Triage** : Connu/accepte (prerequis avant soumission mais pas un fix de code)

### STORE-008 — Pas de gestion offline minimale
**Store** : Les deux
**Fichier** : N/A (comportement runtime)
**Probleme** : L'app effectue tous ses calculs localement (`CalculLocalService`), ce qui est bien. Mais le paiement Stripe necessite une connexion. Les stores apprecient qu'une app fonctionne au moins partiellement offline.
**Impact** : Faible — la simulation gratuite fonctionne offline, seul le paiement necessite le reseau.
**Correction** : Aucune action requise — le calcul local est deja offline-capable. Eventuellement ajouter un message d'erreur gracieux si le paiement echoue sans reseau.
**Triage** : Connu/accepte

---

## Checklist manuelle pre-soumission

> Ces points ne peuvent pas etre verifies depuis le code source.

### App Store Connect
- [ ] Screenshots aux bonnes dimensions pour chaque taille d'ecran ciblee
- [ ] Description et mots-cles completes et optimises ASO
- [ ] Classification d'age correctement renseignee (probablement 4+ ou 12+)
- [ ] URL de politique de confidentialite renseignee dans App Store Connect
- [ ] Notes de version redigees
- [ ] App Review Information : notes pour le reviewer expliquant que le paiement est via Stripe (web) ou IAP selon la strategie choisie

### Google Play Console
- [ ] Screenshots et feature graphic uploades
- [ ] Fiche store complete (description courte + longue)
- [ ] Questionnaire de contenu complete (classification)
- [ ] URL de politique de confidentialite renseignee
- [ ] Declaration de donnees (Data Safety) completee — declarer : informations financieres, situation familiale
- [ ] Keystore de release configure et sauvegarde en lieu sur

---

## Points forts — conformite deja en place

- `ITSAppUsesNonExemptEncryption` correctement declare a `false` dans Info.plist
- `CFBundleDisplayName` correctement a "AllocCheck"
- Pas de permissions dangereuses demandees (pas de camera, micro, contacts, localisation)
- Pas d'IAP natif declare = pas de probleme de configuration StoreKit/Play Billing (mais c'est justement le probleme STORE-001)
- AndroidManifest propre — permission INTERNET uniquement en debug/profile (correct pour Flutter)
- Icone 1024x1024 presente pour iOS (App Store marketing)
- Toutes les tailles d'icones iPhone + iPad declarees dans Contents.json
- Disclaimer juridique present dans l'app ("ne constitue pas un conseil juridique")
- Calcul des droits entierement local (pas de dependance serveur pour le coeur de l'app)
