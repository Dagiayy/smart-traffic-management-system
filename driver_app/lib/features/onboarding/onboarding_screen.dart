import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../core/storage/app_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/app_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingSlide {
  final IconData icon;
  final String title;
  final String description;
  const _OnboardingSlide(
      {required this.icon, required this.title, required this.description});
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  static const _slides = [
    _OnboardingSlide(
      icon: Icons.fact_check_outlined,
      title: 'Track Violations Easily',
      description:
          'View your traffic violations, evidence, and status updates in one secure place.',
    ),
    _OnboardingSlide(
      icon: Icons.payments_outlined,
      title: 'Pay Fines Securely',
      description:
          'Settle traffic fines digitally with instant receipts. No paperwork, no queues.',
    ),
    _OnboardingSlide(
      icon: Icons.alt_route_outlined,
      title: 'Smart Traffic Alerts',
      description:
          'Get live advisories from the central command center and avoid congestion zones.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await AppStorage.instance.setOnboardingDone(true);
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: _finish, child: const Text('Skip')),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final slide = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Icon(slide.icon,
                              size: 64, color: AppColors.primary),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        Text(slide.title,
                            style: AppTypography.h1, textAlign: TextAlign.center),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          slide.description,
                          style: AppTypography.bodyLarge.copyWith(
                              color: AppColors.textSecondary, height: 1.55),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SmoothPageIndicator(
              controller: _controller,
              count: _slides.length,
              effect: const ExpandingDotsEffect(
                dotHeight: 8,
                dotWidth: 8,
                expansionFactor: 3,
                activeDotColor: AppColors.primary,
                dotColor: AppColors.gray300,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
              child: AppButton(
                label: _index == _slides.length - 1
                    ? 'Get Started'
                    : 'Continue',
                onPressed: () {
                  if (_index == _slides.length - 1) {
                    _finish();
                  } else {
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
