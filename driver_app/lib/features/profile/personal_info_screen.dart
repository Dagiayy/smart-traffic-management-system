import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_text_field.dart';
import '../auth/data/auth_providers.dart';

class PersonalInfoScreen extends ConsumerStatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  ConsumerState<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends ConsumerState<PersonalInfoScreen> {
  bool _editing = false;
  bool _saving = false;
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _nameCtrl.text = user?.fullName ?? '';
    _emailCtrl.text = user?.email ?? '';
    _phoneCtrl.text = user?.phoneNumber ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Personal Information'),
        actions: [
          if (!_editing)
            TextButton(
              onPressed: () => setState(() => _editing = true),
              child: const Text('Edit'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          // Profile picture section
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.primarySurface,
                  child: Text(user?.initials ?? '?',
                      style: AppTypography.h1.copyWith(color: AppColors.primary)),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (_editing)
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.camera_alt_outlined, size: 16),
                    label: const Text('Change Photo'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            elevated: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Personal Details', style: AppTypography.h3),
                const Divider(height: AppSpacing.lg),
                if (_editing) ...[
                  AppTextField(
                    controller: _nameCtrl,
                    label: 'Full Name',
                    prefixIcon: Icons.person_outline,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _emailCtrl,
                    label: 'Email Address',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _phoneCtrl,
                    label: 'Phone Number',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                ] else ...[
                  _InfoRow(Icons.person_outline, 'Full Name',
                      user?.fullName ?? '-'),
                  _InfoRow(Icons.email_outlined, 'Email', user?.email ?? '-'),
                  _InfoRow(Icons.phone_outlined, 'Phone',
                      user?.phoneNumber ?? '-'),
                  _InfoRow(Icons.badge_outlined, 'National ID',
                      user?.nationalId ?? '-'),
                  _InfoRow(
                    Icons.calendar_today_outlined,
                    'Member Since',
                    user?.createdAt != null
                        ? '${user!.createdAt!.day}/${user.createdAt!.month}/${user.createdAt!.year}'
                        : '-',
                  ),
                ],
              ],
            ),
          ),
          if (_editing) ...[
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Save Changes',
              loading: _saving,
              onPressed: _saving ? null : _save,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Cancel',
              variant: AppButtonVariant.secondary,
              onPressed: () {
                final user = ref.read(currentUserProvider);
                _nameCtrl.text = user?.fullName ?? '';
                _emailCtrl.text = user?.email ?? '';
                _phoneCtrl.text = user?.phoneNumber ?? '';
                setState(() => _editing = false);
              },
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(authRepositoryProvider).updateProfile({
        'full_name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone_number': _phoneCtrl.text.trim(),
      });
      await ref.read(authControllerProvider.notifier).refreshUser();
      if (mounted) {
        setState(() => _editing = false);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Update failed: ${e.toString()}'),
            backgroundColor: AppColors.danger));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.label, this.value);
  final IconData icon;
  final String label, value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
              width: 100, child: Text(label, style: AppTypography.labelSmall)),
          Expanded(child: Text(value, style: AppTypography.bodyMedium)),
        ]),
      );
}
