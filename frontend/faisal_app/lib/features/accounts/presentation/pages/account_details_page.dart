import 'package:flutter/material.dart';

import '../../../../core/theme/faisal_palette.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/faisal_app_bar.dart';
import '../../../../core/widgets/faisal_buttons.dart';
import '../../../../core/widgets/faisal_loading_view.dart';
import '../../../../core/widgets/faisal_page.dart';
import '../../../../core/widgets/faisal_rows.dart';
import '../../../../core/widgets/faisal_state_views.dart';
import '../../../../core/widgets/faisal_status_badge.dart';
import '../../../../l10n/app_localizations.dart';
import '../cubit/accounts_cubit.dart';
import 'account_closure_dialog.dart';

class AccountDetailsPage extends StatelessWidget {
  const AccountDetailsPage({super.key, required this.accountId});

  final String accountId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AccountDetailsCubit>(param1: accountId)..load(),
      child: const _AccountDetailsView(),
    );
  }
}

class _AccountDetailsView extends StatelessWidget {
  const _AccountDetailsView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    return BlocBuilder<AccountDetailsCubit, AccountDetailsState>(
      builder: (context, state) {
        if (state is AccountDetailsLoading) {
          return FaisalPage(
            title: l10n.accountDetails,
            child: const FaisalLoadingView(lines: 4),
          );
        }
        if (state is AccountDetailsFailure) {
          return FaisalPage(
            title: l10n.accountDetails,
            child: FaisalErrorView(
              error: state.error,
              onRetry: () => context.read<AccountDetailsCubit>().load(),
            ),
          );
        }
        final account = (state as AccountDetailsLoaded).account;
        final arabic = locale == 'ar';
        return Scaffold(
          appBar: FaisalAppBar(
            title: account.productName(arabic: arabic),
            subtitle: account.accountNumberMasked,
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FaisalSurface(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                FaisalStatusBadge(
                                  label: account.isActive
                                      ? l10n.cardStatusActive
                                      : account.status,
                                  tone: account.isActive
                                      ? FaisalStatusTone.success
                                      : FaisalStatusTone.warning,
                                ),
                                const Spacer(),
                                Text(
                                  account.currency,
                                  style: context.texts.bodySmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              l10n.availableBalance,
                              style: context.texts.bodySmall?.copyWith(
                                color: context.colors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              FaisalFormatters.money(
                                account.availableBalance,
                                currency: account.currency,
                                locale: locale,
                              ),
                              style: context.texts.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Divider(height: AppSpacing.xl),
                            FaisalInfoRow(
                              label: l10n.currentBalance,
                              value: FaisalFormatters.money(
                                account.currentBalance,
                                currency: account.currency,
                                locale: locale,
                              ),
                            ),
                            FaisalInfoRow(
                              label: l10n.blockedBalance,
                              value: FaisalFormatters.money(
                                account.blockedBalance,
                                currency: account.currency,
                                locale: locale,
                              ),
                            ),
                            FaisalInfoRow(
                              label: l10n.iban,
                              value: account.iban ?? 'â€”',
                            ),
                            FaisalInfoRow(
                              label: l10n.accountNumber,
                              value: account.accountNumberMasked,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (account.linkedCards.isNotEmpty) ...[
                        FaisalSurface(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.linkedCards,
                                style: context.texts.titleSmall,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              ...account.linkedCards.map(
                                (card) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(
                                    Icons.credit_card_outlined,
                                  ),
                                  title: Text(
                                    l10n.cardEndingIn(card.last4),
                                    style: context.texts.bodyMedium,
                                  ),
                                  subtitle: Text(
                                    card.status,
                                    style: context.texts.bodySmall,
                                  ),
                                  trailing: const Icon(
                                    Icons.chevron_right,
                                    size: 18,
                                  ),
                                  onTap: () =>
                                      context.push(AppRoutes.card(card.id)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      FaisalPrimaryButton(
                        label: l10n.transactionsTitle,
                        icon: Icons.receipt_long_outlined,
                        onPressed: () => context.push(
                          AppRoutes.accountTransactionHistory(account.id),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      FaisalSecondaryButton(
                        label: l10n.closeAccount,
                        icon: Icons.lock_outline,
                        destructive: true,
                        onPressed: () =>
                            requestAccountClosure(context, account),
                      ),
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
