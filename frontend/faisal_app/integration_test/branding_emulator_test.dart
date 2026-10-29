import 'package:faisal_app/features/banks/presentation/bank_onboarding_page.dart';
import 'package:faisal_app/features/authentication/presentation/pages/login_page.dart';

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:go_router/go_router.dart';
import 'package:faisal_app/main.dart' as app;
import 'package:faisal_app/core/config/app_config.dart';
import 'package:faisal_app/core/di/injector.dart';
import 'package:faisal_app/core/widgets/faisal_logo.dart';
import 'package:faisal_app/features/admin/presentation/pages/admin_dashboard_page.dart';
import 'package:faisal_app/features/authentication/presentation/pages/registration_page.dart';
import 'package:faisal_app/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:faisal_app/features/authentication/presentation/bloc/auth_event.dart';
import 'package:faisal_app/features/banks/domain/entities/bank_definition.dart';
import 'package:faisal_app/features/branding/domain/entities/branding_config.dart';
import 'package:faisal_app/features/branding/domain/repositories/branding_repository.dart';
import 'package:faisal_app/features/branding/presentation/cubit/branding_cubit.dart';
import 'package:faisal_app/features/branding/presentation/pages/admin_branding_page.dart';
import 'package:faisal_app/features/branding/presentation/widgets/branding_preview.dart';
import 'package:faisal_app/features/home/presentation/pages/home_page.dart';
import 'package:faisal_app/features/settings/presentation/cubit/appearance_cubits.dart';

import 'security_flow_test.dart' as flow;

/// Explicit private QA credentials; no production/demo publication or resets.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'fixed identity, bank admin publishing and three real bank registrations',
    (tester) async {
      expect(AppConfig.apiBaseUrl.contains(':8017/'), isTrue);
      final credentials = await tester.runAsync(() async {
        final file = File(
          '${Directory.systemTemp.parent.path}/files/qa/branding_login.json',
        );
        final value =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        await file.delete();
        return value;
      });
      Future<void> screenshot(String name) async {
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        debugPrint('BRANDING_SCREENSHOT: $name');
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(seconds: 2)),
        );
      }

      Future<void> selectBank(String code) async {
        if (find.byType(RegistrationPage).evaluate().isNotEmpty) return;
        if (find.byType(AdminBrandingPage).evaluate().isEmpty) {
          await flow.chooseBank(tester, code);
          return;
        }
        final picker = find.byType(DropdownButtonFormField<String>).first;
        await tester.ensureVisible(picker);
        await tester.tap(picker);
        await tester.pumpAndSettle();
        final target = find
            .text(BankCatalogue.bundled.find(code)!.name('en'))
            .last;
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
        await tester.tap(target);
        await tester.pumpAndSettle();
      }

      Future<void> logout() async {
        sl<AuthBloc>().add(const AuthLogoutRequested());
        await flow.waitFor(
          tester,
          find.byWidgetPredicate(
            (w) => w is LoginPage || w is BankOnboardingPage,
          ),
        );
        await flow.openSignIn(tester);
        await tester.pumpAndSettle();
      }

      app.main();
      await flow.waitFor(tester, find.byWidgetPredicate(flow.isStartupPage));
      await sl<LanguageCubit>().change('en');
      await sl<ThemeCubit>().change(ThemeMode.light);
      await logout();
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
      await flow.tap(tester, 'Settings');
      await flow.tap(tester, 'Bank appearance settings');
      await flow.waitFor(tester, find.byType(BrandingPreview));
      expect(find.byType(AdminBrandingPage), findsOneWidget);
      final repository = sl<BrandingRepository>();
      var doc = await repository.editor();
      final beforeVersion = doc.active.version;
      final greeting = 'Welcome to your NBE simulation ${beforeVersion + 1}';
      await selectBank('nbe');
      final welcome = find.byWidgetPredicate(
        (w) =>
            w is TextFormField &&
            w.key.toString().contains('nbe-welcome_message'),
      );
      await tester.ensureVisible(welcome);
      await tester.enterText(welcome, greeting);
      await flow.tap(tester, 'Save draft');
      await flow.waitFor(
        tester,
        find.text('Draft saved. Live branding is unchanged.'),
      );
      expect((await repository.editor()).active.version, beforeVersion);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is TextField &&
              w.decoration?.labelText == 'Application display name',
        ),
        findsNothing,
      );
      await tester.ensureVisible(find.byType(BrandingPreview));
      await screenshot('01_saved_draft_en');
      await flow.tap(tester, 'Publish changes');
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK').last);
      await flow.waitFor(tester, find.text('Branding published successfully.'));
      doc = await repository.editor();
      expect(doc.active.version, greaterThan(beforeVersion));
      expect(doc.active.config.text('application_name'), isNull);
      expect(
        doc.active.config
            .forBank(BankCatalogue.bundled.find('nbe')!)
            .text('welcome_message'),
        greeting,
      );
      expect(
        doc.active.config
            .forBank(BankCatalogue.bundled.find('cib')!)
            .text('welcome_message'),
        isNull,
      );
      await tester.ensureVisible(find.byType(BrandingPreview));
      await screenshot('02_published_en');
      final dark = find.descendant(
        of: find.byType(SegmentedButton<bool>),
        matching: find.byIcon(Icons.dark_mode_outlined),
      );
      await tester.ensureVisible(dark);
      await tester.tap(dark);
      await sl<LanguageCubit>().change('ar');
      await tester.pumpAndSettle();
      await screenshot('03_ar_dark');
      await sl<LanguageCubit>().change('en');
      await sl<ThemeCubit>().change(ThemeMode.light);
      final customers = credentials['customers'] as List;
      final usernames = <String, String>{};
      for (var index = 0; index < customers.length; index++) {
        final customer = customers[index] as Map<String, dynamic>;
        final code = customer['bank_code'] as String;
        await logout();
        await selectBank(code);
        expect(find.text('Banking App'), findsNothing);
        expect(
          Theme.of(tester.element(find.byType(FaisalLogo).first))
              .colorScheme
              .primary,
          BrandingConfig.defaults
              .forBank(BankCatalogue.bundled.find(code)!)
              .color('primary', Brightness.light),
        );
        if (index == 0) {
          await screenshot('08_fixed_login');
        }
        await flow.tap(tester, 'Register for digital banking');
        await flow.waitFor(tester, find.byType(RegistrationPage));
        await selectBank(code);
        await tester.enterText(
          find.byType(TextFormField).first,
          customer['card'] as String,
        );
        if (index == 0) {
          await screenshot('04_registration');
        }
        await flow.tap(tester, 'Continue');
        await flow.waitFor(
          tester,
          find.byKey(const ValueKey('development_otp_code')),
        );
        final otp = tester
            .widget<SelectableText>(
              find.byKey(const ValueKey('development_otp_code')),
            )
            .data!;
        await tester.enterText(find.byType(TextFormField).first, otp);
        await flow.tap(tester, 'Verify code');
        await flow.waitFor(
          tester,
          find.byKey(const ValueKey('registration_username')),
        );
        await tester.enterText(
          find.byType(TextFormField).first,
          'qa${code.replaceAll('_', '')}${customer['card'].toString().substring(12)}',
        );
        await flow.waitFor(tester, find.text('Username is available'));
        await tester.enterText(
          find.byType(TextFormField).at(1),
          credentials['customer_password'] as String,
        );
        await tester.enterText(
          find.byType(TextFormField).at(2),
          credentials['customer_password'] as String,
        );
        await flow.tap(tester, 'Continue');
        await flow.waitFor(tester, find.byType(HomePage));
        await tester.pumpAndSettle();
        expect(sl<AuthBloc>().state.user!.profile!.bankCode, code);
        usernames[code] = sl<AuthBloc>().state.user!.username!;
        final context = tester.element(find.byType(HomePage));
        expect(
          Theme.of(context).colorScheme.primary,
          BrandingConfig.defaults
              .forBank(BankCatalogue.bundled.find(code)!)
              .color('primary', Brightness.light),
        );
        expect(find.text('Banking App'), findsNothing);
        if (code == 'nbe') {
          expect(find.text(greeting), findsOneWidget);
        }
        await screenshot(
          ['05_nbe_home', '06_cib_home', '07_banque_misr_home'][index],
        );
      }
      // The same installation can switch independent usernames across banks.
      // The backend identity, never the previous session/picker alone, owns theme.
      for (final code in ['nbe', 'cib', 'banque_misr', 'nbe']) {
        await logout();
        await selectBank(code);
        await tester.enterText(
          find.byType(TextFormField).first,
          usernames[code]!,
        );
        await tester.enterText(
          find.byType(TextFormField).at(1),
          credentials['customer_password'] as String,
        );
        await flow.tap(tester, 'Sign in');
        await flow.waitFor(tester, find.byType(HomePage));
        await tester.pumpAndSettle();
        expect(sl<AuthBloc>().state.user!.profile!.bankCode, code);
        final context = tester.element(find.byType(HomePage));
        expect(
          Theme.of(context).colorScheme.primary,
          BrandingConfig.defaults
              .forBank(BankCatalogue.bundled.find(code)!)
              .color('primary', Theme.of(context).brightness),
        );
      }
      debugPrint('BANK_SWITCHING_VERIFIED: nbe cib banque_misr nbe');
      final router = GoRouter.of(tester.element(find.byType(HomePage)));
      for (final path in ['/accounts', '/cards', '/profile']) {
        router.go(path);
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, path);
        expect(tester.takeException(), isNull);
      }
      router.go('/home');
      await tester.pumpAndSettle();
      {
        await sl<LanguageCubit>().change('ar');
        await sl<ThemeCubit>().change(ThemeMode.dark);
        await tester.pumpAndSettle();
        await screenshot('09_nbe_dark_ar');
        expect(
          Directionality.of(tester.element(find.byType(HomePage))),
          TextDirection.rtl,
        );
        await sl<LanguageCubit>().change('en');
        await sl<ThemeCubit>().change(ThemeMode.light);
      }
      // Leave disposable QA at defaults; persistent demo was never published.
      await logout();
      await tester.enterText(
        find.byType(TextFormField).first,
        credentials['username'] as String,
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        credentials['password'] as String,
      );
      await flow.tap(tester, 'Sign in');
      await flow.waitFor(tester, find.byType(AdminDashboardPage));
      doc = await repository.editor();
      doc = await repository.restore(doc.revision);
      await repository.publish(doc.revision);
      await sl<BrandingCubit>().refresh(force: true);
      expect(
        (await repository.editor()).active.config,
        BrandingConfig.defaults,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
