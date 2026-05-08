import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/app_storage.dart';
import '../../../shared/models/app_user.dart';
import 'auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider));
});

/// Auth state representing user session lifecycle.
sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthAuthenticated extends AuthState {
  final AppUser user;
  const AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {
  final String? message;
  const AuthUnauthenticated([this.message]);
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repo) : super(const AuthInitial());
  final AuthRepository _repo;

  /// Bootstrap: check stored tokens and validate session on app start.
Future<void> bootstrap() async {
  state = const AuthLoading();

  try {
    final token = await AppStorage.instance.getAccessToken();

    // No saved login → go to onboarding/login
    if (token == null || token.isEmpty) {
      state = const AuthUnauthenticated();
      return;
    }

    // Use only cached user for now
    final cached = AppUser.decode(
      AppStorage.instance.getUserCache(),
    );

    if (cached != null) {
      state = AuthAuthenticated(cached);
    } else {
      state = const AuthUnauthenticated();
    }

    // BACKEND NOT READY YET
    // final fresh = await _repo.getMe();
    // state = AuthAuthenticated(fresh);

  } catch (e) {
    print("BOOTSTRAP ERROR: $e");
    state = const AuthUnauthenticated();
  }
}

  Future<void> login(
      {required String phoneOrEmail,
      required String password,
      bool rememberMe = false}) async {
    state = const AuthLoading();
    try {
      await AppStorage.instance.setRememberMe(rememberMe);
      final user = await _repo.login(
          phoneOrEmail: phoneOrEmail, password: password);
      state = AuthAuthenticated(user);
    } catch (e) {
      state = AuthUnauthenticated(e.toString());
      rethrow;
    }
  }

  Future<void> register({
    required String fullName,
    required String nationalId,
    required String phone,
    required String email,
    required String password,
    List<Map<String, dynamic>> vehicles = const [],
  }) async {
    state = const AuthLoading();
    try {
      final user = await _repo.register(
        fullName: fullName,
        nationalId: nationalId,
        phone: phone,
        email: email,
        password: password,
        vehicles: vehicles,
      );
      state = AuthAuthenticated(user);
    } catch (e) {
      state = AuthUnauthenticated(e.toString());
      rethrow;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthUnauthenticated();
  }

  /// Triggered by interceptor when refresh token also fails.
  void forceLogout() {
    AppStorage.instance.clearTokens();
    AppStorage.instance.clearUserCache();
    state = const AuthUnauthenticated('Session expired. Please sign in again.');
  }

  /// Update local user state after profile edit.
  void updateUser(AppUser user) {
    state = AuthAuthenticated(user);
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

/// Convenience: current user (null if not authenticated)
final currentUserProvider = Provider<AppUser?>((ref) {
  final state = ref.watch(authControllerProvider);
  return state is AuthAuthenticated ? state.user : null;
});
