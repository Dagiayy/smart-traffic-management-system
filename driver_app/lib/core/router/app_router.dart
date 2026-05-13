import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/alerts/alerts_screen.dart';
import '../../features/auth/presentation/email_verification_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/otp_verification_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/reset_password_screen.dart';
import '../../features/disputes/disputes_screen.dart';
import '../../features/home_shell.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/payments/payments_screen.dart';
import '../../features/profile/personal_info_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/violations/violation_detail_screen.dart';
import '../../features/violations/violations_screen.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),

      // -------- Auth --------
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/verify-otp',
        builder: (ctx, state) {
          final extra = (state.extra as Map?) ?? const {};
          return OtpVerificationScreen(
            identifier: extra['identifier']?.toString() ?? '',
            purpose: extra['purpose']?.toString() ?? 'verify',
          );
        },
      ),
      GoRoute(
        path: '/verify-email',
        builder: (_, state) {
          final e = state.extra as Map<String, dynamic>? ?? {};
          return EmailVerificationScreen(email: e['email'] ?? '');
        },
      ),
      GoRoute(
        path: '/reset-password',
        builder: (ctx, state) {
          final extra = (state.extra as Map?) ?? const {};
          return ResetPasswordScreen(
            identifier: extra['identifier']?.toString() ?? '',
            otpToken: extra['otp_token']?.toString() ?? '',
          );
        },
      ),

      // -------- Main app shell --------
      GoRoute(
        path: '/home',
        builder: (_, __) => const HomeShell(),
      ),

      // -------- Direct routes (also reachable from quick actions) --------
      GoRoute(
        path: '/violations/:id',
        builder: (ctx, state) =>
            ViolationDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/violations',
        builder: (_, __) => const ViolationsScreen(),
      ),
      GoRoute(
        path: '/payments',
        builder: (_, __) => const PaymentsScreen(),
      ),
      GoRoute(
        path: '/disputes',
        builder: (_, __) => const DisputesScreen(),
      ),
      GoRoute(
        path: '/alerts',
        builder: (_, __) => const AlertsScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (_, __) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/profile/personal-info',
        builder: (_, __) => const PersonalInfoScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (_, __) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (ctx, state) => Scaffold(
      appBar: AppBar(),
      body: Center(child: Text('Route not found: ${state.uri}')),
    ),
  );
}
