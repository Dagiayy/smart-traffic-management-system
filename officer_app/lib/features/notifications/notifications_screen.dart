import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_format.dart';
import '../../shared/models/app_user.dart';
import '../../shared/widgets/shared_widgets.dart';

class _Notification {
  final String id, title, message, type;
  final bool isRead;
  final DateTime createdAt;
  const _Notification({required this.id, required this.title, required this.message, required this.type, required this.isRead, required this.createdAt});
  factory _Notification.fromJson(Map<String, dynamic> j) => _Notification(
    id: j['id'].toString(), title: j['title'] ?? 'Notification',
    message: j['message'] ?? j['body'] ?? '', type: j['type'] ?? 'GENERAL',
    isRead: j['is_read'] ?? false, createdAt: DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
  );
}

final notificationsProvider = FutureProvider.autoDispose<PaginatedResponse<_Notification>>((ref) async {
  final res = await ref.watch(apiClientProvider).get('/citizen/notifications/');
  return PaginatedResponse.fromJson(res.data as Map<String, dynamic>, _Notification.fromJson);
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Notifications')),
      body: async.when(
        loading: () => ListView.separated(padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: 6, separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, __) => const SkeletonBox(height: 64, radius: 0)),
        error: (e, _) => ErrorRetry(message: e.toString(), onRetry: () => ref.invalidate(notificationsProvider)),
        data: (page) => page.results.isEmpty
            ? const EmptyState(icon: Icons.notifications_none_outlined, title: 'No Notifications', message: 'You are up to date.')
            : ListView.separated(
                itemCount: page.results.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 64),
                itemBuilder: (_, i) {
                  final n = page.results[i];
                  final (icon, color) = switch (n.type) {
                    'VIOLATION_DETECTED' => (Icons.report_outlined,         AppColors.danger),
                    'SYNC_REQUIRED'      => (Icons.sync_outlined,           AppColors.warning),
                    'SUPERVISOR_REVIEW'  => (Icons.find_in_page_outlined,   AppColors.info),
                    'POLICY_UPDATE'      => (Icons.policy_outlined,         AppColors.primary),
                    _                   => (Icons.notifications_outlined,   AppColors.textSecondary),
                  };
                  return Container(
                    color: !n.isRead ? AppColors.primarySurface.withValues(alpha: 0.5) : Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                        child: Icon(icon, size: 18, color: color),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(child: Text(n.title, style: AppTypography.labelLarge.copyWith(
                              fontWeight: !n.isRead ? FontWeight.w700 : FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          if (!n.isRead) Container(width: 8, height: 8,
                              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                        ]),
                        if (n.message.isNotEmpty) Text(n.message, style: AppTypography.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                        Text(AppFormat.relative(n.createdAt), style: AppTypography.caption),
                      ])),
                    ]),
                  );
                },
              ),
      ),
    );
  }
}
