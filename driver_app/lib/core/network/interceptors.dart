import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../storage/app_storage.dart';
import 'api_exceptions.dart';

/// Attaches `Authorization: Bearer <access>` to every request.
class AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth header for public endpoints
    final path = options.path;
    final isPublic = path.contains('/auth/login') ||
        path.contains('/auth/register') ||
        path.contains('/auth/token/refresh') ||
        path.contains('/auth/otp/send') ||
        path.contains('/auth/otp/verify') ||
        path.contains('/auth/password/reset');

    if (!isPublic) {
      final token = await AppStorage.instance.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    options.headers['Accept'] = 'application/json';
    handler.next(options);
  }
}

/// On 401 response, attempts to refresh access token using refresh token.
/// If refresh succeeds — retries the failed request transparently.
/// If refresh fails — propagates UnauthorizedException for global logout handling.
class TokenRefreshInterceptor extends QueuedInterceptor {
  TokenRefreshInterceptor(this._dio, this.onSessionExpired);

  final Dio _dio;
  final void Function() onSessionExpired;

  bool _isRefreshing = false;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final isAuthEndpoint =
        err.requestOptions.path.contains('/auth/token/refresh');

    if (err.response?.statusCode == 401 && !isAuthEndpoint && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshToken = await AppStorage.instance.getRefreshToken();
        if (refreshToken == null || refreshToken.isEmpty) {
          _isRefreshing = false;
          onSessionExpired();
          return handler.reject(err);
        }

        final refreshDio = Dio(BaseOptions(baseUrl: AppConstants.apiBaseUrl));
        final res = await refreshDio.post(
          '/auth/token/refresh/',
          data: {'refresh': refreshToken},
        );

        final newAccess = res.data['access'] as String?;
        final newRefresh =
            (res.data['refresh'] as String?) ?? refreshToken;
        if (newAccess == null) {
          _isRefreshing = false;
          onSessionExpired();
          return handler.reject(err);
        }

        await AppStorage.instance
            .saveTokens(access: newAccess, refresh: newRefresh);

        // Retry original request with new token
        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer $newAccess';
        final retried = await _dio.fetch(opts);
        _isRefreshing = false;
        return handler.resolve(retried);
      } catch (_) {
        _isRefreshing = false;
        onSessionExpired();
        return handler.reject(err);
      }
    }
    handler.next(err);
  }
}

/// Converts Dio errors into our typed [ApiException] hierarchy.
class ErrorNormalizer extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final translated = _translate(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: translated,
        message: translated.message,
      ),
    );
  }

  ApiException _translate(DioException err) {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      return const TimeoutException();
    }
    if (err.type == DioExceptionType.connectionError) {
      return const NetworkException();
    }

    final response = err.response;
    final status = response?.statusCode;
    final data = response?.data;

    String message = 'Something went wrong.';
    String? code;
    Map<String, dynamic>? details;

    if (data is Map<String, dynamic>) {
      message = (data['error'] ?? data['detail'] ?? message).toString();
      code = data['code']?.toString();
      details = data['details'] is Map<String, dynamic>
          ? data['details'] as Map<String, dynamic>
          : null;
    }

    switch (status) {
      case 400:
        return ApiException(
            message: message, code: code, details: details, statusCode: 400);
      case 401:
        return UnauthorizedException(message);
      case 403:
        return ForbiddenException(message);
      case 404:
        return NotFoundException(message);
      case 422:
        return ValidationException(message: message, details: details);
      case 500:
      case 502:
      case 503:
        return ServerException(message);
      default:
        return ApiException(
          message: message,
          code: code,
          details: details,
          statusCode: status,
        );
    }
  }
}
