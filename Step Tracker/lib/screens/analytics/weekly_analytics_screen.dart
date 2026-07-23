import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/walk_provider.dart';
import '../../providers/stats_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/reward_provider.dart';
import '../../providers/step_provider.dart';
import '../../models/daily_stat.dart';
import '../../models/walk_session.dart';
import '../../models/reward_history.dart';
import '../ai_coach/ai_coach_screen.dart';

class WeeklyAnalyticsScreen extends ConsumerStatefulWidget {
  const WeeklyAnalyticsScreen({super.key});

  @override
  ConsumerState<WeeklyAnalyticsScreen> createState() => _WeeklyAnalyticsScreenState();
}

class _WeeklyAnalyticsScreenState extends ConsumerState<WeeklyAnalyticsScreen> {
  String _selectedPeriod = 'Week';
  int _selectedIndex = -1;

  List<int> _steps = [];
  List<double> _distance = [];
  List<int> _calories = [];
  List<int> _actMin = [];
  List<String> _days = [];
  List<int> _dates = [];
  List<String> _dayNames = [];
  int _prevTotal = 0;
  List<WalkSession> _walks = [];
  Map<String, DailyStat> _allStatsMap = {};
  DateTime _referenceDate = DateTime.now();
  
  bool _statsComputedForCurrentPeriod = false;
  String _lastComputedPeriod = '';

  static const _purple = Color(0xFF6324D6);
  static const _green  = Color(0xFF10B981);
  static const _orange = Color(0xFFF97316);
  static const _blue   = Color(0xFF3B82F6);

  int get _totalSteps    => _steps.fold(0, (a, b) => a + b);
  double get _totalDist  => _distance.fold(0.0, (a, b) => a + b);
  int get _totalCal      => _calories.fold(0, (a, b) => a + b);
  int get _totalActMin   => _actMin.fold(0, (a, b) => a + b);
  double get _pctChange  => _prevTotal > 0 ? ((_totalSteps - _prevTotal) / _prevTotal) * 100 : 100.0;

  void _computeStats() {

    final statsList = ref.watch(allDailyStatsStreamProvider).value ?? [];
    _walks = ref.watch(walkHistoryStreamProvider).value ?? [];
    
    _allStatsMap = {};
    for (var s in statsList) {
      _allStatsMap['${s.date.year}-${s.date.month}-${s.date.day}'] = s;
    }

    final actualNow = DateTime.now();
    final todayKey = '${actualNow.year}-${actualNow.month}-${actualNow.day}';
    final stepState = ref.watch(stepProvider);

    // Override today's entry in _allStatsMap with real-time app state
    _allStatsMap[todayKey] = DailyStat(
      dateId: todayKey,
      uid: '',
      date: actualNow,
      steps: stepState.todaySteps,
      distanceKm: stepState.todayDistanceKm,
      calories: stepState.todayCalories,
      activeMinutes: stepState.activeMinutes,
      walkingTimeSeconds: stepState.activeMinutes * 60,
      goalCompleted: stepState.todaySteps >= 10000,
      hourlySteps: stepState.hourlySteps,
      walkingStatus: stepState.walkingStatus,
    );

    final now = _referenceDate;
    
    int numPoints = 7;
    if (_selectedPeriod == 'Day') numPoints = 1;
    else if (_selectedPeriod == 'Month') numPoints = 4;
    else if (_selectedPeriod == 'Year') numPoints = 12;

    _steps = List.filled(numPoints, 0);
    _distance = List.filled(numPoints, 0.0);
    _calories = List.filled(numPoints, 0);
    _actMin = List.filled(numPoints, 0);
    _days = List.filled(numPoints, '');
    _dates = List.filled(numPoints, 0);
    _dayNames = List.filled(numPoints, '');

    _prevTotal = 0;

    if (_selectedPeriod == 'Day') {
      _days[0] = DateFormat('E').format(now);
      _dates[0] = now.day;
      _dayNames[0] = DateFormat('EEEE').format(now);
      final k = '${now.year}-${now.month}-${now.day}';
      if (_allStatsMap.containsKey(k)) {
        final s = _allStatsMap[k]!;
        _steps[0] = s.steps; _distance[0] = s.distanceKm; _calories[0] = s.calories; _actMin[0] = s.activeMinutes;
      }
      final yK = '${now.subtract(const Duration(days: 1)).year}-${now.subtract(const Duration(days: 1)).month}-${now.subtract(const Duration(days: 1)).day}';
      if (_allStatsMap.containsKey(yK)) _prevTotal = _allStatsMap[yK]!.steps;
      _selectedIndex = 0;
    } else if (_selectedPeriod == 'Week') {
      for (int i = 0; i < 7; i++) {
        final date = now.subtract(Duration(days: 6 - i));
        _days[i] = DateFormat('E').format(date);
        _dates[i] = date.day;
        _dayNames[i] = DateFormat('EEEE').format(date);
        final k = '${date.year}-${date.month}-${date.day}';
        if (_allStatsMap.containsKey(k)) {
          final s = _allStatsMap[k]!;
          _steps[i] = s.steps; _distance[i] = s.distanceKm; _calories[i] = s.calories; _actMin[i] = s.activeMinutes;
        }
      }
      for (int i = 0; i < 7; i++) {
        final date = now.subtract(Duration(days: 13 - i));
        final k = '${date.year}-${date.month}-${date.day}';
        if (_allStatsMap.containsKey(k)) _prevTotal += _allStatsMap[k]!.steps;
      }
      if (_selectedIndex < 0 || _selectedIndex > 6) _selectedIndex = 6;
    } else if (_selectedPeriod == 'Month') {
      for (int i = 0; i < 4; i++) {
        final endDate = now.subtract(Duration(days: (3 - i) * 7));
        final startDate = endDate.subtract(const Duration(days: 6));
        _days[i] = 'W${i+1}';
        _dates[i] = endDate.day;
        _dayNames[i] = 'Week of ${DateFormat('MMM d').format(startDate)}';
        
        for (int d = 0; d < 7; d++) {
          final date = startDate.add(Duration(days: d));
          final k = '${date.year}-${date.month}-${date.day}';
          if (_allStatsMap.containsKey(k)) {
            final s = _allStatsMap[k]!;
            _steps[i] += s.steps; _distance[i] += s.distanceKm; _calories[i] += s.calories; _actMin[i] += s.activeMinutes;
          }
        }
      }
      for (int d = 0; d < 28; d++) {
        final date = now.subtract(Duration(days: 28 + d));
        final k = '${date.year}-${date.month}-${date.day}';
        if (_allStatsMap.containsKey(k)) _prevTotal += _allStatsMap[k]!.steps;
      }
      if (_selectedIndex < 0 || _selectedIndex > 3) _selectedIndex = 3;
    } else if (_selectedPeriod == 'Year') {
      for (int i = 0; i < 12; i++) {
        final m = DateTime(now.year, now.month - (11 - i), 1);
        _days[i] = DateFormat('MMM').format(m);
        _dates[i] = m.month;
        _dayNames[i] = DateFormat('MMMM yyyy').format(m);
        
        _allStatsMap.forEach((k, s) {
          if (s.date.year == m.year && s.date.month == m.month) {
            _steps[i] += s.steps; _distance[i] += s.distanceKm; _calories[i] += s.calories; _actMin[i] += s.activeMinutes;
          }
        });
      }
      for (int mOffset = 0; mOffset < 12; mOffset++) {
        final m = DateTime(now.year - 1, now.month - mOffset, 1);
        _allStatsMap.forEach((k, s) {
          if (s.date.year == m.year && s.date.month == m.month) {
            _prevTotal += s.steps;
          }
        });
      }
      if (_selectedIndex < 0 || _selectedIndex > 11) _selectedIndex = 11;
    }
    
    _statsComputedForCurrentPeriod = true;
    _lastComputedPeriod = _selectedPeriod;
  }

  String _fmtDur(int mins) {
    final h = mins ~/ 60; final m = mins % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  String _pace(int mins, double km) {
    if (km == 0) return '0:00';
    final p = mins / km;
    return '${p.toInt()}:${((p - p.toInt()) * 60).toInt().toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    _computeStats();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB);
    final textPrimary = isDark ? Colors.white : const Color(0xFF111827);

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            pinned: false,
            toolbarHeight: 70,
            backgroundColor: isDark ? const Color(0xFF0F172A).withOpacity(0.75) : const Color(0xFFF9FAFB).withOpacity(0.85),
            elevation: 0,
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: textPrimary, size: 24),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$_selectedPeriod Progress',
                    style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 22, fontFamily: 'Outfit')),
                Row(children: [
                  Text(_selectedPeriod == 'Day' ? DateFormat('d MMM yyyy').format(_referenceDate) : _selectedPeriod == 'Week' ? '${DateFormat('d MMM').format(_referenceDate.subtract(const Duration(days: 6)))} - ${DateFormat('d MMM yyyy').format(_referenceDate)}' : _selectedPeriod == 'Month' ? '${DateFormat('d MMM').format(_referenceDate.subtract(const Duration(days: 27)))} - ${DateFormat('d MMM yyyy').format(_referenceDate)}' : '${DateFormat('MMM yyyy').format(DateTime(_referenceDate.year, _referenceDate.month - 11, 1))} - ${DateFormat('MMM yyyy').format(_referenceDate)}',
                      style: TextStyle(color: textPrimary.withOpacity(0.5), fontSize: 13)),
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 14,
                      color: textPrimary.withOpacity(0.5)),
                ]),
              ],
            ),
            actions: [
              GestureDetector(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _referenceDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      final isDark = Theme.of(context).brightness == Brightness.dark;
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: isDark
                              ? const ColorScheme.dark(primary: _purple)
                              : const ColorScheme.light(primary: _purple),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null && picked != _referenceDate) {
                    setState(() {
                      _referenceDate = picked;
                      _statsComputedForCurrentPeriod = false;
                      _selectedIndex = -1;
                    });
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                  ),
                  child: Icon(Icons.calendar_month_rounded, color: textPrimary, size: 20),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: SafeArea(
              top: false,
              bottom: true,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTabs(isDark),
                    const SizedBox(height: 20),
                    _buildSummaryGrid(isDark),
                    const SizedBox(height: 20),
                    if (_selectedPeriod != 'Day') _buildStepsChart(isDark),
                    const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 600) {
                          return Column(
                            children: [
                              _buildDailyDetails(isDark),
                              const SizedBox(height: 20),
                              _buildWeeklyTrends(isDark),
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildDailyDetails(isDark)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildWeeklyTrends(isDark)),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildBestPerformance(isDark),
                    const SizedBox(height: 20),
                    _buildAiCoach(isDark),
                    const SizedBox(height: 20),
                    _buildChallengesRewards(isDark),
                    const SizedBox(height: 20),
                    _buildRecentWalks(isDark),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── TABS ────────────────────────────────────────────────────
  Widget _buildTabs(bool isDark) {
    final tabs = ['Day', 'Week', 'Month', 'Year'];
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white12 : Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: tabs.map((t) {
          final selected = t == _selectedPeriod;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() { _selectedPeriod = t; _selectedIndex = -1; _statsComputedForCurrentPeriod = false; }),
              child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? _purple : Colors.transparent,
                borderRadius: BorderRadius.circular(30),
                boxShadow: selected
                    ? [BoxShadow(color: _purple.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                    : [],
              ),
              child: Text(t,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? Colors.white : (isDark ? Colors.white54 : Colors.black54),
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  )),
            ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── SUMMARY GRID ────────────────────────────────────────────
  Widget _buildSummaryGrid(bool isDark) {
    return Column(children: [
      Row(children: [
        Expanded(child: _summaryCard(isDark, Icons.directions_walk_rounded, _purple,
            'Total Steps', NumberFormat('#,###').format(_totalSteps), '',
            '${_pctChange >= 0 ? '+' : ''}${_pctChange.toStringAsFixed(1)}% vs last ${_selectedPeriod.toLowerCase()}', isSteps: true)),
        const SizedBox(width: 10),
        Expanded(child: _summaryCard(isDark, Icons.location_on_rounded, _green,
            'Distance', _totalDist.toStringAsFixed(1), 'km',
            'Based on daily stats')),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _summaryCard(isDark, Icons.local_fire_department_rounded, _orange,
            'Calories', NumberFormat('#,###').format(_totalCal), 'kcal',
            'Based on daily stats')),
        const SizedBox(width: 10),
        Expanded(child: _summaryCard(isDark, Icons.timer_outlined, _blue,
            'Active Time', _fmtDur(_totalActMin), '',
            'Based on daily stats')),
      ]),
    ]);
  }

  Widget _summaryCard(bool isDark, IconData icon, Color color,
      String title, String value, String unit, String subtitle,
      {bool isSteps = false}) {
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? Colors.white12 : Colors.grey.shade200;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(height: 10),
        Text(title, style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black54)),
        const SizedBox(height: 4),
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          Flexible(child: Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87), overflow: TextOverflow.ellipsis)),
          if (unit.isNotEmpty) ...[const SizedBox(width: 3), Text(unit, style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54))],
        ]),
        const SizedBox(height: 10),
        if (isSteps) ...[
          Text(subtitle, style: const TextStyle(fontSize: 10, color: _purple)),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(value: 1.0, backgroundColor: Colors.grey.shade200, valueColor: const AlwaysStoppedAnimation(_purple), minHeight: 4),
          ),
        ] else
          Text(subtitle,
              style: TextStyle(
                  fontSize: 10,
                  color: subtitle.contains('+') ? _green : (isDark ? Colors.white54 : Colors.black54)),
              overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  // ── STEPS CHART ─────────────────────────────────────────────
  Widget _buildStepsChart(bool isDark) {
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? Colors.white12 : Colors.grey.shade200;

    if (_steps.isEmpty) return const SizedBox.shrink();
    final barGroups = List.generate(_steps.length, (i) {
      return BarChartGroupData(x: i, barRods: [
        BarChartRodData(
          toY: _steps[i].toDouble(),
          width: 22,
          gradient: LinearGradient(
            colors: i == _selectedIndex
                ? [_purple, _purple.withOpacity(0.7)]
                : [_purple.withOpacity(0.6), _purple.withOpacity(0.3)],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ]);
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Steps Overview', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          Row(children: [
            Container(width: 8, height: 8, decoration: const BoxDecoration(color: _purple, shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Text('Steps', style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black54)),
            const SizedBox(width: 12),
            Container(width: 14, height: 1, color: isDark ? Colors.white54 : Colors.black38),
            const SizedBox(width: 5),
            Text('Goal 10,000', style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black54)),
          ]),
        ]),
        const SizedBox(height: 24),
        SizedBox(
          height: 220,
          child: BarChart(BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: 16000,
            barTouchData: BarTouchData(
              enabled: true,
              touchCallback: (event, response) {
                if (event is FlTapUpEvent && response?.spot != null) {
                  setState(() => _selectedIndex = response!.spot!.touchedBarGroupIndex);
                }
              },
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => Colors.transparent,
                tooltipMargin: 6,
                getTooltipItem: (group, gi, rod, ri) {
                  final isHighest = _steps[group.x] == _steps.reduce((a, b) => a > b ? a : b);
                  return BarTooltipItem(
                    isHighest ? '👑\n' : '',
                    const TextStyle(fontSize: 14),
                    children: [
                      TextSpan(
                        text: NumberFormat('#,###').format(rod.toY.toInt()),
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true, reservedSize: 28,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= _steps.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(_days[i],
                        style: TextStyle(
                          color: i == _selectedIndex ? _purple : (isDark ? Colors.white54 : Colors.black54),
                          fontWeight: i == _selectedIndex ? FontWeight.bold : FontWeight.normal,
                          fontSize: 11,
                        )),
                  );
                },
              )),
              leftTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true, reservedSize: 38, interval: 5000,
                getTitlesWidget: (v, _) {
                  if (v == 0) return _yLabel('0', isDark);
                  if (v == 5000) return _yLabel('5K', isDark);
                  if (v == 10000) return _yLabel('10K', isDark);
                  if (v == 15000) return _yLabel('15K', isDark);
                  return const SizedBox.shrink();
                },
              )),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              show: true, drawVerticalLine: false, horizontalInterval: 5000,
              getDrawingHorizontalLine: (_) => FlLine(
                color: isDark ? Colors.white12 : Colors.grey.shade200,
                strokeWidth: 1, dashArray: [4, 4],
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: barGroups,
            extraLinesData: ExtraLinesData(horizontalLines: [
              HorizontalLine(y: 10000, color: isDark ? Colors.white38 : Colors.black26,
                  strokeWidth: 1.5, dashArray: [6, 4]),
            ]),
          )),
        ),
      ]),
    );
  }

  Widget _yLabel(String t, bool isDark) => Padding(
    padding: const EdgeInsets.only(right: 6),
    child: Text(t, textAlign: TextAlign.right,
        style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54)),
  );

  // ── DAILY DETAILS ───────────────────────────────────────────
  Widget _buildDailyDetails(bool isDark) {
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? Colors.white12 : Colors.grey.shade200;
    if (_steps.isEmpty) return const SizedBox.shrink();
    final i = _selectedIndex;
    final steps = _steps[i]; final dist = _distance[i];
    final cal = _calories[i]; final mins = _actMin[i];
    final paceStr = _pace(mins, dist);
    final speed = mins > 0 ? (dist / (mins / 60.0)).toStringAsFixed(1) : '0.0';
    final goalDone = steps >= 10000;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Period Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 12),
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: _purple, borderRadius: BorderRadius.circular(10)),
            child: Column(children: [
              Text(_selectedPeriod == 'Year' ? 'MTH' : _selectedPeriod == 'Month' ? 'WK' : 'DAY', style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold)),
              Text('${_dates[i]}', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
            ]),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_dayNames[i], style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87), overflow: TextOverflow.ellipsis),
            Text(_selectedPeriod == 'Week' || _selectedPeriod == 'Day' ? 'Selected ${_selectedPeriod}' : 'Summary', style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54)),
          ])),
          GestureDetector(
            onTap: () => setState(() { if (_selectedIndex > 0) _selectedIndex--; }),
            child: Icon(Icons.chevron_left_rounded, color: isDark ? Colors.white54 : Colors.black54, size: 20),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => setState(() { if (_selectedIndex < _steps.length - 1) _selectedIndex++; }),
            child: Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white54 : Colors.black54, size: 20),
          ),
        ]),
        const SizedBox(height: 14),
        _dRow(isDark, Icons.directions_walk_rounded, _purple, 'Steps', NumberFormat('#,###').format(steps), ''),
        _dRow(isDark, Icons.location_on_rounded, _green, 'Distance', dist.toStringAsFixed(1), 'km'),
        _dRow(isDark, Icons.local_fire_department_rounded, _orange, 'Calories', '$cal', 'kcal'),
        _dRow(isDark, Icons.timer_outlined, _blue, 'Active Time', _fmtDur(mins), ''),
        _dRow(isDark, Icons.speed_rounded, _purple, 'Avg. Pace', paceStr, 'min/km'),
        _dRow(isDark, Icons.speed_outlined, _purple, 'Avg. Speed', speed, 'km/h'),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Icon(Icons.check_circle_outline_rounded, color: _green, size: 15),
            const SizedBox(width: 6),
            Text('Goal', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13)),
          ]),
          Row(children: [
            Icon(goalDone ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                color: goalDone ? _green : Colors.orange, size: 14),
            const SizedBox(width: 4),
            Text(goalDone ? 'Completed' : 'Pending',
                style: TextStyle(color: goalDone ? _green : Colors.orange, fontWeight: FontWeight.bold, fontSize: 13)),
          ]),
        ]),
      ]),
    );
  }

  Widget _dRow(bool isDark, IconData icon, Color color, String label, String value, String unit) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 12)),
        ]),
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : Colors.black87)),
          if (unit.isNotEmpty) ...[const SizedBox(width: 3), Text(unit, style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.black54))],
        ]),
      ]),
    );
  }

  // ── WEEKLY TRENDS ───────────────────────────────────────────
  Widget _buildWeeklyTrends(bool isDark) {
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? Colors.white12 : Colors.grey.shade200;
    if (_steps.isEmpty) return const SizedBox.shrink();
    final totalDays = _selectedPeriod == 'Day' ? 1 : (_selectedPeriod == 'Month' ? 28 : (_selectedPeriod == 'Year' ? 365 : 7));
    final avgSteps = (_steps.fold(0, (a, b) => a + b) / totalDays).round();
    final avgDist  = _totalDist / totalDays;
    final avgCal   = (_calories.fold(0, (a, b) => a + b) / totalDays).round();
    final avgMins  = _totalActMin / totalDays;
    final paceStr  = _pace(avgMins.round(), avgDist);
    final speedStr = (avgDist / (avgMins / 60.0)).toStringAsFixed(1);

    // Comparison spots
    final curSpots = List.generate(_steps.length, (i) => FlSpot(i.toDouble(), _steps[i].toDouble()));
    final prevSpots = List.generate(_steps.length, (i) => FlSpot(i.toDouble(), (_prevTotal / _steps.length).toDouble()));
    double maxVal = _steps.isEmpty ? 0 : _steps.reduce((a, b) => a > b ? a : b).toDouble();
    if (maxVal == 0) maxVal = 100;
    final maxY = maxVal * 1.3;

    return Column(children: [
      // Averages card
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${_selectedPeriod} Trends', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 12),
          _dRow(isDark, Icons.directions_walk_rounded, _purple, 'Avg. Steps', NumberFormat('#,###').format(avgSteps), ''),
          _dRow(isDark, Icons.location_on_rounded, _green, 'Avg. Distance', avgDist.toStringAsFixed(1), 'km'),
          _dRow(isDark, Icons.local_fire_department_rounded, _orange, 'Avg. Calories', '$avgCal', 'kcal'),
          _dRow(isDark, Icons.speed_rounded, _purple, 'Avg. Pace', paceStr, 'min/km'),
          _dRow(isDark, Icons.speed_outlined, _purple, 'Avg. Speed', speedStr, 'km/h'),
        ]),
      ),
      const SizedBox(height: 12),
      // This week vs last ${_selectedPeriod.toLowerCase()}
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('This $_selectedPeriod vs Last $_selectedPeriod',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('This $_selectedPeriod', style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.black54)),
              Text(NumberFormat('#,###').format(_totalSteps), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _purple)),
            ]),
            Column(children: [
              Icon(_pctChange >= 0 ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
                  color: _pctChange >= 0 ? _green : Colors.red, size: 22),
              Text('${_pctChange.abs().toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _pctChange >= 0 ? _green : Colors.red)),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('Last $_selectedPeriod', style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.black54)),
              Text(NumberFormat('#,###').format(_prevTotal),
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black54)),
            ]),
          ]),
          const SizedBox(height: 14),
          SizedBox(
            height: 60,
            child: LineChart(LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              minX: 0, maxX: (_steps.length - 1).toDouble(), minY: 0, maxY: maxY,
              lineBarsData: [
                LineChartBarData(
                  spots: prevSpots, isCurved: true,
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  barWidth: 2, isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                ),
                LineChartBarData(
                  spots: curSpots, isCurved: true,
                  color: _purple, barWidth: 2, isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (_, __, ___, ____) =>
                        FlDotCirclePainter(radius: 3, color: Colors.white, strokeWidth: 1.5, strokeColor: _purple),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [_purple.withOpacity(0.25), _purple.withOpacity(0.0)],
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            )),
          ),
        ]),
      ),
    ]);
  }

  // ── BEST PERFORMANCE ────────────────────────────────────────
  Widget _buildBestPerformance(bool isDark) {
    final bg = isDark ? const Color(0xFF78350F).withOpacity(0.2) : const Color(0xFFFFFBEB);
    final border = isDark ? Colors.white12 : const Color(0xFFFEF3C7);

    if (_steps.isEmpty) return const SizedBox.shrink();
    DailyStat? bestSteps, bestDist, bestCal;
    for (var stat in _allStatsMap.values) {
      if (bestSteps == null || stat.steps > bestSteps.steps) bestSteps = stat;
      if (bestDist == null || stat.distanceKm > bestDist.distanceKm) bestDist = stat;
      if (bestCal == null || stat.calories > bestCal.calories) bestCal = stat;
    }

    final bdName = bestSteps != null && bestSteps.steps > 0 ? DateFormat('EEEE').format(bestSteps.date) : '-';
    final bdVal = bestSteps != null && bestSteps.steps > 0 ? '${NumberFormat('#,###').format(bestSteps.steps)} steps' : '-';
    final ldName = bestDist != null && bestDist.distanceKm > 0 ? '${bestDist.distanceKm.toStringAsFixed(1)} km' : '-';
    final ldSub = bestDist != null && bestDist.distanceKm > 0 ? DateFormat('EEEE').format(bestDist.date) : '-';
    final mcName = bestCal != null && bestCal.calories > 0 ? '${bestCal.calories} kcal' : '-';
    final mcSub = bestCal != null && bestCal.calories > 0 ? DateFormat('EEEE').format(bestCal.date) : '-';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.emoji_events_rounded, color: Color(0xFFF59E0B), size: 22),
          ),
          const SizedBox(width: 12),
          Text('Best Performance', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        ]),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 600) {
              return Column(
                children: [
                  Row(children: [
                    Expanded(child: _perfItem('Best Day', bdName, bdVal, isDark, _purple)),
                    _perfDiv(isDark),
                    Expanded(child: _perfItem('Longest Walk', ldName, ldSub, isDark, isDark ? Colors.white70 : Colors.black54)),
                  ]),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: _perfItem('Most Calories', mcName, mcSub, isDark, isDark ? Colors.white70 : Colors.black54)),
                    _perfDiv(isDark),
                    Expanded(child: _perfItem('Fastest Pace', '-', '-', isDark, isDark ? Colors.white70 : Colors.black54)),
                  ]),
                ],
              );
            }
            return Row(children: [
              Expanded(child: _perfItem('Best Day', bdName, bdVal, isDark, _purple)),
              _perfDiv(isDark),
              Expanded(child: _perfItem('Longest Walk', ldName, ldSub, isDark, isDark ? Colors.white70 : Colors.black54)),
              _perfDiv(isDark),
              Expanded(child: _perfItem('Most Calories', mcName, mcSub, isDark, isDark ? Colors.white70 : Colors.black54)),
              _perfDiv(isDark),
              Expanded(child: _perfItem('Fastest Pace', '-', '-', isDark, isDark ? Colors.white70 : Colors.black54)),
            ]);
          },
        ),
      ]),
    );
  }

  Widget _perfDiv(bool isDark) => Container(
    width: 1, height: 40, margin: const EdgeInsets.symmetric(horizontal: 8),
    color: isDark ? Colors.white12 : Colors.grey.shade300,
  );

  Widget _perfItem(String title, String value, String sub, bool isDark, Color subColor) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.black54)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87), overflow: TextOverflow.ellipsis),
      const SizedBox(height: 2),
      Text(sub, style: TextStyle(fontSize: 11, color: subColor), overflow: TextOverflow.ellipsis),
    ]);
  }

  // ── AI COACH ────────────────────────────────────────────────
  Widget _buildAiCoach(bool isDark) {
    final bg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF5F3FF);
    final border = isDark ? Colors.white12 : const Color(0xFFEDE9FE);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AiCoachScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: border),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _purple.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.smart_toy_rounded, color: _purple, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('AI Coach', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 6),
            RichText(text: TextSpan(
              style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87, height: 1.5),
              children: [
                const TextSpan(text: 'Excellent work! You walked '),
                TextSpan(text: '${_pctChange.abs().toStringAsFixed(0)}% ${_pctChange >= 0 ? "more" : "less"}', style: const TextStyle(fontWeight: FontWeight.bold, color: _purple)),
                TextSpan(text: ' than last ${_selectedPeriod.toLowerCase()}.\nKeep up the great work and stay consistent to reach your goals!'),
              ],
            )),
          ])),
          Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white54 : Colors.black38),
        ]),
      ),
    );
  }

  // ── CHALLENGES & REWARDS ────────────────────────────────────
  Widget _buildChallengesRewards(bool isDark) {
    final border = isDark ? Colors.white12 : Colors.grey.shade200;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final double prog = (_totalDist / 50.0).clamp(0.0, 1.0);
    final String progPct = '${(prog * 100).toInt()}%';

    final challengesCard = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.flag_rounded, color: _purple, size: 18),
          const SizedBox(width: 8),
          Text('Weekly Challenges', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          const Text('🏅', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Walk 50 km', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(value: prog, backgroundColor: Colors.grey.shade200, valueColor: const AlwaysStoppedAnimation(_purple), minHeight: 5),
            ),
            const SizedBox(height: 2),
            Text('${_totalDist.toStringAsFixed(1)} / 50 km', style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.black54)),
          ])),
          const SizedBox(width: 8),
          Text(progPct, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        ]),
        const SizedBox(height: 8),
        Text('🎁 Reward: 🪙 300 Coins', style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54)),
      ]),
    );

    final historyAsync = ref.watch(rewardHistoryStreamProvider);
    int periodCoins = 0;
    int periodXp = 0;
    String? latestBadgeTitle;

    if (historyAsync.hasValue && historyAsync.value != null) {
      final now = DateTime.now();
      DateTime startDate;
      if (_selectedPeriod == 'Day') {
        startDate = DateTime(now.year, now.month, now.day);
      } else if (_selectedPeriod == 'Week') {
        startDate = now.subtract(const Duration(days: 7));
      } else if (_selectedPeriod == 'Month') {
        startDate = now.subtract(const Duration(days: 30));
      } else {
        startDate = now.subtract(const Duration(days: 365));
      }

      for (var h in historyAsync.value!) {
        if (h.timestamp.isAfter(startDate)) {
          periodCoins += h.coinsEarned.toInt();
          periodXp += h.xpEarned.toInt();
          if (h.type == RewardHistoryType.badgeEarned && latestBadgeTitle == null) {
            latestBadgeTitle = h.title.replaceAll('Badge Unlocked: ', '').replaceAll('Achievement: ', '');
          }
        }
      }
    }
    
    final badgeLabel = latestBadgeTitle != null 
        ? latestBadgeTitle.split(' ').join('\n') 
        : 'No\nBadge';

    final rewardsCard = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.card_giftcard_rounded, color: _orange, size: 18),
          const SizedBox(width: 8),
          Text('Rewards Earned', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        ]),
        const SizedBox(height: 16),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _rewardBadge('🪙', '+$periodCoins', 'Coins', isDark),
          const SizedBox(width: 12),
          _rewardBadge('⭐', '+$periodXp', 'XP', isDark),
          const SizedBox(width: 12),
          _rewardBadge('🏅', '', badgeLabel, isDark, small: true),
        ]),
      ]),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            children: [
              challengesCard,
              const SizedBox(height: 12),
              rewardsCard,
            ],
          );
        }
        return Row(children: [
          Expanded(child: challengesCard),
          const SizedBox(width: 12),
          Expanded(child: rewardsCard),
        ]);
      },
    );
  }

  Widget _rewardBadge(String emoji, String value, String label, bool isDark, {bool small = false}) {
    return Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 24)),
      if (value.isNotEmpty) ...[
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
      ],
      Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 9, color: isDark ? Colors.white54 : Colors.black54)),
    ]);
  }

  // ── RECENT WALKS ────────────────────────────────────────────
  Widget _buildRecentWalks(bool isDark) {
    final recentWalks = _walks.take(5).toList();
    if (recentWalks.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Recent Walks', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            ref.read(dashboardTabIndexProvider.notifier).state = 1;
          },
          child: const Text('View All', style: TextStyle(color: _purple, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ]),
      const SizedBox(height: 8),
      SizedBox(
        height: 175,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: recentWalks.length,
          itemBuilder: (ctx, i) {
            final w = recentWalks[i];
            final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
            final border = isDark ? Colors.white12 : Colors.grey.shade200;
            return Container(
              width: 170,
              margin: const EdgeInsets.only(right: 14),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: border),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.03), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  height: 65,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    gradient: LinearGradient(
                      colors: [_purple.withOpacity(0.35), _green.withOpacity(0.3)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(child: Icon(Icons.map_rounded, color: isDark ? Colors.white54 : Colors.black26, size: 28)),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(w.title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('${w.distanceKm.toStringAsFixed(1)} km', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                    const SizedBox(height: 4),
                    Text(DateFormat('d MMM, h:mm a').format(w.startTime), style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.black54), overflow: TextOverflow.ellipsis),
                  ]),
                ),
              ]),
            );
          },
        ),
      ),
    ]);
  }
}
