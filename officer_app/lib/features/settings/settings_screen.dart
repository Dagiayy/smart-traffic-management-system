import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/services/auto_sync_service.dart';
import '../../core/storage/app_storage.dart';
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
  bool _syncAlerts       = true;
  bool _supervisorAlerts = true;
  bool _systemUpdates    = true;
  bool _policyUpdates    = true;
  bool _highPriority     = true;

  // Security
  bool _biometric        = false;
  bool _autoLock         = true;

  // General
  bool _autoSync         = true;
  String _language       = 'English';

  // Loading notif prefs from backend
  bool _loadingNotifPrefs = false;

  @override
  void initState() {
    super.initState();
    _language       = AppStorage.instance.getLanguage();
    _autoSync       = AppStorage.instance.getAutoSync();
    _biometric      = AppStorage.instance.getBiometric();
    _autoLock       = AppStorage.instance.getAutoLock();
    _syncAlerts     = AppStorage.instance.getNotif(AppConstants.kNotifSync);
    _supervisorAlerts = AppStorage.instance.getNotif(AppConstants.kNotifSupervisor);
    _systemUpdates  = AppStorage.instance.getNotif(AppConstants.kNotifSystem);
    _policyUpdates  = AppStorage.instance.getNotif(AppConstants.kNotifPolicy);
    _highPriority   = AppStorage.instance.getNotif(AppConstants.kNotifHighPriority);

    // Load notif prefs from backend
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadNotifPrefsFromBackend());
  }

  Future<void> _loadNotifPrefsFromBackend() async {
    if (!mounted) return;
    setState(() => _loadingNotifPrefs = true);
    try {
      final res = await ref.read(apiClientProvider).get('/officer/profile/');
      final data = res.data as Map<String, dynamic>? ?? {};
      final prefs = data['notification_preferences'] as Map<String, dynamic>? ?? {};
      if (prefs.isNotEmpty && mounted) {
        setState(() {
          _syncAlerts       = prefs['sync_alerts']       as bool? ?? _syncAlerts;
          _supervisorAlerts = prefs['supervisor_alerts'] as bool? ?? _supervisorAlerts;
          _systemUpdates    = prefs['system_updates']    as bool? ?? _systemUpdates;
          _policyUpdates    = prefs['policy_updates']    as bool? ?? _policyUpdates;
          _highPriority     = prefs['high_priority']     as bool? ?? _highPriority;
        });
      }
    } catch (_) {
      // Silently fall back to local prefs
    } finally {
      if (mounted) setState(() => _loadingNotifPrefs = false);
    }
  }

  Future<void> _saveNotifPrefs() async {
    // Save locally
    await AppStorage.instance.setNotif(AppConstants.kNotifSync, _syncAlerts);
    await AppStorage.instance.setNotif(AppConstants.kNotifSupervisor, _supervisorAlerts);
    await AppStorage.instance.setNotif(AppConstants.kNotifSystem, _systemUpdates);
    await AppStorage.instance.setNotif(AppConstants.kNotifPolicy, _policyUpdates);
    await AppStorage.instance.setNotif(AppConstants.kNotifHighPriority, _highPriority);
    // Sync to backend (fire and forget)
    try {
      await ref.read(apiClientProvider).patch('/officer/profile/', data: {
        'notification_preferences': {
          'sync_alerts':       _syncAlerts,
          'supervisor_alerts': _supervisorAlerts,
          'system_updates':    _systemUpdates,
          'policy_updates':    _policyUpdates,
          'high_priority':     _highPriority,
        },
      });
    } catch (_) {}
  }

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
            onTap: () => _showInfoDialog(context, 'App Theme',
                "Only 'Professional Light' theme is available in this version."),
          ),
          _MenuTile(
            icon: Icons.text_fields_outlined,
            label: 'Display Density',
            trailing: Text('Comfortable', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
            onTap: () => _showInfoDialog(context, 'Display Density',
                'Display density adjustments coming in a future update.'),
          ),
          _ToggleTile(
            icon: Icons.sync_outlined,
            label: 'Auto-Sync',
            subtitle: 'Automatically sync offline records',
            value: _autoSync,
            onChanged: (v) {
              setState(() => _autoSync = v);
              AppStorage.instance.setAutoSync(v);
              AutoSyncService.instance.enabled = v;
            },
          ),

          // ── Security ───────────────────────────────────────────────────
          const SizedBox(height: AppSpacing.sm),
          _SectionHeader('SECURITY'),
          _MenuTile(
            icon: Icons.lock_outline,
            label: 'Change Password',
            onTap: () => _startOtpPasswordChange(context),
          ),
          _MenuTile(
            icon: Icons.devices_outlined,
            label: 'Session Management',
            onTap: () => _showSessionInfo(context, user),
          ),
          _ToggleTile(
            icon: Icons.fingerprint_outlined,
            label: 'Biometric Login',
            subtitle: 'Use fingerprint or face ID',
            value: _biometric,
            onChanged: (v) {
              setState(() => _biometric = v);
              AppStorage.instance.setBiometric(v);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Biometric login configured.')));
            },
          ),
          _ToggleTile(
            icon: Icons.timer_outlined,
            label: 'Auto-Lock Session',
            subtitle: 'Lock after 15 min of inactivity',
            value: _autoLock,
            onChanged: (v) {
              setState(() => _autoLock = v);
              AppStorage.instance.setAutoLock(v);
            },
          ),

          // ── Notifications ─────────────────────────────────────────────
          const SizedBox(height: AppSpacing.sm),
          _SectionHeader('NOTIFICATIONS'),
          _ToggleTile(
            icon: Icons.sync_problem_outlined,
            label: 'Sync Alerts',
            subtitle: 'Alerts when records fail to sync',
            value: _syncAlerts,
            onChanged: (v) { setState(() => _syncAlerts = v); _saveNotifPrefs(); },
          ),
          _ToggleTile(
            icon: Icons.supervisor_account_outlined,
            label: 'Supervisor Alerts',
            subtitle: 'Feedback and review notifications',
            value: _supervisorAlerts,
            onChanged: (v) { setState(() => _supervisorAlerts = v); _saveNotifPrefs(); },
          ),
          _ToggleTile(
            icon: Icons.system_update_outlined,
            label: 'System Updates',
            subtitle: 'App and system change announcements',
            value: _systemUpdates,
            onChanged: (v) { setState(() => _systemUpdates = v); _saveNotifPrefs(); },
          ),
          _ToggleTile(
            icon: Icons.policy_outlined,
            label: 'Policy Updates',
            subtitle: 'Fine rule and regulation changes',
            value: _policyUpdates,
            onChanged: (v) { setState(() => _policyUpdates = v); _saveNotifPrefs(); },
          ),
          _ToggleTile(
            icon: Icons.priority_high_outlined,
            label: 'High-Priority Enforcement Alerts',
            subtitle: 'Hotspot and zone alerts from command',
            value: _highPriority,
            onChanged: (v) { setState(() => _highPriority = v); _saveNotifPrefs(); },
          ),

          // ── Support ───────────────────────────────────────────────────
          const SizedBox(height: AppSpacing.sm),
          _SectionHeader('SUPPORT'),
          _MenuTile(
            icon: Icons.help_outline,
            label: 'Help Center',
            onTap: () => _showHelpSheet(context),
          ),
          _MenuTile(
            icon: Icons.support_agent_outlined,
            label: 'Contact Administrator',
            onTap: () => _showContactDialog(context),
          ),
          _MenuTile(
            icon: Icons.engineering_outlined,
            label: 'Technical Support',
            onTap: () => _showContactDialog(context),
          ),
          _MenuTile(
            icon: Icons.quiz_outlined,
            label: 'FAQ',
            onTap: () => _showHelpSheet(context),
          ),

          // ── Legal & Policy ────────────────────────────────────────────
          const SizedBox(height: AppSpacing.sm),
          _SectionHeader('LEGAL & POLICY'),
          _MenuTile(icon: Icons.gavel_outlined,       label: 'Internal Policy Guidelines',  onTap: () => _showLegalDialog(context, 'Internal Policy Guidelines')),
          _MenuTile(icon: Icons.verified_outlined,    label: 'Enforcement Procedures',      onTap: () => _showLegalDialog(context, 'Enforcement Procedures')),
          _MenuTile(icon: Icons.privacy_tip_outlined, label: 'Legal Compliance Notes',      onTap: () => _showLegalDialog(context, 'Legal Compliance Notes')),
          _MenuTile(icon: Icons.article_outlined,     label: 'Terms of Service',            onTap: () => _showLegalDialog(context, 'Terms of Service')),

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

  Future<void> _startOtpPasswordChange(BuildContext context) async {
    final user = ref.read(currentUserProvider);
    final identifier = user?.email ?? user?.phoneNumber ?? '';
    if (identifier.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No registered email or phone found.')));
      return;
    }
    try {
      await ref.read(authRepositoryProvider)
          .sendOtp(identifier: identifier, purpose: 'reset');
      if (mounted) {
        context.push('/verify-otp',
            extra: {'identifier': identifier, 'purpose': 'reset'});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to send OTP: $e')));
      }
    }
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
            ...['English', 'Amharic (አማርኛ)', 'Oromiffa', 'Tigrinya', 'Somali']
                .map((l) => ListTile(
                  title: Text(l, style: AppTypography.bodyLarge),
                  leading: const Icon(Icons.language_outlined),
                  trailing: l == _language
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    setState(() => _language = l);
                    AppStorage.instance.setLanguage(l);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                            'Language changed. Restart the app to apply.')));
                  },
                )),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  void _showSessionInfo(BuildContext context, dynamic user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Active Session'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (user?.badgeNumber != null) ...[
            Text('Badge: ${user!.badgeNumber}', style: AppTypography.bodyMedium),
            const SizedBox(height: 6),
          ],
          if (user?.email != null) ...[
            Text('Email: ${user!.email}', style: AppTypography.bodySmall),
            const SizedBox(height: 6),
          ],
          Text('Sessions are auto-cleared on logout.', style: AppTypography.caption),
          const SizedBox(height: 4),
          Text('Keep your credentials secure and do not share your account.',
              style: AppTypography.caption),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message, style: AppTypography.bodyMedium),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  void _showLegalDialog(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(
          'This policy document is maintained by the Traffic Police Department. '
          'Contact admin for the full document.',
          style: AppTypography.bodyMedium,
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Contact Administrator'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.email_outlined, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            const Expanded(child: Text('traffic.admin@system.gov.et',
                style: TextStyle(fontSize: 13))),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.phone_outlined, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('Hotline: +251 115 123456',
                style: TextStyle(fontSize: 13)),
          ]),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  void _showHelpSheet(BuildContext context) {
    const faqs = [
      ('How do I sync offline tickets?',
       'Tickets sync automatically when internet is available.'),
      ('How do I add evidence?',
       'Open a ticket, tap the camera icon to capture photos.'),
      ('What if sync keeps failing?',
       'Check your internet connection and contact your supervisor.'),
    ];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Help Center', style: AppTypography.h3),
            const SizedBox(height: AppSpacing.md),
            ...faqs.map((faq) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.help_outline,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(faq.$1,
                      style: AppTypography.labelMedium)),
                ]),
                Padding(
                  padding: const EdgeInsets.only(left: 26, top: 4),
                  child: Text(faq.$2, style: AppTypography.bodySmall),
                ),
              ]),
            )),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
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
        style: AppTypography.caption.copyWith(
            letterSpacing: 0.8,
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w700)),
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
      child: Row(children: [
        Icon(icon, color: AppColors.textSecondary, size: 20),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Text(label, style: AppTypography.bodyLarge)),
        if (trailing != null)
          Padding(padding: const EdgeInsets.only(right: 4), child: trailing!),
        const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 20),
      ]),
    ),
  );
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile(
      {required this.icon,
      required this.label,
      required this.value,
      required this.onChanged,
      this.subtitle});
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
