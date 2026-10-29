import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:faisal_app/main.dart' as app;
import 'package:faisal_app/core/config/app_config.dart';
import 'package:faisal_app/core/di/injector.dart';
import 'package:faisal_app/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:faisal_app/features/authentication/presentation/bloc/auth_event.dart';
import 'package:faisal_app/features/authentication/presentation/bloc/auth_state.dart';
import 'package:faisal_app/features/authentication/presentation/pages/login_page.dart';
import 'package:faisal_app/features/authentication/presentation/pages/registration_page.dart';
import 'package:faisal_app/features/banks/presentation/bank_onboarding_page.dart';
import 'package:faisal_app/features/banks/presentation/bank_selection_cubit.dart';
import 'package:faisal_app/features/banks/presentation/bank_logo.dart';
import 'package:faisal_app/features/branding/presentation/widgets/branding_scope.dart';
import 'package:faisal_app/features/home/presentation/pages/home_page.dart';
import 'package:faisal_app/features/settings/presentation/cubit/appearance_cubits.dart';
import 'package:faisal_app/features/support/presentation/pages/branch_directory_page.dart';
import 'package:faisal_app/features/admin/presentation/pages/admin_dashboard_page.dart';

import 'security_flow_test.dart' as flow;

/// Real API, fresh fictional customers, and private run-as credential staging.
/// No customer records, passwords or native app data are reset.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'three banks: selection, public services, OTP registration and username login',
    (t) async {
      expect(AppConfig.apiBaseUrl.contains(':8017/'), isTrue);
      final credentials = await t.runAsync(() async {
        final file = File(
          '${Directory.systemTemp.parent.path}/files/qa/branding_login.json',
        );
        final value =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        await file.delete();
        return value;
      });
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(BankSelectionCubit.key);
      await preferences.remove(BankSelectionCubit.introductionKey);
      app.main();
      await flow.waitFor(
        t,
        find.byWidgetPredicate(
          (w) =>
              w is BankOnboardingPage ||
              w is LoginPage ||
              w is NavigationBar ||
              w is AdminDashboardPage,
        ),
      );
      sl<AuthBloc>().add(const AuthLogoutRequested());
      await flow.waitFor(t, find.byType(BankOnboardingPage));
      await sl<LanguageCubit>().change('en');
      await sl<ThemeCubit>().change(ThemeMode.light);

      Future<void> shot(String name) async {
        FocusManager.instance.primaryFocus?.unfocus();
        await t.pumpAndSettle();
        debugPrint('ENTRY_SCREENSHOT: $name');
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 1200)),
        );
      }

      Future<void> choose(String code) async {
        await flow.waitFor(t, find.byType(BankOnboardingPage));
        for (
          var i = 0;
          i < 2 &&
              find
                  .byKey(const Key('bank-onboarding-next'))
                  .evaluate()
                  .isNotEmpty;
          i++
        ) {
          await t.tap(find.byKey(const Key('bank-onboarding-next')));
          await t.pumpAndSettle();
        }
        await t.enterText(
          find.byKey(const Key('bank-onboarding-search')),
          code == 'banque_misr' ? 'Misr' : code,
        );
        await t.pumpAndSettle();
        final target = find.byKey(ValueKey('choose-bank-$code'));
        await t.ensureVisible(target);
        await t.tap(target);
        await flow.waitFor(t, find.byType(LoginPage));
        await t.pumpAndSettle();
        expect(
          BrandingScope.bankOf(t.element(find.byType(LoginPage)))?.code,
          code,
        );
        expect(find.byType(TextFormField), findsNWidgets(2));
        expect(find.byType(DropdownButtonFormField<String>), findsNothing);
        expect(find.byType(BankLogo), findsWidgets);
        expect(find.text('Banking App'), findsNothing);
      }

      Future<void> logout() async {
        sl<AuthBloc>().add(const AuthLogoutRequested());
        await flow.waitFor(t, find.byType(LoginPage));
        expect(sl<AuthBloc>().state.status, AuthStatus.unauthenticated);
      }

      Future<void> changeBank(String code) async {
        await flow.tap(t, 'Change bank');
        await choose(code);
      }

      await shot('01_intro');
      final users = <String, String>{};
      for (final raw in credentials!['customers'] as List) {
        final customer = raw as Map<String, dynamic>;
        final bank = customer['bank_code'] as String;
        if (users.isEmpty) {
          await choose(bank);
        } else {
          await logout();
          await changeBank(bank);
        }
        if (users.isEmpty) await shot('02_bank_login');
        if (bank == 'banque_misr') {
          final service = find.byKey(const ValueKey('public_branches'));
          await t.ensureVisible(service);
          await t.tap(service);
          await flow.waitFor(t, find.byType(BranchDirectoryPage));
          await flow.waitFor(t, find.byKey(const ValueKey('branch_count')));
          await t.enterText(
            find.byKey(const ValueKey('branch_search')),
            'Dokki',
          );
          await t.pumpAndSettle();
          expect(find.textContaining('788'), findsNothing);
          await shot('05_misr_branches');
          GoRouter.of(t.element(find.byType(BranchDirectoryPage))).pop();
          await flow.waitFor(t, find.byType(LoginPage));
        }
        await flow.tap(t, 'Register for digital banking');
        await flow.waitFor(t, find.byType(RegistrationPage));
        expect(find.byType(DropdownButtonFormField<String>), findsNothing);
        await t.enterText(
          find.byType(TextFormField).first,
          customer['card'] as String,
        );
        await flow.tap(t, 'Continue');
        await flow.waitFor(
          t,
          find.byKey(const ValueKey('development_otp_code')),
        );
        final otp = t
            .widget<SelectableText>(
              find.byKey(const ValueKey('development_otp_code')),
            )
            .data!;
        expect(otp, matches(RegExp(r'^\d{6}$')));
        await t.enterText(find.byType(TextFormField).first, otp);
        await flow.tap(t, 'Verify code');
        await flow.waitFor(
          t,
          find.byKey(const ValueKey('registration_username')),
        );
        final username =
            'entry${bank.replaceAll('_', '')}${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
        await t.enterText(find.byType(TextFormField).first, username);
        await flow.waitFor(t, find.text('Username is available'));
        await t.enterText(
          find.byType(TextFormField).at(1),
          credentials['customer_password'] as String,
        );
        await t.enterText(
          find.byType(TextFormField).at(2),
          credentials['customer_password'] as String,
        );
        if (users.isEmpty) await shot('03_create_username');
        await flow.tap(t, 'Continue');
        await flow.waitFor(t, find.byType(HomePage));
        await t.pumpAndSettle();
        expect(sl<AuthBloc>().state.user!.profile!.bankCode, bank);
        expect(
          BrandingScope.bankOf(t.element(find.byType(HomePage)))?.code,
          bank,
        );
        expect(find.text('Banking App'), findsNothing);
        users[bank] = username;
        if (users.length == 1) await shot('04_registered_home');
        debugPrint('ENTRY_REGISTERED_BANK: $bank');
      }
      for (final bank in ['nbe', 'cib', 'banque_misr']) {
        await logout();
        await changeBank(bank);
        await t.enterText(find.byType(TextFormField).first, users[bank]!);
        await t.enterText(
          find.byType(TextFormField).at(1),
          credentials['customer_password'] as String,
        );
        await flow.tap(t, 'Sign in');
        await flow.waitFor(t, find.byType(HomePage));
        await t.pumpAndSettle();
        expect(sl<AuthBloc>().state.user!.profile!.bankCode, bank);
        expect(
          BrandingScope.bankOf(t.element(find.byType(HomePage)))?.code,
          bank,
        );
        debugPrint('ENTRY_USERNAME_LOGIN_BANK: $bank');
      }
      await sl<LanguageCubit>().change('ar');
      await sl<ThemeCubit>().change(ThemeMode.dark);
      await t.pumpAndSettle();
      expect(
        Directionality.of(t.element(find.byType(HomePage))),
        TextDirection.rtl,
      );
      await shot('06_arabic_bank_home');
      expect(t.takeException(), isNull);
    },
  );
}
