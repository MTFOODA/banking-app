import 'package:faisal_app/main.dart' as app;
import 'package:faisal_app/core/di/injector.dart';
import 'package:faisal_app/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:faisal_app/features/authentication/presentation/bloc/auth_event.dart';
import 'package:faisal_app/features/settings/presentation/cubit/appearance_cubits.dart';
import 'package:faisal_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'security_flow_test.dart' as flow;

/// Uses an eligible, unenrolled fixture on an isolated development-OTP API.
/// Reads the displayed code without logging it, and leaves enrollment unfinished.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('development OTP panel, real resend and Arabic verification', (
    tester,
  ) async {
    app.main();
    await flow.waitFor(tester, find.byWidgetPredicate(flow.isStartupPage));
    await sl<LanguageCubit>().change('en');
    sl<AuthBloc>().add(const AuthLogoutRequested());
    await flow.waitFor(tester, find.text('Sign in'));
    await flow.openSignIn(tester);
    await flow.tap(tester, 'Register for digital banking');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '0000000000901');
    await flow.tap(tester, 'Continue');
    final panel = find.byKey(const ValueKey('development_otp_panel'));
    final code = find.byKey(const ValueKey('development_otp_code'));
    await flow.waitFor(tester, code);
    await tester.ensureVisible(panel);
    await tester.pumpAndSettle();
    final original = tester.widget<SelectableText>(code).data!;
    expect(RegExp(r'^\d{6}$').hasMatch(original), isTrue);
    expect(find.ancestor(of: panel, matching: find.byType(Form)), findsNothing);
    // Keep the configured cooldown intact; no fixture or server override.
    final resend = find.byWidgetPredicate(
      (w) =>
          w is TextButton &&
          w.child is Text &&
          (w.child as Text).data == 'Request another code' &&
          w.onPressed != null,
    );
    for (var i = 0; i < 280 && resend.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(resend, findsOneWidget);
    await flow.tap(tester, 'Request another code');
    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      if (tester.widget<SelectableText>(code).data != original) break;
    }
    final replacement = tester.widget<SelectableText>(code).data!;
    expect(replacement != original, isTrue);
    await sl<LanguageCubit>().change('ar');
    await tester.pumpAndSettle();
    final l = AppLocalizations.of(tester.element(panel));
    expect(Directionality.of(tester.element(panel)), TextDirection.rtl);
    await tester.ensureVisible(find.byType(TextFormField).first);
    await tester.enterText(find.byType(TextFormField).first, replacement);
    await flow.tap(tester, l.verifyCode);
    await flow.waitFor(
      tester,
      find.byKey(const ValueKey('registration_username')),
    );
    expect(find.byKey(const ValueKey('development_otp_panel')), findsNothing);
    await tester.tap(
      find.byTooltip(
        MaterialLocalizations.of(
          tester.element(find.byKey(const ValueKey('registration_username'))),
        ).backButtonTooltip,
      ),
    );
    await sl<LanguageCubit>().change('en');
    await tester.pumpAndSettle();
  }, timeout: const Timeout(Duration(minutes: 4)));
}
