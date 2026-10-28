import '../entities/transaction_entities.dart';

/// Where the history is scoped: all accounts, a single account or a single card.
enum TransactionScope { all, account, card }

abstract class TransactionsRepository {
  Future<TransactionPage> fetchTransactions({
    required TransactionFilter filter,
    int page,
    int pageSize,
  });

  Future<BankTransaction> fetchTransaction(String transactionId);

  Future<TransactionPage> fetchAccountTransactions(
    String accountId, {
    required TransactionFilter filter,
    int page,
    int pageSize,
  });

  Future<TransactionPage> fetchCardTransactions(
    String cardId, {
    required TransactionFilter filter,
    int page,
    int pageSize,
  });
}
