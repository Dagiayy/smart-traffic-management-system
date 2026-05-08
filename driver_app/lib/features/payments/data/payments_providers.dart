import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/models/app_user.dart';
import 'payment_models.dart';
import 'payments_repository.dart';

final paymentsRepositoryProvider = Provider<PaymentsRepository>((ref) {
  return PaymentsRepository(ref.watch(apiClientProvider));
});

final unpaidFinesProvider =
    FutureProvider.autoDispose<PaginatedResponse<Fine>>((ref) {
  return ref.watch(paymentsRepositoryProvider).getFines(status: 'UNPAID');
});

final allFinesProvider =
    FutureProvider.autoDispose<PaginatedResponse<Fine>>((ref) {
  return ref.watch(paymentsRepositoryProvider).getFines();
});

final receiptsProvider =
    FutureProvider.autoDispose<PaginatedResponse<Receipt>>((ref) {
  return ref.watch(paymentsRepositoryProvider).getReceipts();
});

// Selected fine IDs for multi-payment
final selectedFinesProvider = StateProvider<Set<String>>((ref) => const {});
