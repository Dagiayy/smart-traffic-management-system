import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/shared_widgets.dart';

final performanceProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  try {
    final res = await ref.watch(apiClientProvider).get('/officer/performance/');
    final data = res.data;
    return data is Map<String, dynamic> ? data : {};
  } catch (_) { return {}; }
});

class PerformanceScreen extends ConsumerWidget {
  const PerformanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(performanceProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Performance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => ref.invalidate(performanceProvider),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Column(children: [
            SkeletonBox(height: 120, radius: 14), SizedBox(height: 12),
            SkeletonBox(height: 120, radius: 14), SizedBox(height: 12),
            SkeletonBox(height: 200, radius: 14),
          ]),
        ),
        error: (e, _) => ErrorRetry(message: e.toString(), onRetry: () => ref.invalidate(performanceProvider)),
        data: (data) => ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            // ── Rank & Progress Card ──────────────────────────────────────
            AppCard(
              elevated: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.emoji_events_outlined,
                        color: Color(0xFFD97706), size: 22),
                    const SizedBox(width: 8),
                    Text('Rank & Progress', style: AppTypography.h3),
                  ]),
                  const SizedBox(height: AppSpacing.md),

                  // Rank
                  if (data['rank'] != null)
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFD97706)),
                        ),
                        child: Text(
                          '#${data['rank']} This Month',
                          style: AppTypography.labelMedium
                              .copyWith(color: const Color(0xFF92400E)),
                        ),
                      ),
                    ]),
                  const SizedBox(height: AppSpacing.sm),

                  // Monthly progress bar
                  Row(children: [
                    const Icon(Icons.flag_outlined,
                        size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${data['month_progress'] ?? 0} / ${data['monthly_target'] ?? 20} tickets this month',
                        style: AppTypography.bodySmall,
                      ),
                    ),
                    Text(
                      '${(((data['month_progress'] ?? 0) as num) / ((data['monthly_target'] ?? 20) as num) * 100).clamp(0, 100).round()}%',
                      style: AppTypography.labelSmall
                          .copyWith(color: AppColors.primary),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (((data['month_progress'] ?? 0) as num) /
                              ((data['monthly_target'] ?? 20) as num))
                          .clamp(0.0, 1.0)
                          .toDouble(),
                      backgroundColor: AppColors.gray100,
                      valueColor:
                          const AlwaysStoppedAnimation(AppColors.primary),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Streak
                  Row(children: [
                    const Text('🔥',
                        style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      '${data['streak'] ?? 0} day streak',
                      style: AppTypography.labelMedium
                          .copyWith(color: AppColors.warning),
                    ),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Top stat cards ─────────────────────────────────────────────
            Row(children: [
              _StatCard('Today',  '${data['tickets_today'] ?? 0}',  Icons.today_outlined,      AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              _StatCard('Week',   '${data['tickets_week'] ?? 0}',   Icons.date_range_outlined,  AppColors.accent),
              const SizedBox(width: AppSpacing.sm),
              _StatCard('Total',  '${data['tickets_total'] ?? 0}',  Icons.bar_chart_outlined,   AppColors.success),
            ]),
            const SizedBox(height: AppSpacing.sm),
            Row(children: [
              _StatCard('Accuracy', '${data['accuracy_pct'] ?? 0}%', Icons.verified_outlined,  AppColors.success),
              const SizedBox(width: AppSpacing.sm),
              _StatCard('Pending',  '${data['pending'] ?? 0}',       Icons.pending_outlined,   AppColors.warning),
              const SizedBox(width: AppSpacing.sm),
              _StatCard('Rejected', '${data['rejected'] ?? 0}',      Icons.cancel_outlined,    AppColors.danger),
            ]),
            const SizedBox(height: AppSpacing.lg),

            // Accuracy progress card
            AppCard(
              elevated: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.verified_outlined, color: AppColors.success, size: 20),
                    const SizedBox(width: 8),
                    Text('Confirmation Rate', style: AppTypography.h3),
                    const Spacer(),
                    Text('${data['accuracy_pct'] ?? 0}%',
                        style: AppTypography.numeric(18, FontWeight.w700, color: AppColors.success)),
                  ]),
                  const SizedBox(height: AppSpacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: ((data['accuracy_pct'] ?? 0) as num) / 100,
                      backgroundColor: AppColors.gray100,
                      valueColor: const AlwaysStoppedAnimation(AppColors.success),
                      minHeight: 10,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text('${data['confirmed'] ?? 0} of ${data['tickets_total'] ?? 0} tickets confirmed by supervisor',
                      style: AppTypography.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Weekly bar chart
            AppCard(
              elevated: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Weekly Activity', style: AppTypography.h3),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    height: 160,
                    child: _WeeklyChart(weekly: (data['weekly'] as List?) ?? []),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Summary breakdown
            AppCard(
              elevated: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Status Breakdown', style: AppTypography.h3),
                  const Divider(height: AppSpacing.md),
                  ...[
                    ('Total Tickets',   data['tickets_total'] ?? 0, AppColors.primary),
                    ('Confirmed',       data['confirmed']     ?? 0, AppColors.success),
                    ('Pending Review',  data['pending']       ?? 0, AppColors.warning),
                    ('Rejected',        data['rejected']      ?? 0, AppColors.danger),
                  ].map((row) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Row(children: [
                      Container(width: 10, height: 10,
                          decoration: BoxDecoration(color: row.$3, shape: BoxShape.circle)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(row.$1, style: AppTypography.bodyMedium)),
                      Text('${row.$2}',
                          style: AppTypography.numeric(16, FontWeight.w700, color: row.$3)),
                    ]),
                  )),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Top Violation Type
            if (data['top_violation'] != null)
              AppCard(
                elevated: true,
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.gavel_outlined,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Most Issued Violation', style: AppTypography.labelMedium),
                      Text('${data['top_violation']}',
                          style: AppTypography.bodySmall,
                          overflow: TextOverflow.ellipsis),
                    ],
                  )),
                ]),
              ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.weekly});
  final List weekly;

  @override
  Widget build(BuildContext context) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxY = weekly.isEmpty ? 5.0
        : weekly.map((e) => (e as num).toDouble()).fold(1.0, (a, b) => a > b ? a : b) + 1;
    return BarChart(BarChartData(
      maxY: maxY,
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
        final val = i < weekly.length ? (weekly[i] as num).toDouble() : 0.0;
        return BarChartGroupData(x: i, barRods: [
          BarChartRodData(toY: val, color: AppColors.primary, width: 18, borderRadius: BorderRadius.circular(4)),
        ]);
      }),
    ));
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(this.label, this.value, this.icon, this.color);
  final String label, value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Expanded(
    child: AppCard(
      elevated: true,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(value, style: AppTypography.numeric(18, FontWeight.w700, color: color)),
        Text(label, style: AppTypography.caption, textAlign: TextAlign.center),
      ]),
    ),
  );
}
