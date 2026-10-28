import '../../../branding/presentation/widgets/branding_scope.dart';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/faisal_palette.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/widgets/faisal_logo.dart';

class PasswordSetupHeader extends StatelessWidget {
  const PasswordSetupHeader({
    super.key,
    required this.welcomeText,
    required this.onCancel,
    required this.cancelTooltip,
    this.firstTime = true,
  });

  final String welcomeText;
  final VoidCallback onCancel;
  final String cancelTooltip;
  final bool firstTime;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: context.palette.headerGradient,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.xl),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FaisalLogo(size: 42, onDark: true, showWordmark: true),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: FaisalColors.goldAccent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: FaisalColors.goldAccent.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_user_outlined,
                      size: 14,
                      color: FaisalColors.goldAccent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      firstTime ? l10n.firstLoginBadge : l10n.changePassword,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: FaisalColors.goldAccent,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onCancel,
                tooltip: cancelTooltip,
                icon: Icon(
                  Icons.close,
                  color: BrandingScope.headerText(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            firstTime ? l10n.createSecurePassword : l10n.changePassword,
            style: context.texts.headlineSmall?.copyWith(
              color: BrandingScope.headerText(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            welcomeText,
            style: context.texts.bodyMedium?.copyWith(
              color: BrandingScope.headerText(context).withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
