import 'package:flutter/material.dart';

import '../../features/transactions/domain/entities/transaction_entities.dart';
import '../../l10n/app_localizations.dart';
import '../localization/labels.dart';
import '../theme/app_spacing.dart';
import '../theme/faisal_palette.dart';
import '../utils/formatters.dart';

/// Compact transaction row used across Home, Accounts and Cards.
class FaisalTransactionTile extends StatelessWidget {
  const FaisalTransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
    this.showAccount = false,
  });

  final BankTransaction transaction;
  final VoidCallback? onTap;
  final bool showAccount;

  IconData get _icon => switch (transaction.type) {
    'transfer' => Icons.swap_horiz,
    'salary' => Icons.work_outline,
    'purchase' => Icons.shopping_bag_outlined,
    'bill_payment' => Icons.receipt_outlined,
    'withdrawal' => Icons.atm_outlined,
    'card_repayment' => Icons.credit_score_outlined,
    'fee' => Icons.percent,
    _ => transaction.isCredit ? Icons.south_west : Icons.north_east,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final arabic = locale == 'ar';
    final credit = transaction.isCredit;
    final amountColor = credit
        ? context.palette.success
        : context.colors.onSurface;
    final subtitle = [
      FaisalFormatters.relativeDay(transaction.occurredAt, locale: locale),
      transactionTypeLabel(l10n, transaction.type),
      if (showAccount && transaction.accountNumberMasked != null)
        transaction.accountNumberMasked!,
    ].join(' • ');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: credit
                      ? context.palette.success.withValues(alpha: 0.12)
                      : context.palette.mintSurface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  _icon,
                  size: 20,
                  color: credit
                      ? context.palette.success
                      : context.colors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.localizedDescription(arabic),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      transaction.merchant ??
                          transaction.counterparty ??
                          subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.bodySmall?.copyWith(
                        fontSize: 10.5,
                        color: context.colors.onSurfaceVariant.withValues(
                          alpha: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${credit ? '+' : '−'}${FaisalFormatters.money(transaction.amount, currency: transaction.currency, locale: locale)}',
                    style: context.texts.titleSmall?.copyWith(
                      color: amountColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  if (transaction.status != 'posted') ...[
                    const SizedBox(height: 4),
                    Text(
                      transactionStatusLabel(l10n, transaction.status),
                      style: context.texts.bodySmall?.copyWith(
                        fontSize: 10,
                        color: transaction.status == 'failed'
                            ? context.palette.danger
                            : context.palette.warning,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
