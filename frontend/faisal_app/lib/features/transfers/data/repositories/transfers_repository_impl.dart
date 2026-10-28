import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/json_utils.dart';
import '../../../transactions/data/models/transaction_mapper.dart';
import '../../../transactions/domain/entities/transaction_entities.dart';
import '../../domain/entities/transfer_entities.dart';
import '../../domain/repositories/transfers_repository.dart';

class TransfersRepositoryImpl implements TransfersRepository {
  TransfersRepositoryImpl(this._client);

  final DioClient _client;
  @override
  Future<List<Map<String, dynamic>>> fetchTransferOptions() async =>
      asMapList(await _client.get('/transfers/options'));
  @override
  Future<Map<String, dynamic>> quoteTransfer(
    Map<String, dynamic> draft,
  ) async => asMap(await _client.post('/transfers/quote', body: draft));

  @override
  Future<List<Beneficiary>> fetchBeneficiaries() async {
    final data = await _client.get('/beneficiaries');
    if (data is List) {
      return data
          .map((item) => _beneficiary(asMap(item)))
          .toList(growable: false);
    }
    return const <Beneficiary>[];
  }

  @override
  Future<Beneficiary> addBeneficiary({
    required String name,
    required String bankName,
    required String accountNumber,
    String? nickname,
    String? iban,
    String currency = 'EGP',
  }) async {
    final data = await _client.post(
      '/beneficiaries',
      body: {
        'name': name,
        'bank_name': bankName,
        'account_number': accountNumber,
        'nickname': nickname,
        'iban': iban,
        'currency': currency,
      },
    );
    return _beneficiary(asMap(data));
  }

  @override
  Future<void> deleteBeneficiary(String beneficiaryId) async {
    await _client.delete('/beneficiaries/$beneficiaryId');
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
    final data = await _client.post(
      '/transfers',
      body: {
        'transfer_type': ?transferType,
        'fx_quote_id': ?fxQuoteId,
        'recipient': ?recipient,
        'source_account_id': sourceAccountId,
        'authorization_token': authorizationToken,
        'amount': amount,
        'currency': currency,
        'destination_account_id': ?destinationAccountId,
        'beneficiary_id': ?beneficiaryId,
        'purpose': ?purpose,
        'note': ?note,
      },
      headers: idempotencyKey == null
          ? null
          : {'Idempotency-Key': idempotencyKey},
    );
    final json = asMap(data);
    return TransferResult(
      transferType: asStringOrNull(json['transfer_type']),
      purpose: asStringOrNull(json['purpose']),
      exchangeRate: asStringOrNull(json['exchange_rate']),
      receivedCurrency: asStringOrNull(json['received_currency']),
      receivedAmount: json['received_amount'] == null
          ? null
          : asDouble(json['received_amount']),
      rateProvider: asStringOrNull(json['rate_provider']),
      rateAsOf: asStringOrNull(json['rate_as_of']),
      providerReference: asStringOrNull(json['provider_reference']),
      recipientName: asStringOrNull(json['recipient_name']),
      bankName: asStringOrNull(json['bank_name']),
      countryCode: asStringOrNull(json['country_code']),
      fees: asDouble(json['fees']),
      totalDebit: asDouble(json['total_debit']),
      reference: asString(json['reference']),
      status: asString(json['status']),
      amount: asDouble(json['amount']),
      currency: asString(json['currency'], 'EGP'),
      destinationLabel: asString(json['destination_label']),
      isSimulated: asBool(json['is_simulated'], true),
      createdAt: asDate(json['created_at']),
    );
  }

  @override
  Future<TransactionPage> fetchTransferHistory({
    int page = 1,
    int pageSize = 20,
  }) async {
    final data = await _client.get(
      '/transfers',
      query: {'page': page, 'page_size': pageSize},
    );
    return TransactionMapper.page(asMap(data));
  }

  Beneficiary _beneficiary(Map<String, dynamic> json) {
    return Beneficiary(
      id: asString(json['id']),
      name: asString(json['name']),
      nickname: asStringOrNull(json['nickname']),
      bankName: asString(json['bank_name']),
      accountNumberMasked: asString(json['account_number_masked']),
      iban: asStringOrNull(json['iban']),
      currency: asString(json['currency'], 'EGP'),
      status: asString(json['status'], 'active'),
    );
  }
}
