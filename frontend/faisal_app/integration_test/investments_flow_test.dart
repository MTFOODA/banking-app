import 'package:faisal_app/main.dart' as app;
import 'package:faisal_app/core/di/injector.dart';
import 'package:faisal_app/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:faisal_app/features/authentication/presentation/bloc/auth_event.dart';
import 'package:faisal_app/features/settings/presentation/cubit/appearance_cubits.dart';
import 'package:faisal_app/features/products/domain/repositories/investment_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'security_flow_test.dart'
    show waitFor, tap, stepUp, isStartupPage, openSignIn;

/// Mutation-capable QA using fictional credentials on a dedicated test DB.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'usernames, separated Accounts tabs, all certificates and funds, redemption and FX',
    (tester) async {
      app.main();
      await waitFor(tester, find.byWidgetPredicate(isStartupPage));
      await sl<LanguageCubit>().change('en');
      Future<void> signIn(String username, String password) async {
        sl<AuthBloc>().add(const AuthLogoutRequested());
        await waitFor(tester, find.text('Sign in'));
        await openSignIn(tester);
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField).at(0), username);
        await tester.enterText(find.byType(TextFormField).at(1), password);
        await tap(tester, 'Sign in');
        await waitFor(tester, find.byType(NavigationBar));
        await tap(tester, 'Accounts');
        await waitFor(
          tester,
          find.byKey(const ValueKey('account_certificates_tab')),
        );
      }

      Future<void> section(bool fund) async {
        await tester.tap(
          find.byKey(
            ValueKey(fund ? 'account_funds_tab' : 'account_certificates_tab'),
          ),
        );
        await tester.pumpAndSettle();
        await waitFor(tester, find.byType(DropdownButtonFormField<String>));
      }

      Future<void> confirm(String token, String label) async {
        await tester.enterText(find.byType(TextFormField).last, token);
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byType(CheckboxListTile));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(Checkbox).hitTestable().last);
        await tap(tester, label);
        await waitFor(tester, find.text('Investment operation completed'));
      }

      await signIn('mariaminvestor', 'Fictional#Investor0910');
      await section(false);
      expect(find.text('My certificates'), findsOneWidget);
      final mariam = await sl<InvestmentRepository>().holdings();
      expect(
        mariam.where((h) => h.text('product_type') == 'certificate').length,
        2,
      );
      expect(mariam.where((h) => h.text('product_type') == 'fund').length, 1);
      await section(true);
      expect(find.text('My fund holdings'), findsOneWidget);
      await signIn('tarekinvestor', 'Fictional#Investor0911');
      await section(false);
      final tarek = await sl<InvestmentRepository>().holdings();
      expect(
        tarek.where((h) => h.text('product_type') == 'certificate').length,
        2,
      );
      await section(true);
      expect(find.text('My fund holdings'), findsOneWidget);
      for (final fund in [false, true]) {
        final username = fund ? 'salmanabil' : 'omarsherif';
        final password = fund ? 'Salma#2026' : 'Omar#2026';
        final account = fund ? '0103' : '0104';
        await signIn(username, password);
        await section(fund);
        final products = fund
            ? ['Income investment fund', 'Growth investment fund']
            : [
                'Three-year certificate',
                'Four-year certificate',
                'Five-year certificate',
                'Seven-year certificate',
              ];
        for (final name in products) {
          debugPrint('DEVICE_QA: subscription and redemption: $name');
          await tester.tap(find.byType(DropdownButtonFormField<String>).first);
          await tester.pumpAndSettle();
          final option = find.text(name).last;
          await tester.ensureVisible(option);
          await tester.tap(option);
          await tester.pumpAndSettle();
          await tester.ensureVisible(
            find.byType(DropdownButtonFormField<String>).at(1),
          );
          await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
          await tester.pumpAndSettle();
          await tester.tap(
            find.text('**** **** $account • EGP').hitTestable().last,
          );
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byType(TextFormField).last,
            name == 'Four-year certificate' ? '10000' : '1000',
          );
          await tap(tester, 'Subscribe');
          await waitFor(tester, find.text('Review investment operation'));
          await confirm(await stepUp(tester, password), 'Subscribe');
          await tap(tester, 'Done');
          await waitFor(tester, find.text('Redeem / break'));
          await tap(tester, 'Redeem / break');
          await waitFor(tester, find.text('Review investment operation'));
          expect(
            find.text(
              'Early redemption deduction: ${fund
                  ? '0.00'
                  : name == 'Four-year certificate'
                  ? '500.00'
                  : '50.00'} EGP',
            ),
            findsOneWidget,
          );
          await confirm(await stepUp(tester, password), 'Redeem / break');
          await tap(tester, 'Done');
          await waitFor(
            tester,
            find.text(fund ? 'My fund holdings' : 'My certificates'),
          );
        }
      }
      await tap(tester, 'More');
      await tap(tester, 'Currency exchange rates');
      await waitFor(tester, find.text('USD · US dollar'));
      expect(find.text('SAR · Saudi riyal'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.textContaining('simulated spread'),
        350,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('simulated spread'), findsOneWidget);
      await sl<LanguageCubit>().change('ar');
      await tester.pumpAndSettle();
      expect(
        Directionality.of(tester.element(find.byType(Scaffold).last)),
        TextDirection.rtl,
      );
      await tester.tap(
        find.byTooltip(
          MaterialLocalizations.of(tester.element(find.byType(Scaffold).last))
              .backButtonTooltip,
        ),
      );
      await tester.pumpAndSettle();
      await sl<LanguageCubit>().change('en');
      sl<AuthBloc>().add(const AuthLogoutRequested());
      await waitFor(tester, find.text('Sign in'));
      await openSignIn(tester);
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(minutes: 8)),
  );
}
