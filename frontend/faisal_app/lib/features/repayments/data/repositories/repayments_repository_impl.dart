import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/json_utils.dart';
import '../../domain/entities/repayment_entities.dart';
import '../../domain/repositories/repayments_repository.dart';

class RepaymentsRepositoryImpl implements RepaymentsRepository {
  RepaymentsRepositoryImpl(this._client);

  final DioClient _client;

  @override
  Future<RepaymentQuote> quote({
    required String cardId,
    required String fundingAccountId,
    required String mode,
    double? amount,
  }) async {
    final data = await _client.post(
      '/repayments/quote',
      body: {
        'card_id': cardId,
        'funding_account_id': fundingAccountId,
        'mode': mode,
        'amount': ?amount,
      },
    );
    return _quote(asMap(data));
  }

  @override
  Future<RepaymentRecord> createRepayment({
    required String cardId,
    required String fundingAccountId,
    required String mode,
    double? amount,
    String? idempotencyKey,
  }) async {
    final data = await _client.post(
      '/repayments',
      body: {
        'card_id': cardId,
        'funding_account_id': fundingAccountId,
        'mode': mode,
        'amount': ?amount,
      },
      headers: idempotencyKey == null
          ? null
          : {'Idempotency-Key': idempotencyKey},
    );
    return _record(asMap(data));
  }

  @override
  Future<RepaymentPage> fetchRepayments({
    int page = 1,
    int pageSize = 20,
  }) async {
    final data = await _client.get(
      '/repayments',
      query: {'page': page, 'page_size': pageSize},
    );
    final json = asMap(data);
    return RepaymentPage(
      items: asMapList(json['items']).map(_record).toList(growable: false),
      page: asInt(json['page'], 1),
      total: asInt(json['total']),
    );
  }

  RepaymentQuote _quote(Map<String, dynamic> json) {
    return RepaymentQuote(
      cardId: asString(json['card_id']),
      mode: asString(json['mode'], 'custom'),
      amount: asDouble(json['amount']),
      statementBalance: asDouble(json['statement_balance']),
      outstandingBalance: asDouble(json['outstanding_balance']),
      minimumPayment: asDouble(json['minimum_payment']),
      availableCredit: asDouble(json['available_credit']),
      charges: asDouble(json['charges']),
      payable: asDouble(json['payable']),
      fundingAccountId: asString(json['funding_account_id']),
      fundingAvailableBalance: asDouble(json['funding_available_balance']),
      eligible: asBool(json['eligible'], true),
      ineligibilityReason: asStringOrNull(json['ineligibility_reason']),
    );
  }

  RepaymentRecord _record(Map<String, dynamic> json) {
    return RepaymentRecord(
      id: asString(json['id']),
      reference: asString(json['reference']),
      cardId: asString(json['card_id']),
      cardLast4: asString(json['card_last4']),
      amount: asDouble(json['amount']),
      mode: asString(json['mode'], 'custom'),
      status: asString(json['status'], 'pending'),
      isSimulated: asBool(json['is_simulated'], true),
      charges: asDouble(json['charges']),
      createdAt: asDate(json['created_at']),
      completedAt: asDateOrNull(json['completed_at']),
      notes: asStringOrNull(json['notes']),
    );
  }
}
