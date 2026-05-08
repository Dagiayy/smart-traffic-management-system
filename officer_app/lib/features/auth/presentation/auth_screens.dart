import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/shared_widgets.dart';
import '../data/auth_providers.dart';

// ── Forgot Password ───────────────────────────────────────────────────────
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotState();
}
class _ForgotState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ctrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(authRepositoryProvider).sendOtp(identifier: _ctrl.text.trim(), purpose: 'reset');
      if (mounted) context.push('/verify-otp', extra: {'identifier': _ctrl.text.trim(), 'purpose': 'reset'});
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally { if (mounted) setState(() => _submitting = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Reset Password')),
    body: SafeArea(child: Form(key: _formKey, child: ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        const SizedBox(height: AppSpacing.md),
        Text('Password Recovery', style: AppTypography.h1),
        const SizedBox(height: AppSpacing.xs),
        Text('Enter your Officer ID or official email to receive a verification code.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.xl),
        AppTextField(controller: _ctrl, label: 'Officer ID or Email', hint: 'Enter your ID or email',
            prefixIcon: Icons.badge_outlined,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
        const SizedBox(height: AppSpacing.xl),
        AppButton(label: 'Send Verification Code', onPressed: _submitting ? null : _submit, loading: _submitting),
      ],
    ))),
  );
}

// ── OTP Verification ──────────────────────────────────────────────────────
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.identifier, required this.purpose});
  final String identifier;
  final String purpose;
  @override
  ConsumerState<OtpScreen> createState() => _OtpState();
}
class _OtpState extends ConsumerState<OtpScreen> {
  final _ctrl = TextEditingController();
  bool _submitting = false;
  int _cooldown = 30;

  @override
  void initState() { super.initState(); _startCooldown(); }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _startCooldown() {
    setState(() => _cooldown = 30);
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      if (_cooldown <= 0) return false;
      setState(() => _cooldown--);
      return true;
    });
  }

  Future<void> _verify() async {
    if (_ctrl.text.length < 4) return;
    setState(() => _submitting = true);
    try {
      final token = await ref.read(authRepositoryProvider).verifyOtp(identifier: widget.identifier, code: _ctrl.text);
      if (!mounted) return;
      if (widget.purpose == 'reset') {
        context.go('/reset-password', extra: {'identifier': widget.identifier, 'otp_token': token});
      } else {
        await ref.read(authControllerProvider.notifier).bootstrap();
        if (mounted) context.go('/home');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally { if (mounted) setState(() => _submitting = false); }
  }

  @override
  Widget build(BuildContext context) {
    final defaultPin = PinTheme(
      width: 52, height: 56,
      textStyle: AppTypography.h2,
      decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Verification')),
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SizedBox(height: AppSpacing.md),
          Text('Enter Verification Code', style: AppTypography.h1),
          const SizedBox(height: AppSpacing.xs),
          Text('Code sent to ${widget.identifier}', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.xxl),
          Pinput(controller: _ctrl, length: 6, defaultPinTheme: defaultPin,
              focusedPinTheme: defaultPin.copyWith(decoration: defaultPin.decoration!.copyWith(border: Border.all(color: AppColors.primary, width: 1.6))),
              onCompleted: (_) => _verify()),
          const SizedBox(height: AppSpacing.xl),
          AppButton(label: 'Verify', onPressed: _ctrl.text.length == 6 && !_submitting ? _verify : null, loading: _submitting),
          const SizedBox(height: AppSpacing.md),
          Center(child: TextButton(
            onPressed: _cooldown > 0 ? null : _startCooldown,
            child: Text(_cooldown > 0 ? 'Resend in ${_cooldown}s' : 'Resend code'),
          )),
        ]),
      )),
    );
  }
}

// ── Reset Password ────────────────────────────────────────────────────────
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, required this.identifier, required this.otpToken});
  final String identifier;
  final String otpToken;
  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetState();
}
class _ResetState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() { _pass.dispose(); _confirm.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(authRepositoryProvider).resetPassword(identifier: widget.identifier, newPassword: _pass.text, otpToken: widget.otpToken);
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset successfully'))); context.go('/login'); }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally { if (mounted) setState(() => _submitting = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('New Password')),
    body: SafeArea(child: Form(key: _formKey, child: ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        const SizedBox(height: AppSpacing.md),
        Text('Set New Password', style: AppTypography.h1),
        const SizedBox(height: AppSpacing.xl),
        AppTextField(controller: _pass, label: 'New Password', hint: 'Min. 8 characters',
            prefixIcon: Icons.lock_outline, obscure: true, canToggle: true,
            validator: (v) => (v == null || v.length < 8) ? 'Min 8 characters' : null),
        const SizedBox(height: AppSpacing.md),
        AppTextField(controller: _confirm, label: 'Confirm Password', hint: 'Re-enter password',
            prefixIcon: Icons.lock_outline, obscure: true, canToggle: true,
            validator: (v) => v != _pass.text ? 'Passwords do not match' : null),
        const SizedBox(height: AppSpacing.xl),
        AppButton(label: 'Reset Password', onPressed: _submitting ? null : _submit, loading: _submitting),
      ],
    ))),
  );
}
