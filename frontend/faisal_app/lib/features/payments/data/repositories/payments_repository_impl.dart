import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/json_utils.dart';
import '../../../transactions/data/models/transaction_mapper.dart';
import '../../../transactions/domain/entities/transaction_entities.dart';
import '../../domain/entities/payment_entities.dart';
import '../../domain/repositories/payments_repository.dart';

class PaymentsRepositoryImpl implements PaymentsRepository {
  PaymentsRepositoryImpl(this._client);

  final DioClient _client;

  @override
  Future<List<Biller>> fetchBillers() async {
    final data = await _client.get('/payments/billers');
    if (data is List) {
      return data.map((item) => _biller(asMap(item))).toList(growable: false);
    }
    return const <Biller>[];
  }

  @override
  Future<PaymentResult> payBill({
    required String billerCode,
    required double amount,
    required String fundingAccountId,
    String? note,
    String? idempotencyKey,
  }) async {
    final data = await _client.post(
      '/payments',
      body: {
        'biller_code': billerCode,
        'amount': amount,
        'funding_account_id': fundingAccountId,
        'note': ?note,
      },
      headers: idempotencyKey == null
          ? null
          : {'Idempotency-Key': idempotencyKey},
    );
    final json = asMap(data);
    return PaymentResult(
      reference: asString(json['reference']),
      status: asString(json['status']),
      amount: asDouble(json['amount']),
      currency: asString(json['currency'], 'EGP'),
      billerNameEn: asString(json['biller_name_en']),
      billerNameAr: asString(json['biller_name_ar']),
      isSimulated: asBool(json['is_simulated'], true),
      createdAt: asDate(json['created_at']),
    );
  }

  @override
  Future<TransactionPage> fetchHistory({
    int page = 1,
    int pageSize = 20,
  }) async {
    final data = await _client.get(
      '/payments',
      query: {'page': page, 'page_size': pageSize},
    );
    return TransactionMapper.page(asMap(data));
  }

  Biller _biller(Map<String, dynamic> json) {
    return Biller(
      code: asString(json['code']),
      nameEn: asString(json['name_en']),
      nameAr: asString(json['name_ar']),
      category: asString(json['category'], 'utilities'),
      amountDue: json['amount_due'] == null
          ? null
          : asDouble(json['amount_due']),
    );
  }
}
