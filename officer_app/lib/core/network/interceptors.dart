import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../storage/app_storage.dart';
import 'api_exceptions.dart';

class AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final isPublic = options.path.contains('/auth/login') ||
        options.path.contains('/auth/token/refresh') ||
        options.path.contains('/auth/otp/');
    if (!isPublic) {
      final token = await AppStorage.instance.getAccessToken();
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
    }
    options.headers['Accept'] = 'application/json';
    handler.next(options);
  }
}

class TokenRefreshInterceptor extends QueuedInterceptor {
  TokenRefreshInterceptor(this._dio, this.onSessionExpired);
  final Dio _dio;
  final void Function() onSessionExpired;
  bool _refreshing = false;

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 &&
        !err.requestOptions.path.contains('/auth/token/refresh') &&
        !_refreshing) {
      _refreshing = true;
      try {
        final refresh = await AppStorage.instance.getRefreshToken();
        if (refresh == null) { _refreshing = false; onSessionExpired(); return handler.reject(err); }
        final r = await Dio(BaseOptions(baseUrl: AppConstants.apiBaseUrl))
            .post('/auth/token/refresh/', data: {'refresh': refresh});
        final newAccess = r.data['access'] as String?;
        if (newAccess == null) { _refreshing = false; onSessionExpired(); return handler.reject(err); }
        final newRefresh = (r.data['refresh'] as String?) ?? refresh;
        await AppStorage.instance.saveTokens(access: newAccess, refresh: newRefresh);
        final opts = err.requestOptions..headers['Authorization'] = 'Bearer $newAccess';
        final retried = await _dio.fetch(opts);
        _refreshing = false;
        return handler.resolve(retried);
      } catch (_) { _refreshing = false; onSessionExpired(); return handler.reject(err); }
    }
    handler.next(err);
  }
}

class ErrorNormalizer extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.reject(DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: _translate(err),
      message: _translate(err).message,
    ));
  }

  ApiException _translate(DioException err) {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout) return const TimeoutException();
    if (err.type == DioExceptionType.connectionError) return const NetworkException();
    final data = err.response?.data;
    String msg = 'Something went wrong.';
    String? code;
    Map<String, dynamic>? details;
    if (data is Map<String, dynamic>) {
      msg = (data['error'] ?? data['detail'] ?? msg).toString();
      code = data['code']?.toString();
      details = data['details'] is Map<String, dynamic> ? data['details'] as Map<String, dynamic> : null;
    }
    return switch (err.response?.statusCode) {
      401   => UnauthorizedException(msg),
      403   => ForbiddenException(msg),
      404   => NotFoundException(msg),
      422   => ValidationException(message: msg, details: details),
      500   => const ServerException(),
      _     => ApiException(message: msg, code: code, details: details, statusCode: err.response?.statusCode),
    };
  }
}
