import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stride_ai/models/daily_stat.dart';
import 'package:stride_ai/models/walk_session.dart';
import 'package:stride_ai/repositories/daily_stat_repository.dart';
import 'package:stride_ai/providers/auth_provider.dart';
import 'package:stride_ai/providers/walk_provider.dart';
import 'package:stride_ai/providers/stats_provider.dart';

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
  DateTime _currentDate = DateTime.now();

  WeeklyAnalyticsNotifier(this._ref) : super(WeeklyAnalyticsState()) {
    _init();
  }

  void _init() {
    final now = DateTime(2026, 7, 12); // Sunday, 12 Jul 2026
    _currentDate = now;
    final startOfWeek = DateTime(2026, 7, 6);

    // Current Week Demo Data
    final currentWeekStats = [
      DailyStat(dateId: '2026-7-6', uid: 'demo', steps: 8245, distanceKm: 6.3, calories: 352, walkingTimeSeconds: 78 * 60, activeMinutes: 78, goalCompleted: false, date: DateTime(2026, 7, 6)),
      DailyStat(dateId: '2026-7-7', uid: 'demo', steps: 9100, distanceKm: 6.5, calories: 390, walkingTimeSeconds: 72 * 60, activeMinutes: 72, goalCompleted: false, date: DateTime(2026, 7, 7)),
      DailyStat(dateId: '2026-7-8', uid: 'demo', steps: 10325, distanceKm: 7.4, calories: 440, walkingTimeSeconds: 84 * 60, activeMinutes: 84, goalCompleted: true, date: DateTime(2026, 7, 8)),
      DailyStat(dateId: '2026-7-9', uid: 'demo', steps: 6120, distanceKm: 4.4, calories: 260, walkingTimeSeconds: 48 * 60, activeMinutes: 48, goalCompleted: false, date: DateTime(2026, 7, 9)),
      DailyStat(dateId: '2026-7-10', uid: 'demo', steps: 11450, distanceKm: 8.9, calories: 480, walkingTimeSeconds: 92 * 60, activeMinutes: 92, goalCompleted: true, date: DateTime(2026, 7, 10)),
      DailyStat(dateId: '2026-7-11', uid: 'demo', steps: 8740, distanceKm: 6.2, calories: 525, walkingTimeSeconds: 70 * 60, activeMinutes: 70, goalCompleted: false, date: DateTime(2026, 7, 11)),
      DailyStat(dateId: '2026-7-12', uid: 'demo', steps: 9440, distanceKm: 5.9, calories: 403, walkingTimeSeconds: 61 * 60, activeMinutes: 61, goalCompleted: false, date: DateTime(2026, 7, 12)),
    ];

    // Previous Week Demo Data (Total ~58,100 steps)
    final previousWeekStats = List.generate(7, (i) {
      return DailyStat(
        dateId: '2026-6-${29 + i}', uid: 'demo', steps: 8300, distanceKm: 5.5, calories: 300, walkingTimeSeconds: 60 * 60, activeMinutes: 60, goalCompleted: false, date: DateTime(2026, 6, 29).add(Duration(days: i)),
      );
    });

    // Recent Walks Demo Data
    final currentWeekWalks = [
      WalkSession(id: '1', uid: 'demo', trackingStatus: TrackingStatus.completed, startTime: DateTime(2026, 7, 12, 7, 32), steps: 9000, distanceKm: 7.5, calories: 400, durationSeconds: 4500, route: [], currentPaceString: '8:45', avgSpeedKmH: 6.0),
      WalkSession(id: '2', uid: 'demo', trackingStatus: TrackingStatus.completed, startTime: DateTime(2026, 7, 11, 18, 15), steps: 6000, distanceKm: 5.4, calories: 250, durationSeconds: 3200, route: [], currentPaceString: '9:12', avgSpeedKmH: 5.5),
      WalkSession(id: '3', uid: 'demo', trackingStatus: TrackingStatus.completed, startTime: DateTime(2026, 7, 11, 7, 10), steps: 10000, distanceKm: 8.2, calories: 450, durationSeconds: 5000, route: [], currentPaceString: '8:55', avgSpeedKmH: 6.2),
      // Dummy entry to satisfy longest walk correctly matching Friday
      WalkSession(id: '4', uid: 'demo', trackingStatus: TrackingStatus.completed, startTime: DateTime(2026, 7, 10, 8, 00), steps: 11000, distanceKm: 8.9, calories: 480, durationSeconds: 5200, route: [], currentPaceString: '8:55', avgSpeedKmH: 6.1),
    ];
    
    currentWeekWalks.sort((a, b) => b.startTime.compareTo(a.startTime));

    state = state.copyWith(
      isLoading: false,
      currentWeekStats: currentWeekStats,
      previousWeekStats: previousWeekStats,
      currentWeekWalks: currentWeekWalks,
      error: null,
    );
  }
}

final weeklyAnalyticsProvider = StateNotifierProvider.autoDispose<WeeklyAnalyticsNotifier, WeeklyAnalyticsState>((ref) {
  return WeeklyAnalyticsNotifier(ref);
});
