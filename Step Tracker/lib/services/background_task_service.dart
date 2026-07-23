import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pedometer/pedometer.dart';
import 'notification_service.dart';

Future<String?> _generateGeminiMotivation(int currentSteps, int stepGoal, bool isReward) async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    final prefs = await SharedPreferences.getInstance();
    String? apiKey = prefs.getString('GEMINI_API_KEY');
    if (apiKey == null || apiKey.isEmpty) {
      await dotenv.load(fileName: ".env");
      apiKey = dotenv.env['GEMINI_API_KEY'];
    }
    if (apiKey == null || apiKey.isEmpty) return null;

    final prompt = isReward
        ? "I have taken $currentSteps steps today! Give me a short, 1-sentence motivational congratulation to keep walking."
        : "I have taken $currentSteps steps today. My goal is $stepGoal. I need ${stepGoal - currentSteps} more. Give me a short, 1-sentence energetic reminder to finish my goal.";
    
    final systemInstruction = "You are StrideAI, a personal walking coach. Be motivational, friendly, and extremely concise (max 1 sentence). Do not use hashtags.";

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey',
    );

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {'role': 'user', 'parts': [{'text': prompt}]}
        ],
        'systemInstruction': {
          'parts': [{'text': systemInstruction}]
        },
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 80,
        }
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
      return text?.trim();
    }
  } catch (e) {
    debugPrint("Gemini background error: $e");
  }
  return null;
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      debugPrint("Native called background task: $task");
      WidgetsFlutterBinding.ensureInitialized();
      
      try {
        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp();
        }
      } catch (e) {
        debugPrint("Firebase init error: $e");
      }
      
      final prefs = await SharedPreferences.getInstance();
      final notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      
      // If notifications are disabled in settings, do nothing
      if (!notificationsEnabled) {
        return Future.value(true);
      }
      
      final now = DateTime.now();
      final dateId = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      
      final savedDateId = prefs.getString('last_step_date_id');
      int currentSteps = prefs.getInt('last_step_count') ?? 0;
      if (savedDateId != dateId) {
        currentSteps = 0;
      }
      final stepGoal = prefs.getInt('daily_step_goal') ?? 10000;

      // Try to read live pedometer steps if available
      try {
        final ambientDate = prefs.getString('ambient_baseline_date');
        final event = await Pedometer.stepCountStream.first.timeout(const Duration(seconds: 3));
        
        if (ambientDate == dateId) {
          final baseline = prefs.getInt('ambient_baseline_steps') ?? 0;
          final realSteps = event.steps - baseline;
          if (realSteps > currentSteps) {
            currentSteps = realSteps;
            // Update so the UI reflects this when opened
            await prefs.setInt('last_step_count', currentSteps);
          }
        } else {
          // New day and no baseline yet. We must set one now so future background tasks today can track steps!
          await prefs.setString('ambient_baseline_date', dateId);
          // If we had steps from earlier today, we can't recover them purely in background without yesterday's EOD value.
          // But this establishes a baseline for the rest of today.
          await prefs.setInt('ambient_baseline_steps', event.steps);
        }
      } catch (e) {
        debugPrint("Background pedometer error: $e");
      }

      switch (task) {
        case "step_reminder_task":
          final goalCompleted = prefs.getBool('last_step_goal_completed') ?? false;
          // If it's a new day, or goal is not completed, we should send a reminder
          if (savedDateId != dateId || !goalCompleted) {
            final remaining = stepGoal - currentSteps;
            final actualRemaining = remaining > 0 ? remaining : stepGoal;
            
            String body = await _generateGeminiMotivation(currentSteps, stepGoal, false) ??
                "Don't forget your daily goal! You are $actualRemaining steps away.";
            
            await NotificationService().showNotification(
              id: 888,
              title: 'Step Goal Reminder',
              body: body,
            );
            
            final uid = FirebaseAuth.instance.currentUser?.uid;
            if (uid != null) {
              await FirebaseFirestore.instance.collection('users').doc(uid).collection('notifications').add({
                'title': 'Step Goal Reminder',
                'body': body,
                'type': 'system',
                'createdAt': FieldValue.serverTimestamp(),
                'isRead': false,
              });
            }
          }
          break;
          
        case "reward_notification_task":
          if (currentSteps > 0 && savedDateId == dateId) {
            // Give a motivational reward message based on today's progress
            String body = await _generateGeminiMotivation(currentSteps, stepGoal, true) ??
                "You've taken $currentSteps steps today! Keep walking to earn more XP and coins.";

            await NotificationService().showNotification(
              id: 889,
              title: 'Keep it up!',
              body: body,
            );

            final uid = FirebaseAuth.instance.currentUser?.uid;
            if (uid != null) {
              await FirebaseFirestore.instance.collection('users').doc(uid).collection('notifications').add({
                'title': 'Keep it up!',
                'body': body,
                'type': 'success',
                'createdAt': FieldValue.serverTimestamp(),
                'isRead': false,
              });
            }
          }
          break;
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
      initialDelay: const Duration(hours: 2),
      constraints: Constraints(
        requiresBatteryNotLow: true,
      ),
    );
  }

  Future<void> registerRewardNotificationTask() async {
    await Workmanager().registerPeriodicTask(
      "reward_notification_task_id",
      "reward_notification_task",
      frequency: const Duration(hours: 1),
      initialDelay: const Duration(hours: 1),
      constraints: Constraints(
        requiresBatteryNotLow: true,
      ),
    );
  }
}
