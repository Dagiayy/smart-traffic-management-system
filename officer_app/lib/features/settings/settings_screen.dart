import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/shared_widgets.dart';
import '../auth/data/auth_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Notification preferences
  bool _syncAlerts      = true;
  bool _supervisorAlerts = true;
  bool _systemUpdates   = true;
  bool _policyUpdates   = true;
  bool _highPriority    = true;

  // Security
  bool _biometric       = false;
  bool _autoLock        = true;

  // Display
  String _language = 'English';

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          // ── General ───────────────────────────────────────────────────
          _SectionHeader('GENERAL'),
          _MenuTile(
            icon: Icons.language_outlined,
            label: 'Language',
            trailing: Text(_language, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
            onTap: () => _showLanguageSheet(context),
          ),
          _MenuTile(
            icon: Icons.palette_outlined,
            label: 'App Theme',
            trailing: Text('Professional Light', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
            onTap: () {},
          ),
          _MenuTile(
            icon: Icons.text_fields_outlined,
            label: 'Display Density',
            trailing: Text('Comfortable', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
            onTap: () {},
          ),
          _MenuTile(
            icon: Icons.sync_outlined,
            label: 'Auto-Sync',
            trailing: const StatusBadge(label: 'Enabled', type: BadgeType.success, compact: true),
            onTap: () {},
          ),

          // ── Security ───────────────────────────────────────────────────
          const SizedBox(height: AppSpacing.sm),
          _SectionHeader('SECURITY'),
          _MenuTile(
            icon: Icons.lock_outline,
            label: 'Change Password',
            onTap: () => context.push('/forgot-password'),
          ),
          _MenuTile(
            icon: Icons.devices_outlined,
            label: 'Session Management',
            onTap: () => _showSessionInfo(context),
          ),
          _ToggleTile(
            icon: Icons.fingerprint_outlined,
            label: 'Biometric Login',
            subtitle: 'Use fingerprint or face ID',
            value: _biometric,
            onChanged: (v) => setState(() => _biometric = v),
          ),
          _ToggleTile(
            icon: Icons.timer_outlined,
            label: 'Auto-Lock Session',
            subtitle: 'Lock after 15 min of inactivity',
            value: _autoLock,
            onChanged: (v) => setState(() => _autoLock = v),
          ),

          // ── Notifications ─────────────────────────────────────────────
          const SizedBox(height: AppSpacing.sm),
          _SectionHeader('NOTIFICATIONS'),
          _ToggleTile(
            icon: Icons.sync_problem_outlined,
            label: 'Sync Alerts',
            subtitle: 'Alerts when records fail to sync',
            value: _syncAlerts,
            onChanged: (v) => setState(() => _syncAlerts = v),
          ),
          _ToggleTile(
            icon: Icons.supervisor_account_outlined,
            label: 'Supervisor Alerts',
            subtitle: 'Feedback and review notifications',
            value: _supervisorAlerts,
            onChanged: (v) => setState(() => _supervisorAlerts = v),
          ),
          _ToggleTile(
            icon: Icons.system_update_outlined,
            label: 'System Updates',
            subtitle: 'App and system change announcements',
            value: _systemUpdates,
            onChanged: (v) => setState(() => _systemUpdates = v),
          ),
          _ToggleTile(
            icon: Icons.policy_outlined,
            label: 'Policy Updates',
            subtitle: 'Fine rule and regulation changes',
            value: _policyUpdates,
            onChanged: (v) => setState(() => _policyUpdates = v),
          ),
          _ToggleTile(
            icon: Icons.priority_high_outlined,
            label: 'High-Priority Enforcement Alerts',
            subtitle: 'Hotspot and zone alerts from command',
            value: _highPriority,
            onChanged: (v) => setState(() => _highPriority = v),
          ),

          // ── Support ───────────────────────────────────────────────────
          const SizedBox(height: AppSpacing.sm),
          _SectionHeader('SUPPORT'),
          _MenuTile(icon: Icons.help_outline,               label: 'Help Center',              onTap: () {}),
          _MenuTile(icon: Icons.support_agent_outlined,     label: 'Contact Administrator',    onTap: () {}),
          _MenuTile(icon: Icons.engineering_outlined,       label: 'Technical Support',        onTap: () {}),
          _MenuTile(icon: Icons.quiz_outlined,              label: 'FAQ',                      onTap: () {}),

          // ── Legal & Policy ────────────────────────────────────────────
          const SizedBox(height: AppSpacing.sm),
          _SectionHeader('LEGAL & POLICY'),
          _MenuTile(icon: Icons.gavel_outlined,             label: 'Internal Policy Guidelines',  onTap: () {}),
          _MenuTile(icon: Icons.verified_outlined,          label: 'Enforcement Procedures',      onTap: () {}),
          _MenuTile(icon: Icons.privacy_tip_outlined,       label: 'Legal Compliance Notes',      onTap: () {}),
          _MenuTile(icon: Icons.article_outlined,           label: 'Terms of Service',            onTap: () {}),

          const SizedBox(height: AppSpacing.xl),
          Center(child: Column(children: [
            Text('Traffic Police Field Enforcement System', style: AppTypography.labelMedium),
            const SizedBox(height: 4),
            Text('v1.0.0  •  Officer: ${user?.badgeNumber ?? user?.fullName ?? ''}',
                style: AppTypography.caption),
            const SizedBox(height: 4),
            Text('ITMS — Intelligent Traffic Management System',
                style: AppTypography.caption.copyWith(color: AppColors.primary)),
          ])),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  void _showLanguageSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Language', style: AppTypography.h3),
            const SizedBox(height: AppSpacing.md),
            ...['English', 'Amharic (አማርኛ)', 'Oromiffa', 'Tigrinya', 'Somali']
                .map((l) => ListTile(
                  title: Text(l, style: AppTypography.bodyLarge),
                  leading: const Icon(Icons.language_outlined),
                  trailing: l == _language ? const Icon(Icons.check, color: AppColors.primary) : null,
                  onTap: () { setState(() => _language = l); Navigator.pop(context); },
                )),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  void _showSessionInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Active Session'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Device: Android / iOS', style: AppTypography.bodyMedium),
          const SizedBox(height: 6),
          Text('Login: ${AppColors.primary}', style: AppTypography.bodySmall),
          const SizedBox(height: 6),
          Text('Sessions are auto-cleared on logout.', style: AppTypography.caption),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, top: AppSpacing.xs, bottom: AppSpacing.xs),
    child: Text(text,
        style: AppTypography.caption.copyWith(letterSpacing: 0.8, color: AppColors.textTertiary, fontWeight: FontWeight.w700)),
  );
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.label, required this.onTap, this.trailing});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
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
        if (trailing != null) Padding(padding: const EdgeInsets.only(right: 4), child: trailing!),
        const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 20),
      ]),
    ),
  );
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({required this.icon, required this.label, required this.value, required this.onChanged, this.subtitle});
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
    child: AppCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
      child: Row(children: [
        Icon(icon, color: AppColors.textSecondary, size: 20),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: AppTypography.bodyLarge),
          if (subtitle != null) Text(subtitle!, style: AppTypography.caption),
        ])),
        Switch(value: value, onChanged: onChanged, activeColor: AppColors.primary),
      ]),
    ),
  );
}
