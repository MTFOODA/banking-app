import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:faisal_app/main.dart' as app;
import 'package:faisal_app/core/config/app_config.dart';
import 'package:faisal_app/core/di/injector.dart';
import 'package:faisal_app/core/network/dio_client.dart';
import 'package:faisal_app/core/utils/json_utils.dart';
import 'package:faisal_app/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:faisal_app/features/authentication/presentation/bloc/auth_event.dart';
import 'package:faisal_app/features/products/presentation/pages/bank_notices_page.dart';
import 'package:faisal_app/features/settings/presentation/cubit/appearance_cubits.dart';
import 'package:faisal_app/features/transfers/presentation/cubit/transfers_cubit.dart';

import 'security_flow_test.dart' as flow;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'own-account FX freezes real-feed quotes and posts both currencies atomically',
    (tester) async {
      expect(
        AppConfig.apiBaseUrl.contains(':8015/'),
        isTrue,
        reason: 'Only the isolated fictional QA server is permitted',
      );
      const username = String.fromEnvironment('QA_TRANSFER_USERNAME');
      expect(username.isNotEmpty, isTrue);
      app.main();
      await flow.waitFor(
        tester,
        find.byWidgetPredicate(
          (w) =>
              w is NavigationBar || w is TextFormField || w is BankNoticesPage,
        ),
      );
      await sl<LanguageCubit>().change('en');
      await sl<ThemeCubit>().change(ThemeMode.light);
      sl<AuthBloc>().add(const AuthLogoutRequested());
      await flow.waitFor(tester, find.text('Sign in'));
      await tester.pumpAndSettle();
      final next = find.byKey(const ValueKey('notice_continue_login'));
      if (next.evaluate().isNotEmpty) {
        await tester.tap(next);
        await tester.pumpAndSettle();
      }
      await flow.waitFor(tester, find.byType(TextFormField));
      await tester.enterText(find.byType(TextFormField).first, username);
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Fictional#TransferQA26',
      );
      await flow.tap(tester, 'Sign in');
      await flow.waitFor(tester, find.byType(NavigationBar));
      await tester.pumpAndSettle();
      GoRouter.of(tester.element(find.byType(Scaffold).last)).go('/transfers');
      await flow.waitFor(tester, find.byType(ChoiceChip));
      await tester.pumpAndSettle();
      Finder field(String key) => find.descendant(
        of: find.byKey(ValueKey(key)),
        matching: find.byType(TextFormField),
      );
      Future<void> tap(Finder target) async {
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
        await tester.tap(target);
        await tester.pumpAndSettle();
      }

      Future<void> select(int index, String label) async {
        await tap(find.byType(DropdownButtonFormField<String>).at(index));
        await tap(find.text(label).last);
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
            '${Directory.systemTemp.parent.path}/files/qa/own_fx',
          );
          await dir.create(recursive: true);
          await File('${dir.path}/$name.png')
              .writeAsBytes(data!.buffer.asUint8List());
        });
        debugPrint('OWN_FX_QA: captured $name');
      }

      TransfersCubit cubit() => tester
          .widget<BlocBuilder<TransfersCubit, TransfersState>>(
            find.byType(BlocBuilder<TransfersCubit, TransfersState>),
          )
          .bloc!;
      var egpBalance = 1000.0;
      var usdBalance = 1000.0;
      for (var i = 0; i < 2; i++) {
        final sourceCurrency = i == 0 ? 'USD' : 'EGP';
        final receivedCurrency = i == 0 ? 'EGP' : 'USD';
        await tap(find.byKey(const ValueKey('transfer_type_own_accounts')));
        await select(
          0,
          i == 0
              ? '**** QA USD_SOURCE \u2022 USD'
              : '**** QA SOURCE \u2022 EGP',
        );
        await select(
          1,
          i == 0
              ? '**** QA SOURCE \u2022 EGP'
              : '**** QA USD_SOURCE \u2022 USD',
        );
        await tester.enterText(field('transfer_amount'), '10.00');
        await tester.enterText(
          field('transfer_purpose'),
          'Fictional own-account FX QA',
        );
        await tap(find.byKey(const ValueKey('transfer_review')));
        await flow.waitFor(tester, field('transfer_token'));
        await tester.pumpAndSettle();
        final quote = Map<String, dynamic>.from(cubit().state.quote!);
        final credit = asDouble(quote['received_amount']);
        expect(credit, greaterThan(0));
        expect(quote['currency'], sourceCurrency);
        expect(quote['received_currency'], receivedCurrency);
        expect(quote['rate_provider'], 'exchangerate.dev');
        expect(quote['rate_is_simulated'], isTrue);
        expect(cubit().state.draft!['fx_quote_id'], quote['fx_quote_id']);
        expect(
          DateTime.parse(quote['fx_quote_expires_at'] as String)
              .isAfter(DateTime.now()),
          isTrue,
        );
        if (i == 1) {
          await sl<LanguageCubit>().change('ar');
          await sl<ThemeCubit>().change(ThemeMode.dark);
          await tester.pumpAndSettle();
          expect(
            Directionality.of(tester.element(field('transfer_token'))),
            TextDirection.rtl,
          );
        }
        final rateText = find.byWidgetPredicate(
          (w) =>
              w is Text &&
              (w.data?.startsWith('1 $sourceCurrency = ') ?? false),
        );
        expect(tester.widget<Text>(rateText).textDirection, TextDirection.ltr);
        await tester.ensureVisible(field('transfer_token'));
        await capture(
          i == 0 ? '01_review_usd_egp_en_light' : '04_review_egp_usd_ar_dark',
        );
        if (i == 1) {
          await sl<LanguageCubit>().change('en');
          await tester.pumpAndSettle();
        }
        await flow.tap(tester, 'Authorize operation');
        await flow.waitFor(tester, find.text('Current password'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextFormField).first,
          'Fictional#TransferQA26',
        );
        await flow.tap(tester, 'Authorize operation');
        await flow.waitFor(tester, find.text('Copy Token'));
        await tester.pumpAndSettle();
        if (i == 0) await capture('02_password_authorization_token_masked');
        await flow.tap(tester, 'Copy Token');
        final token = (await Clipboard.getData('text/plain'))?.text;
        expect(token?.isNotEmpty, isTrue);
        await flow.tap(tester, 'Continue');
        await flow.waitFor(tester, field('transfer_token'));
        await tester.pumpAndSettle();
        await tester.enterText(field('transfer_token'), token!);
        await tap(find.byType(CheckboxListTile));
        await tap(find.byKey(const ValueKey('transfer_confirm')));
        await flow.waitFor(tester, find.text('Done'));
        await tester.pumpAndSettle();
        final receipt = cubit().state.result!;
        expect(receipt.status, 'posted');
        expect(receipt.transferType, 'own_accounts');
        expect(receipt.amount, 10);
        expect(receipt.currency, sourceCurrency);
        expect(receipt.receivedCurrency, receivedCurrency);
        expect(receipt.receivedAmount, credit);
        expect(receipt.exchangeRate, quote['exchange_rate']);
        expect(receipt.isSimulated, isTrue);
        if (i == 0) {
          usdBalance -= 10;
          egpBalance += credit;
        } else {
          egpBalance -= 10;
          usdBalance += credit;
        }
        final overview = await sl<DioClient>().get('/accounts') as Map;
        final accounts = overview['accounts'] as List;
        expect(
          asDouble(
            accounts.singleWhere(
              (a) => a['id'] == const String.fromEnvironment('QA_SOURCE_ID'),
            )['available_balance'],
          ),
          closeTo(egpBalance, 0.001),
        );
        expect(
          asDouble(
            accounts.singleWhere(
              (a) =>
                  a['id'] == const String.fromEnvironment('QA_USD_SOURCE_ID'),
            )['available_balance'],
          ),
          closeTo(usdBalance, 0.001),
        );
        expect(
          asDouble(
            accounts.singleWhere(
              (a) => a['id'] == const String.fromEnvironment('QA_OWN_DEST_ID'),
            )['available_balance'],
          ),
          1000,
        );
        if (i == 1) {
          await sl<LanguageCubit>().change('ar');
          await tester.pumpAndSettle();
        }
        await capture(
          i == 0 ? '03_receipt_usd_egp_en_light' : '05_receipt_egp_usd_ar_dark',
        );
        if (i == 1) {
          await sl<LanguageCubit>().change('en');
          await tester.pumpAndSettle();
        }
        await flow.tap(tester, 'Done');
        await flow.waitFor(tester, find.byType(ChoiceChip));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
      debugPrint(
        'OWN_FX_QA: both real-feed conversions, password grants, copied tokens, frozen rates, Arabic RTL, receipts and exact account balances passed',
      );
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );
}
