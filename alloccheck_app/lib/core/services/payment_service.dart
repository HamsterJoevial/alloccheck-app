import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/situation.dart';
import '../utils/web_payment_bridge.dart';

/// Gestion du paywall — Stripe Payment Link + localStorage unlock
class PaymentService {
  static const _unlockKey = 'ac_unlocked';
  static const _situationKey = 'ac_saved_situation';
  static const _justUnlockedKey = 'ac_just_unlocked';
  static const _lastSimulationKey = 'ac_last_simulation';
  static const _lastSimulationTsKey = 'ac_last_simulation_ts';
  static const _validToken = 'AC2026UNLOCK';

  // TODO: Remplacer par l'URL réelle du Payment Link Stripe.
  // Dans Stripe Dashboard, configurer le success_url :
  //   https://alloccheck.flowforges.fr?paid=AC2026UNLOCK
  static const _stripePaymentLink = 'https://buy.stripe.com/6oU3cu4YK4b5etBffu7EQ00';

  /// Code à communiquer à l'utilisateur pour restaurer l'accès sur un autre appareil.
  static String get accessCode => _validToken;

  static Future<bool> isUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_unlockKey) ?? false;
  }

  /// Vérifie si l'URL courante contient le token de retour Stripe.
  /// À appeler au démarrage de l'app. Retourne true si l'utilisateur vient de payer.
  /// [urlToken] : token pré-capturé dans main() avant l'initialisation Flutter.
  static Future<bool> checkUrlAndUnlock({String? urlToken}) async {
    final token = urlToken ?? Uri.base.queryParameters['paid'];
    if (token == _validToken) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_unlockKey, true);
      await prefs.setBool(_justUnlockedKey, true);
      return true;
    }
    return false;
  }

  /// Vérifie si l'accès vient d'être débloqué (à consommer une seule fois).
  static Future<bool> consumeJustUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    final isJust = prefs.getBool(_justUnlockedKey) ?? false;
    if (isJust) await prefs.remove(_justUnlockedKey);
    return isJust;
  }

  /// Déverrouille l'accès via saisie manuelle du code.
  static Future<bool> unlockWithCode(String code) async {
    if (code.trim().toUpperCase() == _validToken) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_unlockKey, true);
      return true;
    }
    return false;
  }

  /// Sauvegarde la situation en localStorage puis ouvre Stripe Checkout.
  /// La situation sera restaurée automatiquement au retour dans l'app.
  static Future<void> saveSituationAndOpenStripe(Situation situation) async {
    final jsonStr = jsonEncode(situation.toJsonFull());

    if (kIsWeb) {
      // Écriture synchrone directe + navigation même onglet via JS interop.
      // Clé préfixée 'flutter.' pour correspondre à shared_preferences_web.
      webSaveSituationAndNavigate(
        'flutter.$_situationKey',
        jsonStr,
        _stripePaymentLink,
      );
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_situationKey, jsonStr);
      await launchUrl(Uri.parse(_stripePaymentLink),
          mode: LaunchMode.externalApplication);
    }
  }

  /// Restaure la simulation sauvegardée avant le redirect Stripe.
  static Future<Situation?> getSavedSituation() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_situationKey);
    if (jsonStr == null) return null;
    return Situation.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
  }

  /// Diagnostic : vérifie si la clé existe dans les prefs (sans désérialiser).
  static Future<bool> hasSavedSituation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_situationKey);
  }

  static Future<void> clearSavedSituation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_situationKey);
  }

  // ── HISTORIQUE ───────────────────────────────────────────────────────────

  static Future<void> saveLastSimulation(Situation situation) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSimulationKey, jsonEncode(situation.toJsonFull()));
    await prefs.setInt(_lastSimulationTsKey, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<Situation?> getLastSimulation() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_lastSimulationKey);
    if (jsonStr == null) return null;
    return Situation.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
  }

  static Future<DateTime?> getLastSimulationDate() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_lastSimulationTsKey);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }
}
