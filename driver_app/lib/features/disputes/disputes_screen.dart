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
          itemBuilder: (_, __) => const SkeletonBox(height: 80, radius: 14),
        ),
        error: (e, _) => ErrorRetry(
          message: e.toString(),
          onRetry: () => ref.invalidate(disputesListProvider),
        ),
        data: (page) => page.results.isEmpty
            ? const EmptyState(
                icon: Icons.gavel_outlined,
                title: 'No Disputes Filed',
                message: 'Contest a violation by tapping "New Dispute" below.',
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(disputesListProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: page.results.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (ctx, i) => _DisputeTile(dispute: page.results[i]),
                ),
              ),
      ),
    );
  }

  void _showSubmitSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SubmitDisputeSheet(),
    );
  }
}

class _DisputeTile extends ConsumerWidget {
  const _DisputeTile({required this.dispute});
  final Dispute dispute;

  (StatusType, String) _badge() => switch (dispute.status) {
        'APPROVED' => (StatusType.success, 'Approved'),
        'REJECTED' => (StatusType.danger, 'Rejected'),
        'UNDER_REVIEW' => (StatusType.info, 'Under Review'),
        'WITHDRAWN' => (StatusType.neutral, 'Withdrawn'),
        _ => (StatusType.warning, 'Submitted'),
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (type, label) = _badge();
    return AppCard(
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.gavel_outlined, size: 16, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(_pretty(dispute.reason),
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
          Row(children: [
            const Icon(Icons.access_time_outlined, size: 12, color: AppColors.textTertiary),
            const SizedBox(width: 4),
            Text('Submitted ${AppFormat.relative(dispute.createdAt)}',
                style: AppTypography.caption),
          ]),
          if (dispute.adminFeedback != null && dispute.adminFeedback!.isNotEmpty) ...[
            const Divider(height: AppSpacing.md),
            Row(children: [
              const Icon(Icons.comment_outlined, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Expanded(child: Text(dispute.adminFeedback!,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.primary),
                  maxLines: 2, overflow: TextOverflow.ellipsis)),
            ]),
          ],
          if (dispute.status == 'SUBMITTED') ...[
            const SizedBox(height: AppSpacing.xs),
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
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
        content: const Text('Are you sure? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Withdraw', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    try {
      await ref.read(disputesRepositoryProvider).withdrawDispute(dispute.id);
      ref.invalidate(disputesListProvider);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dispute withdrawn successfully')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())));
    }
  }

  String _pretty(String s) {
    if (s.isEmpty) return s;
    return s.replaceAll('_', ' ').split(' ').map((w) =>
      w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase()).join(' ');
  }
}

class _SubmitDisputeSheet extends ConsumerStatefulWidget {
  const _SubmitDisputeSheet();

  @override
  ConsumerState<_SubmitDisputeSheet> createState() => _SubmitDisputeSheetState();
}

class _SubmitDisputeSheetState extends ConsumerState<_SubmitDisputeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _violationId = TextEditingController();
  final _description = TextEditingController();
  String _reason = 'WRONG_VEHICLE';
  bool _submitting = false;

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
    _violationId.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.gray300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.gavel_outlined, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text('Submit a Dispute', style: AppTypography.h3),
              ]),
              const SizedBox(height: AppSpacing.xs),
              Text('Contest a violation you believe is incorrect.',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                controller: _violationId,
                label: 'Violation ID',
                hint: 'Enter the violation reference number',
                prefixIcon: Icons.tag_outlined,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Violation ID is required' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Reason for Dispute', style: AppTypography.labelMedium),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _reason,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.help_outline, color: AppColors.gray500, size: 18),
                ),
                items: _reasons.map((r) => DropdownMenuItem(
                    value: r.$1,
                    child: Text(r.$2, style: AppTypography.bodyMedium))).toList(),
                onChanged: (v) => setState(() => _reason = v ?? _reason),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _description,
                label: 'Describe Your Case',
                hint: 'Provide detailed information to support your dispute...',
                maxLines: 4,
                validator: (v) => (v == null || v.trim().length < 10)
                    ? 'Please provide at least 10 characters of description'
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
            content: Text('Dispute submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ${e.toString()}'),
            backgroundColor: AppColors.danger));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
