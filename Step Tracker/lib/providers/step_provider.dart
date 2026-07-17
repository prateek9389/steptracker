import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

class StepNotifier extends StateNotifier<StepState> {
  Timer? _ambientTimer;
  StreamSubscription<User?>? _authSubscription;

  StepNotifier()
      : super(
          StepState(
            todaySteps: 7428,
            todayDistanceKm: 5.57,
            todayCalories: 312,
            activeMinutes: 54,
            currentStreak: 6,
            currentPaceMinKm: 9.3,
            currentSpeedKmH: 4.8,
            weeklySteps: [8200, 9400, 11200, 9800, 7428, 0, 0], // Wed is highest, Fri is today (index 4)
            isTrackingAmbient: true,
            hourlySteps: {},
            walkingStatus: 'Inactive',
          ),
        ) {
    _startAmbientTracking();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _loadInitialStepsFromFirestore();
      }
    });
  }

  void _loadInitialStepsFromFirestore() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final todayStr = DateTime.now().toString().substring(0, 10);
      FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('daily_stats')
          .doc(todayStr)
          .get()
          .then((doc) {
            if (doc.exists) {
              final data = doc.data();
              final steps = data?['steps'] as int? ?? 0;
              final hourly = (data?['hourlySteps'] as Map<String, dynamic>?)?.map((k, e) => MapEntry(k, e as int)) ?? {};
              final status = data?['walkingStatus'] as String? ?? 'Inactive';
              
              if (steps > 0) {
                // Initialize state directly to avoid triggering _saveStepsToFirestore unnecessarily
                final distance = double.parse((steps * 0.00075).toStringAsFixed(2));
                final calories = (steps * 0.042).toInt();
                final minutes = 54 + (steps - 7428) ~/ 120;
                List<int> weekly = List.from(state.weeklySteps);
                weekly[4] = steps;
                
                state = state.copyWith(
                  todaySteps: steps,
                  todayDistanceKm: distance,
                  todayCalories: calories,
                  activeMinutes: minutes.clamp(0, 1440),
                  weeklySteps: weekly,
                  hourlySteps: hourly,
                  walkingStatus: status,
                );
              }
            }
          })
          .catchError((e) {
            print('Error loading initial steps from Firestore: $e');
          });
    }
  }

  void setSteps(int steps) {
    // Estimate: 1 step = 0.75m = 0.00075km
    final distance = double.parse((steps * 0.00075).toStringAsFixed(2));
    // Estimate: 1 step = 0.04 calories
    final calories = (steps * 0.042).toInt();
    
    // Add minutes every 120 steps
    final minutes = 54 + (steps - 7428) ~/ 120;

    List<int> weekly = List.from(state.weeklySteps);
    // Today is Friday (index 4)
    weekly[4] = steps;

    state = state.copyWith(
      todaySteps: steps,
      todayDistanceKm: distance,
      todayCalories: calories,
      activeMinutes: minutes.clamp(0, 1440),
      weeklySteps: weekly,
    );
  }

  void _startAmbientTracking() {
    _ambientTimer?.cancel();
    _ambientTimer = Timer.periodic(const Duration(seconds: 12), (timer) {
      if (state.isTrackingAmbient) {
        incrementSteps(1 + (DateTime.now().second % 3)); // Add 1-3 steps ambiently
      }
    });
  }

  void incrementSteps(int count) {
    final steps = state.todaySteps + count;
    // Estimate: 1 step = 0.75m = 0.00075km
    final distance = double.parse((steps * 0.00075).toStringAsFixed(2));
    // Estimate: 1 step = 0.04 calories
    final calories = (steps * 0.042).toInt();
    
    // Add minutes every 120 steps
    final minutes = 54 + (steps - 7428) ~/ 120;

    List<int> weekly = List.from(state.weeklySteps);
    // Today is Friday (index 4)
    weekly[4] = steps;

    // Premium fields
    final now = DateTime.now();
    final hourKey = '${now.hour.toString().padLeft(2, '0')}:00';
    final hourly = Map<String, int>.from(state.hourlySteps);
    hourly[hourKey] = (hourly[hourKey] ?? 0) + count;
    
    final status = count > 0 ? 'Walking' : 'Inactive';

    state = state.copyWith(
      todaySteps: steps,
      todayDistanceKm: distance,
      todayCalories: calories,
      activeMinutes: minutes.clamp(0, 1440),
      weeklySteps: weekly,
      hourlySteps: hourly,
      walkingStatus: status,
    );

    _saveStepsToFirestore(steps, hourly, status, distance, calories, minutes);
  }

  void _saveStepsToFirestore(int steps, Map<String, int> hourly, String status, double distance, int calories, int minutes) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final todayStr = DateTime.now().toString().substring(0, 10);
      final dailyGoal = 6000; // Standard goal
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
            'activeMinutes': minutes,
            'hourlySteps': hourly,
            'walkingStatus': status,
            'progress': progress,
            'remainingSteps': remaining,
            'date': Timestamp.now(),
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true))
          .catchError((e) {
            print('Error writing stats to Firestore: $e');
          });
    }
  }

  void addManualSteps(int count) {
    incrementSteps(count);
  }

  void setAmbientTracking(bool enable) {
    state = state.copyWith(isTrackingAmbient: enable);
  }

  @override
  void dispose() {
    _ambientTimer?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
}
