import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_format.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/state_widgets.dart';
import '../../shared/widgets/status_badge.dart';
import '../auth/data/auth_providers.dart';
import 'data/dashboard_models.dart';
import 'data/dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final activityAsync = ref.watch(recentActivityProvider);
    final insights = ref.watch(smartInsightsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dashboardSummaryProvider);
            ref.invalidate(recentActivityProvider);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: [
              // ----- Header -----
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome back',
                            style: AppTypography.bodyMedium
                                .copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: 2),
                        Text(
                          user?.fullName.split(' ').first ?? 'Driver',
                          style: AppTypography.h2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _NotificationBell(
                    count: summaryAsync.maybeWhen(
                        data: (s) => s.unreadNotifications, orElse: () => 0),
                    onTap: () => context.push('/notifications'),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _AvatarButton(
                    initials: user?.initials ?? '?',
                    onTap: () => context.push('/profile'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // ----- Summary -----
              summaryAsync.when(
                loading: () => const _SummaryLoading(),
                error: (e, _) => ErrorRetry(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(dashboardSummaryProvider),
                ),
                data: (summary) => _SummarySection(summary: summary),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ----- Quick Actions -----
              Text('Quick Actions', style: AppTypography.h3),
              const SizedBox(height: AppSpacing.md),
              _QuickActions(),

              const SizedBox(height: AppSpacing.xl),

              // ----- Smart Insights -----
              if (insights.isNotEmpty) ...[
                Text('Insights', style: AppTypography.h3),
                const SizedBox(height: AppSpacing.md),
                ...insights.map((i) => Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _InsightCard(insight: i),
                    )),
                const SizedBox(height: AppSpacing.lg),
              ],

              // ----- Recent Activity -----
              Row(
                children: [
                  Text('Recent Activity', style: AppTypography.h3),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.push('/notifications'),
                    child: const Text('View all'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              activityAsync.when(
                loading: () => Column(
                  children: List.generate(
                    3,
                    (_) => const Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.sm),
                      child: SkeletonBox(height: 64, radius: 14),
                    ),
                  ),
                ),
                error: (_, __) => const SizedBox.shrink(),
                data: (items) => items.isEmpty
                    ? AppCard(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md),
                          child: Center(
                            child: Text(
                              'No recent activity',
                              style: AppTypography.bodyMedium
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                      )
                    : Column(
                        children: items
                            .take(5)
                            .map((a) => Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: AppSpacing.sm),
                                  child: _ActivityTile(item: a),
                                ))
                            .toList(),
                      ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Sub-widgets
// ============================================================================

class _AvatarButton extends StatelessWidget {
  const _AvatarButton({required this.initials, required this.onTap});
  final String initials;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: CircleAvatar(
        radius: 20,
        backgroundColor: AppColors.primarySurface,
        child: Text(initials,
            style: AppTypography.labelLarge
                .copyWith(color: AppColors.primary)),
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.notifications_none_outlined,
                  size: 20, color: AppColors.textPrimary),
              if (count > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryLoading extends StatelessWidget {
  const _SummaryLoading();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        SkeletonBox(height: 140, radius: 16),
        SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(child: SkeletonBox(height: 96, radius: 14)),
            SizedBox(width: AppSpacing.md),
            Expanded(child: SkeletonBox(height: 96, radius: 14)),
          ],
        ),
      ],
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.summary});
  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ComplianceCard(summary: summary),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _MiniStatCard(
                label: 'Unpaid Fines',
                value: AppFormat.currency(summary.totalUnpaid),
                icon: Icons.account_balance_wallet_outlined,
                tone: summary.totalUnpaid > 0
                    ? StatusType.danger
                    : StatusType.neutral,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _MiniStatCard(
                label: 'Active Violations',
                value: '${summary.activeViolations}',
                icon: Icons.report_outlined,
                tone: summary.activeViolations > 0
                    ? StatusType.warning
                    : StatusType.neutral,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ComplianceCard extends StatelessWidget {
  const _ComplianceCard({required this.summary});
  final DashboardSummary summary;

  Color _scoreColor() {
    if (summary.complianceScore >= 90) return AppColors.scoreExcellent;
    if (summary.complianceScore >= 75) return AppColors.scoreGood;
    if (summary.complianceScore >= 50) return AppColors.scoreWarning;
    return AppColors.scoreHighRisk;
  }

  StatusType _statusType() {
    switch (summary.driverStatus) {
      case 'HIGH_RISK':
        return StatusType.danger;
      case 'WARNING':
        return StatusType.warning;
      default:
        return StatusType.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: AppRadius.radiusLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Compliance Score',
                style: AppTypography.labelMedium.copyWith(
                    color: AppColors.white.withValues(alpha: 0.85)),
              ),
              const Spacer(),
              StatusBadge(
                label: summary.driverStatusLabel,
                type: _statusType(),
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${summary.complianceScore}',
                style: AppTypography.numeric(40, FontWeight.w700,
                    color: AppColors.white),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '/ 100',
                  style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.white.withValues(alpha: 0.7)),
                ),
              ),
              const Spacer(),
              Text(
                summary.scoreCategory,
                style: AppTypography.labelMedium
                    .copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: summary.complianceScore / 100,
              minHeight: 6,
              backgroundColor: AppColors.white.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.tone,
  });

  final String label;
  final String value;
  final IconData icon;
  final StatusType tone;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      StatusType.danger => AppColors.danger,
      StatusType.warning => AppColors.warning,
      StatusType.success => AppColors.success,
      _ => AppColors.primary,
    };
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(label,
              style: AppTypography.labelSmall
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(value,
              style: AppTypography.numeric(18, FontWeight.w700)),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      (Icons.payments_outlined, 'Pay Fine', '/payments'),
      (Icons.receipt_long_outlined, 'Violations', '/violations'),
      (Icons.gavel_outlined, 'Disputes', '/disputes'),
      (Icons.alt_route_outlined, 'Alerts', '/alerts'),
    ];
    return AppCard(
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md, horizontal: AppSpacing.xs),
      child: Row(
        children: actions.map((a) {
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => GoRouter.of(context).push(a.$3),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(a.$1, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(height: 8),
                    Text(a.$2,
                        style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});
  final SmartInsight insight;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = switch (insight.type) {
      'success' => (
          AppColors.successSurface,
          AppColors.successText,
          Icons.check_circle_outline
        ),
      'warning' => (
          AppColors.warningSurface,
          AppColors.warningText,
          Icons.info_outline
        ),
      'danger' => (
          AppColors.dangerSurface,
          AppColors.dangerText,
          Icons.error_outline
        ),
      _ => (AppColors.infoSurface, AppColors.infoText, Icons.lightbulb_outline),
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.radiusMd,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(insight.message,
                style: AppTypography.bodyMedium.copyWith(color: fg)),
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.item});
  final ActivityItem item;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (item.type) {
      'VIOLATION' => (Icons.report_gmailerrorred_outlined, AppColors.danger),
      'PAYMENT' => (Icons.check_circle_outline, AppColors.success),
      'DISPUTE' => (Icons.gavel_outlined, AppColors.warning),
      _ => (Icons.notifications_none_outlined, AppColors.primary),
    };

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: AppTypography.labelLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(item.subtitle,
                    style: AppTypography.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(AppFormat.relative(item.timestamp),
              style: AppTypography.caption),
        ],
      ),
    );
  }
}
