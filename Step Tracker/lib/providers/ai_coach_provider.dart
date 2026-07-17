import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'auth_provider.dart';
import 'profile_provider.dart';
import 'stats_provider.dart';
import 'walk_provider.dart';
import '../models/user_profile.dart';
import '../models/daily_stat.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'time': time.toIso8601String(),
    };
  }
}

class AiCoachState {
  final List<ChatMessage> messages;
  final List<String> suggestions;
  final bool isTyping;
  final String dailyQuote;
  final String motivationTitle;
  final String motivationBody;

  AiCoachState({
    required this.messages,
    required this.suggestions,
    this.isTyping = false,
    required this.dailyQuote,
    required this.motivationTitle,
    required this.motivationBody,
  });

  AiCoachState copyWith({
    List<ChatMessage>? messages,
    List<String>? suggestions,
    bool? isTyping,
    String? dailyQuote,
    String? motivationTitle,
    String? motivationBody,
  }) {
    return AiCoachState(
      messages: messages ?? this.messages,
      suggestions: suggestions ?? this.suggestions,
      isTyping: isTyping ?? this.isTyping,
      dailyQuote: dailyQuote ?? this.dailyQuote,
      motivationTitle: motivationTitle ?? this.motivationTitle,
      motivationBody: motivationBody ?? this.motivationBody,
    );
  }
}

final aiCoachProvider = StateNotifierProvider.autoDispose<AiCoachNotifier, AiCoachState>((ref) {
  return AiCoachNotifier(ref);
});

class AiCoachNotifier extends StateNotifier<AiCoachState> {
  final Ref _ref;
  StreamSubscription? _historySubscription;

  AiCoachNotifier(this._ref)
      : super(
          AiCoachState(
            messages: [
              ChatMessage(
                text: "Hey! I am StrideAI, your personal walking coach. I can help analyze your walks, suggest active goals, and motivate you. What's on your mind today?",
                isUser: false,
                time: DateTime.now().subtract(const Duration(minutes: 5)),
              ),
            ],
            suggestions: [
              "Analyze my weekly walking stats",
              "How to burn 300 kcal faster?",
              "Give me a walking tip for today",
              "Plan a 5,000 steps workout route",
            ],
            dailyQuote: "Success is the sum of small efforts, repeated day in and day out.",
            motivationTitle: "Almost There!",
            motivationBody: "Ready to walk? I am here to guide you toward your goals today.",
          ),
        ) {
    _loadHistory();
    _initMotivation();
    _listenToStreams();
  }

  void _initMotivation() {
    final todayStat = _ref.read(todayStatStreamProvider).value;
    final profile = _ref.read(profileStreamProvider).value;
    if (profile != null) {
      updateMotivation(todayStat?.steps ?? 0, profile.dailyGoal);
    }
  }

  void _listenToStreams() {
    // Listen to changes in step count
    _ref.listen<AsyncValue<DailyStat?>>(todayStatStreamProvider, (prev, next) {
      final stat = next.value;
      final profile = _ref.read(profileStreamProvider).value;
      if (stat != null && profile != null) {
        updateMotivation(stat.steps, profile.dailyGoal);
      }
    });

    // Listen to changes in user profile (e.g. goal changes)
    _ref.listen<AsyncValue<UserProfile?>>(profileStreamProvider, (prev, next) {
      final profile = next.value;
      final todayStat = _ref.read(todayStatStreamProvider).value;
      if (profile != null) {
        updateMotivation(todayStat?.steps ?? 0, profile.dailyGoal);
      }
    });

    // Listen to auth changes to reset history if needed
    _ref.listen<User?>(currentUserProvider, (prev, next) {
      _historySubscription?.cancel();
      if (next == null) {
        state = state.copyWith(messages: []);
      } else {
        _loadHistory();
      }
    });
  }

  void _loadHistory() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _historySubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('ai_chat_history')
          .orderBy('time', descending: false)
          .limit(50)
          .snapshots()
          .listen((snapshot) {
        final greeting = ChatMessage(
          text: "Hey! I am StrideAI, your personal walking coach. I can help analyze your walks, suggest active goals, and motivate you. What's on your mind today?",
          isUser: false,
          time: DateTime.now().subtract(const Duration(minutes: 5)),
        );

        if (snapshot.docs.isEmpty) {
          state = state.copyWith(messages: [greeting]);
          return;
        }

        final loadedMessages = snapshot.docs.map((doc) {
          final data = doc.data();
          return ChatMessage(
            text: data['text'] as String? ?? '',
            isUser: data['isUser'] as bool? ?? true,
            time: DateTime.tryParse(data['time'] as String? ?? '') ?? DateTime.now(),
          );
        }).toList();

        state = state.copyWith(messages: [greeting, ...loadedMessages]);
      });
    }
  }

  Future<void> _saveMessage(ChatMessage msg) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('ai_chat_history')
          .add(msg.toJson());
    }
  }

  Future<void> sendMessage(String text) async {
    final userMsg = ChatMessage(text: text, isUser: true, time: DateTime.now());

    // Optimistic UI update
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isTyping: true,
    );
    _saveMessage(userMsg);

    // Call Gemini API if available, else use fallback local generator
    String? replyText = await _callGeminiAPI(text);
    if (replyText == null || replyText.trim().isEmpty) {
      // Simulate AI response delay for realistic feel
      await Future.delayed(const Duration(seconds: 1));
      replyText = _generateAiReply(text);
    }

    final aiMsg = ChatMessage(text: replyText, isUser: false, time: DateTime.now());

    state = state.copyWith(
      messages: [...state.messages, aiMsg],
      isTyping: false,
    );
    _saveMessage(aiMsg);
  }

  Future<String?> _callGeminiAPI(String userPrompt) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) return null;

    final profile = _ref.read(profileStreamProvider).value;
    final todayStat = _ref.read(todayStatStreamProvider).value;
    final walkHistory = _ref.read(walkHistoryStreamProvider).value ?? [];
    final allDailyStats = _ref.read(allDailyStatsStreamProvider).value ?? [];

    final int goal = profile?.dailyGoal ?? 6000;
    final int todaySteps = todayStat?.steps ?? 0;
    final double weight = profile?.weight ?? 70.0;
    final double height = profile?.height ?? 170.0;
    final double stepLengthCm = profile?.stepLength ?? 70.0;

    int totalStepsLastWeek = 0;
    for (var s in allDailyStats.take(7)) {
      totalStepsLastWeek += s.steps;
    }
    final double avgSteps = allDailyStats.isNotEmpty
        ? totalStepsLastWeek / (allDailyStats.length > 7 ? 7 : allDailyStats.length)
        : 0.0;

    final systemInstruction = "You are StrideAI, a personal walking coach. Be motivational, friendly, and structured. "
        "Write concise, helpful answers. Bold key figures. "
        "Use the user's actual health statistics in your answers if they are asking about stats, calorie burns, plans, or health. "
        "User metrics: "
        "- Name: ${profile?.name ?? 'User'} "
        "- Height: ${height.toStringAsFixed(0)} cm, Weight: ${weight.toStringAsFixed(0)} kg "
        "- Today's steps: $todaySteps, Daily goal: $goal steps "
        "- Stride length: ${stepLengthCm.toStringAsFixed(0)} cm "
        "- Past week average: ${avgSteps.toStringAsFixed(0)} steps/day "
        "- Walk history workouts: ${walkHistory.length} completed walks. "
        "Do not mention dummy or placeholder stats. If you do not have enough walk logs, gently ask them to log a walk. Keep responses friendly.";

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
    );

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': userPrompt}
              ]
            }
          ],
          'systemInstruction': {
            'parts': [
              {'text': systemInstruction}
            ]
          },
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 400,
          }
        }),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          if (content != null) {
            final parts = content['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              final text = parts[0]['text'] as String?;
              if (text != null && text.trim().isNotEmpty) {
                return text.trim();
              }
            }
          }
        }
      } else {
        debugPrint('[AiCoachProvider] Gemini API returned status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[AiCoachProvider] Error calling Gemini API: $e');
    }
    return null;
  }

  String _generateAiReply(String query) {
    query = query.toLowerCase();

    final profile = _ref.read(profileStreamProvider).value;
    final todayStat = _ref.read(todayStatStreamProvider).value;
    final walkHistory = _ref.read(walkHistoryStreamProvider).value ?? [];
    final allDailyStats = _ref.read(allDailyStatsStreamProvider).value ?? [];

    final int goal = profile?.dailyGoal ?? 6000;
    final int todaySteps = todayStat?.steps ?? 0;
    final double weight = profile?.weight ?? 70.0;
    final double stepLengthCm = profile?.stepLength ?? 70.0;

    if (query.contains('stat') || query.contains('weekly') || query.contains('history')) {
      if (allDailyStats.isEmpty && walkHistory.isEmpty) {
        return "You don't have any walk history recorded yet. Let's start tracking your walks in the 'Walk' tab to get personalized weekly stats!";
      }

      final now = DateTime.now();
      final last7DaysStats = allDailyStats.where((s) {
        final difference = now.difference(s.date).inDays;
        return difference >= 0 && difference < 7;
      }).toList();

      int totalStepsLastWeek = 0;
      int peakSteps = 0;
      String peakDayName = "N/A";
      for (var s in last7DaysStats) {
        totalStepsLastWeek += s.steps;
        if (s.steps > peakSteps) {
          peakSteps = s.steps;
          peakDayName = _weekdayName(s.date.weekday);
        }
      }

      final double avgSteps = last7DaysStats.isNotEmpty ? totalStepsLastWeek / last7DaysStats.length : 0.0;

      double totalSpeed = 0.0;
      int speedCount = 0;
      for (var w in walkHistory) {
        if (w.avgSpeedKmH > 0) {
          totalSpeed += w.avgSpeedKmH;
          speedCount++;
        }
      }
      final double avgSpeed = speedCount > 0 ? totalSpeed / speedCount : 5.0;

      String response = "Based on your real weekly walk records:\n";
      response += "• Average daily steps: **${avgSteps.toStringAsFixed(0)}** steps/day\n";
      if (peakSteps > 0) {
        response += "• Weekly peak: **${peakSteps.toStringAsFixed(0)}** steps on **$peakDayName**\n";
      }
      response += "• Average workout speed: **${avgSpeed.toStringAsFixed(1)}** km/h\n\n";
      response += "Consistency is key! Try to increase your active walking time by just 5 minutes tomorrow to boost your daily calorie burn.";
      return response;

    } else if (query.contains('calorie') || query.contains('burn') || query.contains('kcal')) {
      final double calPerMin = 4.0 * 3.5 * weight / 200.0;
      final double minsNeeded = calPerMin > 0 ? 300.0 / calPerMin : 60.0;

      return "To burn **300 kcal** faster at your current weight of **${weight.toStringAsFixed(0)} kg**, I recommend an Outdoor Power Walk.\n\n"
          "Keep a brisk pace around **6.0 km/h** (10 min/km). At this intensity, you will burn approximately **${calPerMin.toStringAsFixed(1)} kcal/min**, meaning you'll hit your 300 kcal target in about **${minsNeeded.round()} minutes**.\n\n"
          "Tip: Actively swing your arms and walk on a slight incline to increase your energy expenditure by up to 25%!";

    } else if (query.contains('tip') || query.contains('advice') || query.contains('health')) {
      final List<String> tips = [
        "Focus on landing on your heels and rolling smoothly through to your toes. This protects your knees and increases cadence.",
        "Keep your shoulders relaxed, chest lifted, and look ahead (not down at your feet). Good posture naturally improves breathing.",
        "Brisk walking (above 5.5 km/h) helps keep your heart rate in the aerobic zone, boosting cardiovascular endurance.",
        "Taking a short 10-minute walk after meals helps regulate blood sugar spikes and aids digestion.",
      ];
      final tip = tips[DateTime.now().weekday % tips.length];
      return "StrideAI Health Tip: $tip";

    } else if (query.contains('route') || query.contains('plan') || query.contains('5k') || query.contains('5,000')) {
      final double strideLengthM = stepLengthCm / 100.0;
      final double distanceM = 5000 * strideLengthM;
      final double distanceKm = distanceM / 1000.0;

      final double speedKmH = 5.0;
      final double durationMins = (distanceKm / speedKmH) * 60.0;

      return "For a **5,000 steps** session, with your personal step length of **${stepLengthCm.toStringAsFixed(0)} cm**, you will cover a distance of approximately **${distanceKm.toStringAsFixed(2)} km**.\n\n"
          "At a standard walking speed of **${speedKmH.toStringAsFixed(1)} km/h**, it will take you about **${durationMins.round()} minutes**.\n\n"
          "Plan: Select 'Outdoor Walk' in the Walk tab, and try a looping path in a green space. Green exercise has been shown to reduce perceived effort and lower stress hormones!";
    } else {
      final int remaining = goal - todaySteps;
      if (remaining <= 0) {
        return "Magnificent work! You've already met your daily goal of **$goal** steps today by walking **$todaySteps** steps! Keep up the momentum!";
      }
      final int mins = (remaining / 140).round();
      return "Hi! Walking is one of the best habits for active health. Today you have walked **$todaySteps** steps of your **$goal** step goal. You need just **$remaining** steps to hit your target. A brisk **$mins-minute** walk will complete your goal. What walk are we planning next?";
    }
  }

  String _weekdayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[(weekday - 1).clamp(0, 6)];
  }

  void updateMotivation(int currentSteps, int goal) {
    if (currentSteps >= goal) {
      state = state.copyWith(
        motivationTitle: "Goal Achieved!",
        motivationBody: "Magnificent work! You've crushed your daily step goal of $goal steps. Your level XP has been boosted. Try to push for a new record today!",
      );
    } else {
      final remaining = goal - currentSteps;
      final mins = (remaining / 140).round();
      state = state.copyWith(
        motivationTitle: "Almost There!",
        motivationBody: "You need just $remaining steps to hit your target. A brisk $mins-minute walk will complete your goal and extend your streak!",
      );
    }
  }

  @override
  void dispose() {
    _historySubscription?.cancel();
    super.dispose();
  }
}

