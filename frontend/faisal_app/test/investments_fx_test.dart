import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:faisal_app/core/di/injector.dart';
import 'package:faisal_app/core/theme/app_theme.dart';
import 'package:faisal_app/l10n/app_localizations.dart';
import 'package:faisal_app/features/accounts/domain/repositories/accounts_repository.dart';
import 'package:faisal_app/features/accounts/presentation/pages/accounts_page.dart';
import 'package:faisal_app/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:faisal_app/features/products/domain/entities/investment_entities.dart';
import 'package:faisal_app/features/products/domain/repositories/investment_repository.dart';
import 'package:faisal_app/features/products/presentation/cubit/investments_cubit.dart';
import 'package:faisal_app/features/products/presentation/cubit/exchange_rates_cubit.dart';
import 'package:faisal_app/features/products/presentation/pages/investments_page.dart';
import 'package:faisal_app/features/products/presentation/pages/exchange_rates_page.dart';

import 'security_flows_test.dart' as fixtures;

class FakeInvestments implements InvestmentRepository {
  bool fail = false;
  final keys = <String>[];
  final actions = <Map<String, dynamic>>[];
  Completer<ExchangeRates>? pending;
  @override
  Future<List<InvestmentRecord>> products() async => [
    InvestmentRecord({
      'id': 'cert',
      'product_type': 'certificate',
      'name_en': 'Three-year certificate',
      'name_ar': 'الشهادة الثلاثية',
      'minimum_amount': '10.00',
      'amount_step': '10.00',
      'unit_price': '1.00',
      'max_penalty_percent': '5.00',
    }),
    InvestmentRecord({
      'id': 'fund',
      'product_type': 'fund',
      'name_en': 'Growth fund',
      'name_ar': 'صندوق النمو',
      'minimum_amount': '10.00',
      'amount_step': '10.00',
      'unit_price': '1.00',
      'max_penalty_percent': '0.00',
    }),
  ];
  @override
  Future<List<InvestmentRecord>> holdings() async => [
    InvestmentRecord({
      'id': 'holding',
      'product_type': 'certificate',
      'name_en': 'My certificate',
      'name_ar': 'شهادتي',
      'status': 'active',
      'principal': '1000.00',
      'units': '1000',
      'matures_at': '2029-10-25T12:00:00Z',
    }),
    InvestmentRecord({
      'id': 'fund-holding',
      'product_type': 'fund',
      'name_en': 'My fund',
      'name_ar': 'صندوقي',
      'status': 'active',
      'principal': '1000.00',
      'units': '10',
    }),
  ];
  @override
  Future<InvestmentRecord> quote(Map<String, dynamic> action) async {
    if (fail) throw fixtures.failure;
    return InvestmentRecord({
      'action': action['action'],
      'name_en': 'Reviewed certificate',
      'name_ar': 'الشهادة المحددة',
      'account_label': '***0010',
      'principal': action['amount'] ?? '1000.00',
      'penalty': '50.00',
      'net_credit': '950.00',
    });
  }

  @override
  Future<InvestmentRecord> execute(
    Map<String, dynamic> action,
    String token,
    String retryKey,
  ) async {
    keys.add(retryKey);
    actions.add(action);
    if (fail) throw fixtures.failure;
    return InvestmentRecord({
      'reference': 'INV-RECEIPT',
      'status': 'posted',
      'name_en': 'Certificate',
      'name_ar': 'شهادة',
      'amount': '950.00',
      'penalty': '50.00',
      'timestamp': '2026-10-25T12:00:00Z',
      'account_label': '***0010',
    });
  }

  @override
  Future<ExchangeRates> exchangeRates() async {
    if (pending != null) return pending!.future;
    if (fail) throw fixtures.failure;
    return ExchangeRates({
      'provider_updated_at': '2026-10-25T12:00:00Z',
      'fetched_at': '2026-10-25T12:15:00Z',
      'delay_seconds': 900,
      'spread_bps': 100,
      'stale': true,
      'market_session': 'weekend',
      'quotes': [
        for (final code in ['USD', 'SAR'])
          {
            'currency': code,
            'mid': '50.00',
            'buy': '49.75',
            'sell': '50.25',
            'updated_at': '2026-10-25T12:00:00Z',
            'source': 'ecb_daily',
            'stale': true,
          },
      ],
    });
  }
}

void main() {
  late FakeInvestments repository;
  setUp(() {
    repository = FakeInvestments();
    sl.registerSingleton<InvestmentRepository>(repository);
    sl.registerSingleton<AccountsRepository>(fixtures.FakeAccounts());
    sl.registerFactory(() => AccountsCubit(sl<AccountsRepository>()));
  });
  tearDown(() => sl.reset());
  Future<void> pump(WidgetTester t, Widget page, {String locale = 'en'}) async {
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: page,
      ),
    );
    await t.pumpAndSettle();
  }

  Future<void> tap(WidgetTester t, String text) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await t.pumpAndSettle();
    final target = find.text(text).last;
    await t.ensureVisible(target);
    await t.pumpAndSettle();
    await t.tap(target);
    await t.pumpAndSettle();
  }

  test(
    'subscription quote freezes details and retry keeps the same key',
    () async {
      final c = InvestmentsCubit(repository, fixtures.FakeAccounts());
      await c.load();
      expect(c.state.accounts.length, 2);
      final action = {
        'action': 'subscribe',
        'product_id': 'cert',
        'account_id': '0010',
        'amount': '10.00',
      };
      await c.review(action);
      action['amount'] = '999.00';
      repository.fail = true;
      await c.submit('token');
      expect(c.state.error, isNotNull);
      repository.fail = false;
      await c.submit('token');
      expect(repository.keys[0], repository.keys[1]);
      expect(repository.actions.last['amount'], '10.00');
      expect(c.state.receipt!.text('status'), 'posted');
      await c.close();
    },
  );
  testWidgets(
    'subscription validates minimum, selects owned account and displays review',
    (t) async {
      await pump(t, const InvestmentsPage());
      await t.tap(find.byType(DropdownButtonFormField<String>).first);
      await t.pumpAndSettle();
      await t.tap(find.text('Three-year certificate').last);
      await t.pumpAndSettle();
      await t.tap(find.byType(DropdownButtonFormField<String>).at(1));
      await t.pumpAndSettle();
      expect(find.textContaining('0030'), findsNothing);
      await t.tap(find.text('***0010 • EGP').last);
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextFormField).last, '5');
      await tap(t, 'Subscribe');
      expect(
        find.textContaining('Use the minimum subscription'),
        findsOneWidget,
      );
      await t.enterText(find.byType(TextFormField).last, '20');
      await tap(t, 'Subscribe');
      expect(find.text('Review investment operation'), findsOneWidget);
      expect(find.text('Total debit: 20 EGP'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'redemption review requires token and explicit confirmation; retry produces receipt',
    (t) async {
      await pump(t, const InvestmentsPage());
      await tap(t, 'Redeem / break');
      expect(
        find.text('Net amount returned to your account: 950.00 EGP'),
        findsOneWidget,
      );
      await t.enterText(find.byType(TextFormField).last, 'backend-test-token');
      repository.fail = true;
      await t.ensureVisible(find.byType(CheckboxListTile));
      await t.pumpAndSettle();
      await t.tap(find.byType(CheckboxListTile));
      await t.pumpAndSettle();
      await tap(t, 'Redeem / break');
      expect(find.text('INV-RECEIPT'), findsNothing);
      repository.fail = false;
      await tap(t, 'Redeem / break');
      expect(repository.keys[0], repository.keys[1]);
      expect(find.text('Investment operation completed'), findsOneWidget);
      expect(find.text('INV-RECEIPT'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    },
  );
  test('FX handles loading, failures and cached data', () async {
    final c = ExchangeRatesCubit(repository);
    repository.pending = Completer();
    final request = c.load();
    expect(c.state.loading, true);
    repository.pending!.completeError(fixtures.failure);
    await request;
    expect(c.state.error, isNotNull);
    repository.pending = null;
    await c.load();
    expect(c.state.rates!.rates.length, 2);
    repository.fail = true;
    await c.load();
    expect(c.state.rates, isNotNull);
    expect(c.state.error, isNotNull);
    await c.close();
  });
  for (final locale in ['en', 'ar']) {
    testWidgets(
      'FX search, regional filters and persistent favorites in $locale',
      (t) async {
        SharedPreferences.setMockInitialValues({
          'faisal.fx_favorites': <String>[],
        });
        final prefs = await SharedPreferences.getInstance();
        sl.registerSingleton<SharedPreferences>(prefs);
        await pump(t, const ExchangeRatesPage(), locale: locale);
        await t.enterText(find.byKey(const ValueKey('fx_search')), 'دولار');
        await t.pumpAndSettle();
        expect(find.byKey(const ValueKey('fx_card_USD')), findsOneWidget);
        expect(find.byKey(const ValueKey('fx_card_SAR')), findsNothing);
        await t.enterText(find.byKey(const ValueKey('fx_search')), '');
        await t.pumpAndSettle();
        await t.tap(find.byKey(const ValueKey('fx_favorite_USD')));
        await t.pumpAndSettle();
        expect(prefs.getStringList('faisal.fx_favorites'), ['USD']);
        await t.tap(find.byKey(const ValueKey('fx_filter_favorites')));
        await t.pumpAndSettle();
        expect(find.byKey(const ValueKey('fx_card_USD')), findsOneWidget);
        expect(find.byKey(const ValueKey('fx_card_SAR')), findsNothing);
        await t.ensureVisible(find.byKey(const ValueKey('fx_filter_arab')));
        await t.tap(find.byKey(const ValueKey('fx_filter_arab')));
        await t.pumpAndSettle();
        expect(find.byKey(const ValueKey('fx_card_SAR')), findsOneWidget);
        expect(find.byKey(const ValueKey('fx_card_USD')), findsNothing);
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
      },
    );
  }
  for (final locale in ['en', 'ar']) {
    testWidgets('Accounts separates certificates and funds in $locale', (
      t,
    ) async {
      await pump(t, const Scaffold(body: AccountsPage()), locale: locale);
      await t.tap(find.byKey(const ValueKey('account_certificates_tab')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('account_funds_tab')));
      await t.pumpAndSettle();
      expect(find.text(locale == 'ar' ? 'صندوقي' : 'My fund'), findsOneWidget);
      expect(
        find.text(locale == 'ar' ? 'شهادتي' : 'My certificate'),
        findsNothing,
      );
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    });
    testWidgets('investment and FX pages support $locale on narrow screens', (
      t,
    ) async {
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await pump(t, const InvestmentsPage(), locale: locale);
      expect(
        Directionality.of(t.element(find.byType(InvestmentsPage))),
        locale == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      );
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      await pump(t, const ExchangeRatesPage(), locale: locale);
      final details = AppLocalizations.of(
        t.element(find.byType(ExchangeRatesPage)),
      ).fxDetails;
      await t.scrollUntilVisible(
        find.text(details),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tap(t, details);
      await t.scrollUntilVisible(
        find.textContaining('900'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('900'), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    });
  }
}
