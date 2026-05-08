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

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // System UI overlay style
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
    statusBarColor: const Color.fromRGBO(0, 0, 0, 0),
  ));

  // Initialize secure/shared storage before any widgets mount
  await AppStorage.instance.init();

  runApp(
    ProviderScope(
      overrides: [
        // Wire up the API client with the session-expired callback.
        // Using a ProviderContainer trick so we can call the auth notifier.
        apiClientProvider.overrideWith((ref) {
          return ApiClient(
            onSessionExpired: () {
              ref.read(authControllerProvider.notifier).forceLogout();
              AppRouter.router.go('/login');
            },
          );
        }),
      ],
      child: const CitizenApp(),
    ),
  );
}

class CitizenApp extends StatelessWidget {
  const CitizenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Citizen Traffic Compliance',
      theme: AppTheme.light,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
