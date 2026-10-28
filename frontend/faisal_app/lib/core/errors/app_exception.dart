/// Failure codes shared by the API layer and the UI.
enum AppErrorCode {
  network,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  validation,
  rateLimited,
  conflict,
  server,
  unknown,
}

/// Immutable, user-presentable error wrapper.
class AppException implements Exception {
  const AppException({
    required this.code,
    this.message,
    this.statusCode,
    this.details,
  });

  final AppErrorCode code;
  final String? message;
  final int? statusCode;
  final Object? details;

  bool get isAuthFailure =>
      code == AppErrorCode.unauthorized || code == AppErrorCode.forbidden;

  @override
  String toString() => 'AppException($code, $statusCode, $message)';
}
