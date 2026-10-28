import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:faisal_app/core/errors/app_exception.dart';
import 'package:faisal_app/core/theme/app_theme.dart';
import 'package:faisal_app/l10n/app_localizations.dart';
import 'package:faisal_app/features/cards/domain/entities/card_product.dart';
import 'package:faisal_app/features/cards/domain/repositories/cards_repository.dart';
import 'package:faisal_app/features/cards/presentation/cubit/card_application_cubit.dart';
import 'package:faisal_app/features/cards/presentation/pages/card_application_page.dart';
import 'package:faisal_app/features/requests/domain/entities/request_entities.dart';
import 'package:faisal_app/features/requests/domain/repositories/requests_repository.dart';

const account = CardEligibleAccount(
  id: 'owned',
  masked: '**** 1234',
  currency: 'EGP',
  type: 'investment',
);
CardProduct offer(String variant, {bool eligible = true, String? reason}) =>
    CardProduct(
      code: variant,
      variant: variant,
      nameEn: 'Faisal $variant',
      nameAr: 'فيصل $variant',
      eligible: eligible,
      reason: reason,
      accounts: eligible ? [account] : [],
      currencies: const ['EGP'],
    );
ServiceRequestEntity request({String status = 'submitted'}) =>
    ServiceRequestEntity(
      id: 'request',
      reference: 'REQ-CARD-QA',
      requestType: 'card_issue',
      status: status,
      priority: 'normal',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      decisionReason: status == 'rejected'
          ? 'Fictional rejection reason'
          : null,
    );

class Cards extends Fake implements CardsRepository {
  bool fail = false;
  List<CardProduct> products = [
    offer('gold'),
    offer('platinum'),
    offer('platinum_fx', eligible: false, reason: 'card_fx_account_required'),
    offer('youth', eligible: false, reason: 'card_youth_age'),
    offer('meeza'),
    offer('meeza_bab_rezq'),
  ];
  @override
  Future<List<CardProduct>> fetchProducts() async {
    if (fail) throw const AppException(code: AppErrorCode.network);
    return products;
  }
}

class Requests extends Fake implements RequestsRepository {
  int submissions = 0;
  Map<String, dynamic>? sent;
  List<ServiceRequestEntity> rows = [];
  Completer<ServiceRequestEntity>? pending;
  bool fail = false;
  @override
  Future<RequestPage> fetchRequests({
    int page = 1,
    int pageSize = 20,
    String? status,
    String? type,
  }) async =>
      RequestPage(items: rows, page: 1, total: rows.length, hasNext: false);
  @override
  Future<ServiceRequestEntity> createRequest({
    required String requestType,
    Map<String, dynamic> formData = const {},
    String? priority,
  }) async {
    submissions++;
    sent = formData;
    if (fail) throw const AppException(code: AppErrorCode.network);
    return pending != null ? pending!.future : request();
  }
}

void main() {
  late Cards cards;
  late Requests requests;
  late CardApplicationCubit cubit;
  setUp(() {
    cards = Cards();
    requests = Requests();
    cubit = CardApplicationCubit(cards, requests);
  });
  tearDown(() async {
    await cubit.close();
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
    await cubit.load();
    await t.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MaterialApp(
          theme: dark ? AppTheme.dark() : AppTheme.light(),
          locale: Locale(locale),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const CardApplicationView(),
        ),
      ),
    );
    await t.pumpAndSettle();
  }

  Future<void> tap(WidgetTester t, Finder f) async {
    await t.ensureVisible(f);
    await t.tap(f);
    await t.pumpAndSettle();
  }

  for (final lang in ['en', 'ar']) {
    for (final dark in [false, true]) {
      testWidgets(
        'six category previews, eligibility and RTL $lang dark=$dark',
        (t) async {
          await pump(t, locale: lang, dark: dark);
          expect(find.byType(CardProductPreview), findsNWidgets(6));
          expect(
            t
                .widget<OutlinedButton>(
                  find.byKey(const ValueKey('choose_youth')),
                )
                .onPressed,
            isNull,
          );
          expect(
            t
                .widget<OutlinedButton>(
                  find.byKey(const ValueKey('choose_platinum_fx')),
                )
                .onPressed,
            isNull,
          );
          expect(
            Directionality.of(t.element(find.byType(CardApplicationView))),
            lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          );
          expect(t.takeException(), isNull);
        },
      );
    }
  }
  testWidgets(
    'review cancel does not submit; confirm creates pending receipt once',
    (t) async {
      await pump(t);
      await tap(t, find.byKey(const ValueKey('choose_gold')));
      await tap(t, find.byKey(const ValueKey('card_issue_review')));
      expect(requests.submissions, 0);
      await tap(t, find.text('Cancel'));
      expect(requests.submissions, 0);
      await tap(t, find.byKey(const ValueKey('card_issue_review')));
      await tap(t, find.byKey(const ValueKey('card_issue_confirm')));
      expect(requests.submissions, 1);
      expect(requests.sent, {
        'card_product_code': 'gold',
        'account_id': 'owned',
      });
      expect(
        find.byKey(const ValueKey('card_issue_reference')),
        findsOneWidget,
      );
      expect(cubit.state.hasOpen, isTrue);
      expect(await cubit.submit(cards.products.first, 'owned'), isFalse);
      expect(requests.submissions, 1);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('API errors offer retry and rejected request displays reason', (
    t,
  ) async {
    cards.fail = true;
    requests.rows = [request(status: 'rejected')];
    await pump(t);
    expect(find.text('Try again'), findsOneWidget);
    cards.fail = false;
    await tap(t, find.text('Try again'));
    expect(find.text('Fictional rejection reason'), findsOneWidget);
    expect(cubit.state.hasOpen, isFalse);
    expect(t.takeException(), isNull);
  });
  test('invalid account and ineligible product never submit; busy suppresses duplicate', () async {
    await cubit.load();
    expect(
      await cubit.submit(cards.products.first, 'foreign-customer'),
      isFalse,
    );
    expect(await cubit.submit(cards.products[2], 'owned'), isFalse);
    requests.pending = Completer<ServiceRequestEntity>();
    final pending = cubit.submit(cards.products.first, 'owned');
    expect(cubit.state.busy, isTrue);
    expect(await cubit.submit(cards.products.first, 'owned'), isFalse);
    requests.pending!.complete(request());
    await pending;
    expect(requests.submissions, 1);
    expect(cubit.state.receipt?.status, 'submitted');
  });
}
