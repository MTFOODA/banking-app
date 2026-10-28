import '../entities/notification_entities.dart';

abstract class NotificationsRepository {
  Future<NotificationFeed> fetchNotifications({int page, int pageSize});

  Future<void> markRead(String notificationId);

  Future<void> markAllRead();
}
