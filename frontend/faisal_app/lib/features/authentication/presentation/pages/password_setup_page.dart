import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/faisal_palette.dart';
import '../../../../core/utils/password_policy.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'password_setup_form.dart';
import 'password_setup_header.dart';

class PasswordSetupPage extends StatefulWidget {
  const PasswordSetupPage({super.key});

  @override
  State<PasswordSetupPage> createState() => _PasswordSetupPageState();
}

class _PasswordSetupPageState extends State<PasswordSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _showRequirements = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  PasswordEvaluation get _evaluation =>
      evaluatePassword(_passwordController.text);

  bool get _canContinue =>
      _evaluation.isValid &&
      passwordsMatch(_passwordController.text, _confirmController.text);

  void _submit() {
    if (!_canContinue || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(
      AuthPasswordSetupSubmitted(
        password: _passwordController.text,
        confirmPassword: _confirmController.text,
      ),
    );
  }

  String? _errorText(AppLocalizations l10n, AuthState state) {
    if (state.errorCode == null) {
      return null;
    }
    return switch (state.errorCode!) {
      AppErrorCode.validation => l10n.passwordPolicyError,
      AppErrorCode.unauthorized || AppErrorCode.forbidden => l10n.setupExpired,
      AppErrorCode.network => l10n.errorNetwork,
      AppErrorCode.timeout => l10n.errorTimeout,
      _ => l10n.errorUnexpected,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: context.palette.softSurface,
      body: BlocConsumer<AuthBloc, AuthState>(
        listenWhen: (previous, current) =>
            previous.status != current.status ||
            previous.errorCode != current.errorCode,
        listener: (context, state) {
          if (state.status == AuthStatus.authenticated) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(l10n.passwordUpdated)));
            context.go(AppRoutes.home);
          }
        },
        builder: (context, state) {
          final arabic = Localizations.localeOf(context).languageCode == 'ar';
          final name =
              state.user?.profile?.displayName(arabic: arabic) ??
              state.user?.displayName ??
              '';

          return SafeArea(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSizes.maxAuthWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PasswordSetupHeader(
                        welcomeText: l10n.setupSubtitle(name),
                        cancelTooltip: l10n.cancel,
                        onCancel: () => context.read<AuthBloc>().add(
                          const AuthLogoutRequested(),
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(0, -AppSpacing.lg),
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          decoration: BoxDecoration(
                            color: context.colors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                            border: Border.all(color: context.palette.outline),
                          ),
                          child: PasswordSetupForm(
                            formKey: _formKey,
                            passwordController: _passwordController,
                            confirmController: _confirmController,
                            evaluation: _evaluation,
                            showRequirements: _showRequirements,
                            canContinue: _canContinue,
                            busy: state.busy,
                            onChanged: () => setState(
                              () => _showRequirements =
                                  _passwordController.text.isNotEmpty,
                            ),
                            onSubmit: _submit,
                            errorMessage: _errorText(l10n, state),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
