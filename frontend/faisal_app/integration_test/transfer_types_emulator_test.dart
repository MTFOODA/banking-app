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
import 'package:faisal_app/features/transfers/presentation/pages/transfers_page.dart';

import 'security_flow_test.dart' as flow;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'six routes use real password grants, explicit confirmation and committed receipts',
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
            '${Directory.systemTemp.parent.path}/files/qa/transfer_types',
          );
          await dir.create(recursive: true);
          await File('${dir.path}/$name.png')
              .writeAsBytes(data!.buffer.asUint8List());
        });
        debugPrint('TRANSFER_QA: captured $name');
      }

      await capture('01_types_en_light');
      for (var index = 0; index < transferTypes.length; index++) {
        final type = transferTypes[index];
        await tap(find.byKey(ValueKey('transfer_type_$type')));
        await select(
          0,
          type == 'international'
              ? '**** QA USD_SOURCE • USD'
              : '**** QA SOURCE • EGP',
        );
        if (type == 'own_accounts') await select(1, '**** QA OWN_DEST • EGP');
        if (type == 'internal') {
          await select(
            1,
            'Fictional same-bank recipient • ${const String.fromEnvironment('QA_RECIPIENT_MASK')}',
          );
        }
        if (!['own_accounts', 'internal'].contains(type)) {
          await tester.enterText(
            field('transfer_recipient_name'),
            'Fictional recipient',
          );
          await tester.enterText(
            field('transfer_recipient_destination'),
            type == 'wallet'
                ? '01012345678'
                : (type == 'instapay'
                      ? 'fictional.qa@instapay'
                      : '001234567890'),
          );
          if (['external_domestic', 'international'].contains(type)) {
            await tester.enterText(
              field('transfer_recipient_bank'),
              'Fictional receiving bank',
            );
          }
          if (type == 'international') {
            await tester.enterText(field('transfer_recipient_country'), 'US');
            await tester.enterText(
              field('transfer_recipient_swift'),
              'FAKEUS33XXX',
            );
          }
        }
        await tester.enterText(field('transfer_amount'), '10.00');
        await tester.enterText(
          field('transfer_purpose'),
          'Fictional $type transfer test',
        );
        await tester.ensureVisible(
          find.byKey(const ValueKey('transfer_review')),
        );
        await tester.pumpAndSettle();
        await capture(
          '${(2 + index * 2).toString().padLeft(2, '0')}_form_$type',
        );
        await tap(find.byKey(const ValueKey('transfer_review')));
        await flow.waitFor(
          tester,
          find.byKey(const ValueKey('transfer_token')),
        );
        await tester.pumpAndSettle();
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
        if (index == 0) await capture('15_authorization_token_masked');
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
        final bloc = tester
            .widget<BlocBuilder<TransfersCubit, TransfersState>>(
              find.byType(BlocBuilder<TransfersCubit, TransfersState>),
            )
            .bloc!;
        final receipt = bloc.state.result;
        expect(receipt != null, isTrue);
        expect(receipt!.transferType, type);
        expect(receipt.amount, 10);
        expect(receipt.currency, type == 'international' ? 'USD' : 'EGP');
        expect(
          receipt.status,
          ['own_accounts', 'internal'].contains(type)
              ? 'posted'
              : 'simulated_completed',
        );
        if (!['own_accounts', 'internal'].contains(type)) {
          expect(receipt.providerReference?.startsWith('SIM-'), isTrue);
        }
        await capture(
          '${(3 + index * 2).toString().padLeft(2, '0')}_receipt_$type',
        );
        await flow.tap(tester, 'Done');
        await flow.waitFor(tester, find.byType(ChoiceChip));
        await tester.pumpAndSettle();
      }
      final overview = await sl<DioClient>().get('/accounts') as Map;
      final accounts = overview['accounts'] as List;
      expect(
        asDouble(
          accounts.singleWhere(
            (a) => a['id'] == const String.fromEnvironment('QA_SOURCE_ID'),
          )['available_balance'],
        ),
        950.0,
      );
      expect(
        asDouble(
          accounts.singleWhere(
            (a) => a['id'] == const String.fromEnvironment('QA_OWN_DEST_ID'),
          )['available_balance'],
        ),
        1010.0,
      );
      expect(
        asDouble(
          accounts.singleWhere(
            (a) => a['id'] == const String.fromEnvironment('QA_USD_SOURCE_ID'),
          )['available_balance'],
        ),
        990.0,
      );
      await sl<LanguageCubit>().change('ar');
      await sl<ThemeCubit>().change(ThemeMode.dark);
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('transfer_type_own_accounts')),
      );
      await tester.pumpAndSettle();
      await capture('14_types_ar_dark');
      expect(tester.takeException(), isNull);
      debugPrint(
        'TRANSFER_QA: all six real UI flows, password grants, explicit confirmation and exact closing balances passed',
      );
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );
}
