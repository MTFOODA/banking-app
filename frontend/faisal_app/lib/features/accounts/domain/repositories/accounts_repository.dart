import '../entities/account_entities.dart';

abstract class AccountsRepository {
  Future<AccountsOverview> fetchOverview();

  Future<Account> fetchAccount(String accountId);

  Future<List<AccountProduct>> fetchProducts();

  /// Submits an account opening/closing request and returns its reference.
  Future<String> requestAccountChange({
    required String requestType,
    String? accountId,
    String? productCode,
    String? reason,
  });
}
