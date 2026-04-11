import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/situation.dart';
import '../utils/web_payment_bridge.dart';

/// Gestion du paywall — Stripe Payment Link + localStorage unlock par simulation
class PaymentService {
  static const _situationKey = 'ac_saved_situation';
  static const _justUnlockedKey = 'ac_just_unlocked';
  static const _lastSimulationKey = 'ac_last_simulation';
  static const _lastSimulationTsKey = 'ac_last_simulation_ts';
  static const _lastSimulationSimIdKey = 'ac_last_simulation_sim_id';
  static const _unlockedSimKey = 'ac_unlocked_sim'; // simId de la simulation débloquée
  static const _pendingSimKey = 'ac_pending_sim';   // simId en attente (avant redirect Stripe)
  static const _validToken = 'AC2026UNLOCK';

  // TODO (MANUAL): Créer un nouveau Payment Link Stripe à 0,99€ et remplacer l'URL.
  // Configurer success_url : https://alloccheck.flowforges.fr?paid=AC2026UNLOCK
  static const _stripePaymentLink = 'https://buy.stripe.com/6oU3cu4YK4b5etBffu7EQ00';

  /// Vérifie si la simulation [simId] est débloquée.
  static Future<bool> isUnlockedForSim(String simId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_unlockedSimKey) == simId;
  }

  /// Vérifie si l'URL courante contient le token de retour Stripe.
  /// Retourne le simId débloqué, ou null si pas de paiement détecté.
  static Future<String?> checkUrlAndUnlock({String? urlToken}) async {
    final token = urlToken ?? Uri.base.queryParameters['paid'];
    if (token == _validToken) {
      final prefs = await SharedPreferences.getInstance();
      // Récupère le simId sauvegardé avant le redirect Stripe
      final simId = prefs.getString(_pendingSimKey) ??
          DateTime.now().millisecondsSinceEpoch.toString();
      await prefs.setString(_unlockedSimKey, simId);
      await prefs.remove(_pendingSimKey);
      await prefs.setBool(_justUnlockedKey, true);
      return simId;
    }
    return null;
  }

  /// Vérifie si l'accès vient d'être débloqué (à consommer une seule fois).
  static Future<bool> consumeJustUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    final isJust = prefs.getBool(_justUnlockedKey) ?? false;
    if (isJust) await prefs.remove(_justUnlockedKey);
    return isJust;
  }

  /// Sauvegarde la situation + le simId en localStorage puis ouvre Stripe Checkout.
  /// La situation et le simId sont restaurés automatiquement au retour dans l'app.
  static Future<void> saveSituationAndOpenStripe(
      Situation situation, String simId) async {
    final prefs = await SharedPreferences.getInstance();
    // Sauvegarder le simId avant de naviguer vers Stripe
    await prefs.setString(_pendingSimKey, simId);

    final jsonStr = jsonEncode(situation.toJsonFull());
    if (kIsWeb) {
      // Écriture synchrone directe + navigation même onglet via JS interop.
      webSaveSituationAndNavigate(
        'flutter.$_situationKey',
        jsonStr,
        _stripePaymentLink,
      );
    } else {
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

  static Future<void> clearSavedSituation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_situationKey);
  }

  // ── HISTORIQUE ───────────────────────────────────────────────────────────

  static Future<void> saveLastSimulation(
      Situation situation, String simId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _lastSimulationKey, jsonEncode(situation.toJsonFull()));
    await prefs.setInt(
        _lastSimulationTsKey, DateTime.now().millisecondsSinceEpoch);
    await prefs.setString(_lastSimulationSimIdKey, simId);
  }

  static Future<Situation?> getLastSimulation() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_lastSimulationKey);
    if (jsonStr == null) return null;
    return Situation.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
  }

  static Future<String?> getLastSimulationSimId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastSimulationSimIdKey);
  }

  static Future<DateTime?> getLastSimulationDate() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_lastSimulationTsKey);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }
}
