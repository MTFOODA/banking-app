import 'package:dio/dio.dart';

import '../errors/app_exception.dart';

/// Maps transport and API errors to a single [AppException] type so the UI can
/// present consistent, localized messages.
AppException mapDioError(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return const AppException(code: AppErrorCode.timeout);
    case DioExceptionType.connectionError:
    case DioExceptionType.badCertificate:
      return const AppException(code: AppErrorCode.network);
    case DioExceptionType.cancel:
      return const AppException(code: AppErrorCode.unknown);
    case DioExceptionType.badResponse:
      return mapResponseError(error.response);
    case DioExceptionType.unknown:
      return const AppException(code: AppErrorCode.network);
  }
}

AppException mapResponseError(Response<dynamic>? response) {
  final status = response?.statusCode ?? 0;
  final data = response?.data;
  String? message;
  String? serverCode;
  Object? details;

  if (data is Map<String, dynamic>) {
    final error = data['error'];
    if (error is Map<String, dynamic>) {
      message = error['message'] as String?;
      serverCode = error['code'] as String?;
      details = error['details'];
    }
  }

  final code = switch (status) {
    400 || 409 || 422 => AppErrorCode.validation,
    401 => AppErrorCode.unauthorized,
    403 => AppErrorCode.forbidden,
    404 => AppErrorCode.notFound,
    429 => AppErrorCode.rateLimited,
    >= 500 => AppErrorCode.server,
    _ => AppErrorCode.unknown,
  };

  return AppException(
    code: code,
    statusCode: status,
    message: message,
    details: <String, dynamic>{'server_code': ?serverCode, 'details': details},
  );
}

/// Extracts the server error code (e.g. `password_policy_violation`).
String? serverErrorCode(AppException exception) {
  final details = exception.details;
  if (details is Map<String, dynamic>) {
    final code = details['server_code'];
    if (code is String) {
      return code;
    }
  }
  return null;
}

/// Reads `details.failed_requirements` from a password policy violation.
List<String> failedPasswordRequirements(AppException exception) {
  final details = exception.details;
  if (details is Map<String, dynamic>) {
    final inner = details['details'];
    if (inner is Map<String, dynamic>) {
      final requirements = inner['failed_requirements'];
      if (requirements is List) {
        return requirements.whereType<String>().toList();
      }
    }
  }
  return const <String>[];
}
