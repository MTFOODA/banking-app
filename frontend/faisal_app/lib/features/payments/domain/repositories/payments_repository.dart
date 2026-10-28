import '../../../transactions/domain/entities/transaction_entities.dart';
import '../entities/payment_entities.dart';

abstract class PaymentsRepository {
  Future<List<Biller>> fetchBillers();

  Future<PaymentResult> payBill({
    required String billerCode,
    required double amount,
    required String fundingAccountId,
    String? note,
    String? idempotencyKey,
  });

  Future<TransactionPage> fetchHistory({int page, int pageSize});
}
