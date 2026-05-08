import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_format.dart';
import '../../shared/models/app_user.dart';
import '../../shared/widgets/shared_widgets.dart';
import '../tickets/data/ticket_data.dart';

// ── Supervisor data providers ─────────────────────────────────────────────
final pendingTicketsProvider = FutureProvider.autoDispose<PaginatedResponse<FieldTicket>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.get('/supervisor/tickets/pending/');
  return PaginatedResponse.fromJson(res.data as Map<String, dynamic>, FieldTicket.fromJson);
});

final officersListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.get('/supervisor/officers/');
  final data = res.data;
  if (data is Map && data['results'] is List) return List<Map<String, dynamic>>.from(data['results'] as List);
  if (data is List) return List<Map<String, dynamic>>.from(data);
  return [];
});

// ── Supervisor Screen ─────────────────────────────────────────────────────
class SupervisorScreen extends ConsumerStatefulWidget {
  const SupervisorScreen({super.key});
  @override
  ConsumerState<SupervisorScreen> createState() => _SupervisorState();
}

class _SupervisorState extends ConsumerState<SupervisorScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() { super.initState(); _tab = TabController(length: 2, vsync: this); }
  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Supervisor View'),
        bottom: TabBar(
          controller: _tab,
          labelStyle: AppTypography.labelMedium,
          indicatorColor: AppColors.white,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.white.withValues(alpha: 0.6),
          tabs: const [Tab(text: 'Pending Review'), Tab(text: 'Officers')],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _PendingTicketsTab(),
          _OfficersTab(),
        ],
      ),
    );
  }
}

class _PendingTicketsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pendingTicketsProvider);
    return async.when(
      loading: () => ListView.separated(padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: 5, separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
          itemBuilder: (_, __) => const SkeletonBox(height: 80, radius: 12)),
      error: (e, _) => ErrorRetry(message: e.toString(), onRetry: () => ref.invalidate(pendingTicketsProvider)),
      data: (page) => page.results.isEmpty
          ? const EmptyState(icon: Icons.check_circle_outline, title: 'All Reviewed', message: 'No tickets pending supervisor review.')
          : RefreshIndicator(
              onRefresh: () async => ref.invalidate(pendingTicketsProvider),
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: page.results.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
                itemBuilder: (ctx, i) => _PendingTicketCard(ticket: page.results[i], ref: ref),
              ),
            ),
    );
  }
}

class _PendingTicketCard extends StatelessWidget {
  const _PendingTicketCard({required this.ticket, required this.ref});
  final FieldTicket ticket;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(ticket.violationType ?? ticket.plateNumber,
                style: AppTypography.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis)),
            StatusBadge(label: ticket.severity, type: switch (ticket.severity) {
              'CRITICAL' => BadgeType.danger, 'MAJOR' => BadgeType.warning, _ => BadgeType.info,
            }, compact: true),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.directions_car_outlined, size: 13, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(ticket.plateNumber, style: AppTypography.bodySmall),
            const Spacer(),
            Text(AppFormat.relative(ticket.createdAt), style: AppTypography.caption),
          ]),
          const Divider(height: AppSpacing.md),
          Row(children: [
            Expanded(child: AppButton(
              label: 'Approve',
              variant: AppButtonVariant.success,
              compact: true,
              icon: Icons.check_outlined,
              onPressed: () => _decide(context, 'APPROVE'),
            )),
            const SizedBox(width: 8),
            Expanded(child: AppButton(
              label: 'Reject',
              variant: AppButtonVariant.danger,
              compact: true,
              icon: Icons.close,
              onPressed: () => _decide(context, 'REJECT'),
            )),
          ]),
        ],
      ),
    );
  }

  Future<void> _decide(BuildContext context, String decision) async {
    final feedbackCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${decision == 'APPROVE' ? 'Approve' : 'Reject'} Ticket'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Plate: ${ticket.plateNumber}'),
          const SizedBox(height: 12),
          TextField(controller: feedbackCtrl,
              decoration: const InputDecoration(hintText: 'Feedback (optional)', border: OutlineInputBorder()),
              maxLines: 2),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: decision == 'APPROVE' ? AppColors.success : AppColors.danger),
            child: Text(decision == 'APPROVE' ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    try {
      final api = ref.read(apiClientProvider);
      await api.post('/supervisor/tickets/${ticket.id}/validate/', data: {
        'decision': decision,
        'feedback': feedbackCtrl.text,
      });
      ref.invalidate(pendingTicketsProvider);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ticket ${decision == 'APPROVE' ? 'approved' : 'rejected'}')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}

class _OfficersTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(officersListProvider);
    return async.when(
      loading: () => ListView.separated(padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: 4, separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
          itemBuilder: (_, __) => const SkeletonBox(height: 68, radius: 12)),
      error: (e, _) => ErrorRetry(message: e.toString(), onRetry: () => ref.invalidate(officersListProvider)),
      data: (officers) => officers.isEmpty
          ? const EmptyState(icon: Icons.group_outlined, title: 'No Officers', message: 'No officers assigned to your supervision.')
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: officers.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
              itemBuilder: (_, i) {
                final o = officers[i];
                final name = o['full_name']?.toString() ?? o['name']?.toString() ?? 'Officer';
                final badge = o['badge_number']?.toString();
                final ticketsCount = o['tickets_count'] ?? o['performance']?['tickets_issued'] ?? 0;
                return AppCard(
                  child: Row(children: [
                    CircleAvatar(radius: 20, backgroundColor: AppColors.primarySurface,
                        child: Text(name.isNotEmpty ? name[0] : '?',
                            style: AppTypography.labelLarge.copyWith(color: AppColors.primary))),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(name, style: AppTypography.labelLarge),
                        if (badge != null) Text('Badge: $badge', style: AppTypography.bodySmall),
                      ]),
                    ),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('$ticketsCount', style: AppTypography.numeric(18, FontWeight.w700, color: AppColors.primary)),
                      Text('tickets', style: AppTypography.caption),
                    ]),
                  ]),
                );
              },
            ),
    );
  }
}
