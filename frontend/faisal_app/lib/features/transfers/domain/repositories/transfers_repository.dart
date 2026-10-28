import '../../../transactions/domain/entities/transaction_entities.dart';
import '../entities/transfer_entities.dart';

abstract class TransfersRepository {
  Future<List<Map<String, dynamic>>> fetchTransferOptions();
  Future<Map<String, dynamic>> quoteTransfer(Map<String, dynamic> draft);
  Future<List<Beneficiary>> fetchBeneficiaries();

  Future<Beneficiary> addBeneficiary({
    required String name,
    required String bankName,
    required String accountNumber,
    String? nickname,
    String? iban,
    String currency = 'EGP',
  });

  Future<void> deleteBeneficiary(String beneficiaryId);

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
  });

  Future<TransactionPage> fetchTransferHistory({int page, int pageSize});
}
