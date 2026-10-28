import 'package:flutter/material.dart';

import '../../../../core/utils/password_policy.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/faisal_palette.dart';

class PasswordRequirementRow extends StatelessWidget {
  const PasswordRequirementRow({
    super.key,
    required this.label,
    required this.satisfied,
  });

  final String label;
  final bool satisfied;

  @override
  Widget build(BuildContext context) {
    final color = satisfied
        ? context.palette.success
        : context.colors.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            satisfied ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: color,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: context.texts.bodySmall?.copyWith(
                color: color,
                fontWeight: satisfied ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PasswordRequirementsList extends StatelessWidget {
  const PasswordRequirementsList({
    super.key,
    required this.evaluation,
    required this.showAll,
  });

  final PasswordEvaluation evaluation;
  final bool showAll;

  bool _ok(PasswordRequirement requirement) =>
      evaluation.satisfied.contains(requirement);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rows = <Widget>[
      PasswordRequirementRow(
        label: l10n.reqMinLength,
        satisfied: _ok(PasswordRequirement.minLength),
      ),
      PasswordRequirementRow(
        label: l10n.reqUppercase,
        satisfied: _ok(PasswordRequirement.uppercase),
      ),
      PasswordRequirementRow(
        label: l10n.reqLowercase,
        satisfied: _ok(PasswordRequirement.lowercase),
      ),
      PasswordRequirementRow(
        label: l10n.reqDigit,
        satisfied: _ok(PasswordRequirement.digit),
      ),
      PasswordRequirementRow(
        label: l10n.reqSpecial,
        satisfied: _ok(PasswordRequirement.special),
      ),
      PasswordRequirementRow(
        label: l10n.reqNoRepeat,
        satisfied: _ok(PasswordRequirement.noTripleRepeat),
      ),
    ];
    if (!showAll) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.palette.mintSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.passwordStrength,
            style: context.texts.titleSmall?.copyWith(fontSize: 12),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...rows,
        ],
      ),
    );
  }
}

class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.evaluation});

  final PasswordEvaluation evaluation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (label, color) = switch (evaluation.strength) {
      0 || 1 => (l10n.strengthWeak, context.palette.danger),
      2 => (l10n.strengthFair, context.palette.warning),
      3 => (l10n.strengthGood, const Color(0xFF4B9F72)),
      _ => (l10n.strengthStrong, FaisalColors.success),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Row(
                children: List.generate(4, (index) {
                  final active = index < evaluation.strength;
                  return Expanded(
                    child: Container(
                      height: 5,
                      margin: EdgeInsetsDirectional.only(
                        end: index == 3 ? 0 : AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: active ? color : context.palette.outline,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: context.texts.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
