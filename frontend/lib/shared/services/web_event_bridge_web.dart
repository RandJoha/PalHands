// Web implementation using dart:html
import 'dart:html' as html;

class WebEventBridge {
  html.EventListener? _storageListener;
  html.EventListener? _messageListener;

  void init(void Function() onEmailUpdated) {
    _storageListener = (event) {
      if (event is html.StorageEvent) {
        if (event.key == 'palhands:event' && event.newValue != null) {
          try {
            final data = html.window.localStorage['palhands:event'];
            if (data != null && data.contains('email:updated')) {
              onEmailUpdated();
              // Clear the event to avoid re-trigger loops
              html.window.localStorage.remove('palhands:event');
            }
          } catch (_) {
            onEmailUpdated();
          }
        }
      }
    };
    _messageListener = (event) {
      if (event is html.MessageEvent) {
        try {
          final data = event.data;
          if (data is Map && data['source'] == 'palhands' && data['type'] == 'email:updated') {
            onEmailUpdated();
          }
        } catch (_) {}
      }
    };
    html.window.addEventListener('storage', _storageListener);
    html.window.addEventListener('message', _messageListener);
    // Fallback: if same-tab redirect occurred and no message event is delivered, check once on load
    try {
      final data = html.window.localStorage['palhands:event'];
      if (data != null && data.contains('email:updated')) {
        onEmailUpdated();
        html.window.localStorage.remove('palhands:event');
      }
    } catch (_) {}
  }

  void dispose() {
    if (_storageListener != null) {
      html.window.removeEventListener('storage', _storageListener);
      _storageListener = null;
    }
    if (_messageListener != null) {
      html.window.removeEventListener('message', _messageListener);
      _messageListener = null;
    }
  }
}
