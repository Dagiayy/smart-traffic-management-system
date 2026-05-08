import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/auth_providers.dart';
import '../../features/auth/presentation/auth_screens.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/map/map_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/reports/performance_screen.dart';
import '../../features/reports/reports_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/supervisor/supervisor_screen.dart';
import '../../features/tickets/presentation/new_ticket_screen.dart';
import '../../features/tickets/presentation/sync_screen.dart';
import '../../features/tickets/presentation/ticket_detail_screen.dart';
import '../../features/tickets/presentation/tickets_list_screen.dart';

// Wrapper so main.dart can hold the router instance stably
class GoRouterConfig {
  final GoRouter router;
  const GoRouterConfig(this.router);
}

// ── Bottom nav shell ──────────────────────────────────────────────────────
class HomeShell extends StatelessWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});

  static const _tabs = ['/home', '/tickets', '/map', '/reports', '/profile'];

  int _indexFor(String loc) {
    final idx = _tabs.indexWhere((t) => loc.startsWith(t));
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final idx = _indexFor(location);
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                _NavItem(icon: Icons.dashboard_outlined,    activeIcon: Icons.dashboard,     label: 'Home',    selected: idx == 0, onTap: () => context.go('/home')),
                _NavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long,  label: 'Tickets', selected: idx == 1, onTap: () => context.go('/tickets')),
                _NavItem(icon: Icons.map_outlined,          activeIcon: Icons.map,           label: 'Map',     selected: idx == 2, onTap: () => context.go('/map')),
                _NavItem(icon: Icons.bar_chart_outlined,    activeIcon: Icons.bar_chart,     label: 'Reports', selected: idx == 3, onTap: () => context.go('/reports')),
                _NavItem(icon: Icons.person_outline,        activeIcon: Icons.person,        label: 'Profile', selected: idx == 4, onTap: () => context.go('/profile')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.activeIcon, required this.label, required this.selected, required this.onTap});
  final IconData icon, activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  static const _primary = Color(0xFF0D2B4E);

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(selected ? activeIcon : icon, size: 22,
              color: selected ? _primary : const Color(0xFF6B7280)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(
            fontSize: 10,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            color: selected ? _primary : const Color(0xFF6B7280),
          )),
        ],
      ),
    ),
  );
}

// ── Router builder ────────────────────────────────────────────────────────
class AppRouter {
  AppRouter._();

  static GoRouterConfig buildRouterConfig(WidgetRef ref) {
    late GoRouter router;
    router = GoRouter(
      initialLocation: '/splash',
      redirect: (ctx, state) {
        final auth = ref.read(authControllerProvider);
        final loc  = state.uri.path;
        const publicPaths = ['/splash', '/login', '/forgot-password', '/verify-otp', '/reset-password'];
        final isPublic = publicPaths.any((p) => loc.startsWith(p));
        if (auth is AuthAuthenticated && isPublic && loc != '/splash') return '/home';
        if (auth is AuthUnauthenticated && !isPublic) return '/login';
        return null;
      },
      routes: [
        // Auth screens
        GoRoute(path: '/splash',         builder: (_, __) => const SplashScreen()),
        GoRoute(path: '/login',          builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/forgot-password',builder: (_, __) => const ForgotPasswordScreen()),
        GoRoute(
          path: '/verify-otp',
          builder: (_, state) {
            final e = state.extra as Map<String, dynamic>? ?? {};
            return OtpScreen(identifier: e['identifier'] ?? '', purpose: e['purpose'] ?? 'reset');
          },
        ),
        GoRoute(
          path: '/reset-password',
          builder: (_, state) {
            final e = state.extra as Map<String, dynamic>? ?? {};
            return ResetPasswordScreen(identifier: e['identifier'] ?? '', otpToken: e['otp_token'] ?? '');
          },
        ),

        // Shell — bottom nav
        ShellRoute(
          builder: (ctx, state, child) => HomeShell(child: child),
          routes: [
            GoRoute(path: '/home',    builder: (_, __) => const DashboardScreen()),
            GoRoute(path: '/tickets', builder: (_, __) => const TicketsListScreen()),
            GoRoute(path: '/map',     builder: (_, __) => const MapScreen()),
            GoRoute(path: '/reports', builder: (_, __) => const ReportsScreen()),
            GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          ],
        ),

        // Full-screen flows (no bottom nav)
        GoRoute(path: '/new-ticket',    builder: (_, __) => const NewTicketScreen()),
        GoRoute(path: '/tickets/:id',   builder: (_, state) => TicketDetailScreen(id: state.pathParameters['id']!)),
        GoRoute(path: '/sync',          builder: (_, __) => const SyncScreen()),
        GoRoute(path: '/supervisor',    builder: (_, __) => const SupervisorScreen()),
        GoRoute(path: '/performance',   builder: (_, __) => const PerformanceScreen()),
        GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
        GoRoute(path: '/settings',      builder: (_, __) => const SettingsScreen()),
      ],
      errorBuilder: (ctx, state) => Scaffold(
        appBar: AppBar(title: const Text('Not Found')),
        body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline, size: 48, color: Color(0xFF9CA3AF)),
          const SizedBox(height: 16),
          Text('Route not found: ${state.uri.path}'),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () => ctx.go('/home'), child: const Text('Go Home')),
        ])),
      ),
    );
    return GoRouterConfig(router);
  }
}
