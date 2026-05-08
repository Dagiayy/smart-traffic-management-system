import '../../../core/network/api_client.dart';
import '../../../shared/models/app_user.dart';

class AppNotification {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'].toString(),
        title: j['title'] ?? _defaultTitle(j['type']),
        message: j['message'] ?? j['body'] ?? '',
        type: j['type'] ?? 'GENERAL',
        isRead: j['is_read'] ?? j['read'] ?? false,
        createdAt:
            DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
      );

  static String _defaultTitle(dynamic type) => switch (type) {
        'VIOLATION_DETECTED' => 'New Violation Recorded',
        'FINE_DUE' => 'Fine Due Reminder',
        'PAYMENT_CONFIRMED' => 'Payment Confirmed',
        'DISPUTE_UPDATE' => 'Dispute Update',
        'TRAFFIC_ALERT' => 'Traffic Alert',
        _ => 'Notification',
      };
}

class NotificationsRepository {
  NotificationsRepository(this._api);
  final ApiClient _api;

  Future<PaginatedResponse<AppNotification>> getNotifications() async {
    final res = await _api.get('/citizen/notifications/');
    return PaginatedResponse.fromJson(
        res.data as Map<String, dynamic>, AppNotification.fromJson);
  }

  Future<void> markRead(String id) async {
    await _api.patch('/citizen/notifications/$id/read/');
  }
}
