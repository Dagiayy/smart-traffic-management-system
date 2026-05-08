class ApiException implements Exception {
  final String message;
  final String? code;
  final Map<String, dynamic>? details;
  final int? statusCode;
  const ApiException({required this.message, this.code, this.details, this.statusCode});
  @override
  String toString() => message;
}
class NetworkException  extends ApiException { const NetworkException([String? m]) : super(message: m ?? 'No internet connection.', code: 'NETWORK_ERROR'); }
class TimeoutException  extends ApiException { const TimeoutException()             : super(message: 'Request timed out. Please try again.', code: 'TIMEOUT'); }
class UnauthorizedException extends ApiException { const UnauthorizedException([String? m]) : super(message: m ?? 'Session expired. Please sign in again.', code: 'UNAUTHORIZED', statusCode: 401); }
class ForbiddenException extends ApiException { const ForbiddenException([String? m]) : super(message: m ?? 'Access denied.', code: 'FORBIDDEN', statusCode: 403); }
class ValidationException extends ApiException { ValidationException({required super.message, super.details}) : super(code: 'VALIDATION_ERROR', statusCode: 422); }
class NotFoundException  extends ApiException { const NotFoundException([String? m])  : super(message: m ?? 'Not found.', code: 'NOT_FOUND', statusCode: 404); }
class ServerException    extends ApiException { const ServerException([String? m])    : super(message: m ?? 'Server error. Try again later.', code: 'SERVER_ERROR', statusCode: 500); }
