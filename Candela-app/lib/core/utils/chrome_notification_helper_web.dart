import 'package:flutter/foundation.dart';
import 'dart:js_interop' as js;
import 'dart:js_interop_unsafe' as js_unsafe;

/// Helper class to trigger Chrome Web Notifications directly from Flutter Web
class ChromeNotificationHelper {
  static void requestPermission() {
    if (!kIsWeb) return;
    try {
      final window = js.globalContext;
      if (window.has('Notification')) {
        final notificationObj = window.getProperty('Notification'.toJS) as js.JSObject?;
        if (notificationObj != null && notificationObj.has('requestPermission')) {
          notificationObj.callMethod('requestPermission'.toJS);
        }
      }
    } catch (_) {}
  }

  static void showNotification(String title, String body) {
    if (!kIsWeb) return;
    try {
      final window = js.globalContext;
      if (window.has('Notification')) {
        final notificationClass = window.getProperty('Notification'.toJS) as js.JSFunction?;
        final options = js.JSObject();
        options.setProperty('body'.toJS, body.toJS);
        options.setProperty('dir'.toJS, 'rtl'.toJS);

        if (notificationClass != null) {
          notificationClass.callAsConstructor<js.JSObject>(title.toJS, options);
        }
      }
    } catch (_) {}
  }
}
