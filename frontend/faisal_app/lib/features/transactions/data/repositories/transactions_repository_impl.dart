import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/json_utils.dart';
import '../../domain/entities/transaction_entities.dart';
import '../../domain/repositories/transactions_repository.dart';
import '../models/transaction_mapper.dart';

class TransactionsRepositoryImpl implements TransactionsRepository {
  TransactionsRepositoryImpl(this._client);

  final DioClient _client;

  @override
  Future<TransactionPage> fetchTransactions({
    required TransactionFilter filter,
    int page = 1,
    int pageSize = 20,
  }) async {
    final data = await _client.get(
      '/transactions',
      query: {...filter.toQuery(), 'page': page, 'page_size': pageSize},
    );
    return TransactionMapper.page(asMap(data));
  }

  @override
  Future<BankTransaction> fetchTransaction(String transactionId) async {
    final data = await _client.get('/transactions/$transactionId');
    return TransactionMapper.transaction(asMap(data));
  }

  @override
  Future<TransactionPage> fetchAccountTransactions(
    String accountId, {
    required TransactionFilter filter,
    int page = 1,
    int pageSize = 20,
  }) async {
    final data = await _client.get(
      '/accounts/$accountId/transactions',
      query: {...filter.toQuery(), 'page': page, 'page_size': pageSize},
    );
    return TransactionMapper.page(asMap(data));
  }

  @override
  Future<TransactionPage> fetchCardTransactions(
    String cardId, {
    required TransactionFilter filter,
    int page = 1,
    int pageSize = 20,
  }) async {
    final data = await _client.get(
      '/cards/$cardId/transactions',
      query: {...filter.toQuery(), 'page': page, 'page_size': pageSize},
    );
    return TransactionMapper.page(asMap(data));
  }
}
