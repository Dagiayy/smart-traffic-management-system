import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_format.dart';
import '../../shared/widgets/shared_widgets.dart';

// ── Providers (officer-scoped endpoints only) ─────────────────────────────
final reportPeriodProvider = StateProvider<String>((ref) => 'week');

final officerAnalyticsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final period = ref.watch(reportPeriodProvider);
  try {
    final res = await ref.watch(apiClientProvider)
        .get('/officer/analytics/', query: {'period': period});
    final data = res.data;
    return data is Map<String, dynamic> ? data : {};
  } catch (_) { return {}; }
});

final officerDailyReportProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  try {
    final res = await ref.watch(apiClientProvider).get('/officer/reports/daily/');
    final data = res.data;
    return data is Map<String, dynamic> ? data : {};
  } catch (_) { return {}; }
});

// ── Reports Screen ─────────────────────────────────────────────────────────
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});
  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() { super.initState(); _tab = TabController(length: 3, vsync: this); }
  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Reports'),
        bottom: TabBar(
          controller: _tab,
          labelStyle: AppTypography.labelMedium,
          indicatorColor: AppColors.white,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.white.withValues(alpha: 0.6),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Violations'),
            Tab(text: 'Daily'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _OverviewTab(),
          _ViolationsTab(),
          _DailyTab(),
        ],
      ),
    );
  }
}

// ── Overview Tab ──────────────────────────────────────────────────────────
class _OverviewTab extends ConsumerWidget {
  const _OverviewTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period    = ref.watch(reportPeriodProvider);
    final async     = ref.watch(officerAnalyticsProvider);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        // Period selector
        Row(
          children: ['day', 'week', 'month'].map((p) => Expanded(child: Padding(
            padding: EdgeInsets.only(right: p != 'month' ? 6 : 0),
            child: ChoiceChip(
              label: Text(p[0].toUpperCase() + p.substring(1), style: AppTypography.labelSmall),
              selected: period == p,
              onSelected: (v) { if (v) ref.read(reportPeriodProvider.notifier).state = p; },
            ),
          ))).toList(),
        ),
        const SizedBox(height: AppSpacing.lg),

        async.when(
          loading: () => const Column(children: [
            SkeletonBox(height: 90, radius: 14), SizedBox(height: 12),
            SkeletonBox(height: 90, radius: 14),
          ]),
          error: (e, _) => ErrorRetry(message: e.toString(), onRetry: () => ref.invalidate(officerAnalyticsProvider)),
          data: (data) => Column(
            children: [
              _OverviewStats(data: data),
              const SizedBox(height: AppSpacing.lg),

              // Fines collected
              if ((data['total_collected'] ?? 0) > 0)
                AppCard(
                  elevated: true,
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(color: AppColors.successSurface, shape: BoxShape.circle),
                      child: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.success, size: 22),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Fines from My Tickets', style: AppTypography.labelMedium),
                      Text(AppFormat.currency((data['total_collected'] ?? 0).toDouble()),
                          style: AppTypography.numeric(20, FontWeight.w700, color: AppColors.success)),
                    ])),
                  ]),
                ),
              const SizedBox(height: AppSpacing.lg),

              // Daily bar chart
              AppCard(
                elevated: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Daily Breakdown (Last 7 Days)', style: AppTypography.h3),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      height: 150,
                      child: _DailyBarChart(daily: (data['daily'] as List?) ?? []),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Top Violation row
              if ((data['by_type'] as List? ?? []).isNotEmpty) ...[
                AppCard(
                  elevated: true,
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.emoji_events_outlined,
                          color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Top Violation', style: AppTypography.labelMedium),
                        Text(
                          (data['by_type'] as List).first['name']?.toString() ?? '',
                          style: AppTypography.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ]),
                    ),
                    Text(
                      '${(data['by_type'] as List).first['count'] ?? 0}',
                      style: AppTypography.numeric(18, FontWeight.w700, color: AppColors.primary),
                    ),
                  ]),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DailyBarChart extends StatelessWidget {
  const _DailyBarChart({required this.daily});
  final List daily;

  @override
  Widget build(BuildContext context) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxY = daily.isEmpty ? 10.0 : daily.map((e) => (e as num).toDouble()).fold(1.0, (a, b) => a > b ? a : b);
    return BarChart(BarChartData(
      maxY: maxY + 1,
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (v, _) => Text(days[v.toInt() % 7], style: AppTypography.caption),
        )),
        leftTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      barGroups: List.generate(7, (i) {
        final val = i < daily.length ? (daily[i] as num).toDouble() : 0.0;
        return BarChartGroupData(x: i, barRods: [
          BarChartRodData(toY: val, color: AppColors.primary, width: 20, borderRadius: BorderRadius.circular(4)),
        ]);
      }),
    ));
  }
}

class _OverviewStats extends StatelessWidget {
  const _OverviewStats({required this.data});
  final Map<String, dynamic> data;
  @override
  Widget build(BuildContext context) {
    final stats = [
      ('Issued Tickets', '${data['total'] ?? 0}',     Icons.receipt_long_outlined,  AppColors.primary),
      ('Confirmed',      '${data['confirmed'] ?? 0}', Icons.check_circle_outline,   AppColors.success),
      ('Critical',       '${data['critical'] ?? 0}',  Icons.warning_amber_outlined, AppColors.danger),
      ('Dismissed',      '${data['dismissed'] ?? 0}', Icons.cancel_outlined,        AppColors.gray500),
    ];
    return GridView.count(
      crossAxisCount: 2, crossAxisSpacing: AppSpacing.sm, mainAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.7, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      children: stats.map((s) => AppCard(
        elevated: true,
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: s.$4.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(s.$3, size: 18, color: s.$4),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(s.$2, style: AppTypography.numeric(22, FontWeight.w700, color: s.$4)),
            Text(s.$1, style: AppTypography.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ]),
      )).toList(),
    );
  }
}

// ── Violations Tab ────────────────────────────────────────────────────────
class _ViolationsTab extends ConsumerWidget {
  const _ViolationsTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch period so changing it in Overview also refreshes this tab
    ref.watch(reportPeriodProvider);
    final async = ref.watch(officerAnalyticsProvider);
    return async.when(
      loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: SkeletonBox(height: 300, radius: 16)),
      error: (e, _) => ErrorRetry(message: e.toString(), onRetry: () => ref.invalidate(officerAnalyticsProvider)),
      data: (data) {
        final byType = (data['by_type'] as List?) ?? [];
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            AppCard(
              elevated: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Violations by Type', style: AppTypography.h3),
                  const SizedBox(height: AppSpacing.md),
                  if (byType.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: Text('No violations for this period'),
                    )
                  else
                    ...byType.cast<Map<String, dynamic>>().take(8).map((item) {
                      final name  = item['name']?.toString() ?? 'Unknown';
                      final count = (item['count'] ?? 0) as num;
                      final maxCount = (byType.cast<Map<String, dynamic>>()
                          .map((i) => (i['count'] ?? 0) as num)
                          .fold(0.0, (a, b) => a > b ? a : b.toDouble()));
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(child: Text(name, style: AppTypography.labelMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
                              Text('$count', style: AppTypography.numeric(14, FontWeight.w700, color: AppColors.primary)),
                            ]),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: maxCount > 0 ? count / maxCount : 0,
                                backgroundColor: AppColors.gray100,
                                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              elevated: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('By Severity', style: AppTypography.h3),
                  const SizedBox(height: AppSpacing.md),
                  Row(children: [
                    _SeverityBar(label: 'Critical', count: data['critical'] ?? 0, color: AppColors.danger),
                    const SizedBox(width: 8),
                    _SeverityBar(label: 'Major',    count: data['major']    ?? 0, color: AppColors.warning),
                    const SizedBox(width: 8),
                    _SeverityBar(label: 'Minor',    count: data['minor']    ?? 0, color: AppColors.info),
                  ]),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SeverityBar extends StatelessWidget {
  const _SeverityBar({required this.label, required this.count, required this.color});
  final String label;
  final num count;
  final Color color;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        Text('$count', style: AppTypography.numeric(20, FontWeight.w700, color: color)),
        Text(label, style: AppTypography.caption.copyWith(color: color)),
      ]),
    ),
  );
}

// ── Daily Tab ─────────────────────────────────────────────────────────────
class _DailyTab extends ConsumerWidget {
  const _DailyTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(officerDailyReportProvider);
    return async.when(
      loading: () => ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, __) => const SkeletonBox(height: 72, radius: 14)),
      error: (e, _) => ErrorRetry(message: e.toString(), onRetry: () => ref.invalidate(officerDailyReportProvider)),
      data: (report) => ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          // Date header
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF163A6E)]),
              borderRadius: AppRadius.radiusMd,
            ),
            child: Row(children: [
              const Icon(Icons.today_outlined, color: AppColors.white, size: 22),
              const SizedBox(width: AppSpacing.sm),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("Today's Report", style: AppTypography.h3.copyWith(color: AppColors.white)),
                Text(AppFormat.date(DateTime.now()),
                    style: AppTypography.bodySmall.copyWith(color: AppColors.white.withValues(alpha: 0.8))),
              ]),
            ]),
          ),
          const SizedBox(height: AppSpacing.md),
          ...[
            ('Tickets Issued',    Icons.receipt_long_outlined,    report['tickets_issued']  ?? 0, AppColors.primary),
            ('Fines Generated',   Icons.account_balance_outlined, report['fines_generated'] ?? 0, AppColors.success),
            ('Confirmed',         Icons.check_circle_outline,     report['confirmed']       ?? 0, AppColors.success),
            ('Dismissed',         Icons.cancel_outlined,          report['dismissed']       ?? 0, AppColors.gray500),
            ('Escalated Cases',   Icons.warning_amber_outlined,   report['escalated']       ?? 0, AppColors.danger),
            if ((report['sync_failures'] ?? 0) > 0)
              ('Sync Failures',   Icons.sync_problem_outlined,    report['sync_failures']   ?? 0, AppColors.warning),
          ].map((s) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: AppCard(
              elevated: true,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: (s.$4 as Color).withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(s.$2 as IconData, size: 18, color: s.$4 as Color),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(s.$1 as String, style: AppTypography.labelMedium)),
                Text('${s.$3}', style: AppTypography.numeric(20, FontWeight.w700, color: s.$4 as Color)),
              ]),
            ),
          )),
        ],
      ),
    );
  }
}
