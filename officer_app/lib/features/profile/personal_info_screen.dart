import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
          tabs: const [Tab(text: 'My Info'), Tab(text: 'Security')],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [_MyInfoTab(), _SecurityTab()],
      ),
    );
  }
}

// ── My Info Tab (View + Request Edit) ────────────────────────────────────
class _MyInfoTab extends ConsumerWidget {
  const _MyInfoTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

        // Read-only info tiles
        AppCard(
          elevated: true,
          child: Column(
            children: [
              _InfoTile(Icons.person_outline, 'Full Name', user?.fullName ?? '—'),
              _InfoTile(Icons.email_outlined, 'Email', user?.email ?? '—'),
              _InfoTile(Icons.phone_outlined, 'Phone Number', user?.phoneNumber ?? '—'),
              _InfoTile(Icons.badge_outlined, 'Badge Number', user?.badgeNumber ?? '—'),
              _InfoTile(Icons.security_outlined, 'Role', user?.role.value ?? '—'),
              _InfoTile(Icons.location_city_outlined, 'Assigned Zone', user?.assignedZone ?? '—'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        AppCard(
          color: AppColors.infoSurface,
          child: Row(children: [
            const Icon(Icons.info_outline, color: AppColors.info, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(
              'To change your profile information, submit a request for admin review.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.infoText),
            )),
          ]),
        ),
        const SizedBox(height: AppSpacing.md),

        AppButton(
          label: 'Request Information Change',
          icon: Icons.edit_note_outlined,
          variant: AppButtonVariant.secondary,
          onPressed: () => _showEditRequestSheet(context, ref),
        ),
      ],
    );
  }

  void _showEditRequestSheet(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    String? selectedField;
    final valueCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    bool submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg, right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Request Profile Edit', style: AppTypography.h3),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Field to Change',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  value: selectedField,
                  items: const [
                    DropdownMenuItem(value: 'full_name',    child: Text('Full Name')),
                    DropdownMenuItem(value: 'email',        child: Text('Email Address')),
                    DropdownMenuItem(value: 'phone_number', child: Text('Phone Number')),
                  ],
                  onChanged: (v) => setModalState(() => selectedField = v),
                  validator: (v) => v == null ? 'Please select a field' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: valueCtrl,
                  decoration: const InputDecoration(
                    labelText: 'New Value',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: reasonCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Reason / Note',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  maxLines: 3,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: 'Submit Request',
                    icon: Icons.send_outlined,
                    loading: submitting,
                    onPressed: submitting ? null : () async {
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      setModalState(() => submitting = true);
                      try {
                        await ref.read(apiClientProvider).post(
                          '/officer/profile/edit-request/',
                          data: {
                            'field_name': selectedField,
                            'requested_value': valueCtrl.text.trim(),
                            'reason': reasonCtrl.text.trim(),
                          },
                        );
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text('Request submitted. Admin will review.')));
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          setModalState(() => submitting = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed: $e')));
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile(this.icon, this.label, this.value);
  final IconData icon;
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Row(children: [
      Icon(icon, size: 18, color: AppColors.primary),
      const SizedBox(width: AppSpacing.sm),
      SizedBox(
        width: 110,
        child: Text('$label:', style: AppTypography.labelSmall
            .copyWith(color: AppColors.textSecondary)),
      ),
      Expanded(child: Text(value, style: AppTypography.bodyMedium,
          overflow: TextOverflow.ellipsis)),
    ]),
  );
}

// ── Security Tab ──────────────────────────────────────────────────────────
class _SecurityTab extends ConsumerStatefulWidget {
  const _SecurityTab();
  @override
  ConsumerState<_SecurityTab> createState() => _SecurityTabState();
}

class _SecurityTabState extends ConsumerState<_SecurityTab> {
  bool _sending = false;

  Future<void> _startOtpPasswordChange() async {
    final user = ref.read(currentUserProvider);
    final identifier = user?.email ?? user?.phoneNumber ?? '';
    if (identifier.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No registered email or phone found for your account.')));
      return;
    }
    setState(() => _sending = true);
    try {
      await ref.read(authRepositoryProvider).sendOtp(
          identifier: identifier, purpose: 'reset');
      if (mounted) {
        context.push('/verify-otp',
            extra: {'identifier': identifier, 'purpose': 'reset'});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to send OTP: $e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        // Info card
        AppCard(
          color: AppColors.infoSurface,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.security_outlined, color: AppColors.info, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(
              'For security, password changes require identity verification via OTP '
              'sent to your registered contact.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.infoText),
            )),
          ]),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Password security tile
        AppCard(
          elevated: true,
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.lock_outline, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Password', style: AppTypography.labelLarge),
              Text('Password security is managed by your administrator',
                  style: AppTypography.bodySmall),
            ])),
          ]),
        ),
        const SizedBox(height: AppSpacing.md),

        AppButton(
          label: 'Change Password via OTP',
          icon: Icons.sms_outlined,
          loading: _sending,
          onPressed: _sending ? null : _startOtpPasswordChange,
        ),
        const SizedBox(height: AppSpacing.xl),

        // Contact admin fallback
        AppCard(
          color: AppColors.warningSurface,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.info_outline, color: AppColors.warning, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(
              'Contact your administrator to request a password reset if you '
              'cannot access your registered contact.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.warningText),
            )),
          ]),
        ),
      ],
    );
  }
}
