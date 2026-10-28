import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/faisal_palette.dart';
import '../../../../core/widgets/faisal_buttons.dart';
import '../../../../core/widgets/faisal_logo.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// Startup screen used while a saved session is validated.
///
/// The router keeps this route mounted for [AuthStatus.unknown] and
/// [AuthStatus.sessionRestoreFailed]. A transient failure (backend down,
/// timeout, unexpected payload) therefore becomes a recoverable error with a
/// retry action instead of an endless spinner.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  String _errorMessage(AppLocalizations l10n, AppErrorCode? code) =>
      switch (code) {
        AppErrorCode.network => l10n.errorNetwork,
        AppErrorCode.timeout => l10n.errorTimeout,
        _ => l10n.errorUnexpected,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<AuthBloc>().state;
    final failed = state.status == AuthStatus.sessionRestoreFailed;

    return Scaffold(
      backgroundColor: context.colors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.xl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.maxAuthWidth,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: FaisalLogo(size: 64, showWordmark: true)),
                  const SizedBox(height: AppSpacing.xl),
                  if (failed)
                    ..._failure(context, l10n, state)
                  else
                    ..._loading(context, l10n),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _loading(BuildContext context, AppLocalizations l10n) => [
    const Center(
      child: SizedBox(
        width: 26,
        height: 26,
        child: CircularProgressIndicator(strokeWidth: 2.4),
      ),
    ),
    const SizedBox(height: AppSpacing.md),
    Text(
      l10n.loading,
      textAlign: TextAlign.center,
      style: context.texts.bodySmall,
    ),
  ];

  List<Widget> _failure(
    BuildContext context,
    AppLocalizations l10n,
    AuthState state,
  ) => [
    Text(
      l10n.startupRestoreFailed,
      textAlign: TextAlign.center,
      style: context.texts.titleSmall,
    ),
    const SizedBox(height: AppSpacing.sm),
    Text(
      _errorMessage(l10n, state.errorCode),
      textAlign: TextAlign.center,
      style: context.texts.bodySmall?.copyWith(color: context.palette.danger),
    ),
    const SizedBox(height: AppSpacing.lg),
    FaisalPrimaryButton(
      label: l10n.retry,
      loading: state.busy,
      onPressed: () => context.read<AuthBloc>().add(const AuthStarted()),
    ),
  ];
}
