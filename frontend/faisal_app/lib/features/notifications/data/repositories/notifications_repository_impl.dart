import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/json_utils.dart';
import '../../domain/entities/notification_entities.dart';
import '../../domain/repositories/notifications_repository.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationsRepositoryImpl(this._client);

  final DioClient _client;

  @override
  Future<NotificationFeed> fetchNotifications({
    int page = 1,
    int pageSize = 30,
  }) async {
    final data = await _client.get(
      '/notifications',
      query: {'page': page, 'page_size': pageSize},
    );
    final json = asMap(data);
    return NotificationFeed(
      items: asMapList(json['items'])
          .map(_notification)
          .toList(growable: false),
      unreadCount: asInt(json['unread_count']),
    );
  }

  @override
  Future<void> markRead(String notificationId) async {
    await _client.post('/notifications/$notificationId/read');
  }

  @override
  Future<void> markAllRead() async {
    await _client.post('/notifications/read-all');
  }

  AppNotification _notification(Map<String, dynamic> json) {
    return AppNotification(
      id: asString(json['id']),
      category: asString(json['category'], 'system'),
      titleEn: asString(json['title_en']),
      titleAr: asString(json['title_ar']),
      bodyEn: asString(json['body_en']),
      bodyAr: asString(json['body_ar']),
      priority: asString(json['priority'], 'normal'),
      isRead: asBool(json['is_read']),
      createdAt: asDate(json['created_at']),
      ctaRoute: asStringOrNull(json['cta_route']),
      relatedEntityType: asStringOrNull(json['related_entity_type']),
      relatedEntityId: asStringOrNull(json['related_entity_id']),
    );
  }
}
