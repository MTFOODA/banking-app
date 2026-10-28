import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/json_utils.dart';
import '../../domain/entities/card_entities.dart';
import '../../domain/entities/card_product.dart';
import '../../domain/repositories/cards_repository.dart';
import '../models/card_mapper.dart';

class CardsRepositoryImpl implements CardsRepository {
  CardsRepositoryImpl(this._client);

  final DioClient _client;

  @override
  Future<List<CardProduct>> fetchProducts() async {
    final rows = await _client.get('/cards/products');
    return (rows as List).map((value) {
      final r = asMap(value);
      return CardProduct(
        code: asString(r['code']),
        variant: asString(r['variant']),
        nameEn: asString(r['name_en']),
        nameAr: asString(r['name_ar']),
        eligible: asBool(r['eligible']),
        reason: asStringOrNull(r['ineligibility_reason']),
        investmentOnly: asBool(r['investment_only']),
        under21Only: asBool(r['under_21_only']),
        annualFee: asDouble(r['annual_fee']),
        feeCurrency: asString(r['fee_currency'], 'EGP'),
        network: asStringOrNull(r['network']),
        currencies: (r['currencies'] as List).map((s) => '$s').toList(),
        accounts: asMapList(r['accounts'])
            .map(
              (a) => CardEligibleAccount(
                id: asString(a['id']),
                masked: asString(a['account_number_masked']),
                currency: asString(a['currency']),
                type: asString(a['account_type']),
              ),
            )
            .toList(),
      );
    }).toList();
  }

  @override
  Future<CardsOverview> fetchCards() async {
    final data = await _client.get('/cards');
    return CardMapper.overview(asMap(data));
  }

  @override
  Future<BankCard> fetchCard(String cardId) async {
    final data = await _client.get('/cards/$cardId');
    return CardMapper.card(asMap(data));
  }

  @override
  Future<BankCard> freezeCard(String cardId, {String? reason}) =>
      _action('/cards/$cardId/freeze', {'reason': reason});

  @override
  Future<BankCard> unfreezeCard(String cardId) async {
    final data = await _client.post('/cards/$cardId/unfreeze');
    return CardMapper.card(asMap(data));
  }

  @override
  Future<BankCard> reportLost(
    String cardId, {
    required String reportType,
    String? note,
  }) => _action('/cards/$cardId/report-lost', {
    'report_type': reportType,
    'note': note,
  });

  @override
  Future<BankCard> blockCard(String cardId, {String? reason}) =>
      _action('/cards/$cardId/block', {'reason': reason});

  @override
  Future<BankCard> toggleControl(String cardId, String control, bool enabled) =>
      _action('/cards/$cardId/controls/$control', {'enabled': enabled});

  @override
  Future<String> requestReplacement(
    String cardId, {
    required String reason,
    String? deliveryBranch,
    bool urgent = false,
  }) async {
    final data = await _client.post(
      '/cards/$cardId/replacement-requests',
      body: {
        'reason': reason,
        if (deliveryBranch != null && deliveryBranch.isNotEmpty)
          'delivery_branch': deliveryBranch,
        'urgent': urgent,
      },
    );
    return asString(asMap(data)['reference']);
  }

  @override
  Future<String> requestLimitChange(
    String cardId, {
    required String limitType,
    required double requestedAmount,
    required String reason,
    required bool increase,
  }) async {
    final data = increase
        ? await _client.post(
            '/cards/$cardId/limit-requests',
            body: {
              'limit_type': limitType,
              'requested_amount': requestedAmount,
              'reason': reason,
            },
          )
        : await _client.post(
            '/cards/requests',
            body: {
              'request_type': 'card_limit_decrease',
              'card_id': cardId,
              'form_data': {
                'limit_type': limitType,
                'requested_amount': requestedAmount.toString(),
                'reason': reason,
              },
            },
          );
    return asString(asMap(data)['reference']);
  }

  @override
  Future<String> requestSupplementary({
    required String primaryCardId,
    required String holderFirstName,
    required String holderLastName,
    required String relationship,
    required String nationalId,
    String? phone,
    String? productCode,
    required double spendingLimit,
    List<String> restrictions = const <String>[],
  }) async {
    final data = await _client.post(
      '/cards/$primaryCardId/supplementary-requests',
      body: {
        'primary_card_id': primaryCardId,
        'holder_first_name': holderFirstName,
        'holder_last_name': holderLastName,
        'holder_relationship': relationship,
        'holder_national_id': nationalId,
        'holder_phone': phone,
        'card_product_code': productCode,
        'spending_limit': spendingLimit,
        'restrictions': restrictions,
      },
    );
    return asString(asMap(data)['reference']);
  }

  @override
  Future<String> requestService(
    String cardId,
    String requestType, {
    String? note,
  }) async {
    final endpoint = switch (requestType) {
      'card_renewal' => '/cards/$cardId/renewal-requests',
      'card_cancellation' => '/cards/$cardId/cancellation-requests',
      'pin_reset' => '/cards/$cardId/pin-reset-requests',
      _ => '/cards/requests',
    };
    final data = endpoint == '/cards/requests'
        ? await _client.post(
            endpoint,
            body: {
              'request_type': requestType,
              'card_id': cardId,
              'notes': note,
            },
          )
        : await _client.post(endpoint, body: {'note': note});
    return asString(asMap(data)['reference']);
  }

  @override
  Future<List<CardStatement>> fetchStatements(String cardId) async {
    final data = await _client.get('/cards/$cardId/statements');
    if (data is List) {
      return data
          .map((item) => CardMapper.statement(asMap(item)))
          .toList(growable: false);
    }
    return const <CardStatement>[];
  }

  Future<BankCard> _action(String path, [Map<String, dynamic>? body]) async {
    final data = await _client.post(
      path,
      body: body ?? const <String, dynamic>{},
    );
    return CardMapper.card(asMap(data));
  }
}
