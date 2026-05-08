import '../../../core/network/api_client.dart';
import 'dashboard_models.dart';

class DashboardRepository {
  DashboardRepository(this._api);
  final ApiClient _api;

  /// GET /citizen/violations/summary/
  Future<DashboardSummary> getSummary() async {
    final res = await _api.get('/citizen/violations/summary/');
    return DashboardSummary.fromJson(res.data as Map<String, dynamic>);
  }

  /// Aggregates recent activity from the notifications endpoint as the timeline.
  /// In future, backend can expose a dedicated `/citizen/activity/` endpoint.
  Future<List<ActivityItem>> getRecentActivity({int limit = 8}) async {
    try {
      final res = await _api
          .get('/citizen/notifications/', query: {'page_size': limit});
      final data = res.data;
      final list = (data is Map && data['results'] is List)
          ? data['results'] as List
          : (data is List ? data : []);
      return list
          .whereType<Map<String, dynamic>>()
          .map((e) => ActivityItem.fromJson({
                'id': e['id'],
                'title': e['title'] ?? e['type'] ?? 'Notification',
                'subtitle': e['message'] ?? '',
                'timestamp': e['created_at'],
                'type': e['type'] ?? 'NOTIFICATION',
                'status': e['status'],
              }))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Smart insights — derived from summary data on the client.
  /// (Backend may later expose this as `/citizen/insights/`.)
  List<SmartInsight> deriveInsights(DashboardSummary summary) {
    final insights = <SmartInsight>[];

    if (summary.totalUnpaid > 0) {
      insights.add(SmartInsight(
        message:
            'You have ${summary.activeViolations} unpaid fine${summary.activeViolations == 1 ? '' : 's'} pending.',
        type: 'warning',
      ));
    }

    if (summary.complianceScore >= 90) {
      insights.add(const SmartInsight(
        message: 'Excellent driving record this month. Keep it up!',
        type: 'success',
      ));
    } else if (summary.complianceScore < 50) {
      insights.add(const SmartInsight(
        message:
            'Your compliance score is low. Review safe driving guidelines.',
        type: 'danger',
      ));
    }

    if (summary.activeViolations == 0 && summary.totalUnpaid == 0) {
      insights.add(const SmartInsight(
        message: 'No active violations. Your record is clean.',
        type: 'success',
      ));
    }

    return insights;
  }
}
