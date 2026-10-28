import 'package:flutter/material.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:faisal_app/main.dart' as app;
import 'package:faisal_app/core/config/app_config.dart';
import 'package:faisal_app/core/di/injector.dart';
import 'package:faisal_app/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:faisal_app/features/authentication/presentation/bloc/auth_event.dart';
import 'package:faisal_app/features/products/presentation/pages/bank_notices_page.dart';
import 'package:faisal_app/features/admin/presentation/pages/admin_dashboard_page.dart';

/// Opt-in real API test in an isolated headless browser profile. Private test
/// defines are supplied only to this test entry point, never the app build.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'real web admin login, protected dashboard and fresh registration OTP',
    (tester) async {
      // Track the text-input client in profile mode; the framework's debug-only
      // client -1 shortcut is unavailable here. Authentication remains real.
      binding.testTextInput.register();
      addTearDown(binding.testTextInput.unregister);
      expect(AppConfig.apiBaseUrl.contains(':8011/'), isTrue);
      const password = String.fromEnvironment('QA_ADMIN_PASSWORD');
      const card = String.fromEnvironment('QA_REGISTRATION_CARD');
      expect(password.isNotEmpty && card.isNotEmpty, isTrue);
      var phase = 'startup';
      void mark(String value) {
        phase = value;
        binding.reportData = {'phase': value};
        debugPrint('WEB_QA: $value');
      }

      Future<void> until(Finder finder) async {
        for (var i = 0; i < 400; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)),
          );
          await tester.pump(const Duration(milliseconds: 100));
          if (finder.evaluate().isNotEmpty) return;
        }
        binding.reportData = {
          'phase': phase,
          'authStatus': sl<AuthBloc>().state.status.name,
          'errorCode': sl<AuthBloc>().state.errorCode?.name,
        };
        if (phase == 'wait for admin dashboard') {
          await binding.takeScreenshot('03_web_login_failure');
        }
        fail('Expected real web screen did not appear: $phase');
      }

      Future<void> tap(Finder finder) async {
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)),
        );
        await tester.pump();
      }

      Future<void> loginCard() async {
        await until(find.byType(BankNoticesPage));
        await tap(find.byKey(const ValueKey('notice_continue_login')));
        await until(find.byType(TextFormField));
      }

      app.main();
      await until(find.byType(BankNoticesPage));
      await tester.pumpAndSettle();
      await binding.takeScreenshot('01_web_public_portal');
      mark('open first sign-in');
      await loginCard();
      mark('enter admin credentials');
      await tester.enterText(find.byType(TextFormField).first, 'devadmin');
      await tester.enterText(find.byType(TextFormField).at(1), password);
      expect(
        tester
                .widget<TextFormField>(find.byType(TextFormField).first)
                .controller!
                .text ==
            'devadmin',
        isTrue,
        reason: 'Username input not delivered',
      );
      expect(
        tester
                .widget<TextFormField>(find.byType(TextFormField).at(1))
                .controller!
                .text ==
            password,
        isTrue,
        reason: 'Password input not delivered',
      );
      await tap(
        find
            .ancestor(
              of: find.text('Sign in').last,
              matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
            )
            .last,
      );
      mark('wait for admin dashboard');
      await until(find.byType(AdminDashboardPage));
      await until(find.text('Pending requests'));
      await binding.takeScreenshot('02_web_admin_dashboard');
      expect(sl<AuthBloc>().state.isStaff, isTrue);
      expect(sl<AuthBloc>().state.can('admin.dashboard.view'), isTrue);
      expect(find.text('Administration portal'), findsOneWidget);
      mark('logout admin');
      sl<AuthBloc>().add(const AuthLogoutRequested());
      await loginCard();
      mark('open registration');
      await until(find.text('Register for digital banking'));
      await tap(find.text('Register for digital banking'));
      await until(find.byType(TextFormField));
      await tester.enterText(find.byType(TextFormField).first, card);
      await tap(find.text('Continue').last);
      mark('wait for development OTP');
      await until(find.byKey(const ValueKey('development_otp_code')));
      final code = tester
          .widget<SelectableText>(
            find.byKey(const ValueKey('development_otp_code')),
          )
          .data!;
      expect(RegExp(r'^\d{6}$').hasMatch(code), isTrue);
      expect(tester.takeException(), isNull);
      mark('admin dashboard and fresh registration OTP passed');
      // Stop before verification/completion: this customer stays unenrolled.
      await tester.pumpWidget(const SizedBox());
    },
    skip: !const bool.fromEnvironment('WEB_LIVE_QA'),
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
