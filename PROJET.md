# PROJET — AllocCheck

*Créé le : 2026-04-03 via /nouveau_auto*
*Pipeline : /nouveau_auto (IDEE-066, score 26/30)*

---

## Résumé

**Pitch** : Tu sais enfin ce que la CAF te doit vraiment. En 3 minutes, tu vérifies tes droits et tu contestes si ça colle pas.

**Objectif principal** : Donner à chaque allocataire CAF un outil pour calculer ses droits exacts, comparer avec ce qu'il perçoit, et contester automatiquement en cas d'écart.

**Périmètre MVP** :
- Formulaire de situation (revenus, foyer, logement, situation pro)
- Calcul des droits CAF via OpenFisca (RSA, APL, Prime d'activité, AF, AAH, CMG)
- Saisie du montant perçu → comparaison → écart affiché
- Génération courrier de contestation PDF (réclamation gracieuse + CRA)
- Dashboard "mes droits" avec historique

**Hors périmètre MVP** :
- Envoi LRE intégré (V2)
- Alertes push proactives (V2)
- Connexion directe API CAF (inexistante)
- Suivi dossier temps réel (V2)

---

## Architecture

### Stack

**App mobile (rétention + push)** :
- Flutter 3.x (iOS + Android)
- Supabase (auth, DB, storage, Edge Functions)
- RevenueCat (IAP abonnements)
- Claude API (reformulation droits en langage simple + génération courriers)

**Web app (acquisition SEO)** :
- Next.js 16 (App Router, SSR)
- Même Supabase backend
- Tailwind CSS
- Pages SEO : /simulateur-[aide], /contester-caf, /erreur-caf

**Moteur de calcul** :
- OpenFisca France (Python, open source AGPL)
- Déployé comme API REST sur Supabase Edge Functions ou serveur dédié
- Alternative : recoder les formules clés en Dart/TypeScript si OpenFisca trop lourd

**PDF** :
- pdf_service via Supabase Edge Function (génération courriers)

### Flux de données

```
Utilisateur → Formulaire situation
                    ↓
            OpenFisca API (calcul droits théoriques)
                    ↓
            Comparaison avec montant déclaré perçu
                    ↓
            Si écart > 0 → Claude API (rédaction courrier personnalisé)
                    ↓
            PDF généré → téléchargement / envoi email
                    ↓
            Supabase DB (historique droits, dossiers, courriers)
```

### Monétisation

| Offre | Prix | Déclencheur |
|-------|------|-------------|
| Simulation gratuite | 0€ | Acquisition |
| Rapport PDF détaillé | 4,99€ | Écart détecté |
| Lettre contestation | 4,99€ | Réclamation gracieuse ou CRA |
| Abonnement suivi | 3,99€/mois | Alertes + multi-dossiers |

Break-even : ~2 000 rapports/mois = 10k€ MRR
ARR Y2 cible : ~490k€

---

## Phases d'exécution

### Phase 1 — MVP Simulation + Comparaison (semaines 1-3)
**Objectif** : L'utilisateur peut calculer ses droits et voir l'écart.
**Livrables** :
- Formulaire multi-étapes (revenus, foyer, logement)
- Intégration OpenFisca (RSA, APL, Prime activité)
- Écran résultat : droits théoriques vs perçu
- Web app Next.js avec pages SEO
- App Flutter avec même fonctionnalité
**Critères de succès** : Calcul correct pour RSA/APL/Prime activité vérifié sur 10 cas tests

### Phase 2 — Contestation + PDF (semaines 3-4)
**Objectif** : Générer des courriers de contestation.
**Livrables** :
- Claude API intégrée pour rédaction courriers
- Templates légaux : réclamation gracieuse, saisine CRA
- Génération PDF avec en-tête, références légales
- Paiement IAP (RevenueCat) pour rapports + lettres
**Critères de succès** : Courrier généré juridiquement correct, vérifié sur 5 scénarios

### Phase 3 — Abonnement + Dashboard (semaines 4-5)
**Objectif** : Rétention via suivi continu.
**Livrables** :
- Dashboard "mes droits" (historique calculs)
- Abonnement mensuel via RevenueCat
- Multi-dossiers (pour aider sa famille)
- Notifications de recalcul (trimestriel CAF)
**Critères de succès** : Parcours abonnement fonctionnel iOS + Android + Web

### Phase 4 — SEO + Landing pages (semaine 5)
**Objectif** : Acquisition organique.
**Livrables** :
- Pages SEO : /simulateur-rsa, /simulateur-apl, /contester-decision-caf
- Blog : 5 articles (erreurs CAF fréquentes, comment contester, droits oubliés)
- Meta tags, sitemap, structured data
**Critères de succès** : Pages indexées Google, position <50 sur "erreur CAF"

---

## Règles de sécurité

### NE PAS faire
- Ne jamais stocker de données fiscales en clair (chiffrement AES-256)
- Ne jamais affirmer que le calcul est un "avis juridique" (disclaimer obligatoire)
- Ne jamais envoyer de courrier au nom de l'utilisateur sans son action explicite
- Ne jamais collecter de numéro allocataire CAF (pas nécessaire pour le calcul)
- Ne jamais se connecter à l'API CAF (n'existe pas publiquement)

### Données sensibles
- Revenus du foyer → chiffrés en DB, supprimables par l'utilisateur
- Composition familiale → même traitement
- Courriers générés → stockés chiffrés, supprimables

### Disclaimers obligatoires
- "AllocCheck est un outil d'aide à la compréhension de vos droits. Il ne constitue pas un conseil juridique."
- "Les calculs sont basés sur les barèmes publics et peuvent différer du calcul officiel de la CAF."
- "Les courriers générés sont des modèles à adapter à votre situation."

---

## Métriques de succès

| Métrique | Cible M3 | Cible M6 | Cible M12 |
|----------|----------|----------|-----------|
| Utilisateurs web (uniques/mois) | 5 000 | 20 000 | 50 000 |
| Téléchargements app | 1 000 | 5 000 | 15 000 |
| Rapports PDF vendus | 200/mois | 1 000/mois | 3 000/mois |
| Lettres contestation vendues | 100/mois | 500/mois | 1 500/mois |
| Abonnés mensuels | 50 | 300 | 1 500 |
| MRR | 1 500€ | 7 500€ | 25 000€ |
