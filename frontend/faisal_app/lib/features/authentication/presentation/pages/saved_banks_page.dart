import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/security/biometric_service.dart';
import '../../../../core/theme/branding_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../banks/domain/entities/bank_definition.dart';
import '../../../banks/presentation/bank_logo.dart';
import '../../../banks/presentation/bank_selection_cubit.dart';
import '../../../branding/domain/entities/branding_config.dart';
import '../../../branding/presentation/cubit/branding_cubit.dart';
import '../../../branding/presentation/widgets/branding_scope.dart';
import '../../../settings/presentation/cubit/appearance_cubits.dart';
import '../../domain/entities/saved_bank.dart';
import '../../domain/repositories/saved_banks_repository.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../cubit/saved_banks_cubit.dart';
import 'login_widgets.dart';

class SavedBanksPage extends StatelessWidget {
  const SavedBanksPage({super.key});

  Future<void> _open(
    BuildContext context,
    SavedBank entry, {
    bool password = false,
  }) async {
    if (context.read<AuthBloc>().state.busy) return;
    final repository = sl<SavedBanksRepository>();
    repository.pendingLogin = entry;
    final reason = AppLocalizations.of(context).biometricReason;
    final auth = context.read<AuthBloc>();
    await sl<BankSelectionCubit>().select(entry.bankCode);
    if (!context.mounted) return;
    auth.add(const AuthErrorCleared());
    if (!password && sl<BiometricService>().enabledFor(entry.userId)) {
      auth.add(AuthSavedBankRequested(entry, reason));
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.isAuthenticated) context.go(AppRoutes.home);
        if (state.sessionExpired &&
            sl<SavedBanksRepository>().pendingLogin != null) {
          context.go(AppRoutes.login);
        }
      },
      builder: (context, auth) => Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(l.savedBanksTitle),
          actions: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 12),
              child: FaisalLanguageToggle(
                languageCode: language,
                onChanged: auth.busy
                    ? (_) async {}
                    : context.read<LanguageCubit>().change,
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: BlocBuilder<SavedBanksCubit, List<SavedBank>>(
                bloc: sl<SavedBanksCubit>(),
                builder: (context, entries) => ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text(
                      l.savedBanksSubtitle,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 20),
                    if (auth.busy)
                      const LinearProgressIndicator(
                        key: Key('saved-bank-loading'),
                      ),
                    if (auth.errorCode != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          switch (auth.errorCode!) {
                            AppErrorCode.network => l.errorNetwork,
                            AppErrorCode.timeout => l.errorTimeout,
                            AppErrorCode.rateLimited => l.errorRateLimited,
                            AppErrorCode.forbidden =>
                              l.savedBanksBiometricRetry,
                            _ => l.loginFailed,
                          },
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    for (final entry in entries)
                      if (BankCatalogue.bundled.find(entry.bankCode)
                          case final bank?)
                        _bankCard(context, entry, bank, auth.busy),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      key: const Key('saved-banks-add'),
                      onPressed: auth.busy
                          ? null
                          : () {
                              sl<SavedBanksRepository>().pendingLogin = null;
                              context.read<AuthBloc>().add(
                                const AuthErrorCleared(),
                              );
                              context.go(AppRoutes.onboarding);
                            },
                      icon: const Icon(Icons.add),
                      label: Text(l.savedBanksAdd),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l.savedBanksPrivacy,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bankCard(
    BuildContext context,
    SavedBank entry,
    BankDefinition bank,
    bool busy,
  ) {
    final published = sl.isRegistered<BrandingCubit>()
        ? sl<BrandingCubit>().state.config
        : BrandingConfig.defaults;
    final config = published.forBank(bank);
    final biometric = sl<BiometricService>().enabledFor(entry.userId);
    return Theme(
      data: BrandingTheme.build(
        config,
        Theme.of(context).brightness,
        Localizations.localeOf(context).languageCode,
      ),
      child: BrandingScope(
        config: config,
        bank: bank,
        child: Builder(
          builder: (context) {
            final l = AppLocalizations.of(context),
                colors = Theme.of(context).colorScheme;
            return Card(
              key: ValueKey('saved-bank-${entry.userId}'),
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: colors.primary.withValues(alpha: .4)),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: busy ? null : () => _open(context, entry),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          BankLogo(bank: bank, size: 64),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bank.name(
                                    Localizations.localeOf(context)
                                        .languageCode,
                                  ),
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: colors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  entry.username,
                                  textDirection: TextDirection.ltr,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        key: ValueKey('saved-bank-sign-in-${entry.userId}'),
                        onPressed: busy ? null : () => _open(context, entry),
                        icon: Icon(biometric ? Icons.fingerprint : Icons.login),
                        label: Text(biometric ? l.biometricUnlock : l.signIn),
                      ),
                      if (biometric)
                        TextButton(
                          key: ValueKey('saved-bank-password-${entry.userId}'),
                          onPressed: busy
                              ? null
                              : () => _open(context, entry, password: true),
                          child: Text(l.savedBanksUsePassword),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
