import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../data/auth_providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _nationalId = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _plate = TextEditingController();
  String _vehicleType = 'CAR';
  bool _agreed = false;
  bool _submitting = false;

  static const _vehicleTypes = ['CAR', 'MOTORCYCLE', 'TRUCK', 'BUS', 'TAXI'];

  @override
  void dispose() {
    for (final c in [
      _name, _nationalId, _phone, _email, _password, _confirm, _plate
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please accept the Terms of Service to continue')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(authControllerProvider.notifier).register(
        fullName: _name.text.trim(),
        nationalId: _nationalId.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        vehicles: [
          {
            'plate_number': _plate.text.trim().toUpperCase(),
            'type': _vehicleType,
          }
        ],
      );
      if (mounted) {
        // Send to OTP verification screen passing phone
        context.go('/verify-otp', extra: {
          'identifier': _phone.text.trim(),
          'purpose': 'verify',
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
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: [
              Text('Personal Information', style: AppTypography.h3),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _name,
                label: 'Full Name',
                hint: 'As shown on your ID',
                prefixIcon: Icons.person_outline,
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().length < 3)
                    ? 'Please enter your full name'
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _nationalId,
                label: 'National ID / Driver ID',
                hint: 'Enter your government-issued ID',
                prefixIcon: Icons.badge_outlined,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _phone,
                label: 'Phone Number',
                hint: '+251 911 234 567',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().length < 9)
                    ? 'Enter a valid phone number'
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _email,
                label: 'Email Address',
                hint: 'you@example.com',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  final s = v?.trim() ?? '';
                  if (s.isEmpty || !s.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _password,
                label: 'Password',
                hint: 'At least 8 characters',
                prefixIcon: Icons.lock_outline,
                obscure: true,
                canTogglePassword: true,
                textInputAction: TextInputAction.next,
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
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    v != _password.text ? 'Passwords do not match' : null,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Vehicle Information', style: AppTypography.h3),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _plate,
                label: 'Primary Vehicle Plate Number',
                hint: 'e.g. AA-12345',
                prefixIcon: Icons.directions_car_outlined,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().length < 3) ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Vehicle Type', style: AppTypography.labelMedium),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _vehicleType,
                decoration: const InputDecoration(
                  prefixIcon:
                      Icon(Icons.local_taxi_outlined, color: AppColors.gray500),
                ),
                items: _vehicleTypes
                    .map((t) =>
                        DropdownMenuItem(value: t, child: Text(_pretty(t))))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _vehicleType = v ?? _vehicleType),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _agreed,
                    onChanged: (v) => setState(() => _agreed = v ?? false),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'I agree to the Terms of Service and Privacy Policy of the Traffic Authority.',
                        style: AppTypography.bodySmall,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Create Account',
                onPressed: _submitting ? null : _submit,
                loading: _submitting,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already have an account? ',
                      style: AppTypography.bodyMedium),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: Text('Sign In',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _pretty(String t) {
    return t[0] + t.substring(1).toLowerCase();
  }
}
