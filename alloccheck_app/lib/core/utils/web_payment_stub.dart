/// Stub pour les plateformes non-web (iOS/Android).
bool webSaveSituationAndNavigate(String key, String value, String url) {
  // Non supporté hors web — le code appelant utilise SharedPreferences + url_launcher.
  return true;
}
