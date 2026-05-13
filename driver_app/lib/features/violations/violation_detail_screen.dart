import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

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
                _Row(Icons.location_on_outlined, 'Location',
                    violation.location!),
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
          onPressed: () => _downloadTicket(context, violation),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  void _downloadTicket(BuildContext context, Violation v) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _TicketSheet(violation: v),
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

  String _prettyStatus(String s) => s[0] + s.substring(1).toLowerCase();
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

// ── Ticket Sheet ──────────────────────────────────────────────────────────
class _TicketSheet extends StatelessWidget {
  const _TicketSheet({required this.violation});
  final Violation violation;

  String _buildTicketText() {
    final buf = StringBuffer();
    buf.writeln('========================================');
    buf.writeln('   TRAFFIC VIOLATION TICKET');
    buf.writeln('   Integrated Traffic Management System');
    buf.writeln('========================================');
    buf.writeln();
    buf.writeln('Violation Type : ${violation.violationType}');
    if (violation.typeCode.isNotEmpty) {
      buf.writeln('Type Code      : ${violation.typeCode}');
    }
    buf.writeln('Plate Number   : ${violation.plateNumber}');
    buf.writeln('Date & Time    : ${AppFormat.dateTime(violation.date)}');
    buf.writeln('Status         : ${violation.status}');
    buf.writeln('Severity       : ${violation.severity}');
    if (violation.location != null) {
      buf.writeln('Location       : ${violation.location}');
    }
    if (violation.officerOrSystem != null) {
      buf.writeln('Issued By      : ${violation.officerOrSystem}');
    }
    if (violation.referenceNumber != null) {
      buf.writeln('Reference No.  : ${violation.referenceNumber}');
    }
    if (violation.legalCode != null) {
      buf.writeln('Legal Code     : ${violation.legalCode}');
    }
    if (violation.paymentDeadline != null) {
      buf.writeln(
          'Pay By         : ${AppFormat.date(violation.paymentDeadline!)}');
    }
    buf.writeln();
    buf.writeln('Fine Amount    : ${AppFormat.currency(violation.fineAmount)}');
    buf.writeln();
    buf.writeln('========================================');
    buf.writeln('Please pay by the deadline to avoid');
    buf.writeln('additional penalties.');
    buf.writeln('========================================');
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        top: AppSpacing.lg,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_long_outlined,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('Violation Ticket', style: AppTypography.h3),
            ]),
            const SizedBox(height: AppSpacing.lg),

            // Ticket body
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: AppRadius.radiusMd,
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(children: [
                      const Icon(Icons.local_police_outlined,
                          color: AppColors.primary, size: 32),
                      const SizedBox(height: 4),
                      Text('TRAFFIC VIOLATION TICKET',
                          style: AppTypography.labelLarge
                              .copyWith(color: AppColors.primary)),
                      Text('Integrated Traffic Management System',
                          style: AppTypography.caption
                              .copyWith(color: AppColors.textSecondary)),
                    ]),
                  ),
                  const Divider(height: AppSpacing.lg),
                  _TicketRow('Violation', violation.violationType),
                  if (violation.typeCode.isNotEmpty)
                    _TicketRow('Type Code', violation.typeCode),
                  _TicketRow('Plate Number', violation.plateNumber),
                  _TicketRow(
                      'Date & Time', AppFormat.dateTime(violation.date)),
                  _TicketRow('Status', violation.status),
                  _TicketRow('Severity', violation.severity),
                  if (violation.location != null)
                    _TicketRow('Location', violation.location!),
                  if (violation.officerOrSystem != null)
                    _TicketRow('Issued By', violation.officerOrSystem!),
                  if (violation.referenceNumber != null)
                    _TicketRow('Reference No.', violation.referenceNumber!),
                  if (violation.legalCode != null)
                    _TicketRow('Legal Code', violation.legalCode!),
                  if (violation.paymentDeadline != null)
                    _TicketRow('Pay By',
                        AppFormat.date(violation.paymentDeadline!)),
                  const Divider(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Fine Amount',
                          style: AppTypography.labelLarge),
                      Text(AppFormat.currency(violation.fineAmount),
                          style: AppTypography.numeric(18, FontWeight.w800,
                              color: AppColors.danger)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Share button
            AppButton(
              label: 'Share Ticket',
              icon: Icons.share_outlined,
              onPressed: () {
                Share.share(_buildTicketText(),
                    subject: 'Traffic Violation Ticket');
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Close',
              variant: AppButtonVariant.secondary,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketRow extends StatelessWidget {
  const _TicketRow(this.label, this.value);
  final String label, value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 100,
                child: Text(label,
                    style: AppTypography.labelSmall
                        .copyWith(color: AppColors.textSecondary))),
            Expanded(child: Text(value, style: AppTypography.bodySmall)),
          ],
        ),
      );
}
