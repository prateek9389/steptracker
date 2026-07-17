import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stride_ai/providers/weekly_analytics_provider.dart';

class BestPerformanceCard extends StatelessWidget {
  final WeeklyAnalyticsState state;

  const BestPerformanceCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF78350F).withOpacity(0.2) : const Color(0xFFFFFBEB);
    final borderColor = isDark ? Colors.white12 : const Color(0xFFFEF3C7);
    final primaryPurple = const Color(0xFF6324D6);
    
    // Derived stats
    final bestDay = state.bestDay;
    final bestDayName = bestDay != null ? DateFormat('EEEE').format(bestDay.date) : '--';
    final bestDaySteps = bestDay != null ? NumberFormat('#,###').format(bestDay.steps) : '0';
    
    final longestWalk = state.longestWalk;
    final longestWalkKm = longestWalk != null ? longestWalk.distanceKm.toStringAsFixed(1) : '0.0';
    final longestWalkDay = longestWalk != null ? DateFormat('EEEE').format(longestWalk.startTime) : '--';
    
    final highestCalDay = state.highestCaloriesDay;
    final highestCalVal = highestCalDay != null ? NumberFormat('#,###').format(highestCalDay.calories) : '0';
    final highestCalName = highestCalDay != null ? DateFormat('EEEE').format(highestCalDay.date) : '--';
    
    // Compute fastest pace walk
    double fastestPace = 9999.0;
    String fastestPaceDay = '--';
    for (var walk in state.currentWeekWalks) {
      if (walk.distanceKm > 0.5) { // Only count meaningful walks
        final pace = (walk.durationSeconds / 60) / walk.distanceKm;
        if (pace < fastestPace) {
          fastestPace = pace;
          fastestPaceDay = DateFormat('EEEE').format(walk.startTime);
        }
      }
    }
    final fastestPaceStr = fastestPace < 9999.0 ? '${fastestPace.toInt()}:${((fastestPace - fastestPace.toInt()) * 60).toInt().toString().padLeft(2, '0')}' : '--';

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.emoji_events_rounded, color: Color(0xFFF59E0B), size: 24),
              ),
              const SizedBox(width: 12),
              Text('Best Performance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 300) {
                // Mobile layout - 2x2
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildItem('Best Day', bestDayName, '$bestDaySteps steps', isDark, primaryPurple)),
                        Expanded(child: _buildItem('Longest Walk', '$longestWalkKm km', longestWalkDay, isDark, isDark ? Colors.white70 : Colors.black54)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildItem('Most Calories', '$highestCalVal kcal', highestCalName, isDark, isDark ? Colors.white70 : Colors.black54)),
                        Expanded(child: _buildItem('Fastest Pace', '$fastestPaceStr min/km', fastestPaceDay, isDark, isDark ? Colors.white70 : Colors.black54)),
                      ],
                    ),
                  ],
                );
              }
              // Tablet / wider layout - row of 4
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildItem('Best Day', bestDayName, '$bestDaySteps steps', isDark, primaryPurple)),
                  _buildDivider(isDark),
                  Expanded(child: _buildItem('Longest Walk', '$longestWalkKm km', longestWalkDay, isDark, isDark ? Colors.white70 : Colors.black54)),
                  _buildDivider(isDark),
                  Expanded(child: _buildItem('Most Calories', '$highestCalVal kcal', highestCalName, isDark, isDark ? Colors.white70 : Colors.black54)),
                  _buildDivider(isDark),
                  Expanded(child: _buildItem('Fastest Pace', '$fastestPaceStr min/km', fastestPaceDay, isDark, isDark ? Colors.white70 : Colors.black54)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      width: 1,
      height: 40,
      color: isDark ? Colors.white12 : Colors.grey[300],
      margin: const EdgeInsets.symmetric(horizontal: 12),
    );
  }

  Widget _buildItem(String title, String value, String subtitle, bool isDark, Color subtitleColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(fit: BoxFit.scaleDown, child: Text(title, style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54))),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87, fontFamily: 'Outfit'),
              children: [
                TextSpan(text: value.split(' ')[0]),
                if (value.contains(' ')) ...[
                  TextSpan(text: ' ${value.split(' ')[1]}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal)),
                ]
              ],
            ),
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(fit: BoxFit.scaleDown, child: Text(subtitle, style: TextStyle(fontSize: 12, color: subtitleColor))),
      ],
    );
  }
}
