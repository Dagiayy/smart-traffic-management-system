import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_format.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/state_widgets.dart';
import '../../shared/widgets/status_badge.dart';
import 'data/violation_model.dart';
import 'data/violations_providers.dart';

class ViolationDetailScreen extends ConsumerWidget {
  const ViolationDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(violationDetailProvider(id));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Violation Detail', style: AppTypography.h2)),
      body: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(children: [
            SkeletonBox(height: 220, radius: 16),
            SizedBox(height: 16),
            SkeletonBox(height: 160, radius: 16),
            SizedBox(height: 16),
            SkeletonBox(height: 80, radius: 16),
          ]),
        ),
        error: (e, _) => ErrorRetry(
            message: e.toString(),
            onRetry: () => ref.invalidate(violationDetailProvider(id))),
        data: (v) => _DetailBody(violation: v),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.violation});
  final Violation violation;

  @override
  Widget build(BuildContext context) {
    final canPay =
        violation.status == 'CONFIRMED' || violation.status == 'DETECTED';
    final canDispute = !violation.isDisputed && !violation.isPaid;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        // Header card
        AppCard(
          elevated: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                      child: Text(violation.violationType,
                          style: AppTypography.h2)),
                  _statusBadge(violation.status),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              if (violation.typeCode.isNotEmpty)
                Text(violation.typeCode,
                    style: AppTypography.caption
                        .copyWith(color: AppColors.primary)),
              const Divider(height: AppSpacing.lg),
              _Row(Icons.directions_car_outlined, 'Plate Number',
                  violation.plateNumber),
              _Row(Icons.calendar_today_outlined, 'Date & Time',
                  AppFormat.dateTime(violation.date)),
              if (violation.location != null)
                _Row(Icons.location_on_outlined, 'Location', violation.location!),
              if (violation.officerOrSystem != null)
                _Row(Icons.person_outline, 'Issued By',
                    violation.officerOrSystem!),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Fine breakdown
        AppCard(
          elevated: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Fine Breakdown', style: AppTypography.h3),
              const SizedBox(height: AppSpacing.md),
              _Row(Icons.gavel_outlined, 'Severity',
                  _prettyStatus(violation.severity)),
              if (violation.referenceNumber != null)
                _Row(Icons.tag_outlined, 'Reference No.',
                    violation.referenceNumber!),
              if (violation.legalCode != null)
                _Row(Icons.book_outlined, 'Legal Code', violation.legalCode!),
              if (violation.paymentDeadline != null)
                _Row(Icons.timer_outlined, 'Payment Deadline',
                    AppFormat.date(violation.paymentDeadline!)),
              const Divider(height: AppSpacing.lg),
              Row(
                children: [
                  Text('Total Fine Amount', style: AppTypography.labelLarge),
                  const Spacer(),
                  Text(
                    AppFormat.currency(violation.fineAmount),
                    style: AppTypography.numeric(22, FontWeight.w700,
                        color: violation.isPaid
                            ? AppColors.success
                            : AppColors.danger),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Actions
        if (canPay)
          AppButton(
            label: 'Pay Now',
            icon: Icons.payments_outlined,
            onPressed: () => context.push('/payments'),
          ),
        if (canPay) const SizedBox(height: AppSpacing.sm),
        if (canDispute)
          AppButton(
            label: 'Submit Dispute',
            variant: AppButtonVariant.secondary,
            icon: Icons.gavel_outlined,
            onPressed: () => context.push('/disputes'),
          ),
        if (canDispute) const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: 'Download Ticket',
          variant: AppButtonVariant.ghost,
          icon: Icons.download_outlined,
          onPressed: () {},
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _statusBadge(String status) {
    return switch (status) {
      'PAID' => const StatusBadge(label: 'Paid', type: StatusType.success),
      'DISPUTED' =>
        const StatusBadge(label: 'Disputed', type: StatusType.info),
      'DISMISSED' =>
        const StatusBadge(label: 'Dismissed', type: StatusType.neutral),
      'UNDER_REVIEW' =>
        const StatusBadge(label: 'Under Review', type: StatusType.info),
      _ => const StatusBadge(label: 'Unpaid', type: StatusType.warning),
    };
  }

  String _prettyStatus(String s) =>
      s[0] + s.substring(1).toLowerCase();
}

class _Row extends StatelessWidget {
  const _Row(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
              width: 110,
              child: Text(label, style: AppTypography.labelSmall)),
          Expanded(child: Text(value, style: AppTypography.bodyMedium)),
        ],
      ),
    );
  }
}
