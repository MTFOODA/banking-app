import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/faisal_palette.dart';
import '../../../../core/widgets/faisal_buttons.dart';
import '../../../../core/widgets/faisal_page.dart';
import '../../../../core/widgets/faisal_text_field.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../authentication/domain/repositories/auth_repository.dart';

/// Customers request a one-time reset code from the bank; the code is issued by
/// staff (see `python -m app.cli issue-reset-token`) and never generated in-app.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  bool _busy = false;
  String? _message;
  AppException? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _message = null;
    });
    try {
      final message = await context.read<AuthRepository>().requestPasswordReset(
        _controller.text.replaceAll(' ', ''),
      );
      if (!mounted) {
        return;
      }
      setState(() => _message = message);
    } on AppException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FaisalPage(
      title: l10n.forgotPassword,
      maxWidth: AppSizes.maxFormWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.loginSubtitle, style: context.texts.bodyMedium),
          const SizedBox(height: AppSpacing.xl),
          Form(
            key: _formKey,
            child: FaisalTextField(
              controller: _controller,
              label: l10n.cardNumber,
              hint: l10n.cardNumberHint,
              prefixIcon: Icons.credit_card_outlined,
              keyboardType: TextInputType.number,
              validator: (value) => value == null || value.trim().isEmpty
                  ? l10n.fieldRequired
                  : null,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FaisalPrimaryButton(
            label: l10n.submit,
            loading: _busy,
            onPressed: _busy ? null : _submit,
          ),
          if (_message != null) ...[
            const SizedBox(height: AppSpacing.lg),
            FaisalSurface(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.mark_email_read_outlined,
                    color: context.palette.success,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(_message!, style: context.texts.bodySmall),
                  ),
                ],
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.lg),
            FaisalSurface(
              borderColor: context.palette.danger,
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: context.palette.danger),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      _error!.code == AppErrorCode.network
                          ? l10n.errorNetwork
                          : l10n.errorUnexpected,
                      style: context.texts.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          TextButton(
            onPressed: () => context.go(AppRoutes.login),
            child: Text(l10n.back),
          ),
        ],
      ),
    );
  }
}
