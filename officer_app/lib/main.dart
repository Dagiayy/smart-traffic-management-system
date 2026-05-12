import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/network/api_client.dart';
import 'core/router/app_router.dart';
import 'core/services/auto_sync_service.dart';
import 'core/storage/app_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_providers.dart';
import 'features/tickets/data/ticket_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  await AppStorage.instance.init();

  runApp(const ProviderScope(child: OfficerApp()));
}

class OfficerApp extends ConsumerStatefulWidget {
  const OfficerApp({super.key});
  @override
  ConsumerState<OfficerApp> createState() => _OfficerAppState();
}

class _OfficerAppState extends ConsumerState<OfficerApp> {
  late final GoRouterConfig _config;

  static final messengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _config = AppRouter.buildRouterConfig(ref);
    // Wire the session-expiry callback. Uses the global setter in api_client.dart
    // to avoid circular imports.
    setSessionExpiredHandler(() {
      ref.read(authControllerProvider.notifier).forceLogout();
      _config.router.go('/login');
    });

    // Init AutoSyncService and schedule first sync after first frame
    AutoSyncService.instance.init(messengerKey: messengerKey);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoSync());
  }

  void _startAutoSync() {
    final repo = ref.read(ticketsRepositoryProvider);
    AutoSyncService.instance.start((tickets) async {
      final result = await repo.bulkSync(tickets);
      final synced = (result['synced'] as List? ?? [])
          .where((e) => e != null)
          .map((e) => e.toString())
          .toList();
      for (final id in synced) {
        await AppStorage.instance.removeFromOfflineQueue(id);
      }
      // Refresh the offline queue provider state
      ref.read(offlineQueueProvider.notifier).state =
          AppStorage.instance.getOfflineQueue();
      ref.invalidate(ticketsListProvider);
      return result;
    });
  }

  @override
  void dispose() {
    AutoSyncService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Traffic Police Field Enforcement',
      theme: AppTheme.light,
      routerConfig: _config.router,
      scaffoldMessengerKey: messengerKey,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(
            MediaQuery.of(context).textScaler.scale(1.0).clamp(1.0, 1.3),
          ),
        ),
        child: child!,
      ),
    );
  }
}
