import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:go_router/go_router.dart';
import 'package:faisal_app/main.dart' as app;
import 'package:faisal_app/core/config/app_config.dart';
import 'package:faisal_app/core/di/injector.dart';
import 'package:faisal_app/core/network/dio_client.dart';
import 'package:faisal_app/core/security/biometric_service.dart';
import 'package:faisal_app/core/security/session_store.dart';
import 'package:faisal_app/features/authentication/domain/entities/saved_bank.dart';
import 'package:faisal_app/features/authentication/domain/repositories/saved_banks_repository.dart';
import 'package:faisal_app/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:faisal_app/features/authentication/presentation/bloc/auth_event.dart';
import 'package:faisal_app/features/authentication/presentation/pages/login_page.dart';
import 'package:faisal_app/features/authentication/presentation/pages/registration_page.dart';
import 'package:faisal_app/features/authentication/presentation/pages/authorization_page.dart';
import 'package:faisal_app/features/authentication/presentation/pages/saved_banks_page.dart';
import 'package:faisal_app/features/banks/presentation/bank_onboarding_page.dart';
import 'package:faisal_app/features/branding/presentation/widgets/branding_scope.dart';
import 'package:faisal_app/features/home/presentation/pages/home_page.dart';
import 'package:faisal_app/features/settings/presentation/pages/profile_page.dart';
import 'package:faisal_app/features/settings/presentation/cubit/appearance_cubits.dart';

import 'security_flow_test.dart' as flow;

/// Opt-in real Android keystore + enrolled emulator fingerprint + isolated API.
/// The host runner supplies private fixtures and sends exactly one finger touch
/// for each explicit SAVED_BIOMETRIC marker, after the system prompt appears.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'saved banks: enrollment, cold bootstrap, scoped fingerprint, switch and logout',
    (t) async {
      expect(AppConfig.apiBaseUrl.contains(':8017/'), isTrue);
      final credentials = await t.runAsync(() async {
        final file = File(
          '${Directory.systemTemp.parent.path}/files/qa/branding_login.json',
        );
        final data =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        await file.delete();
        return data;
      });
      final password = credentials!['customer_password'] as String;
      app.main();
      await flow.waitFor(
        t,
        find.byWidgetPredicate(
          (w) =>
              w is LoginPage ||
              w is SavedBanksPage ||
              w is BankOnboardingPage ||
              w is HomePage,
        ),
      );
      if (sl<AuthBloc>().state.isAuthenticated) {
        sl<AuthBloc>().add(const AuthLogoutRequested());
        await flow.waitFor(
          t,
          find.byWidgetPredicate(
            (w) =>
                w is SavedBanksPage ||
                w is LoginPage ||
                w is BankOnboardingPage,
          ),
        );
      }
      await sl<LanguageCubit>().change('en');
      await sl<ThemeCubit>().change(ThemeMode.light);
      await t.pumpAndSettle();

      Future<void> shot(String name) async {
        FocusManager.instance.primaryFocus?.unfocus();
        await t.pumpAndSettle();
        debugPrint('SAVED_SCREENSHOT: $name');
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 1200)),
        );
      }

      Future<void> park() async {
        sl<AuthBloc>().add(const AuthReturnToBanksRequested());
        await flow.waitFor(t, find.byType(SavedBanksPage));
        expect(sl<SessionStore>().hasSession, isFalse);
      }

      Future<void> openPassword(SavedBank entry) async {
        final button = find.byKey(
          ValueKey('saved-bank-sign-in-${entry.userId}'),
        );
        await t.ensureVisible(button);
        await t.tap(button);
        await flow.waitFor(t, find.byType(LoginPage));
        expect(
          t
              .widget<TextFormField>(find.byType(TextFormField).first)
              .controller!
              .text,
          entry.username,
        );
        expect(
          BrandingScope.bankOf(t.element(find.byType(LoginPage)))!.code,
          entry.bankCode,
        );
        await t.enterText(find.byType(TextFormField).at(1), password);
        await flow.tap(t, 'Sign in');
        await flow.waitFor(t, find.byType(HomePage));
        expect(sl<AuthBloc>().state.user!.id, entry.userId);
        expect(
          BrandingScope.bankOf(t.element(find.byType(HomePage)))!.code,
          entry.bankCode,
        );
      }

      final enrolled = <SavedBank>[];
      for (final raw in credentials['customers'] as List) {
        final fixture = raw as Map<String, dynamic>;
        final bank = fixture['bank_code'] as String;
        await flow.chooseBank(t, bank);
        await flow.tap(t, 'Register for digital banking');
        await flow.waitFor(t, find.byType(RegistrationPage));
        await t.enterText(
          find.byType(TextFormField).first,
          fixture['card'] as String,
        );
        await flow.tap(t, 'Continue');
        await flow.waitFor(t, find.byKey(const Key('development_otp_code')));
        final otp = t
            .widget<SelectableText>(
              find.byKey(const Key('development_otp_code')),
            )
            .data!;
        await t.enterText(find.byType(TextFormField).first, otp);
        await flow.tap(t, 'Verify code');
        await flow.waitFor(t, find.byKey(const Key('registration_username')));
        final username =
            'saved${bank.replaceAll('_', '')}${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
        await t.enterText(find.byType(TextFormField).first, username);
        await flow.waitFor(t, find.text('Username is available'));
        await t.enterText(find.byType(TextFormField).at(1), password);
        await t.enterText(find.byType(TextFormField).at(2), password);
        await flow.tap(t, 'Continue');
        await flow.waitFor(t, find.byType(HomePage));
        expect(sl<AuthBloc>().state.user!.profile!.bankCode, bank);
        enrolled.add(
          sl<SavedBanksRepository>().entries.firstWhere(
            (e) => e.username == username,
          ),
        );
        debugPrint('SAVED_REGISTERED_BANK: $bank');
        await park();
      }
      await shot('01_three_saved_banks');
      for (final entry in enrolled) {
        await openPassword(entry);
        await park();
      }
      final bioEntry = enrolled.firstWhere((e) => e.bankCode == 'cib');
      await openPassword(bioEntry);
      GoRouter.of(t.element(find.byType(HomePage))).go('/profile');
      await flow.waitFor(t, find.byType(SwitchListTile));
      expect(await sl<BiometricService>().available(), isTrue);
      final toggle = find.byType(SwitchListTile).first;
      await t.ensureVisible(toggle);
      await t.tap(toggle);
      await flow.waitFor(t, find.byType(AuthorizationPage));
      await t.enterText(find.byType(TextFormField).last, password);
      await flow.tap(t, 'Authorize operation');
      await flow.waitFor(t, find.text('Copy Token'));
      debugPrint('SAVED_BIOMETRIC: enable');
      await flow.tap(t, 'Continue');
      await flow.waitFor(t, find.textContaining('Biometric re-entry enabled'));
      expect(sl<BiometricService>().enabledFor(bioEntry.userId), isTrue);
      for (final entry in enrolled.where((e) => e != bioEntry)) {
        expect(sl<BiometricService>().enabledFor(entry.userId), isFalse);
      }
      await shot('02_biometric_enabled');

      // Rebuild the real composition root, reloading preferences and keystore;
      // no mocked session store and no application data reset.
      final oldRouter = GoRouter.of(t.element(find.byType(ProfilePage)));
      final oldAuth = sl<AuthBloc>(),
          oldLanguage = sl<LanguageCubit>(),
          oldTheme = sl<ThemeCubit>();
      await t.pumpWidget(const SizedBox());
      oldRouter.dispose();
      await oldAuth.close();
      await oldLanguage.close();
      await oldTheme.close();
      await resetDependencies();
      await app.main();
      await flow.waitFor(t, find.byType(SavedBanksPage));
      await flow.waitFor(t, find.byKey(const Key('saved-banks-add')));
      await t.pumpAndSettle();
      expect(sl<SessionStore>().hasSession, isFalse);
      expect(
        enrolled.every((e) => sl<SavedBanksRepository>().entries.contains(e)),
        isTrue,
      );
      await shot('03_cold_bootstrap_chooser');
      debugPrint('SAVED_BIOMETRIC: sign_in');
      final bioButton = find.byKey(
        ValueKey('saved-bank-sign-in-${bioEntry.userId}'),
      );
      await t.ensureVisible(bioButton);
      await t.tap(bioButton);
      await flow.waitFor(t, find.byType(HomePage));
      expect(sl<AuthBloc>().state.user!.id, bioEntry.userId);
      expect(
        find.text(
          'Your session is locked. Unlock or sign out to use a password.',
        ),
        findsNothing,
      );
      expect(
        BrandingScope.bankOf(t.element(find.byType(HomePage)))!.code,
        'cib',
      );
      final cibAccess = sl<SessionStore>().accessToken!;
      await shot('04_single_fingerprint_cib_home');
      await park();
      await openPassword(enrolled.firstWhere((e) => e.bankCode == 'nbe'));
      await shot('05_nbe_password_switch');
      await park();
      await sl<LanguageCubit>().change('ar');
      await sl<ThemeCubit>().change(ThemeMode.dark);
      await t.pumpAndSettle();
      expect(
        Directionality.of(t.element(find.byType(SavedBanksPage))),
        TextDirection.rtl,
      );
      await shot('06_arabic_dark_chooser');
      await sl<LanguageCubit>().change('en');
      await sl<ThemeCubit>().change(ThemeMode.light);

      // Revoke the saved CIB session through the real backend. A successful
      // fingerprint must still fall back to password, never open a revoked user.
      final token = await sl<SavedBanksRepository>().credential(bioEntry);
      await sl<DioClient>().post(
        '/auth/logout',
        body: {'refresh_token': token, 'all_devices': false},
        headers: {'Authorization': 'Bearer $cibAccess'},
      );
      debugPrint('SAVED_BIOMETRIC: revoked');
      final revoked = find.byKey(
        ValueKey('saved-bank-sign-in-${bioEntry.userId}'),
      );
      await t.ensureVisible(revoked);
      await t.tap(revoked);
      await flow.waitFor(t, find.byType(LoginPage));
      await flow.waitFor(t, find.byType(TextFormField));
      expect(sl<AuthBloc>().state.isAuthenticated, isFalse);
      expect(sl<SessionStore>().hasSession, isFalse);
      expect(await sl<SavedBanksRepository>().credential(bioEntry), isNull);
      await shot('07_revoked_password_fallback');
      expect(t.takeException(), isNull);
    },
  );
}
