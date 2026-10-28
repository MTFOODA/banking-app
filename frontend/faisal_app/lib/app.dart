import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/branding_theme.dart';
import 'features/branding/presentation/cubit/branding_cubit.dart';
import 'features/branding/presentation/widgets/branding_runtime.dart';
import 'core/di/injector.dart';
import 'core/security/biometric_gate.dart';
import 'core/security/biometric_service.dart';
import 'core/security/session_store.dart';
import 'features/authentication/presentation/bloc/auth_bloc.dart';
import 'features/authentication/presentation/bloc/auth_state.dart';
import 'features/settings/presentation/cubit/appearance_cubits.dart';
import 'l10n/app_localizations.dart';

class FaisalApp extends StatelessWidget {
  const FaisalApp({
    super.key,
    required this.authBloc,
    required this.languageCubit,
    required this.themeCubit,
    required this.router,
    this.brandingCubit,
  });

  final AuthBloc authBloc;
  final LanguageCubit languageCubit;
  final ThemeCubit themeCubit;
  final GoRouter router;
  final BrandingCubit? brandingCubit;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: authBloc),
        BlocProvider<LanguageCubit>.value(value: languageCubit),
        BlocProvider<ThemeCubit>.value(value: themeCubit),
      ],
      child: BlocBuilder<LanguageCubit, Locale>(
        builder: (context, locale) {
          return BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, themeMode) {
              return BrandingRuntime(
                cubit: brandingCubit,
                builder: (context, branding) => MaterialApp.router(
                  debugShowCheckedModeBanner: false,
                  onGenerateTitle: (context) =>
                      branding.text('application_name') ??
                      AppLocalizations.of(context).appName,
                  locale: locale,
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  theme: BrandingTheme.build(
                    branding,
                    Brightness.light,
                    locale.languageCode,
                  ),
                  darkTheme: BrandingTheme.build(
                    branding,
                    Brightness.dark,
                    locale.languageCode,
                  ),
                  themeMode: BrandingTheme.mode(branding, themeMode),
                  routerConfig: router,
                  builder: (context, child) {
                    return BlocListener<AuthBloc, AuthState>(
                      listenWhen: (previous, current) =>
                          !previous.sessionExpired && current.sessionExpired,
                      listener: (context, state) {
                        final l10n = AppLocalizations.of(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.errorUnauthorized)),
                        );
                      },
                      child: sl.isRegistered<BiometricService>()
                          ? BiometricGate(
                              service: sl<BiometricService>(),
                              store: sl<SessionStore>(),
                              child: child ?? const SizedBox.shrink(),
                            )
                          : child ?? const SizedBox.shrink(),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
