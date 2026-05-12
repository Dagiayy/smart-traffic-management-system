import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../storage/app_storage.dart';

typedef BulkSyncFn = Future<Map<String, dynamic>> Function(
    List<Map<String, dynamic>> tickets);

class AutoSyncService {
  AutoSyncService._();
  static final AutoSyncService instance = AutoSyncService._();

  GlobalKey<ScaffoldMessengerState>? _messengerKey;
  StreamSubscription<List<ConnectivityResult>>? _sub;
  BulkSyncFn? _syncFn;
  bool _running = false;

  /// Whether auto-sync is globally enabled (mirrors the user setting).
  bool enabled = true;

  void init({required GlobalKey<ScaffoldMessengerState> messengerKey}) {
    _messengerKey = messengerKey;
    enabled = AppStorage.instance.getAutoSync();
  }

  /// Start listening for connectivity changes and register the sync function.
  /// If there are queued items and connectivity is available right now, sync
  /// immediately.
  void start(BulkSyncFn syncFn) {
    _syncFn = syncFn;
    _sub?.cancel();

    _sub = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final connected = results
          .any((r) => r != ConnectivityResult.none);
      if (connected) {
        _trySync();
      }
    });

    // Also check connectivity immediately
    _checkAndSyncNow();
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }

  Future<void> _checkAndSyncNow() async {
    final results = await Connectivity().checkConnectivity();
    final connected = results.any((r) => r != ConnectivityResult.none);
    if (connected) {
      _trySync();
    }
  }

  /// Trigger a sync pass (ignoring if one is already in progress or disabled).
  Future<void> _trySync() async {
    if (!enabled) return;
    if (_running) return;
    if (_syncFn == null) return;

    final queue = AppStorage.instance.getOfflineQueue();
    if (queue.isEmpty) return;

    _running = true;
    try {
      final result = await _syncFn!(queue);
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

      // Record last sync time
      await AppStorage.instance
          .setLastSyncTime(DateTime.now().toIso8601String());

      if (failed.isNotEmpty) {
        _showSnackBar(
          '${failed.length} ticket(s) failed to sync. Tap Sync Status to retry.',
          isError: true,
        );
      }
    } catch (e) {
      _showSnackBar('Auto-sync failed: $e', isError: true);
    } finally {
      _running = false;
    }
  }

  /// Public method to manually trigger a sync (e.g., "Retry Sync Now" button).
  Future<void> triggerSync() => _trySync();

  void _showSnackBar(String message, {bool isError = false}) {
    final messenger = _messengerKey?.currentState;
    if (messenger == null) return;
    messenger.showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red[700] : Colors.green[700],
      duration: const Duration(seconds: 4),
    ));
  }
}
