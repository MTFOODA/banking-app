import '../../../branding/presentation/widgets/branding_scope.dart';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/faisal_palette.dart';

class FaisalLanguageToggle extends StatelessWidget {
  const FaisalLanguageToggle({
    super.key,
    required this.languageCode,
    required this.onChanged,
  });

  final String languageCode;
  final Future<void> Function(String code) onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Language: ${languageCode == 'ar' ? 'Arabic' : 'English'}',
      child: Container(
        decoration: BoxDecoration(
          color: BrandingScope.headerText(context).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: BrandingScope.headerText(context).withValues(alpha: 0.18),
          ),
        ),
        padding: const EdgeInsets.all(3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _pill(context, 'EN', languageCode == 'en', () => onChanged('en')),
            _pill(context, 'ع', languageCode == 'ar', () => onChanged('ar')),
          ],
        ),
      ),
    );
  }

  Widget _pill(
    BuildContext context,
    String label,
    bool active,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? (BrandingScope.of(context).customTheme
                    ? context.palette.gold
                    : FaisalColors.goldAccent)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: active
                ? (BrandingScope.of(context).customTheme
                      ? context.colors.onTertiary
                      : FaisalColors.deepForestGreen)
                : BrandingScope.headerText(context),
          ),
        ),
      ),
    );
  }
}

class FaisalErrorBanner extends StatelessWidget {
  const FaisalErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.palette.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 18, color: context.palette.danger),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: context.texts.bodySmall?.copyWith(
                color: context.palette.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FaisalSecurityNotice extends StatelessWidget {
  const FaisalSecurityNotice({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.shield_outlined,
          size: 16,
          color: context.colors.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: context.texts.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}
