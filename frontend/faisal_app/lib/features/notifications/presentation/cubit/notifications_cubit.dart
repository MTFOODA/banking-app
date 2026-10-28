import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/notification_entities.dart';
import '../../domain/repositories/notifications_repository.dart';

class NotificationsState extends Equatable {
  const NotificationsState({
    this.items = const <AppNotification>[],
    this.unreadCount = 0,
    this.loading = true,
    this.error,
  });

  final List<AppNotification> items;
  final int unreadCount;
  final bool loading;
  final AppException? error;

  bool get isEmpty => !loading && items.isEmpty && error == null;

  NotificationsState copyWith({
    List<AppNotification>? items,
    int? unreadCount,
    bool? loading,
    AppException? error,
    bool clearError = false,
  }) {
    return NotificationsState(
      items: items ?? this.items,
      unreadCount: unreadCount ?? this.unreadCount,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [items, unreadCount, loading, error?.code];
}

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(this._repository) : super(const NotificationsState());

  final NotificationsRepository _repository;

  Future<void> load() async {
    if (isClosed) return;
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final feed = await _repository.fetchNotifications();
      if (isClosed) return;
      emit(
        state.copyWith(
          items: feed.items,
          unreadCount: feed.unreadCount,
          loading: false,
        ),
      );
    } on AppException catch (error) {
      if (!isClosed) emit(state.copyWith(loading: false, error: error));
    }
  }

  Future<void> markRead(String notificationId) async {
    final target = state.items.firstWhere(
      (item) => item.id == notificationId,
      orElse: () => state.items.first,
    );
    if (target.isRead) {
      return;
    }
    try {
      await _repository.markRead(notificationId);
      final updated = state.items
          .map(
            (item) => item.id == notificationId
                ? AppNotification(
                    id: item.id,
                    category: item.category,
                    titleEn: item.titleEn,
                    titleAr: item.titleAr,
                    bodyEn: item.bodyEn,
                    bodyAr: item.bodyAr,
                    priority: item.priority,
                    isRead: true,
                    createdAt: item.createdAt,
                    ctaRoute: item.ctaRoute,
                    relatedEntityType: item.relatedEntityType,
                    relatedEntityId: item.relatedEntityId,
                  )
                : item,
          )
          .toList(growable: false);
      emit(
        state.copyWith(
          items: updated,
          unreadCount: (state.unreadCount - 1).clamp(0, 999),
        ),
      );
    } on AppException catch (error) {
      emit(state.copyWith(error: error));
    }
  }

  Future<void> markAllRead() async {
    try {
      await _repository.markAllRead();
      emit(
        NotificationsState(
          items: state.items
              .map(
                (item) => AppNotification(
                  id: item.id,
                  category: item.category,
                  titleEn: item.titleEn,
                  titleAr: item.titleAr,
                  bodyEn: item.bodyEn,
                  bodyAr: item.bodyAr,
                  priority: item.priority,
                  isRead: true,
                  createdAt: item.createdAt,
                  ctaRoute: item.ctaRoute,
                  relatedEntityType: item.relatedEntityType,
                  relatedEntityId: item.relatedEntityId,
                ),
              )
              .toList(growable: false),
          unreadCount: 0,
          loading: false,
        ),
      );
    } on AppException catch (error) {
      emit(state.copyWith(error: error));
    }
  }
}
