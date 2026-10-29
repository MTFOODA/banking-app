import '../di/injector.dart';
import '../../features/banks/presentation/bank_selection_cubit.dart';
import '../../features/banks/presentation/bank_onboarding_page.dart';
import '../config/banking_identity.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/support/presentation/pages/bank_services_gate.dart';

import '../../features/admin/presentation/pages/admin_settings_page.dart';
import '../../features/branding/presentation/pages/admin_branding_page.dart';

import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../features/admin/presentation/pages/admin_requests_page.dart';
import '../../features/admin/presentation/pages/admin_request_page.dart';
import '../../features/admin/presentation/pages/admin_announcements_page.dart';
import '../../features/products/presentation/pages/bank_notices_page.dart';

import '../../features/products/presentation/pages/exchange_rates_page.dart';

import '../../features/accounts/presentation/pages/account_details_page.dart';
import '../../features/accounts/presentation/pages/accounts_page.dart';
import '../../features/authentication/presentation/bloc/auth_bloc.dart';
import '../../features/authentication/presentation/pages/forgot_password_page.dart';
import '../../features/authentication/presentation/pages/login_page.dart';
import '../../features/authentication/presentation/pages/registration_page.dart';
import '../../features/authentication/presentation/pages/password_change_page.dart';
import '../../features/settings/presentation/pages/profile_page.dart';
import '../../features/transfers/presentation/pages/transfers_page.dart';
import '../../features/authentication/presentation/pages/password_setup_page.dart';
import '../../features/authentication/presentation/pages/splash_page.dart';
import '../../features/cards/presentation/pages/card_details_page.dart';
import '../../features/cards/presentation/pages/cards_page.dart';
import '../../features/cards/presentation/pages/card_application_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/more/presentation/pages/more_page.dart';
import '../../features/transactions/domain/repositories/transactions_repository.dart';
import '../../features/transactions/presentation/pages/transactions_page.dart';
import '../presentation/main_shell.dart';
import 'app_routes.dart';
import 'route_guard.dart';

GoRouter buildRouter({required AuthBloc authBloc}) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: GoRouterRefreshStream(
      authBloc.stream,
      sl.isRegistered<BankSelectionCubit>()
          ? sl<BankSelectionCubit>().stream
          : null,
    ),
    redirect: (context, state) => resolveRedirect(
      auth: authBloc.state,
      location: state.uri.path,
      hasSelectedBank:
          !sl.isRegistered<BankSelectionCubit>() ||
          sl<BankSelectionCubit>().state != null,
    ),
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, _) => const BankOnboardingPage(),
      ),
      GoRoute(
        path: AppRoutes.adminSettings,
        builder: (_, _) => const AdminSettingsPage(),
      ),
      GoRoute(
        path: AppRoutes.adminBranding,
        builder: (_, _) => const AdminBrandingPage(),
      ),
      GoRoute(
        path: AppRoutes.branches,
        builder: (_, _) =>
            const BankServicesGate(kind: BankServiceKind.branches),
      ),
      GoRoute(
        path: AppRoutes.atms,
        builder: (_, _) => const BankServicesGate(kind: BankServiceKind.atms),
      ),
      GoRoute(
        path: AppRoutes.callCenter,
        builder: (_, _) =>
            const BankServicesGate(kind: BankServiceKind.callCenter),
      ),
      GoRoute(
        path: AppRoutes.preLogin,
        builder: (_, _) => const BankNoticesPage(),
      ),
      GoRoute(
        path: AppRoutes.announcementDetails,
        builder: (_, s) =>
            BankNoticesPage(id: s.pathParameters['announcementId']!),
      ),
      GoRoute(
        path: AppRoutes.adminRequests,
        builder: (_, _) => const AdminRequestsPage(),
      ),
      GoRoute(
        path: AppRoutes.adminRequestDetails,
        builder: (_, s) =>
            AdminRequestDetailsPage(id: s.pathParameters['requestId']!),
      ),
      GoRoute(
        path: AppRoutes.adminAnnouncements,
        builder: (_, _) => const AdminAnnouncementsPage(),
      ),
      GoRoute(
        path: AppRoutes.admin,
        builder: (_, _) => const AdminDashboardPage(),
      ),
      GoRoute(
        path: AppRoutes.products,
        redirect: (_, _) => AppRoutes.accountCertificates,
      ),
      GoRoute(
        path: AppRoutes.exchangeRates,
        builder: (_, _) => const ExchangeRatesPage(),
      ),
      GoRoute(
        path: AppRoutes.registration,
        builder: (_, _) => const RegistrationPage(),
      ),
      GoRoute(path: AppRoutes.profile, builder: (_, _) => const ProfilePage()),
      GoRoute(
        path: AppRoutes.passwordChange,
        builder: (_, _) => const PasswordChangePage(),
      ),
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.passwordSetup,
        builder: (context, state) => const PasswordSetupPage(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.transfers,
            builder: (_, _) => const TransfersPage(),
          ),
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: AppRoutes.accounts,
            builder: (context, state) => AccountsPage(
              key: ValueKey(state.uri.queryParameters['section']),
              initialTab: switch (state.uri.queryParameters['section']) {
                'certificates' => 1,
                'funds' => 2,
                _ => 0,
              },
            ),
          ),
          GoRoute(
            path: AppRoutes.cards,
            builder: (context, state) => const CardsPage(),
          ),
          GoRoute(
            path: AppRoutes.more,
            builder: (context, state) => const MorePage(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.accountDetails,
        builder: (context, state) => AccountDetailsPage(
          accountId: state.pathParameters['accountId'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.accountTransactions,
        builder: (context, state) => TransactionsPage(
          scope: TransactionScope.account,
          scopeId: state.pathParameters['accountId'],
        ),
      ),
      GoRoute(
        path: AppRoutes.cardApplication,
        builder: (_, _) => const CardApplicationPage(),
      ),
      GoRoute(
        path: AppRoutes.cardDetails,
        builder: (context, state) =>
            CardDetailsPage(cardId: state.pathParameters['cardId'] ?? ''),
      ),
      GoRoute(
        path: AppRoutes.cardTransactions,
        builder: (context, state) => TransactionsPage(
          scope: TransactionScope.card,
          scopeId: state.pathParameters['cardId'],
        ),
      ),
      GoRoute(
        path: AppRoutes.transactions,
        builder: (context, state) => const TransactionsPage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: Text(BankingIdentity.displayName(context))),
      body: Center(
        child: TextButton(
          onPressed: () => context.go(AppRoutes.home),
          child: const Text('Return home'),
        ),
      ),
    ),
  );
}
