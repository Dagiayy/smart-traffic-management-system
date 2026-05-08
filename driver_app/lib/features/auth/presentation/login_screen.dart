import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/storage/app_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../data/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _rememberMe = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _rememberMe = AppStorage.instance.rememberMe;
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(authControllerProvider.notifier).login(
            phoneOrEmail: _idCtrl.text.trim(),
            password: _passCtrl.text,
            rememberMe: _rememberMe,
          );
      if (mounted) context.go('/home');
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
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: [
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.shield_outlined,
                    size: 32, color: AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Welcome Back', style: AppTypography.h1),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'Sign in to manage your traffic compliance',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xxl),
              AppTextField(
                controller: _idCtrl,
                label: 'Phone Number or Email',
                hint: 'e.g. +251 911 234 567 or you@example.com',
                prefixIcon: Icons.person_outline,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [
                  AutofillHints.username,
                  AutofillHints.email
                ],
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter your phone or email'
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _passCtrl,
                label: 'Password',
                hint: 'Enter your password',
                prefixIcon: Icons.lock_outline,
                obscure: true,
                canTogglePassword: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                autofillHints: const [AutofillHints.password],
                validator: (v) => (v == null || v.length < 6)
                    ? 'Password must be at least 6 characters'
                    : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    onChanged: (v) => setState(() => _rememberMe = v ?? false),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  Text('Remember me', style: AppTypography.bodyMedium),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: const Text('Forgot password?'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Sign In',
                onPressed: _submitting ? null : _submit,
                loading: _submitting,
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account? ",
                      style: AppTypography.bodyMedium),
                  GestureDetector(
                    onTap: () => context.push('/register'),
                    child: Text(
                      'Create Account',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: Text(
                  'Secured by ${AppConstants.appName}',
                  style: AppTypography.caption,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
