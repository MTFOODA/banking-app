import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/faisal_palette.dart';

/// Dismissible inline banner used for demo notices and service messages.
class FaisalNotificationBanner extends StatelessWidget {
  const FaisalNotificationBanner({
    super.key,
    required this.message,
    this.title,
    this.icon = Icons.campaign_outlined,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
    this.tone = FaisalBannerTone.info,
  });

  final String message;
  final String? title;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;
  final FaisalBannerTone tone;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final (background, accent) = switch (tone) {
      FaisalBannerTone.info => (palette.mintSurface, context.colors.primary),
      FaisalBannerTone.warning => (
        palette.warning.withValues(alpha: 0.12),
        palette.warning,
      ),
      FaisalBannerTone.danger => (
        palette.danger.withValues(alpha: 0.1),
        palette.danger,
      ),
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: accent),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: context.texts.titleSmall?.copyWith(color: accent),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(message, style: context.texts.bodySmall),
                if (actionLabel != null && onAction != null)
                  TextButton(
                    onPressed: onAction,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(actionLabel!),
                  ),
              ],
            ),
          ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close, size: 18),
              visualDensity: VisualDensity.compact,
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            ),
        ],
      ),
    );
  }
}

enum FaisalBannerTone { info, warning, danger }
