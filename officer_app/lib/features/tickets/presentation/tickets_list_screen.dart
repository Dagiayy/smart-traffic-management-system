import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/app_format.dart';
import '../../../shared/widgets/shared_widgets.dart';
import '../../tickets/data/ticket_data.dart';

class TicketsListScreen extends ConsumerWidget {
  const TicketsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(ticketFiltersProvider);
    final listAsync = ref.watch(filteredTicketsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Tickets'),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list_outlined), onPressed: () => _showFilters(context, ref)),
          IconButton(icon: const Icon(Icons.add), onPressed: () => context.push('/new-ticket')),
        ],
      ),
      body: Column(
        children: [
          if (filters.status != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, 0),
              child: Row(children: [
                Chip(
                  label: Text('Status: ${filters.status}', style: AppTypography.labelSmall),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () => ref.read(ticketFiltersProvider.notifier).state = (status: null),
                ),
              ]),
            ),
          Expanded(
            child: listAsync.when(
              loading: () => ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: 5, separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
                  itemBuilder: (_, __) => const SkeletonBox(height: 88, radius: 12)),
              error: (e, _) => ErrorRetry(message: e.toString(), onRetry: () => ref.invalidate(filteredTicketsProvider)),
              data: (page) => page.results.isEmpty
                  ? EmptyState(icon: Icons.receipt_long_outlined, title: 'No Tickets',
                      message: 'Tickets you create will appear here.',
                      actionLabel: 'New Ticket', onAction: () => context.push('/new-ticket'))
                  : RefreshIndicator(
                      onRefresh: () async => ref.invalidate(filteredTicketsProvider),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: page.results.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
                        itemBuilder: (ctx, i) => _TicketCard(ticket: page.results[i]),
                      ),
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/new-ticket'),
        icon: const Icon(Icons.add),
        label: const Text('New Ticket'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
    );
  }

  void _showFilters(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filter Tickets', style: AppTypography.h3),
            const SizedBox(height: AppSpacing.md),
            Wrap(spacing: 8, runSpacing: 4,
              children: ['DRAFT', 'SUBMITTED', 'SYNCED', 'UNDER_REVIEW', 'CLOSED'].map((s) {
                final selected = ref.watch(ticketFiltersProvider).status == s;
                return ChoiceChip(
                  label: Text(s, style: AppTypography.labelSmall),
                  selected: selected,
                  onSelected: (v) {
                    ref.read(ticketFiltersProvider.notifier).state = (status: v ? s : null);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket});
  final FieldTicket ticket;

  Color _severityColor(String s) => switch (s) {
    'CRITICAL' => AppColors.danger, 'MAJOR' => AppColors.warning, _ => AppColors.info,
  };

  @override
  Widget build(BuildContext context) {
    final sCol = _severityColor(ticket.severity);
    return AppCard(
      onTap: () => context.push('/tickets/${ticket.id}'),
      elevated: true,
      child: Row(
        children: [
          Container(
            width: 4, height: 60,
            decoration: BoxDecoration(
              color: sCol,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), bottomLeft: Radius.circular(4)),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text(ticket.violationType ?? 'Violation',
                      style: AppTypography.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  SyncBadge(status: ticket.status),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.directions_car_outlined, size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(ticket.plateNumber, style: AppTypography.bodySmall),
                  const SizedBox(width: 12),
                  const Icon(Icons.access_time_outlined, size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(AppFormat.relative(ticket.createdAt), style: AppTypography.bodySmall),
                ]),
                if (ticket.locationName != null)
                  Row(children: [
                    const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(child: Text(ticket.locationName!, style: AppTypography.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ]),
                if (ticket.estimatedFine != null && ticket.estimatedFine! > 0)
                  Text(AppFormat.currency(ticket.estimatedFine!),
                      style: AppTypography.numeric(14, FontWeight.w700, color: sCol)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 20),
        ],
      ),
    );
  }
}
