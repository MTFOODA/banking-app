import '../entities/investment_entities.dart';

abstract class InvestmentRepository {
  Future<List<InvestmentRecord>> products();
  Future<List<InvestmentRecord>> holdings();
  Future<InvestmentRecord> quote(Map<String, dynamic> action);
  Future<InvestmentRecord> execute(
    Map<String, dynamic> action,
    String token,
    String retryKey,
  );
  Future<ExchangeRates> exchangeRates();
}
