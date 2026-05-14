import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/state_widgets.dart';
import '../auth/data/auth_providers.dart';

class PersonalInfoScreen extends ConsumerStatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  ConsumerState<PersonalInfoScreen> createState() =>
      _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends ConsumerState<PersonalInfoScreen> {
  bool _editing = false;
  bool _saving = false;
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _populate();
  }

  void _populate() {
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
      body: CustomScrollView(
        slivers: [
          // ── Branded App Bar ─────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            title: const Text('Personal Information'),
            actions: [
              if (!_editing && !_saving)
                TextButton.icon(
                  onPressed: () => setState(() => _editing = true),
                  icon: const Icon(Icons.edit_outlined,
                      size: 16, color: AppColors.white),
                  label: const Text('Edit',
                      style: TextStyle(color: AppColors.white)),
                ),
              if (_editing)
                TextButton(
                  onPressed: _saving
                      ? null
                      : () {
                          _populate();
                          setState(() => _editing = false);
                        },
                  child: const Text('Cancel',
                      style: TextStyle(color: AppColors.white)),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _ProfileHeader(user: user),
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Personal Details ──────────────────────────────────
                    _SectionHeader(
                        icon: Icons.person_outline, title: 'Personal Details'),
                    const SizedBox(height: AppSpacing.sm),
                    AppCard(
                      elevated: true,
                      child: Column(
                        children: _editing
                            ? [
                                AppTextField(
                                  controller: _nameCtrl,
                                  label: 'Full Name',
                                  hint: 'As shown on your ID',
                                  prefixIcon: Icons.person_outline,
                                  textInputAction: TextInputAction.next,
                                  validator: (v) =>
                                      (v == null || v.trim().length < 2)
                                          ? 'Name is required'
                                          : null,
                                ),
                              ]
                            : [
                                _InfoTile(
                                  icon: Icons.person_outline,
                                  label: 'Full Name',
                                  value: user?.fullName ?? '—',
                                  isFirst: true,
                                ),
                                _InfoTile(
                                  icon: Icons.badge_outlined,
                                  label: 'National ID',
                                  value: user?.nationalId ?? '—',
                                ),
                                _InfoTile(
                                  icon: Icons.verified_user_outlined,
                                  label: 'Account Role',
                                  value: 'Citizen',
                                  valueColor: AppColors.primary,
                                  isLast: true,
                                ),
                              ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Contact Information ───────────────────────────────
                    _SectionHeader(
                        icon: Icons.contact_phone_outlined,
                        title: 'Contact Information'),
                    const SizedBox(height: AppSpacing.sm),
                    AppCard(
                      elevated: true,
                      child: Column(
                        children: _editing
                            ? [
                                AppTextField(
                                  controller: _emailCtrl,
                                  label: 'Email Address',
                                  hint: 'you@example.com',
                                  prefixIcon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return null;
                                    }
                                    if (!v.contains('@')) {
                                      return 'Enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppSpacing.md),
                                AppTextField(
                                  controller: _phoneCtrl,
                                  label: 'Phone Number',
                                  hint: '+251 911 234 567',
                                  prefixIcon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                  textInputAction: TextInputAction.done,
                                ),
                              ]
                            : [
                                _InfoTile(
                                  icon: Icons.email_outlined,
                                  label: 'Email',
                                  value: user?.email ?? '—',
                                  isFirst: true,
                                ),
                                _InfoTile(
                                  icon: Icons.phone_outlined,
                                  label: 'Phone',
                                  value: user?.phoneNumber ?? '—',
                                  isLast: true,
                                ),
                              ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Account Activity ──────────────────────────────────
                    if (!_editing) ...[
                      _SectionHeader(
                          icon: Icons.history_outlined,
                          title: 'Account Activity'),
                      const SizedBox(height: AppSpacing.sm),
                      AppCard(
                        elevated: true,
                        child: Column(children: [
                          _InfoTile(
                            icon: Icons.calendar_today_outlined,
                            label: 'Member Since',
                            value: user?.createdAt != null
                                ? _formatDate(user!.createdAt!)
                                : '—',
                            isFirst: true,
                          ),
                          _InfoTile(
                            icon: Icons.security_outlined,
                            label: 'Account Status',
                            value: (user?.isActive ?? true)
                                ? 'Active'
                                : 'Suspended',
                            valueColor: (user?.isActive ?? true)
                                ? AppColors.success
                                : AppColors.danger,
                            isLast: true,
                          ),
                        ]),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // ── Security ────────────────────────────────────────
                      _SectionHeader(
                          icon: Icons.lock_outline, title: 'Security'),
                      const SizedBox(height: AppSpacing.sm),
                      AppCard(
                        elevated: true,
                        child: Column(children: [
                          _ActionTile(
                            icon: Icons.lock_outline,
                            label: 'Change Password',
                            subtitle: 'Update your account password',
                            onTap: () => context.push('/forgot-password'),
                            isFirst: true,
                            isLast: true,
                          ),
                        ]),
                      ),
                    ],

                    // ── Save button ───────────────────────────────────────
                    if (_editing) ...[
                      const SizedBox(height: AppSpacing.lg),
                      AppButton(
                        label: 'Save Changes',
                        icon: Icons.check_outlined,
                        loading: _saving,
                        onPressed: _saving ? null : _save,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppButton(
                        label: 'Discard',
                        variant: AppButtonVariant.secondary,
                        onPressed: () {
                          _populate();
                          setState(() => _editing = false);
                        },
                      ),
                    ],

                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(authRepositoryProvider).updateProfile({
        'full_name': _nameCtrl.text.trim(),
        if (_emailCtrl.text.trim().isNotEmpty) 'email': _emailCtrl.text.trim(),
        if (_phoneCtrl.text.trim().isNotEmpty)
          'phone_number': _phoneCtrl.text.trim(),
      });
      await ref.read(authControllerProvider.notifier).refreshUser();
      if (mounted) {
        setState(() => _editing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
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

  String _formatDate(DateTime d) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month]} ${d.day}, ${d.year}';
  }
}

// ── Profile Header ────────────────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});
  final dynamic user; // AppUser?

  Color _scoreColor(int score) {
    if (score >= 80) return AppColors.success;
    if (score >= 50) return AppColors.warning;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    final initials = user?.initials ?? '?';
    final name = user?.fullName ?? 'Driver';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF163A6E)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 90, 20, 16),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.4), width: 2),
            ),
            child: Center(
              child: Text(initials,
                  style: AppTypography.h2
                      .copyWith(color: AppColors.white)),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(name,
                    style: AppTypography.h3
                        .copyWith(color: AppColors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(user?.email ?? user?.phoneNumber ?? 'Citizen',
                    style: AppTypography.bodySmall.copyWith(
                        color: AppColors.white.withValues(alpha: 0.8)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 2),
        child: Row(children: [
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(title.toUpperCase(),
              style: AppTypography.caption.copyWith(
                  letterSpacing: 0.8,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600)),
        ]),
      );
}

// ── Info Tile ─────────────────────────────────────────────────────────────
class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.isFirst = false,
    this.isLast = false,
  });
  final IconData icon;
  final String label, value;
  final Color? valueColor;
  final bool isFirst, isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              vertical: 12, horizontal: AppSpacing.sm),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: AppTypography.caption
                            .copyWith(color: AppColors.textTertiary)),
                    const SizedBox(height: 2),
                    Text(value,
                        style: AppTypography.bodyMedium
                            .copyWith(color: valueColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(height: 1, indent: 56),
      ],
    );
  }
}

// ── Action Tile ───────────────────────────────────────────────────────────
class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
    this.destructive = false,
  });
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isFirst, isLast, destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.danger : AppColors.primary;
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.only(
            topLeft: isFirst ? const Radius.circular(12) : Radius.zero,
            topRight: isFirst ? const Radius.circular(12) : Radius.zero,
            bottomLeft: isLast ? const Radius.circular(12) : Radius.zero,
            bottomRight: isLast ? const Radius.circular(12) : Radius.zero,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                vertical: 12, horizontal: AppSpacing.sm),
            child: Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: AppTypography.bodyMedium
                            .copyWith(color: color)),
                    if (subtitle != null)
                      Text(subtitle!,
                          style: AppTypography.caption
                              .copyWith(color: AppColors.textTertiary)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  size: 18, color: AppColors.textTertiary),
            ]),
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: 56),
      ],
    );
  }
}
