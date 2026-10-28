import 'dart:convert';
import 'dart:io';

import 'package:faisal_app/main.dart' as app;
import 'package:faisal_app/core/di/injector.dart';
import 'package:faisal_app/features/admin/presentation/pages/admin_dashboard_page.dart';
import 'package:faisal_app/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:faisal_app/features/authentication/presentation/bloc/auth_event.dart';
import 'package:faisal_app/features/products/presentation/pages/bank_notices_page.dart';
import 'package:faisal_app/features/settings/presentation/cubit/appearance_cubits.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'security_flow_test.dart' as flow;

/// Opt-in operator smoke test. Credentials are read once from a private device
/// file and deleted before login; never embedded in an APK, build flag or log.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('current local administrator signs in through the real UI', (
    tester,
  ) async {
    final credentials = await tester.runAsync(() async {
      final file = File(
        '${Directory.systemTemp.parent.path}/files/qa/local_admin_login.json',
      );
      final data =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      await file.delete();
      return data;
    });
    expect(credentials != null, isTrue);
    app.main();
    await flow.waitFor(
      tester,
      find.byWidgetPredicate(
        (w) => w is TextFormField || w is NavigationBar || w is BankNoticesPage,
      ),
    );
    await sl<LanguageCubit>().change('en');
    sl<AuthBloc>().add(const AuthLogoutRequested());
    await flow.waitFor(tester, find.text('Sign in'));
    await tester.pumpAndSettle();
    final continueLogin = find.byKey(const ValueKey('notice_continue_login'));
    if (continueLogin.evaluate().isNotEmpty) {
      await tester.tap(continueLogin);
      await tester.pumpAndSettle();
    }
    await flow.waitFor(tester, find.byType(TextFormField));
    await tester.enterText(
      find.byType(TextFormField).first,
      credentials!['username'] as String,
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      credentials['password'] as String,
    );
    await flow.tap(tester, 'Sign in');
    await flow.waitFor(tester, find.byType(AdminDashboardPage));
    await flow.waitFor(tester, find.text('Customers'));
    expect(sl<AuthBloc>().state.isStaff, isTrue);
    expect(sl<AuthBloc>().state.can('admin.dashboard.view'), isTrue);
    expect(tester.takeException(), isNull);
    debugPrint(
      'LOCAL_ADMIN_SMOKE: real UI login and authorized dashboard passed',
    );
    // Leave the verified staff session available for manual operator review.
  }, skip: !const bool.fromEnvironment('RUN_LOCAL_ADMIN_SMOKE'));
}
