import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/models/app_user.dart';
import 'violation_model.dart';
import 'violations_repository.dart';

final violationsRepositoryProvider = Provider<ViolationsRepository>((ref) {
  return ViolationsRepository(ref.watch(apiClientProvider));
});

// Holds current filter state
class ViolationFilters {
  final String? status;
  final String? severity;
  const ViolationFilters({this.status, this.severity});
  ViolationFilters copyWith({String? status, String? severity}) =>
      ViolationFilters(
        status: status ?? this.status,
        severity: severity ?? this.severity,
      );
}

final violationFiltersProvider =
    StateProvider<ViolationFilters>((ref) => const ViolationFilters());

final violationsListProvider =
    FutureProvider.autoDispose<PaginatedResponse<Violation>>((ref) {
  final filters = ref.watch(violationFiltersProvider);
  return ref.watch(violationsRepositoryProvider).getViolations(
        status: filters.status,
        severity: filters.severity,
      );
});

final violationDetailProvider =
    FutureProvider.autoDispose.family<Violation, String>((ref, id) {
  return ref.watch(violationsRepositoryProvider).getViolation(id);
});
