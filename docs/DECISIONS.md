# Décisions — AllocCheck

## 2026-04-03 — Stack hybride Web + Mobile
Question : Faut-il une app mobile, un site web, ou les deux ?
Décision : Les deux — Next.js pour le SEO + Flutter pour la rétention
Raison : Web capte le trafic SEO ("erreur CAF", "contester CAF"), mobile permet push notifications et alertes récurrentes
Alternative écartée : Mobile seul (perd le SEO) ou Web seul (perd la rétention push)

## 2026-04-03 — OpenFisca comme moteur de calcul
Question : Recoder les formules CAF en Dart/TS ou utiliser OpenFisca ?
Décision : OpenFisca d'abord (API REST), recoder si trop lourd
Raison : OpenFisca est le moteur officiel utilisé par l'État, crédibilité maximale. AGPL = obligation de publier les modifications
Alternative écartée : Recoder from scratch — risque d'erreurs de calcul, maintenance des barèmes annuels

## 2026-04-03 — Pas de connexion API CAF
Question : Se connecter à l'API CAF pour récupérer les montants perçus ?
Décision : Non — l'utilisateur saisit manuellement ce qu'il perçoit
Raison : Pas d'API publique CAF. La connexion France Connect nécessiterait un agrément. MVP = saisie manuelle
Alternative écartée : Scraping CAF Mon Compte — illégal et fragile
