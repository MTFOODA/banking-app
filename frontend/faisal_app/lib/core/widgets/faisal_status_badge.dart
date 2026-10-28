import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_spacing.dart';
import '../theme/faisal_palette.dart';

enum FaisalStatusTone { success, warning, danger, neutral, info }

class FaisalStatusBadge extends StatelessWidget {
  const FaisalStatusBadge({
    super.key,
    required this.label,
    this.tone = FaisalStatusTone.neutral,
    this.compact = false,
  });

  final String label;
  final FaisalStatusTone tone;
  final bool compact;

  static FaisalStatusTone toneForStatus(String status) => switch (status) {
    'approved' ||
    'completed' ||
    'posted' ||
    'active' ||
    'simulated_completed' => FaisalStatusTone.success,
    'rejected' ||
    'failed' ||
    'blocked' ||
    'stolen' ||
    'lost' ||
    'cancelled' => FaisalStatusTone.danger,
    'pending_customer_info' ||
    'pending' ||
    'pending_approval' ||
    'under_review' ||
    'frozen' => FaisalStatusTone.warning,
    'processing' || 'submitted' => FaisalStatusTone.info,
    _ => FaisalStatusTone.neutral,
  };

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final (Color background, Color foreground) = switch (tone) {
      FaisalStatusTone.success => (
        palette.success.withValues(alpha: 0.12),
        palette.success,
      ),
      FaisalStatusTone.warning => (
        palette.warning.withValues(alpha: 0.16),
        palette.warning,
      ),
      FaisalStatusTone.danger => (
        palette.danger.withValues(alpha: 0.12),
        palette.danger,
      ),
      FaisalStatusTone.info => (
        context.colors.primary.withValues(alpha: 0.12),
        context.colors.primary,
      ),
      FaisalStatusTone.neutral => (
        palette.mintSurface,
        context.colors.onSurface,
      ),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.md,
        vertical: compact ? 3 : 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: context.texts.bodySmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
          fontSize: compact ? 10.5 : 11.5,
        ),
      ),
    );
  }
}

/// Banner reminding customers that the build is a demo.
class DemoDataBanner extends StatelessWidget {
  const DemoDataBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.palette.mintSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.palette.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: context.colors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(l10n.demoDataNotice, style: context.texts.bodySmall),
          ),
        ],
      ),
    );
  }
}
