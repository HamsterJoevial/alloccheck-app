# QA — Backlog des corrections
*Dernière mise à jour : 2026-04-11*
*Rapport complet session 2 : docs/QA_REPORT_2026-04-11.md*
*Rapport complet session 1 : docs/QA_REPORT_2026-04-06.md*

---
*Session 2 — 2026-04-11*

## À corriger

### P0 — Bloquants

- [ ] QA-001 — Token `AC2026UNLOCK` hardcodé dans le bundle JS (P0) — **session dédiée backend** — voir rapport 2026-04-11
- [ ] QA-002 — Paywall 100% client-side bypassable via console (P0) — **session dédiée backend** (lié à QA-001) — voir rapport 2026-04-11
- [x] QA-003 — Enum draft sérialisé par `.name` (v3), `_applyDraft` avec `firstWhere+orElse` — corrigé 2026-04-11

### P1 — Importants

- [x] QA-004 — `orElse` ajouté sur tous les `firstWhere` d'enum dans `Situation.fromJson` — corrigé 2026-04-11
- [x] QA-005 — PDF mobile : `Printing.sharePdf` au lieu du stub — corrigé 2026-04-11
- [x] QA-006 — `await _clearDraft()` + `_submitSimulation` async — corrigé 2026-04-11
- [x] QA-007 — `_initScreen` séquence `await _calculate()` puis `await _loadUnlockStatus()` — corrigé 2026-04-11
- [x] QA-008 — `try/catch` sur `jsonDecode` dans `PaymentService` (getSaved + getLast) — corrigé 2026-04-11
- [x] QA-009 — Brouillon affiché pour toutes les situations (filtre `nombreEnfants == 0` supprimé) — corrigé 2026-04-11
- [x] QA-010 — Zéro tests sur PaymentService (P1) — corrigé 2026-04-11
- [x] QA-011 — `localizationsDelegates` + `supportedLocales` ajoutés dans MaterialApp — corrigé 2026-04-11

### P2 — Améliorations

- [x] QA-012 — Accents manquants dans les PDF (9+ occurrences) (P2) — corrigé 2026-04-11
- [x] QA-013 — `CalculService` dead code (~300 lignes) + 3 unused_field warnings (P2) — corrigé 2026-04-11
- [x] QA-014 — ARS affichée en équivalent mensuel (÷12) — doit être annuel + mention août (P2) — corrigé 2026-04-11
- [x] QA-015 — `textSecondary` #475569 (5.9:1) — corrigé 2026-04-11
- [x] QA-016 — `AppTheme.warning` #B45309 (4.9:1) — corrigé 2026-04-11
- [x] QA-017 — Widget `Radio` déprécié depuis Flutter 3.32 (4 warnings) (P2) — corrigé 2026-04-11
- [x] QA-018 — `flutter_localizations` + `flutter_web_plugins` ajoutés en dépendances — corrigé 2026-04-11
- [x] QA-019 — Pas de loader visible pendant `_calculate()` → flash écran blanc (P2) — corrigé 2026-04-11
- [x] QA-020 — Pas de bouton "Modifier ma situation" depuis ResultsScreen (P2) — corrigé 2026-04-11
- [x] QA-021 — `webSaveSituationAndNavigate` peut échouer silencieusement (localStorage plein) (P2) — corrigé 2026-04-11
- [x] QA-022 — `_pendingSimKey` nettoyé au démarrage si aucun token Stripe détecté — corrigé 2026-04-11

### P3 — Suggestions

- [ ] QA-023 — Widgets statiques non `const` dans ResultsScreen (P3) — voir rapport 2026-04-11
- [ ] QA-024 — Pas de bouton "Partager" le PDF via `share_plus` (P3) — voir rapport 2026-04-11
- [ ] QA-025 — Pas d'explication "Qu'est-ce que la CAF ?" pour nouveaux utilisateurs SEO (P3) — voir rapport 2026-04-11
- [ ] QA-026 — Aucun test d'intégration flow simulation → résultats (P3) — voir rapport 2026-04-11

---
*Session 1 — 2026-04-06 (issues non encore traitées)*

## Connus / Dettes acceptees

- [~] QA-006 -- simulation_screen.dart trop long -- refactor non urgent pour MVP
- [~] QA-009 -- Pas de confirmation avant soumission -- choix UX delibere
- [~] QA-016 -- Duplication code PDF -- refactor non urgent
- [~] QA-017 -- Pas de bouton "Modifier" depuis resultats -- suggestion backlog
- [~] QA-018 -- Aucun test MVA/ASF/pension -- tests a ajouter plus tard
- [~] QA-019 -- Melange tutoiement/vouvoiement -- coherence tonale mineure
- [~] QA-020 -- "il y a 0 min" -- edge case mineur
- [~] QA-021 -- Garde alternee non accessible divorces -- a revoir
- [~] QA-022 -- Strings hardcodees (pas d'i18n) -- pas necessaire MVP France

## En cours


## Traites

