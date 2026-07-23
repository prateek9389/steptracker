import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:stride_ai/models/walk_session.dart';
import 'package:stride_ai/models/daily_stat.dart';
import 'package:stride_ai/theme/app_colors.dart';

class AveragePaceTab extends StatefulWidget {
  final List<WalkSession> walks;
  final List<DailyStat> dailyStats;

  const AveragePaceTab({
    Key? key,
    required this.walks,
    required this.dailyStats,
  }) : super(key: key);

  @override
  State<AveragePaceTab> createState() => _AveragePaceTabState();
}

class _AveragePaceTabState extends State<AveragePaceTab> {
  String _timeRange = 'Daily';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final now = DateTime.now();

    // Today's Average Pace
    final todayWalks = widget.walks.where((s) => s.startTime.year == now.year && s.startTime.month == now.month && s.startTime.day == now.day).toList();
    
    double todayTotalDistance = todayWalks.fold(0.0, (sum, w) => sum + w.distanceKm);
    int todayTotalSeconds = todayWalks.fold(0, (sum, w) => sum + w.durationSeconds);
    
    String todayPaceString = "0'00\"";
    double todayAvgSpeed = 0.0;
    if (todayTotalDistance > 0) {
      double totalMinutes = (todayTotalSeconds / 60) / todayTotalDistance;
      int paceMins = totalMinutes.toInt();
      int paceSecs = ((totalMinutes - paceMins) * 60).toInt();
      todayPaceString = "$paceMins'${paceSecs.toString().padLeft(2, '0')}\"";
      
      todayAvgSpeed = todayTotalDistance / (todayTotalSeconds / 3600);
    }

    // Best Pace (Lowest min/km)
    double bestPaceMinKm = double.infinity;
    for (var w in widget.walks) {
      if (w.distanceKm > 0.5) { // Only consider walks > 0.5km for valid pace
        double p = (w.durationSeconds / 60) / w.distanceKm;
        if (p < bestPaceMinKm) {
          bestPaceMinKm = p;
        }
      }
    }
    String bestPaceString = "--'--\"";
    if (bestPaceMinKm != double.infinity) {
      int pMins = bestPaceMinKm.toInt();
      int pSecs = ((bestPaceMinKm - pMins) * 60).toInt();
      bestPaceString = "$pMins'${pSecs.toString().padLeft(2, '0')}\"";
    }

    // Average Lifetime Speed
    double lifetimeDistance = widget.walks.fold(0.0, (sum, w) => sum + w.distanceKm);
    int lifetimeSeconds = widget.walks.fold(0, (sum, w) => sum + w.durationSeconds);
    double lifetimeAvgSpeed = 0.0;
    if (lifetimeSeconds > 0) {
      lifetimeAvgSpeed = lifetimeDistance / (lifetimeSeconds / 3600);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Insight Card
          _buildAIInsight(isDark, todayAvgSpeed, lifetimeAvgSpeed),
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
                    'Today\'s Avg Pace',
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
                        todayPaceString,
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
                        '/km',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
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
                  color: Colors.purple.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.speed_rounded, color: Colors.purple, size: 28),
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
                  'Best Pace',
                  bestPaceString,
                  Icons.directions_run_rounded,
                  AppColors.danger,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSmallMetricCard(
                  isDark,
                  'Avg Speed',
                  '${lifetimeAvgSpeed.toStringAsFixed(1)} km/h',
                  Icons.electric_bolt_rounded,
                  Colors.amber,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAIInsight(bool isDark, double todaySpeed, double avgSpeed) {
    String msg = "Maintaining a consistent pace helps improve cardiovascular health.";
    if (todaySpeed > avgSpeed && avgSpeed > 0) {
      msg = "Great effort! Your pace today is faster than your historical average.";
    } else if (todaySpeed < avgSpeed && todaySpeed > 0) {
      msg = "You're taking it easy today. A relaxed pace is great for recovery.";
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
            child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'StrideAI Performance Analysis',
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
    
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: 6 - i));
      final walks = widget.walks.where((w) => w.startTime.year == date.year && w.startTime.month == date.month && w.startTime.day == date.day);
      double dist = walks.fold(0.0, (sum, w) => sum + w.distanceKm);
      int secs = walks.fold(0, (sum, w) => sum + w.durationSeconds);
      weeklyData[i] = secs > 0 ? (dist / (secs / 3600.0)) : 0.0;
    }

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
                'Pace Trend',
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
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(7, (i) => FlSpot(i.toDouble(), weeklyData[i])),
                    isCurved: true,
                    color: Colors.purple,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: Colors.purple,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.purple.withOpacity(0.3),
                          Colors.purple.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
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
