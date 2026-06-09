import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/health_record_service.dart';
import 'service_providers.dart';

final healthRecordsProvider = FutureProvider.autoDispose<List<HealthRecordItem>>((ref) {
  return ref.watch(healthRecordServiceProvider).fetchAll();
});
