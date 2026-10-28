import 'package:equatable/equatable.dart';

import '../../../accounts/domain/entities/account_entities.dart';
import '../../../cards/domain/entities/card_entities.dart';
import '../../../transactions/domain/entities/transaction_entities.dart';

class FeaturedBanner extends Equatable {
  const FeaturedBanner({
    required this.id,
    required this.titleEn,
    required this.titleAr,
    required this.bodyEn,
    required this.bodyAr,
    required this.category,
    this.imageUrl,
    this.ctaLabelEn,
    this.ctaLabelAr,
    this.ctaRoute,
  });

  final String id;
  final String titleEn;
  final String titleAr;
  final String bodyEn;
  final String bodyAr;
  final String category;
  final String? imageUrl;
  final String? ctaLabelEn;
  final String? ctaLabelAr;
  final String? ctaRoute;

  String title(bool arabic) => arabic ? titleAr : titleEn;
  String body(bool arabic) => arabic ? bodyAr : bodyEn;
  String? ctaLabel(bool arabic) => arabic ? ctaLabelAr : ctaLabelEn;

  @override
  List<Object?> get props => [id, category, titleEn];
}

class HomeOverview extends Equatable {
  const HomeOverview({
    required this.accounts,
    required this.cards,
    required this.recentTransactions,
    required this.banners,
  });

  final AccountsOverview accounts;
  final CardsOverview cards;
  final List<BankTransaction> recentTransactions;
  final List<FeaturedBanner> banners;

  @override
  List<Object?> get props => [accounts, cards, recentTransactions, banners];
}
