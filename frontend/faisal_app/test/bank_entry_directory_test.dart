import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:faisal_app/core/di/injector.dart';
import 'package:faisal_app/core/routing/app_routes.dart';
import 'package:faisal_app/core/routing/route_guard.dart';
import 'package:faisal_app/core/security/session_store.dart';
import 'package:faisal_app/core/theme/app_theme.dart';
import 'package:faisal_app/core/utils/password_policy.dart';
import 'package:faisal_app/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:faisal_app/features/authentication/presentation/bloc/auth_state.dart';
import 'package:faisal_app/features/authentication/presentation/pages/login_page.dart';
import 'package:faisal_app/features/banks/domain/entities/bank_definition.dart';
import 'package:faisal_app/features/banks/presentation/bank_catalogue_cubit.dart';
import 'package:faisal_app/features/banks/presentation/bank_selection_cubit.dart';
import 'package:faisal_app/features/banks/presentation/bank_onboarding_page.dart';
import 'package:faisal_app/features/banks/presentation/bank_logo.dart';
import 'package:faisal_app/features/branding/domain/entities/branding_config.dart';
import 'package:faisal_app/features/branding/presentation/widgets/branding_scope.dart';
import 'package:faisal_app/features/branding/presentation/widgets/customer_appearance.dart';
import 'package:faisal_app/features/settings/presentation/cubit/appearance_cubits.dart';
import 'package:faisal_app/features/support/data/repositories/bank_directory_repository_impl.dart';
import 'package:faisal_app/features/support/domain/entities/bank_directory.dart';
import 'package:faisal_app/features/support/domain/repositories/bank_directory_repository.dart';
import 'package:faisal_app/features/support/presentation/pages/bank_services_gate.dart';
import 'package:faisal_app/features/support/presentation/services/bank_contact_links.dart';
import 'package:faisal_app/features/products/domain/repositories/discover_repository.dart';
import 'package:faisal_app/l10n/app_localizations.dart';

import 'bank_appearance_test.dart' as banks;
import 'security_flows_test.dart' as fixtures;
import 'admin_workflow_test.dart' as admin;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() async => sl.reset());
  test(
    'selection restores offline and rejects unknown bank preferences',
    () async {
      SharedPreferences.setMockInitialValues({
        BankSelectionCubit.key: 'unknown',
      });
      final prefs = await SharedPreferences.getInstance();
      final selected = BankSelectionCubit(prefs);
      expect(selected.state, isNull);
      await selected.select('cib');
      final restored = BankSelectionCubit(prefs);
      expect(restored.state, 'cib');
      expect(restored.introductionSeen, isTrue);
      expect(() => restored.select('unknown'), throwsArgumentError);
      await selected.close();
      await restored.close();
    },
  );
  test(
    'first launch requires bank choice and preserves mandatory first login',
    () {
      expect(
        resolveRedirect(
          auth: const AuthState(status: AuthStatus.unauthenticated),
          location: AppRoutes.login,
          hasSelectedBank: false,
        ),
        AppRoutes.onboarding,
      );
      expect(
        resolveRedirect(
          auth: const AuthState(status: AuthStatus.firstLoginRequired),
          location: AppRoutes.onboarding,
          hasSelectedBank: false,
        ),
        AppRoutes.passwordSetup,
      );
      expect(validateUsernameField('client26'), isNull);
      for (final value in [
        '4000000000000102',
        'user.name',
        'user-name',
        'user_name',
        '1user',
      ]) {
        expect(validateUsernameField(value), 'invalid');
      }
    },
  );
  for (final language in ['en', 'ar']) {
    for (final dark in [false, true]) {
      testWidgets(
        'intro then bank choice opens themed username login and services $language dark=$dark',
        (t) async {
          SharedPreferences.setMockInitialValues({});
          final selection = BankSelectionCubit(
            await SharedPreferences.getInstance(),
          );
          final catalogue = BankCatalogueCubit(
            banks.CatalogueRepository(),
            null,
          );
          final auth = AuthBloc(fixtures.FakeAuth(), SessionStore());
          final theme = ThemeCubit(null, fixtures.FakeSettings());
          final locale = LanguageCubit(null, fixtures.FakeSettings());
          addTearDown(() async {
            await auth.close();
            await theme.close();
            await locale.close();
          });
          sl.registerSingleton<BankSelectionCubit>(
            selection,
            dispose: (c) => c.close(),
          );
          sl.registerSingleton<BankCatalogueCubit>(
            catalogue,
            dispose: (c) => c.close(),
          );
          sl.registerSingleton<DiscoverRepository>(
            admin.PublicRepository()..empty = true,
          );
          final directories = BankDirectoryRepositoryImpl();
          // Preload real bundled IO outside the fake clock; assertions still
          // exercise the production repository, controller and service pages.
          await t.runAsync(() => directories.loadDirectory('cib'));
          sl.registerSingleton<BankDirectoryRepository>(directories);
          sl.registerSingleton<BankContactLinks>(BankContactLinks());
          await locale.change(language);
          await theme.change(dark ? ThemeMode.dark : ThemeMode.light);
          final router = GoRouter(
            initialLocation: AppRoutes.onboarding,
            routes: [
              GoRoute(
                path: AppRoutes.onboarding,
                builder: (_, _) => const BankOnboardingPage(),
              ),
              GoRoute(
                path: AppRoutes.login,
                builder: (_, _) => const LoginPage(),
              ),
              GoRoute(
                path: AppRoutes.branches,
                builder: (_, _) =>
                    const BankServicesGate(kind: BankServiceKind.branches),
              ),
              GoRoute(
                path: AppRoutes.atms,
                builder: (_, _) =>
                    const BankServicesGate(kind: BankServiceKind.atms),
              ),
              GoRoute(
                path: AppRoutes.callCenter,
                builder: (_, _) =>
                    const BankServicesGate(kind: BankServiceKind.callCenter),
              ),
            ],
          );
          await t.pumpWidget(
            MultiBlocProvider(
              providers: [
                BlocProvider<AuthBloc>.value(value: auth),
                BlocProvider<ThemeCubit>.value(value: theme),
                BlocProvider<LanguageCubit>.value(value: locale),
              ],
              child: MaterialApp.router(
                locale: Locale(language),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                theme: dark ? AppTheme.dark() : AppTheme.light(),
                routerConfig: router,
                builder: (context, child) => CustomerAppearance(
                  published: BrandingConfig.defaults,
                  router: router,
                  child: child!,
                ),
              ),
            ),
          );
          await t.pumpAndSettle();
          expect(find.byKey(const Key('bank-onboarding-next')), findsOneWidget);
          final introIcon = t.widget<Icon>(
            find.byIcon(Icons.account_balance_wallet_outlined).first,
          );
          final introContext = t.element(find.byType(BankOnboardingPage));
          expect(
            BrandingConfig.contrastRatio(
              introIcon.color!,
              Theme.of(introContext).colorScheme.primaryContainer,
            ),
            greaterThanOrEqualTo(4.5),
          );
          for (var i = 0; i < 2; i++) {
            await t.tap(find.byKey(const Key('bank-onboarding-next')));
            await t.pumpAndSettle();
          }
          await t.enterText(
            find.byKey(const Key('bank-onboarding-search')),
            'CIB',
          );
          await t.pumpAndSettle();
          await t.tap(find.byKey(const Key('choose-bank-cib')));
          await t.pumpAndSettle();
          expect(
            router.routeInformationProvider.value.uri.path,
            AppRoutes.login,
          );
          expect(selection.state, 'cib');
          expect(find.byType(TextFormField), findsNWidgets(2));
          expect(find.byType(DropdownButtonFormField<String>), findsNothing);
          expect(find.byType(BankLogo), findsOneWidget);
          expect(find.text('Banking App'), findsNothing);
          expect(find.textContaining('username, card'), findsNothing);
          final context = t.element(find.byType(LoginPage));
          expect(BrandingScope.bankOf(context)?.code, 'cib');
          expect(
            Directionality.of(context),
            language == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          );
          for (final key in [
            'public_branches',
            'public_atms',
            'public_call_center',
          ]) {
            final target = find.byKey(ValueKey(key));
            await t.ensureVisible(target);
            await t.tap(target);
            await t.pumpAndSettle();
            expect(find.text('19851'), findsNothing);
            expect(find.textContaining('الجيزة'), findsNothing);
            router.pop();
            await t.pumpAndSettle();
          }
          await t.pumpWidget(const SizedBox());
          await t.pumpAndSettle();
          router.dispose();
        },
      );
    }
  }
  testWidgets('all 37 official artwork assets render without failures', (
    t,
  ) async {
    for (final bank in BankCatalogue.bundled.banks) {
      expect(bank.logoAsset, isNotNull);
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(body: BankLogo(bank: bank)),
        ),
      );
      await t.pumpAndSettle();
      expect(t.takeException(), isNull, reason: bank.code);
    }
  });
  testWidgets(
    'offline directories retain bank affiliation, maps and distinct branch/ATM lists',
    (t) async {
      await t.runAsync(() async {
        final repo = BankDirectoryRepositoryImpl();
        final faisal = await repo.loadDirectory('faisal');
        final misr = await repo.loadDirectory('banque_misr');
        expect(faisal.branches.length, 44);
        expect(faisal.atms.length, greaterThan(300));
        expect(misr.branches.length, greaterThan(700));
        expect(misr.atms.length, greaterThan(4000));
        expect(
          misr.branches.every((b) => b.id.startsWith('banque_misr-')),
          isTrue,
        );
        final json = jsonDecode(
          await rootBundle.loadString(
            'assets/data/bank_directories/faisal.json',
          ),
        ) as Map<String, dynamic>;
        expect(
          () => BankDirectory.fromJson(json, 'cib'),
          throwsFormatException,
        );
        (json['branches'] as List).first['maps_url'] =
            'https://example.invalid';
        expect(
          () => BankDirectory.fromJson(json, 'faisal'),
          throwsFormatException,
        );
        final cib = await repo.loadDirectory('cib');
        expect(cib.branches, isEmpty);
        expect(cib.branchesStatus, 'unavailable');
        expect(cib.hotline, '19666');
      });
    },
  );
}
