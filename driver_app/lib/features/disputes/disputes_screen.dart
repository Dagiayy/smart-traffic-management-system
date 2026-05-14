import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_format.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/state_widgets.dart';
import '../../shared/widgets/status_badge.dart';
import '../violations/data/violation_model.dart';
import 'data/disputes_providers.dart';
import 'data/disputes_repository.dart';

class DisputesScreen extends ConsumerWidget {
  const DisputesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(disputesListProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('My Disputes', style: AppTypography.h2),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => ref.invalidate(disputesListProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSubmitSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('New Dispute'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: listAsync.when(
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (_, __) => const SkeletonBox(height: 100, radius: 14),
        ),
        error: (e, _) => ErrorRetry(
          message: e.toString(),
          onRetry: () => ref.invalidate(disputesListProvider),
        ),
        data: (page) => page.results.isEmpty
            ? const EmptyState(
                icon: Icons.gavel_outlined,
                title: 'No Disputes Filed',
                message:
                    'If you believe a violation was issued in error,\ntap "New Dispute" to contest it.',
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(disputesListProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.md, AppSpacing.md, 100),
                  itemCount: page.results.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (ctx, i) =>
                      _DisputeTile(dispute: page.results[i]),
                ),
              ),
      ),
    );
  }

  void _showSubmitSheet(BuildContext context) {
    showDisputeSheet(context);
  }
}

/// Public helper — call from anywhere (e.g. violation detail) to open the
/// dispute submission sheet, optionally pre-selecting a violation.
void showDisputeSheet(BuildContext context, {Violation? preSelected}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => SubmitDisputeSheet(preSelected: preSelected),
  );
}

// ── Dispute Tile ──────────────────────────────────────────────────────────
class _DisputeTile extends ConsumerWidget {
  const _DisputeTile({required this.dispute});
  final Dispute dispute;

  (StatusType, String, Color) _badge() => switch (dispute.status) {
        'APPROVED' => (StatusType.success, 'Approved', AppColors.success),
        'REJECTED' => (StatusType.danger, 'Rejected', AppColors.danger),
        'UNDER_REVIEW' =>
          (StatusType.info, 'Under Review', AppColors.primary),
        'WITHDRAWN' =>
          (StatusType.neutral, 'Withdrawn', AppColors.textSecondary),
        _ => (StatusType.warning, 'Submitted', AppColors.warning),
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (type, label, color) = _badge();
    return AppCard(
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.gavel_outlined, size: 18, color: color),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_pretty(dispute.reason),
                      style: AppTypography.labelLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text('ID: ${dispute.violationId.length > 8 ? dispute.violationId.substring(0, 8).toUpperCase() : dispute.violationId}',
                      style: AppTypography.caption
                          .copyWith(color: AppColors.textTertiary)),
                ],
              ),
            ),
            StatusBadge(label: label, type: type, compact: true),
          ]),
          const SizedBox(height: AppSpacing.sm),
          Text(dispute.description,
              style: AppTypography.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: AppSpacing.xs),
          Row(children: [
            const Icon(Icons.access_time_outlined,
                size: 12, color: AppColors.textTertiary),
            const SizedBox(width: 4),
            Text('Submitted ${AppFormat.relative(dispute.createdAt)}',
                style: AppTypography.caption),
          ]),
          // Admin feedback / decision
          if (dispute.adminFeedback != null &&
              dispute.adminFeedback!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: dispute.status == 'APPROVED'
                    ? AppColors.successSurface
                    : AppColors.dangerSurface,
                borderRadius: AppRadius.radiusSm,
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(
                  dispute.status == 'APPROVED'
                      ? Icons.check_circle_outline
                      : Icons.info_outline,
                  size: 14,
                  color: dispute.status == 'APPROVED'
                      ? AppColors.success
                      : AppColors.danger,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(dispute.adminFeedback!,
                      style: AppTypography.bodySmall.copyWith(
                          color: dispute.status == 'APPROVED'
                              ? AppColors.success
                              : AppColors.danger),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis),
                ),
              ]),
            ),
          ],
          if (dispute.status == 'SUBMITTED') ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () => _withdraw(context, ref),
                icon: const Icon(Icons.cancel_outlined, size: 14),
                label: const Text('Withdraw'),
                style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    textStyle: AppTypography.labelSmall,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _withdraw(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Withdraw Dispute'),
        content: const Text(
            'Are you sure you want to withdraw this dispute?\nThis action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Withdraw',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    try {
      await ref
          .read(disputesRepositoryProvider)
          .withdrawDispute(dispute.id);
      ref.invalidate(disputesListProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dispute withdrawn')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  String _pretty(String s) {
    if (s.isEmpty) return s;
    return s
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) =>
            w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }
}

// ── Submit Dispute Sheet ──────────────────────────────────────────────────
class SubmitDisputeSheet extends ConsumerStatefulWidget {
  const SubmitDisputeSheet({super.key, this.preSelected});
  final Violation? preSelected;

  @override
  ConsumerState<SubmitDisputeSheet> createState() => SubmitDisputeSheetState();
}

class SubmitDisputeSheetState extends ConsumerState<SubmitDisputeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  String _reason = 'WRONG_VEHICLE';
  bool _submitting = false;
  Violation? _selectedViolation;

  @override
  void initState() {
    super.initState();
    _selectedViolation = widget.preSelected;
  }

  static const _reasons = [
    ('WRONG_VEHICLE', 'Wrong vehicle identified'),
    ('INCORRECT_DETECTION', 'Incorrect detection / false positive'),
    ('EMERGENCY_CASE', 'Emergency situation'),
    ('FALSE_VIOLATION', 'False violation'),
    ('TECHNICAL_ERROR', 'Technical error'),
    ('OTHER', 'Other reason'),
  ];

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final violationsAsync = ref.watch(disputeViolationsProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: AppSpacing.lg,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.gray300,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Header
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.gavel_outlined,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('File a Dispute', style: AppTypography.h3),
                    Text('Contest a violation you believe is incorrect',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ]),
              const SizedBox(height: AppSpacing.lg),

              // Step 1 — pick violation
              _StepLabel(number: '1', label: 'Select Violation'),
              const SizedBox(height: AppSpacing.xs),
              violationsAsync.when(
                loading: () => const SkeletonBox(height: 68, radius: 12),
                error: (_, __) => _manualIdNote(),
                data: (violations) => violations.isEmpty
                    ? _manualIdNote()
                    : _ViolationPickerButton(
                        violations: violations,
                        selected: _selectedViolation,
                        onSelected: (v) =>
                            setState(() => _selectedViolation = v),
                      ),
              ),
              if (_selectedViolation == null && _submitting == false)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('Please select a violation',
                      style: AppTypography.caption
                          .copyWith(color: AppColors.textTertiary)),
                ),

              const SizedBox(height: AppSpacing.md),

              // Step 2 — reason
              _StepLabel(number: '2', label: 'Reason for Dispute'),
              const SizedBox(height: AppSpacing.xs),
              DropdownButtonFormField<String>(
                value: _reason,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.help_outline,
                      color: AppColors.gray500, size: 18),
                ),
                items: _reasons
                    .map((r) => DropdownMenuItem(
                        value: r.$1,
                        child: Text(r.$2, style: AppTypography.bodyMedium)))
                    .toList(),
                onChanged: (v) => setState(() => _reason = v ?? _reason),
              ),
              const SizedBox(height: AppSpacing.md),

              // Step 3 — description
              _StepLabel(number: '3', label: 'Describe Your Case'),
              const SizedBox(height: AppSpacing.xs),
              AppTextField(
                controller: _description,
                label: 'Details',
                hint:
                    'Explain why this violation is incorrect, include any relevant context...',
                maxLines: 4,
                validator: (v) => (v == null || v.trim().length < 10)
                    ? 'Please write at least 10 characters'
                    : null,
              ),
              const SizedBox(height: AppSpacing.xl),

              AppButton(
                label: 'Submit Dispute',
                icon: Icons.send_outlined,
                loading: _submitting,
                onPressed: _submitting ? null : _submit,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Widget _manualIdNote() => Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.warningSurface,
          borderRadius: AppRadius.radiusSm,
        ),
        child: Row(children: [
          const Icon(Icons.info_outline,
              size: 16, color: AppColors.warningText),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'No violations found for your account. Make sure you are logged in correctly.',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.warningText),
            ),
          ),
        ]),
      );

  Future<void> _submit() async {
    if (_selectedViolation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a violation first')));
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      await ref.read(disputesRepositoryProvider).submitDispute(
            violationId: _selectedViolation!.id,
            reason: _reason,
            description: _description.text.trim(),
          );
      ref.invalidate(disputesListProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dispute submitted — we\'ll review it shortly.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Submission failed: ${e.toString()}'),
              backgroundColor: AppColors.danger));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

// ── Violation Picker Button ───────────────────────────────────────────────
class _ViolationPickerButton extends StatelessWidget {
  const _ViolationPickerButton({
    required this.violations,
    required this.selected,
    required this.onSelected,
  });
  final List<Violation> violations;
  final Violation? selected;
  final ValueChanged<Violation> onSelected;

  @override
  Widget build(BuildContext context) {
    if (selected != null) {
      return _SelectedViolationCard(
          violation: selected!, onClear: () => onSelected(selected!));
    }
    return OutlinedButton(
      onPressed: () => _openPicker(context),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        shape:
            RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
      ),
      child: Row(children: [
        const Icon(Icons.receipt_long_outlined, size: 18),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text('Tap to select a violation',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.primary)),
        ),
        const Icon(Icons.chevron_right, size: 18),
      ]),
    );
  }

  void _openPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ViolationPickerSheet(
          violations: violations, onSelected: onSelected),
    );
  }
}

class _SelectedViolationCard extends StatelessWidget {
  const _SelectedViolationCard(
      {required this.violation, required this.onClear});
  final Violation violation;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        const Icon(Icons.receipt_long_outlined,
            color: AppColors.primary, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(violation.violationType,
                  style: AppTypography.labelMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text(
                  '${violation.plateNumber} · ${AppFormat.date(violation.date)}',
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => _openRepicker(context),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.swap_horiz,
                size: 16, color: AppColors.primary),
          ),
        ),
      ]),
    );
  }

  void _openRepicker(BuildContext context) {
    // Re-use the same sheet — just passing context up
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ViolationPickerSheet(
          violations: [], onSelected: onClear as ValueChanged<Violation>),
    );
  }
}

// ── Violation Picker Sheet ────────────────────────────────────────────────
class _ViolationPickerSheet extends StatelessWidget {
  const _ViolationPickerSheet(
      {required this.violations, required this.onSelected});
  final List<Violation> violations;
  final ValueChanged<Violation> onSelected;

  Color _severityColor(String s) => switch (s) {
        'CRITICAL' => AppColors.danger,
        'MAJOR' => AppColors.warning,
        _ => AppColors.info,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(children: [
              Text('Select Violation to Dispute',
                  style: AppTypography.h3),
            ]),
          ),
          const Divider(height: 1),
          Expanded(
            child: violations.isEmpty
                ? const Center(
                    child: Text('No violations available'),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: violations.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.xs),
                    itemBuilder: (ctx, i) {
                      final v = violations[i];
                      return InkWell(
                        borderRadius: AppRadius.radiusMd,
                        onTap: () {
                          onSelected(v);
                          Navigator.pop(ctx);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            borderRadius: AppRadius.radiusMd,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _severityColor(v.severity)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.receipt_long_outlined,
                                  size: 18,
                                  color: _severityColor(v.severity)),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(v.violationType,
                                      style: AppTypography.labelMedium,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  Text(
                                    '${v.plateNumber} · ${AppFormat.date(v.date)}',
                                    style: AppTypography.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(AppFormat.currency(v.fineAmount),
                                      style: AppTypography.numeric(13,
                                          FontWeight.w700,
                                          color:
                                              AppColors.danger)),
                                  Text(v.severity.toLowerCase(),
                                      style: AppTypography.caption
                                          .copyWith(
                                              color:
                                                  _severityColor(v.severity))),
                                ]),
                          ]),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Step Label ────────────────────────────────────────────────────────────
class _StepLabel extends StatelessWidget {
  const _StepLabel({required this.number, required this.label});
  final String number, label;

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
              color: AppColors.primary, shape: BoxShape.circle),
          child: Center(
            child: Text(number,
                style: AppTypography.caption.copyWith(
                    color: AppColors.white, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: AppTypography.labelMedium),
      ]);
}
