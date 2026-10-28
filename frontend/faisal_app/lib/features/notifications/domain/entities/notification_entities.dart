import 'package:equatable/equatable.dart';

class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.category,
    required this.titleEn,
    required this.titleAr,
    required this.bodyEn,
    required this.bodyAr,
    required this.priority,
    required this.isRead,
    required this.createdAt,
    this.ctaRoute,
    this.relatedEntityType,
    this.relatedEntityId,
  });

  final String id;
  final String category;
  final String titleEn;
  final String titleAr;
  final String bodyEn;
  final String bodyAr;
  final String priority;
  final bool isRead;
  final DateTime createdAt;
  final String? ctaRoute;
  final String? relatedEntityType;
  final String? relatedEntityId;

  String title(bool arabic) => arabic ? titleAr : titleEn;
  String body(bool arabic) => arabic ? bodyAr : bodyEn;

  @override
  List<Object?> get props => [id, isRead, category, createdAt];
}

class NotificationFeed extends Equatable {
  const NotificationFeed({required this.items, required this.unreadCount});

  final List<AppNotification> items;
  final int unreadCount;

  @override
  List<Object?> get props => [items, unreadCount];
}
