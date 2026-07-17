import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:stride_ai/providers/weekly_analytics_provider.dart';
import 'package:stride_ai/models/daily_stat.dart';

class StepsOverviewChart extends StatelessWidget {
  final WeeklyAnalyticsState state;
  final int selectedIndex;
  final ValueChanged<int> onDaySelected;

  const StepsOverviewChart({
    super.key,
    required this.state,
    required this.selectedIndex,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? Colors.white12 : Colors.grey[200]!;
    final primaryPurple = const Color(0xFF6324D6);
    
    // Default goal if no stats, otherwise use goal from first stat (assuming 10k default)
    double goal = 10000;
    
    // Prepare data
    // FlChart expects data on X axis. Let's make X = 0 (Mon) to 6 (Sun).
    final List<BarChartGroupData> barGroups = [];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    // Create an array of 7 items initialized to 0
    List<int> stepsArray = List.filled(7, 0);
    int highestSteps = 0;
    int highestIndex = -1;

    for (var stat in state.currentWeekStats) {
      // weekday is 1 for Mon, 7 for Sun
      int index = stat.date.weekday - 1;
      if (index >= 0 && index < 7) {
        stepsArray[index] = stat.steps;
        if (stat.steps > highestSteps) {
          highestSteps = stat.steps;
          highestIndex = index;
        }
      }
    }

    for (int i = 0; i < 7; i++) {
      final isSelected = i == selectedIndex;
      final isHighest = i == highestIndex;
      
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: stepsArray[i].toDouble(),
              width: 24,
              gradient: LinearGradient(
                colors: isSelected 
                  ? [primaryPurple, primaryPurple.withOpacity(0.7)] 
                  : [primaryPurple.withOpacity(0.6), primaryPurple.withOpacity(0.3)],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: 15000, // Max Y
                color: Colors.transparent,
              ),
            ),
          ],
          showingTooltipIndicators: stepsArray[i] > 0 ? [0] : [],
        ),
      );
    }

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Steps Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: primaryPurple, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('Steps', style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54)),
                  const SizedBox(width: 16),
                  Container(width: 16, height: 1, color: isDark ? Colors.white54 : Colors.black54), // Should be dashed, keeping simple
                  const SizedBox(width: 6),
                  Text('Goal 10,000', style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 40),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 16000,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchCallback: (FlTouchEvent event, barTouchResponse) {
                    if (!event.isInterestedForInteractions ||
                        barTouchResponse == null ||
                        barTouchResponse.spot == null) {
                      return;
                    }
                    if (event is FlTapUpEvent) {
                      onDaySelected(barTouchResponse.spot!.touchedBarGroupIndex);
                    }
                  },
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => Colors.transparent,
                    tooltipPadding: const EdgeInsets.only(bottom: 0),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final isHighest = group.x == highestIndex;
                      return BarTooltipItem(
                        isHighest ? '👑\n' : '',
                        const TextStyle(fontSize: 14),
                        children: [
                          TextSpan(
                            text: NumberFormat('#,###').format(rod.toY.toInt()),
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= 7) return const SizedBox.shrink();
                        final isSelected = index == selectedIndex;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            days[index],
                            style: TextStyle(
                              color: isSelected ? primaryPurple : (isDark ? Colors.white54 : Colors.black54),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 5000,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return _buildYAxisLabel('0', isDark);
                        if (value == 5000) return _buildYAxisLabel('5K', isDark);
                        if (value == 10000) return _buildYAxisLabel('10K', isDark);
                        if (value == 15000) return _buildYAxisLabel('15K', isDark);
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 5000,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: isDark ? Colors.white12 : Colors.grey[200]!,
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: goal,
                      color: isDark ? Colors.white54 : Colors.black38,
                      strokeWidth: 1.5,
                      dashArray: [6, 4],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYAxisLabel(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Text(
        text,
        textAlign: TextAlign.right,
        style: TextStyle(
          color: isDark ? Colors.white54 : Colors.black54,
          fontSize: 12,
        ),
      ),
    );
  }
}
