import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../errors/app_exception.dart';
import '../theme/app_spacing.dart';
import '../theme/faisal_palette.dart';
import 'faisal_buttons.dart';

class FaisalEmptyState extends StatelessWidget {
  const FaisalEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: context.palette.mintSurface,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: context.colors.primary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.texts.titleMedium,
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: context.texts.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FaisalSecondaryButton(
                label: actionLabel!,
                onPressed: onAction,
                expand: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class FaisalErrorView extends StatelessWidget {
  const FaisalErrorView({super.key, required this.error, this.onRetry});

  final AppException error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final message = switch (error.code) {
      AppErrorCode.network => l10n.errorNetwork,
      AppErrorCode.timeout => l10n.errorTimeout,
      AppErrorCode.unauthorized => l10n.errorUnauthorized,
      AppErrorCode.forbidden => l10n.errorForbidden,
      AppErrorCode.notFound => l10n.errorNotFound,
      AppErrorCode.validation => l10n.errorValidation,
      AppErrorCode.rateLimited => l10n.errorRateLimited,
      _ => l10n.errorUnexpected,
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 42,
              color: context.palette.danger,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.texts.bodyMedium,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FaisalSecondaryButton(
                label: l10n.retry,
                icon: Icons.refresh,
                onPressed: onRetry,
                expand: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
