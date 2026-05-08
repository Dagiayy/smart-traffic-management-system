import '../../../core/network/api_client.dart';
import '../../../core/storage/app_storage.dart';
import '../../../shared/models/app_user.dart';

class AuthRepository {
  AuthRepository(this._api);
  final ApiClient _api;

  /// POST /auth/login/ — same endpoint shared by all roles
  Future<AppUser> login({required String officerIdOrEmail, required String password}) async {
    final res = await _api.post('/auth/login/', data: {
      'phone_or_email': officerIdOrEmail,
      'password': password,
    });
    final data = res.data as Map<String, dynamic>;
    await AppStorage.instance.saveTokens(access: data['access'], refresh: data['refresh']);
    final user = AppUser.fromJson(data['user']);
    await AppStorage.instance.saveUserCache(user.encoded);
    return user;
  }

  Future<AppUser> getMe() async {
    final res = await _api.get('/auth/me/');
    final user = AppUser.fromJson(res.data as Map<String, dynamic>);
    await AppStorage.instance.saveUserCache(user.encoded);
    return user;
  }

  Future<void> sendOtp({required String identifier, required String purpose}) async {
    await _api.post('/auth/otp/send/', data: {'phone_or_email': identifier, 'purpose': purpose});
  }

  Future<String?> verifyOtp({required String identifier, required String code}) async {
    final res = await _api.post('/auth/otp/verify/', data: {'phone_or_email': identifier, 'code': code});
    return (res.data as Map<String, dynamic>)['otp_token'] as String?;
  }

  Future<void> resetPassword({required String identifier, required String newPassword, required String otpToken}) async {
    await _api.post('/auth/password/reset/', data: {
      'phone_or_email': identifier, 'new_password': newPassword, 'otp_token': otpToken,
    });
  }

  Future<void> logout() async {
    final refresh = await AppStorage.instance.getRefreshToken();
    try { if (refresh != null) await _api.post('/auth/logout/', data: {'refresh': refresh}); } catch (_) {}
    await AppStorage.instance.clearTokens();
    await AppStorage.instance.clearUserCache();
  }
}
