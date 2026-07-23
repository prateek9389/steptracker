import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stride_ai/models/daily_stat.dart';
import 'package:stride_ai/models/walk_session.dart';
import 'package:stride_ai/repositories/daily_stat_repository.dart';
import 'package:stride_ai/providers/auth_provider.dart';

class WeeklyAnalyticsState {
  final bool isLoading;
  final String? error;
  final List<DailyStat> currentWeekStats; // Mon - Sun
  final List<DailyStat> previousWeekStats; // Mon - Sun
  final List<WalkSession> currentWeekWalks;

  WeeklyAnalyticsState({
    this.isLoading = true,
    this.error,
    this.currentWeekStats = const [],
    this.previousWeekStats = const [],
    this.currentWeekWalks = const [],
  });

  WeeklyAnalyticsState copyWith({
    bool? isLoading,
    String? error,
    List<DailyStat>? currentWeekStats,
    List<DailyStat>? previousWeekStats,
    List<WalkSession>? currentWeekWalks,
  }) {
    return WeeklyAnalyticsState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      currentWeekStats: currentWeekStats ?? this.currentWeekStats,
      previousWeekStats: previousWeekStats ?? this.previousWeekStats,
      currentWeekWalks: currentWeekWalks ?? this.currentWeekWalks,
    );
  }

  // Aggregations for current week
  int get totalSteps => currentWeekStats.fold(0, (sum, stat) => sum + stat.steps);
  double get totalDistance => currentWeekStats.fold(0.0, (sum, stat) => sum + stat.distanceKm);
  int get totalCalories => currentWeekStats.fold(0, (sum, stat) => sum + stat.calories);
  int get totalActiveMinutes => currentWeekStats.fold(0, (sum, stat) => sum + stat.activeMinutes);

  // Aggregations for previous week
  int get prevTotalSteps => previousWeekStats.fold(0, (sum, stat) => sum + stat.steps);
  double get prevTotalDistance => previousWeekStats.fold(0.0, (sum, stat) => sum + stat.distanceKm);
  int get prevTotalCalories => previousWeekStats.fold(0, (sum, stat) => sum + stat.calories);
  int get prevTotalActiveMinutes => previousWeekStats.fold(0, (sum, stat) => sum + stat.activeMinutes);

  // Averages
  int get avgSteps => currentWeekStats.isEmpty ? 0 : totalSteps ~/ currentWeekStats.length;
  double get avgDistance => currentWeekStats.isEmpty ? 0.0 : totalDistance / currentWeekStats.length;
  int get avgCalories => currentWeekStats.isEmpty ? 0 : totalCalories ~/ currentWeekStats.length;

  double get avgPace {
    if (totalDistance == 0) return 0.0;
    return totalActiveMinutes / totalDistance;
  }

  double get avgSpeed {
    if (totalActiveMinutes == 0) return 0.0;
    return totalDistance / (totalActiveMinutes / 60.0);
  }

  // Comparisons
  double get stepsIncrease => prevTotalSteps == 0 ? 0.0 : ((totalSteps - prevTotalSteps) / prevTotalSteps) * 100;
  double get distanceIncrease => prevTotalDistance == 0 ? 0.0 : ((totalDistance - prevTotalDistance) / prevTotalDistance) * 100;
  double get caloriesIncrease => prevTotalCalories == 0 ? 0.0 : ((totalCalories - prevTotalCalories) / prevTotalCalories) * 100;
  double get activeTimeIncrease => prevTotalActiveMinutes == 0 ? 0.0 : ((totalActiveMinutes - prevTotalActiveMinutes) / prevTotalActiveMinutes) * 100;

  // Best Performance
  DailyStat? get bestDay {
    if (currentWeekStats.isEmpty) return null;
    return currentWeekStats.reduce((curr, next) => curr.steps > next.steps ? curr : next);
  }

  WalkSession? get longestWalk {
    if (currentWeekWalks.isEmpty) return null;
    return currentWeekWalks.reduce((curr, next) => curr.distanceKm > next.distanceKm ? curr : next);
  }

  DailyStat? get highestCaloriesDay {
    if (currentWeekStats.isEmpty) return null;
    return currentWeekStats.reduce((curr, next) => curr.calories > next.calories ? curr : next);
  }
}

class WeeklyAnalyticsNotifier extends StateNotifier<WeeklyAnalyticsState> {
  final Ref _ref;
  final DailyStatRepository _repository = DailyStatRepository();

  WeeklyAnalyticsNotifier(this._ref) : super(WeeklyAnalyticsState()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final uid = _ref.read(currentUserProvider)?.uid;
      if (uid == null) {
        state = state.copyWith(isLoading: false, error: 'Not logged in');
        return;
      }

      final now = DateTime.now();

      // Monday of current week
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final mondayMidnight = DateTime(monday.year, monday.month, monday.day);

      // Monday of previous week
      final prevMonday = mondayMidnight.subtract(const Duration(days: 7));

      // Fetch all daily stats
      final allStats = await _repository.getAllStatsBetween(uid, prevMonday, now);

      // Partition into current / previous week
      final currentWeekStats = allStats
          .where((s) => !s.date.isBefore(mondayMidnight))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      final previousWeekStats = allStats
          .where((s) => !s.date.isBefore(prevMonday) && s.date.isBefore(mondayMidnight))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      // Fetch this week's walk sessions
      final walkSessions = await _fetchCurrentWeekWalks(uid, mondayMidnight);

      state = state.copyWith(
        isLoading: false,
        currentWeekStats: currentWeekStats,
        previousWeekStats: previousWeekStats,
        currentWeekWalks: walkSessions,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<List<WalkSession>> _fetchCurrentWeekWalks(
      String uid, DateTime mondayMidnight) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('walk_sessions')
          .where('startTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(mondayMidnight))
          .where('trackingStatus', isEqualTo: 'completed')
          .orderBy('startTime', descending: true)
          .get();
      return snap.docs
          .map((doc) => WalkSession.fromJson(doc.data(), doc.id))
          .toList();
    } catch (_) {
      return [];
    }
  }
}

final weeklyAnalyticsProvider =
    StateNotifierProvider.autoDispose<WeeklyAnalyticsNotifier, WeeklyAnalyticsState>(
        (ref) {
  return WeeklyAnalyticsNotifier(ref);
});
