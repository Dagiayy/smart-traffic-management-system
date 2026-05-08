import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

enum AppButtonVariant { primary, secondary, ghost, danger }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.fullWidth = true,
    this.height,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final bool fullWidth;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || loading;

    Color bg;
    Color fg;
    BorderSide border = BorderSide.none;

    switch (variant) {
      case AppButtonVariant.primary:
        bg = AppColors.primary;
        fg = AppColors.white;
        break;
      case AppButtonVariant.secondary:
        bg = AppColors.surface;
        fg = AppColors.primary;
        border = const BorderSide(color: AppColors.border, width: 1.2);
        break;
      case AppButtonVariant.ghost:
        bg = Colors.transparent;
        fg = AppColors.primary;
        break;
      case AppButtonVariant.danger:
        bg = AppColors.danger;
        fg = AppColors.white;
        break;
    }

    final child = loading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation(fg),
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(label, style: AppTypography.button.copyWith(color: fg)),
            ],
          );

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height ?? AppSizing.buttonHeight,
      child: Material(
        color: isDisabled
            ? (variant == AppButtonVariant.primary
                ? AppColors.gray300
                : bg.withValues(alpha: 0.5))
            : bg,
        borderRadius: AppRadius.radiusMd,
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          borderRadius: AppRadius.radiusMd,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: AppRadius.radiusMd,
              border: Border.fromBorderSide(border),
            ),
            alignment: Alignment.center,
            child: child,
          ),
        ),
      ),
    );
  }
}
