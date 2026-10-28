import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:faisal_app/core/di/injector.dart';
import 'package:faisal_app/core/theme/app_theme.dart';
import 'package:faisal_app/core/widgets/faisal_buttons.dart';
import 'package:faisal_app/l10n/app_localizations.dart';
import 'package:faisal_app/features/accounts/domain/entities/account_entities.dart';
import 'package:faisal_app/features/transfers/domain/entities/transfer_entities.dart';
import 'package:faisal_app/features/transfers/presentation/cubit/transfers_cubit.dart';
import 'package:faisal_app/features/transfers/presentation/pages/transfers_page.dart';

import 'security_flows_test.dart' as fixtures;

class Accounts extends fixtures.FakeAccounts {
  @override
  Future<AccountsOverview> fetchOverview() async {
    final base = await super.fetchOverview();
    return AccountsOverview(
      totals: base.totals,
      accounts: [
        ...base.accounts,
        Account(
          id: 'usd',
          accountType: 'current',
          accountNumberMasked: '***USD',
          currency: 'USD',
          status: 'active',
          currentBalance: 100,
          availableBalance: 100,
          blockedBalance: 0,
          productNameEn: 'USD',
          productNameAr: 'دولار',
          openedAt: DateTime(2026),
        ),
      ],
    );
  }
}

class Transfers extends fixtures.FakeTransfers {
  Map<String, dynamic>? quoted;
  String? sentType;
  String? sentFxQuoteId;
  Map<String, dynamic>? sentRecipient;
  bool outboundAvailable = true;
  @override
  Future<List<Beneficiary>> fetchBeneficiaries() async => [
    const Beneficiary(
      id: 'same-bank',
      name: 'Fictional customer',
      bankName: 'Same bank',
      accountNumberMasked: '***DEST',
      currency: 'EGP',
    ),
  ];
  @override
  Future<List<Map<String, dynamic>>> fetchTransferOptions() async => [
    for (final type in transferTypes)
      {
        'transfer_type': type,
        'available':
            ['own_accounts', 'internal'].contains(type) || outboundAvailable,
        'delivery_mode': 'simulation',
      },
  ];
  @override
  Future<Map<String, dynamic>> quoteTransfer(Map<String, dynamic> draft) async {
    quoted = draft;
    final base = await super.quoteTransfer(draft);
    final recipient = draft['recipient'] as Map<String, dynamic>?;
    return {
      ...base,
      if (draft['transfer_type'] == 'own_accounts' &&
          draft['destination_account_id'] == 'usd') ...{
        'fx_quote_id': 'fictional-frozen-quote',
        'exchange_rate': '0.020000000000',
        'received_amount': '0.20',
        'received_currency': 'USD',
        'rate_provider': 'fictional-feed',
        'rate_as_of': DateTime.now().toUtc().toIso8601String(),
        'fx_quote_expires_at': DateTime.now()
            .toUtc()
            .add(const Duration(minutes: 3))
            .toIso8601String(),
      },
      'transfer_type': draft['transfer_type'],
      'bank_name': recipient?['bank_name'],
      'country_code': recipient?['country_code'],
      'swift_code': recipient?['swift_code'],
    };
  }

  @override
  Future<TransferResult> createTransfer({
    required String sourceAccountId,
    required double amount,
    required String currency,
    String? destinationAccountId,
    String? beneficiaryId,
    String? purpose,
    String? note,
    String? idempotencyKey,
    String? authorizationToken,
    String? transferType,
    Map<String, dynamic>? recipient,
    String? fxQuoteId,
  }) async {
    sentType = transferType;
    sentFxQuoteId = fxQuoteId;
    sentRecipient = recipient;
    final base = await super.createTransfer(
      sourceAccountId: sourceAccountId,
      amount: amount,
      currency: currency,
      idempotencyKey: idempotencyKey,
      authorizationToken: authorizationToken,
    );
    return TransferResult(
      reference: base.reference,
      status: ['own_accounts', 'internal'].contains(transferType)
          ? 'posted'
          : 'simulated_completed',
      amount: amount,
      currency: currency,
      destinationLabel: '**** 5678',
      isSimulated: true,
      createdAt: base.createdAt,
      transferType: transferType,
      providerReference: 'SIM-UNIT-TEST',
      purpose: purpose,
      exchangeRate: fxQuoteId == null ? null : '0.02',
      receivedAmount: fxQuoteId == null ? null : 0.20,
      receivedCurrency: fxQuoteId == null ? null : 'USD',
      recipientName: recipient?['name'] as String?,
    );
  }
}

void main() {
  late Transfers repo;
  setUp(() async {
    await sl.reset();
    repo = Transfers();
    sl.registerFactory(() => TransfersCubit(repo, Accounts()));
  });
  tearDown(() async {
    await sl.reset();
  });
  Future<void> pump(
    WidgetTester t, {
    String locale = 'en',
    bool dark = false,
  }) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(
      MaterialApp(
        theme: dark ? AppTheme.dark() : AppTheme.light(),
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const TransfersPage(),
      ),
    );
    await t.pumpAndSettle();
  }

  Finder field(String key) => find.descendant(
    of: find.byKey(ValueKey(key)),
    matching: find.byType(TextFormField),
  );
  Future<void> tap(WidgetTester t, Finder f) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await t.pumpAndSettle();
    await t.ensureVisible(f);
    await t.pumpAndSettle();
    await t.tap(f);
    await t.pumpAndSettle();
  }

  for (final language in ['en', 'ar']) {
    for (final dark in [false, true]) {
      testWidgets(
        'six transfer routes support $language dark=$dark and type-specific fields',
        (t) async {
          await pump(t, locale: language, dark: dark);
          expect(find.byType(ChoiceChip), findsNWidgets(6));
          await tap(
            t,
            find.byKey(const ValueKey('transfer_type_international')),
          );
          expect(field('transfer_recipient_country'), findsOneWidget);
          expect(field('transfer_recipient_swift'), findsOneWidget);
          await tap(t, find.byKey(const ValueKey('transfer_type_wallet')));
          expect(field('transfer_recipient_country'), findsNothing);
          expect(field('transfer_recipient_bank'), findsNothing);
          final source = t.widget<DropdownButtonFormField<String>>(
            find.byType(DropdownButtonFormField<String>).first,
          );
          // FormField validator exists, and the rendered dropdown excludes USD.
          expect(source.validator, isNotNull);
          expect(find.text('***USD • USD'), findsNothing);
          expect(
            Directionality.of(t.element(find.byType(TransfersPage))),
            language == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          );
          expect(t.takeException(), isNull);
        },
      );
    }
  }
  for (final type in [
    'external_domestic',
    'international',
    'wallet',
    'instapay',
  ]) {
    testWidgets(
      '$type reviews, binds routing fields and requires explicit confirmation',
      (t) async {
        await pump(t);
        await tap(t, find.byKey(ValueKey('transfer_type_$type')));
        await tap(t, find.byType(DropdownButtonFormField<String>).first);
        await tap(t, find.text('***0010 • EGP').last);
        await t.enterText(
          field('transfer_recipient_name'),
          'Fictional recipient',
        );
        await t.enterText(
          field('transfer_recipient_destination'),
          type == 'instapay'
              ? 'fictional@instapay'
              : (type == 'wallet' ? '01012345678' : '001234567890'),
        );
        if (['external_domestic', 'international'].contains(type)) {
          await t.enterText(field('transfer_recipient_bank'), 'Fictional bank');
        }
        if (type == 'international') {
          await t.enterText(field('transfer_recipient_country'), 'US');
          await t.enterText(field('transfer_recipient_swift'), 'FAKEUS33XXX');
        }
        await t.enterText(field('transfer_amount'), '10.00');
        await t.enterText(field('transfer_purpose'), 'Fictional purpose');
        await tap(t, find.byKey(const ValueKey('transfer_review')));
        expect(repo.quoted?['transfer_type'], type);
        expect(
          (repo.quoted?['recipient'] as Map)['name'],
          'Fictional recipient',
        );
        expect(repo.submissions, 0);
        await t.enterText(field('transfer_token'), 'fictional-unit-token');
        await t.pumpAndSettle();
        expect(
          t
              .widget<FaisalPrimaryButton>(
                find.byKey(const ValueKey('transfer_confirm')),
              )
              .onPressed,
          isNull,
        );
        await tap(t, find.byType(CheckboxListTile));
        await tap(t, find.byKey(const ValueKey('transfer_confirm')));
        expect(repo.sentType, type);
        expect(repo.sentRecipient?['name'], 'Fictional recipient');
        expect(find.text('Transfer simulation completed'), findsOneWidget);
        expect(find.text('simulated_completed'), findsNothing);
        expect(find.textContaining('SIM-UNIT-TEST'), findsOneWidget);
        expect(t.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'unconfigured delivery disables review; switching clears recipient data',
    (t) async {
      repo.outboundAvailable = false;
      await pump(t);
      await tap(t, find.byKey(const ValueKey('transfer_type_wallet')));
      expect(
        find.textContaining('no configured delivery provider'),
        findsOneWidget,
      );
      expect(
        t
            .widget<FaisalPrimaryButton>(
              find.byKey(const ValueKey('transfer_review')),
            )
            .onPressed,
        isNull,
      );
      await t.enterText(field('transfer_recipient_name'), 'Fictional name');
      await tap(t, find.byKey(const ValueKey('transfer_type_instapay')));
      expect(
        t
            .widget<TextFormField>(field('transfer_recipient_name'))
            .controller!
            .text,
        isEmpty,
      );
      expect(repo.submissions, 0);
    },
  );
  for (final locale in ['en', 'ar']) {
    testWidgets(
      'own-account FX review freezes quote and sends it with confirmation $locale',
      (t) async {
        await pump(t, locale: locale, dark: locale == 'ar');
        final l = AppLocalizations.of(t.element(find.byType(TransfersPage)));
        await tap(t, find.byType(DropdownButtonFormField<String>).first);
        await tap(t, find.text('***0010 • EGP').last);
        await tap(t, find.byType(DropdownButtonFormField<String>).at(1));
        await tap(t, find.text('***USD • USD').last);
        await t.enterText(field('transfer_amount'), '10.00');
        await t.enterText(field('transfer_purpose'), 'Fictional own FX');
        await tap(t, find.byKey(const ValueKey('transfer_review')));
        expect(
          find.textContaining('${l.ownFxReceived}: 0.20 USD'),
          findsOneWidget,
        );
        expect(find.textContaining('1 EGP = 0.02 USD'), findsOneWidget);
        expect(find.textContaining('${l.ownFxExpires}:'), findsOneWidget);
        expect(
          t.widget<Text>(find.text('1 EGP = 0.02 USD')).textDirection,
          TextDirection.ltr,
        );
        expect(
          Directionality.of(t.element(find.text('1 EGP = 0.02 USD'))),
          locale == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        );
        expect(repo.quoted?['fx_quote_id'], isNull);
        await t.enterText(field('transfer_token'), 'fictional-unit-token');
        await tap(t, find.byType(CheckboxListTile));
        await tap(t, find.byKey(const ValueKey('transfer_confirm')));
        expect(repo.sentFxQuoteId, 'fictional-frozen-quote');
        expect(
          find.textContaining('${l.ownFxReceived}: 0.20 USD'),
          findsOneWidget,
        );
        expect(t.takeException(), isNull);
      },
    );
  }
}
