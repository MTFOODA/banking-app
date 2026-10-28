import 'package:flutter/material.dart';

import '../../features/accounts/domain/entities/account_entities.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_spacing.dart';
import '../theme/faisal_palette.dart';
import '../utils/formatters.dart';
import 'faisal_status_badge.dart';

/// Rounded account tile used on Home and Accounts.
class FaisalAccountCard extends StatelessWidget {
  const FaisalAccountCard({
    super.key,
    required this.account,
    this.onTap,
    this.onTransactions,
    this.showBalance = true,
  });

  final Account account;
  final VoidCallback? onTap;
  final VoidCallback? onTransactions;
  final bool showBalance;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final arabic = locale == 'ar';
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: context.palette.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: context.palette.mintSurface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      account.accountType == 'investment'
                          ? Icons.trending_up
                          : account.accountType == 'savings'
                          ? Icons.savings_outlined
                          : Icons.account_balance_wallet_outlined,
                      size: 20,
                      color: context.colors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.productName(arabic: arabic),
                          style: context.texts.titleSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          account.accountNumberMasked,
                          style: context.texts.bodySmall?.copyWith(
                            color: context.colors.onSurfaceVariant,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FaisalStatusBadge(
                    label: account.isActive
                        ? l10n.cardStatusActive
                        : account.status,
                    tone: account.isActive
                        ? FaisalStatusTone.success
                        : FaisalStatusTone.warning,
                    compact: true,
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
                showBalance
                    ? FaisalFormatters.money(
                        account.availableBalance,
                        currency: account.currency,
                        locale: locale,
                      )
                    : '••••••',
                style: context.texts.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${l10n.currentBalance}: ${showBalance ? FaisalFormatters.money(account.currentBalance, currency: account.currency, locale: locale) : '••••'}',
                      style: context.texts.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (onTransactions != null)
                    TextButton.icon(
                      onPressed: onTransactions,
                      icon: const Icon(Icons.receipt_long_outlined, size: 16),
                      label: Text(l10n.transactionsTitle),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
