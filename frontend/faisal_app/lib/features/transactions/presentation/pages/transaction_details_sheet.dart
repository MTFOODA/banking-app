import 'package:flutter/material.dart';

import '../../../../core/localization/labels.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/faisal_palette.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/faisal_rows.dart';
import '../../../../core/widgets/faisal_status_badge.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/transaction_entities.dart';

/// Shows the full detail of a transaction, including its simulated marker.
void showTransactionDetails(BuildContext context, BankTransaction transaction) {
  final l10n = AppLocalizations.of(context);
  final locale = Localizations.localeOf(context).languageCode;
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              transaction.localizedDescription(locale == 'ar'),
              style: context.texts.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${transaction.isCredit ? '+' : 'Ã¢Ë†â€™'}${FaisalFormatters.money(transaction.amount, currency: transaction.currency, locale: locale)}',
              style: context.texts.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: transaction.isCredit ? context.palette.success : null,
              ),
            ),
            const Divider(height: AppSpacing.xl),
            FaisalInfoRow(
              label: l10n.date,
              value: FaisalFormatters.dateTime(
                transaction.occurredAt,
                locale: locale,
              ),
            ),
            FaisalInfoRow(
              label: l10n.transactionType,
              value: transactionTypeLabel(l10n, transaction.type),
            ),
            FaisalInfoRow(
              label: l10n.status,
              value: transactionStatusLabel(l10n, transaction.status),
            ),
            FaisalInfoRow(label: l10n.reference, value: transaction.reference),
            if (transaction.counterparty != null)
              FaisalInfoRow(
                label: l10n.destination,
                value: transaction.counterparty!,
              ),
            if (transaction.accountNumberMasked != null)
              FaisalInfoRow(
                label: l10n.accountNumber,
                value: transaction.accountNumberMasked!,
              ),
            if (transaction.balanceAfter != null)
              FaisalInfoRow(
                label: l10n.availableBalance,
                value: FaisalFormatters.money(
                  transaction.balanceAfter!,
                  currency: transaction.currency,
                  locale: locale,
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FaisalStatusBadge(
                label: l10n.simulated,
                tone: FaisalStatusTone.info,
                compact: true,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
