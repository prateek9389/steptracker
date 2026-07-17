import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../widgets/live_map_card.dart';
import '../../providers/walk_provider.dart';
import '../../providers/stats_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../history/route_details_screen.dart';
import '../history/achievements_screen.dart';
import '../history/saved_routes_screen.dart';
import '../../models/walk_session.dart';
import '../../models/daily_stat.dart';

// ─── Sort Options ────────────────────────────────────────────
enum SortOrder { newestFirst, oldestFirst, longestDistance, highestCalories, mostSteps }

class HistoryTab extends ConsumerStatefulWidget {
  const HistoryTab({super.key});

  @override
  ConsumerState<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends ConsumerState<HistoryTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedChip = 'All'; // All, Walks
  SortOrder _sortOrder = SortOrder.newestFirst;
  DateTime _calendarMonth = DateTime.now();
  DateTime? _selectedDate;
  int _listLimit = 5;

  static const _purple = Color(0xFF6324D6);
  static const _green  = Color(0xFF10B981);
  static const _orange = Color(0xFFF97316);
  static const _blue   = Color(0xFF3B82F6);
  static const _gold   = Color(0xFFF59E0B);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Helpers ─────────────────────────────────────────────────
  String _fmtDur(int seconds) {
    final h = seconds ~/ 3600; final m = (seconds % 3600) ~/ 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  String _fmtDate(DateTime dt) => DateFormat('d MMM yyyy • h:mm a').format(dt);

  Color _cardBg(bool isDark) => isDark ? const Color(0xFF1E293B) : Colors.white;
  Color _cardBorder(bool isDark) => isDark ? Colors.white12 : Colors.grey.shade200;

  List<WalkSession> _applyFilters(List<WalkSession> all) {
    final now = DateTime.now();
    var list = all.where((w) {
      // chip / time filter
      switch (_selectedChip) {
        case 'All': break;
        case 'Walks': break;
      }
      // date filter from calendar
      if (_selectedDate != null) {
        if (w.startTime.year != _selectedDate!.year ||
            w.startTime.month != _selectedDate!.month ||
            w.startTime.day != _selectedDate!.day) return false;
      }
      // search
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!w.title.toLowerCase().contains(q) &&
            !DateFormat('d MMM yyyy').format(w.startTime).toLowerCase().contains(q) &&
            !w.distanceKm.toStringAsFixed(1).contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();

    switch (_sortOrder) {
      case SortOrder.newestFirst: list.sort((a, b) => b.startTime.compareTo(a.startTime)); break;
      case SortOrder.oldestFirst: list.sort((a, b) => a.startTime.compareTo(b.startTime)); break;
      case SortOrder.longestDistance: list.sort((a, b) => b.distanceKm.compareTo(a.distanceKm)); break;
      case SortOrder.highestCalories: list.sort((a, b) => b.calories.compareTo(a.calories)); break;
      case SortOrder.mostSteps: list.sort((a, b) => b.steps.compareTo(a.steps)); break;
    }
    return list;
  }

  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final walksAsync = ref.watch(walkHistoryStreamProvider);
    final statsAsync = ref.watch(allDailyStatsStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: walksAsync.when(
          loading: () => _buildLoading(isDark),
          error: (e, _) => _buildError(isDark, e.toString()),
          data: (allWalks) {
            final stats = statsAsync.value ?? [];
            final filtered = _applyFilters(allWalks);
            return CustomScrollView(
              slivers: [
                _buildHeader(isDark),
                SliverToBoxAdapter(child: _buildFilterChips(isDark)),
                SliverToBoxAdapter(child: _buildQuickStats(isDark, allWalks)),
                SliverToBoxAdapter(child: _buildCalendar(isDark, allWalks)),
                SliverToBoxAdapter(child: _buildWalkListAndOverview(context, isDark, filtered, stats)),
                SliverToBoxAdapter(child: _buildAiInsightsCard(isDark, allWalks, stats)),
                SliverToBoxAdapter(child: _buildAchievementsAndRoutes(isDark, allWalks)),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── 1. HEADER ────────────────────────────────────────────────
  Widget _buildHeader(bool isDark) {
    return SliverAppBar(
      floating: true,
      snap: true,
      pinned: false,
      toolbarHeight: 70,
      backgroundColor: isDark ? const Color(0xFF0F172A).withOpacity(0.75) : const Color(0xFFF9FAFB).withOpacity(0.85),
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            color: Colors.transparent,
          ),
        ),
      ),
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: _purple,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.directions_walk_rounded, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('History', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF111827), fontFamily: 'Outfit', letterSpacing: 0.2)),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Flexible(
                child: Text(
                  'Your walking journey',
                  style: TextStyle(fontSize: 14, color: isDark ? Colors.white54 : Colors.black54),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.directions_walk_rounded, color: _purple, size: 14),
            ],
          ),
        ])),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: _cardBorder(isDark)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(Icons.search_rounded, color: isDark ? Colors.white : Colors.black87, size: 22),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => _showSortSheet(context, isDark),
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: _cardBorder(isDark)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(Icons.filter_alt_outlined, color: isDark ? Colors.white : Colors.black87, size: 22),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _purple,
                    shape: BoxShape.circle,
                    border: Border.all(color: _cardBg(isDark), width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ]),
      ),
    );
  }

  // ── 2. SEARCH BAR ────────────────────────────────────────────
  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: _cardBg(isDark), borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _cardBorder(isDark)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          const SizedBox(width: 14),
          Icon(Icons.search_rounded, color: isDark ? Colors.white38 : Colors.grey.shade400, size: 20),
          const SizedBox(width: 10),
          Expanded(child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() { _searchQuery = v; _listLimit = 5; }),
            style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: 'Search walks, dates, distance...',
              hintStyle: TextStyle(fontSize: 14, color: isDark ? Colors.white38 : Colors.grey.shade400),
              border: InputBorder.none,
            ),
          )),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () { _searchController.clear(); setState(() { _searchQuery = ''; _listLimit = 5; }); },
              child: Icon(Icons.close_rounded, color: isDark ? Colors.white38 : Colors.grey.shade400, size: 18),
            ),
          const SizedBox(width: 4),
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: _purple.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.calendar_month_rounded, color: _purple, size: 18),
          ),
        ]),
      ),
    );
  }

  // ── 3. FILTER CHIPS ──────────────────────────────────────────
  Widget _buildFilterChips(bool isDark) {
    const chips = ['All', 'Walks'];
    return Container(
      height: 48,
      margin: const EdgeInsets.only(top: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: chips.length,
        itemBuilder: (ctx, i) {
          final selected = _selectedChip == chips[i];
          return GestureDetector(
            onTap: () => setState(() { _selectedChip = chips[i]; _selectedDate = null; _listLimit = 5; }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                gradient: selected ? const LinearGradient(colors: [_purple, Color(0xFF4F46E5)]) : null,
                color: selected ? null : _cardBg(isDark),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: selected ? Colors.transparent : _cardBorder(isDark)),
                boxShadow: selected ? [BoxShadow(color: _purple.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
              ),
              child: Text(chips[i], style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: selected ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
              )),
            ),
          );
        },
      ),
    );
  }

  // ── 4. QUICK STATS ───────────────────────────────────────────
  Widget _buildQuickStats(bool isDark, List<WalkSession> walks) {
    final totalWalks = walks.length;
    final totalDist = walks.fold(0.0, (s, w) => s + w.distanceKm);
    final totalCal = walks.fold(0, (s, w) => s + w.calories);
    final totalSec = walks.fold(0, (s, w) => s + w.durationSeconds);
    DateTime longestWalkDate = DateTime.now();
    double longestWalk = 0.0;
    if (walks.isNotEmpty) {
      final w = walks.reduce((a, b) => a.distanceKm > b.distanceKm ? a : b);
      longestWalk = w.distanceKm;
      longestWalkDate = w.startTime;
    }
    
    final now = DateTime.now();
    final thisYearWalksList = walks.where((w) => w.startTime.year == now.year);
    final lastYearWalksList = walks.where((w) => w.startTime.year == now.year - 1);

    final thisYearDist = thisYearWalksList.fold(0.0, (s, w) => s + w.distanceKm);
    final lastYearDist = lastYearWalksList.fold(0.0, (s, w) => s + w.distanceKm);
    final distPercent = lastYearDist > 0 ? ((thisYearDist - lastYearDist) / lastYearDist * 100) : 100.0;
    final distSub = lastYearDist == 0 ? (thisYearDist > 0 ? '+100% vs last year' : 'No data') : '${distPercent >= 0 ? '+' : ''}${distPercent.toStringAsFixed(1)}% vs last year';

    final thisYearCal = thisYearWalksList.fold(0, (s, w) => s + w.calories);
    final lastYearCal = lastYearWalksList.fold(0, (s, w) => s + w.calories);
    final calPercent = lastYearCal > 0 ? ((thisYearCal - lastYearCal) / lastYearCal * 100) : 100.0;
    final calSub = lastYearCal == 0 ? (thisYearCal > 0 ? '+100% vs last year' : 'No data') : '${calPercent >= 0 ? '+' : ''}${calPercent.toStringAsFixed(1)}% vs last year';

    final thisYearSec = thisYearWalksList.fold(0, (s, w) => s + w.durationSeconds);
    final lastYearSec = lastYearWalksList.fold(0, (s, w) => s + w.durationSeconds);
    final secPercent = lastYearSec > 0 ? ((thisYearSec - lastYearSec) / lastYearSec * 100) : 100.0;
    final secSub = lastYearSec == 0 ? (thisYearSec > 0 ? '+100% vs last year' : 'No data') : '${secPercent >= 0 ? '+' : ''}${secPercent.toStringAsFixed(1)}% vs last year';

    final items = [
      {'icon': Icons.directions_walk_rounded, 'color': _purple, 'label': 'Total Walks',
        'value': '$totalWalks', 'unit': '', 'sub': 'This Year ${thisYearWalksList.length}'},
      {'icon': Icons.location_on_rounded, 'color': _green, 'label': 'Total Distance',
        'value': totalDist.toStringAsFixed(1), 'unit': 'km', 'sub': distSub},
      {'icon': Icons.local_fire_department_rounded, 'color': _orange, 'label': 'Total Calories',
        'value': NumberFormat('#,###').format(totalCal), 'unit': 'kcal', 'sub': calSub},
      {'icon': Icons.timer_outlined, 'color': _blue, 'label': 'Total Time',
        'value': _fmtDur(totalSec), 'unit': '', 'sub': secSub},
      {'icon': Icons.emoji_events_rounded, 'color': _gold, 'label': 'Longest Walk',
        'value': longestWalk.toStringAsFixed(1), 'unit': 'km', 'sub': DateFormat('d MMM yyyy').format(longestWalkDate)},
    ];

    return Container(
      height: 155,
      margin: const EdgeInsets.only(top: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length,
        itemBuilder: (ctx, i) {
          final item = items[i];
          final color = item['color'] as Color;
          return Container(
            width: 140,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _cardBg(isDark), borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _cardBorder(isDark)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.04), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
                child: Icon(item['icon'] as IconData, color: color, size: 16),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item['label'] as String, style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.black54)),
                const SizedBox(height: 2),
                Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                  Flexible(child: Text(item['value'] as String,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                    overflow: TextOverflow.ellipsis)),
                  if ((item['unit'] as String).isNotEmpty) ...[
                    const SizedBox(width: 2),
                    Text(item['unit'] as String, style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.black54)),
                  ],
                ]),
                const SizedBox(height: 2),
                Text(item['sub'] as String, style: const TextStyle(fontSize: 9, color: _green), overflow: TextOverflow.ellipsis),
              ]),
            ]),
          );
        },
      ),
    );
  }

  // ── 5. CALENDAR ──────────────────────────────────────────────
  Widget _buildCalendar(bool isDark, List<WalkSession> walks) {
    final bg = _cardBg(isDark);
    final border = _cardBorder(isDark);
    final daysInMonth = DateTime(_calendarMonth.year, _calendarMonth.month + 1, 0).day;
    final firstWeekday = DateTime(_calendarMonth.year, _calendarMonth.month, 1).weekday; // 1=Mon

    // Set of days that have walks
    final walkDays = <int>{};
    for (final w in walks) {
      if (w.startTime.year == _calendarMonth.year && w.startTime.month == _calendarMonth.month) {
        walkDays.add(w.startTime.day);
      }
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          GestureDetector(
            onTap: () => setState(() => _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month - 1)),
            child: Icon(Icons.chevron_left_rounded, color: isDark ? Colors.white70 : Colors.black54),
          ),
          const SizedBox(width: 8),
          Text(DateFormat('MMMM yyyy').format(_calendarMonth),
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          Icon(Icons.keyboard_arrow_right_rounded, color: isDark ? Colors.white54 : Colors.black38, size: 16),
          const Spacer(),
          Row(children: [
            Container(width: 8, height: 8, decoration: const BoxDecoration(color: _purple, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text('Walk', style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.black54)),
            const SizedBox(width: 12),
            Container(width: 8, height: 8, decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.grey.shade300, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text('No Activity', style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.black54)),
          ]),
        ]),
        const SizedBox(height: 12),
        // Day headers M T W T F S S
        Row(children: ['M','T','W','T','F','S','S'].map((d) => Expanded(
          child: Center(child: Text(d, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white38 : Colors.black38))),
        )).toList()),
        const SizedBox(height: 8),
        // Calendar grid
        ...() {
          final rows = <Widget>[];
          int day = 1;
          int startOffset = firstWeekday - 1;
          while (day <= daysInMonth) {
            final cells = <Widget>[];
            for (int col = 0; col < 7; col++) {
              if ((rows.isEmpty && col < startOffset) || day > daysInMonth) {
                cells.add(const Expanded(child: SizedBox()));
              } else {
                final d = day;
                final hasWalk = walkDays.contains(d);
                final isSelected = _selectedDate != null &&
                    _selectedDate!.year == _calendarMonth.year &&
                    _selectedDate!.month == _calendarMonth.month &&
                    _selectedDate!.day == d;
                final isToday = DateTime.now().year == _calendarMonth.year &&
                    DateTime.now().month == _calendarMonth.month &&
                    DateTime.now().day == d;
                cells.add(Expanded(child: GestureDetector(
                  onTap: () => setState(() {
                    if (_selectedDate?.day == d && _selectedDate?.month == _calendarMonth.month) {
                      _selectedDate = null;
                    } else {
                      _selectedDate = DateTime(_calendarMonth.year, _calendarMonth.month, d);
                    }
                  }),
                  child: Column(children: [
                    Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? _purple : Colors.transparent,
                        border: isToday && !isSelected ? Border.all(color: _purple, width: 1.5) : null,
                      ),
                      child: Center(child: Text('$d', style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                      ))),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      width: 5, height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: hasWalk ? _purple : (isDark ? Colors.white12 : Colors.grey.shade200),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ]),
                )));
                day++;
              }
            }
            rows.add(Row(children: cells));
          }
          return rows;
        }(),
        if (_selectedDate != null) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _selectedDate = null),
            child: Row(children: [
              const Icon(Icons.close_rounded, size: 14, color: _purple),
              const SizedBox(width: 4),
              Text('Clear filter: ${DateFormat('d MMM').format(_selectedDate!)}',
                  style: const TextStyle(fontSize: 12, color: _purple, fontWeight: FontWeight.w600)),
            ]),
          ),
        ],
      ]),
    );
  }

  // ── 6. WALK LIST + ACTIVITY OVERVIEW ─────────────────────────
  Widget _buildWalkListAndOverview(BuildContext context, bool isDark, List<WalkSession> filtered, List<DailyStat> stats) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWalkList(context, isDark, filtered),
                const SizedBox(height: 20),
                _buildActivityOverview(isDark, stats),
              ],
            );
          }
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(flex: 5, child: _buildWalkList(context, isDark, filtered)),
            const SizedBox(width: 12),
            Expanded(flex: 4, child: _buildActivityOverview(isDark, stats)),
          ]);
        },
      ),
    );
  }

  Widget _buildWalkList(BuildContext context, bool isDark, List<WalkSession> walks) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Walk History', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87)),
        GestureDetector(
          onTap: () => _showSortSheet(context, isDark),
          child: Row(children: [
            Text(_sortLabel(), style: const TextStyle(fontSize: 12, color: _purple, fontWeight: FontWeight.w600)),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: _purple),
          ]),
        ),
      ]),
      const SizedBox(height: 12),
      if (walks.isEmpty)
        _buildEmptyWalks(isDark)
      else
        ...walks.take(_listLimit).map((w) => _buildWalkCard(context, isDark, w)).toList(),
      if (walks.length > _listLimit)
        GestureDetector(
          onTap: () => setState(() => _listLimit += 5),
          child: Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: _cardBg(isDark), borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _cardBorder(isDark)),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('Load More (${walks.length - _listLimit} more)',
                  style: const TextStyle(color: _purple, fontWeight: FontWeight.w600, fontSize: 13)),
              const Icon(Icons.keyboard_arrow_down_rounded, color: _purple, size: 18),
            ]),
          ),
        ),
    ]);
  }

  Widget _buildWalkCard(BuildContext context, bool isDark, WalkSession walk) {
    final bg = _cardBg(isDark); final border = _cardBorder(isDark);
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RouteDetailsScreen(activity: walk))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(18), border: Border.all(color: border),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Map preview
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: SizedBox(
              height: 80,
              child: walk.route.isNotEmpty
                ? LiveMapCard(points: walk.route, height: 80, interactive: false)
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_purple.withOpacity(0.2), _green.withOpacity(0.2)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(child: Icon(Icons.map_rounded, color: isDark ? Colors.white30 : Colors.black26, size: 30)),
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(walk.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87))),
                const Icon(Icons.star_border_rounded, color: _gold, size: 18),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showWalkOptions(context, isDark, walk),
                  child: Icon(Icons.more_vert_rounded, color: isDark ? Colors.white38 : Colors.grey.shade400, size: 18),
                ),
              ]),
              const SizedBox(height: 4),
              Text(_fmtDate(walk.startTime), style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54)),
              const SizedBox(height: 10),
              Row(children: [
                _miniStat(Icons.location_on_rounded, _green, '${walk.distanceKm.toStringAsFixed(1)} km'),
                const SizedBox(width: 12),
                _miniStat(Icons.directions_walk_rounded, _purple, '${NumberFormat('#,###').format(walk.steps)}'),
                const SizedBox(width: 12),
                _miniStat(Icons.local_fire_department_rounded, _orange, '${walk.calories} kcal'),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                _miniStat(Icons.timer_outlined, _blue, _fmtDur(walk.durationSeconds)),
                const SizedBox(width: 12),
                _miniStat(Icons.speed_rounded, _purple, '${walk.paceString} /km'),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _miniStat(IconData icon, Color color, String label) => Row(children: [
    Icon(icon, size: 12, color: color),
    const SizedBox(width: 3),
    Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey)),
  ]);

  Widget _buildEmptyWalks(bool isDark) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: _cardBg(isDark), borderRadius: BorderRadius.circular(18), border: Border.all(color: _cardBorder(isDark))),
    child: Column(children: [
      Icon(Icons.directions_walk_rounded, size: 40, color: isDark ? Colors.white24 : Colors.grey.shade300),
      const SizedBox(height: 12),
      Text('No walks found', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white54 : Colors.black54)),
      const SizedBox(height: 4),
      Text(_selectedDate != null ? 'No walks on this date' : 'Start your first walk!',
          style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey.shade400), textAlign: TextAlign.center),
    ]),
  );

  // ── 7. ACTIVITY OVERVIEW ─────────────────────────────────────
  Widget _buildActivityOverview(bool isDark, List<DailyStat> stats) {
    final bg = _cardBg(isDark); final border = _cardBorder(isDark);
    final now = DateTime.now();
    final weekStats = stats.where((s) {
      final diff = now.difference(s.date).inDays;
      return diff >= 0 && diff < 7;
    }).toList()..sort((a, b) => a.date.compareTo(b.date));

    final totalSteps = weekStats.fold(0, (s, e) => s + e.steps);
    final totalDist = weekStats.fold(0.0, (s, e) => s + e.distanceKm);
    final totalCal = weekStats.fold(0, (s, e) => s + e.calories);
    final totalMins = weekStats.fold(0, (s, e) => s + e.activeMinutes);

    return Column(children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: border),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Activity Overview', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: _purple.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: const Text('This Week', style: TextStyle(fontSize: 10, color: _purple, fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 12),
          _overviewRow(isDark, Icons.directions_walk_rounded, _purple, 'Steps',
              NumberFormat('#,###').format(totalSteps), _buildSparkline(weekStats.map((s) => s.steps.toDouble()).toList(), _purple)),
          const SizedBox(height: 10),
          _overviewRow(isDark, Icons.location_on_rounded, _green, 'Distance',
              '${totalDist.toStringAsFixed(1)} km', _buildSparkline(weekStats.map((s) => s.distanceKm).toList(), _green)),
          const SizedBox(height: 10),
          _overviewRow(isDark, Icons.local_fire_department_rounded, _orange, 'Calories',
              '${NumberFormat('#,###').format(totalCal)} kcal', _buildSparkline(weekStats.map((s) => s.calories.toDouble()).toList(), _orange)),
          const SizedBox(height: 10),
          _overviewRow(isDark, Icons.timer_outlined, _blue, 'Active Time',
              _fmtDur(totalMins * 60), _buildSparkline(weekStats.map((s) => s.activeMinutes.toDouble()).toList(), _blue)),
        ]),
      ),
      const SizedBox(height: 12),
      // AI Insights mini card
      _buildAiMiniCard(isDark, stats),
    ]);
  }

  Widget _overviewRow(bool isDark, IconData icon, Color color, String label, String value, Widget sparkline) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54)),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
      ]),
      const SizedBox(height: 4),
      SizedBox(height: 32, child: sparkline),
    ]);
  }

  Widget _buildSparkline(List<double> data, Color color) {
    if (data.isEmpty) return const SizedBox.shrink();
    final spots = data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();
    final maxY = data.isEmpty ? 1.0 : (data.reduce((a, b) => a > b ? a : b) * 1.2).clamp(1.0, double.infinity);
    return LineChart(LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      minX: 0, maxX: (data.length - 1).toDouble().clamp(1, double.infinity),
      minY: 0, maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: spots, isCurved: true, color: color, barWidth: 1.5,
          isStrokeCapRound: true, dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: true, gradient: LinearGradient(
            colors: [color.withOpacity(0.2), color.withOpacity(0.0)],
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
          )),
        ),
      ],
    ));
  }

  Widget _buildAiMiniCard(bool isDark, List<DailyStat> stats) {
    final now = DateTime.now();
    final thisWeekStats = stats.where((s) {
      final diff = now.difference(s.date).inDays;
      return diff >= 0 && diff < 7;
    });
    final lastWeekStats = stats.where((s) {
      final diff = now.difference(s.date).inDays;
      return diff >= 7 && diff < 14;
    });
    
    final thisWeekMins = thisWeekStats.fold(0, (s, e) => s + e.activeMinutes);
    final lastWeekMins = lastWeekStats.fold(0, (s, e) => s + e.activeMinutes);
    
    int pct = 0;
    if (lastWeekMins > 0) {
      pct = (((thisWeekMins - lastWeekMins) / lastWeekMins) * 100).round();
    } else if (thisWeekMins > 0) {
      pct = 100;
    }

    final String moreOrLess = pct >= 0 ? 'more' : 'less';
    final int displayPct = pct.abs();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_purple.withOpacity(0.15), const Color(0xFF4F46E5).withOpacity(0.1)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _purple.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: _purple.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.smart_toy_rounded, color: _purple, size: 18),
          ),
          const SizedBox(width: 8),
          Text('AI Coach', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        ]),
        const SizedBox(height: 10),
        RichText(text: TextSpan(
          style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87, height: 1.5),
          children: [
            const TextSpan(text: 'Great job! You\'re '),
            TextSpan(text: '$displayPct% $moreOrLess', style: const TextStyle(fontWeight: FontWeight.bold, color: _purple)),
            const TextSpan(text: ' active than last week.\nYour consistency is improving! Keep going 💪'),
          ],
        )),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {},
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_purple, Color(0xFF4F46E5)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('View Insights', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: Colors.white, size: 16),
            ]),
          ),
        ),
      ]),
    );
  }

  // ── 8. AI INSIGHTS CARD (full width) ─────────────────────────
  Widget _buildAiInsightsCard(bool isDark, List<WalkSession> walks, List<DailyStat> stats) {
    final now = DateTime.now();
    final thisWeek = walks.where((w) => now.difference(w.startTime).inDays < 7).length;
    final lastWeek = walks.where((w) {
      final d = now.difference(w.startTime).inDays;
      return d >= 7 && d < 14;
    }).length;
    int pct = 0;
    if (lastWeek > 0) {
      pct = (((thisWeek - lastWeek) / lastWeek) * 100).round();
    } else if (thisWeek > 0) {
      pct = 100;
    }

    // current streak
    int streak = 0;
    final uniqueDays = walks.map((w) => '${w.startTime.year}-${w.startTime.month}-${w.startTime.day}').toSet();
    for (int i = 0; i < 30; i++) {
      final d = now.subtract(Duration(days: i));
      if (uniqueDays.contains('${d.year}-${d.month}-${d.day}')) { streak++; } else { break; }
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_purple.withOpacity(isDark ? 0.3 : 0.1), const Color(0xFF4F46E5).withOpacity(isDark ? 0.2 : 0.05)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _purple.withOpacity(0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _purple.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.smart_toy_rounded, color: _purple, size: 24),
          ),
          const SizedBox(width: 14),
          Text('AI Insights', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87)),
        ]),
        const SizedBox(height: 16),
        Wrap(spacing: 10, runSpacing: 10, children: [
          _insightChip(isDark, '🏃', 'Performance', pct >= 0 ? '+$pct% this week' : '$pct% this week', pct >= 0 ? _green : Colors.red),
          _insightChip(isDark, '🔥', 'Streak', '$streak day${streak != 1 ? 's' : ''}', _orange),
          _insightChip(isDark, '💡', 'Tip', 'Add evening walks', _blue),
          _insightChip(isDark, '⭐', 'Goal', walks.isNotEmpty && walks.first.distanceKm >= 5 ? 'On track' : 'Walk 5km today', _gold),
        ]),
      ]),
    );
  }

  Widget _insightChip(bool isDark, String emoji, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 6),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 9, color: isDark ? Colors.white54 : Colors.black54)),
          Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        ]),
      ]),
    );
  }

  // ── 9. ACHIEVEMENTS + SAVED ROUTES ───────────────────────────
  Widget _buildAchievementsAndRoutes(bool isDark, List<WalkSession> walks) {
    final bg = _cardBg(isDark); final border = _cardBorder(isDark);

    // Compute real milestones
    final totalDist = walks.fold(0.0, (s, w) => s + w.distanceKm);
    final totalSteps = walks.fold(0, (s, w) => s + w.steps);
    final now = DateTime.now();
    final uniqueDays = walks.map((w) => '${w.startTime.year}-${w.startTime.month}-${w.startTime.day}').toSet();
    int streak = 0;
    for (int i = 0; i < 30; i++) {
      final d = now.subtract(Duration(days: i));
      if (uniqueDays.contains('${d.year}-${d.month}-${d.day}')) { streak++; } else { break; }
    }

    final achievements = <Map<String, dynamic>>[
      if (totalSteps >= 100000) {'emoji': '👟', 'title': '100K Steps', 'sub': 'Earned', 'color': _purple},
      if (streak >= 7) {'emoji': '🔥', 'title': '7 Day Streak', 'sub': 'Earned', 'color': _orange},
      if (totalDist >= 25) {'emoji': '🏅', 'title': '25 km Walk', 'sub': 'Earned', 'color': _gold},
      if (totalDist >= 50) {'emoji': '🥇', 'title': '50 km Total', 'sub': 'Earned', 'color': _green},
      // Upcoming
      if (totalSteps < 100000) {'emoji': '👟', 'title': '100K Steps', 'sub': '${NumberFormat('#,###').format(100000 - totalSteps)} to go', 'color': Colors.grey},
      if (streak < 7) {'emoji': '🔥', 'title': '7 Day Streak', 'sub': '${7 - streak} more days', 'color': Colors.grey},
    ];

    // Saved routes = unique walks with route data
    final savedRoutes = walks.where((w) => w.route.isNotEmpty).take(4).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Achievements
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Recent Achievements', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87)),
          TextButton(onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AchievementsScreen(achievements: achievements)),
            );
          }, child: const Text('View All', style: TextStyle(color: _purple, fontWeight: FontWeight.bold, fontSize: 12))),
        ]),
      ),
      SizedBox(
        height: 95,
        child: achievements.isEmpty
          ? Center(child: Text('Complete walks to earn achievements!',
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey.shade400)))
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: achievements.length,
              itemBuilder: (ctx, i) {
                final a = achievements[i]; final color = a['color'] as Color;
                final earned = a['sub'] == 'Earned';
                return Container(
                  width: 80, margin: const EdgeInsets.only(right: 12),
                  child: Column(children: [
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: earned ? LinearGradient(colors: [color, color.withOpacity(0.6)]) : null,
                        color: earned ? null : (isDark ? Colors.white12 : Colors.grey.shade200),
                        border: Border.all(color: earned ? color : Colors.transparent, width: 2),
                      ),
                      child: Center(child: Text(a['emoji'] as String, style: const TextStyle(fontSize: 24))),
                    ),
                    const SizedBox(height: 4),
                    Text(a['title'] as String, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.black87), textAlign: TextAlign.center, maxLines: 2),
                    Text(a['sub'] as String, style: TextStyle(fontSize: 8,
                        color: earned ? _green : (isDark ? Colors.white38 : Colors.grey)), textAlign: TextAlign.center),
                  ]),
                );
              },
            ),
      ),

      // Saved Routes
      if (savedRoutes.isNotEmpty) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Saved Routes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87)),
            TextButton(onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SavedRoutesScreen(routes: savedRoutes)),
              );
            }, child: const Text('View All', style: TextStyle(color: _purple, fontWeight: FontWeight.bold, fontSize: 12))),
          ]),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: savedRoutes.length,
            itemBuilder: (ctx, i) {
              final w = savedRoutes[i];
              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RouteDetailsScreen(activity: w))),
                child: Container(
                  width: 110, margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: border),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.04), blurRadius: 8, offset: const Offset(0, 4))],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                      child: SizedBox(height: 65, child: LiveMapCard(points: w.route, height: 65, interactive: false)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(w.title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87), overflow: TextOverflow.ellipsis),
                        Text('${w.distanceKm.toStringAsFixed(1)} km', style: const TextStyle(fontSize: 10, color: _green)),
                      ]),
                    ),
                  ]),
                ),
              );
            },
          ),
        ),
      ],
    ]);
  }

  // ── BOTTOM SHEETS ────────────────────────────────────────────
  void _showSortSheet(BuildContext context, bool isDark) {
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    showModalBottomSheet(
      context: context,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Sort by', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 16),
          ...[
            (SortOrder.newestFirst, 'Newest First', Icons.schedule_rounded),
            (SortOrder.oldestFirst, 'Oldest First', Icons.history_rounded),
            (SortOrder.longestDistance, 'Longest Distance', Icons.location_on_rounded),
            (SortOrder.highestCalories, 'Highest Calories', Icons.local_fire_department_rounded),
            (SortOrder.mostSteps, 'Most Steps', Icons.directions_walk_rounded),
          ].map((opt) {
            final selected = _sortOrder == opt.$1;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(opt.$3, color: selected ? _purple : (isDark ? Colors.white54 : Colors.black54), size: 20),
              title: Text(opt.$2, style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
              trailing: selected ? const Icon(Icons.check_rounded, color: _purple, size: 18) : null,
              onTap: () { setState(() => _sortOrder = opt.$1); Navigator.pop(context); },
            );
          }),
        ]),
      ),
    );
  }

  void _showWalkOptions(BuildContext context, bool isDark, WalkSession walk) {
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    showModalBottomSheet(
      context: context,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text(walk.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          Text(_fmtDate(walk.startTime), style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54)),
          const SizedBox(height: 16),
          ...[
            (Icons.share_rounded, 'Share', _purple, () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Share feature coming soon!')));
            }),
            (Icons.picture_as_pdf_rounded, 'Export PDF', _blue, () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF Export coming soon!')));
            }),
            (Icons.download_rounded, 'Export GPX', _green, () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('GPX Export coming soon!')));
            }),
            (Icons.delete_outline_rounded, 'Delete Walk', Colors.red, () async {
              try {
                await ref.read(walkRepositoryProvider).deleteWalkSession(walk.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Walk deleted')));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete walk: $e')));
                }
              }
            }),
          ].map((opt) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: (opt.$3 as Color).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(opt.$1 as IconData, color: opt.$3 as Color, size: 18),
            ),
            title: Text(opt.$2 as String, style: TextStyle(fontSize: 14,
                color: opt.$3 == Colors.red ? Colors.red : (isDark ? Colors.white : Colors.black87))),
            onTap: () { Navigator.pop(context); (opt.$4 as VoidCallback)(); },
          )),
        ]),
      ),
    );
  }

  String _sortLabel() {
    switch (_sortOrder) {
      case SortOrder.newestFirst: return 'Newest First';
      case SortOrder.oldestFirst: return 'Oldest First';
      case SortOrder.longestDistance: return 'Longest';
      case SortOrder.highestCalories: return 'Highest Calories';
      case SortOrder.mostSteps: return 'Most Steps';
    }
  }

  // ── LOADING / ERROR ──────────────────────────────────────────
  Widget _buildLoading(bool isDark) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      SizedBox(width: 48, height: 48,
          child: CircularProgressIndicator(color: _purple, strokeWidth: 3)),
      const SizedBox(height: 16),
      Text('Loading your history...', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 14)),
    ]));
  }

  Widget _buildError(bool isDark, String error) {
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
        const SizedBox(height: 16),
        Text('Something went wrong', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 8),
        Text(error, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54), textAlign: TextAlign.center),
      ]),
    ));
  }
}
