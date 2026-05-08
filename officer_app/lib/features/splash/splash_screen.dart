import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../auth/data/auth_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashState();
}

class _SplashState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
   // await ref.read(authControllerProvider.notifier).bootstrap();
   // if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    final state = ref.read(authControllerProvider);
    context.go(state is AuthAuthenticated ? '/home' : '/login');
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, Color(0xFF163A6E)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 96, height: 96,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.white.withValues(alpha: 0.25), width: 1.5),
                    ),
                    child: const Icon(Icons.local_police_outlined, color: AppColors.white, size: 48),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(AppConstants.appName,
                      style: AppTypography.h1.copyWith(color: AppColors.white), textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.xs),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
                    child: Text(AppConstants.appTagline,
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.white.withValues(alpha: 0.8)),
                        textAlign: TextAlign.center),
                  ),
                  const SizedBox(height: AppSpacing.huge),
                  SizedBox(width: 24, height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(AppColors.white.withValues(alpha: 0.8)))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
