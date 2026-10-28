import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/di/injector.dart';
import 'core/routing/app_router.dart';
import 'features/authentication/presentation/bloc/auth_bloc.dart';
import 'features/authentication/presentation/bloc/auth_event.dart';
import 'features/branding/presentation/cubit/branding_cubit.dart';

/// Single entry point that prepares localization, DI and the router.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) {
    // Helps diagnose unreachable backends (emulator vs physical device).
    debugPrint('Faisal API base URL: ${AppConfig.apiBaseUrl}');
  }
  await initializeDateFormatting('en');
  await initializeDateFormatting('ar');
  await configureDependencies();

  final authBloc = sl<AuthBloc>();
  final GoRouter router = buildRouter(authBloc: authBloc);
  authBloc.add(const AuthStarted());

  runApp(
    FaisalApp(
      authBloc: authBloc,
      languageCubit: sl(),
      themeCubit: sl(),
      brandingCubit: sl<BrandingCubit>(),
      router: router,
    ),
  );
}
