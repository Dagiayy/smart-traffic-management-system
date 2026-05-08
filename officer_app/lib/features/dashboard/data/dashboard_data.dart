import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

class OfficerSummary {
  final int ticketsToday;
  final int ticketsWeek;
  final int pendingSubmissions;
  final int unsyncedCount;
  final int confirmedViolations;
  final List<AlertItem> alerts;

  const OfficerSummary({
    this.ticketsToday = 0,
    this.ticketsWeek = 0,
    this.pendingSubmissions = 0,
    this.unsyncedCount = 0,
    this.confirmedViolations = 0,
    this.alerts = const [],
  });

  factory OfficerSummary.fromJson(Map<String, dynamic> j) => OfficerSummary(
        ticketsToday: j['tickets_today'] ?? j['total_violations_today'] ?? 0,
        ticketsWeek: j['tickets_week'] ?? 0,
        pendingSubmissions: j['pending_submissions'] ?? 0,
        unsyncedCount: j['unsynced_count'] ?? 0,
        confirmedViolations: j['confirmed_violations'] ?? 0,
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
    // Officer-specific summary — falls back to admin if officer endpoint not separate
    try {
      final res = await _api.get('/officer/tickets/', query: {'page_size': 1, 'date_from': _today()});
      final todayCount = (res.data as Map<String, dynamic>?)?['count'] ?? 0;
      final weekRes  = await _api.get('/officer/tickets/', query: {'page_size': 1, 'date_from': _weekAgo()});
      final weekCount = (weekRes.data as Map<String, dynamic>?)?['count'] ?? 0;
      final pendingRes = await _api.get('/officer/tickets/', query: {'page_size': 1, 'status': 'SUBMITTED'});
      final pendingCount = (pendingRes.data as Map<String, dynamic>?)?['count'] ?? 0;
      return OfficerSummary(ticketsToday: todayCount, ticketsWeek: weekCount, pendingSubmissions: pendingCount);
    } catch (_) {
      return const OfficerSummary();
    }
  }

  String _today() => DateTime.now().toIso8601String().substring(0, 10);
  String _weekAgo() => DateTime.now().subtract(const Duration(days: 7)).toIso8601String().substring(0, 10);
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) =>
    DashboardRepository(ref.watch(apiClientProvider)));

final dashboardSummaryProvider = FutureProvider.autoDispose<OfficerSummary>((ref) =>
    ref.watch(dashboardRepositoryProvider).getSummary());
