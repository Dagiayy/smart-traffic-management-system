import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/auto_sync_service.dart';
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
  bool _retrying = false;
  List<ConnectivityResult> _connectivity = [ConnectivityResult.none];

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    if (mounted) setState(() => _connectivity = results);
  }

  bool get _isConnected =>
      _connectivity.any((r) => r != ConnectivityResult.none);

  String get _connectivityLabel {
    if (_connectivity.contains(ConnectivityResult.wifi)) return 'Wi-Fi';
    if (_connectivity.contains(ConnectivityResult.mobile)) return 'Mobile Data';
    if (_connectivity.contains(ConnectivityResult.ethernet)) return 'Ethernet';
    return 'Offline';
  }

  Future<void> _retrySync() async {
    final queue = ref.read(offlineQueueProvider);
    if (queue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nothing to sync')));
      return;
    }
    setState(() => _retrying = true);
    try {
      final repo = ref.read(ticketsRepositoryProvider);
      final result = await repo.bulkSync(queue);
      final synced = (result['synced'] as List? ?? [])
          .where((e) => e != null)
          .map((e) => e.toString())
          .toList();
      final failed = (result['failed'] as List? ?? [])
          .where((e) => e != null)
          .map((e) => e.toString())
          .toList();
      for (final id in synced) {
        await AppStorage.instance.removeFromOfflineQueue(id);
      }
      await AppStorage.instance
          .setLastSyncTime(DateTime.now().toIso8601String());
      ref.read(offlineQueueProvider.notifier).state =
          AppStorage.instance.getOfflineQueue();
      ref.invalidate(ticketsListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${synced.length} synced, ${failed.length} failed')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Sync failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  String? _lastSyncFormatted() {
    final raw = AppStorage.instance.getLastSyncTime();
    if (raw == null) return null;
    final dt = DateTime.tryParse(raw);
    if (dt == null) return null;
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final queue = ref.watch(offlineQueueProvider);
    final lastSync = _lastSyncFormatted();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Sync Status')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          // Auto-sync status card
          AppCard(
            elevated: true,
            color: AppColors.primarySurface,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                      color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.sync_outlined,
                      color: AppColors.white, size: 20),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Auto-sync is active',
                          style: AppTypography.labelLarge
                              .copyWith(color: AppColors.primary)),
                      Text(
                        'Connectivity: $_connectivityLabel'
                        '${lastSync != null ? '  •  Last sync: $lastSync' : ''}',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
                Icon(
                  _isConnected ? Icons.wifi : Icons.wifi_off,
                  color: _isConnected ? AppColors.success : AppColors.danger,
                  size: 20,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Queue count card
          AppCard(
            elevated: true,
            color: queue.isEmpty ? AppColors.successSurface : AppColors.warningSurface,
            child: Row(
              children: [
                Icon(
                    queue.isEmpty
                        ? Icons.cloud_done_outlined
                        : Icons.cloud_upload_outlined,
                    color: queue.isEmpty ? AppColors.success : AppColors.warning,
                    size: 28),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          queue.isEmpty
                              ? 'All Synced'
                              : '${queue.length} Pending',
                          style: AppTypography.h3.copyWith(
                              color: queue.isEmpty
                                  ? AppColors.success
                                  : AppColors.warning)),
                      Text(
                          queue.isEmpty
                              ? 'No offline records pending upload.'
                              : 'Records waiting to be uploaded to the central system.',
                          style: AppTypography.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (queue.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Retry Sync Now',
              icon: Icons.sync_outlined,
              variant: AppButtonVariant.secondary,
              loading: _retrying,
              onPressed: _retrying ? null : _retrySync,
            ),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader('PENDING RECORDS'),
            const SizedBox(height: AppSpacing.sm),
            ...queue.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: AppCard(
                child: Row(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.warningSurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.hourglass_top_outlined,
                        size: 18, color: AppColors.warning),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(t['plate_number']?.toString() ?? 'Ticket',
                          style: AppTypography.labelLarge),
                      Text(
                          t['created_at']?.toString().length != null &&
                                  (t['created_at']?.toString().length ?? 0) >=
                                      10
                              ? t['created_at'].toString().substring(0, 10)
                              : 'Offline',
                          style: AppTypography.bodySmall),
                    ]),
                  ),
                  const SyncBadge(status: 'PENDING_SYNC'),
                ]),
              ),
            )),
          ],

          if (queue.isEmpty)
            const EmptyState(
              icon: Icons.cloud_done_outlined,
              title: 'All records synced',
              message:
                  'All offline records have been uploaded to the central system.',
            ),
        ],
      ),
    );
  }
}
