import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stride_ai/models/walk_session.dart';

class RecentWalksList extends StatelessWidget {
  final List<WalkSession> walks;

  const RecentWalksList({super.key, required this.walks});

  @override
  Widget build(BuildContext context) {
    if (walks.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Walks', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
            TextButton(
              onPressed: () {}, // Could navigate to history tab
              child: Text('See All', style: TextStyle(color: const Color(0xFF6324D6), fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: walks.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: _buildWalkCard(context, walks[index], isDark),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWalkCard(BuildContext context, WalkSession walk, bool isDark) {
    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? Colors.white12 : Colors.grey[200]!;
    
    // Determine walk title
    String title = "Walk";
    if (walk.startTime.hour < 12) {
      title = "Morning Walk";
    } else if (walk.startTime.hour < 17) {
      title = "Afternoon Walk";
    } else {
      title = "Evening Walk";
    }
    // Override if weekend
    if (walk.startTime.weekday == 6 || walk.startTime.weekday == 7) {
      title = "${DateFormat('EEEE').format(walk.startTime)} Walk";
    }

    final durationMins = walk.durationSeconds ~/ 60;
    
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Map Header (mock map image / gradient)
          Container(
            height: 70,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              gradient: LinearGradient(
                colors: [const Color(0xFF6324D6).withOpacity(0.3), const Color(0xFF10B981).withOpacity(0.3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Icon(Icons.map_rounded, color: isDark ? Colors.white54 : Colors.black26, size: 30),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                const SizedBox(height: 4),
                Text(
                  '${DateFormat('EEEE, h:mm a').format(walk.startTime)}',
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMiniStat(Icons.location_on_rounded, const Color(0xFF10B981), '${walk.distanceKm.toStringAsFixed(1)} km', isDark),
                    _buildMiniStat(Icons.timer_outlined, const Color(0xFF3B82F6), '${durationMins}m', isDark),
                    _buildMiniStat(Icons.local_fire_department_rounded, const Color(0xFFF97316), '${walk.calories}', isDark),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, Color color, String text, bool isDark) {
    return Row(
      children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87)),
      ],
    );
  }
}
