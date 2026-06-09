import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification_model.dart';
import 'service_providers.dart';

final notificationsProvider = FutureProvider.autoDispose<List<NotificationModel>>((ref) {
  return ref.watch(notificationServiceProvider).fetchAll();
});

final notificationsReadProvider = StateProvider<Set<String>>((_) => {});
