import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../auth/data/auth_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Profile', style: AppTypography.h2)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            // User card
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primarySurface,
                    child: Text(
                      user?.initials ?? '?',
                      style: AppTypography.h2
                          .copyWith(color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.fullName ?? 'Guest',
                            style: AppTypography.h3,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        if (user?.phoneNumber != null)
                          Text(user!.phoneNumber!,
                              style: AppTypography.bodySmall),
                        if (user?.email != null)
                          Text(user!.email!,
                              style: AppTypography.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            _SectionLabel('Account'),
            _MenuTile(
              icon: Icons.person_outline,
              label: 'Personal Information',
              onTap: () => context.push('/profile/personal-info'),
            ),
            _MenuTile(
              icon: Icons.directions_car_outlined,
              label: 'My Vehicles',
              onTap: () => context.push('/profile/vehicles'),
            ),
            _MenuTile(
              icon: Icons.lock_outline,
              label: 'Change Password',
              onTap: () => context.push('/verify-otp', extra: {
                'identifier': user?.email ?? user?.phoneNumber ?? '',
                'purpose': 'reset',
              }),
            ),

            const SizedBox(height: AppSpacing.md),
            _SectionLabel('Preferences'),
            _MenuTile(
              icon: Icons.notifications_none_outlined,
              label: 'Notifications',
              onTap: () => context.push('/notifications'),
            ),
            _MenuTile(
              icon: Icons.settings_outlined,
              label: 'Settings',
              onTap: () => context.push('/settings'),
            ),

            const SizedBox(height: AppSpacing.md),
            _SectionLabel('Support'),
            _MenuTile(
              icon: Icons.help_outline,
              label: 'Help Center',
              onTap: () => _showHelpDialog(context),
            ),
            _MenuTile(
              icon: Icons.privacy_tip_outlined,
              label: 'Privacy Policy',
              onTap: () => _showPrivacyDialog(context),
            ),

            const SizedBox(height: AppSpacing.xl),
            AppButton(
              variant: AppButtonVariant.secondary,
              icon: Icons.logout_outlined,
              label: 'Sign Out',
              onPressed: () => _confirmLogout(context, ref),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Help Center'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contact us for support:'),
            SizedBox(height: 12),
            Text('Phone: +251 11 551 7777'),
            Text('Email: support@trafficauthority.gov.et'),
            Text('Hours: Mon–Fri, 8:00 AM – 5:00 PM'),
            SizedBox(height: 12),
            Text('For emergencies, call 945 (Traffic Police).'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close')),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'The Integrated Traffic Management System collects and processes '
            'your personal data strictly for the purpose of traffic law enforcement '
            'and compliance monitoring.\n\n'
            'Your data is stored securely and is not shared with third parties '
            'except as required by law or with your explicit consent.\n\n'
            'You have the right to access, correct, or request deletion of your '
            'personal data at any time by contacting the Traffic Authority.\n\n'
            'For full policy details, visit trafficauthority.gov.et/privacy.',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Sign Out',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await ref.read(authControllerProvider.notifier).logout();
    if (context.mounted) context.go('/login');
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
          left: 4, top: AppSpacing.sm, bottom: AppSpacing.xs),
      child: Text(text.toUpperCase(),
          style: AppTypography.caption.copyWith(
              letterSpacing: 0.8, color: AppColors.textTertiary)),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(label, style: AppTypography.bodyLarge)),
            const Icon(Icons.chevron_right,
                color: AppColors.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }
}
