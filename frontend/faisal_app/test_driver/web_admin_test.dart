import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  await integrationDriver(
    onScreenshot:
        (String name, List<int> bytes, [Map<String, Object?>? args]) async {
          if (!RegExp(r'^[0-9]{2}_web_[a-z_]+$').hasMatch(name)) return false;
          final directory = Directory('../../screenshots/admin_web/2026-10-27');
          await directory.create(recursive: true);
          await File('${directory.path}/$name.png').writeAsBytes(bytes);
          return true;
        },
  );
}
