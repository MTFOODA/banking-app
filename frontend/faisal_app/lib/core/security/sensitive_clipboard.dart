import 'dart:async';

import 'package:flutter/services.dart';

/// Never overwrite clipboard content placed there by another action or app.
class SensitiveClipboard {
  static Timer? _timer;
  static Future<void> copy(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 60), () async {
      try {
        if ((await Clipboard.getData('text/plain'))?.text == value) {
          await Clipboard.setData(const ClipboardData(text: ''));
        }
      } catch (_) {
        /* Clipboard access is platform-dependent. */
      }
    });
  }
}
