import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../constants/app_constants.dart';
import 'interceptors.dart';

class ApiClient {
  ApiClient({required this.onSessionExpired}) {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      sendTimeout: AppConstants.connectTimeout,
      responseType: ResponseType.json,
      validateStatus: (s) => s != null && s < 500,
    ));
    _dio.interceptors.addAll([
      AuthInterceptor(),
      TokenRefreshInterceptor(_dio, onSessionExpired),
      ErrorNormalizer(),
      if (kDebugMode) PrettyDioLogger(requestBody: true, responseBody: true, compact: true),
    ]);
  }

  final void Function() onSessionExpired;
  late final Dio _dio;
  Dio get dio => _dio;

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? query, Options? opts}) =>
      _dio.get<T>(path, queryParameters: query, options: opts);

  Future<Response<T>> post<T>(String path, {dynamic data, Map<String, dynamic>? query, Options? opts}) =>
      _dio.post<T>(path, data: data, queryParameters: query, options: opts);

  Future<Response<T>> patch<T>(String path, {dynamic data}) =>
      _dio.patch<T>(path, data: data);

  Future<Response<T>> delete<T>(String path, {dynamic data}) =>
      _dio.delete<T>(path, data: data);

  Future<Response<T>> postMultipart<T>(String path, FormData form) =>
      _dio.post<T>(path, data: form, options: Options(contentType: 'multipart/form-data'));

  Future<Response<T>> patchMultipart<T>(String path, FormData form) =>
      _dio.patch<T>(path, data: form, options: Options(contentType: 'multipart/form-data'));
}

// A global nullable hook set by main.dart so ApiClient can navigate on session expiry.
// Using a callback avoids circular imports between api_client ↔ auth_providers.
void Function()? _onSessionExpiredGlobal;

void setSessionExpiredHandler(void Function() handler) {
  _onSessionExpiredGlobal = handler;
}

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    onSessionExpired: () => _onSessionExpiredGlobal?.call(),
  );
});
