import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_format.dart';
import '../../shared/widgets/state_widgets.dart';
import 'data/notifications_providers.dart';
import 'data/notifications_repository.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(notificationsListProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Notifications', style: AppTypography.h2)),
      body: listAsync.when(
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: 6,
          separatorBuilder: (_, __) => const SizedBox(height: 1),
          itemBuilder: (_, __) => const SkeletonBox(height: 68, radius: 0),
        ),
        error: (e, _) => ErrorRetry(
          message: e.toString(),
          onRetry: () => ref.invalidate(notificationsListProvider),
        ),
        data: (page) => page.results.isEmpty
            ? const EmptyState(
                icon: Icons.notifications_none_outlined,
                title: 'No Notifications',
                message: 'You are all caught up.',
              )
            : RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(notificationsListProvider),
                child: ListView.separated(
                  itemCount: page.results.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 64),
                  itemBuilder: (ctx, i) => _NotificationTile(
                    notification: page.results[i],
                    onTap: () async {
                      if (!page.results[i].isRead) {
                        await ref
                            .read(notificationsRepositoryProvider)
                            .markRead(page.results[i].id);
                        ref.invalidate(notificationsListProvider);
                      }
                    },
                  ),
                ),
              ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile(
      {required this.notification, required this.onTap});
  final AppNotification notification;
  final VoidCallback onTap;

  (IconData, Color) _iconForType() => switch (notification.type) {
        'VIOLATION_DETECTED' => (
            Icons.report_gmailerrorred_outlined,
            AppColors.danger
          ),
        'FINE_DUE' => (Icons.timer_outlined, AppColors.warning),
        'PAYMENT_CONFIRMED' => (
            Icons.check_circle_outline,
            AppColors.success
          ),
        'DISPUTE_UPDATE' => (Icons.gavel_outlined, AppColors.info),
        'TRAFFIC_ALERT' => (Icons.alt_route_outlined, AppColors.primary),
        _ => (Icons.notifications_none_outlined, AppColors.textSecondary),
      };

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _iconForType();
    final isUnread = !notification.isRead;
    return InkWell(
      onTap: onTap,
      child: Container(
        color: isUnread
            ? AppColors.primarySurface.withValues(alpha: 0.5)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: AppTypography.labelLarge.copyWith(
                              fontWeight: isUnread
                                  ? FontWeight.w700
                                  : FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  if (notification.message.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      notification.message,
                      style: AppTypography.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(AppFormat.relative(notification.createdAt),
                      style: AppTypography.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
