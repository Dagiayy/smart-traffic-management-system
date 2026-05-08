import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_format.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/state_widgets.dart';
import '../../shared/widgets/status_badge.dart';
import 'data/alerts_providers.dart';
import 'data/alerts_repository.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(trafficAlertsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Traffic Alerts', style: AppTypography.h2),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => ref.invalidate(trafficAlertsProvider),
          ),
        ],
      ),
      body: alertsAsync.when(
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: 5,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (_, __) => const SkeletonBox(height: 90, radius: 14),
        ),
        error: (e, _) => ErrorRetry(
          message: e.toString(),
          onRetry: () => ref.invalidate(trafficAlertsProvider),
        ),
        data: (alerts) {
          if (alerts.isEmpty) {
            return const EmptyState(
              icon: Icons.check_circle_outline,
              title: 'No Active Alerts',
              message:
                  'The central command center has not issued any active advisories for your area.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(trafficAlertsProvider),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              children: [
                // Command center banner
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: AppRadius.radiusMd,
                    border: Border.all(color: AppColors.primary.withValues(alpha:0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.broadcast_on_personal_outlined,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Live advisories from Traffic Command Center',
                          style: AppTypography.labelMedium
                              .copyWith(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                Text('Active Alerts (${alerts.length})',
                    style: AppTypography.h3),
                const SizedBox(height: AppSpacing.md),
                ...alerts.map((a) => Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _AlertCard(alert: a),
                    )),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert});
  final TrafficAlert alert;

  (Color bg, Color fg, IconData icon) _style() {
    return switch (alert.severity) {
      'CRITICAL' => (
          AppColors.dangerSurface,
          AppColors.dangerText,
          Icons.error_outline
        ),
      'HIGH' => (
          AppColors.warningSurface,
          AppColors.warningText,
          Icons.warning_amber_outlined
        ),
      'MEDIUM' => (
          AppColors.warningSurface,
          AppColors.warningText,
          Icons.info_outline
        ),
      _ => (
          AppColors.infoSurface,
          AppColors.infoText,
          Icons.info_outline
        ),
    };
  }

  StatusType _badgeType() => switch (alert.severity) {
        'CRITICAL' => StatusType.danger,
        'HIGH' => StatusType.warning,
        'MEDIUM' => StatusType.warning,
        _ => StatusType.info,
      };

  String _typeLabel() => switch (alert.type) {
        'CONGESTION' => 'Congestion',
        'ACCIDENT' => 'Accident',
        'MAINTENANCE' => 'Maintenance',
        _ => 'Advisory',
      };

  IconData _typeIcon() => switch (alert.type) {
        'CONGESTION' => Icons.traffic_outlined,
        'ACCIDENT' => Icons.warning_amber_outlined,
        'MAINTENANCE' => Icons.construction_outlined,
        _ => Icons.campaign_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = _style();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.radiusLg,
        border: Border.all(color: fg.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_typeIcon(), color: fg, size: 18),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                  child: Text(alert.title,
                      style: AppTypography.labelLarge.copyWith(color: fg),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis)),
              StatusBadge(
                label: _typeLabel(),
                type: _badgeType(),
                compact: true,
              ),
            ],
          ),
          if (alert.message.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(alert.message,
                style: AppTypography.bodyMedium.copyWith(color: fg)),
          ],
          if (alert.locationName != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(children: [
              Icon(Icons.location_on_outlined, size: 13, color: fg),
              const SizedBox(width: 4),
              Text(alert.locationName!,
                  style: AppTypography.bodySmall.copyWith(color: fg)),
            ]),
          ],
          const SizedBox(height: AppSpacing.xs),
          Text(AppFormat.relative(alert.createdAt),
              style: AppTypography.caption.copyWith(color: fg)),
        ],
      ),
    );
  }
}
