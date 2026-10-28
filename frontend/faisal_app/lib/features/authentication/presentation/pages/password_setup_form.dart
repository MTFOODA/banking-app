import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/faisal_palette.dart';
import '../../../../core/utils/password_policy.dart';
import '../../../../core/widgets/faisal_buttons.dart';
import '../../../../core/widgets/faisal_text_field.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/password_widgets.dart';

class PasswordSetupForm extends StatelessWidget {
  const PasswordSetupForm({
    super.key,
    required this.formKey,
    required this.passwordController,
    required this.confirmController,
    required this.evaluation,
    required this.showRequirements,
    required this.canContinue,
    required this.busy,
    required this.onChanged,
    required this.onSubmit,
    this.errorMessage,
    this.buttonLabel,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final PasswordEvaluation evaluation;
  final bool showRequirements;
  final bool canContinue;
  final bool busy;
  final VoidCallback onChanged;
  final VoidCallback onSubmit;
  final String? errorMessage;
  final String? buttonLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FaisalTextField(
            controller: passwordController,
            label: l10n.newPassword,
            prefixIcon: Icons.lock_outline,
            obscureText: true,
            textInputAction: TextInputAction.next,
            onChanged: (_) => onChanged(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.fieldRequired;
              }
              if (!evaluatePassword(value).isValid) {
                return l10n.passwordPolicyError;
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          PasswordStrengthMeter(evaluation: evaluation),
          const SizedBox(height: AppSpacing.md),
          FaisalTextField(
            controller: confirmController,
            label: l10n.confirmPassword,
            prefixIcon: Icons.lock_reset_outlined,
            obscureText: true,
            textInputAction: TextInputAction.done,
            onChanged: (_) => onChanged(),
            onSubmitted: (_) => onSubmit(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.fieldRequired;
              }
              if (value != passwordController.text) {
                return l10n.passwordMismatch;
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          if (confirmController.text.isNotEmpty)
            Text(
              passwordsMatch(passwordController.text, confirmController.text)
                  ? l10n.passwordsMatchLabel
                  : l10n.passwordMismatch,
              style: TextStyle(
                color:
                    passwordsMatch(
                      passwordController.text,
                      confirmController.text,
                    )
                    ? context.palette.success
                    : context.palette.danger,
              ),
            ),
          PasswordRequirementsList(
            evaluation: evaluation,
            showAll: showRequirements,
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: context.palette.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 18,
                    color: context.palette.danger,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      errorMessage!,
                      style: context.texts.bodySmall?.copyWith(
                        color: context.palette.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          FaisalPrimaryButton(
            label: buttonLabel ?? l10n.continueToHome,
            loading: busy,
            onPressed: canContinue && !busy ? onSubmit : null,
          ),
        ],
      ),
    );
  }
}
