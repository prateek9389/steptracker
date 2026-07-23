import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pedometer/pedometer.dart';

final stepProvider = StateNotifierProvider<StepNotifier, StepState>((ref) {
  return StepNotifier();
});

class StepState {
  final int todaySteps;
  final double todayDistanceKm;
  final int todayCalories;
  final int activeMinutes;
  final int currentStreak;
  final double currentPaceMinKm;
  final double currentSpeedKmH;
  final List<int> weeklySteps; // Mon-Sun
  final bool isTrackingAmbient;
  final Map<String, int> hourlySteps;
  final String walkingStatus;

  StepState({
    required this.todaySteps,
    required this.todayDistanceKm,
    required this.todayCalories,
    required this.activeMinutes,
    required this.currentStreak,
    required this.currentPaceMinKm,
    required this.currentSpeedKmH,
    required this.weeklySteps,
    this.isTrackingAmbient = true,
    this.hourlySteps = const {},
    this.walkingStatus = 'Inactive',
  });

  StepState copyWith({
    int? todaySteps,
    double? todayDistanceKm,
    int? todayCalories,
    int? activeMinutes,
    int? currentStreak,
    double? currentPaceMinKm,
    double? currentSpeedKmH,
    List<int>? weeklySteps,
    bool? isTrackingAmbient,
    Map<String, int>? hourlySteps,
    String? walkingStatus,
  }) {
    return StepState(
      todaySteps: todaySteps ?? this.todaySteps,
      todayDistanceKm: todayDistanceKm ?? this.todayDistanceKm,
      todayCalories: todayCalories ?? this.todayCalories,
      activeMinutes: activeMinutes ?? this.activeMinutes,
      currentStreak: currentStreak ?? this.currentStreak,
      currentPaceMinKm: currentPaceMinKm ?? this.currentPaceMinKm,
      currentSpeedKmH: currentSpeedKmH ?? this.currentSpeedKmH,
      weeklySteps: weeklySteps ?? this.weeklySteps,
      isTrackingAmbient: isTrackingAmbient ?? this.isTrackingAmbient,
      hourlySteps: hourlySteps ?? this.hourlySteps,
      walkingStatus: walkingStatus ?? this.walkingStatus,
    );
  }
}

/// Returns the 0-indexed day of the week for today (Mon=0 … Sun=6)
int _todayWeekdayIndex() {
  // DateTime.weekday: Monday=1 … Sunday=7
  return DateTime.now().weekday - 1;
}

/// Derives steps-per-minute from step count (~100 spm average walking pace).
/// Minimum 0, maximum 1440 minutes per day.
int _computeActiveMinutes(int steps) {
  const stepsPerMinute = 100;
  return (steps / stepsPerMinute).round().clamp(0, 1440);
}

class StepNotifier extends StateNotifier<StepState> {
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<QuerySnapshot>? _weeklySubscription;

  StepNotifier()
      : super(
          StepState(
            todaySteps: 0,
            todayDistanceKm: 0.0,
            todayCalories: 0,
            activeMinutes: 0,
            currentStreak: 0,
            currentPaceMinKm: 0.0,
            currentSpeedKmH: 0.0,
            weeklySteps: List.filled(7, 0),
            isTrackingAmbient: false,
            hourlySteps: {},
            walkingStatus: 'Inactive',
          ),
        ) {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _loadFromFirestore(user.uid);
        _subscribeToWeeklyStats(user.uid);
      } else {
        // Reset to zeroes when logged out
        state = state.copyWith(
          todaySteps: 0,
          todayDistanceKm: 0.0,
          todayCalories: 0,
          activeMinutes: 0,
          currentStreak: 0,
          weeklySteps: List.filled(7, 0),
          hourlySteps: {},
          walkingStatus: 'Inactive',
        );
      }
    });
  }

  Future<void> _initPedometerBaseline(String todayStr) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedDate = prefs.getString('ambient_baseline_date');
      if (savedDate != todayStr) {
        final event = await Pedometer.stepCountStream.first.timeout(const Duration(seconds: 3));
        await prefs.setString('ambient_baseline_date', todayStr);
        await prefs.setInt('ambient_baseline_steps', event.steps);
      }
    } catch (e) {
      // Ignore if pedometer is unavailable
    }
  }

  /// Load today's stat from Firestore and reflect it in state.
  void _loadFromFirestore(String uid) {
    final todayStr = DateTime.now().toString().substring(0, 10);
    
    // Save pedometer baseline if not already saved for today
    _initPedometerBaseline(todayStr);

    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('daily_stats')
        .doc(todayStr)
        .get()
        .then((doc) {
      if (!doc.exists) return;
      final data = doc.data()!;
      final steps = (data['steps'] as int?) ?? 0;
      if (steps == 0) return;

      final distance = (data['distanceKm'] as num?)?.toDouble() ??
          double.parse((steps * 0.00075).toStringAsFixed(2));
      final calories = (data['calories'] as int?) ??
          (steps * 0.042).toInt();
      final hourly = (data['hourlySteps'] as Map<String, dynamic>?)
              ?.map((k, e) => MapEntry(k, e as int)) ??
          {};
      final status = (data['walkingStatus'] as String?) ?? 'Inactive';
      final activeMinutes = _computeActiveMinutes(steps);

      // Reflect today's slot in weekly array
      final weekly = List<int>.from(state.weeklySteps);
      weekly[_todayWeekdayIndex()] = steps;

      state = state.copyWith(
        todaySteps: steps,
        todayDistanceKm: distance,
        todayCalories: calories,
        activeMinutes: activeMinutes,
        weeklySteps: weekly,
        hourlySteps: hourly,
        walkingStatus: status,
      );
    }).catchError((e) {
      // Silently ignore — state stays at zeroes; user just sees 0 steps
    });
  }

  /// Subscribe to this week's daily_stats documents so the weekly bar chart
  /// stays live without polling.
  void _subscribeToWeeklyStats(String uid) {
    _weeklySubscription?.cancel();

    // Monday of the current week
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    // Subscribe to this week's daily_stats documents so the weekly bar chart
    // stays live without polling.
    _weeklySubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('daily_stats')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(monday))
        .snapshots()
        .listen((snap) {
      final weekly = List<int>.from(state.weeklySteps);
      for (final doc in snap.docs) {
        final data = doc.data();
        final steps = (data['steps'] as int?) ?? 0;
        final dateTs = data['date'] as Timestamp?;
        if (dateTs == null) continue;
        final date = dateTs.toDate();
        final idx = date.weekday - 1; // Mon=0 … Sun=6
        if (idx >= 0 && idx < 7) {
          weekly[idx] = steps;
        }
      }
      state = state.copyWith(weeklySteps: weekly);
    });
  }

  void setSteps(int steps) {
    final distance = double.parse((steps * 0.00075).toStringAsFixed(2));
    final calories = (steps * 0.042).toInt();
    final activeMinutes = _computeActiveMinutes(steps);

    final weekly = List<int>.from(state.weeklySteps);
    weekly[_todayWeekdayIndex()] = steps;

    state = state.copyWith(
      todaySteps: steps,
      todayDistanceKm: distance,
      todayCalories: calories,
      activeMinutes: activeMinutes,
      weeklySteps: weekly,
    );
  }

  void incrementSteps(int count) {
    final steps = state.todaySteps + count;
    final distance = double.parse((steps * 0.00075).toStringAsFixed(2));
    final calories = (steps * 0.042).toInt();
    final activeMinutes = _computeActiveMinutes(steps);

    final weekly = List<int>.from(state.weeklySteps);
    weekly[_todayWeekdayIndex()] = steps;

    final now = DateTime.now();
    final hourKey = '${now.hour.toString().padLeft(2, '0')}:00';
    final hourly = Map<String, int>.from(state.hourlySteps);
    hourly[hourKey] = (hourly[hourKey] ?? 0) + count;

    const status = 'Walking';

    state = state.copyWith(
      todaySteps: steps,
      todayDistanceKm: distance,
      todayCalories: calories,
      activeMinutes: activeMinutes,
      weeklySteps: weekly,
      hourlySteps: hourly,
      walkingStatus: status,
    );

    _saveStepsToFirestore(steps, hourly, status, distance, calories, activeMinutes);
  }

  void _saveStepsToFirestore(int steps, Map<String, int> hourly, String status,
      double distance, int calories, int activeMinutes) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final todayStr = DateTime.now().toString().substring(0, 10);

    // Fetch the user's actual daily goal from Firestore asynchronously.
    FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get()
        .then((profileDoc) {
      final dailyGoal =
          (profileDoc.data()?['dailyGoal'] as int?) ?? 10000;
      final goalCompleted = steps >= dailyGoal;
      final progress = (steps / dailyGoal).clamp(0.0, 1.0);
      final remaining = (dailyGoal - steps).clamp(0, dailyGoal);

      FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('daily_stats')
          .doc(todayStr)
          .set({
        'uid': currentUser.uid,
        'steps': steps,
        'distanceKm': distance,
        'calories': calories,
        'activeMinutes': activeMinutes,
        'hourlySteps': hourly,
        'walkingStatus': status,
        'goalCompleted': goalCompleted,
        'progress': progress,
        'remainingSteps': remaining,
        'date': Timestamp.now(),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).then((_) {
        // Also persist to SharedPreferences for background notification tasks
        _persistToSharedPreferences(
            todayStr, steps, dailyGoal, goalCompleted);
      }).catchError((e) {
        // ignore
      });
    }).catchError((e) {
      // ignore
    });
  }

  Future<void> _persistToSharedPreferences(
      String dateId, int steps, int dailyGoal, bool goalCompleted) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_step_date_id', dateId);
      await prefs.setInt('last_step_count', steps);
      await prefs.setInt('daily_step_goal', dailyGoal);
      await prefs.setBool('last_step_goal_completed', goalCompleted);
    } catch (_) {}
  }

  void addManualSteps(int count) {
    incrementSteps(count);
  }

  void setAmbientTracking(bool enable) {
    state = state.copyWith(isTrackingAmbient: enable);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _weeklySubscription?.cancel();
    super.dispose();
  }
}
