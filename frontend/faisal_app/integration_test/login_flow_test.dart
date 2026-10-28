import 'package:faisal_app/main.dart' as app;
import 'package:faisal_app/core/di/injector.dart';
import 'package:faisal_app/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:faisal_app/features/authentication/presentation/bloc/auth_event.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'security_flow_test.dart' as flow;

/// On-device smoke test for the real login flow.
///
/// Run against a reachable backend:
///
/// ```text
/// flutter test integration_test/login_flow_test.dart -d DEVICE \
///   --dart-define=API_BASE_URL=http://HOST:8000/api/v1
/// ```
Future<void> _waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 60),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  fail('Timed out waiting for $finder');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'demo account number signs in and reaches the authenticated shell',
    (tester) async {
      app.main();
      await _waitFor(tester, find.byWidgetPredicate(flow.isStartupPage));
      sl<AuthBloc>().add(const AuthLogoutRequested());
      await _waitFor(tester, find.text('Sign in'));
      await flow.openSignIn(tester);
      await _waitFor(tester, find.byType(TextFormField));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      expect(fields, findsNWidgets(2));
      await tester.enterText(fields.at(0), '5550000000101');
      await tester.enterText(fields.at(1), 'Youssef#2026');
      await tester.pump();

      await tester.tap(find.text('Sign in'));
      await _waitFor(tester, find.byType(NavigationBar));
      await tester.pumpAndSettle();

      expect(find.text('Welcome back'), findsNothing);
      expect(find.text('Accounts'), findsWidgets);
      expect(find.text('Cards'), findsWidgets);
      sl<AuthBloc>().add(const AuthLogoutRequested());
      await _waitFor(tester, find.text('Sign in'));
      await flow.openSignIn(tester);
      await tester.pumpAndSettle();
    },
  );
  testWidgets('native biometrics capability checks reach the platform plugin', (
    tester,
  ) async {
    final auth = LocalAuthentication();
    expect(await auth.isDeviceSupported(), isA<bool>());
    expect(await auth.getAvailableBiometrics(), isA<List<BiometricType>>());
  });
}
