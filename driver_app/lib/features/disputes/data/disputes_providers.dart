import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/models/app_user.dart';
import 'disputes_repository.dart';

final disputesRepositoryProvider = Provider<DisputesRepository>((ref) {
  return DisputesRepository(ref.watch(apiClientProvider));
});

final disputesListProvider =
    FutureProvider.autoDispose<PaginatedResponse<Dispute>>((ref) {
  return ref.watch(disputesRepositoryProvider).getDisputes();
});
