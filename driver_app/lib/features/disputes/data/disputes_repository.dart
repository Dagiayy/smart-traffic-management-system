import '../../../core/network/api_client.dart';
import '../../../shared/models/app_user.dart';

class Dispute {
  final String id;
  final String violationId;
  final String reason;
  final String description;
  final String status; // SUBMITTED | UNDER_REVIEW | APPROVED | REJECTED
  final DateTime createdAt;
  final String? adminFeedback;
  final String? decision;

  const Dispute({
    required this.id,
    required this.violationId,
    required this.reason,
    required this.description,
    required this.status,
    required this.createdAt,
    this.adminFeedback,
    this.decision,
  });

  factory Dispute.fromJson(Map<String, dynamic> j) => Dispute(
        id: j['id'].toString(),
        violationId: j['violation_ref']?.toString() ??
            j['violation']?.toString() ??
            j['violation_id']?.toString() ?? '',
        reason: j['reason'] ?? '',
        description: j['description'] ?? '',
        status: j['status'] ?? 'SUBMITTED',
        createdAt: DateTime.tryParse(
                j['submitted_at'] ?? j['created_at'] ?? '') ??
            DateTime.now(),
        adminFeedback: j['decision']?['reason'] ??
            j['admin_notes'] ?? j['feedback'],
        decision: j['decision']?['decision']?.toString(),
      );
}

class DisputesRepository {
  DisputesRepository(this._api);
  final ApiClient _api;

  Future<PaginatedResponse<Dispute>> getDisputes() async {
    final res = await _api.get('/citizen/disputes/');
    return PaginatedResponse.fromJson(
        res.data as Map<String, dynamic>, Dispute.fromJson);
  }

  Future<Dispute> submitDispute({
    required String violationId,
    required String reason,
    required String description,
  }) async {
    final res = await _api.post('/citizen/disputes/', data: {
      'violation_id': violationId,
      'reason': reason,
      'description': description,
    });
    return Dispute.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> withdrawDispute(String id) async {
    await _api.delete('/citizen/disputes/$id/');
  }
}
