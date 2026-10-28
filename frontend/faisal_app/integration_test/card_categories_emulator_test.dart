import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:faisal_app/main.dart' as app;
import 'package:faisal_app/core/config/app_config.dart';
import 'package:faisal_app/core/di/injector.dart';
import 'package:faisal_app/core/network/dio_client.dart';
import 'package:faisal_app/core/widgets/faisal_bank_card.dart';
import 'package:faisal_app/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:faisal_app/features/authentication/presentation/bloc/auth_event.dart';
import 'package:faisal_app/features/cards/domain/repositories/cards_repository.dart';
import 'package:faisal_app/features/cards/presentation/pages/card_application_page.dart';
import 'package:faisal_app/features/cards/presentation/cubit/card_application_cubit.dart';
import 'package:faisal_app/features/products/presentation/pages/bank_notices_page.dart';
import 'package:faisal_app/features/settings/presentation/cubit/appearance_cubits.dart';

import 'security_flow_test.dart' as flow;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'six card categories require real bank approval and retain their designs',
    (tester) async {
      expect(
        AppConfig.apiBaseUrl.contains(':8015/'),
        isTrue,
        reason: 'Only the dedicated fictional QA API is allowed',
      );
      app.main();
      await flow.waitFor(
        tester,
        find.byWidgetPredicate(
          (w) =>
              w is TextFormField || w is NavigationBar || w is BankNoticesPage,
        ),
      );
      await sl<LanguageCubit>().change('en');
      await sl<ThemeCubit>().change(ThemeMode.light);
      Future<void> logout() async {
        sl<AuthBloc>().add(const AuthLogoutRequested());
        await flow.waitFor(tester, find.text('Sign in'));
        await tester.pumpAndSettle();
        final next = find.byKey(const ValueKey('notice_continue_login'));
        if (next.evaluate().isNotEmpty) {
          await tester.tap(next);
          await tester.pumpAndSettle();
        }
      }

      Future<void> login(bool staff) async {
        await flow.waitFor(tester, find.byType(TextFormField));
        await tester.enterText(
          find.byType(TextFormField).first,
          staff ? 'qaadmin' : 'youssefkamal',
        );
        await tester.enterText(
          find.byType(TextFormField).at(1),
          staff ? 'Fictional#PortalReady26' : 'Youssef#2026',
        );
        await flow.tap(tester, 'Sign in');
        await flow.waitFor(tester, find.byType(NavigationBar));
        await tester.pumpAndSettle();
      }

      Future<void> go(String path) async {
        GoRouter.of(tester.element(find.byType(Scaffold).last)).go(path);
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
          final png = await raster.toByteData(format: ui.ImageByteFormat.png);
          raster.dispose();
          final dir = Directory(
            '${Directory.systemTemp.parent.path}/files/qa/card_categories',
          );
          await dir.create(recursive: true);
          await File('${dir.path}/$name.png')
              .writeAsBytes(png!.buffer.asUint8List());
        });
        debugPrint('CARD_QA: captured $name');
      }

      await logout();
      await login(false);
      // Cancel only unfinished card QA requests from a previous interrupted run.
      final api = sl<DioClient>();
      final prior = await api.get(
        '/requests',
        query: {'request_type': 'card_issue'},
      );
      for (final row in (prior as Map)['items'] as List) {
        if (!['completed', 'rejected', 'cancelled'].contains(row['status'])) {
          await api.post('/requests/${row['id']}/cancel');
        }
      }
      Future<void> openApplication() async {
        await go('/cards');
        await flow.waitFor(tester, find.byType(FaisalBankCard));
        await tester.pumpAndSettle();
        await flow.waitFor(
          tester,
          find.byKey(const ValueKey('request_new_card')),
        );
        await tester.ensureVisible(
          find.byKey(const ValueKey('request_new_card')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('request_new_card')));
        await flow.waitFor(tester, find.byType(CardProductPreview));
        await tester.pumpAndSettle();
      }

      Future<String> apply(String variant, {bool captureReview = false}) async {
        await openApplication();
        if (captureReview) {
          await capture('01_catalogue_gold_platinum');
          await tester.ensureVisible(
            find.byKey(const ValueKey('choose_meeza')),
          );
          await tester.pumpAndSettle();
          await capture('02_catalogue_youth_meeza');
        }
        final choice = find.byKey(ValueKey('choose_$variant'));
        await tester.ensureVisible(choice);
        await tester.tap(choice);
        await tester.pumpAndSettle();
        final review = find.byKey(const ValueKey('card_issue_review'));
        await tester.ensureVisible(review);
        await tester.tap(review);
        await tester.pumpAndSettle();
        if (captureReview) await capture('03_review_requires_approval');
        final before = (await sl<CardsRepository>().fetchCards()).cards.length;
        await tester.tap(find.byKey(const ValueKey('card_issue_confirm')));
        await flow.waitFor(
          tester,
          find.byKey(const ValueKey('card_issue_reference')),
        );
        await tester.pumpAndSettle();
        final cubit = tester
            .element(find.byType(CardApplicationView))
            .read<CardApplicationCubit>();
        expect(cubit.state.receipt?.status, 'submitted');
        expect((await sl<CardsRepository>().fetchCards()).cards.length, before);
        if (captureReview) {
          await tester.ensureVisible(
            find.byKey(const ValueKey('card_issue_reference')),
          );
          await capture('04_pending_request_receipt');
        }
        return cubit.state.receipt!.reference;
      }

      Future<void> decide(String reference, bool approve) async {
        await logout();
        await login(true);
        await go('/admin/requests');
        final search = find.byKey(const ValueKey('admin_request_search'));
        await flow.waitFor(tester, search);
        await tester.enterText(search, reference);
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        await flow.waitFor(tester, find.text(reference));
        await flow.tap(tester, reference);
        final action = find.byKey(
          ValueKey(approve ? 'admin_approve' : 'admin_reject'),
        );
        await flow.waitFor(tester, action);
        await tester.ensureVisible(action);
        await tester.tap(action);
        await tester.pumpAndSettle();
        if (!approve) {
          await tester.tap(
            find.byKey(const ValueKey('admin_decision_confirm')),
          );
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byKey(const ValueKey('admin_decision_reason')),
            'Fictional QA rejection: missing delivery details',
          );
        }
        await tester.tap(find.byKey(const ValueKey('admin_decision_confirm')));
        await tester.pumpAndSettle();
        await flow.waitFor(
          tester,
          find.text(approve ? 'Completed' : 'Rejected'),
        );
        if (!approve) await capture('05_admin_rejected_with_reason');
        await logout();
        await login(false);
      }

      final rejected = await apply('gold', captureReview: true);
      await decide(rejected, false);
      await openApplication();
      await tester.ensureVisible(
        find.text('Fictional QA rejection: missing delivery details').first,
      );
      await capture('06_customer_rejection_reason');
      const variants = [
        'gold',
        'platinum',
        'platinum_fx',
        'youth',
        'meeza',
        'meeza_bab_rezq',
      ];
      const codes = [
        'CP-GOLD-DEBIT',
        'CP-PLATINUM-DEBIT',
        'CP-PLATINUM-FX',
        'CP-YOUTH-DEBIT',
        'CP-MEEZA-DEBIT',
        'CP-MEEZA-BAB-REZQ',
      ];
      for (var i = 0; i < variants.length; i++) {
        final ref = await apply(variants[i]);
        await decide(ref, true);
        await go('/cards');
        final owned = find.byWidgetPredicate(
          (w) => w is FaisalBankCard && w.card.productCode == codes[i],
        );
        await flow.waitFor(tester, owned);
        await tester.ensureVisible(owned.first);
        await tester.pumpAndSettle();
        final actual = tester.widget<FaisalBankCard>(owned.first).card;
        expect(actual.status, 'pending_activation');
        if (variants[i] == 'platinum_fx') {
          expect(['USD', 'EUR', 'SAR'], contains(actual.currency));
        }
        await capture(
          '${(i + 7).toString().padLeft(2, '0')}_issued_${variants[i]}',
        );
      }
      await go('/cards/apply');
      await flow.waitFor(tester, find.byType(CardProductPreview));
      await sl<LanguageCubit>().change('ar');
      await sl<ThemeCubit>().change(ThemeMode.dark);
      await tester.pumpAndSettle();
      await capture('13_catalogue_ar_dark');
      expect(tester.takeException(), isNull);
      debugPrint(
        'CARD_QA: all six categories issued only after UI approval; rejection and customer status verified',
      );
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );
}
