import 'dart:io';
import 'dart:ui' as ui;

import 'package:faisal_app/main.dart' as app;
import 'package:faisal_app/core/di/injector.dart';
import 'package:faisal_app/core/network/dio_client.dart';
import 'package:faisal_app/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:faisal_app/features/authentication/presentation/bloc/auth_event.dart';
import 'package:faisal_app/features/settings/presentation/cubit/appearance_cubits.dart';
import 'package:faisal_app/features/products/presentation/pages/bank_notices_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'security_flow_test.dart' as flow;

/// Fresh dedicated QA API + two real customer-created fixture requests.
/// Defines contain identifiers only; no password/token is passed in build flags.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'admin decisions, announcement placement and themed public/customer screens',
    (tester) async {
      app.main();
      await flow.waitFor(
        tester,
        find.byWidgetPredicate(
          (w) =>
              w is TextFormField || w is NavigationBar || w is BankNoticesPage,
        ),
      );
      sl<AuthBloc>().add(const AuthLogoutRequested());
      await sl<LanguageCubit>().change('en');
      await sl<ThemeCubit>().change(ThemeMode.light);
      await flow.waitFor(tester, find.text('Sign in'));
      await tester.pumpAndSettle();
      if (find
          .byKey(const ValueKey('notice_continue_login'))
          .evaluate()
          .isNotEmpty) {
        await tester.tap(find.byKey(const ValueKey('notice_continue_login')));
        await tester.pumpAndSettle();
      }
      Future<void> login(String name, String password) async {
        await flow.waitFor(tester, find.byType(TextFormField));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField).at(0), name);
        await tester.enterText(find.byType(TextFormField).at(1), password);
        await flow.tap(tester, 'Sign in');
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
          final bytes = data!.buffer.asUint8List();
          raster.dispose();
          final dir = Directory(
            '${Directory.systemTemp.parent.path}/files/qa/admin_portal',
          );
          await dir.create(recursive: true);
          await File('${dir.path}/$name.png').writeAsBytes(bytes);
          debugPrint('EMULATOR_QA: captured $name');
        });
      }

      Future<void> back() async {
        final tip = MaterialLocalizations.of(
          tester.element(find.byType(Scaffold).last),
        ).backButtonTooltip;
        await tester.tap(find.byTooltip(tip));
        await tester.pumpAndSettle();
      }

      await login('qaadmin', 'Fictional#PortalReady26');
      await flow.waitFor(tester, find.text('Customers'));
      await tester.pumpAndSettle();

      await tester.pumpAndSettle();
      await capture('01_dashboard_en_light');
      await flow.tap(tester, 'Request queue');
      await flow.waitFor(
        tester,
        find.byKey(const ValueKey('admin_request_search')),
      );
      await tester.pumpAndSettle();
      await capture('02_requests_en_light');
      Future<void> request(String ref) async {
        await tester.enterText(
          find.byKey(const ValueKey('admin_request_search')),
          ref,
        );
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        await flow.waitFor(tester, find.text(ref));
        await flow.tap(tester, ref);
        await flow.waitFor(tester, find.byKey(const ValueKey('admin_reject')));
        await tester.pumpAndSettle();
      }

      await request(const String.fromEnvironment('QA_REJECT_REFERENCE'));
      await tester.tap(find.byKey(const ValueKey('admin_reject')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('admin_decision_confirm')));
      await tester.pumpAndSettle();
      expect(find.textContaining('at least 5'), findsOneWidget);
      await capture('03_rejection_reason_required');
      await tester.enterText(
        find.byKey(const ValueKey('admin_decision_reason')),
        'Incomplete fictional documents',
      );
      await tester.tap(find.byKey(const ValueKey('admin_decision_confirm')));
      await tester.pumpAndSettle();
      await flow.waitFor(
        tester,
        find.textContaining('Incomplete fictional documents'),
      );
      expect(find.byKey(const ValueKey('admin_reject')), findsNothing);
      await capture('04_rejected_request');
      await back();
      await flow.waitFor(
        tester,
        find.byKey(const ValueKey('admin_request_search')),
      );
      await request(const String.fromEnvironment('QA_APPROVE_REFERENCE'));
      await tester.tap(find.byKey(const ValueKey('admin_approve')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('admin_decision_reason')),
        'Verified fictional application',
      );
      await tester.tap(find.byKey(const ValueKey('admin_decision_confirm')));
      await tester.pumpAndSettle();
      await flow.waitFor(tester, find.text('Completed'));
      expect(find.byKey(const ValueKey('admin_approve')), findsNothing);
      await capture('05_approved_request');
      await back();
      await flow.tap(tester, 'Announcements');
      await flow.waitFor(
        tester,
        find.byKey(const ValueKey('admin_new_announcement')),
      );
      await tester.pumpAndSettle();
      const batch = String.fromEnvironment('QA_BATCH');
      final publicTitle = 'Urgent banking notice $batch',
          homeTitle = 'Bank service update $batch';
      Future<void> create(String title, String location) async {
        await tester.tap(find.byKey(const ValueKey('admin_new_announcement')));
        await tester.pumpAndSettle();
        for (final entry in {
          'announcement_title_en': title,
          'announcement_title_ar': 'تنبيه مصرفي تجريبي $batch',
          'announcement_body_en':
              'Fictional service update. Your banking records remain safe.',
          'announcement_body_ar':
              'تنبيه خدمي خيالي للاختبار. بياناتك المصرفية محفوظة.',
        }.entries) {
          await tester.enterText(find.byKey(ValueKey(entry.key)), entry.value);
        }
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.byKey(const ValueKey('announcement_location')),
        );
        await tester.tap(find.byKey(const ValueKey('announcement_location')));
        await tester.pumpAndSettle();
        await tester.tap(find.text(location).last);
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.byKey(const ValueKey('announcement_priority')),
        );
        await tester.tap(find.byKey(const ValueKey('announcement_priority')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('High').last);
        await tester.pumpAndSettle();
        await capture(
          location == 'Before sign-in'
              ? '06_public_announcement_editor'
              : '07_home_announcement_editor',
        );
        await tester.tap(find.byKey(const ValueKey('announcement_publish')));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Publish').last);
        for (
          var i = 0;
          i < 160 &&
              find
                  .byKey(const ValueKey('announcement_title_en'))
                  .evaluate()
                  .isNotEmpty;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 250));
        }
        expect(
          find.byKey(const ValueKey('announcement_title_en')),
          findsNothing,
        );
        await flow.waitFor(tester, find.text(title));
      }

      await create(publicTitle, 'Before sign-in');
      await create(homeTitle, 'Customer home');
      await tester.pumpAndSettle();
      await capture('08_announcement_library_en');
      await sl<LanguageCubit>().change('ar');
      await sl<ThemeCubit>().change(ThemeMode.dark);
      await tester.pumpAndSettle();
      await capture('09_admin_announcements_ar_dark');
      sl<AuthBloc>().add(const AuthLogoutRequested());
      await flow.waitFor(tester, find.byType(BankNoticesPage));
      await tester.pumpAndSettle();
      await capture('10_before_login_ar_dark');
      await sl<LanguageCubit>().change('en');
      await sl<ThemeCubit>().change(ThemeMode.light);
      await tester.pumpAndSettle();
      await flow.waitFor(tester, find.text(publicTitle));
      expect(find.text(homeTitle), findsNothing);
      await capture('11_before_login_en_light');
      await tester.tap(find.byKey(const ValueKey('notice_continue_login')));
      await tester.pumpAndSettle();
      await login('youssefkamal', 'Youssef#2026');
      await flow.waitFor(tester, find.text('My accounts'));
      final banners = await sl<DioClient>().get('/banners') as List;
      expect(banners.any((r) => r['title_en'] == homeTitle), isTrue);
      expect(banners.any((r) => r['title_en'] == publicTitle), isFalse);
      await tester.scrollUntilVisible(
        find.text(homeTitle),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await capture('12_customer_home_notice');
      await flow.tap(tester, homeTitle);
      await flow.waitFor(tester, find.byType(BankNoticesPage));
      await tester.pumpAndSettle();
      await capture('13_home_announcement_details');
      final own = await sl<DioClient>().get(
        '/requests',
        query: {'request_type': 'other'},
      ) as Map;
      expect(
        (own['items'] as List).any(
          (r) =>
              r['id'] == const String.fromEnvironment('QA_APPROVE_ID') &&
              r['status'] == 'completed',
        ),
        isTrue,
      );
      debugPrint(
        'EMULATOR_QA: customer decisions, mandatory rejection reason, notice placement and localized themes passed.',
      );
      sl<AuthBloc>().add(const AuthLogoutRequested());
      await tester.pumpAndSettle();
    },
    timeout: const Timeout(Duration(minutes: 8)),
  );
}
