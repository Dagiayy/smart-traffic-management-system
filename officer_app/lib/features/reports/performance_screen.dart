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
    final res = await ref.watch(apiClientProvider).get('/admin/analytics/officer-performance/');
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
      appBar: AppBar(title: const Text('My Performance')),
      body: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Column(children: [SkeletonBox(height: 120, radius: 14), SizedBox(height: 12), SkeletonBox(height: 200, radius: 14)]),
        ),
        error: (e, _) => ErrorRetry(message: e.toString(), onRetry: () => ref.invalidate(performanceProvider)),
        data: (data) => ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            // Stats row
            Row(children: [
              _StatCard('Today',  '${data['tickets_today'] ?? 0}',   Icons.today_outlined,     AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              _StatCard('Week',   '${data['tickets_week'] ?? 0}',    Icons.date_range_outlined, AppColors.accent),
              const SizedBox(width: AppSpacing.sm),
              _StatCard('Total',  '${data['tickets_total'] ?? 0}',   Icons.bar_chart_outlined,  AppColors.success),
            ]),
            const SizedBox(height: AppSpacing.md),
            Row(children: [
              _StatCard('Accuracy', '${data['accuracy_pct'] ?? 0}%', Icons.verified_outlined,   AppColors.success),
              const SizedBox(width: AppSpacing.sm),
              _StatCard('Pending',  '${data['pending'] ?? 0}',       Icons.pending_outlined,    AppColors.warning),
              const SizedBox(width: AppSpacing.sm),
              _StatCard('Rejected', '${data['rejected'] ?? 0}',      Icons.cancel_outlined,     AppColors.danger),
            ]),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              elevated: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Weekly Activity', style: AppTypography.h3),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    height: 160,
                    child: BarChart(
                      BarChartData(
                        maxY: 15,
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, _) => Text(['M','T','W','T','F','S','S'][v.toInt() % 7],
                                style: AppTypography.caption),
                          )),
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        barGroups: List.generate(7, (i) {
                          final weeklyData = (data['weekly'] as List?) ?? [3, 5, 7, 4, 6, 2, 8];
                          final val = i < weeklyData.length ? (weeklyData[i] as num).toDouble() : 0.0;
                          return BarChartGroupData(x: i, barRods: [
                            BarChartRodData(toY: val, color: AppColors.primary, width: 18, borderRadius: BorderRadius.circular(4)),
                          ]);
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
