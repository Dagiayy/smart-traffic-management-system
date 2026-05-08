import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

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

  // ── Tokens ───────────────────────────────────────────────────────────
  Future<void> saveTokens({required String access, required String refresh}) async {
    await _secure.write(key: AppConstants.kAccessToken, value: access);
    await _secure.write(key: AppConstants.kRefreshToken, value: refresh);
  }

  Future<String?> getAccessToken()  => _secure.read(key: AppConstants.kAccessToken);
  Future<String?> getRefreshToken() => _secure.read(key: AppConstants.kRefreshToken);

  Future<void> clearTokens() async {
    await _secure.delete(key: AppConstants.kAccessToken);
    await _secure.delete(key: AppConstants.kRefreshToken);
  }

  // ── User cache ────────────────────────────────────────────────────────
  Future<void> saveUserCache(String json) async =>
      _prefs?.setString(AppConstants.kUserCache, json);
  String? getUserCache() => _prefs?.getString(AppConstants.kUserCache);
  Future<void> clearUserCache() async =>
      _prefs?.remove(AppConstants.kUserCache);

  // ── Remember me ───────────────────────────────────────────────────────
  bool get rememberMe => _prefs?.getBool(AppConstants.kRememberMe) ?? false;
  Future<void> setRememberMe(bool v) async =>
      _prefs?.setBool(AppConstants.kRememberMe, v);

  // ── Offline ticket queue ──────────────────────────────────────────────
  List<Map<String, dynamic>> getOfflineQueue() {
    final raw = _prefs?.getString(AppConstants.kOfflineQueue);
    if (raw == null) return [];
    try {
      return List<Map<String, dynamic>>.from(
          (jsonDecode(raw) as List).whereType<Map<String, dynamic>>());
    } catch (_) {
      return [];
    }
  }

  Future<void> saveOfflineQueue(List<Map<String, dynamic>> queue) async {
    await _prefs?.setString(AppConstants.kOfflineQueue, jsonEncode(queue));
  }

  Future<void> addToOfflineQueue(Map<String, dynamic> ticket) async {
    final q = getOfflineQueue();
    q.add(ticket);
    await saveOfflineQueue(q);
  }

  Future<void> removeFromOfflineQueue(String localId) async {
    final q = getOfflineQueue()..removeWhere((t) => t['local_id'] == localId);
    await saveOfflineQueue(q);
  }

  // ── Reference data cache ──────────────────────────────────────────────
  Future<void> saveViolationTypes(String json) async =>
      _prefs?.setString(AppConstants.kViolationTypesCache, json);
  String? getViolationTypes() =>
      _prefs?.getString(AppConstants.kViolationTypesCache);

  Future<void> saveIntersections(String json) async =>
      _prefs?.setString(AppConstants.kIntersectionsCache, json);
  String? getIntersections() =>
      _prefs?.getString(AppConstants.kIntersectionsCache);

  Future<void> clearAll() async {
    await _secure.deleteAll();
    await _prefs?.clear();
  }
}
