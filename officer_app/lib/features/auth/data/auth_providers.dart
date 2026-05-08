import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/app_storage.dart';
import '../../../shared/models/app_user.dart';
import 'auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) =>
    AuthRepository(ref.watch(apiClientProvider)));

sealed class AuthState { const AuthState(); }
class AuthInitial       extends AuthState { const AuthInitial(); }
class AuthLoading       extends AuthState { const AuthLoading(); }
class AuthAuthenticated extends AuthState { final AppUser user; const AuthAuthenticated(this.user); }
class AuthUnauthenticated extends AuthState { final String? message; const AuthUnauthenticated([this.message]); }

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repo) : super(const AuthInitial());
  final AuthRepository _repo;

  Future<void> bootstrap() async {
    state = const AuthLoading();
    try {
      final token = await AppStorage.instance.getAccessToken();
      if (token == null) { state = const AuthUnauthenticated(); return; }
      final cached = AppUser.decode(AppStorage.instance.getUserCache());
      if (cached != null) state = AuthAuthenticated(cached);
      final fresh = await _repo.getMe();
      state = AuthAuthenticated(fresh);
    } catch (_) {
      final cached = AppUser.decode(AppStorage.instance.getUserCache());
      state = cached != null ? AuthAuthenticated(cached) : const AuthUnauthenticated();
    }
  }

  Future<void> login({required String id, required String password, bool rememberMe = false}) async {
    state = const AuthLoading();
    try {
      await AppStorage.instance.setRememberMe(rememberMe);
      final user = await _repo.login(officerIdOrEmail: id, password: password);
      state = AuthAuthenticated(user);
    } catch (e) { state = AuthUnauthenticated(e.toString()); rethrow; }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthUnauthenticated();
  }

  void forceLogout() {
    AppStorage.instance.clearTokens();
    AppStorage.instance.clearUserCache();
    state = const AuthUnauthenticated('Session expired.');
  }

  void updateUser(AppUser u) => state = AuthAuthenticated(u);
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) =>
    AuthController(ref.watch(authRepositoryProvider)));

final currentUserProvider = Provider<AppUser?>((ref) {
  final s = ref.watch(authControllerProvider);
  return s is AuthAuthenticated ? s.user : null;
});
