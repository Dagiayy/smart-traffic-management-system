import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/storage/app_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/shared_widgets.dart';
import '../data/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idCtrl   = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _rememberMe = false;
  bool _submitting = false;

  @override
  void initState() { super.initState(); _rememberMe = AppStorage.instance.rememberMe; }
  @override
  void dispose() { _idCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(authControllerProvider.notifier)
          .login(id: _idCtrl.text.trim(), password: _passCtrl.text, rememberMe: _rememberMe);
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Dark top banner
          Positioned(top: 0, left: 0, right: 0,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.35,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryLight],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                children: [
                  const SizedBox(height: AppSpacing.xl),
                  // Logo
                  Center(child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.white.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.local_police_outlined, color: AppColors.white, size: 40),
                  )),
                  const SizedBox(height: AppSpacing.md),
                  Center(child: Text(AppConstants.appName,
                      style: AppTypography.h2.copyWith(color: AppColors.white), textAlign: TextAlign.center)),
                  const SizedBox(height: AppSpacing.xs),
                  Center(child: Text(AppConstants.appTagline,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.white.withValues(alpha: 0.8)),
                      textAlign: TextAlign.center)),
                  const SizedBox(height: AppSpacing.xxxl),
                  // Login card
                  AppCard(
                    elevated: true,
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Officer Sign In', style: AppTypography.h2),
                        const SizedBox(height: AppSpacing.xs),
                        Text('Enter your badge ID or official email',
                            style: AppTypography.bodySmall),
                        const SizedBox(height: AppSpacing.xl),
                        AppTextField(
                          controller: _idCtrl,
                          label: 'Officer ID or Email',
                          hint: 'Badge ID or official email',
                          prefixIcon: Icons.badge_outlined,
                          textInputAction: TextInputAction.next,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          controller: _passCtrl,
                          label: 'Password',
                          hint: 'Enter your password',
                          prefixIcon: Icons.lock_outline,
                          obscure: true,
                          canToggle: true,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                          validator: (v) => (v == null || v.length < 4) ? 'Enter your password' : null,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Checkbox(value: _rememberMe, onChanged: (v) => setState(() => _rememberMe = v ?? false),
                                visualDensity: VisualDensity.compact),
                            Text('Remember session', style: AppTypography.bodyMedium),
                            const Spacer(),
                            TextButton(
                              onPressed: () => context.push('/forgot-password'),
                              child: const Text('Forgot password?'),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppButton(label: 'Sign In', onPressed: _submitting ? null : _submit, loading: _submitting),
                        const SizedBox(height: AppSpacing.sm),
                        AppButton(
                          label: 'Contact Administrator',
                          variant: AppButtonVariant.ghost,
                          icon: Icons.support_agent_outlined,
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Center(child: Text('Authorized personnel only.\nUnauthorized access is prohibited.',
                      style: AppTypography.caption, textAlign: TextAlign.center)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
