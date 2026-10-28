import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/json_utils.dart';
import '../../domain/entities/discover_entities.dart';
import '../../domain/repositories/discover_repository.dart';

class DiscoverRepositoryImpl implements DiscoverRepository {
  DiscoverRepositoryImpl(this._client);

  final DioClient _client;

  @override
  Future<List<Announcement>> fetchPublicAnnouncements() async {
    final data = await _client.get('/public/announcements');
    return (data as List).map((item) => announcement(asMap(item))).toList();
  }

  @override
  Future<DiscoverContent> loadDiscover() async {
    final results = await Future.wait([
      _client.get('/announcements'),
      _client.get('/products'),
      _client.get('/offers'),
    ]);
    return DiscoverContent(
      announcements: (results[0] is List)
          ? (results[0] as List)
                .map((item) => announcement(asMap(item)))
                .toList(growable: false)
          : const <Announcement>[],
      products: (results[1] is List)
          ? (results[1] as List)
                .map((item) => product(asMap(item)))
                .toList(growable: false)
          : const <BankingProduct>[],
      offers: (results[2] is List)
          ? (results[2] as List)
                .map((item) => offer(asMap(item)))
                .toList(growable: false)
          : const <Offer>[],
    );
  }

  @override
  Future<Announcement> fetchAnnouncement(String announcementId) async {
    final data = await _client.get('/announcements/$announcementId');
    return announcement(asMap(data));
  }

  Announcement announcement(Map<String, dynamic> json) {
    return Announcement(
      id: asString(json['id']),
      titleEn: asString(json['title_en']),
      titleAr: asString(json['title_ar']),
      bodyEn: asString(json['body_en']),
      bodyAr: asString(json['body_ar']),
      summaryEn: asStringOrNull(json['summary_en']),
      summaryAr: asStringOrNull(json['summary_ar']),
      category: asString(json['category'], 'announcement'),
      priority: asString(json['priority'], 'normal'),
      displayLocation: asString(json['display_location'], 'home'),
      status: asString(json['status'], 'published'),
      imageUrl: asStringOrNull(json['image_url']),
      publishAt: asDateOrNull(json['publish_at']),
      expiresAt: asDateOrNull(json['expires_at']),
      ctaLabelEn: asStringOrNull(json['cta_label_en']),
      ctaLabelAr: asStringOrNull(json['cta_label_ar']),
      ctaRoute: asStringOrNull(json['cta_route']),
    );
  }

  BankingProduct product(Map<String, dynamic> json) {
    return BankingProduct(
      id: asString(json['id']),
      code: asString(json['code']),
      nameEn: asString(json['name_en']),
      nameAr: asString(json['name_ar']),
      productType: asString(json['product_type'], 'investment'),
      summaryEn: asString(json['summary_en']),
      summaryAr: asString(json['summary_ar']),
      detailsEn: asString(json['details_en']),
      detailsAr: asString(json['details_ar']),
      pricingNoteEn: asStringOrNull(json['pricing_note_en']),
      pricingNoteAr: asStringOrNull(json['pricing_note_ar']),
      eligibilityEn: asStringOrNull(json['eligibility_en']),
      eligibilityAr: asStringOrNull(json['eligibility_ar']),
      imageUrl: asStringOrNull(json['image_url']),
      ctaRoute: asStringOrNull(json['cta_route']),
    );
  }

  Offer offer(Map<String, dynamic> json) {
    return Offer(
      id: asString(json['id']),
      titleEn: asString(json['title_en']),
      titleAr: asString(json['title_ar']),
      descriptionEn: asString(json['description_en']),
      descriptionAr: asString(json['description_ar']),
      status: asString(json['status'], 'published'),
      imageUrl: asStringOrNull(json['image_url']),
      ctaRoute: asStringOrNull(json['cta_route']),
      startAt: asDateOrNull(json['start_at']),
      endAt: asDateOrNull(json['end_at']),
      isFeatured: asBool(json['is_featured']),
    );
  }
}
