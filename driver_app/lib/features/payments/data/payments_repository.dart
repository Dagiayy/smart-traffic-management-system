import '../../../core/network/api_client.dart';
import '../../../shared/models/app_user.dart';
import 'payment_models.dart';

class PaymentsRepository {
  PaymentsRepository(this._api);
  final ApiClient _api;

  Future<PaginatedResponse<Fine>> getFines({String? status}) async {
    final query = <String, dynamic>{};
    if (status != null) query['status'] = status;
    final res = await _api.get('/citizen/fines/', query: query);
    return PaginatedResponse.fromJson(
        res.data as Map<String, dynamic>, Fine.fromJson);
  }

  Future<Fine> getFine(String id) async {
    final res = await _api.get('/citizen/fines/$id/');
    return Fine.fromJson(res.data as Map<String, dynamic>);
  }

  /// POST /citizen/fines/{id}/pay/
  Future<Map<String, dynamic>> payFine(
      {required String fineId,
      required String paymentMethod,
      required String transactionRef}) async {
    final res = await _api.post('/citizen/fines/$fineId/pay/', data: {
      'payment_method': paymentMethod,
      'transaction_ref': transactionRef,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<PaginatedResponse<Receipt>> getReceipts() async {
    final res = await _api.get('/citizen/receipts/');
    return PaginatedResponse.fromJson(
        res.data as Map<String, dynamic>, Receipt.fromJson);
  }

  Future<Receipt> getReceipt(String id) async {
    final res = await _api.get('/citizen/receipts/$id/');
    return Receipt.fromJson(res.data as Map<String, dynamic>);
  }
}
