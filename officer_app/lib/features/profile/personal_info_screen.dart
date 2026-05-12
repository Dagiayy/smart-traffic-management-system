import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/shared_widgets.dart';
import '../auth/data/auth_providers.dart';

class PersonalInfoScreen extends ConsumerStatefulWidget {
  const PersonalInfoScreen({super.key});
  @override
  ConsumerState<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends ConsumerState<PersonalInfoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  @override
  void initState() { super.initState(); _tab = TabController(length: 2, vsync: this); }
  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Personal Information'),
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.white.withValues(alpha: 0.6),
          indicatorColor: AppColors.white,
          tabs: const [Tab(text: 'My Info'), Tab(text: 'Change Password')],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [_ProfileTab(), _PasswordTab()],
      ),
    );
  }
}

// ── Profile Info Tab ──────────────────────────────────────────────────────
class _ProfileTab extends ConsumerStatefulWidget {
  const _ProfileTab();
  @override
  ConsumerState<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<_ProfileTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _saving = false;
  bool _loaded = false;

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose(); _emailCtrl.dispose();
    super.dispose();
  }

  void _loadUser() {
    if (_loaded) return;
    final user = ref.read(currentUserProvider);
    if (user != null) {
      _nameCtrl.text  = user.fullName;
      _phoneCtrl.text = user.phoneNumber ?? '';
      _emailCtrl.text = user.email ?? '';
      _loaded = true;
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.patch('/officer/profile/', data: {
        'full_name': _nameCtrl.text.trim(),
        'phone_number': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
      });
      await ref.read(authControllerProvider.notifier).refreshUser();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _loadUser();
    final user = ref.watch(currentUserProvider);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        // Avatar
        Center(
          child: CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: Text(user?.initials ?? '?',
                style: AppTypography.h1.copyWith(color: AppColors.primary)),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Read-only info
        AppCard(
          color: AppColors.primarySurface,
          child: Column(children: [
            if (user?.badgeNumber != null)
              _InfoRow(Icons.badge_outlined, 'Badge Number', user!.badgeNumber!),
            _InfoRow(Icons.person_outline, 'Role', user?.role.value ?? ''),
            if (user?.assignedZone != null)
              _InfoRow(Icons.location_city_outlined, 'Zone', user!.assignedZone!),
          ]),
        ),
        const SizedBox(height: AppSpacing.lg),

        Form(
          key: _formKey,
          child: Column(children: [
            AppTextField(
              controller: _nameCtrl,
              label: 'Full Name',
              prefixIcon: Icons.person_outline,
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _phoneCtrl,
              label: 'Phone Number',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _emailCtrl,
              label: 'Email',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
            ),
          ]),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: 'Save Changes',
          icon: Icons.save_outlined,
          loading: _saving,
          onPressed: _saving ? null : _save,
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.label, this.value);
  final IconData icon;
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
    child: Row(children: [
      Icon(icon, size: 16, color: AppColors.primary),
      const SizedBox(width: 8),
      Text('$label: ', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
      Expanded(child: Text(value, style: AppTypography.bodyMedium.copyWith(color: AppColors.primary),
          overflow: TextOverflow.ellipsis)),
    ]),
  );
}

// ── Change Password Tab ───────────────────────────────────────────────────
class _PasswordTab extends ConsumerStatefulWidget {
  const _PasswordTab();
  @override
  ConsumerState<_PasswordTab> createState() => _PasswordTabState();
}

class _PasswordTabState extends ConsumerState<_PasswordTab> {
  final _formKey  = GlobalKey<FormState>();
  final _oldCtrl  = TextEditingController();
  final _newCtrl  = TextEditingController();
  final _confCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() { _oldCtrl.dispose(); _newCtrl.dispose(); _confCtrl.dispose(); super.dispose(); }

  Future<void> _changePassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await ref.read(apiClientProvider).patch('/officer/profile/', data: {
        'old_password': _oldCtrl.text,
        'new_password': _newCtrl.text,
      });
      _oldCtrl.clear(); _newCtrl.clear(); _confCtrl.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        AppCard(
          color: AppColors.infoSurface,
          child: Row(children: [
            const Icon(Icons.info_outline, color: AppColors.info, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text('Use a strong password with at least 8 characters.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.infoText))),
          ]),
        ),
        const SizedBox(height: AppSpacing.lg),
        Form(
          key: _formKey,
          child: Column(children: [
            AppTextField(
              controller: _oldCtrl,
              label: 'Current Password',
              prefixIcon: Icons.lock_outline,
              obscure: true,
              canToggle: true,
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _newCtrl,
              label: 'New Password',
              prefixIcon: Icons.lock_reset_outlined,
              obscure: true,
              canToggle: true,
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || v.length < 8) ? 'Min 8 characters' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _confCtrl,
              label: 'Confirm New Password',
              prefixIcon: Icons.lock_reset_outlined,
              obscure: true,
              canToggle: true,
              textInputAction: TextInputAction.done,
              validator: (v) => v != _newCtrl.text ? 'Passwords do not match' : null,
            ),
          ]),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: 'Change Password',
          icon: Icons.lock_reset_outlined,
          loading: _saving,
          onPressed: _saving ? null : _changePassword,
        ),
      ],
    );
  }
}
