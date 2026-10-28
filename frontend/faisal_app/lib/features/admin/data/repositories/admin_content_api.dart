import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/json_utils.dart';
import '../../../products/domain/entities/discover_entities.dart';

/// Content-management API calls shared by the admin repository implementation.
mixin AdminContentApi {
  DioClient get client;

  Future<List<Announcement>> fetchAnnouncements() async {
    final items = <Announcement>[];
    var page = 1;
    while (true) {
      final json = asMap(
        await client.get(
          '/admin/announcements',
          query: {'page': page, 'page_size': 100},
        ),
      );
      items.addAll(asMapList(json['items']).map(_announcement));
      if (json['has_next'] != true) break;
      page++;
    }
    return items;
  }

  Future<Announcement> createAnnouncement(Map<String, dynamic> payload) async {
    final data = await client.post('/admin/announcements', body: payload);
    return _announcement(asMap(data));
  }

  Future<Announcement> updateAnnouncement(
    String id,
    Map<String, dynamic> payload,
  ) async {
    final data = await client.patch('/admin/announcements/$id', body: payload);
    return _announcement(asMap(data));
  }

  Future<Announcement> publishAnnouncement(String id) async {
    final data = await client.post('/admin/announcements/$id/publish');
    return _announcement(asMap(data));
  }

  Future<Announcement> archiveAnnouncement(String id) async {
    final data = await client.post('/admin/announcements/$id/archive');
    return _announcement(asMap(data));
  }

  Future<Announcement> duplicateAnnouncement(String id) async {
    final data = await client.post('/admin/announcements/$id/duplicate');
    return _announcement(asMap(data));
  }

  Future<List<BankingProduct>> fetchProducts() async {
    final data = await client.get('/admin/products');
    if (data is List) {
      return data.map((item) => _product(asMap(item))).toList(growable: false);
    }
    return const <BankingProduct>[];
  }

  Future<BankingProduct> createProduct(Map<String, dynamic> payload) async {
    final data = await client.post('/admin/products', body: payload);
    return _product(asMap(data));
  }

  Future<List<Offer>> fetchOffers() async {
    final data = await client.get('/admin/offers');
    if (data is List) {
      return data.map((item) => _offer(asMap(item))).toList(growable: false);
    }
    return const <Offer>[];
  }

  Future<Offer> createOffer(Map<String, dynamic> payload) async {
    final data = await client.post('/admin/offers', body: payload);
    return _offer(asMap(data));
  }

  Announcement _announcement(Map<String, dynamic> json) {
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
      publiclyAddressed: asMapList(json['audiences'])
          .every((a) => a['audience_type'] == 'all'),
      status: asString(json['status'], 'draft'),
      imageUrl: asStringOrNull(json['image_url']),
      publishAt: asDateOrNull(json['publish_at']),
      expiresAt: asDateOrNull(json['expires_at']),
      ctaLabelEn: asStringOrNull(json['cta_label_en']),
      ctaLabelAr: asStringOrNull(json['cta_label_ar']),
      ctaRoute: asStringOrNull(json['cta_route']),
    );
  }

  BankingProduct _product(Map<String, dynamic> json) {
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

  Offer _offer(Map<String, dynamic> json) {
    return Offer(
      id: asString(json['id']),
      titleEn: asString(json['title_en']),
      titleAr: asString(json['title_ar']),
      descriptionEn: asString(json['description_en']),
      descriptionAr: asString(json['description_ar']),
      status: asString(json['status'], 'draft'),
      imageUrl: asStringOrNull(json['image_url']),
      ctaRoute: asStringOrNull(json['cta_route']),
      startAt: asDateOrNull(json['start_at']),
      endAt: asDateOrNull(json['end_at']),
      isFeatured: asBool(json['is_featured']),
    );
  }
}
