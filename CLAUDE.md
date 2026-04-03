# AllocCheck — Règles du projet

## Contexte

AllocCheck est une app de vérification et contestation des droits CAF.
L'utilisateur entre sa situation → calcul des droits exacts via OpenFisca → comparaison avec ce qu'il perçoit → contestation automatique si écart.

**Stack** : Flutter (mobile) + Next.js (web SEO) + Supabase (backend) + OpenFisca (calcul) + Claude API (rédaction) + RevenueCat (IAP)

**Chemin projet** : `~/ClaudeAssistantBuilder/CLAUDE_ASSISTANT_BUILDER/projets/AllocCheck/`

## Structure

```
AllocCheck/
├── alloccheck_app/          # App Flutter (iOS + Android)
├── alloccheck_web/          # Web app Next.js (SEO + simulateur)
├── supabase/                # Backend Supabase (migrations, edge functions)
│   ├── migrations/
│   ├── functions/
│   │   ├── calculate-rights/ # OpenFisca integration
│   │   ├── generate-pdf/     # Génération courriers PDF
│   │   └── generate-letter/  # Claude API → rédaction courrier
├── docs/                    # Documentation, rapports d'audit
├── scripts/                 # Scripts utilitaires
└── screenshots/             # Captures pour stores
```

## Règles techniques

### OpenFisca
- Moteur de calcul open source (licence AGPL) — les modifications doivent être publiées
- Déployé comme Edge Function Supabase ou microservice Python
- Couvre : RSA, APL, Prime d'activité, Allocations familiales, AAH, CMG
- Barèmes publics : Service-Public.fr, cafdata.fr
- Mise à jour annuelle des barèmes (avril + janvier)

### Sécurité données
- Chiffrement AES-256 pour revenus et composition familiale en DB
- Aucun stockage de numéro allocataire CAF
- Suppression des données sur demande (RGPD Art. 17)
- Disclaimer obligatoire : pas un conseil juridique

### Courriers de contestation
- Templates + autocomplétion — l'utilisateur signe (pas d'exercice illégal du droit)
- Deux niveaux : réclamation gracieuse (1er recours) + saisine CRA (2e recours)
- Références légales automatiques (Code de la Sécurité Sociale)
- PDF généré avec en-tête, date, références

### Monétisation
- RevenueCat pour iOS + Android (abonnement + one-shot)
- Stripe pour web (paiement unique rapport/lettre)
- Freemium : simulation gratuite, rapport + lettre payants

## Conventions

- Langue du code : anglais (variables, fonctions, classes)
- Langue UI : français
- Commits : français, format conventionnel (`feat:`, `fix:`, `docs:`)
- Tests : 1 test minimum par feature critique (calcul droits, génération PDF)

## Site FlowForges

Les modifications du site peuvent se faire depuis n'importe quel projet. Les fichiers sont toujours à :
`~/ClaudeAssistantBuilder/CLAUDE_ASSISTANT_BUILDER/projets/FlowForgesSite/site/`

**État AllocCheck sur le site** :
- Homepage : non listé
- Landing dédiée : non
- Description visible sur le site : non — sera ajoutée uniquement lors de la soumission App Store

Après chaque modification du site : mettre à jour `APPS_REGISTRY.md` + pousser depuis `FlowForgesSite/site/`.
