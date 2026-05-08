import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../data/auth_providers.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({
    super.key,
    required this.identifier,
    required this.otpToken,
  });

  final String identifier;
  final String otpToken;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPass = TextEditingController();
  final _confirm = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _newPass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(authRepositoryProvider).resetPassword(
            phoneOrEmail: widget.identifier,
            newPassword: _newPass.text,
            otpToken: widget.otpToken,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset successfully')),
        );
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Password')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: [
              const SizedBox(height: AppSpacing.md),
              Text('Create a new password', style: AppTypography.h1),
              const SizedBox(height: AppSpacing.xl),
              AppTextField(
                controller: _newPass,
                label: 'New Password',
                hint: 'At least 8 characters',
                prefixIcon: Icons.lock_outline,
                obscure: true,
                canTogglePassword: true,
                validator: (v) => (v == null || v.length < 8)
                    ? 'Password must be at least 8 characters'
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _confirm,
                label: 'Confirm Password',
                hint: 'Re-enter password',
                prefixIcon: Icons.lock_outline,
                obscure: true,
                canTogglePassword: true,
                validator: (v) =>
                    v != _newPass.text ? 'Passwords do not match' : null,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Reset Password',
                onPressed: _submitting ? null : _submit,
                loading: _submitting,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
