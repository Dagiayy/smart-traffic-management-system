import '../../../core/network/api_client.dart';
import '../../../core/storage/app_storage.dart';
import '../../../shared/models/app_user.dart';

/// Wraps all auth-related backend endpoints.
class AuthRepository {
  AuthRepository(this._api);
  final ApiClient _api;

  /// POST /auth/login/
  /// Body: { phone_or_email, password }
  /// Returns: { access, refresh, user }
  Future<AppUser> login({
    required String phoneOrEmail,
    required String password,
  }) async {
    final res = await _api.post('/auth/login/', data: {
      'phone_or_email': phoneOrEmail,
      'password': password,
    });
    final data = res.data as Map<String, dynamic>;
    await AppStorage.instance.saveTokens(
      access: data['access'],
      refresh: data['refresh'],
    );
    final user = AppUser.fromJson(data['user']);
    await AppStorage.instance.saveUserCache(user.encoded);
    return user;
  }

  /// POST /auth/register/
  /// Body: { full_name, national_id, phone, email, password, vehicles[] }
  Future<AppUser> register({
    required String fullName,
    required String nationalId,
    required String phone,
    required String email,
    required String password,
    List<Map<String, dynamic>> vehicles = const [],
  }) async {
    final res = await _api.post('/auth/register/', data: {
      'full_name': fullName,
      'national_id': nationalId,
      'phone': phone,
      'email': email,
      'password': password,
      'vehicles': vehicles,
    });
    final data = res.data as Map<String, dynamic>;
    if (data['access'] != null && data['refresh'] != null) {
      await AppStorage.instance.saveTokens(
        access: data['access'],
        refresh: data['refresh'],
      );
    }
    final user = AppUser.fromJson(data['user'] ?? data);
    await AppStorage.instance.saveUserCache(user.encoded);
    return user;
  }

  /// POST /auth/otp/send/
  /// purpose: "verify" | "reset"
  Future<void> sendOtp(
      {required String phoneOrEmail, required String purpose}) async {
    await _api.post('/auth/otp/send/', data: {
      'phone_or_email': phoneOrEmail,
      'purpose': purpose,
    });
  }

  /// POST /auth/otp/verify/
  /// Returns { otp_token } on success — used for password reset confirmation
  Future<String?> verifyOtp(
      {required String phoneOrEmail, required String code}) async {
    final res = await _api.post('/auth/otp/verify/', data: {
      'phone_or_email': phoneOrEmail,
      'code': code,
    });
    final data = res.data as Map<String, dynamic>;
    return data['otp_token'] as String?;
  }

  /// POST /auth/password/reset/
  Future<void> resetPassword({
    required String phoneOrEmail,
    required String newPassword,
    required String otpToken,
  }) async {
    await _api.post('/auth/password/reset/', data: {
      'phone_or_email': phoneOrEmail,
      'new_password': newPassword,
      'otp_token': otpToken,
    });
  }

  /// GET /auth/me/
  Future<AppUser> getMe() async {
    final res = await _api.get('/auth/me/');
    final user = AppUser.fromJson(res.data as Map<String, dynamic>);
    await AppStorage.instance.saveUserCache(user.encoded);
    return user;
  }

  /// PUT /auth/me/
  Future<AppUser> updateProfile(Map<String, dynamic> body) async {
    final res = await _api.put('/auth/me/', data: body);
    final user = AppUser.fromJson(res.data as Map<String, dynamic>);
    await AppStorage.instance.saveUserCache(user.encoded);
    return user;
  }

  /// POST /auth/logout/
  Future<void> logout() async {
    final refresh = await AppStorage.instance.getRefreshToken();
    try {
      if (refresh != null) {
        await _api.post('/auth/logout/', data: {'refresh': refresh});
      }
    } catch (_) {
      // best-effort
    }
    await AppStorage.instance.clearTokens();
    await AppStorage.instance.clearUserCache();
  }

  /// POST /auth/push-token/
  Future<void> registerPushToken(
      {required String token, required String platform}) async {
    try {
      await _api.post('/auth/push-token/', data: {
        'token': token,
        'platform': platform,
      });
    } catch (_) {
      // non-critical
    }
  }
}
