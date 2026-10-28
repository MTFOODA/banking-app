import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:faisal_app/core/config/app_config.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);
  test(
    'default emulator API matches the persistent demo credentials database',
    () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(
        AppConfig.apiBaseUrl,
        kIsWeb ? 'http://localhost:8011/api/v1' : 'http://10.0.2.2:8011/api/v1',
      );
    },
  );
  test(
    'default desktop API matches the persistent demo credentials database',
    () {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      expect(
        AppConfig.apiBaseUrl,
        kIsWeb
            ? 'http://localhost:8011/api/v1'
            : 'http://127.0.0.1:8011/api/v1',
      );
    },
  );
}
