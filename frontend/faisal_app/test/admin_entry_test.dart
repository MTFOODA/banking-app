import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:faisal_app/core/routing/app_router.dart';
import 'package:faisal_app/core/routing/app_routes.dart';
import 'package:faisal_app/core/routing/route_guard.dart';
import 'package:faisal_app/core/security/session_store.dart';
import 'package:faisal_app/features/authentication/domain/entities/auth_entities.dart';
import 'package:faisal_app/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:faisal_app/features/authentication/presentation/bloc/auth_state.dart';
import 'package:faisal_app/features/admin/domain/entities/admin_entities.dart';
import 'package:faisal_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:faisal_app/features/admin/presentation/cubit/admin_dashboard_cubit.dart';

import 'security_flows_test.dart' as fixtures;

const admin = SessionUser(
  id: 'staff',
  maskedIdentifier: '***01',
  username: 'devadmin',
  loginType: 'staff',
  mustChangePassword: false,
  permissions: ['admin.dashboard.view'],
);

class PendingAdmin extends AdminRepository {
  final result = Completer<AdminDashboard>();
  @override
  Future<AdminDashboard> fetchDashboard() => result.future;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'admin route exists and staff startup goes to protected dashboard',
    () async {
      final bloc = AuthBloc(fixtures.FakeAuth(), SessionStore());
      final router = buildRouter(authBloc: bloc);
      expect(
        router.configuration.routes.any(
          (r) => r is GoRoute && r.path == AppRoutes.admin,
        ),
        isTrue,
      );
      const auth = AuthState(status: AuthStatus.authenticated, user: admin);
      for (final location in [
        AppRoutes.login,
        AppRoutes.splash,
        AppRoutes.passwordSetup,
        AppRoutes.home,
      ]) {
        expect(
          resolveRedirect(auth: auth, location: location),
          AppRoutes.admin,
        );
      }
      expect(resolveRedirect(auth: auth, location: AppRoutes.admin), isNull);
      router.dispose();
      await bloc.close();
    },
  );
  test(
    'customer cannot enter admin and initial password setup stays mandatory',
    () {
      const customer = SessionUser(
        id: 'customer',
        maskedIdentifier: '***02',
        username: 'devadmin',
        loginType: 'customer',
        mustChangePassword: false,
      );
      expect(
        resolveRedirect(
          auth: const AuthState(
            status: AuthStatus.authenticated,
            user: customer,
          ),
          location: AppRoutes.admin,
        ),
        AppRoutes.home,
      );
      expect(
        resolveRedirect(
          auth: const AuthState(
            status: AuthStatus.firstLoginRequired,
            user: admin,
          ),
          location: AppRoutes.admin,
        ),
        AppRoutes.passwordSetup,
      );
    },
  );
  test('closing dashboard during a request ignores late errors', () async {
    final repo = PendingAdmin();
    final cubit = AdminDashboardCubit(repo);
    final request = cubit.load();
    await cubit.close();
    repo.result.completeError(fixtures.failure);
    await request;
  });
}
