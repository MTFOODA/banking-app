import 'package:flutter/foundation.dart';

/// Environment configuration.
///
/// The base URL is resolved per platform because `localhost`/`127.0.0.1` inside
/// an Android emulator points at the emulator itself. On a physical phone,
/// reaching the host requires a LAN endpoint or an explicit USB port tunnel.
///
/// Development defaults use the persistent demo database matching admin/admin.txt.
/// The separate API on port 8000 is available through API_BASE_URL.
/// Defaults:
/// * Android emulator → `http://10.0.2.2:8011/api/v1`
/// * iOS simulator / desktop → `http://127.0.0.1:8011/api/v1`
/// * Web → `http://localhost:8011/api/v1`
///
/// On a physical device, pass the host machine's LAN address at build time
/// (and make sure the backend listens on `0.0.0.0`):
///   flutter run --dart-define=API_BASE_URL=https://your-api.example/api/v1
///
/// For an isolated backend over USB, `adb reverse tcp:8011 tcp:8011` allows
/// `--dart-define=API_BASE_URL=http://127.0.0.1:8011/api/v1` without Wi-Fi.
///
/// Plain HTTP is only permitted by the Android **debug/profile** manifests;
/// release builds should use an HTTPS endpoint.
class AppConfig {
  const AppConfig._();

  static const String _override = String.fromEnvironment('API_BASE_URL');

  /// Default base URLs are chosen per platform because `localhost` inside an
  /// Android emulator points at the emulator itself, not the host machine.
  static String get apiBaseUrl {
    if (kReleaseMode &&
        (_override.isEmpty || !Uri.parse(_override).isScheme('https'))) {
      throw StateError('Release builds require an HTTPS API_BASE_URL');
    }
    if (_override.isNotEmpty) {
      return _override;
    }
    if (kIsWeb) {
      return 'http://localhost:8011/api/v1';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8011/api/v1';
      default:
        return 'http://127.0.0.1:8011/api/v1';
    }
  }

  static const String appVersion = '1.1.0';
  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
  static const int pageSize = 20;
  static const bool isDemoBuild = true;
}
