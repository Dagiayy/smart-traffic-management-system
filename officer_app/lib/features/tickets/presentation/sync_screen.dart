import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/app_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/shared_widgets.dart';
import '../../tickets/data/ticket_data.dart';

class SyncScreen extends ConsumerStatefulWidget {
  const SyncScreen({super.key});
  @override
  ConsumerState<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends ConsumerState<SyncScreen> {
  bool _syncing = false;
  Map<String, String> _results = {};

  Future<void> _syncAll() async {
    final queue = ref.read(offlineQueueProvider);
    if (queue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nothing to sync')));
      return;
    }
    setState(() { _syncing = true; _results = {}; });
    try {
      final repo = ref.read(ticketsRepositoryProvider);
      final result = await repo.bulkSync(queue);
      debugPrint('Bulk sync result: $result'); // Add this line for debugging
      final synced = (result['synced'] as List? ?? []).map((e) => e.toString()).toList();
      final failed = (result['failed'] as List? ?? []).map((e) => e.toString()).toList();
      // Remove synced from queue
      for (final id in synced) { await AppStorage.instance.removeFromOfflineQueue(id); }
      ref.invalidate(offlineQueueProvider);
      ref.invalidate(ticketsListProvider);
      setState(() {
        _results = {for (var id in synced) id: 'synced', for (var id in failed) id: 'failed'};
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${synced.length} synced, ${failed.length} failed')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sync failed: $e')));
    } finally { if (mounted) setState(() => _syncing = false); }
  }

  @override
  Widget build(BuildContext context) {
    final queue = ref.watch(offlineQueueProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Sync Manager')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          // Status card
          AppCard(
            elevated: true,
            color: queue.isEmpty ? AppColors.successSurface : AppColors.warningSurface,
            child: Row(
              children: [
                Icon(queue.isEmpty ? Icons.cloud_done_outlined : Icons.cloud_upload_outlined,
                    color: queue.isEmpty ? AppColors.success : AppColors.warning, size: 28),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(queue.isEmpty ? 'All Synced' : '${queue.length} Pending',
                          style: AppTypography.h3.copyWith(
                              color: queue.isEmpty ? AppColors.success : AppColors.warning)),
                      Text(queue.isEmpty ? 'No offline records pending upload.'
                          : 'These records were created offline and need to be uploaded.',
                          style: AppTypography.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (queue.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Sync All Records',
              icon: Icons.sync_outlined,
              loading: _syncing,
              onPressed: _syncing ? null : _syncAll,
            ),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader('PENDING RECORDS'),
            const SizedBox(height: AppSpacing.sm),
            ...queue.map((t) {
              final lid = t['local_id']?.toString() ?? '';
              final result = _results[lid];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: AppCard(
                  child: Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: result == 'synced' ? AppColors.successSurface
                            : result == 'failed' ? AppColors.dangerSurface
                            : AppColors.warningSurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        result == 'synced' ? Icons.check_circle_outline
                            : result == 'failed' ? Icons.error_outline
                            : Icons.hourglass_top_outlined,
                        size: 18,
                        color: result == 'synced' ? AppColors.success
                            : result == 'failed' ? AppColors.danger
                            : AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(t['plate_number']?.toString() ?? 'Ticket', style: AppTypography.labelLarge),
                        Text(t['created_at']?.toString().substring(0, 10) ?? 'Offline', style: AppTypography.bodySmall),
                      ]),
                    ),
                    SyncBadge(status: result == 'synced' ? 'SYNCED' : result == 'failed' ? 'FAILED' : 'PENDING_SYNC'),
                  ]),
                ),
              );
            }),
          ],
          if (queue.isEmpty)
            const EmptyState(icon: Icons.cloud_done_outlined, title: 'All Synced',
                message: 'All offline records have been uploaded to the central system.'),
        ],
      ),
    );
  }
}
