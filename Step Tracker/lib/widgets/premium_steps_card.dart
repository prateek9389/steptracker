import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:stride_ai/theme/app_colors.dart';
import 'glass_card.dart';
import 'circular_progress_ring.dart';

class PremiumStepsCard extends StatelessWidget {
  final bool showTotal;
  final int currentSteps;
  final int totalAppSteps;
  final int goal;
  final Map<String, int> hourlySteps;
  final String walkingStatus;
  final int activeMinutes;
  final bool isCompact;
  final VoidCallback? onTap;

  const PremiumStepsCard({
    super.key,
    required this.showTotal,
    required this.currentSteps,
    required this.totalAppSteps,
    required this.goal,
    required this.hourlySteps,
    required this.walkingStatus,
    required this.activeMinutes,
    this.isCompact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final int displaySteps = showTotal ? totalAppSteps : currentSteps;
    final double progress = goal > 0 ? (displaySteps / goal).clamp(0.0, 1.0) : 0.0;
    final int remaining = goal > displaySteps ? goal - displaySteps : 0;
    
    // AI Motivation
    String motivationMsg = "Let's get moving!";
    if (progress >= 1.0) {
      motivationMsg = "Goal Completed! Outstanding!";
    } else if (progress >= 0.8) {
      motivationMsg = "Almost there! Keep pushing!";
    } else if (progress >= 0.5) {
      motivationMsg = "Halfway there! Great pace.";
    } else if (progress > 0.0) {
      motivationMsg = "Good start! Keep it up.";
    }

    // Chart logic
    final spots = _generateHourlySpots();

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: GlassCard(
        padding: const EdgeInsets.all(24.0),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFF8B5CF6), const Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and Goal Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusBadge(isDark),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Goal: $goal',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Steps & Ring Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        showTotal ? 'Total App Steps' : "Today's Steps",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TweenAnimationBuilder<int>(
                        tween: IntTween(begin: 0, end: displaySteps),
                        duration: const Duration(seconds: 1),
                        curve: Curves.easeOutQuart,
                        builder: (context, value, child) {
                          return Text(
                            value.toString(),
                            style: const TextStyle(
                              fontSize: 48,
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        motivationMsg,
                        style: TextStyle(
                          color: progress >= 1.0 ? const Color(0xFF10B981) : Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                CircularProgressRing(
                  progress: progress,
                  size: 100,
                  strokeWidth: 10,
                  trackColor: Colors.white.withOpacity(0.1),
                  gradientColors: progress >= 1.0 
                      ? const [Color(0xFF10B981), Color(0xFF34D399)]
                      : const [Color(0xFFF472B6), Color(0xFF38BDF8), Color(0xFFA855F7)],
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          progress > 0 && (progress * 100) < 1
                              ? '<1%'
                              : '${(progress * 100).toInt()}%',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 28),
            
            // Hourly Chart
            if (!isCompact && !showTotal)
              SizedBox(
                height: 80,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots.isEmpty ? [const FlSpot(0, 0), const FlSpot(1, 0)] : spots,
                        isCurved: true,
                        color: Colors.white,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          checkToShowDot: (spot, barData) {
                            return spot.x == spots.last.x;
                          },
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: Colors.white,
                              strokeWidth: 2,
                              strokeColor: AppColors.secondary,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.25),
                              Colors.white.withOpacity(0.0),
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

            if (!showTotal && !isCompact) const SizedBox(height: 24),
            
            // Info row
            if (!showTotal && !isCompact)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildInfoColumn('Active Time', '${activeMinutes}m'),
                    Container(width: 1, height: 30, color: Colors.white24),
                    _buildInfoColumn('Remaining', '$remaining'),
                    Container(width: 1, height: 30, color: Colors.white24),
                    _buildInfoColumn('Rewards', progress >= 1.0 ? 'Earned' : '${remaining} left'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isDark) {
    final bool isWalking = walkingStatus == 'Walking';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isWalking ? const Color(0xFF10B981).withOpacity(0.2) : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isWalking ? const Color(0xFF10B981).withOpacity(0.5) : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isWalking ? const Color(0xFF10B981) : Colors.white54,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            walkingStatus,
            style: TextStyle(
              color: isWalking ? const Color(0xFF10B981) : Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  List<FlSpot> _generateHourlySpots() {
    if (hourlySteps.isEmpty) {
      return [const FlSpot(0, 0)];
    }
    
    // Sort keys just in case
    final sortedKeys = hourlySteps.keys.toList()..sort();
    List<FlSpot> spots = [];
    
    double x = 0;
    for (String key in sortedKeys) {
      spots.add(FlSpot(x, hourlySteps[key]!.toDouble()));
      x += 1;
    }
    
    return spots;
  }
}
