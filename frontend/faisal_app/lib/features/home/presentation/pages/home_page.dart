import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/faisal_balance_visibility.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../authentication/presentation/bloc/auth_event.dart';
import '../../../notifications/presentation/cubit/notifications_cubit.dart';
import '../cubit/home_cubit.dart';
import '../widgets/home_header.dart';
import '../widgets/home_quick_actions.dart';
import 'home_content.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<HomeCubit>()..load()),
        BlocProvider(create: (_) => sl<NotificationsCubit>()..load()),
      ],
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  final BalanceVisibilityController _visibility = BalanceVisibilityController();

  @override
  void dispose() {
    _visibility.dispose();
    super.dispose();
  }

  String _greeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return l10n.greetingMorning;
    }
    if (hour < 17) {
      return l10n.greetingAfternoon;
    }
    return l10n.greetingEvening;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authState = context.watch<AuthBloc>().state;
    final unread = context.watch<NotificationsCubit>().state.unreadCount;
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final displayName =
        authState.user?.profile?.displayName(arabic: arabic) ??
        authState.user?.displayName ??
        '';

    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () => context.read<HomeCubit>().load(silent: true),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              HomeHeader(
                greeting: _greeting(l10n),
                name: displayName,
                unreadCount: unread,
                notificationsTooltip: l10n.notifications,
                logoutTooltip: l10n.signOut,
                onNotifications: () => context.push(AppRoutes.notifications),
                onLogout: () =>
                    context.read<AuthBloc>().add(const AuthLogoutRequested()),
              ),
              Transform.translate(
                offset: const Offset(0, -AppSpacing.xxxl),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppSizes.maxContentWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          HomeQuickActions(
                            onTransfers: () => context.go(AppRoutes.transfers),
                            onPayments: () => context.push(AppRoutes.payments),
                            onCards: () => context.go(AppRoutes.cards),
                            onAccounts: () => context.go(AppRoutes.accounts),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          HomeContent(
                            state: state,
                            visibility: _visibility,
                            onRetry: () => context.read<HomeCubit>().load(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
