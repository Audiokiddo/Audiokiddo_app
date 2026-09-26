import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Saves [content] through the browser's download mechanism.
void downloadTextFile(String fileName, String content) {
  final blob = web.Blob([content.toJS].toJS, web.BlobPropertyBag(type: 'application/json'));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName;
  web.document.body!.append(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}
