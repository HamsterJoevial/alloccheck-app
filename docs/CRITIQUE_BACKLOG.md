# Critique produit — Backlog des recommandations
*Derniere mise a jour : 2026-04-06*
*Rapport complet : docs/CRITIQUE_2026-04-06.md*

## A corriger

- [ ] Export PDF rapport ne fonctionne pas sur mobile (bytes generees mais jamais partagees) — Features — voir rapport 2026-04-06
- [ ] Garde alternee proposee uniquement aux couples (devrait etre divorce/separe) — Features — voir rapport 2026-04-06
- [ ] Validation pension versee manquante (Step 0 accepte montant 0) — UX — voir rapport 2026-04-06
- [ ] Bouton retour physique Android quitte la simulation au lieu de revenir a l'etape precedente — UX — voir rapport 2026-04-06
- [ ] Step 1 Famille surcharge quand toutes conditions actives (25+ widgets) — UX — voir rapport 2026-04-06
- [ ] Token Stripe code en dur et previsible (AC2026UNLOCK) — Monetisation — voir rapport 2026-04-06

## Connu/accepte

- [ ] Pas d'onboarding ni explication du fonctionnement — Onboarding — voir rapport 2026-04-06
- [ ] Incohérence tutoiement/vouvoiement (tagline vs UI) — Copy — voir rapport 2026-04-06
- [ ] Labels Step 4 melange je/vous — Copy — voir rapport 2026-04-06
- [ ] Disclaimer trop petit (fontSize 10-11) — Copy/UX — voir rapport 2026-04-06
- [ ] Message d'erreur de calcul generique — Copy — voir rapport 2026-04-06
- [ ] CMG en doublon (calculee ET suggeree) — Features — voir rapport 2026-04-06
- [ ] Faute "je saisie" dans courrier CRA — Copy — voir rapport 2026-04-06

---

*Session precedente : 2026-04-02*

## Historique — A revoir (2026-04-02)

- [x] Corriger la navigation vers /letter (route inexistante) — UX — TRAITE (route /letter implementee)
- [x] Ajouter la validation des champs avant changement d'etape — UX — TRAITE (validation implementee)
- [x] Remplacer la selection manuelle de zone par un champ code postal — UX — TRAITE (detection auto par CP)
- [ ] Unifier les baremes entre moteur local Dart et Edge Function TS — Features/Coherence — voir rapport 2026-04-02
- [ ] Migrer vers go_router + Riverpod ou retirer les dependances inutilisees — Coherence — voir rapport 2026-04-02
- [ ] Harmoniser le ton (tutoiement -> vouvoiement partout) — Copy — voir rapport 2026-04-02
- [ ] Augmenter la taille et la visibilite des disclaimers — Copy/UX — voir rapport 2026-04-02
- [ ] Mettre a jour le scaffold Next.js (metadata, lang, landing page minimale) — Features — voir rapport 2026-04-02

## Historique — Discutable (2026-04-02)

- [ ] Revoir le pricing (rapport PDF vs lettre au meme prix) — Monetisation
- [ ] Ajouter un apercu floute du courrier avant paiement — Monetisation/UX
- [x] Rendre l'etape 4 (montants percus) optionnelle — UX/Features — TRAITE (validation accepte tout decoché)
- [x] Sauvegarder la situation en cours dans SharedPreferences — Features — TRAITE (historique derniere simulation)
- [x] Aligner le calcul AAH de l'Edge Function sur la deconjugalisation — Features — TRAITE (moteur local deconjugalise)
