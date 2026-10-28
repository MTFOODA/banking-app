import 'package:equatable/equatable.dart';

class RepaymentQuote extends Equatable {
  const RepaymentQuote({
    required this.cardId,
    required this.mode,
    required this.amount,
    required this.statementBalance,
    required this.outstandingBalance,
    required this.minimumPayment,
    required this.availableCredit,
    required this.charges,
    required this.payable,
    required this.fundingAccountId,
    required this.fundingAvailableBalance,
    required this.eligible,
    this.ineligibilityReason,
  });

  final String cardId;
  final String mode;
  final double amount;
  final double statementBalance;
  final double outstandingBalance;
  final double minimumPayment;
  final double availableCredit;
  final double charges;
  final double payable;
  final String fundingAccountId;
  final double fundingAvailableBalance;
  final bool eligible;
  final String? ineligibilityReason;

  @override
  List<Object?> get props => [cardId, mode, payable, eligible];
}

class RepaymentRecord extends Equatable {
  const RepaymentRecord({
    required this.id,
    required this.reference,
    required this.cardId,
    required this.cardLast4,
    required this.amount,
    required this.mode,
    required this.status,
    required this.isSimulated,
    required this.charges,
    required this.createdAt,
    this.completedAt,
    this.notes,
  });

  final String id;
  final String reference;
  final String cardId;
  final String cardLast4;
  final double amount;
  final String mode;
  final String status;
  final bool isSimulated;
  final double charges;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? notes;

  bool get isCompleted =>
      status == 'simulated_completed' || status == 'completed';

  @override
  List<Object?> get props => [id, reference, status, amount];
}

class RepaymentPage extends Equatable {
  const RepaymentPage({
    required this.items,
    required this.page,
    required this.total,
  });

  final List<RepaymentRecord> items;
  final int page;
  final int total;

  @override
  List<Object?> get props => [items, page, total];
}
