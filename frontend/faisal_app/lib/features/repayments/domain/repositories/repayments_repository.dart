import '../entities/repayment_entities.dart';

abstract class RepaymentsRepository {
  Future<RepaymentQuote> quote({
    required String cardId,
    required String fundingAccountId,
    required String mode,
    double? amount,
  });

  Future<RepaymentRecord> createRepayment({
    required String cardId,
    required String fundingAccountId,
    required String mode,
    double? amount,
    String? idempotencyKey,
  });

  Future<RepaymentPage> fetchRepayments({int page, int pageSize});
}
