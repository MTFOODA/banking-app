import 'dart:io';

import 'package:faisal_app/main.dart' as app;
import 'package:faisal_app/core/di/injector.dart';
import 'package:faisal_app/core/security/biometric_service.dart';
import 'package:faisal_app/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:faisal_app/features/authentication/presentation/bloc/auth_event.dart';
import 'package:faisal_app/features/settings/presentation/cubit/appearance_cubits.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'security_flow_test.dart' as flow;

/// Interactive hardware QA. Requires an enrolled fingerprint and a person at
/// the phone. No biometric platform response is mocked or injected.
/// Pass --dart-define=DEVICE_BIOMETRIC_TEST=true to opt in.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'real fingerprint, protected storage, background lock and API outage recovery',
    (tester) async {
      app.main();
      await flow.waitFor(tester, find.byWidgetPredicate(flow.isStartupPage));
      await sl<LanguageCubit>().change('en');
      await tester.pumpAndSettle();
      // A preceding interrupted first-login test can leave a setup-only grant.
      // Use the normal logout path for either kind of saved session.
      sl<AuthBloc>().add(const AuthLogoutRequested());
      await flow.waitFor(tester, find.text('Sign in'));
      await flow.openSignIn(tester);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), '5550000000101');
      await tester.enterText(find.byType(TextFormField).at(1), 'Youssef#2026');
      await flow.tap(tester, 'Sign in');
      await flow.waitFor(tester, find.byType(NavigationBar));
      final service = sl<BiometricService>();
      expect(
        await service.available(),
        isTrue,
        reason: 'This interactive test requires enrolled device biometrics.',
      );
      await flow.tap(tester, 'More');
      await flow.tap(tester, 'Profile');
      await flow.waitFor(tester, find.byType(SwitchListTile));
      if (service.enabled) {
        // An interrupted earlier hardware run can leave the local preference on.
        // Reset it using the actual password-authorized disable flow.
        await tester.tap(find.byType(SwitchListTile));
        await flow.waitFor(tester, find.text('Current password'));
        await tester.enterText(find.byType(TextFormField).last, 'Youssef#2026');
        await flow.tap(tester, 'Authorize operation');
        await flow.waitFor(tester, find.text('Copy Token'));
        await flow.tap(tester, 'Continue');
        for (var i = 0; i < 120 && service.enabled; i++) {
          await tester.pump(const Duration(milliseconds: 250));
        }
        expect(service.enabled, isFalse);
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byType(SwitchListTile));
      await flow.waitFor(tester, find.text('Current password'));
      await tester.enterText(find.byType(TextFormField).last, 'Youssef#2026');
      await flow.tap(tester, 'Authorize operation');
      await flow.waitFor(tester, find.text('Copy Token'));
      // No token is printed, recorded or copied for biometric configuration.
      debugPrint('DEVICE_QA: fingerprint prompts for enablement are starting.');
      await flow.tap(tester, 'Continue');
      for (var i = 0; i < 960 && !service.enabled; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      expect(
        service.enabled,
        isTrue,
        reason:
            'Native authentication and protected marker write must succeed.',
      );
      await tester.pumpAndSettle();

      // The host backgrounds and restores the actual Android activity after
      // this marker. Wait for the production lifecycle overlay to appear.
      debugPrint('DEVICE_QA: ready for actual background/resume.');
      for (var i = 0; i < 960; i++) {
        await tester.pump(const Duration(milliseconds: 250));
        if (find.text('Unlock with biometrics').evaluate().isNotEmpty) break;
      }
      expect(find.text('Unlock with biometrics'), findsOneWidget);
      debugPrint('DEVICE_QA: fingerprint prompts for re-entry are starting.');
      await flow.tap(tester, 'Unlock with biometrics');
      final lockMessage = find.text(
        'Your session is locked. Unlock or sign out to use a password.',
      );
      for (var i = 0; i < 960; i++) {
        await tester.pump(const Duration(milliseconds: 250));
        if (lockMessage.evaluate().isEmpty) break;
      }
      expect(
        lockMessage,
        findsNothing,
        reason: 'Native biometric read and backend session validation must succeed.',
      );
      await flow.waitFor(tester, find.byType(SwitchListTile));
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isTrue,
      );
      await tester.tap(find.byType(SwitchListTile));
      await flow.waitFor(tester, find.text('Current password'));
      await tester.enterText(find.byType(TextFormField).last, 'Youssef#2026');
      await flow.tap(tester, 'Authorize operation');
      await flow.waitFor(tester, find.text('Copy Token'));
      await flow.tap(tester, 'Continue');
      for (var i = 0; i < 120 && service.enabled; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      expect(service.enabled, isFalse);
      await tester.pumpAndSettle();
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isFalse,
      );

      await tester.pageBack();
      await tester.pumpAndSettle();
      final endpoint = Uri.parse(const String.fromEnvironment('API_BASE_URL'));
      Future<bool> reachable() async {
        final client = HttpClient()
          ..connectionTimeout = const Duration(seconds: 2);
        try {
          final request = await client
              .getUrl(endpoint.replace(path: '/health'))
              .timeout(const Duration(seconds: 2));
          final response = await request.close().timeout(
            const Duration(seconds: 2),
          );
          await response.drain<void>();
          return response.statusCode == 200;
        } catch (_) {
          return false;
        } finally {
          client.close(force: true);
        }
      }

      debugPrint('DEVICE_QA: ready to stop QA API.');
      var connected = true;
      for (var i = 0; i < 240 && connected; i++) {
        connected = await tester.runAsync(reachable) ?? false;
        await tester.pump(const Duration(milliseconds: 250));
      }
      expect(
        connected,
        isFalse,
        reason:
            'Host must stop the isolated QA API, closing keep-alive streams.',
      );
      await flow.tap(tester, 'Profile');
      await flow.waitFor(tester, find.text('Try again'));
      expect(find.text('Youssef Kamal'), findsNothing);
      debugPrint('DEVICE_QA: profile failure displayed; restart QA API.');
      for (var i = 0; i < 240 && !connected; i++) {
        connected = await tester.runAsync(reachable) ?? false;
        await tester.pump(const Duration(milliseconds: 250));
      }
      expect(
        connected,
        isTrue,
        reason: 'Host must restart the same isolated QA API.',
      );
      await flow.tap(tester, 'Try again');
      await flow.waitFor(tester, find.text('Youssef Kamal'));
      sl<AuthBloc>().add(const AuthLogoutRequested());
      await flow.waitFor(tester, find.text('Sign in'));
      await flow.openSignIn(tester);
      await tester.pumpAndSettle();
    },
    skip: !const bool.fromEnvironment('DEVICE_BIOMETRIC_TEST'),
    timeout: const Timeout(Duration(minutes: 12)),
  );
}
