import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/app_format.dart';
import '../../../shared/widgets/shared_widgets.dart';
import '../../dashboard/data/dashboard_data.dart';
import '../../tickets/data/ticket_data.dart';

class TicketDetailScreen extends ConsumerWidget {
  const TicketDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(ticketDetailProvider(id));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Ticket Detail')),
      body: async.when(
        loading: () => Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(children: const [
            SkeletonBox(height: 180, radius: 16), SizedBox(height: 12),
            SkeletonBox(height: 140, radius: 16), SizedBox(height: 12),
            SkeletonBox(height: 100, radius: 16),
          ]),
        ),
        error: (e, _) => ErrorRetry(message: e.toString(), onRetry: () => ref.invalidate(ticketDetailProvider(id))),
        data: (t) => _DetailBody(ticket: t),
      ),
    );
  }
}

class _DetailBody extends ConsumerStatefulWidget {
  const _DetailBody({required this.ticket});
  final FieldTicket ticket;
  @override
  ConsumerState<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends ConsumerState<_DetailBody> {
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final ticket = widget.ticket;
    final canSubmit = ticket.status == 'DRAFT';
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        // ── Status banner ────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF163A6E)]),
            borderRadius: AppRadius.radiusLg,
          ),
          child: Row(
            children: [
              const Icon(Icons.receipt_long_outlined, color: AppColors.white, size: 28),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ticket.violationType ?? 'Field Ticket',
                        style: AppTypography.h3.copyWith(color: AppColors.white)),
                    Text('Plate: ${ticket.plateNumber}',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.white.withValues(alpha: 0.8))),
                  ],
                ),
              ),
              SyncBadge(status: ticket.status),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Lifecycle timeline ────────────────────────────────────────
        AppCard(child: _LifecycleTimeline(status: ticket.status)),
        const SizedBox(height: AppSpacing.md),

        // ── Details ───────────────────────────────────────────────────
        AppCard(
          elevated: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Violation Details', style: AppTypography.h3),
              const Divider(height: AppSpacing.md),
              _Row(Icons.gavel_outlined,          'Violation',   ticket.violationType ?? '-'),
              _Row(Icons.warning_amber_outlined,  'Severity',    ticket.severity),
              if (ticket.legalCode != null) _Row(Icons.book_outlined, 'Legal Code', ticket.legalCode!),
              if (ticket.estimatedFine != null)
                _Row(Icons.account_balance_wallet_outlined, 'Estimated Fine',
                    AppFormat.currency(ticket.estimatedFine!), valueColor: AppColors.danger),
              _Row(Icons.access_time_outlined, 'Issued At', AppFormat.dateTime(ticket.createdAt)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        AppCard(
          elevated: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Vehicle & Driver', style: AppTypography.h3),
              const Divider(height: AppSpacing.md),
              _Row(Icons.confirmation_number_outlined, 'Plate',         ticket.plateNumber),
              if (ticket.vehicleType != null)  _Row(Icons.directions_car_outlined, 'Vehicle Type', ticket.vehicleType!),
              if (ticket.vehicleColor != null) _Row(Icons.palette_outlined,        'Color',        ticket.vehicleColor!),
              if (ticket.driverName != null)   _Row(Icons.person_outline,          'Driver',       ticket.driverName!),
              if (ticket.driverLicense != null) _Row(Icons.card_membership_outlined, 'License',   ticket.driverLicense!),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        if (ticket.locationName != null || ticket.locationLat != null)
          AppCard(
            elevated: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Location', style: AppTypography.h3),
                const Divider(height: AppSpacing.md),
                if (ticket.locationName != null) _Row(Icons.location_on_outlined, 'Intersection', ticket.locationName!),
                if (ticket.locationLat != null)  _Row(Icons.gps_fixed_outlined,   'Coordinates',
                    '${ticket.locationLat!.toStringAsFixed(5)}, ${ticket.locationLng!.toStringAsFixed(5)}'),
              ],
            ),
          ),
        if (ticket.notes != null && ticket.notes!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Officer Notes', style: AppTypography.labelMedium),
                const SizedBox(height: 6),
                Text(ticket.notes!, style: AppTypography.bodyMedium),
              ],
            ),
          ),
        ],
        if (ticket.evidenceUrls.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Evidence (${ticket.evidenceUrls.length})', style: AppTypography.h3),
                const SizedBox(height: AppSpacing.sm),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 6, mainAxisSpacing: 6),
                  itemCount: ticket.evidenceUrls.length,
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(ticket.evidenceUrls[i], fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: AppColors.gray200, child: const Icon(Icons.broken_image_outlined))),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        if (canSubmit)
          AppButton(
            label: 'Submit for Review',
            icon: Icons.send_outlined,
            variant: AppButtonVariant.success,
            loading: _submitting,
            onPressed: _submitting ? null : () => _submit(context),
          ),
        if (canSubmit) const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: 'Share / Export',
          icon: Icons.share_outlined,
          variant: AppButtonVariant.secondary,
          onPressed: () {},
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Future<void> _submit(BuildContext context) async {
    final ticket = widget.ticket;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit Ticket'),
        content: const Text('Once submitted, this ticket will be sent for supervisor review. You cannot edit it after submission.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Submit')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _submitting = true);
    try {
      await ref.read(ticketsRepositoryProvider).submitTicket(ticket.id);
      ref.invalidate(ticketDetailProvider(ticket.id));
      ref.invalidate(ticketsListProvider);
      ref.invalidate(dashboardSummaryProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket submitted for review')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submit failed: $e'), backgroundColor: Colors.red[700]));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _Row extends StatelessWidget {
  const _Row(this.icon, this.label, this.value, {this.valueColor});
  final IconData icon;
  final String label, value;
  final Color? valueColor;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 15, color: AppColors.textSecondary),
      const SizedBox(width: AppSpacing.sm),
      SizedBox(width: 110, child: Text(label, style: AppTypography.labelSmall)),
      Expanded(child: Text(value, style: AppTypography.bodyMedium.copyWith(color: valueColor))),
    ]),
  );
}

// ── Lifecycle Timeline ────────────────────────────────────────────────────
class _LifecycleTimeline extends StatelessWidget {
  const _LifecycleTimeline({required this.status});
  final String status;

  // Backend statuses: DRAFT → SUBMITTED → CONFIRMED | DISMISSED | ESCALATED
  static const _steps = [
    ('DRAFT',      'Draft',       Icons.edit_outlined),
    ('SUBMITTED',  'Submitted',   Icons.send_outlined),
    ('CONFIRMED',  'Confirmed',   Icons.verified_outlined),
  ];

  bool get _isDismissed  => status == 'DISMISSED';
  bool get _isEscalated  => status == 'ESCALATED';

  int _currentIndex() {
    if (status == 'DRAFT')      return 0;
    if (status == 'SUBMITTED')  return 1;
    // CONFIRMED, DISMISSED, ESCALATED, CLOSED all map to the final visual step
    if ({'CONFIRMED', 'DISMISSED', 'ESCALATED', 'CLOSED'}.contains(status)) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIdx = _currentIndex();

    Color finalColor() {
      if (_isDismissed) return AppColors.danger;
      if (_isEscalated) return AppColors.warning;
      return AppColors.success;
    }

    IconData finalIcon() {
      if (_isDismissed) return Icons.cancel_outlined;
      if (_isEscalated) return Icons.warning_amber_outlined;
      return Icons.verified_outlined;
    }

    String finalLabel() {
      if (_isDismissed) return 'Dismissed';
      if (_isEscalated) return 'Escalated';
      if (status == 'CLOSED') return 'Closed';
      return 'Confirmed';
    }

    final steps = [
      (_steps[0].$1, _steps[0].$2, _steps[0].$3, AppColors.success),
      (_steps[1].$1, _steps[1].$2, _steps[1].$3, AppColors.primary),
      ('FINAL', finalLabel(), finalIcon(), finalColor()),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Case Lifecycle', style: AppTypography.labelLarge),
            const Spacer(),
            _StatusChip(status: status),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: List.generate(steps.length, (i) {
            final done    = i <= currentIdx;
            final current = i == currentIdx;
            final stepColor = done ? steps[i].$4 : AppColors.gray300;
            return Expanded(
              child: Column(
                children: [
                  Row(children: [
                    if (i > 0) Expanded(child: Container(height: 2,
                        color: i <= currentIdx ? AppColors.primary : AppColors.gray200)),
                    Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        color: done ? stepColor : AppColors.gray200,
                        shape: BoxShape.circle,
                        border: current ? Border.all(color: stepColor, width: 2) : null,
                      ),
                      child: Icon(steps[i].$3, size: 15, color: AppColors.white),
                    ),
                    if (i < steps.length - 1) Expanded(child: Container(height: 2,
                        color: i < currentIdx ? AppColors.primary : AppColors.gray200)),
                  ]),
                  const SizedBox(height: 4),
                  Text(steps[i].$2,
                      style: AppTypography.caption.copyWith(
                          color: current ? stepColor : done ? stepColor.withValues(alpha: 0.8) : AppColors.textTertiary,
                          fontWeight: current ? FontWeight.w700 : FontWeight.w400),
                      textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'DRAFT'      => ('Draft',       AppColors.gray500),
      'SUBMITTED'  => ('Under Review', AppColors.primary),
      'CONFIRMED'  => ('Confirmed',    AppColors.success),
      'DISMISSED'  => ('Dismissed',    AppColors.danger),
      'ESCALATED'  => ('Escalated',    AppColors.warning),
      'CLOSED'     => ('Closed',       AppColors.gray600),
      _            => (status,         AppColors.gray500),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: AppTypography.caption.copyWith(color: color, fontWeight: FontWeight.w700)),
    );
  }
}
