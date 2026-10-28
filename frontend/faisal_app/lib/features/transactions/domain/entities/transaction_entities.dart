import 'package:equatable/equatable.dart';

class BankTransaction extends Equatable {
  const BankTransaction({
    required this.id,
    required this.reference,
    required this.type,
    required this.direction,
    required this.amount,
    required this.currency,
    required this.description,
    required this.status,
    required this.isSimulated,
    required this.occurredAt,
    this.descriptionAr,
    this.counterparty,
    this.merchant,
    this.balanceAfter,
    this.accountId,
    this.cardId,
    this.cardLast4,
    this.accountNumberMasked,
    this.fees = 0,
  });

  final String id;
  final String reference;
  final String type;
  final String direction;
  final double amount;
  final String currency;
  final String description;
  final String? descriptionAr;
  final String? counterparty;
  final String? merchant;
  final String status;
  final bool isSimulated;
  final double? balanceAfter;
  final DateTime occurredAt;
  final String? accountId;
  final String? cardId;
  final String? cardLast4;
  final String? accountNumberMasked;
  final double fees;

  bool get isCredit => direction == 'credit';

  String localizedDescription(bool arabic) {
    final translated = descriptionAr;
    return arabic && translated != null && translated.isNotEmpty
        ? translated
        : description;
  }

  @override
  List<Object?> get props => [id, status, amount, direction, occurredAt];
}

class TransactionPage extends Equatable {
  const TransactionPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.hasNext,
  });

  final List<BankTransaction> items;
  final int page;
  final int pageSize;
  final int total;
  final bool hasNext;

  @override
  List<Object?> get props => [items, page, total, hasNext];
}

class TransactionFilter extends Equatable {
  const TransactionFilter({
    this.type,
    this.direction,
    this.status,
    this.dateFrom,
    this.dateTo,
    this.minAmount,
    this.maxAmount,
    this.search,
    this.accountId,
    this.cardId,
  });

  final String? type;
  final String? direction;
  final String? status;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final double? minAmount;
  final double? maxAmount;
  final String? search;
  final String? accountId;
  final String? cardId;

  bool get isEmpty =>
      type == null &&
      direction == null &&
      status == null &&
      dateFrom == null &&
      dateTo == null &&
      minAmount == null &&
      maxAmount == null &&
      (search == null || search!.isEmpty);

  int get activeCount => [
    type,
    direction,
    status,
    dateFrom,
    dateTo,
    minAmount,
    maxAmount,
    (search != null && search!.isNotEmpty) ? search : null,
  ].where((value) => value != null).length;

  TransactionFilter copyWith({
    String? type,
    String? direction,
    String? status,
    DateTime? dateFrom,
    DateTime? dateTo,
    double? minAmount,
    double? maxAmount,
    String? search,
    bool clearDates = false,
    bool clearAmounts = false,
    bool clearType = false,
    bool clearDirection = false,
    bool clearStatus = false,
    bool clearSearch = false,
  }) {
    return TransactionFilter(
      type: clearType ? null : (type ?? this.type),
      direction: clearDirection ? null : (direction ?? this.direction),
      status: clearStatus ? null : (status ?? this.status),
      dateFrom: clearDates ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDates ? null : (dateTo ?? this.dateTo),
      minAmount: clearAmounts ? null : (minAmount ?? this.minAmount),
      maxAmount: clearAmounts ? null : (maxAmount ?? this.maxAmount),
      search: clearSearch ? null : (search ?? this.search),
      accountId: accountId,
      cardId: cardId,
    );
  }

  Map<String, dynamic> toQuery() => {
    'transaction_type': type,
    'direction': direction,
    'status': status,
    'date_from': dateFrom?.toIso8601String().split('T').first,
    'date_to': dateTo?.toIso8601String().split('T').first,
    'min_amount': minAmount,
    'max_amount': maxAmount,
    'search': search,
    'account_id': accountId,
    'card_id': cardId,
  };

  @override
  List<Object?> get props => [
    type,
    direction,
    status,
    dateFrom,
    dateTo,
    minAmount,
    maxAmount,
    search,
    accountId,
    cardId,
  ];
}
