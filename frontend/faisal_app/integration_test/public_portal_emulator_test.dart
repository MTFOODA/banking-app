import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:faisal_app/main.dart' as app;
import 'package:faisal_app/core/config/app_config.dart';
import 'package:faisal_app/core/di/injector.dart';
import 'package:faisal_app/core/network/dio_client.dart';
import 'package:faisal_app/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:faisal_app/features/authentication/presentation/bloc/auth_event.dart';
import 'package:faisal_app/features/products/presentation/pages/bank_notices_page.dart';
import 'package:faisal_app/features/settings/presentation/cubit/appearance_cubits.dart';
import 'package:faisal_app/features/support/presentation/pages/branch_directory_page.dart';
import 'package:faisal_app/features/support/presentation/pages/public_bank_services_page.dart';
import 'package:faisal_app/features/support/presentation/services/bank_contact_links.dart';

import 'security_flow_test.dart' as flow;

class CheckedLinks extends BankContactLinks {
  final requests = <Uri>[];
  final results = <bool>[];
  @override
  Future<bool> open(Uri uri) async {
    requests.add(uri);
    final opened = await super.open(uri);
    results.add(opened);
    debugPrint(
      'PUBLIC_EXTERNAL_READY: ${requests.length} ${opened ? "opened" : "unavailable"}',
    );
    return opened;
  }
}

/// Run scripts/watch_public_link_test.py alongside this emulator test. It records
/// the external foreground handler and restores this app; it never places a call.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'permanent public portal, offline branches, native maps/browser/dialer, copy and bilingual layout',
    (tester) async {
      expect(AppConfig.apiBaseUrl.contains(':8011/'), isTrue);
      app.main();
      await flow.waitFor(tester, find.byWidgetPredicate(flow.isStartupPage));
      await sl<LanguageCubit>().change('en');
      await sl<ThemeCubit>().change(ThemeMode.light);
      sl<AuthBloc>().add(const AuthLogoutRequested());
      await flow.waitFor(tester, find.byType(BankNoticesPage));
      await tester.pumpAndSettle();
      final links = CheckedLinks();
      await sl.unregister<BankContactLinks>();
      sl.registerSingleton<BankContactLinks>(links);
      final publicItems =
          await sl<DioClient>().get('/public/announcements') as List;
      expect(publicItems, isA<List>());
      Future<void> tap(String key) async {
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        final target = find.byKey(ValueKey(key));
        await tester.ensureVisible(target);
        await tester.tap(target);
        await tester.pumpAndSettle();
      }

      Future<void> capture(String name) async {
        FocusManager.instance.primaryFocus?.unfocus();
        ScaffoldMessenger.maybeOf(tester.element(find.byType(Scaffold).last))
            ?.clearSnackBars();
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final scene = tester.binding.renderViews.first.debugLayer!.buildScene(
            ui.SceneBuilder(),
          );
          final raster = await scene.toImage(
            tester.view.physicalSize.width.toInt(),
            tester.view.physicalSize.height.toInt(),
          );
          scene.dispose();
          final data = await raster.toByteData(format: ui.ImageByteFormat.png);
          raster.dispose();
          final dir = Directory(
            '${Directory.systemTemp.parent.path}/files/qa/public_portal',
          );
          await dir.create(recursive: true);
          await File('${dir.path}/$name.png')
              .writeAsBytes(data!.buffer.asUint8List());
        });
        debugPrint('PUBLIC_QA: captured $name');
      }

      Future<void> back() async {
        GoRouter.of(tester.element(find.byType(Scaffold).last)).pop();
        await tester.pumpAndSettle();
        await flow.waitFor(tester, find.byType(BankNoticesPage));
      }

      Future<void> external(String key) async {
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        final finder = find.byKey(ValueKey(key));
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        await tester.tap(finder);
        // The host observes the real Android handler, then resumes MainActivity.
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(seconds: 7)),
        );
        await tester.pumpAndSettle();
        expect(links.results.last, isTrue);
      }

      for (final key in [
        'notice_continue_login',
        'public_branches',
        'public_atms',
        'public_call_center',
      ]) {
        expect(find.byKey(ValueKey(key)), findsOneWidget);
      }
      await capture('01_public_services_en_light');
      if (publicItems.isNotEmpty) {
        final title = find.text(
          (publicItems.first as Map)['title_en'] as String,
        );
        await tester.ensureVisible(title);
        await capture('02_announcements_below_cards');
      }
      await tap('public_branches');
      await flow.waitFor(tester, find.byKey(const ValueKey('branch_count')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('branch_count'))).data,
        'Results: 44',
      );
      await capture('03_branches_en');
      expect(find.text('الجيزة - المبنى الإداري'), findsOneWidget);
      await external('branch_map_15');
      expect(
        links.requests.last.queryParameters['query'],
        '30.039497,31.218555',
      );
      await tester.enterText(
        find.byKey(const ValueKey('branch_search')),
        '\u0627\u0644\u0627\u0632\u0647\u0631',
      );
      await tester.pumpAndSettle();
      expect(find.text('Results: 1'), findsOneWidget);
      await capture('04_branch_search');
      await back();
      await tap('public_atms');
      expect(find.byType(AtmLocatorPage), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('atm_area')),
        'Nasr City',
      );
      await capture('05_atm_locator_en');
      await external('atm_map_search');
      expect(
        links.requests.last.queryParameters['query'],
        contains('Nasr City'),
      );
      await external('atm_official_locator');
      expect(links.requests.last, BankContactLinks.locator);
      await back();
      await tap('public_call_center');
      expect(find.byType(CallCenterPage), findsOneWidget);
      await tap('call_center_copy');
      expect(
        (await Clipboard.getData('text/plain'))?.text,
        BankContactLinks.hotline,
      );
      await capture('06_call_center_en');
      await external('call_center_dial');
      expect(links.requests.last.toString(), 'tel:19851');
      expect(links.requests.length, 4);
      expect(links.results.every((value) => value), isTrue);
      await back();
      await sl<LanguageCubit>().change('ar');
      await sl<ThemeCubit>().change(ThemeMode.dark);
      await tester.pumpAndSettle();
      expect(
        Directionality.of(tester.element(find.byType(BankNoticesPage))),
        TextDirection.rtl,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('notice_continue_login')),
      );
      await capture('07_public_services_ar_dark');
      await tap('public_branches');
      await flow.waitFor(tester, find.byKey(const ValueKey('branch_count')));
      await capture('08_branches_ar_dark');
      expect(
        Directionality.of(tester.element(find.byType(BranchDirectoryPage))),
        TextDirection.rtl,
      );
      await back();
      await tap('public_call_center');
      await capture('09_call_center_ar_dark');
      await back();
      await sl<LanguageCubit>().change('en');
      await sl<ThemeCubit>().change(ThemeMode.light);
      await tester.pumpAndSettle();
      await tap('notice_continue_login');
      await flow.waitFor(tester, find.byType(TextFormField));
      await capture('10_signin_entry');
      expect(tester.takeException(), isNull);
      debugPrint(
        'PUBLIC_QA: four cards, actual public notices, 44 offline branches, Arabic search, real external handlers, copied hotline, RTL/dark and explicit sign-in passed',
      );
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}
