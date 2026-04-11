import 'dart:js_interop';

/// Navigation synchrone vers une URL (même onglet) — Flutter Web uniquement.
@JS('window.location.assign')
external void _jsLocationAssign(String url);

/// Écriture synchrone en localStorage — Flutter Web uniquement.
@JS('window.localStorage.setItem')
external void _jsLocalStorageSetItem(String key, String value);

/// Sauvegarde une paire clé/valeur en localStorage puis navigue vers [url].
/// Retourne false si le localStorage est plein ou indisponible.
bool webSaveSituationAndNavigate(String key, String value, String url) {
  try {
    _jsLocalStorageSetItem(key, value);
    _jsLocationAssign(url);
    return true;
  } catch (_) {
    return false;
  }
}
