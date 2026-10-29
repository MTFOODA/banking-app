import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../features/authentication/presentation/bloc/auth_state.dart';
import 'app_routes.dart';

/// Adapts a BLoC state stream into a [Listenable] for GoRouter refresh.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(
    Stream<dynamic> stream, [
    Stream<dynamic>? selection,
    Stream<dynamic>? savedBanks,
  ]) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
    _selection = selection?.listen((_) => notifyListeners());
    _savedBanks = savedBanks?.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;
  StreamSubscription<dynamic>? _selection;
  StreamSubscription<dynamic>? _savedBanks;

  @override
  void dispose() {
    _subscription.cancel();
    _selection?.cancel();
    _savedBanks?.cancel();
    super.dispose();
  }
}

/// Pure redirect function (easy to unit test without a router).
String? resolveRedirect({
  required AuthState auth,
  required String location,
  bool hasSelectedBank = true,
  bool hasSavedBanks = false,
}) {
  // Screens that are reachable without an authenticated session. The splash
  // route is deliberately **not** part of this list: it is only a transient
  // startup screen, so a signed-out state must leave it immediately.
  final isCredentialScreen =
      location == AppRoutes.onboarding ||
      location == AppRoutes.savedBanks ||
      location == AppRoutes.login ||
      location == AppRoutes.preLogin ||
      location == AppRoutes.branches ||
      location == AppRoutes.atms ||
      location == AppRoutes.callCenter ||
      location == AppRoutes.forgotPassword ||
      location == AppRoutes.registration;

  switch (auth.status) {
    case AuthStatus.unknown:
      return location == AppRoutes.splash ? null : AppRoutes.splash;
    case AuthStatus.sessionRestoreFailed:
      // Keep the startup screen mounted so it can show the recoverable error
      // and the retry action instead of bouncing to the login screen.
      return location == AppRoutes.splash ? null : AppRoutes.splash;
    case AuthStatus.unauthenticated:
      if (hasSavedBanks &&
          (location == AppRoutes.splash || !isCredentialScreen)) {
        return AppRoutes.savedBanks;
      }
      if (!hasSelectedBank) {
        if (hasSavedBanks && location == AppRoutes.savedBanks) return null;
        return location == AppRoutes.onboarding ? null : AppRoutes.onboarding;
      }
      return isCredentialScreen ? null : AppRoutes.login;
    case AuthStatus.firstLoginRequired:
      return location == AppRoutes.passwordSetup
          ? null
          : AppRoutes.passwordSetup;
    case AuthStatus.authenticated:
      final landing = auth.isStaff && auth.can('admin.dashboard.view')
          ? AppRoutes.admin
          : AppRoutes.home;
      if (location == AppRoutes.onboarding ||
          location == AppRoutes.savedBanks ||
          location == AppRoutes.login ||
          location == AppRoutes.preLogin ||
          location == AppRoutes.splash ||
          location == AppRoutes.passwordSetup ||
          location == AppRoutes.forgotPassword ||
          location == AppRoutes.registration) {
        return landing;
      }
      if (location == AppRoutes.home && landing == AppRoutes.admin) {
        return landing;
      }
      if (location.startsWith('/admin') && !auth.can('admin.dashboard.view')) {
        return AppRoutes.home;
      }
      return null;
  }
}
