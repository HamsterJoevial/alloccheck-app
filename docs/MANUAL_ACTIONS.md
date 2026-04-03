# Actions manuelles — AllocCheck
*Généré le : 2026-04-03*
*Status pipeline : REVIEW (build partiel — MVP Flutter + backend, web Next.js à finaliser)*

## Avant publication

### Configuration requise
- [ ] Créer un projet Supabase (supabase.com) et récupérer URL + anon key
- [ ] Configurer les variables d'environnement Supabase (SUPABASE_URL, SUPABASE_ANON_KEY)
- [ ] Obtenir une clé API Anthropic (ANTHROPIC_API_KEY) pour la génération de courriers
- [ ] Exécuter la migration SQL `supabase/migrations/001_initial_schema.sql` sur la DB
- [ ] Déployer les Edge Functions (`calculate-rights`, `generate-letter`)
- [ ] Créer un projet RevenueCat et configurer les produits IAP :
  - `alloccheck_report` : 4,99€ (consommable — rapport PDF)
  - `alloccheck_letter` : 4,99€ (consommable — courrier contestation)
  - `alloccheck_premium` : 3,99€/mois (abonnement — suivi continu)
- [ ] Configurer RevenueCat dans l'app Flutter (API keys iOS + Android)

### Compléments code
- [ ] Finaliser le site web Next.js (pages SEO : /simulateur-rsa, /simulateur-apl, /contester-caf)
- [ ] Implémenter l'écran de génération de courrier (`/letter` route dans Flutter)
- [ ] Implémenter l'écran dashboard historique
- [ ] Ajouter l'intégration RevenueCat (paywall avant rapport PDF + lettre)
- [ ] Ajouter Supabase Auth (inscription/connexion)
- [ ] Implémenter la génération PDF du rapport détaillé (Edge Function `generate-pdf`)
- [ ] Vérifier les barèmes 2026 avec les valeurs officielles (avril 2026)

### Design
- [ ] Créer un logo AllocCheck (icône app 1024x1024)
- [ ] Personnaliser le splash screen / launch screen
- [ ] Lancer `/design` pour obtenir les specs visuelles Gemini

### Juridique
- [ ] Rédiger la politique de confidentialité (RGPD — données financières = sensibles)
- [ ] Rédiger les CGU avec disclaimer "pas un conseil juridique"
- [ ] Vérifier avec un avocat que les templates de contestation sont légaux

## Publication
- [ ] Captures écran sur device réel (iPhone 15 Pro + iPad)
- [ ] Rédiger la fiche App Store (description, mots-clés, catégorie : Finance ou Utilitaires)
- [ ] Rédiger la fiche Google Play
- [ ] Soumettre App Store Connect
- [ ] Soumettre Google Play Console
- [ ] Déployer le site web Next.js sur Vercel

## Post-publication
- [ ] Configurer analytics (Posthog ou Mixpanel)
- [ ] Lancer campagne SEO (articles blog : "erreur CAF que faire", "contester décision CAF")
- [ ] Lancer campagne Apify (voir CAMPAIGN_PROFILE.md)
- [ ] Configurer monitoring barèmes CAF (mise à jour annuelle avril)

## Audits à lancer
- [ ] `/qa-team` — qualité code
- [ ] `/security-team` — sécurité (données financières)
- [ ] `/legal-team` — RGPD + disclaimer juridique
- [ ] `/store-team` — conformité stores
- [ ] `/pricing-team` — validation modèle économique
- [ ] `/critique` — choix produit
- [ ] `/ux-review` — parcours utilisateur
