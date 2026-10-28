import 'package:equatable/equatable.dart';

class Beneficiary extends Equatable {
  const Beneficiary({
    required this.id,
    required this.name,
    required this.bankName,
    required this.accountNumberMasked,
    required this.currency,
    this.nickname,
    this.iban,
    this.status = 'active',
  });

  final String id;
  final String name;
  final String? nickname;
  final String bankName;
  final String accountNumberMasked;
  final String? iban;
  final String currency;
  final String status;

  String get label => nickname == null || nickname!.isEmpty ? name : nickname!;

  @override
  List<Object?> get props => [id, name, accountNumberMasked];
}

class TransferResult extends Equatable {
  const TransferResult({
    required this.reference,
    required this.status,
    required this.amount,
    required this.currency,
    required this.destinationLabel,
    required this.isSimulated,
    required this.createdAt,
    this.transferType,
    this.providerReference,
    this.recipientName,
    this.bankName,
    this.countryCode,
    this.fees = 0,
    this.totalDebit,
    this.purpose,
    this.exchangeRate,
    this.receivedAmount,
    this.receivedCurrency,
    this.rateProvider,
    this.rateAsOf,
  });

  final String reference;
  final String status;
  final double amount;
  final String currency;
  final String destinationLabel;
  final bool isSimulated;
  final DateTime createdAt;
  final String? transferType,
      providerReference,
      recipientName,
      bankName,
      countryCode;
  final double fees;
  final double? totalDebit;
  final String? purpose;
  final String? exchangeRate, receivedCurrency, rateProvider, rateAsOf;
  final double? receivedAmount;

  @override
  List<Object?> get props => [reference, status, amount];
}

class TransferDraft extends Equatable {
  const TransferDraft({
    this.sourceAccountId,
    this.destinationAccountId,
    this.beneficiaryId,
    this.amount,
    this.purpose,
    this.note,
  });

  final String? sourceAccountId;
  final String? destinationAccountId;
  final String? beneficiaryId;
  final double? amount;
  final String? purpose;
  final String? note;

  bool get hasDestination =>
      destinationAccountId != null || beneficiaryId != null;

  TransferDraft copyWith({
    String? sourceAccountId,
    String? destinationAccountId,
    String? beneficiaryId,
    double? amount,
    String? purpose,
    String? note,
    bool clearDestinationAccount = false,
    bool clearBeneficiary = false,
  }) {
    return TransferDraft(
      sourceAccountId: sourceAccountId ?? this.sourceAccountId,
      destinationAccountId: clearDestinationAccount
          ? null
          : (destinationAccountId ?? this.destinationAccountId),
      beneficiaryId: clearBeneficiary
          ? null
          : (beneficiaryId ?? this.beneficiaryId),
      amount: amount ?? this.amount,
      purpose: purpose ?? this.purpose,
      note: note ?? this.note,
    );
  }

  @override
  List<Object?> get props => [
    sourceAccountId,
    destinationAccountId,
    beneficiaryId,
    amount,
    purpose,
    note,
  ];
}
