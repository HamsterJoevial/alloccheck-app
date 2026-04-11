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
- [ ] QA-003 — Enum `CongeParental` sérialisé par `.index` → corruption silencieuse des brouillons (P0) — voir rapport 2026-04-11

### P1 — Importants

- [ ] QA-004 — `fromJson()` sans `orElse` → crash sur données périmées (P1) — voir rapport 2026-04-11
- [ ] QA-005 — PDF mobile = stub non fonctionnel, feature payante cassée (P1) — voir rapport 2026-04-11
- [ ] QA-006 — `_clearDraft()` non awaité → race condition soumission (P1) — voir rapport 2026-04-11
- [ ] QA-007 — Race condition `_calculate()` + `_loadUnlockStatus()` dans initState (P1) — voir rapport 2026-04-11
- [ ] QA-008 — `jsonDecode` sans try/catch dans PaymentService → crash localStorage corrompu (P1) — voir rapport 2026-04-11
- [ ] QA-009 — Brouillon non affiché si `nombreEnfants == 0` (P1) — voir rapport 2026-04-11
- [ ] QA-010 — Zéro tests sur PaymentService (P1) — voir rapport 2026-04-11
- [ ] QA-011 — `localizationsDelegates` absent → TalkBack en anglais (P1) — voir rapport 2026-04-11

### P2 — Améliorations

- [ ] QA-012 — Accents manquants dans les PDF (9+ occurrences) (P2) — voir rapport 2026-04-11
- [ ] QA-013 — `CalculService` dead code (~300 lignes) + 3 unused_field warnings (P2) — voir rapport 2026-04-11
- [ ] QA-014 — ARS affichée en équivalent mensuel (÷12) — doit être annuel + mention août (P2) — voir rapport 2026-04-11
- [ ] QA-015 — `textSecondary` contraste 4.48:1 (sous seuil WCAG AA 4.5:1) (P2) — voir rapport 2026-04-11
- [ ] QA-016 — `AppTheme.warning` contraste 2.9:1 sur blanc — illisible (P2) — voir rapport 2026-04-11
- [ ] QA-017 — Widget `Radio` déprécié depuis Flutter 3.32 (4 warnings) (P2) — voir rapport 2026-04-11
- [ ] QA-018 — `flutter_web_plugins` non déclaré en dépendance pubspec.yaml (P2) — voir rapport 2026-04-11
- [ ] QA-019 — Pas de loader visible pendant `_calculate()` → flash écran blanc (P2) — voir rapport 2026-04-11
- [ ] QA-020 — Pas de bouton "Modifier ma situation" depuis ResultsScreen (P2) — voir rapport 2026-04-11
- [ ] QA-021 — `webSaveSituationAndNavigate` peut échouer silencieusement (localStorage plein) (P2) — voir rapport 2026-04-11
- [ ] QA-022 — `_pendingSimKey` jamais nettoyé si paiement abandonné (P2) — voir rapport 2026-04-11

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

