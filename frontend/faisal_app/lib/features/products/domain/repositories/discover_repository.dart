import '../entities/discover_entities.dart';

abstract class DiscoverRepository {
  Future<DiscoverContent> loadDiscover();

  Future<Announcement> fetchAnnouncement(String announcementId);
  Future<List<Announcement>> fetchPublicAnnouncements({String? bankCode});
}
