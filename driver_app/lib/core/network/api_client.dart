import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import 'interceptors.dart';

/// Singleton Dio client with auth, refresh, error normalization, and logging.
class ApiClient {
  ApiClient({required this.onSessionExpired}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        sendTimeout: AppConstants.connectTimeout,
        contentType: 'application/json',
        responseType: ResponseType.json,
        validateStatus: (s) => s != null && s < 500,
      ),
    );

    _dio.interceptors.addAll([
      AuthInterceptor(),
      TokenRefreshInterceptor(_dio, onSessionExpired),
      ErrorNormalizer(),
      if (kDebugMode)
        PrettyDioLogger(
          requestHeader: false,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
          maxWidth: 100,
        ),
    ]);
  }

  final void Function() onSessionExpired;
  late final Dio _dio;

  Dio get dio => _dio;

  // -------------------- Convenience HTTP methods --------------------
  Future<Response<T>> get<T>(String path,
          {Map<String, dynamic>? query, Options? options}) =>
      _dio.get<T>(path, queryParameters: query, options: options);

  Future<Response<T>> post<T>(String path,
          {dynamic data, Map<String, dynamic>? query, Options? options}) =>
      _dio.post<T>(path,
          data: data, queryParameters: query, options: options);

  Future<Response<T>> put<T>(String path,
          {dynamic data, Map<String, dynamic>? query}) =>
      _dio.put<T>(path, data: data, queryParameters: query);

  Future<Response<T>> patch<T>(String path,
          {dynamic data, Map<String, dynamic>? query}) =>
      _dio.patch<T>(path, data: data, queryParameters: query);

  Future<Response<T>> delete<T>(String path, {dynamic data}) =>
      _dio.delete<T>(path, data: data);
}

/// Riverpod provider — instantiated once at app startup with logout callback.
final apiClientProvider = Provider<ApiClient>((ref) {
  throw UnimplementedError(
      'apiClientProvider must be overridden in main.dart with the session-expired callback');
});
