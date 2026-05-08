import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/models/app_user.dart';
import 'notifications_repository.dart';

final notificationsRepositoryProvider =
    Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(ref.watch(apiClientProvider));
});

final notificationsListProvider =
    FutureProvider.autoDispose<PaginatedResponse<AppNotification>>((ref) {
  return ref.watch(notificationsRepositoryProvider).getNotifications();
});
