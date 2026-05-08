import '../../../core/network/api_client.dart';
import '../../../shared/models/app_user.dart';
import 'violation_model.dart';

class ViolationsRepository {
  ViolationsRepository(this._api);
  final ApiClient _api;

  Future<PaginatedResponse<Violation>> getViolations({
    String? status,
    String? severity,
    String? dateFrom,
    String? dateTo,
    String? type,
    int page = 1,
  }) async {
    final query = <String, dynamic>{};
    if (status != null) query['status'] = status;
    if (severity != null) query['severity'] = severity;
    if (dateFrom != null) query['date_from'] = dateFrom;
    if (dateTo != null) query['date_to'] = dateTo;
    if (type != null) query['type'] = type;
    query['page'] = page;

    final res = await _api.get('/citizen/violations/', query: query);
    return PaginatedResponse.fromJson(
        res.data as Map<String, dynamic>, Violation.fromJson);
  }

  Future<Violation> getViolation(String id) async {
    final res = await _api.get('/citizen/violations/$id/');
    return Violation.fromJson(res.data as Map<String, dynamic>);
  }
}
