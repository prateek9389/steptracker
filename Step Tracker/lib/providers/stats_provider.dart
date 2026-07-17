import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stride_ai/models/daily_stat.dart';
import 'package:stride_ai/providers/auth_provider.dart';
import 'package:stride_ai/repositories/daily_stat_repository.dart';

final dailyStatRepositoryProvider = Provider<DailyStatRepository>((ref) {
  return DailyStatRepository();
});

final todayStatStreamProvider = StreamProvider<DailyStat?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);

  final todayStr = DateTime.now().toString().substring(0, 10);
  final repo = ref.watch(dailyStatRepositoryProvider);
  
  return repo.streamDailyStat(user.uid, todayStr);
});

final allDailyStatsStreamProvider = StreamProvider<List<DailyStat>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  final repo = ref.watch(dailyStatRepositoryProvider);
  return repo.streamAllDailyStats(user.uid);
});
