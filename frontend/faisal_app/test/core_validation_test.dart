import 'package:faisal_app/core/errors/app_exception.dart';
import 'package:faisal_app/core/network/api_error_mapper.dart';
import 'package:faisal_app/core/routing/route_guard.dart';
import 'package:faisal_app/core/utils/password_policy.dart';
import 'package:faisal_app/features/authentication/presentation/bloc/auth_state.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('password policy', () {
    test('accepts a compliant password', () {
      expect(evaluatePassword('Bank@2026A').isValid, isTrue);
    });
    test('rejects three consecutive identical characters', () {
      expect(
        evaluatePassword('Bank@111A').failed,
        contains(PasswordRequirement.noTripleRepeat),
      );
    });
    test(
      'rejects missing uppercase, lowercase, digit, special and short values',
      () {
        expect(evaluatePassword('bank@2026a').isValid, isFalse);
        expect(evaluatePassword('BANK@2026A').isValid, isFalse);
        expect(evaluatePassword('Bank2026Aa').isValid, isFalse);
        expect(evaluatePassword('Aa@12').isValid, isFalse);
      },
    );
    test('confirmation must match exactly', () {
      expect(passwordsMatch('Bank@2026A', 'Bank@2026B'), isFalse);
      expect(passwordsMatch('Bank@2026A', 'Bank@2026A'), isTrue);
    });
  });

  group('api error mapping', () {
    test('maps 401 to unauthorized', () {
      final error = mapResponseError(
        Response<dynamic>(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 401,
        ),
      );
      expect(error.code, AppErrorCode.unauthorized);
    });
    test('maps validation status codes', () {
      final error = mapResponseError(
        Response<dynamic>(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 422,
        ),
      );
      expect(error.code, AppErrorCode.validation);
    });
    test('skips expired sessions back to login', () {
      final redirect = resolveRedirect(
        auth: const AuthState(status: AuthStatus.unauthenticated),
        location: '/home',
      );
      expect(redirect, '/bank-notices');
    });
    test('forces password setup before home', () {
      final redirect = resolveRedirect(
        auth: const AuthState(status: AuthStatus.firstLoginRequired),
        location: '/home',
      );
      expect(redirect, '/first-login/password-setup');
    });
  });
}
