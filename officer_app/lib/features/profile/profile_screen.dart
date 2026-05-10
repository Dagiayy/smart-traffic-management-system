import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/shared_widgets.dart';
import '../auth/data/auth_providers.dart';
import 'personal_info_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Profile')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          // Officer card
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF163A6E)]),
              borderRadius: AppRadius.radiusLg,
            ),
            child: Row(children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.white.withValues(alpha: 0.2),
                child: Text(user?.initials ?? '?', style: AppTypography.h1.copyWith(color: AppColors.white)),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user?.fullName ?? 'Officer', style: AppTypography.h2.copyWith(color: AppColors.white)),
                if (user?.badgeNumber != null) Text('Badge: ${user!.badgeNumber}',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.white.withValues(alpha: 0.8))),
                Text(user?.role.value ?? '', style: AppTypography.labelSmall.copyWith(color: AppColors.white.withValues(alpha: 0.7))),
                if (user?.assignedZone != null) Text('Zone: ${user!.assignedZone}',
                    style: AppTypography.caption.copyWith(color: AppColors.white.withValues(alpha: 0.7))),
              ])),
              const Icon(Icons.local_police_outlined, color: AppColors.white, size: 32),
            ]),
          ),
          const SizedBox(height: AppSpacing.lg),

          _Section('Account'),
          _MenuTile(icon: Icons.person_outline,            label: 'Personal Information', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalInfoScreen()))),
          _MenuTile(icon: Icons.bar_chart_outlined,        label: 'My Performance',       onTap: () => context.push('/performance')),
          _MenuTile(icon: Icons.receipt_long_outlined,     label: 'My Tickets',           onTap: () => context.push('/tickets')),

          if (user?.isSupervisor == true) ...[
            const SizedBox(height: AppSpacing.sm),
            _Section('Supervisor'),
            _MenuTile(icon: Icons.supervisor_account_outlined, label: 'Supervisor View', onTap: () => context.push('/supervisor')),
          ],

          const SizedBox(height: AppSpacing.sm),
          _Section('Settings'),
          _MenuTile(icon: Icons.settings_outlined,      label: 'Settings',      onTap: () => context.push('/settings')),
          _MenuTile(icon: Icons.notifications_outlined, label: 'Notifications', onTap: () => context.push('/notifications')),

          const SizedBox(height: AppSpacing.sm),
          _Section('Support'),
          _MenuTile(icon: Icons.help_outline,        label: 'Help Center',           onTap: () {}),
          _MenuTile(icon: Icons.support_agent_outlined, label: 'Contact Admin',     onTap: () {}),

          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Sign Out',
            variant: AppButtonVariant.secondary,
            icon: Icons.logout_outlined,
            onPressed: () => _logout(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sign Out', style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (confirm != true) return;
    await ref.read(authControllerProvider.notifier).logout();
    if (context.mounted) context.go('/login');
  }
}

class _Section extends StatelessWidget {
  const _Section(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, top: AppSpacing.sm, bottom: AppSpacing.xs),
    child: Text(text.toUpperCase(),
        style: AppTypography.caption.copyWith(letterSpacing: 0.8, color: AppColors.textTertiary, fontWeight: FontWeight.w700)),
  );
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
    child: AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
      child: Row(children: [
        Icon(icon, color: AppColors.textSecondary, size: 20),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Text(label, style: AppTypography.bodyLarge)),
        const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 20),
      ]),
    ),
  );
}
