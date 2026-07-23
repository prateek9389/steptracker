import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:stride_ai/models/walk_session.dart';
import 'package:stride_ai/models/daily_stat.dart';
import 'package:stride_ai/theme/app_colors.dart';

class CaloriesTab extends StatefulWidget {
  final List<WalkSession> walks;
  final List<DailyStat> dailyStats;

  const CaloriesTab({
    Key? key,
    required this.walks,
    required this.dailyStats,
  }) : super(key: key);

  @override
  State<CaloriesTab> createState() => _CaloriesTabState();
}

class _CaloriesTabState extends State<CaloriesTab> {
  String _timeRange = 'Daily'; // Daily, Weekly, Monthly

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Calculate Today's Calories
    final now = DateTime.now();
    final todayStats = widget.dailyStats.where((s) => s.date.year == now.year && s.date.month == now.month && s.date.day == now.day);
    int todayCalories = todayStats.isNotEmpty ? todayStats.first.calories : 0;

    // Check if walks today have more calories
    final todayWalks = widget.walks.where((s) => s.startTime.year == now.year && s.startTime.month == now.month && s.startTime.day == now.day).toList();
    int todayWalksCalories = todayWalks.fold(0, (sum, w) => sum + w.calories);
    if (todayWalksCalories > todayCalories) todayCalories = todayWalksCalories;

    // Calculate Max Calories in a single session
    int maxSessionCalories = 0;
    for (var w in widget.walks) {
      if (w.calories > maxSessionCalories) {
        maxSessionCalories = w.calories;
      }
    }

    // Calculate average daily calories
    int totalCaloriesAllTime = widget.dailyStats.fold(0, (sum, s) => sum + s.calories);
    int activeDays = widget.dailyStats.where((s) => s.calories > 0).length;
    int avgDailyCalories = activeDays > 0 ? (totalCaloriesAllTime / activeDays).round() : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Insight Card
          _buildAIInsight(isDark, todayCalories, avgDailyCalories),
          const SizedBox(height: 24),
          
          // Main Value
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Today\'s Burn',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$todayCalories',
                        style: TextStyle(
                          fontSize: 40,
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : AppColors.textLight,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'kcal',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.danger,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.local_fire_department_rounded, color: AppColors.danger, size: 28),
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
                  'Avg Daily Burn',
                  '$avgDailyCalories kcal',
                  Icons.show_chart_rounded,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSmallMetricCard(
                  isDark,
                  'Highest Session',
                  '$maxSessionCalories kcal',
                  Icons.bolt_rounded,
                  AppColors.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Recent Walks list
          Text(
            'Recent Activities',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...widget.walks.take(5).map((w) => _buildWalkItem(w, isDark)).toList(),
        ],
      ),
    );
  }

  Widget _buildAIInsight(bool isDark, int today, int avg) {
    String msg = "Keep it up! Walking daily boosts your metabolism.";
    if (today > avg && avg > 0) {
      msg = "You're on fire! You've burned more calories today than your daily average.";
    } else if (today == 0) {
      msg = "Time to get moving! A short walk can help you start burning calories.";
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Colors.purple, Colors.blue]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'StrideAI Insight',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  msg,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(bool isDark) {
    final now = DateTime.now();
    final List<double> weeklyData = List.filled(7, 0.0);
    double maxY = 100.0;
    
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: 6 - i));
      
      final stat = widget.dailyStats.where((s) => s.date.year == date.year && s.date.month == date.month && s.date.day == date.day).firstOrNull;
      final walks = widget.walks.where((w) => w.startTime.year == date.year && w.startTime.month == date.month && w.startTime.day == date.day);
      
      double walkCals = walks.fold(0.0, (sum, w) => sum + w.calories);
      double statCals = (stat?.calories ?? 0).toDouble();
      double val = walkCals > statCals ? walkCals : statCals;
      
      weeklyData[i] = val;
      if (val > maxY) maxY = val;
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
                'Calories History',
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
            height: 180,
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
                        color: AppColors.danger,
                        width: 12,
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

  Widget _buildWalkItem(WalkSession act, bool isDark) {
    final time = '${act.startTime.hour.toString().padLeft(2, '0')}:${act.startTime.minute.toString().padLeft(2, '0')}';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161E2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_fire_department_rounded, color: AppColors.danger, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
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
                  '${act.startTime.month}/${act.startTime.day} at $time',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${act.calories} kcal',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: AppColors.danger,
              fontFamily: 'Outfit',
            ),
          ),
        ],
      ),
    );
  }
}
