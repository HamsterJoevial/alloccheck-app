import 'dart:convert';
import 'dart:js_interop';

@JS('document.createElement')
external JSObject _jsCreateElement(String tag);

extension _JSDownloadAnchor on JSObject {
  external set href(String value);
  external set download(String value);
  external void click();
}

/// Télécharge un PDF via un lien `<a>` créé dynamiquement (web uniquement).
void downloadPdfWeb(List<int> bytes, String filename) {
  final base64Str = base64Encode(bytes);
  final dataUrl = 'data:application/pdf;base64,$base64Str';
  final anchor = _jsCreateElement('a');
  anchor.href = dataUrl;
  anchor.download = filename;
  anchor.click();
}
