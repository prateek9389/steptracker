import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      debugPrint("Native called background task: $task");
      
      final prefs = await SharedPreferences.getInstance();
      
      // We will check SharedPreferences to see if goal is completed today.
      // This requires the main app to save goal completion status to SharedPreferences.
      
      final now = DateTime.now();
      final dateId = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      
      final savedDateId = prefs.getString('last_step_date_id');
      final goalCompleted = prefs.getBool('last_step_goal_completed') ?? false;
      final currentSteps = prefs.getInt('last_step_count') ?? 0;
      final stepGoal = prefs.getInt('daily_step_goal') ?? 10000;

      // If it's a new day, or goal is not completed, we should send a reminder
      if (savedDateId != dateId || !goalCompleted) {
        // Send local notification
        final remaining = stepGoal - currentSteps;
        final actualRemaining = remaining > 0 ? remaining : stepGoal;
        
        await NotificationService().showNotification(
          id: 888,
          title: 'Step Goal Reminder',
          body: "Don't forget your daily goal! You are $actualRemaining steps away.",
        );
      }

      return Future.value(true);
    } catch (e) {
      debugPrint("Background task error: $e");
      return Future.value(false);
    }
  });
}

class BackgroundTaskService {
  static final BackgroundTaskService _instance = BackgroundTaskService._internal();
  factory BackgroundTaskService() => _instance;
  BackgroundTaskService._internal();

  Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );
  }

  Future<void> registerStepReminderTask() async {
    await Workmanager().registerPeriodicTask(
      "step_reminder_task_id",
      "step_reminder_task",
      frequency: const Duration(hours: 2),
      initialDelay: const Duration(hours: 2), // First run after 2 hours
      constraints: Constraints(
        requiresBatteryNotLow: true,
      ),
    );
  }
}
