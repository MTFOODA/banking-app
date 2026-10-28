import 'package:equatable/equatable.dart';

class Biller extends Equatable {
  const Biller({
    required this.code,
    required this.nameEn,
    required this.nameAr,
    required this.category,
    this.amountDue,
  });

  final String code;
  final String nameEn;
  final String nameAr;
  final String category;
  final double? amountDue;

  String name(bool arabic) => arabic ? nameAr : nameEn;

  @override
  List<Object?> get props => [code, category];
}

class PaymentResult extends Equatable {
  const PaymentResult({
    required this.reference,
    required this.status,
    required this.amount,
    required this.currency,
    required this.billerNameEn,
    required this.billerNameAr,
    required this.isSimulated,
    required this.createdAt,
  });

  final String reference;
  final String status;
  final double amount;
  final String currency;
  final String billerNameEn;
  final String billerNameAr;
  final bool isSimulated;
  final DateTime createdAt;

  @override
  List<Object?> get props => [reference, status, amount];
}
