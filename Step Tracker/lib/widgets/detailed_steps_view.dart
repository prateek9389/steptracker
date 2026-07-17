import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:stride_ai/theme/app_colors.dart';

class DetailedStepsView extends StatelessWidget {
  final int currentSteps;
  final int goal;
  final Map<String, int> hourlySteps;
  final String walkingStatus;
  final int activeMinutes;
  final double distanceKm;
  final int calories;
  final VoidCallback? onBack;

  const DetailedStepsView({
    super.key,
    required this.currentSteps,
    required this.goal,
    required this.hourlySteps,
    required this.walkingStatus,
    required this.activeMinutes,
    required this.distanceKm,
    required this.calories,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double progress = goal > 0 ? (currentSteps / goal).clamp(0.0, 1.0) : 0.0;
    final int remaining = goal > currentSteps ? goal - currentSteps : 0;

    final primaryPurple = const Color(0xFF6324D6); 
    final lightPurpleBg = const Color(0xFFF3EDFF);
    final textDark = isDark ? Colors.white : const Color(0xFF1E1E1E);
    final textGrey = isDark ? Colors.white60 : const Color(0xFF8E8E93);
    final cardBgColor = isDark ? const Color(0xFF161E2E) : Colors.white;
    final borderColor = isDark ? Colors.white12 : Colors.black.withOpacity(0.05);

    final int hours = activeMinutes ~/ 60;
    final int mins = activeMinutes % 60;
    final String activeTimeString = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';

    final int paceMins = distanceKm > 0 ? (activeMinutes ~/ distanceKm) : 0;
    final int paceSecs = distanceKm > 0 ? (((activeMinutes / distanceKm) - paceMins) * 60).toInt() : 0;

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

    int base = (currentSteps ~/ 5000) * 5000;
    int m1 = base == 0 ? 5000 : base;
    int m2 = m1 + 5000;
    int m3 = m2 + 5000;
    
    bool m1Reached = currentSteps >= m1;
    bool m2Reached = currentSteps >= m2;
    
    int nextRewardGoal = currentSteps < 5000 ? 5000 : m2;
    int stepsToNextMilestone = nextRewardGoal > currentSteps ? nextRewardGoal - currentSteps : 0;

    Widget buildCard({required Widget child, EdgeInsets padding = const EdgeInsets.all(20)}) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: padding,
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Top Card: Today's Steps
        buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (onBack != null) ...[
                    GestureDetector(
                      onTap: onBack,
                      child: Icon(Icons.arrow_back_rounded, color: textDark, size: 24),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: lightPurpleBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.directions_walk_rounded, color: primaryPurple, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Today's Steps",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            currentSteps.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},'),
                            style: TextStyle(
                              fontSize: 56, 
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w900,
                              color: primaryPurple,
                              height: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text("Steps", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textGrey)),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Icon(Icons.track_changes_rounded, color: primaryPurple, size: 18),
                            const SizedBox(width: 6),
                            Text('Goal: ', style: TextStyle(fontSize: 14, color: textGrey, fontWeight: FontWeight.w500)),
                            Text(
                              '${goal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} Steps',
                              style: TextStyle(fontSize: 14, color: primaryPurple, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: List.generate(7, (index) {
                            final bool isFilled = progress >= (index / 7.0);
                            return Expanded(
                              child: Container(
                                height: 8,
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: isFilled ? primaryPurple : (isDark ? Colors.white12 : const Color(0xFFE5E7EB)),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 12),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(fontSize: 14, fontFamily: 'Outfit'),
                              children: [
                                TextSpan(
                                  text: '${remaining.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} ',
                                  style: TextStyle(color: primaryPurple, fontWeight: FontWeight.bold),
                                ),
                                TextSpan(
                                  text: 'Steps Remaining',
                                  style: TextStyle(color: textGrey, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: SizedBox(
                        width: 130, 
                        height: 130,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: 1.0,
                              strokeWidth: 12,
                              color: isDark ? Colors.white12 : const Color(0xFFF3EDFF),
                            ),
                            CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 12,
                              color: primaryPurple,
                              strokeCap: StrokeCap.round,
                            ),
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.local_fire_department_rounded, color: primaryPurple, size: 28),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${(progress * 100).toInt()}%',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: textDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 2. Middle Chart Card (24 Hours)
        buildCard(
          padding: const EdgeInsets.only(left: 16, right: 24, top: 20, bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 20),
                child: Text(
                  "Today's Activity",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
                ),
              ),
              SizedBox(
                height: 140,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 2500,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: borderColor,
                        strokeWidth: 1,
                        dashArray: [4, 4],
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22, 
                          interval: 4,
                          getTitlesWidget: (value, meta) {
                            String text = '';
                            if (value == 0) text = '12 AM';
                            else if (value == 4) text = '4 AM';
                            else if (value == 8) text = '8 AM';
                            else if (value == 12) text = '12 PM';
                            else if (value == 16) text = '4 PM';
                            else if (value == 20) text = '8 PM';
                            else if (value == 24) text = '12 AM';
                            
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(text, style: TextStyle(color: textGrey, fontWeight: FontWeight.w600, fontSize: 10)),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 2500,
                          reservedSize: 32, 
                          getTitlesWidget: (value, meta) {
                            String text = '';
                            if (value == 0) text = '0';
                            else if (value == 2500) text = '2.5K';
                            else if (value == 5000) text = '5K';
                            else if (value == 7500) text = '7.5K';
                            else if (value == 10000) text = '10K';
                            return Text(text, style: TextStyle(color: textGrey, fontWeight: FontWeight.w600, fontSize: 10));
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: 24,
                    minY: 0,
                    maxY: 10000,
                    lineBarsData: [
                      LineChartBarData(
                        spots: _generate24HourSpots(),
                        isCurved: true,
                        color: primaryPurple,
                        barWidth: 2,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          checkToShowDot: (spot, barData) => spot.x == DateTime.now().hour.toDouble(),
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: Colors.white,
                              strokeWidth: 2,
                              strokeColor: primaryPurple,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [primaryPurple.withOpacity(0.3), primaryPurple.withOpacity(0.0)],
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
        ),

        // 3. Status & Active Time Row
        Row(
          children: [
            // Status Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF064E3B).withOpacity(0.3) : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: isDark ? Colors.white12 : Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.directions_walk_rounded, color: Color(0xFF16A34A), size: 28),
                        ),
                        const Spacer(),
                        if (walkingStatus == 'Walking')
                          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Status', style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : const Color(0xFF4B5563))),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(walkingStatus, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                    ),
                    const SizedBox(height: 16),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.sensors_rounded, size: 14, color: Color(0xFF16A34A)),
                            const SizedBox(width: 6),
                            Text('Live Tracking Active', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Active Time Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E3A8A).withOpacity(0.3) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: isDark ? Colors.white12 : Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.timer_outlined, color: Color(0xFF2563EB), size: 28),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Active Time', style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : const Color(0xFF4B5563))),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(activeTimeString, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                    ),
                    const SizedBox(height: 16),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF2563EB)),
                            const SizedBox(width: 6),
                            Text('Total Walking Time', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 4. Next Reward Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF78350F).withOpacity(0.3) : const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: isDark ? Colors.white12 : Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.stars_rounded, color: Color(0xFFF59E0B), size: 36),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Next Reward', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1F2937))),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(fontSize: 14, fontFamily: 'Outfit'),
                              children: [
                                TextSpan(
                                  text: '${stepsToNextMilestone.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} ',
                                  style: const TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.bold),
                                ),
                                TextSpan(text: 'more steps to earn ', style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF4B5563))),
                                const TextSpan(text: '50 Coins', style: TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white54 : Colors.black26, size: 28),
                ],
              ),
              const SizedBox(height: 24),
              // Linear Reward Track
              Row(
                children: [
                  _buildRewardNode(active: m1Reached, icon: m1Reached ? Icons.check_circle_rounded : Icons.directions_walk_rounded, label: '${m1 ~/ 1000}K Steps', isCurrent: currentSteps < m2 && m1Reached),
                  Expanded(child: Container(height: 2, color: m1Reached ? const Color(0xFFF59E0B) : Colors.grey[300])),
                  _buildRewardNode(active: m2Reached, icon: m2Reached ? Icons.check_circle_rounded : (m1Reached ? Icons.directions_walk_rounded : Icons.lock_rounded), label: '${m2 ~/ 1000}K Steps', isCurrent: currentSteps >= m1 && currentSteps < m3 && !m2Reached),
                  Expanded(child: Container(height: 2, color: m2Reached ? const Color(0xFFF59E0B) : Colors.grey[300])),
                  _buildRewardNode(active: false, icon: m2Reached ? Icons.directions_walk_rounded : Icons.lock_rounded, label: '${m3 ~/ 1000}K Steps', isCurrent: currentSteps >= m2),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 5. AI Coach Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? primaryPurple.withOpacity(0.15) : lightPurpleBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Row(
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
                    Row(
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text('AI Coach', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryPurple)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '"$motivationMsg"',
                      style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : const Color(0xFF1F2937)),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white54 : Colors.black26, size: 28),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 6. Bottom Stats Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomStat(Icons.directions_run_rounded, Colors.blue, '${distanceKm.toStringAsFixed(1)} km', 'Distance'),
            _buildBottomStat(Icons.local_fire_department_rounded, Colors.deepOrange, '$calories kcal', 'Calories'),
            _buildBottomStat(Icons.timer_outlined, Colors.green, activeTimeString, 'Active Time'),
            _buildBottomStat(Icons.speed_rounded, primaryPurple, '$paceMins\'$paceSecs"', 'Avg. Pace'),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildRewardNode({required bool active, required IconData icon, required String label, bool isCurrent = false}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFF59E0B) : Colors.grey[300],
            shape: BoxShape.circle,
            border: isCurrent ? Border.all(color: Colors.white, width: 2) : null,
            boxShadow: isCurrent ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : null,
          ),
          child: Icon(icon, size: 16, color: active ? Colors.white : Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF4B5563))),
      ],
    );
  }

  Widget _buildBottomStat(IconData icon, Color color, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  List<FlSpot> _generate24HourSpots() {
    List<FlSpot> spots = [];
    final currentHour = DateTime.now().hour;
    int cumulativeSteps = 0;
    
    for (int i = 0; i <= currentHour; i++) {
      final hourKey = '${i.toString().padLeft(2, '0')}:00';
      final stepsInHour = hourlySteps[hourKey] ?? 0;
      cumulativeSteps += stepsInHour;
      if (i == currentHour) {
        spots.add(FlSpot(i.toDouble(), currentSteps.toDouble()));
      } else {
        spots.add(FlSpot(i.toDouble(), cumulativeSteps.toDouble()));
      }
    }
    
    if (spots.isEmpty) return [const FlSpot(0, 0)];
    return spots;
  }
}
