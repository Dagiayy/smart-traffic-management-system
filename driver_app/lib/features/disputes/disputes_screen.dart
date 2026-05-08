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
import 'data/disputes_providers.dart';
import 'data/disputes_repository.dart';

class DisputesScreen extends ConsumerWidget {
  const DisputesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(disputesListProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Disputes', style: AppTypography.h2)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSubmitSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Submit Dispute'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: listAsync.when(
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (_, __) => const SkeletonBox(height: 80, radius: 14),
        ),
        error: (e, _) => ErrorRetry(
          message: e.toString(),
          onRetry: () => ref.invalidate(disputesListProvider),
        ),
        data: (page) => page.results.isEmpty
            ? const EmptyState(
                icon: Icons.gavel_outlined,
                title: 'No Disputes',
                message:
                    'You have not submitted any disputes yet.\nUse the button below to contest a violation.',
              )
            : RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(disputesListProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: page.results.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (ctx, i) =>
                      _DisputeTile(dispute: page.results[i], ref: ref),
                ),
              ),
      ),
    );
  }

  void _showSubmitSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _SubmitDisputeSheet(ref: ref),
    );
  }
}

class _DisputeTile extends StatelessWidget {
  const _DisputeTile({required this.dispute, required this.ref});
  final Dispute dispute;
  final WidgetRef ref;

  (StatusType, String) _badge() => switch (dispute.status) {
        'APPROVED' => (StatusType.success, 'Approved'),
        'REJECTED' => (StatusType.danger, 'Rejected'),
        'UNDER_REVIEW' => (StatusType.info, 'Under Review'),
        _ => (StatusType.neutral, 'Submitted'),
      };

  @override
  Widget build(BuildContext context) {
    final (type, label) = _badge();
    return AppCard(
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
                child: Text(
                    _pretty(dispute.reason),
                    style: AppTypography.labelLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis)),
            StatusBadge(label: label, type: type, compact: true),
          ]),
          const SizedBox(height: AppSpacing.xs),
          Text(dispute.description,
              style: AppTypography.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: AppSpacing.xs),
          Text('Submitted ${AppFormat.relative(dispute.createdAt)}',
              style: AppTypography.caption),
          if (dispute.adminFeedback != null && dispute.adminFeedback!.isNotEmpty)
            ...[
              const Divider(height: AppSpacing.md),
              Row(children: [
                const Icon(Icons.comment_outlined,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(dispute.adminFeedback!,
                      style: AppTypography.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ),
              ]),
            ],
          if (dispute.status == 'SUBMITTED') ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _withdraw(context, ref),
                icon: const Icon(Icons.cancel_outlined, size: 16),
                label: const Text('Withdraw'),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    textStyle: AppTypography.labelSmall),
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
        content: const Text('Are you sure you want to withdraw this dispute?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Withdraw',
                  style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    try {
      await ref.read(disputesRepositoryProvider).withdrawDispute(dispute.id);
      ref.invalidate(disputesListProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  String _pretty(String s) => s.replaceAll('_', ' ').toLowerCase().replaceFirst(
      s[0].toLowerCase(), s[0].toUpperCase());
}

class _SubmitDisputeSheet extends ConsumerStatefulWidget {
  const _SubmitDisputeSheet({required this.ref});
  final WidgetRef ref;

  @override
  ConsumerState<_SubmitDisputeSheet> createState() =>
      _SubmitDisputeSheetState();
}

class _SubmitDisputeSheetState extends ConsumerState<_SubmitDisputeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _violationId = TextEditingController();
  final _description = TextEditingController();
  String _reason = 'WRONG_VEHICLE';
  bool _submitting = false;

  static const _reasons = [
    ('WRONG_VEHICLE', 'Wrong vehicle'),
    ('INCORRECT_DETECTION', 'Incorrect detection'),
    ('EMERGENCY_CASE', 'Emergency case'),
    ('FALSE_VIOLATION', 'False violation'),
    ('OTHER', 'Other'),
  ];

  @override
  void dispose() {
    _violationId.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Submit a Dispute', style: AppTypography.h3),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _violationId,
                  label: 'Violation ID',
                  hint: 'Enter the violation reference number',
                  prefixIcon: Icons.tag_outlined,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Required'
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Reason for Dispute', style: AppTypography.labelMedium),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _reason,
                  items: _reasons
                      .map((r) => DropdownMenuItem(
                          value: r.$1, child: Text(r.$2)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _reason = v ?? _reason),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _description,
                  label: 'Description',
                  hint: 'Explain your case in detail...',
                  maxLines: 4,
                  validator: (v) => (v == null || v.trim().length < 10)
                      ? 'Please provide a detailed description'
                      : null,
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: 'Submit Dispute',
                  loading: _submitting,
                  onPressed: _submitting ? null : _submit,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(disputesRepositoryProvider).submitDispute(
            violationId: _violationId.text.trim(),
            reason: _reason,
            description: _description.text.trim(),
          );
      ref.invalidate(disputesListProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Dispute submitted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
