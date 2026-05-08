import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

// ── AppButton ─────────────────────────────────────────────────────────────
enum AppButtonVariant { primary, secondary, ghost, danger, success }

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
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final bool fullWidth;
  final double? height;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || loading;
    final (bg, fg, border) = switch (variant) {
      AppButtonVariant.primary   => (AppColors.primary,         AppColors.white,       BorderSide.none),
      AppButtonVariant.secondary => (AppColors.surface,         AppColors.primary,     const BorderSide(color: AppColors.border, width: 1.2)),
      AppButtonVariant.ghost     => (Colors.transparent,        AppColors.primary,     BorderSide.none),
      AppButtonVariant.danger    => (AppColors.danger,          AppColors.white,       BorderSide.none),
      AppButtonVariant.success   => (AppColors.success,         AppColors.white,       BorderSide.none),
    };
    final h = height ?? (compact ? 40.0 : AppSizing.buttonHeight);
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: h,
      child: Material(
        color: isDisabled ? AppColors.gray300 : bg,
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
            padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16),
            child: loading
                ? SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation(fg)))
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[Icon(icon, size: compact ? 16 : 18, color: isDisabled ? AppColors.gray500 : fg), const SizedBox(width: 6)],
                      Text(label, style: AppTypography.button.copyWith(color: isDisabled ? AppColors.gray500 : fg)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ── AppCard ───────────────────────────────────────────────────────────────
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding, this.onTap, this.color, this.elevated = false, this.noBorder = false});
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final bool elevated;
  final bool noBorder;

  @override
  Widget build(BuildContext context) {
    final inner = Container(
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: AppRadius.radiusLg,
        border: noBorder ? null : Border.all(color: AppColors.border),
        boxShadow: elevated ? AppShadows.card : null,
      ),
      padding: padding ?? const EdgeInsets.all(AppSpacing.cardPadding),
      child: child,
    );
    if (onTap == null) return inner;
    return Material(color: Colors.transparent,
      child: InkWell(onTap: onTap, borderRadius: AppRadius.radiusLg, child: inner));
  }
}

// ── StatusBadge ───────────────────────────────────────────────────────────
enum BadgeType { success, warning, danger, info, neutral, primary }

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, this.type = BadgeType.neutral, this.compact = false, this.icon});
  final String label;
  final BadgeType type;
  final bool compact;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (type) {
      BadgeType.success => (AppColors.successSurface, AppColors.successText),
      BadgeType.warning => (AppColors.warningSurface, AppColors.warningText),
      BadgeType.danger  => (AppColors.dangerSurface,  AppColors.dangerText),
      BadgeType.info    => (AppColors.infoSurface,    AppColors.infoText),
      BadgeType.primary => (AppColors.primarySurface, AppColors.primaryLight),
      BadgeType.neutral => (AppColors.gray100,        AppColors.gray700),
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 10, vertical: compact ? 3 : 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: compact ? 10 : 12, color: fg), const SizedBox(width: 3)],
          Text(label, style: (compact ? AppTypography.caption : AppTypography.labelSmall)
              .copyWith(color: fg, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ── SyncBadge ─────────────────────────────────────────────────────────────
class SyncBadge extends StatelessWidget {
  const SyncBadge({super.key, required this.status});
  final String status; // SYNCED | PENDING_SYNC | FAILED | DRAFT

  @override
  Widget build(BuildContext context) {
    final (label, icon, type) = switch (status) {
      'SYNCED'       => ('Synced',      Icons.cloud_done_outlined,    BadgeType.success),
      'PENDING_SYNC' => ('Pending',     Icons.cloud_upload_outlined,  BadgeType.warning),
      'FAILED'       => ('Failed',      Icons.cloud_off_outlined,     BadgeType.danger),
      'SUBMITTED'    => ('Submitted',   Icons.send_outlined,          BadgeType.info),
      'UNDER_REVIEW' => ('In Review',   Icons.find_in_page_outlined,  BadgeType.info),
      'CLOSED'       => ('Closed',      Icons.check_circle_outline,   BadgeType.neutral),
      _              => ('Draft',       Icons.edit_outlined,          BadgeType.neutral),
    };
    return StatusBadge(label: label, type: type, icon: icon, compact: true);
  }
}

// ── AppTextField ──────────────────────────────────────────────────────────
class AppTextField extends StatefulWidget {
  const AppTextField({super.key, this.controller, this.label, this.hint,
      this.prefixIcon, this.suffix, this.obscure = false, this.canToggle = false,
      this.keyboardType, this.textInputAction, this.onChanged, this.onSubmitted,
      this.validator, this.maxLines = 1, this.maxLength, this.enabled = true,
      this.autofillHints, this.helperText, this.onTap, this.readOnly = false,
      this.inputFormatters});
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool obscure;
  final bool canToggle;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;
  final Iterable<String>? autofillHints;
  final String? helperText;
  final GestureTapCallback? onTap;
  final bool readOnly;
  final List<dynamic>? inputFormatters;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _hidden;
  @override
  void initState() { super.initState(); _hidden = widget.obscure; }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!, style: AppTypography.labelMedium),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: widget.controller,
          obscureText: _hidden,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          validator: widget.validator,
          maxLines: _hidden ? 1 : widget.maxLines,
          maxLength: widget.maxLength,
          enabled: widget.enabled,
          autofillHints: widget.autofillHints,
          readOnly: widget.readOnly,
          onTap: widget.onTap,
          style: AppTypography.bodyLarge,
          decoration: InputDecoration(
            hintText: widget.hint,
            helperText: widget.helperText,
            counterText: '',
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon, size: 20, color: AppColors.textSecondary)
                : null,
            suffixIcon: widget.canToggle
                ? IconButton(
                    icon: Icon(_hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 20, color: AppColors.textSecondary),
                    onPressed: () => setState(() => _hidden = !_hidden))
                : widget.suffix,
          ),
        ),
      ],
    );
  }
}

// ── State Widgets ─────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.title, this.message, this.icon = Icons.inbox_outlined, this.actionLabel, this.onAction});
  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.xl),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: AppColors.primarySurface, shape: BoxShape.circle),
        child: Icon(icon, size: 36, color: AppColors.primary)),
      const SizedBox(height: AppSpacing.lg),
      Text(title, style: AppTypography.h3, textAlign: TextAlign.center),
      if (message != null) ...[
        const SizedBox(height: AppSpacing.xs),
        Text(message!, style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
      ],
      if (actionLabel != null && onAction != null) ...[
        const SizedBox(height: AppSpacing.lg),
        SizedBox(width: 200, child: AppButton(label: actionLabel!, onPressed: onAction)),
      ],
    ]),
  );
}

class ErrorRetry extends StatelessWidget {
  const ErrorRetry({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => EmptyState(
    icon: Icons.cloud_off_outlined, title: 'Something went wrong',
    message: message, actionLabel: 'Try Again', onAction: onRetry);
}

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width = double.infinity, this.height = 16, this.radius = 8});
  final double width, height, radius;
  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
    baseColor: AppColors.gray200, highlightColor: AppColors.gray100,
    child: Container(width: width, height: height,
        decoration: BoxDecoration(color: AppColors.gray200, borderRadius: BorderRadius.circular(radius))));
}

// ── Section header ────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 2, bottom: AppSpacing.xs),
    child: Row(children: [
      Text(title.toUpperCase(),
          style: AppTypography.caption.copyWith(letterSpacing: 0.8, color: AppColors.textTertiary, fontWeight: FontWeight.w700)),
      const Spacer(),
      if (trailing != null) trailing!,
    ]),
  );
}
