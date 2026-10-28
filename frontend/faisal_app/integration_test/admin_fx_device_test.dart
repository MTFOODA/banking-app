import 'dart:io';

import 'package:faisal_app/main.dart' as app;
import 'package:faisal_app/core/di/injector.dart';
import 'package:faisal_app/core/network/dio_client.dart';
import 'package:faisal_app/core/errors/app_exception.dart';
import 'package:faisal_app/l10n/app_localizations.dart';
import 'package:faisal_app/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:faisal_app/features/authentication/presentation/bloc/auth_event.dart';
import 'package:faisal_app/features/settings/presentation/cubit/appearance_cubits.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'security_flow_test.dart' as flow;

/// Fictional staff identity is provisioned only in a dedicated *_device_*_test
/// database. Never use this fixture to change the persistent phone admin.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('staff username/setup/dashboard and real FX filters on Android', (
    tester,
  ) async {
    app.main();
    await flow.waitFor(tester, find.byWidgetPredicate(flow.isStartupPage));
    await sl<LanguageCubit>().change('en');
    sl<AuthBloc>().add(const AuthLogoutRequested());
    await flow.waitFor(tester, find.text('Sign in'));
    await flow.openSignIn(tester);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'deviceqaadmin');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      const bool.fromEnvironment('QA_ADMIN_ALREADY_READY')
          ? 'Device#AdminReady2026'
          : 'Device#AdminTemp2026',
    );
    await flow.tap(tester, 'Sign in');
    if (!const bool.fromEnvironment('QA_ADMIN_ALREADY_READY')) {
      await flow.waitFor(tester, find.text('New password'));
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsNWidgets(2));
      await tester.enterText(
        find.byType(TextFormField).first,
        'Device#AdminReady2026',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Device#AdminReady2026',
      );
      await flow.tap(
        tester,
        AppLocalizations.of(tester.element(find.byType(TextFormField).first))
            .continueToHome,
      );
    }
    await flow.waitFor(tester, find.text('Administration portal'));
    await flow.waitFor(tester, find.text('Customers'));
    expect(find.text('Active accounts'), findsOneWidget);
    expect(find.text('Pending requests'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    final data = await sl<DioClient>().get('/admin/dashboard');
    expect(data, isA<Map>());
    debugPrint('DEVICE_QA: staff username and protected dashboard passed.');
    sl<AuthBloc>().add(const AuthLogoutRequested());
    await flow.waitFor(tester, find.text('Sign in'));
    await flow.openSignIn(tester);
    await tester.pumpAndSettle();
    // Normal subsequent staff login must return to the same dashboard.
    await tester.enterText(find.byType(TextFormField).first, 'deviceqaadmin');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Device#AdminReady2026',
    );
    await flow.tap(tester, 'Sign in');
    await flow.waitFor(tester, find.text('Customers'));
    sl<AuthBloc>().add(const AuthLogoutRequested());
    await flow.waitFor(tester, find.text('Sign in'));
    await flow.openSignIn(tester);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'salmanabil');
    await tester.enterText(find.byType(TextFormField).at(1), 'Salma#2026');
    await flow.tap(tester, 'Sign in');
    await flow.waitFor(tester, find.byType(NavigationBar));
    var denied = false;
    try {
      await sl<DioClient>().get('/admin/dashboard');
    } on AppException catch (error) {
      denied = error.code == AppErrorCode.forbidden;
    }
    expect(denied, isTrue);
    await flow.tap(tester, 'More');
    await flow.tap(tester, 'Currency exchange rates');
    final usd = find.byKey(const ValueKey('fx_card_USD'));
    await flow.waitFor(tester, usd);
    await tester.enterText(find.byKey(const ValueKey('fx_search')), 'SAR');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('fx_card_SAR')), findsOneWidget);
    expect(usd, findsNothing);
    await tester.enterText(find.byKey(const ValueKey('fx_search')), '');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('fx_filter_arab')));
    await tester.tap(find.byKey(const ValueKey('fx_filter_arab')));
    await tester.pumpAndSettle();
    expect(usd, findsNothing);
    expect(find.byKey(const ValueKey('fx_card_SAR')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('fx_filter_all')));
    await tester.tap(find.byKey(const ValueKey('fx_filter_all')));
    await sl<LanguageCubit>().change('ar');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    expect(Directionality.of(tester.element(usd)), TextDirection.rtl);
    // Capture only the application's Flutter surface, excluding other apps/PiP.
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    final bytes = await binding.takeScreenshot('fx_ar_device');
    final imageDirectory = Directory(
      '${Directory.systemTemp.parent.path}/files/qa',
    );
    await imageDirectory.create(recursive: true);
    await File('${imageDirectory.path}/fx_ar_device.png').writeAsBytes(bytes);
    binding.reportData?.remove('screenshots');
    debugPrint(
      'DEVICE_QA: real FX search, regional filters and Arabic layout passed.',
    );
    await tester.tap(
      find.byTooltip(
        MaterialLocalizations.of(tester.element(usd)).backButtonTooltip,
      ),
    );
    await sl<LanguageCubit>().change('en');
    sl<AuthBloc>().add(const AuthLogoutRequested());
    await flow.waitFor(tester, find.text('Sign in'));
    await flow.openSignIn(tester);
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 5)));
}
