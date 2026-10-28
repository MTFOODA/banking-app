import 'dart:async';
import 'dart:io' show SocketException;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../errors/app_exception.dart';
import '../security/session_store.dart';
import 'api_error_mapper.dart';

typedef TokenRefresher = Future<bool> Function();
typedef SessionExpiredCallback = Future<void> Function();

/// Shared Dio configuration with bearer-token attachment, single-flight token
/// refresh and consistent error mapping.
///
/// Authorization headers and payloads are never logged.
class DioClient {
  DioClient({required this._sessionStore, Dio? dio, this.languageProvider})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: AppConfig.apiBaseUrl,
              connectTimeout: AppConfig.connectTimeout,
              receiveTimeout: AppConfig.receiveTimeout,
              sendTimeout: AppConfig.sendTimeout,
              headers: const {'Accept': 'application/json'},
              responseType: ResponseType.json,
              validateStatus: (status) => status != null && status < 400,
            ),
          ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _sessionStore.accessToken;
          if (token != null &&
              token.isNotEmpty &&
              !options.headers.containsKey('Authorization')) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          final language = languageProvider?.call();
          if (language != null) {
            options.headers['Accept-Language'] = language;
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final status = error.response?.statusCode;
          final isRefreshCall = error.requestOptions.path.contains(
            '/auth/refresh',
          );
          final canRetry =
              status == 401 &&
              !isRefreshCall &&
              _sessionStore.hasSession &&
              !error.requestOptions.path.contains('/auth/registration/') &&
              !error.requestOptions.path.contains('/auth/first-login/') &&
              error.requestOptions.extra['retried'] != true &&
              _refresher != null;

          if (canRetry) {
            final refreshed = await _refreshOnce();
            if (refreshed) {
              final options = error.requestOptions
                ..extra['retried'] = true
                ..headers['Authorization'] =
                    'Bearer ${_sessionStore.accessToken ?? ''}';
              try {
                final response = await _dio.fetch<dynamic>(options);
                return handler.resolve(response);
              } on DioException catch (retryError) {
                return handler.next(retryError);
              }
            }
            await _onExpired?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  final SessionStore _sessionStore;
  final Dio _dio;
  final String? Function()? languageProvider;

  TokenRefresher? _refresher;
  SessionExpiredCallback? _onExpired;
  Future<bool>? _refreshInFlight;

  Dio get raw => _dio;

  void configureSession({
    required TokenRefresher onRefresh,
    required SessionExpiredCallback onExpired,
  }) {
    _refresher = onRefresh;
    _onExpired = onExpired;
  }

  Future<bool> _refreshOnce() {
    final existing = _refreshInFlight;
    if (existing != null) {
      return existing;
    }
    final future = (_refresher ?? () async => false)();
    _refreshInFlight = future;
    return future.whenComplete(() => _refreshInFlight = null);
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) {
    return _request(
      () => _dio.get<dynamic>(path, queryParameters: _clean(query)),
    );
  }

  Future<dynamic> post(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
  }) {
    return _request(
      () => _dio.post<dynamic>(
        path,
        data: body,
        queryParameters: _clean(query),
        options: headers == null ? null : Options(headers: headers),
      ),
    );
  }

  Future<dynamic> patch(String path, {Object? body}) {
    return _request(() => _dio.patch<dynamic>(path, data: body));
  }

  Future<dynamic> delete(String path) {
    return _request(() => _dio.delete<dynamic>(path));
  }

  Future<dynamic> upload(
    String path, {
    required String filename,
    required Uint8List bytes,
    String? contentType,
  }) {
    return _request(() async {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: filename,
          contentType: contentType == null
              ? null
              : DioMediaType.parse(contentType),
        ),
      });
      return _dio.post<dynamic>(path, data: formData);
    });
  }

  Map<String, dynamic>? _clean(Map<String, dynamic>? query) {
    if (query == null) {
      return null;
    }
    final cleaned = <String, dynamic>{};
    for (final entry in query.entries) {
      final value = entry.value;
      if (value == null) {
        continue;
      }
      if (value is String && value.isEmpty) {
        continue;
      }
      cleaned[entry.key] = value;
    }
    return cleaned;
  }

  Future<dynamic> _request(Future<Response<dynamic>> Function() call) async {
    try {
      final response = await call();
      return response.data;
    } on DioException catch (error) {
      throw mapDioError(error);
    } on SocketException {
      throw const AppException(code: AppErrorCode.network);
    } catch (_) {
      throw const AppException(code: AppErrorCode.unknown);
    }
  }
}
