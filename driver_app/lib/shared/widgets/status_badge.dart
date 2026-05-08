import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

enum StatusType { success, warning, danger, info, neutral }

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.type = StatusType.neutral,
    this.icon,
    this.compact = false,
  });

  final String label;
  final StatusType type;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = _resolveColors(type);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: compact ? 11 : 13, color: colors.$2),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: (compact ? AppTypography.caption : AppTypography.labelSmall)
                .copyWith(color: colors.$2, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  (Color bg, Color fg) _resolveColors(StatusType t) {
    switch (t) {
      case StatusType.success:
        return (AppColors.successSurface, AppColors.successText);
      case StatusType.warning:
        return (AppColors.warningSurface, AppColors.warningText);
      case StatusType.danger:
        return (AppColors.dangerSurface, AppColors.dangerText);
      case StatusType.info:
        return (AppColors.infoSurface, AppColors.infoText);
      case StatusType.neutral:
        return (AppColors.gray100, AppColors.gray700);
    }
  }
}
