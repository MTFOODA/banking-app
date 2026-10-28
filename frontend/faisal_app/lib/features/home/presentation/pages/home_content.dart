import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/faisal_palette.dart';
import '../../../../core/widgets/faisal_account_card.dart';
import '../../../../core/widgets/faisal_balance_visibility.dart';
import '../../../../core/widgets/faisal_page.dart';
import '../../../../core/widgets/faisal_section_header.dart';
import '../../../../core/widgets/faisal_state_views.dart';
import '../../../../core/widgets/faisal_transaction_tile.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/home_entities.dart';
import '../cubit/home_cubit.dart';
import '../widgets/featured_banner_strip.dart';
import '../widgets/home_balance_card.dart';

class HomeContent extends StatelessWidget {
  const HomeContent({
    super.key,
    required this.state,
    required this.visibility,
    required this.onRetry,
  });

  final HomeState state;
  final BalanceVisibilityController visibility;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state is HomeLoaded)
          HomeBalanceCard(
            overview: (state as HomeLoaded).overview,
            visibility: visibility,
            onAccountsTap: () => context.go(AppRoutes.accounts),
          )
        else if (state is HomeFailure)
          FaisalSurface(
            child: FaisalErrorView(
              error: (state as HomeFailure).error,
              onRetry: onRetry,
            ),
          )
        else
          const FaisalSurface(
            child: SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        if (state is HomeLoaded)
          ..._loadedSections(context, (state as HomeLoaded).overview, l10n),
      ],
    );
  }

  List<Widget> _loadedSections(
    BuildContext context,
    HomeOverview overview,
    AppLocalizations l10n,
  ) {
    return [
      FaisalSectionHeader(
        title: l10n.myAccounts,
        actionLabel: l10n.viewAll,
        onAction: () => context.go(AppRoutes.accounts),
      ),
      ...overview.accounts.accounts
          .take(2)
          .map(
            (account) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: FaisalAccountCard(
                account: account,
                showBalance: visibility.visible,
                onTap: () => context.push(AppRoutes.account(account.id)),
                onTransactions: () => context.push(
                  AppRoutes.accountTransactionHistory(account.id),
                ),
              ),
            ),
          ),
      if (overview.banners.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.sm),
        FaisalSectionHeader(title: l10n.featured),
        FeaturedBannerStrip(
          banners: overview.banners,
          onBannerTap: (banner) => context.push('/announcements/${banner.id}'),
        ),
      ],
      const SizedBox(height: AppSpacing.lg),
      FaisalSectionHeader(
        title: l10n.recentTransactions,
        actionLabel: l10n.viewAll,
        onAction: () => context.push(AppRoutes.transactions),
      ),
      if (overview.recentTransactions.isEmpty)
        FaisalSurface(
          child: Text(
            l10n.noRecentTransactions,
            style: context.texts.bodySmall,
          ),
        )
      else
        FaisalSurface(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            children: [
              for (final transaction in overview.recentTransactions)
                FaisalTransactionTile(
                  transaction: transaction,
                  onTap: () => context.push(
                    '${AppRoutes.transactions}/${transaction.id}',
                  ),
                ),
            ],
          ),
        ),
      const SizedBox(height: AppSpacing.xxl),
    ];
  }
}
