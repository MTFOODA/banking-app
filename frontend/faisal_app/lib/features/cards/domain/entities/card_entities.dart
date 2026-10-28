import 'package:equatable/equatable.dart';

class CardLimits extends Equatable {
  const CardLimits({
    required this.dailyPurchaseLimit,
    required this.dailyAtmLimit,
    required this.monthlyLimit,
    required this.onlineEnabled,
    required this.internationalEnabled,
    required this.contactlessEnabled,
  });

  final double dailyPurchaseLimit;
  final double dailyAtmLimit;
  final double monthlyLimit;
  final bool onlineEnabled;
  final bool internationalEnabled;
  final bool contactlessEnabled;

  @override
  List<Object?> get props => [
    dailyPurchaseLimit,
    dailyAtmLimit,
    monthlyLimit,
    onlineEnabled,
    internationalEnabled,
    contactlessEnabled,
  ];
}

class BankCard extends Equatable {
  const BankCard({
    required this.id,
    required this.last4,
    required this.kind,
    required this.status,
    required this.cardholderName,
    required this.expiryMonth,
    required this.expiryYear,
    required this.isPrimary,
    required this.isSupplementary,
    required this.productNameEn,
    required this.productNameAr,
    required this.issuedAt,
    this.network,
    this.accountId,
    this.accountNumberMasked,
    this.availableBalance,
    this.creditLimit,
    this.availableCredit,
    this.outstandingBalance,
    this.statementBalance,
    this.minimumPayment,
    this.paymentDueDate,
    this.limits,
    this.productCode = '',
    this.currency,
  });

  final String id;
  final String last4;
  final String kind;
  final String? network;
  final String status;
  final String cardholderName;
  final int expiryMonth;
  final int expiryYear;
  final bool isPrimary;
  final bool isSupplementary;
  final String? accountId;
  final String? accountNumberMasked;
  final double? availableBalance;
  final String productNameEn;
  final String productNameAr;
  final double? creditLimit;
  final double? availableCredit;
  final double? outstandingBalance;
  final double? statementBalance;
  final double? minimumPayment;
  final DateTime? paymentDueDate;
  final DateTime issuedAt;
  final CardLimits? limits;
  final String productCode;
  final String? currency;

  bool get isCredit => kind == 'credit';
  bool get isActive => status == 'active';
  bool get isFrozen => status == 'frozen';
  bool get isInactive =>
      status == 'lost' ||
      status == 'stolen' ||
      status == 'blocked' ||
      status == 'cancelled';

  String productName({required bool arabic}) =>
      arabic ? productNameAr : productNameEn;

  @override
  List<Object?> get props => [
    id,
    status,
    limits,
    outstandingBalance,
    availableCredit,
  ];
}

class CardsOverview extends Equatable {
  const CardsOverview({
    required this.cards,
    required this.activeCount,
    required this.frozenCount,
    required this.creditOutstandingTotal,
  });

  final List<BankCard> cards;
  final int activeCount;
  final int frozenCount;
  final double creditOutstandingTotal;

  @override
  List<Object?> get props => [
    cards,
    activeCount,
    frozenCount,
    creditOutstandingTotal,
  ];
}

class CardStatement extends Equatable {
  const CardStatement({
    required this.id,
    required this.periodStart,
    required this.periodEnd,
    required this.statementBalance,
    required this.minimumPayment,
    required this.dueDate,
    required this.status,
  });

  final String id;
  final DateTime periodStart;
  final DateTime periodEnd;
  final double statementBalance;
  final double minimumPayment;
  final DateTime dueDate;
  final String status;

  @override
  List<Object?> get props => [id, status];
}
