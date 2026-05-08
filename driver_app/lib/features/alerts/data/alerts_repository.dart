import '../../../core/network/api_client.dart';
import '../../../core/utils/app_format.dart';

class TrafficAlert {
  final String id;
  final String title;
  final String message;
  final String type; // CONGESTION | ACCIDENT | MAINTENANCE | ADVISORY
  final String severity; // LOW | MEDIUM | HIGH | CRITICAL
  final double? lat;
  final double? lng;
  final String? locationName;
  final DateTime createdAt;
  final bool isActive;

  const TrafficAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.severity,
    this.lat,
    this.lng,
    this.locationName,
    required this.createdAt,
    this.isActive = true,
  });

  factory TrafficAlert.fromJson(Map<String, dynamic> j) => TrafficAlert(
        id: j['id'].toString(),
        title: j['title'] ?? j['type'] ?? 'Traffic Alert',
        message: j['message'] ?? j['description'] ?? '',
        type: j['type'] ?? 'ADVISORY',
        severity: j['severity'] ?? 'LOW',
        lat: AppFormat.parseNullableDouble(j['lat'] ?? j['latitude']),
        lng: AppFormat.parseNullableDouble(j['lng'] ?? j['longitude']),
        locationName: j['location_name'] ?? j['intersection']?['name'],
        createdAt:
            DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
        isActive: j['is_active'] ?? true,
      );
}

class AlertsRepository {
  AlertsRepository(this._api);
  final ApiClient _api;

  Future<List<TrafficAlert>> getAlerts({
    double? lat,
    double? lng,
    double radius = 5000,
  }) async {
    final query = <String, dynamic>{};
    if (lat != null) query['lat'] = lat;
    if (lng != null) query['lng'] = lng;
    query['radius'] = radius;

    final res = await _api.get('/citizen/traffic-alerts/', query: query);
    final data = res.data;
    final list = (data is Map && data['results'] is List)
        ? data['results'] as List
        : (data is List ? data : []);
    return list
        .whereType<Map<String, dynamic>>()
        .map(TrafficAlert.fromJson)
        .toList();
  }
}
