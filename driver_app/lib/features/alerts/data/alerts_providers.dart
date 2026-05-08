import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import 'alerts_repository.dart';

final alertsRepositoryProvider = Provider<AlertsRepository>((ref) {
  return AlertsRepository(ref.watch(apiClientProvider));
});

final trafficAlertsProvider =
    FutureProvider.autoDispose<List<TrafficAlert>>((ref) {
  return ref.watch(alertsRepositoryProvider).getAlerts();
});
