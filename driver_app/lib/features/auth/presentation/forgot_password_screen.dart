import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../data/auth_providers.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _idCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(authRepositoryProvider).sendOtp(
            phoneOrEmail: _idCtrl.text.trim(),
            purpose: 'reset',
          );
      if (mounted) {
        context.push('/verify-otp', extra: {
          'identifier': _idCtrl.text.trim(),
          'purpose': 'reset',
        });
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
      appBar: AppBar(title: const Text('Reset Password')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: [
              const SizedBox(height: AppSpacing.md),
              Text('Forgot your password?', style: AppTypography.h1),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Enter the phone number or email associated with your account, '
                'and we will send a verification code to reset your password.',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textSecondary, height: 1.55),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppTextField(
                controller: _idCtrl,
                label: 'Phone Number or Email',
                hint: 'Enter your registered phone or email',
                prefixIcon: Icons.alternate_email_outlined,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter your phone or email'
                    : null,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Send Verification Code',
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
