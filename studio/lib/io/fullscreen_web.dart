import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Browsers that can show a page fullscreen (Chrome, Android, iPad). iPhone Safari cannot: there
/// the page opens without the address bar once it is added to the home screen.
bool get fullscreenSupported => web.document.fullscreenEnabled;

bool get isFullscreen => web.document.fullscreenElement != null;

void toggleFullscreen() {
  if (isFullscreen) {
    web.document.exitFullscreen().toDart.then((_) {}, onError: (_) {});
  } else {
    web.document.documentElement?.requestFullscreen().toDart.then((_) {}, onError: (_) {});
  }
}

bool _armed = false;

void armFullscreenOnTap() {
  if (_armed || isFullscreen || !fullscreenSupported) return;
  _armed = true;
  web.document.addEventListener(
    'pointerup',
    ((web.Event _) {
      _armed = false;
      if (!isFullscreen) toggleFullscreen();
    }).toJS,
    web.AddEventListenerOptions(once: true, capture: true),
  );
}
