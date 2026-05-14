import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/models/app_user.dart';
import '../../violations/data/violation_model.dart';
import '../../violations/data/violations_repository.dart';
import 'disputes_repository.dart';

final disputesRepositoryProvider = Provider<DisputesRepository>((ref) {
  return DisputesRepository(ref.watch(apiClientProvider));
});

final disputesListProvider =
    FutureProvider.autoDispose<PaginatedResponse<Dispute>>((ref) {
  return ref.watch(disputesRepositoryProvider).getDisputes();
});

/// Loads the citizen's violations so the dispute form can offer a picker
/// instead of asking the user to type a UUID manually.
final disputeViolationsProvider =
    FutureProvider.autoDispose<List<Violation>>((ref) async {
  final repo = ViolationsRepository(ref.watch(apiClientProvider));
  final page = await repo.getViolations();
  return page.results;
});
