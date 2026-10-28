import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/faisal_palette.dart';
import '../../../../core/utils/password_policy.dart';
import '../../../../core/widgets/faisal_buttons.dart';
import '../../../../core/widgets/faisal_text_field.dart';
import '../../../../l10n/app_localizations.dart';
import 'login_widgets.dart';
import '../../../banks/presentation/bank_selector.dart';

class LoginFormCard extends StatelessWidget {
  const LoginFormCard({
    super.key,
    required this.formKey,
    required this.identifierController,
    required this.passwordController,
    required this.rememberDevice,
    required this.onRememberChanged,
    required this.onSubmit,
    required this.busy,
    required this.onForgotPassword,
    this.errorMessage,
    this.bankCode,
    this.onBankChanged,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController identifierController;
  final TextEditingController passwordController;
  final bool rememberDevice;
  final ValueChanged<bool> onRememberChanged;
  final VoidCallback onSubmit;
  final bool busy;
  final VoidCallback onForgotPassword;
  final String? errorMessage;
  final String? bankCode;
  final ValueChanged<String?>? onBankChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (onBankChanged != null) ...[
              BankSelector(
                value: bankCode,
                onChanged: onBankChanged!,
                enabled: !busy,
                requiredSelection: false,
                label: l10n.bankLoginSelectionLabel,
              ),
              const SizedBox(height: 8),
              Text(l10n.bankLoginSelectionHelp, style: context.texts.bodySmall),
              const SizedBox(height: AppSpacing.lg),
            ],
            FaisalTextField(
              controller: identifierController,
              label: l10n.loginIdentifier,
              hint: l10n.loginIdentifierHint,
              prefixIcon: Icons.credit_card_outlined,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              maxLength: 32,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_.\- ]')),
                LengthLimitingTextInputFormatter(32),
              ],
              validator: (value) {
                final result = validateLoginIdentifier(value);
                if (result == 'required') {
                  return l10n.fieldRequired;
                }
                if (result != null) {
                  return l10n.invalidLoginIdentifier;
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            FaisalTextField(
              controller: passwordController,
              label: l10n.password,
              hint: l10n.passwordHint,
              prefixIcon: Icons.lock_outline,
              obscureText: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onSubmit(),
              validator: (value) => validatePasswordField(value) == null
                  ? null
                  : l10n.passwordRequired,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Checkbox(
                  value: rememberDevice,
                  onChanged: (value) => onRememberChanged(value ?? false),
                  visualDensity: VisualDensity.compact,
                ),
                Expanded(
                  child: Text(
                    l10n.rememberDevice,
                    style: context.texts.bodySmall,
                  ),
                ),
                TextButton(
                  onPressed: onForgotPassword,
                  child: Text(l10n.forgotPassword),
                ),
              ],
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: AppSpacing.sm),
              FaisalErrorBanner(message: errorMessage!),
            ],
            const SizedBox(height: AppSpacing.lg),
            FaisalPrimaryButton(
              label: busy ? l10n.signingIn : l10n.signIn,
              loading: busy,
              onPressed: busy ? null : onSubmit,
            ),
            const SizedBox(height: AppSpacing.lg),
            FaisalSecurityNotice(text: l10n.securityNotice),
          ],
        ),
      ),
    );
  }
}
