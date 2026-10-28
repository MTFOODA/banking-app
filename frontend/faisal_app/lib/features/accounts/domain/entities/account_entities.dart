import 'package:equatable/equatable.dart';

class LinkedCard extends Equatable {
  const LinkedCard({
    required this.id,
    required this.last4,
    required this.kind,
    required this.status,
    this.network,
  });

  final String id;
  final String last4;
  final String kind;
  final String status;
  final String? network;

  @override
  List<Object?> get props => [id, last4, status];
}

class Account extends Equatable {
  const Account({
    required this.id,
    required this.accountType,
    required this.accountNumberMasked,
    required this.currency,
    required this.status,
    required this.currentBalance,
    required this.availableBalance,
    required this.blockedBalance,
    required this.productNameEn,
    required this.productNameAr,
    required this.openedAt,
    this.iban,
    this.linkedCards = const <LinkedCard>[],
    this.services = const <String>[],
  });

  final String id;
  final String accountType;
  final String accountNumberMasked;
  final String? iban;
  final String currency;
  final String status;
  final double currentBalance;
  final double availableBalance;
  final double blockedBalance;
  final String productNameEn;
  final String productNameAr;
  final DateTime openedAt;
  final List<LinkedCard> linkedCards;
  final List<String> services;

  bool get isActive => status == 'active';

  String get last4 {
    final digits = accountNumberMasked.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length >= 4
        ? digits.substring(digits.length - 4)
        : accountNumberMasked;
  }

  String productName({required bool arabic}) =>
      arabic ? productNameAr : productNameEn;

  @override
  List<Object?> get props => [
    id,
    status,
    availableBalance,
    currentBalance,
    linkedCards,
  ];
}

class AccountTotals extends Equatable {
  const AccountTotals({
    required this.totalAvailable,
    required this.totalCurrent,
    required this.currency,
    required this.eligibleAccounts,
  });

  final double totalAvailable;
  final double totalCurrent;
  final String currency;
  final int eligibleAccounts;

  @override
  List<Object?> get props => [
    totalAvailable,
    totalCurrent,
    currency,
    eligibleAccounts,
  ];
}

class AccountsOverview extends Equatable {
  const AccountsOverview({required this.totals, required this.accounts});

  final AccountTotals totals;
  final List<Account> accounts;

  @override
  List<Object?> get props => [totals, accounts];
}

class AccountProduct extends Equatable {
  const AccountProduct({
    required this.id,
    required this.code,
    required this.nameEn,
    required this.nameAr,
    required this.accountType,
    required this.currency,
    required this.descriptionEn,
    required this.descriptionAr,
    required this.minimumBalance,
    required this.isActive,
  });

  final String id;
  final String code;
  final String nameEn;
  final String nameAr;
  final String accountType;
  final String currency;
  final String descriptionEn;
  final String descriptionAr;
  final double minimumBalance;
  final bool isActive;

  @override
  List<Object?> get props => [id, code, isActive];
}
