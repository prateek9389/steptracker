import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:stride_ai/models/walk_session.dart';
import 'package:stride_ai/models/daily_stat.dart';
import 'package:stride_ai/theme/app_colors.dart';

class DistanceTab extends StatefulWidget {
  final List<WalkSession> walks;
  final List<DailyStat> dailyStats;

  const DistanceTab({
    Key? key,
    required this.walks,
    required this.dailyStats,
  }) : super(key: key);

  @override
  State<DistanceTab> createState() => _DistanceTabState();
}

class _DistanceTabState extends State<DistanceTab> {
  String _timeRange = 'Daily';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final now = DateTime.now();
    
    // Today's Distance
    final todayWalks = widget.walks.where((s) => s.startTime.year == now.year && s.startTime.month == now.month && s.startTime.day == now.day);
    double todayDistance = todayWalks.fold(0.0, (sum, w) => sum + w.distanceKm);

    // Total Lifetime Distance
    double totalLifetimeDistance = widget.walks.fold(0.0, (sum, w) => sum + w.distanceKm);

    // Longest Walk
    double longestWalk = 0.0;
    WalkSession? longestSession;
    for (var w in widget.walks) {
      if (w.distanceKm > longestWalk) {
        longestWalk = w.distanceKm;
        longestSession = w;
      }
    }

    // Average Daily Distance
    int activeDays = widget.dailyStats.where((s) => s.steps > 0).length;
    double avgDailyDistance = activeDays > 0 ? totalLifetimeDistance / activeDays : 0.0;

    // Recent Route
    WalkSession? recentRouteSession;
    for (var w in widget.walks) {
      if (w.route.isNotEmpty) {
        recentRouteSession = w;
        break;
      }
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
                    'Today\'s Distance',
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
                        todayDistance < 1.0 ? '${(todayDistance * 1000).toInt()}' : todayDistance.toStringAsFixed(2),
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
                        todayDistance < 1.0 ? 'm' : 'km',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
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
                  color: AppColors.secondary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_on_rounded, color: AppColors.secondary, size: 28),
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
                  'Total Distance',
                  totalLifetimeDistance < 1.0 ? '${(totalLifetimeDistance * 1000).toInt()} m' : '${totalLifetimeDistance.toStringAsFixed(1)} km',
                  Icons.map_rounded,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSmallMetricCard(
                  isDark,
                  'Longest Walk',
                  longestWalk < 1.0 ? '${(longestWalk * 1000).toInt()} m' : '${longestWalk.toStringAsFixed(2)} km',
                  Icons.emoji_events_rounded,
                  Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSmallMetricCard(
            isDark,
            'Average Daily Distance',
            avgDailyDistance < 1.0 ? '${(avgDailyDistance * 1000).toInt()} m/day' : '${avgDailyDistance.toStringAsFixed(2)} km/day',
            Icons.query_stats_rounded,
            Colors.teal,
          ),
          const SizedBox(height: 32),

          // Map Preview
          if (recentRouteSession != null) ...[
            Text(
              'Most Recent Route',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildMapPreview(isDark, recentRouteSession),
          ],
        ],
      ),
    );
  }

  Widget _buildMapPreview(bool isDark, WalkSession session) {
    if (session.route.isEmpty) return const SizedBox();

    List<LatLng> points = session.route.map((p) => LatLng(p.latitude, p.longitude)).toList();
    
    // Calculate bounds
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    // Fix for "Infinity or NaN toInt" crash when route bounds have zero area
    if (minLat == maxLat) {
      minLat -= 0.002;
      maxLat += 0.002;
    }
    if (minLng == maxLng) {
      minLng -= 0.002;
      maxLng += 0.002;
    }

    final bounds = LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );

    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withOpacity(0.05),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: FlutterMap(
          options: MapOptions(
            initialCameraFit: CameraFit.bounds(
              bounds: bounds,
              padding: const EdgeInsets.all(32),
            ),
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none, // Static preview map
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.strideai.app',
            ),
            PolylineLayer(
              polylines: [
                Polyline(
                  points: points,
                  color: AppColors.primary,
                  strokeWidth: 5,
                  isDotted: false,
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: points.first,
                  width: 20,
                  height: 20,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                    ),
                  ),
                ),
                Marker(
                  point: points.last,
                  width: 20,
                  height: 20,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection(bool isDark) {
    final now = DateTime.now();
    final List<double> weeklyData = List.filled(7, 0.0);
    
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: 6 - i));
      final walks = widget.walks.where((w) => w.startTime.year == date.year && w.startTime.month == date.month && w.startTime.day == date.day);
      weeklyData[i] = walks.fold(0.0, (sum, w) => sum + w.distanceKm);
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
                'Distance Trend',
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
                    color: AppColors.secondary,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
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
                          AppColors.secondary.withOpacity(0.3),
                          AppColors.secondary.withOpacity(0.0),
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
