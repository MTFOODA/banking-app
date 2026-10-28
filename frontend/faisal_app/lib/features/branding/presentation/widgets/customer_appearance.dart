import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/branding_theme.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../authentication/presentation/bloc/auth_state.dart';
import '../../../banks/domain/entities/bank_definition.dart';
import '../../../banks/presentation/bank_catalogue_cubit.dart';
import '../../../settings/presentation/cubit/appearance_cubits.dart';
import '../../domain/entities/branding_config.dart';
import 'branding_scope.dart';

/// Scopes bank appearance to authenticated customer routes without replacing
/// the Router/Navigator child when a publication changes.
class CustomerAppearance extends StatelessWidget {
  const CustomerAppearance({
    super.key,
    required this.published,
    required this.router,
    required this.child,
  });
  final BrandingConfig published;
  final GoRouter router;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    Widget usingCatalogue(BankCatalogue catalogue) =>
        BlocBuilder<AuthBloc, AuthState>(
          buildWhen: (a, b) =>
              a.status != b.status ||
              a.user?.profile?.bankCode != b.user?.profile?.bankCode ||
              a.isStaff != b.isStaff,
          builder: (context, auth) => ListenableBuilder(
            listenable: router.routeInformationProvider,
            builder: (context, _) {
              final path = router.routeInformationProvider.value.uri.path;
              final external = {
                AppRoutes.splash,
                AppRoutes.login,
                AppRoutes.registration,
                AppRoutes.passwordSetup,
                AppRoutes.forgotPassword,
                AppRoutes.preLogin,
                AppRoutes.branches,
                AppRoutes.atms,
                AppRoutes.callCenter,
              };
              final bank = catalogue.find(
                auth.user?.profile?.bankCode ?? 'faisal',
              );
              if (auth.status != AuthStatus.authenticated ||
                  auth.isStaff ||
                  external.contains(path) ||
                  path.startsWith('/admin') ||
                  bank == null) {
                return Theme(
                  data: Theme.of(context),
                  child: BrandingScope(
                    config: BrandingConfig.defaults,
                    child: child,
                  ),
                );
              }
              final config = published.forBank(bank);
              final policy = BrandingTheme.mode(
                config,
                context.read<ThemeCubit>().state,
              );
              final brightness = switch (policy) {
                ThemeMode.light => Brightness.light,
                ThemeMode.dark => Brightness.dark,
                _ => MediaQuery.platformBrightnessOf(context),
              };
              return Theme(
                data: BrandingTheme.build(
                  config,
                  brightness,
                  Localizations.localeOf(context).languageCode,
                ),
                child: BrandingScope(config: config, bank: bank, child: child),
              );
            },
          ),
        );
    if (!sl.isRegistered<BankCatalogueCubit>()) {
      return usingCatalogue(BankCatalogue.bundled);
    }
    return BlocBuilder<BankCatalogueCubit, BankCatalogue>(
      bloc: sl<BankCatalogueCubit>(),
      builder: (_, catalogue) => usingCatalogue(catalogue),
    );
  }
}
