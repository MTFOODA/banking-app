import 'package:equatable/equatable.dart';

class Announcement extends Equatable {
  const Announcement({
    required this.id,
    required this.titleEn,
    required this.titleAr,
    required this.bodyEn,
    required this.bodyAr,
    required this.category,
    required this.priority,
    required this.status,
    this.summaryEn,
    this.summaryAr,
    this.imageUrl,
    this.publishAt,
    this.expiresAt,
    this.ctaLabelEn,
    this.ctaLabelAr,
    this.ctaRoute,
    this.displayLocation = 'home',
    this.publiclyAddressed = true,
    this.bankCode,
  });

  final String id;
  final String titleEn;
  final String titleAr;
  final String bodyEn;
  final String bodyAr;
  final String? summaryEn;
  final String? summaryAr;
  final String category;
  final String priority;
  final String status;
  final String? imageUrl;
  final DateTime? publishAt;
  final DateTime? expiresAt;
  final String? ctaLabelEn;
  final String? ctaLabelAr;
  final String? ctaRoute;
  final String displayLocation;
  final bool publiclyAddressed;
  final String? bankCode;

  String title(bool arabic) => arabic ? titleAr : titleEn;
  String body(bool arabic) => arabic ? bodyAr : bodyEn;
  String summary(bool arabic) {
    final value = arabic ? summaryAr : summaryEn;
    return value == null || value.isEmpty ? body(arabic) : value;
  }

  String? ctaLabel(bool arabic) => arabic ? ctaLabelAr : ctaLabelEn;

  @override
  List<Object?> get props => [
    id,
    category,
    priority,
    status,
    displayLocation,
    publiclyAddressed,
    titleEn,
    titleAr,
    bodyEn,
    bodyAr,
  ];
}

class BankingProduct extends Equatable {
  const BankingProduct({
    required this.id,
    required this.code,
    required this.nameEn,
    required this.nameAr,
    required this.productType,
    required this.summaryEn,
    required this.summaryAr,
    required this.detailsEn,
    required this.detailsAr,
    this.pricingNoteEn,
    this.pricingNoteAr,
    this.eligibilityEn,
    this.eligibilityAr,
    this.imageUrl,
    this.ctaRoute,
  });

  final String id;
  final String code;
  final String nameEn;
  final String nameAr;
  final String productType;
  final String summaryEn;
  final String summaryAr;
  final String detailsEn;
  final String detailsAr;
  final String? pricingNoteEn;
  final String? pricingNoteAr;
  final String? eligibilityEn;
  final String? eligibilityAr;
  final String? imageUrl;
  final String? ctaRoute;

  String name(bool arabic) => arabic ? nameAr : nameEn;
  String summary(bool arabic) => arabic ? summaryAr : summaryEn;
  String details(bool arabic) => arabic ? detailsAr : detailsEn;
  String? pricingNote(bool arabic) => arabic ? pricingNoteAr : pricingNoteEn;
  String? eligibility(bool arabic) => arabic ? eligibilityAr : eligibilityEn;

  @override
  List<Object?> get props => [id, code, productType];
}

class Offer extends Equatable {
  const Offer({
    required this.id,
    required this.titleEn,
    required this.titleAr,
    required this.descriptionEn,
    required this.descriptionAr,
    required this.status,
    this.imageUrl,
    this.ctaRoute,
    this.startAt,
    this.endAt,
    this.isFeatured = false,
  });

  final String id;
  final String titleEn;
  final String titleAr;
  final String descriptionEn;
  final String descriptionAr;
  final String status;
  final String? imageUrl;
  final String? ctaRoute;
  final DateTime? startAt;
  final DateTime? endAt;
  final bool isFeatured;

  String title(bool arabic) => arabic ? titleAr : titleEn;
  String description(bool arabic) => arabic ? descriptionAr : descriptionEn;

  @override
  List<Object?> get props => [id, status, isFeatured];
}

class DiscoverContent extends Equatable {
  const DiscoverContent({
    required this.announcements,
    required this.products,
    required this.offers,
  });

  final List<Announcement> announcements;
  final List<BankingProduct> products;
  final List<Offer> offers;

  @override
  List<Object?> get props => [announcements, products, offers];
}
