import 'package:flutter/material.dart';

import '../../features/requests/domain/entities/request_entities.dart';
import '../../l10n/app_localizations.dart';
import '../localization/labels.dart';
import '../theme/app_spacing.dart';
import '../theme/faisal_palette.dart';
import '../utils/formatters.dart';
import 'faisal_status_badge.dart';

class FaisalRequestCard extends StatelessWidget {
  const FaisalRequestCard({
    super.key,
    required this.request,
    this.onTap,
    this.customerName,
  });

  final ServiceRequestEntity request;
  final VoidCallback? onTap;
  final String? customerName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
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
            border: Border.all(
              color: request.needsCustomerAction
                  ? context.palette.gold
                  : context.palette.outline,
              width: request.needsCustomerAction ? 1.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          requestTypeLabel(l10n, request.requestType),
                          style: context.texts.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          request.reference,
                          style: context.texts.bodySmall?.copyWith(
                            color: context.colors.onSurfaceVariant,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FaisalStatusBadge(
                    label: requestStatusLabel(l10n, request.status),
                    tone: FaisalStatusBadge.toneForStatus(request.status),
                    compact: true,
                  ),
                ],
              ),
              if (customerName != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(customerName!, style: context.texts.bodySmall),
              ],
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: context.colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    FaisalFormatters.dateTime(
                      request.submittedAt ?? request.createdAt,
                      locale: locale,
                    ),
                    style: context.texts.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  if (request.assignedLabel != null) ...[
                    const Spacer(),
                    Flexible(
                      child: Text(
                        '${l10n.assignedTo}: ${request.assignedLabel}',
                        overflow: TextOverflow.ellipsis,
                        style: context.texts.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (request.needsCustomerAction) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: context.palette.gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 16,
                        color: context.palette.warning,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          l10n.awaitingYourInformation,
                          style: context.texts.bodySmall?.copyWith(
                            color: context.palette.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
