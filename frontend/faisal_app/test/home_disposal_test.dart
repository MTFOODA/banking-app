import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:faisal_app/core/errors/app_exception.dart';
import 'package:faisal_app/features/accounts/domain/entities/account_entities.dart';
import 'package:faisal_app/features/cards/domain/entities/card_entities.dart';
import 'package:faisal_app/features/home/domain/entities/home_entities.dart';
import 'package:faisal_app/features/home/domain/repositories/home_repository.dart';
import 'package:faisal_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:faisal_app/features/notifications/domain/entities/notification_entities.dart';
import 'package:faisal_app/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:faisal_app/features/notifications/presentation/cubit/notifications_cubit.dart';

class PendingHome implements HomeRepository {
  final pending = Completer<HomeOverview>();
  @override
  Future<HomeOverview> load() => pending.future;
}

class PendingNotifications implements NotificationsRepository {
  final pending = Completer<NotificationFeed>();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  @override
  Future<NotificationFeed> fetchNotifications({
    int page = 1,
    int pageSize = 20,
  }) => pending.future;
}

void main() {
  for (final fails in [false, true]) {
    test(
      'leaving Home during ${fails ? 'failed' : 'successful'} network response is safe',
      () async {
        final repo = PendingHome(), notifications = PendingNotifications();
        final home = HomeCubit(repo), feed = NotificationsCubit(notifications);
        final homeLoad = home.load(), feedLoad = feed.load();
        await home.close();
        await feed.close();
        if (fails) {
          repo.pending.completeError(
            const AppException(code: AppErrorCode.network),
          );
          notifications.pending.completeError(
            const AppException(code: AppErrorCode.network),
          );
        } else {
          repo.pending.complete(
            const HomeOverview(
              accounts: AccountsOverview(
                totals: AccountTotals(
                  totalAvailable: 0,
                  totalCurrent: 0,
                  currency: 'EGP',
                  eligibleAccounts: 0,
                ),
                accounts: [],
              ),
              cards: CardsOverview(
                cards: [],
                activeCount: 0,
                frozenCount: 0,
                creditOutstandingTotal: 0,
              ),
              recentTransactions: [],
              banners: [],
            ),
          );
          notifications.pending.complete(
            const NotificationFeed(items: [], unreadCount: 0),
          );
        }
        await expectLater(homeLoad, completes);
        await expectLater(feedLoad, completes);
      },
    );
  }
}
