import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/network/api_client.dart';
import 'core/router/app_router.dart';
import 'core/storage/app_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_providers.dart';

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
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Traffic Police Field Enforcement',
      theme: AppTheme.light,
      routerConfig: _config.router,
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
