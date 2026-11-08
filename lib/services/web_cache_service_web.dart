import 'dart:js_interop';

@JS('window.resetLibreTracWebCache')
external JSPromise? _jsResetWebCache();

Future<void> purgeWebCacheAndReload() async {
  try {
    final promise = _jsResetWebCache();
    if (promise != null) {
      await promise.toDart;
    }
  } catch (_) {
    // If helper not loaded, fall through
  }
}

