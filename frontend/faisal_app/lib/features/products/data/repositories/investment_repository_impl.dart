import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/json_utils.dart';
import '../../domain/entities/investment_entities.dart';
import '../../domain/repositories/investment_repository.dart';

class InvestmentRepositoryImpl implements InvestmentRepository {
  InvestmentRepositoryImpl(this._client);
  final DioClient _client;
  @override
  Future<List<InvestmentRecord>> products() async =>
      ((await _client.get('/investments/products')) as List)
          .map((e) => InvestmentRecord(asMap(e)))
          .toList();
  @override
  Future<List<InvestmentRecord>> holdings() async =>
      ((await _client.get('/investments/holdings')) as List)
          .map((e) => InvestmentRecord(asMap(e)))
          .toList();
  @override
  Future<InvestmentRecord> quote(Map<String, dynamic> action) async =>
      InvestmentRecord(
        asMap(await _client.post('/investments/quote', body: action)),
      );
  @override
  Future<InvestmentRecord> execute(
    Map<String, dynamic> action,
    String token,
    String retryKey,
  ) async => InvestmentRecord(
    asMap(
      await _client.post(
        '/investments/execute',
        body: {...action, 'authorization_token': token},
        headers: {'Idempotency-Key': retryKey},
      ),
    ),
  );
  @override
  Future<ExchangeRates> exchangeRates() async =>
      ExchangeRates(asMap(await _client.get('/exchange-rates')));
}
