import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stride_ai/providers/weekly_analytics_provider.dart';

class AiCoachWeeklyCard extends StatelessWidget {
  final WeeklyAnalyticsState state;

  const AiCoachWeeklyCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryPurple = const Color(0xFF6324D6);
    final bgColor = isDark ? primaryPurple.withOpacity(0.15) : const Color(0xFFF3EDFF);
    final borderColor = isDark ? Colors.white12 : Colors.grey[200]!;

    String message = _generateCoachMessage();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: isDark ? Colors.white12 : Colors.white, shape: BoxShape.circle),
            child: Icon(Icons.smart_toy_rounded, color: primaryPurple, size: 40),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Coach', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : const Color(0xFF1F2937), height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white54 : Colors.black26, size: 28),
        ],
      ),
    );
  }
  
  String _generateCoachMessage() {
    if (state.currentWeekStats.isEmpty) {
      return "Start walking this week to get personalized AI insights!";
    }
    
    String msg = "";
    
    // Performance summary
    if (state.stepsIncrease > 5) {
      msg += "Excellent work! You walked ${state.stepsIncrease.toStringAsFixed(0)}% more than last week. ";
    } else if (state.stepsIncrease < -5) {
      msg += "You're taking it easy this week. You walked ${state.stepsIncrease.abs().toStringAsFixed(0)}% less than last week. ";
    } else {
      msg += "Great consistency! You're maintaining a steady pace compared to last week. ";
    }
    
    // Best day
    if (state.bestDay != null) {
      msg += "${DateFormat('EEEE').format(state.bestDay!.date)} was your most active day. ";
    }
    
    // Suggestion
    if (state.totalSteps < 50000) {
      msg += "Try adding one more evening walk to reach 50,000 steps this week!";
    } else {
      msg += "You're crushing your goals! Keep this momentum up for next week.";
    }
    
    return msg;
  }
}
