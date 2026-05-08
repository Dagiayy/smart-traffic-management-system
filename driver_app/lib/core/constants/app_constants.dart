/// Centralized app constants. Update [apiBaseUrl] for staging/production.
class AppConstants {
  AppConstants._();

  // -------------------- API --------------------
  /// Backend base URL — matches Django backend `/api/v1/` prefix
  static const String apiBaseUrl = 'http://127.0.0.1:8000//api/v1';
  // For physical device testing, replace with your machine LAN IP, e.g.
  // 'http://192.168.1.10:8000/api/v1'

  static const String wsBaseUrl = 'ws://127.0.0.1:8000/ws';

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 20);

  // -------------------- Storage Keys --------------------
  static const String kAccessToken = 'access_token';
  static const String kRefreshToken = 'refresh_token';
  static const String kUserCache = 'user_cache';
  static const String kOnboardingDone = 'onboarding_done';
  static const String kRememberMe = 'remember_me';
  static const String kThemeMode = 'theme_mode';
  static const String kLocale = 'locale';
  static const String kPushToken = 'push_token';

  // -------------------- App Info --------------------
  static const String appName = 'Citizen Traffic Compliance';
  static const String appTagline = 'Smart Driving. Safe Roads. Easy Compliance.';
  static const String supportEmail = 'support@traffic.gov';
  static const String supportPhone = '+251-911-000-000';
}

/// User role enum mirroring backend `accounts.role`
enum UserRole {
  citizen('CITIZEN'),
  officer('OFFICER'),
  supervisor('SUPERVISOR'),
  admin('ADMIN'),
  developer('DEVELOPER');

  final String value;
  const UserRole(this.value);

  static UserRole fromString(String? value) {
    return UserRole.values.firstWhere(
      (e) => e.value == value,
      orElse: () => UserRole.citizen,
    );
  }
}
