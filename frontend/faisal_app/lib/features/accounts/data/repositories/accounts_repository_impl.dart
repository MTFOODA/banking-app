import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/json_utils.dart';
import '../../domain/entities/account_entities.dart';
import '../../domain/repositories/accounts_repository.dart';
import '../models/account_mapper.dart';

class AccountsRepositoryImpl implements AccountsRepository {
  AccountsRepositoryImpl(this._client);

  final DioClient _client;

  @override
  Future<AccountsOverview> fetchOverview() async {
    final data = await _client.get('/accounts');
    return AccountMapper.overview(asMap(data));
  }

  @override
  Future<Account> fetchAccount(String accountId) async {
    final data = await _client.get('/accounts/$accountId');
    return AccountMapper.account(asMap(data));
  }

  @override
  Future<List<AccountProduct>> fetchProducts() async {
    final data = await _client.get('/accounts/products');
    if (data is List) {
      return data
          .map((item) => AccountMapper.product(asMap(item)))
          .toList(growable: false);
    }
    return const <AccountProduct>[];
  }

  @override
  Future<String> requestAccountChange({
    required String requestType,
    String? accountId,
    String? productCode,
    String? reason,
  }) async {
    final data = await _client.post(
      '/accounts/requests',
      body: {
        'request_type': requestType,
        'account_id': ?accountId,
        'account_type': ?productCode,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
    );
    return asString(asMap(data)['reference']);
  }
}
