import '../../../../core/config/banking_identity.dart';
import '../../../../core/di/injector.dart';
import '../../../banks/presentation/bank_selection_cubit.dart';
import '../../domain/repositories/saved_banks_repository.dart';
import '../../../products/presentation/widgets/public_service_cards.dart';
import '../../../products/presentation/widgets/public_announcements_panel.dart';
import '../../../branding/presentation/widgets/branding_scope.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/faisal_palette.dart';
import '../../../../core/widgets/faisal_logo.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../settings/presentation/cubit/appearance_cubits.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'login_form_card.dart';
import 'login_widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberDevice = false;
  String? get _bankCode => sl.isRegistered<BankSelectionCubit>()
      ? sl<BankSelectionCubit>().state
      : null;

  @override
  void initState() {
    super.initState();
    if (sl.isRegistered<SavedBanksRepository>()) {
      final pending = sl<SavedBanksRepository>().pendingLogin;
      if (pending?.bankCode == _bankCode) {
        _identifierController.text = pending!.username;
      }
    }
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _errorMessage(AppLocalizations l10n, AppErrorCode code) =>
      switch (code) {
        AppErrorCode.network => l10n.errorNetwork,
        AppErrorCode.timeout => l10n.errorTimeout,
        AppErrorCode.rateLimited => l10n.errorRateLimited,
        _ => l10n.loginFailed,
      };

  void _submit() {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(
      AuthLoginRequested(
        identifier: _identifierController.text,
        password: _passwordController.text,
        rememberDevice: _rememberDevice,
        bankCode: _bankCode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCubit = context.read<LanguageCubit>();
    final languageCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listenWhen: (previous, current) =>
            previous.status != current.status ||
            previous.errorCode != current.errorCode,
        listener: (context, state) {
          if (state.status == AuthStatus.authenticated) {
            context.go(state.isStaff ? AppRoutes.admin : AppRoutes.home);
          }
        },
        builder: (context, state) {
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: context.palette.headerGradient,
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xl,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppSizes.maxAuthWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: FaisalLogo(
                                size: 52,
                                onDark: true,
                                showWordmark: true,
                              ),
                            ),
                            FaisalLanguageToggle(
                              languageCode: languageCode,
                              onChanged: languageCubit.change,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        Text(
                          l10n.welcomeBack,
                          style: context.texts.headlineMedium?.copyWith(
                            color: BrandingScope.headerText(context),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          l10n.loginSubtitle,
                          style: context.texts.bodyMedium?.copyWith(
                            color: BrandingScope.headerText(context)
                                .withValues(alpha: 0.78),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        LoginFormCard(
                          formKey: _formKey,
                          identifierController: _identifierController,
                          passwordController: _passwordController,
                          rememberDevice: _rememberDevice,
                          onRememberChanged: (value) =>
                              setState(() => _rememberDevice = value),
                          onSubmit: _submit,
                          busy: state.busy,
                          errorMessage: state.errorCode == null
                              ? null
                              : _errorMessage(l10n, state.errorCode!),
                          onForgotPassword: () =>
                              context.push(AppRoutes.forgotPassword),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        TextButton(
                          onPressed: state.busy
                              ? null
                              : () {
                                  if (sl.isRegistered<SavedBanksRepository>()) {
                                    sl<SavedBanksRepository>().pendingLogin =
                                        null;
                                  }
                                  context.go(AppRoutes.onboarding);
                                },
                          child: Text(
                            l10n.bankChangeSelection,
                            style: TextStyle(
                              color: BrandingScope.headerText(context),
                            ),
                          ),
                        ),
                        if (sl.isRegistered<SavedBanksRepository>() &&
                            sl<SavedBanksRepository>().entries.isNotEmpty)
                          TextButton(
                            onPressed: state.busy
                                ? null
                                : () => context.go(AppRoutes.savedBanks),
                            child: Text(
                              l10n.savedBanksTitle,
                              style: TextStyle(
                                color: BrandingScope.headerText(context),
                              ),
                            ),
                          ),
                        OutlinedButton(
                          onPressed: state.busy
                              ? null
                              : () => context.push(AppRoutes.registration),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: BrandingScope.headerText(context),
                          ),
                          child: Text(l10n.registerTitle),
                        ),
                        const SizedBox(height: 24),
                        const PublicServiceCards(includeLogin: false),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: context.colors.surface,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const PublicAnnouncementsPanel(),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          BankingIdentity.displayName(context),
                          textAlign: TextAlign.center,
                          style: context.texts.bodySmall?.copyWith(
                            color: BrandingScope.headerText(context)
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
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
