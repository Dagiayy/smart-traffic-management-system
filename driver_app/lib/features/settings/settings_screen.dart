import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/app_card.dart';
import '../auth/data/auth_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _paymentReminders = true;
  bool _trafficAlerts = true;
  bool _violationUpdates = true;
  bool _biometric = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Settings', style: AppTypography.h2)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          // ── General ───────────────────────────────────────────────────
          _Section('General'),
          _MenuTile(
            icon: Icons.language_outlined,
            label: 'Language',
            trailing: const Text('English',
                style: TextStyle(color: AppColors.textSecondary)),
            onTap: () => _showLanguageSheet(context),
          ),
          _MenuTile(
            icon: Icons.palette_outlined,
            label: 'App Theme',
            trailing: const Text('Light',
                style: TextStyle(color: AppColors.textSecondary)),
            onTap: () {},
          ),
          _MenuTile(
            icon: Icons.text_fields_outlined,
            label: 'Font Size',
            trailing: const Text('Normal',
                style: TextStyle(color: AppColors.textSecondary)),
            onTap: () {},
          ),

          // ── Security ───────────────────────────────────────────────────
          _Section('Security'),
          _MenuTile(
            icon: Icons.lock_outline,
            label: 'Change Password',
            onTap: () => context.push('/forgot-password'),
          ),
          AppCard(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.fingerprint_outlined,
                    color: AppColors.textSecondary, size: 20),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                    child: Text('Biometric Login',
                        style: AppTypography.bodyLarge)),
                Switch(
                  value: _biometric,
                  onChanged: (v) => setState(() => _biometric = v),
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // ── Notifications ─────────────────────────────────────────────
          _Section('Notifications'),
          _ToggleTile(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Payment Reminders',
            value: _paymentReminders,
            onChanged: (v) => setState(() => _paymentReminders = v),
          ),
          _ToggleTile(
            icon: Icons.alt_route_outlined,
            label: 'Traffic Alerts',
            value: _trafficAlerts,
            onChanged: (v) => setState(() => _trafficAlerts = v),
          ),
          _ToggleTile(
            icon: Icons.report_outlined,
            label: 'Violation Updates',
            value: _violationUpdates,
            onChanged: (v) => setState(() => _violationUpdates = v),
          ),

          // ── Support ───────────────────────────────────────────────────
          _Section('Support'),
          _MenuTile(
            icon: Icons.help_outline,
            label: 'Help Center',
            onTap: () {},
          ),
          _MenuTile(
            icon: Icons.phone_outlined,
            label: 'Contact Traffic Authority',
            onTap: () {},
          ),
          _MenuTile(
            icon: Icons.quiz_outlined,
            label: 'FAQ',
            onTap: () {},
          ),
          _MenuTile(
            icon: Icons.bug_report_outlined,
            label: 'Report an Issue',
            onTap: () {},
          ),

          // ── Legal ─────────────────────────────────────────────────────
          _Section('Legal'),
          _MenuTile(
            icon: Icons.privacy_tip_outlined,
            label: 'Privacy Policy',
            onTap: () {},
          ),
          _MenuTile(
            icon: Icons.article_outlined,
            label: 'Terms of Service',
            onTap: () {},
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: Text('v1.0.0 — Citizen Traffic Compliance',
                style: AppTypography.caption),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  void _showLanguageSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Language', style: AppTypography.h3),
            const SizedBox(height: AppSpacing.md),
            ...['English', 'Amharic (አማርኛ)', 'Oromiffa', 'Somali']
                .map((l) => ListTile(
                      title: Text(l),
                      leading: const Icon(Icons.language_outlined),
                      trailing: l == 'English'
                          ? const Icon(Icons.check, color: AppColors.primary)
                          : null,
                      onTap: () => Navigator.pop(context),
                    )),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(
            left: 4, top: AppSpacing.md, bottom: AppSpacing.xs),
        child: Text(
          text.toUpperCase(),
          style: AppTypography.caption
              .copyWith(letterSpacing: 0.8, color: AppColors.textTertiary),
        ),
      );
}

class _MenuTile extends StatelessWidget {
  const _MenuTile(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.trailing});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
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
              if (trailing != null)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: trailing!,
                ),
              const Icon(Icons.chevron_right,
                  color: AppColors.textTertiary, size: 20),
            ],
          ),
        ),
      );
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile(
      {required this.icon,
      required this.label,
      required this.value,
      required this.onChanged});
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: AppCard(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: AppColors.textSecondary, size: 20),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(label, style: AppTypography.bodyLarge)),
              Switch(
                  value: value, onChanged: onChanged, activeColor: AppColors.primary),
            ],
          ),
        ),
      );
}
