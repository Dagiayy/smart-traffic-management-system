import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_button.dart';
import '../data/auth_providers.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({
    super.key,
    required this.identifier,
    required this.purpose, // "verify" or "reset"
  });

  final String identifier;
  final String purpose;

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final _ctrl = TextEditingController();
  bool _submitting = false;
  bool _resending = false;
  int _cooldown = 0;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

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

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _resend() async {
    if (_cooldown > 0) return;
    setState(() => _resending = true);
    try {
      await ref.read(authRepositoryProvider).sendOtp(
            phoneOrEmail: widget.identifier,
            purpose: widget.purpose,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A new code has been sent')),
        );
        _startCooldown();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _verify() async {
    if (_ctrl.text.length < 4) return;
    setState(() => _submitting = true);
    try {
      final token = await ref.read(authRepositoryProvider).verifyOtp(
            phoneOrEmail: widget.identifier,
            code: _ctrl.text,
          );
      if (!mounted) return;
      if (widget.purpose == 'reset') {
        context.go('/reset-password', extra: {
          'identifier': widget.identifier,
          'otp_token': token,
        });
      } else {
        // verify flow — bootstrap auth and route home
        await ref.read(authControllerProvider.notifier).bootstrap();
        if (mounted) context.go('/home');
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
    final defaultPin = PinTheme(
      width: 52,
      height: 56,
      textStyle: AppTypography.h2,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
    );

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.sms_outlined,
                    size: 30, color: AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Verification Code', style: AppTypography.h1),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Enter the 6-digit code we sent to ${widget.identifier}',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Pinput(
                controller: _ctrl,
                length: 6,
                defaultPinTheme: defaultPin,
                focusedPinTheme: defaultPin.copyWith(
                  decoration: defaultPin.decoration!.copyWith(
                    border: Border.all(color: AppColors.primary, width: 1.6),
                  ),
                ),
                submittedPinTheme: defaultPin.copyWith(
                  decoration: defaultPin.decoration!.copyWith(
                    color: AppColors.primarySurface,
                  ),
                ),
                onCompleted: (_) => _verify(),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Verify',
                onPressed: _ctrl.text.length == 6 && !_submitting ? _verify : null,
                loading: _submitting,
              ),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: TextButton(
                  onPressed: _cooldown > 0 || _resending ? null : _resend,
                  child: _resending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_cooldown > 0
                          ? 'Resend code in ${_cooldown}s'
                          : 'Resend code'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
