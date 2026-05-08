import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

/// Wraps secure (encrypted) storage for tokens, and SharedPreferences for non-sensitive flags.
class AppStorage {
  AppStorage._();
  static final AppStorage instance = AppStorage._();

  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // -------------------- Tokens (secure) --------------------
  Future<void> saveTokens(
      {required String access, required String refresh}) async {
    await _secure.write(key: AppConstants.kAccessToken, value: access);
    await _secure.write(key: AppConstants.kRefreshToken, value: refresh);
  }

  Future<String?> getAccessToken() =>
      _secure.read(key: AppConstants.kAccessToken);

  Future<String?> getRefreshToken() =>
      _secure.read(key: AppConstants.kRefreshToken);

  Future<void> clearTokens() async {
    await _secure.delete(key: AppConstants.kAccessToken);
    await _secure.delete(key: AppConstants.kRefreshToken);
  }

  // -------------------- User cache (non-sensitive) --------------------
  Future<void> saveUserCache(String json) async {
    await _prefs?.setString(AppConstants.kUserCache, json);
  }

  String? getUserCache() => _prefs?.getString(AppConstants.kUserCache);

  Future<void> clearUserCache() async {
    await _prefs?.remove(AppConstants.kUserCache);
  }

  // -------------------- Onboarding --------------------
  bool get onboardingDone =>
      _prefs?.getBool(AppConstants.kOnboardingDone) ?? false;
  Future<void> setOnboardingDone(bool v) async {
    await _prefs?.setBool(AppConstants.kOnboardingDone, v);
  }

  // -------------------- Remember Me --------------------
  bool get rememberMe => _prefs?.getBool(AppConstants.kRememberMe) ?? false;
  Future<void> setRememberMe(bool v) async {
    await _prefs?.setBool(AppConstants.kRememberMe, v);
  }

  // -------------------- Push Token --------------------
  String? get pushToken => _prefs?.getString(AppConstants.kPushToken);
  Future<void> setPushToken(String token) async {
    await _prefs?.setString(AppConstants.kPushToken, token);
  }

  // -------------------- Generic --------------------
  Future<void> clearAll() async {
    await _secure.deleteAll();
    await _prefs?.clear();
  }
}
