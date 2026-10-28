import 'package:flutter/material.dart';

import '../../../../core/theme/faisal_palette.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/faisal_account_card.dart';
import '../../../../core/widgets/faisal_loading_view.dart';
import '../../../../core/widgets/faisal_page.dart';
import '../../../../core/widgets/faisal_state_views.dart';
import '../../../../l10n/app_localizations.dart';
import 'account_services_section.dart';
import '../cubit/accounts_cubit.dart';
import '../../../products/presentation/pages/investments_page.dart';

class AccountsPage extends StatelessWidget {
  const AccountsPage({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AccountsCubit>()..load(),
      child: _AccountsTabs(initialTab: initialTab),
    );
  }
}

class _AccountsTabs extends StatefulWidget {
  const _AccountsTabs({required this.initialTab});
  final int initialTab;
  @override
  State<_AccountsTabs> createState() => _AccountsTabsState();
}

class _AccountsTabsState extends State<_AccountsTabs>
    with SingleTickerProviderStateMixin {
  late final _tabs = TabController(
    length: 3,
    initialIndex: widget.initialTab,
    vsync: this,
  )..addListener(_changed);
  late int _lastTab = widget.initialTab;
  void _changed() {
    if (!_tabs.indexIsChanging && _lastTab != _tabs.index) {
      _lastTab = _tabs.index;
      if (_lastTab == 0) context.read<AccountsCubit>().load(silent: true);
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      children: [
        Material(
          color: Theme.of(context).colorScheme.surface,
          child: TabBar(
            controller: _tabs,
            tabs: [
              Tab(key: const ValueKey('account_cash_tab'), text: l.accounts),
              Tab(
                key: const ValueKey('account_certificates_tab'),
                text: l.certificatesTitle,
              ),
              Tab(
                key: const ValueKey('account_funds_tab'),
                text: l.investmentFundsTitle,
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: const [
              _AccountsView(),
              InvestmentsPage(productType: 'certificate', embedded: true),
              InvestmentsPage(productType: 'fund', embedded: true),
            ],
          ),
        ),
      ],
    );
  }
}

class _AccountsView extends StatelessWidget {
  const _AccountsView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    return BlocBuilder<AccountsCubit, AccountsState>(
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () => context.read<AccountsCubit>().load(silent: true),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xxxl,
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSizes.maxContentWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(l10n.accounts, style: context.texts.headlineSmall),
                      const SizedBox(height: AppSpacing.lg),
                      if (state is AccountsLoading)
                        const FaisalLoadingView(lines: 3)
                      else if (state is AccountsFailure)
                        FaisalErrorView(
                          error: state.error,
                          onRetry: () => context.read<AccountsCubit>().load(),
                        )
                      else if (state is AccountsLoaded) ...[
                        FaisalSurface(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.totalAcrossAccounts,
                                style: context.texts.bodySmall?.copyWith(
                                  color: context.colors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                FaisalFormatters.money(
                                  state.overview.totals.totalAvailable,
                                  currency: state.overview.totals.currency,
                                  locale: locale,
                                ),
                                style: context.texts.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                l10n.activeAccountsCount(
                                  state.overview.totals.eligibleAccounts,
                                ),
                                style: context.texts.bodySmall?.copyWith(
                                  color: context.colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        if (state.overview.accounts.isEmpty)
                          FaisalEmptyState(
                            title: l10n.noData,
                            icon: Icons.account_balance_wallet_outlined,
                          )
                        else
                          ...state.overview.accounts.map(
                            (account) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.md,
                              ),
                              child: FaisalAccountCard(
                                account: account,
                                onTap: () =>
                                    context.push(AppRoutes.account(account.id)),
                                onTransactions: () => context.push(
                                  AppRoutes.accountTransactionHistory(
                                    account.id,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: AppSpacing.sm),
                        const AccountServicesSection(),
                      ],
                    ],
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
