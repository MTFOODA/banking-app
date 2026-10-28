import 'package:equatable/equatable.dart';

class CardEligibleAccount extends Equatable {
  const CardEligibleAccount({
    required this.id,
    required this.masked,
    required this.currency,
    required this.type,
  });
  final String id, masked, currency, type;
  @override
  List<Object?> get props => [id, masked, currency, type];
}

class CardProduct extends Equatable {
  const CardProduct({
    required this.code,
    required this.variant,
    required this.nameEn,
    required this.nameAr,
    required this.eligible,
    required this.accounts,
    required this.currencies,
    this.investmentOnly = false,
    this.under21Only = false,
    this.reason,
    this.annualFee = 0,
    this.feeCurrency = 'EGP',
    this.network,
  });
  final String code, variant, nameEn, nameAr, feeCurrency;
  final String? reason, network;
  final bool eligible, investmentOnly, under21Only;
  final double annualFee;
  final List<CardEligibleAccount> accounts;
  final List<String> currencies;
  String name(bool arabic) => arabic ? nameAr : nameEn;
  @override
  List<Object?> get props => [code, eligible, reason, accounts, annualFee];
}
