import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:stride_ai/models/walk_session.dart';
import 'package:stride_ai/models/daily_stat.dart';
import 'package:stride_ai/theme/app_colors.dart';

class ActiveTimeTab extends StatefulWidget {
  final List<WalkSession> walks;
  final List<DailyStat> dailyStats;

  const ActiveTimeTab({
    Key? key,
    required this.walks,
    required this.dailyStats,
  }) : super(key: key);

  @override
  State<ActiveTimeTab> createState() => _ActiveTimeTabState();
}

class _ActiveTimeTabState extends State<ActiveTimeTab> {
  String _timeRange = 'Daily';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final now = DateTime.now();

    // Today's Active Time
    final todayWalks = widget.walks.where((s) => s.startTime.year == now.year && s.startTime.month == now.month && s.startTime.day == now.day).toList();
    todayWalks.sort((a, b) => b.startTime.compareTo(a.startTime));
    
    int todayActiveTimeSeconds = todayWalks.fold(0, (sum, w) => sum + w.durationSeconds);
    int activeMinutes = todayActiveTimeSeconds ~/ 60;
    String activeMinutesString;
    if (todayActiveTimeSeconds < 60) {
      activeMinutesString = "${todayActiveTimeSeconds}s";
    } else if (activeMinutes >= 60) {
      activeMinutesString = "${activeMinutes ~/ 60}h ${activeMinutes % 60}m";
    } else {
      activeMinutesString = "${activeMinutes}m";
    }

    // Longest Session
    int longestSessionSeconds = 0;
    for (var w in widget.walks) {
      if (w.durationSeconds > longestSessionSeconds) {
        longestSessionSeconds = w.durationSeconds;
      }
    }
    String longestSessionString;
    if (longestSessionSeconds < 60) {
      longestSessionString = "${longestSessionSeconds}s";
    } else if (longestSessionSeconds >= 3600) {
      longestSessionString = "${longestSessionSeconds ~/ 3600}h ${(longestSessionSeconds % 3600) ~/ 60}m";
    } else {
      longestSessionString = "${longestSessionSeconds ~/ 60}m";
    }

    // Total Active Time
    int totalActiveTimeSeconds = widget.walks.fold(0, (sum, w) => sum + w.durationSeconds);
    String totalActiveTimeString;
    if (totalActiveTimeSeconds < 60) {
      totalActiveTimeString = "${totalActiveTimeSeconds}s";
    } else if (totalActiveTimeSeconds >= 3600) {
      totalActiveTimeString = "${totalActiveTimeSeconds ~/ 3600}h ${(totalActiveTimeSeconds % 3600) ~/ 60}m";
    } else {
      totalActiveTimeString = "${totalActiveTimeSeconds ~/ 60}m";
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Value
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Today\'s Active Time',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activeMinutesString,
                    style: TextStyle(
                      fontSize: 40,
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : AppColors.textLight,
                      height: 1,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.timer_rounded, color: AppColors.accent, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Chart Section
          _buildChartSection(isDark),
          const SizedBox(height: 24),

          // Metrics Grid
          Row(
            children: [
              Expanded(
                child: _buildSmallMetricCard(
                  isDark,
                  'Total Active Time',
                  totalActiveTimeString,
                  Icons.timelapse_rounded,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSmallMetricCard(
                  isDark,
                  'Longest Session',
                  longestSessionString,
                  Icons.sports_score_rounded,
                  Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Today's Timeline
          if (todayWalks.isNotEmpty) ...[
            Text(
              'Today\'s Timeline',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ...todayWalks.map((w) => _buildTimelineItem(w, isDark)).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineItem(WalkSession act, bool isDark) {
    final startTime = '${act.startTime.hour.toString().padLeft(2, '0')}:${act.startTime.minute.toString().padLeft(2, '0')}';
    final endTimeObj = act.startTime.add(Duration(seconds: act.durationSeconds));
    final endTime = '${endTimeObj.hour.toString().padLeft(2, '0')}:${endTimeObj.minute.toString().padLeft(2, '0')}';

    return IntrinsicHeight(
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              startTime,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight, width: 2),
                ),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: AppColors.accent.withOpacity(0.3),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161E2E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.black.withOpacity(0.05),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    act.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$startTime - $endTime  •  ${act.durationString}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(bool isDark) {
    final now = DateTime.now();
    final List<double> weeklyData = List.filled(7, 0.0);
    double maxY = 30.0;
    
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: 6 - i));
      final walks = widget.walks.where((w) => w.startTime.year == date.year && w.startTime.month == date.month && w.startTime.day == date.day);
      double mins = walks.fold(0, (sum, w) => sum + w.durationSeconds) / 60.0;
      weeklyData[i] = mins;
      if (mins > maxY) maxY = mins;
    }
    maxY = (maxY * 1.2).ceilToDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161E2E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withOpacity(0.05),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Time History',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              DropdownButton<String>(
                value: _timeRange,
                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                underline: const SizedBox(),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
                items: ['Daily', 'Weekly', 'Monthly'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _timeRange = val);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i > 6) return const SizedBox.shrink();
                        final d = now.subtract(Duration(days: 6 - i));
                        const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        final letter = weekdays[d.weekday - 1];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            letter,
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.black54,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (i) {
                  double yValue = weeklyData[i]; 
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: yValue,
                        color: AppColors.accent,
                        width: 14,
                        borderRadius: BorderRadius.circular(4),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY,
                          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallMetricCard(bool isDark, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161E2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withOpacity(0.05),
        ),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              fontFamily: 'Outfit',
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
