import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:faisal_app/core/security/session_store.dart';
import 'package:faisal_app/core/theme/app_theme.dart';
import 'package:faisal_app/core/widgets/faisal_logo.dart';
import 'package:faisal_app/core/widgets/card_artwork.dart';
import 'package:faisal_app/features/home/presentation/widgets/home_header.dart';
import 'package:faisal_app/features/authentication/domain/entities/auth_entities.dart';
import 'package:faisal_app/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:faisal_app/features/authentication/presentation/bloc/auth_state.dart';
import 'package:faisal_app/features/banks/domain/entities/bank_definition.dart';
import 'package:faisal_app/features/banks/domain/entities/bank_catalogue.g.dart';
import 'package:faisal_app/features/banks/domain/repositories/bank_catalogue_repository.dart';
import 'package:faisal_app/features/banks/presentation/bank_catalogue_cubit.dart';
import 'package:faisal_app/features/banks/presentation/bank_selector.dart';
import 'package:faisal_app/features/branding/domain/entities/branding_config.dart';
import 'package:faisal_app/features/branding/presentation/widgets/branding_scope.dart';
import 'package:faisal_app/features/branding/presentation/widgets/customer_appearance.dart';
import 'package:faisal_app/features/settings/presentation/cubit/appearance_cubits.dart';
import 'package:faisal_app/l10n/app_localizations.dart';

import 'security_flows_test.dart' as fixtures;

class CatalogueRepository extends BankCatalogueRepository {
  int calls = 0;
  Completer<BankCatalogue?>? result;
  bool offline = false;
  @override
  Future<BankCatalogue?> fetch({String? knownVersion}) async {
    calls++;
    if (offline) {
      throw Exception('offline');
    }
    return result?.future;
  }
}

class BankAuth extends AuthBloc {
  BankAuth(String code, {bool staff = false})
    : super(fixtures.FakeAuth(), SessionStore()) {
    emit(
      AuthState(
        status: AuthStatus.authenticated,
        user: SessionUser(
          id: 'bank-customer',
          maskedIdentifier: '***',
          loginType: staff ? 'staff' : 'customer',
          mustChangePassword: false,
          profile: CustomerProfileEntity(
            id: 'profile',
            customerNumber: '***',
            firstNameEn: 'QA',
            lastNameEn: 'Customer',
            firstNameAr: 'عميل',
            lastNameAr: 'تجريبي',
            bankCode: code,
          ),
        ),
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('37 distinct reviewed bank presets validate for Arabic and English', () {
    final banks = BankCatalogue.bundled.banks;
    expect(banks.length, 37);
    expect(banks.map((b) => '${b.primary}-${b.accent}').toSet().length, 37);
    for (final bank in banks) {
      expect(bank.name('ar'), isNotEmpty);
      expect(bank.name('en'), isNotEmpty);
      expect(BrandingConfig.defaults.forBank(bank).customTheme, isTrue);
      final gradient = cardGradient(
        'gold',
        primary: BrandingConfig.parseColor(bank.primary),
        accent: BrandingConfig.parseColor(bank.accent),
      );
      expect(
        gradient.colors.every(
          (c) => BrandingConfig.contrastRatio(Colors.white, c) >= 4.5,
        ),
        isTrue,
      );
    }
    expect(banks.where((b) => b.registrationEnabled).length, 35);
  });
  test('old cached names logos and colors never override fixed identity', () {
    final value = BrandingConfig.defaults.toJson();
    value['application_name'] = 'Old name';
    value['logo_url'] = '/branding/assets/${'a' * 64}.png';
    value['custom_theme'] = true;
    value['light']['primary'] = '#1D4ED8';
    final config = BrandingConfig.fromJson(value);
    expect(config.text('application_name'), isNull);
    expect(config.text('logo_url'), isNull);
    expect(config.customTheme, isFalse);
  });
  test('per-bank appearance isolation and unsafe overrides rejected', () {
    final value = BrandingConfig.defaults.toJson();
    value['bank_overrides'] = {
      'nbe': {'welcome_message': 'NBE only', 'font_size_scale': 1.1},
    };
    final config = BrandingConfig.fromJson(value);
    expect(
      config
          .forBank(BankCatalogue.bundled.find('nbe')!)
          .text('welcome_message'),
      'NBE only',
    );
    expect(
      config
          .forBank(BankCatalogue.bundled.find('cib')!)
          .text('welcome_message'),
      isNull,
    );
    value['bank_overrides'] = {
      'nbe': {'application_name': 'Other name'},
    };
    expect(() => BrandingConfig.fromJson(value), throwsFormatException);
  });
  testWidgets('published bank greeting appears only inside customer header', (
    tester,
  ) async {
    final bank = BankCatalogue.bundled.find('nbe')!;
    final config = BrandingConfig.fromJson({
      ...BrandingConfig.defaults.toJson(),
      'bank_overrides': {
        'nbe': {'welcome_message': 'Published customer greeting'},
      },
    }).forBank(bank);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BrandingScope(
            config: config,
            bank: bank,
            child: HomeHeader(
              greeting: 'Original greeting',
              name: 'Fictional customer',
              unreadCount: 0,
              onNotifications: () {},
              onLogout: () {},
              notificationsTooltip: 'Notifications',
              logoutTooltip: 'Sign out',
            ),
          ),
        ),
      ),
    );
    expect(find.text('Published customer greeting'), findsOneWidget);
    expect(find.text('Original greeting'), findsNothing);
    expect(find.text('Banking App'), findsNothing);
  });
  test(
    'offline bank catalogue uses cache and coalesces refresh requests',
    () async {
      final json = jsonDecode(bankCatalogueJson) as Map<String, dynamic>;
      SharedPreferences.setMockInitialValues({
        BankCatalogueCubit.cacheKey: jsonEncode(json),
      });
      final repository = CatalogueRepository()..offline = true;
      final cubit = BankCatalogueCubit(
        repository,
        await SharedPreferences.getInstance(),
      );
      expect(cubit.state.version, BankCatalogue.bundled.version);
      await cubit.refresh();
      expect(cubit.state.banks.length, 37);
      repository.offline = false;
      repository.result = Completer<BankCatalogue?>();
      final first = cubit.refresh(force: true),
          second = cubit.refresh(force: true);
      expect(repository.calls, 2);
      repository.result!.complete(null);
      await Future.wait([first, second]);
      await cubit.close();
    },
  );
  for (final language in ['en', 'ar']) {
    testWidgets('bank required before card registration in $language', (
      tester,
    ) async {
      final key = GlobalKey<FormState>();
      String? selected;
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(language),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Form(
              key: key,
              child: BankSelector(
                value: null,
                registrationOnly: true,
                onChanged: (v) => selected = v,
              ),
            ),
          ),
        ),
      );
      expect(key.currentState!.validate(), isFalse);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(BankCatalogue.bundled.find('nbe')!.name(language)).last,
      );
      await tester.pumpAndSettle();
      expect(selected, 'nbe');
      expect(key.currentState!.validate(), isTrue);
      expect(tester.takeException(), isNull);
    });
  }
  for (final bank in ['nbe', 'cib', 'banque_misr']) {
    testWidgets(
      'customer bank $bank applies internally with form and router retained',
      (tester) async {
        final auth = BankAuth(bank);
        final theme = ThemeCubit(null, fixtures.FakeSettings());
        addTearDown(() async {
          await auth.close();
          await theme.close();
        });
        late BuildContext pageContext;
        Widget page(BuildContext context) {
          pageContext = context;
          return const Scaffold(
            body: Column(
              children: [
                FaisalLogo(showWordmark: true),
                TextField(key: Key('draft')),
              ],
            ),
          );
        }

        final router = GoRouter(
          initialLocation: '/home',
          routes: [
            GoRoute(path: '/home', builder: (c, s) => page(c)),
            GoRoute(path: '/login', builder: (c, s) => page(c)),
          ],
        );
        var config = BrandingConfig.defaults;
        late StateSetter update;
        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>.value(value: auth),
              BlocProvider<ThemeCubit>.value(value: theme),
            ],
            child: StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return MaterialApp.router(
                  theme: AppTheme.light(),
                  routerConfig: router,
                  builder: (context, child) => CustomerAppearance(
                    published: config,
                    router: router,
                    child: child!,
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        final expected = BrandingConfig.defaults
            .forBank(BankCatalogue.bundled.find(bank)!)
            .color('primary', Brightness.light);
        expect(Theme.of(pageContext).colorScheme.primary, expected);
        await tester.enterText(
          find.byKey(const Key('draft')),
          'Unsubmitted transfer',
        );
        final navigatorState = tester.state(find.byType(Navigator).first);
        update(() {
          config = BrandingConfig.fromJson({
            ...BrandingConfig.defaults.toJson(),
            'bank_overrides': {
              bank: {'welcome_message': 'Published'},
            },
          });
        });
        await tester.pumpAndSettle();
        expect(find.text('Unsubmitted transfer'), findsOneWidget);
        expect(
          tester.state(find.byType(Navigator).first),
          same(navigatorState),
        );
        expect(
          BrandingScope.of(pageContext).text('welcome_message'),
          'Published',
        );
        expect(find.text('Banking App'), findsNothing);
        expect(
          find.text(BankCatalogue.bundled.find(bank)!.name('en')),
          findsOneWidget,
        );
        router.go('/login');
        await tester.pumpAndSettle();
        pageContext = tester.element(find.byKey(const Key('draft')));
        expect(Theme.of(pageContext).colorScheme.primary, expected);
        expect(BrandingScope.bankOf(pageContext)?.code, bank);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        router.dispose();
      },
    );
  }
}
