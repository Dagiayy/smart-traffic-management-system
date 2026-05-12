import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/app_storage.dart';

class OfficerSummary {
  final int ticketsToday;
  final int ticketsWeek;
  final int pendingSubmissions;
  final int unsyncedCount;
  final int confirmedViolations;
  final int submittedCount;
  final int totalTickets;
  final List<AlertItem> alerts;

  const OfficerSummary({
    this.ticketsToday = 0,
    this.ticketsWeek = 0,
    this.pendingSubmissions = 0,
    this.unsyncedCount = 0,
    this.confirmedViolations = 0,
    this.submittedCount = 0,
    this.totalTickets = 0,
    this.alerts = const [],
  });

  factory OfficerSummary.fromJson(Map<String, dynamic> j, {int offlineCount = 0}) => OfficerSummary(
        ticketsToday: j['tickets_today'] ?? 0,
        ticketsWeek: j['tickets_week'] ?? 0,
        pendingSubmissions: j['pending_submissions'] ?? 0,
        unsyncedCount: offlineCount,
        confirmedViolations: j['confirmed_count'] ?? 0,
        submittedCount: j['submitted_count'] ?? 0,
        totalTickets: j['total_tickets'] ?? 0,
        alerts: ((j['alerts'] as List?) ?? [])
            .whereType<Map<String, dynamic>>()
            .map(AlertItem.fromJson)
            .toList(),
      );
}

class AlertItem {
  final String id;
  final String message;
  final String type;
  final DateTime createdAt;

  const AlertItem({required this.id, required this.message, required this.type, required this.createdAt});

  factory AlertItem.fromJson(Map<String, dynamic> j) => AlertItem(
        id: j['id'].toString(),
        message: j['message'] ?? j['title'] ?? '',
        type: j['type'] ?? 'INFO',
        createdAt: DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
      );
}

class DashboardRepository {
  DashboardRepository(this._api);
  final ApiClient _api;

  Future<OfficerSummary> getSummary() async {
    final offlineCount = AppStorage.instance.getOfflineQueue().length;
    try {
      final res = await _api.get('/officer/dashboard/');
      final data = res.data as Map<String, dynamic>? ?? {};
      return OfficerSummary.fromJson(data, offlineCount: offlineCount);
    } catch (_) {
      return OfficerSummary(unsyncedCount: offlineCount);
    }
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) =>
    DashboardRepository(ref.watch(apiClientProvider)));

final dashboardSummaryProvider = FutureProvider.autoDispose<OfficerSummary>((ref) =>
    ref.watch(dashboardRepositoryProvider).getSummary());
