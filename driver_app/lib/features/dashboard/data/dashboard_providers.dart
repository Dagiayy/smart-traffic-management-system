import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import 'dashboard_models.dart';
import 'dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(apiClientProvider));
});

final dashboardSummaryProvider =
    FutureProvider.autoDispose<DashboardSummary>((ref) async {
  return ref.watch(dashboardRepositoryProvider).getSummary();
});

final recentActivityProvider =
    FutureProvider.autoDispose<List<ActivityItem>>((ref) async {
  return ref.watch(dashboardRepositoryProvider).getRecentActivity();
});

final smartInsightsProvider = Provider.autoDispose<List<SmartInsight>>((ref) {
  final asyncSummary = ref.watch(dashboardSummaryProvider);
  return asyncSummary.maybeWhen(
    data: (s) => ref.watch(dashboardRepositoryProvider).deriveInsights(s),
    orElse: () => const [],
  );
});
