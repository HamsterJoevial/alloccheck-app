import 'dart:js_interop';

/// Navigation synchrone vers une URL (même onglet) — Flutter Web uniquement.
@JS('window.location.assign')
external void _jsLocationAssign(String url);

/// Écriture synchrone en localStorage — Flutter Web uniquement.
@JS('window.localStorage.setItem')
external void _jsLocalStorageSetItem(String key, String value);

/// Sauvegarde une paire clé/valeur en localStorage puis navigue vers [url].
void webSaveSituationAndNavigate(String key, String value, String url) {
  _jsLocalStorageSetItem(key, value);
  _jsLocationAssign(url);
}
