import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_format.dart';
import '../../shared/widgets/shared_widgets.dart';
import '../auth/data/auth_providers.dart';
import '../dashboard/data/dashboard_data.dart';
import '../tickets/data/ticket_data.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user      = ref.watch(currentUserProvider);
    final summaryAsync = ref.watch(dashboardSummaryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async { ref.invalidate(dashboardSummaryProvider); },
        child: CustomScrollView(
          slivers: [
            // ── Branded AppBar ──────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 160,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, Color(0xFF163A6E)],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.screenPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: AppColors.white.withValues(alpha: 0.2),
                                child: Text(user?.initials ?? '?',
                                    style: AppTypography.labelLarge.copyWith(color: AppColors.white)),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Officer ${user?.fullName.split(' ').first ?? ''}',
                                        style: AppTypography.h3.copyWith(color: AppColors.white)),
                                    Text(
                                      '${user?.badgeNumber != null ? 'Badge: ${user!.badgeNumber}' : user?.role.value ?? 'OFFICER'}'
                                      '${user?.assignedZone != null ? ' · ${user!.assignedZone}' : ''}',
                                      style: AppTypography.bodySmall.copyWith(color: AppColors.white.withValues(alpha: 0.8)),
                                    ),
                                  ],
                                ),
                              ),
                              // Notification bell
                              IconButton(
                                icon: const Icon(Icons.notifications_outlined, color: AppColors.white),
                                onPressed: () => context.push('/notifications'),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Today: ${AppFormat.date(DateTime.now())}',
                            style: AppTypography.caption.copyWith(color: AppColors.white.withValues(alpha: 0.7)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(icon: const Icon(Icons.person_outline), onPressed: () => context.push('/profile')),
              ],
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Summary cards ───────────────────────────────────
                    summaryAsync.when(
                      loading: () => const _SummaryLoading(),
                      error: (e, _) => ErrorRetry(message: e.toString(), onRetry: () => ref.invalidate(dashboardSummaryProvider)),
                      data: (s) => _SummaryGrid(summary: s),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Quick Actions ────────────────────────────────────
                    Text('Quick Actions', style: AppTypography.h3),
                    const SizedBox(height: AppSpacing.sm),
                    _QuickActions(),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Live Alerts ──────────────────────────────────────
                    summaryAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (s) => s.alerts.isEmpty
                          ? const SizedBox.shrink()
                          : _AlertsSection(alerts: s.alerts),
                    ),

                    // ── Recent tickets ───────────────────────────────────
                    _RecentTicketsSection(),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Summary Grid ──────────────────────────────────────────────────────────
class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.summary});
  final OfficerSummary summary;
  @override
  Widget build(BuildContext context) {
    final cards = [
      (Icons.receipt_long_outlined, 'Today',          '${summary.ticketsToday}',          AppColors.primary),
      (Icons.date_range_outlined,   'This Week',      '${summary.ticketsWeek}',           AppColors.accent),
      (Icons.pending_outlined,      'Pending',        '${summary.pendingSubmissions}',    AppColors.warning),
      (Icons.check_circle_outline,  'Confirmed',      '${summary.confirmedViolations}',   AppColors.success),
    ];
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.55,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: cards.map((c) => _StatCard(icon: c.$1, label: c.$2, value: c.$3, color: c.$4)).toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.label, required this.value, required this.color});
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return AppCard(
      elevated: true,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 18, color: color),
          ),
          const Spacer(),
          Text(value, style: AppTypography.numeric(22, FontWeight.w700, color: color)),
          Text(label, style: AppTypography.labelSmall),
        ],
      ),
    );
  }
}

// ── Quick Actions ─────────────────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      (Icons.add_circle_outline,   'New Ticket',    '/new-ticket',         AppColors.primary),
      (Icons.list_alt_outlined,    'My Cases',      '/tickets',            AppColors.accent),
      (Icons.search_outlined,      'Search',        '/search-violations',  AppColors.info),
      (Icons.bar_chart_outlined,   'Reports',       '/reports',            AppColors.gray600),
      (Icons.person_outline,       'My Activity',   '/performance',        AppColors.gray600),
    ];
    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: actions.map((a) => _QuickActionTile(icon: a.$1, label: a.$2, route: a.$3, color: a.$4)).toList(),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.icon, required this.label, required this.route, required this.color});
  final IconData icon;
  final String label;
  final String route;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.push(route),
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: AppTypography.labelSmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ── Alerts Section ────────────────────────────────────────────────────────
class _AlertsSection extends StatelessWidget {
  const _AlertsSection({required this.alerts});
  final List<AlertItem> alerts;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Live Alerts', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.sm),
        ...alerts.take(3).map((a) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.warningSurface,
              borderRadius: AppRadius.radiusMd,
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_outlined, color: AppColors.warning, size: 18),
                const SizedBox(width: AppSpacing.xs),
                Expanded(child: Text(a.message, style: AppTypography.bodySmall.copyWith(color: AppColors.warningText), maxLines: 2, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
        )),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

// ── Recent Tickets ────────────────────────────────────────────────────────
class _RecentTicketsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(ticketsListProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Recent Tickets', style: AppTypography.h3),
            const Spacer(),
            TextButton(onPressed: () => context.push('/tickets'), child: const Text('View all')),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        async.when(
          loading: () => Column(children: List.generate(3, (_) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: const SkeletonBox(height: 68, radius: 12)))),
          error: (_, __) => const SizedBox.shrink(),
          data: (page) => page.results.isEmpty
              ? AppCard(child: Center(child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text('No tickets yet', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)))))
              : Column(
                  children: page.results.take(4).map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: _RecentTicketRow(ticket: t))).toList()),
        ),
      ],
    );
  }
}

class _RecentTicketRow extends StatelessWidget {
  const _RecentTicketRow({required this.ticket});
  final FieldTicket ticket;
  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.push('/tickets/${ticket.id}'),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: _severityColor(ticket.severity).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.receipt_long_outlined, size: 18, color: _severityColor(ticket.severity)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(ticket.violationType ?? ticket.plateNumber, style: AppTypography.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(ticket.plateNumber, style: AppTypography.bodySmall),
            ]),
          ),
          SyncBadge(status: ticket.status),
        ],
      ),
    );
  }

  Color _severityColor(String s) => switch (s) {
    'CRITICAL' => AppColors.danger, 'MAJOR' => AppColors.warning, _ => AppColors.info,
  };
}

// ── Loading Placeholder ───────────────────────────────────────────────────
class _SummaryLoading extends StatelessWidget {
  const _SummaryLoading();
  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Row(children: [
          Expanded(child: SkeletonBox(height: 80, radius: 12)),
          SizedBox(width: 12),
          Expanded(child: SkeletonBox(height: 80, radius: 12)),
        ]),
        SizedBox(height: 12),
        Row(children: [
          Expanded(child: SkeletonBox(height: 80, radius: 12)),
          SizedBox(width: 12),
          Expanded(child: SkeletonBox(height: 80, radius: 12)),
        ]),
      ],
    );
  }
}
