import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stride_ai/screens/analytics/weekly_analytics_screen.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/circular_progress_ring.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/live_map_card.dart';
import '../../providers/step_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/walk_provider.dart';
import '../../providers/stats_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/walk_session.dart';
import '../ai_coach/ai_coach_screen.dart';
import 'today_workouts_screen.dart';
import '../../widgets/premium_steps_card.dart';
import '../history/route_details_screen.dart';
import 'activity_details/activity_details_screen.dart';

final showTotalStepsProvider = StateProvider<bool>((ref) => false);

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  IconData _getAvatarIcon(String avatarPath) {
    final List<IconData> avatarIcons = [
      Icons.face_unlock_rounded,
      Icons.face_retouching_natural_rounded,
      Icons.person_pin_rounded,
      Icons.child_care_rounded,
    ];
    final idx = int.tryParse(avatarPath) ?? 0;
    if (idx >= 0 && idx < avatarIcons.length) {
      return avatarIcons[idx];
    }
    return Icons.person_rounded;
  }

  void _openQuickAction(BuildContext context, Widget screen) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => screen,
    );
  }

  void _showCaloriesHistory(
    BuildContext context,
    List<dynamic> history,
    bool isDark,
  ) {
    final now = DateTime.now();
    // Group walks by date, excluding today
    final Map<String, List<dynamic>> byDay = {};
    for (final act in history) {
      final date = act.date;
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final isToday =
          date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
      if (!isToday) {
        byDay.putIfAbsent(dateStr, () => []).add(act);
      }
    }
    final sortedDays = byDay.keys.toList()..sort((a, b) => b.compareTo(a));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.35,
          maxChildSize: 0.92,
          builder: (_, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                border: Border.all(
                  color: isDark
                      ? const Color(0x1AFFFFFF)
                      : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.local_fire_department_rounded,
                            color: Color(0xFFEF4444),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Calories Burned History',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Outfit',
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Calories burned by walking activities',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.textMutedDark
                                    : AppColors.textMutedLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Content
                  Expanded(
                    child: sortedDays.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.history_rounded,
                                  size: 48,
                                  color: isDark
                                      ? Colors.white24
                                      : Colors.black12,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No previous walk history yet',
                                  style: TextStyle(
                                    color: isDark
                                        ? AppColors.textMutedDark
                                        : AppColors.textMutedLight,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            itemCount: sortedDays.length,
                            itemBuilder: (_, dayIdx) {
                              final dayStr = sortedDays[dayIdx];
                              final dayActivities = byDay[dayStr]!;
                              final dayTotal = dayActivities.fold<int>(
                                0,
                                (sum, a) => sum + (a.calories as int),
                              );
                              final parsed = DateTime.tryParse(dayStr);
                              final dayLabel = parsed != null
                                  ? '${_weekdayName(parsed.weekday)}, ${_monthName(parsed.month)} ${parsed.day}'
                                  : dayStr;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Day header
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 12,
                                      bottom: 6,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          dayLabel,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? AppColors.textSecondaryDark
                                                : AppColors.textSecondaryLight,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFFEF4444,
                                            ).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            '$dayTotal kcal total',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFEF4444),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ...dayActivities.map((act) {
                                    final time =
                                        '${act.date.hour.toString().padLeft(2, '0')}:${act.date.minute.toString().padLeft(2, '0')}';
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF161E2E)
                                            : const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: isDark
                                              ? const Color(0x12FFFFFF)
                                              : const Color(0xFFE2E8F0),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFFEF4444,
                                              ).withOpacity(0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.directions_walk_rounded,
                                              color: Color(0xFFEF4444),
                                              size: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  act.title,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: isDark
                                                        ? Colors.white
                                                        : const Color(
                                                            0xFF0F172A,
                                                          ),
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'at $time  •  ${act.distanceKm} km  •  ${act.durationString}',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: isDark
                                                        ? AppColors
                                                              .textMutedDark
                                                        : AppColors
                                                              .textMutedLight,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                '${act.calories}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w900,
                                                  color: Color(0xFFEF4444),
                                                  fontFamily: 'Outfit',
                                                ),
                                              ),
                                              const Text(
                                                'kcal',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  color: Color(0xFFEF4444),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static String _weekdayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[(weekday - 1).clamp(0, 6)];
  }

  static String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[(month - 1).clamp(0, 11)];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walkHistory = ref.watch(walkHistoryStreamProvider).value ?? [];
    final activeWalk = ref.watch(activeWalkStreamProvider).value;
    final isTracking =
        activeWalk?.trackingStatus == TrackingStatus.tracking ||
        activeWalk?.trackingStatus == TrackingStatus.paused;
    // Use the new providers for user profile and stats
    final currentUser = ref.watch(currentUserProvider);
    final currentProfile = ref.watch(profileStreamProvider).value;
    final todayStat = ref.watch(todayStatStreamProvider).value;
    final notificationState = ref.watch(notificationProvider);
    final showTotalSteps = ref.watch(showTotalStepsProvider);

    // Compute today's real walking calories from walk history
    final now = DateTime.now();
    final todayWalks = walkHistory
        .where(
          (act) =>
              act.startTime.year == now.year &&
              act.startTime.month == now.month &&
              act.startTime.day == now.day,
        )
        .toList();
    todayWalks.sort((a, b) => b.startTime.compareTo(a.startTime));

    final todayWalkCalories = todayWalks.fold<int>(0, (sum, act) => sum + act.calories);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final int goal = currentProfile?.dailyGoal ?? 6000;

    final String greeting;
    final int hour = DateTime.now().hour;
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    final firestoreSteps = todayStat?.steps ?? 0;
    final double progress = goal > 0
        ? (firestoreSteps / goal).clamp(0.0, 1.0)
        : 0.0;

    final double todayDistanceKm = walkHistory
        .where(
          (act) =>
              act.startTime.year == now.year &&
              act.startTime.month == now.month &&
              act.startTime.day == now.day,
        )
        .fold<double>(0.0, (sum, act) => sum + act.distanceKm);

    final int todayActiveTimeSeconds = walkHistory
        .where(
          (act) =>
              act.startTime.year == now.year &&
              act.startTime.month == now.month &&
              act.startTime.day == now.day,
        )
        .fold<int>(0, (sum, act) => sum + act.durationSeconds);

    final int todayCalories = todayStat?.calories ?? 0;
    final int activeMinutes = todayActiveTimeSeconds ~/ 60;

    final double paceMinPerKm = todayDistanceKm > 0
        ? (activeMinutes / todayDistanceKm)
        : 0.0;
    final int paceMinutes = paceMinPerKm.toInt();
    final int paceSeconds = ((paceMinPerKm - paceMinutes) * 60).toInt();
    final String paceString = paceMinutes > 0
        ? "$paceMinutes'${paceSeconds.toString().padLeft(2, '0')}\""
        : "0'00\"";

    final String activeMinutesString;
    if (todayActiveTimeSeconds < 60) {
      activeMinutesString = "${todayActiveTimeSeconds}s";
    } else if (activeMinutes >= 60) {
      final hours = activeMinutes ~/ 60;
      final mins = activeMinutes % 60;
      activeMinutesString = "${hours}h ${mins}m";
    } else {
      activeMinutesString = "${activeMinutes}m";
    }

    int currentStreak = 0;
    int streakSteps = 0;
    final Map<String, int> dailyStepsMap = {};

    for (var act in walkHistory) {
      final dateStr =
          '${act.startTime.year}-${act.startTime.month.toString().padLeft(2, '0')}-${act.startTime.day.toString().padLeft(2, '0')}';
      dailyStepsMap[dateStr] = (dailyStepsMap[dateStr] ?? 0) + act.steps;
    }

    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    bool todayHasSteps =
        dailyStepsMap.containsKey(todayStr) || firestoreSteps > 0;

    if (todayHasSteps) {
      currentStreak++;
      int todayWalkHistorySteps = dailyStepsMap[todayStr] ?? 0;
      streakSteps += (firestoreSteps > todayWalkHistorySteps)
          ? firestoreSteps
          : todayWalkHistorySteps;
    }

    DateTime checkDate = now.subtract(const Duration(days: 1));
    while (true) {
      final dateStr =
          '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
      if (dailyStepsMap.containsKey(dateStr) && dailyStepsMap[dateStr]! > 0) {
        currentStreak++;
        streakSteps += dailyStepsMap[dateStr]!;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    if (currentStreak == 0) {
      checkDate = now.subtract(const Duration(days: 1));
      while (true) {
        final dateStr =
            '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
        if (dailyStepsMap.containsKey(dateStr) && dailyStepsMap[dateStr]! > 0) {
          currentStreak++;
          streakSteps += dailyStepsMap[dateStr]!;
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }
    }

    // Compute current week's steps (Monday to Sunday)
    final List<double> weeklySteps = List.filled(7, 0.0);
    final int currentWeekday = now.weekday; // 1 = Monday, 7 = Sunday
    final DateTime startOfWeek = now.subtract(
      Duration(days: currentWeekday - 1),
    );
    for (int i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      double steps = (dailyStepsMap[dateStr] ?? 0).toDouble();

      if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) {
        steps = (steps > firestoreSteps) ? steps : firestoreSteps.toDouble();
      }
      weeklySteps[i] = steps;
    }

    double thisWeekTotal = weeklySteps.fold(0.0, (sum, val) => sum + val);
    double thisWeekAvg = currentWeekday > 0 ? thisWeekTotal / currentWeekday : 0;

    double lastWeekTotal = 0.0;
    final DateTime startOfLastWeek = startOfWeek.subtract(const Duration(days: 7));
    for (int i = 0; i < 7; i++) {
      final date = startOfLastWeek.add(Duration(days: i));
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      lastWeekTotal += (dailyStepsMap[dateStr] ?? 0).toDouble();
    }
    double lastWeekAvg = lastWeekTotal / 7;
    
    double percentChange = 0.0;
    if (lastWeekAvg > 0) {
      percentChange = ((thisWeekAvg - lastWeekAvg) / lastWeekAvg) * 100;
    } else if (thisWeekAvg > 0) {
      percentChange = 100.0;
    }

    int totalAppSteps = dailyStepsMap.values.fold(0, (sum, val) => sum + val);
    int todayWalkHistorySteps = dailyStepsMap[todayStr] ?? 0;
    if (firestoreSteps > todayWalkHistorySteps) {
      totalAppSteps += (firestoreSteps - todayWalkHistorySteps);
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppColors.darkBgGradient
              : const LinearGradient(
                  colors: [Color(0xFFF1F5F9), Color(0xFFF8FAFC)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
        ),
        child: SafeArea(
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  pinned: false,
                  floating: true,
                  snap: true,
                  backgroundColor: innerBoxIsScrolled
                      ? (isDark
                            ? AppColors.backgroundDark
                            : const Color(0xFFF1F5F9))
                      : Colors.transparent,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  titleSpacing: 20.0,
                  toolbarHeight: 70.0,
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$greeting,',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${currentProfile?.name ?? 'User'} 👋',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: isDark ? Colors.white : AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Bell notification button with active red badge in a modern glass circle
                        GestureDetector(
                          onTap: () {
                            ref
                                .read(notificationProvider.notifier)
                                .markAsRead();
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              builder: (context) {
                                final sheetDark =
                                    Theme.of(context).brightness ==
                                    Brightness.dark;
                                return Container(
                                  padding: const EdgeInsets.all(28.0),
                                  decoration: BoxDecoration(
                                    color: sheetDark
                                        ? const Color(0xFF0F172A)
                                        : Colors.white,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(30),
                                      topRight: Radius.circular(30),
                                    ),
                                    border: Border.all(
                                      color: sheetDark
                                          ? const Color(0x1AFFFFFF)
                                          : const Color(0xFFCBD5E1),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      const Text(
                                        'Activity Alerts',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                          color: Colors.white,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 24),
                                      if (notificationState
                                          .notifications
                                          .isEmpty)
                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 32.0,
                                          ),
                                          child: Text(
                                            'No new notifications',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.white70,
                                            ),
                                          ),
                                        )
                                      else
                                        Flexible(
                                          child: SingleChildScrollView(
                                            child: Column(
                                              children: notificationState.notifications.map((notif) {
                                                final isSuccess = notif['type'] == 'success';
                                                final iconColor = isSuccess ? AppColors.success : AppColors.primary;
                                                final iconData = isSuccess ? Icons.check_circle_outline_rounded : Icons.notifications_active_rounded;
                                                return Padding(
                                                  padding: const EdgeInsets.only(bottom: 16.0),
                                                  child: Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.all(10),
                                                        decoration: BoxDecoration(
                                                          color: iconColor.withOpacity(0.12),
                                                          shape: BoxShape.circle,
                                                        ),
                                                        child: Icon(iconData, color: iconColor, size: 20),
                                                      ),
                                                      const SizedBox(width: 16),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              notif['title'] ?? 'Notification',
                                                              style: const TextStyle(
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 13,
                                                                color: Colors.white,
                                                              ),
                                                            ),
                                                            const SizedBox(height: 4),
                                                            Text(
                                                              notif['message'] ?? '',
                                                              style: const TextStyle(
                                                                color: AppColors.textSecondaryDark,
                                                                fontSize: 11,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: 16),
                                      CustomButton(
                                        text: 'Close',
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        height: 48,
                                        type: ButtonType.primary,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF1E293B).withOpacity(0.4)
                                      : Colors.white.withOpacity(0.8),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0x2BFFFFFF)
                                        : const Color(0x1F000000),
                                    width: 1.5,
                                  ),
                                ),
                                child: Icon(
                                  Icons.notifications_outlined,
                                  color: isDark
                                      ? Colors.white70
                                      : AppColors.textLight,
                                  size: 20,
                                ),
                              ),
                              if (notificationState.hasUnread)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.danger,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Dual-Ring Glowing Avatar
                        GestureDetector(
                          onTap: () =>
                              ref
                                      .read(dashboardTabIndexProvider.notifier)
                                      .state =
                                  4,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.neonAccentGradient,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(1.5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark
                                    ? AppColors.backgroundDark
                                    : Colors.white,
                              ),
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: AppColors.primary.withOpacity(
                                  0.12,
                                ),
                                child:
                                    currentProfile?.photoUrl.startsWith(
                                          'http',
                                        ) ==
                                        true
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.network(
                                          currentProfile!.photoUrl,
                                          width: 32,
                                          height: 32,
                                          fit: BoxFit.cover,
                                          errorBuilder: (ctx, err, st) =>
                                              const Icon(
                                                Icons.person_rounded,
                                                size: 20,
                                                color: AppColors.primary,
                                              ),
                                        ),
                                      )
                                    : Icon(
                                        _getAvatarIcon(
                                          currentProfile?.photoUrl ?? '0',
                                        ),
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                  ],
                ),
              ];
            },
            body: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 110.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PremiumStepsCard(
                    showTotal: false,
                    currentSteps: firestoreSteps,
                    totalAppSteps: totalAppSteps,
                    goal: goal,
                    hourlySteps: todayStat?.hourlySteps ?? const {},
                    walkingStatus: todayStat?.walkingStatus ?? 'Inactive',
                    activeMinutes: todayStat?.activeMinutes ?? 0,
                    isCompact: true,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TodayWorkoutsScreen(
                          walks: todayWalks,
                          firestoreSteps: firestoreSteps,
                          totalAppSteps: totalAppSteps,
                          goal: goal,
                          hourlySteps: todayStat?.hourlySteps ?? const {},
                          walkingStatus: todayStat?.walkingStatus ?? 'Inactive',
                          activeMinutes: todayStat?.activeMinutes ?? 0,
                          distanceKm: todayStat?.distanceKm ?? 0.0,
                          calories: todayStat?.calories ?? 0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Four-Item Metrics Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildMetricCard(
                          icon: Icons.local_fire_department_rounded,
                          label: 'Calories',
                          value:
                              '${todayWalkCalories > 0 ? todayWalkCalories : todayCalories}',
                          unit: 'kcal',
                          color: AppColors.danger,
                          isDark: isDark,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const ActivityDetailsScreen(initialIndex: 0),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _buildMetricCard(
                          icon: Icons.location_on_rounded,
                          label: 'Distance',
                          value: todayDistanceKm < 1.0 ? '${(todayDistanceKm * 1000).toInt()}' : '${todayDistanceKm.toStringAsFixed(2)}',
                          unit: todayDistanceKm < 1.0 ? 'm' : 'km',
                          color: AppColors.secondary,
                          isDark: isDark,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const ActivityDetailsScreen(initialIndex: 1),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _buildMetricCard(
                          icon: Icons.timer_rounded,
                          label: 'Active Time',
                          value: activeMinutesString,
                          unit: '',
                          color: AppColors.accent,
                          isDark: isDark,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const ActivityDetailsScreen(initialIndex: 2),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _buildMetricCard(
                          icon: Icons.speed_rounded,
                          label: 'Avg. Pace',
                          value: paceString,
                          unit: '/km',
                          color: Colors.purple,
                          isDark: isDark,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const ActivityDetailsScreen(initialIndex: 3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Current Streak Card
                  GestureDetector(
                    onTap: () =>
                        ref.read(dashboardTabIndexProvider.notifier).state = 1,
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current Streak',
                                  style: TextStyle(
                                    color: isDark
                                        ? AppColors.textMutedDark
                                        : AppColors.textMutedLight,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$currentStreak Days',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.textLight,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$streakSteps steps total 🔥',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStreakDays(
                            isDark,
                            dailyStepsMap,
                            now,
                            firestoreSteps,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 4. Today's Route Card
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Today's Route",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textLight,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (isTracking) {
                            Navigator.of(context).pushNamed('/live-tracking');
                          } else {
                            ref.read(dashboardTabIndexProvider.notifier).state =
                                2;
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B).withOpacity(0.4)
                                : Colors.white.withOpacity(0.8),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? const Color(0x2BFFFFFF)
                                  : const Color(0x1F000000),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 10,
                            color: isDark ? Colors.white70 : Colors.black45,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      if (isTracking) {
                        Navigator.of(context).pushNamed('/live-tracking');
                      } else {
                        ref.read(dashboardTabIndexProvider.notifier).state = 2;
                      }
                    },
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: SizedBox(
                            height: 180,
                            child: LiveMapCard(
                              points: walkHistory.isNotEmpty
                                  ? walkHistory.first.route
                                  : const [],
                              height: 180,
                              interactive: true,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.65),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              walkHistory.isNotEmpty
                                  ? "${walkHistory.first.distanceKm} km • ${walkHistory.first.durationString}"
                                  : "2.45 km • 28 min",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 5. Companion Row (AI Coach and Next Challenge Card)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // AI Coach Card
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _openQuickAction(
                              context,
                              const AiCoachScreen(),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF161E2E)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0x12FFFFFF)
                                      : const Color(0xFFCBD5E1),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(
                                        0.12,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.android_rounded,
                                      color: AppColors.primary,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'AI Coach',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: isDark
                                                    ? Colors.white
                                                    : AppColors.textLight,
                                              ),
                                            ),
                                            Icon(
                                              Icons.arrow_forward_ios_rounded,
                                              size: 11,
                                              color: isDark
                                                  ? Colors.white54
                                                  : Colors.black45,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          firestoreSteps >= goal
                                              ? "Goal Achieved! Magnificent work!"
                                              : "You're doing great! Only ${goal - firestoreSteps} steps left.",
                                          style: const TextStyle(
                                            color: AppColors.textMutedDark,
                                            fontSize: 10,
                                            height: 1.3,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Next Challenge Card
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                ref
                                        .read(
                                          dashboardTabIndexProvider.notifier,
                                        )
                                        .state =
                                    3,
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF161E2E)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0x12FFFFFF)
                                      : const Color(0xFFCBD5E1),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.emoji_events_rounded,
                                      color: Colors.amber,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Next Challenge',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? Colors.white
                                                : AppColors.textLight,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          "Walk 12,000 steps",
                                          style: TextStyle(
                                            color: AppColors.textMutedDark,
                                            fontSize: 10,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        const Text(
                                          "Reward: 50 Coins",
                                          style: TextStyle(
                                            color: Colors.amber,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        // Progress bar
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          child: LinearProgressIndicator(
                                            value: 0.7,
                                            minHeight: 4,
                                            backgroundColor: isDark
                                                ? const Color(0xFF334155)
                                                : const Color(0xFFE2E8F0),
                                            valueColor:
                                                const AlwaysStoppedAnimation<
                                                  Color
                                                >(AppColors.accent),
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
                  ),
                  const SizedBox(height: 24),

                  // 6. Weekly Progress Card
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WeeklyAnalyticsScreen(),
                        ),
                      );
                    },
                    child: GlassCard(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Weekly Progress',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textLight,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  'This Week',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 14,
                                  color: isDark
                                      ? AppColors.textMutedDark
                                      : AppColors.textMutedLight,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Left: Bar chart (60% width)
                            Expanded(
                              flex: 6,
                              child: SizedBox(
                                height: 110,
                                child: IgnorePointer(
                                  child: BarChart(
                                    BarChartData(
                                    gridData: const FlGridData(show: false),
                                    titlesData: FlTitlesData(
                                      show: true,
                                      leftTitles: const AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      rightTitles: const AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      topTitles: const AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (val, meta) {
                                            const days = [
                                              'M',
                                              'T',
                                              'W',
                                              'T',
                                              'F',
                                              'S',
                                              'S',
                                            ];
                                            if (val.toInt() >= 0 &&
                                                val.toInt() < days.length) {
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 4.0,
                                                ),
                                                child: Text(
                                                  days[val.toInt()],
                                                  style: TextStyle(
                                                    color: isDark
                                                        ? AppColors
                                                              .textMutedDark
                                                        : AppColors
                                                              .textMutedLight,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              );
                                            }
                                            return const Text('');
                                          },
                                        ),
                                      ),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    barGroups: List.generate(7, (i) {
                                      final val = weeklySteps[i];
                                      return BarChartGroupData(
                                        x: i,
                                        barRods: [
                                          BarChartRodData(
                                            toY: val,
                                            gradient: AppColors.primaryGradient,
                                            width: 10,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            backDrawRodData:
                                                BackgroundBarChartRodData(
                                                  show: true,
                                                  toY: goal.toDouble() > 0 ? goal.toDouble() : 6000.0,
                                                  color: isDark
                                                      ? const Color(0xFF1E293B)
                                                      : const Color(0xFFE2E8F0),
                                                ),
                                          ),
                                        ],
                                      );
                                    }),
                                  ),
                                ),
                              ),
                            ),
                            ),
                            const SizedBox(width: 16),
                            // Right: Avg steps concentric progress ring (40% width)
                            Expanded(
                              flex: 4,
                              child: Column(
                                children: [
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                        width: 54,
                                        height: 54,
                                        child: CircularProgressIndicator(
                                          value: goal > 0 ? (thisWeekAvg / goal).clamp(0.0, 1.0) : 0.0,
                                          strokeWidth: 5.5,
                                          backgroundColor: isDark
                                              ? const Color(0xFF1E293B)
                                              : const Color(0xFFE2E8F0),
                                          valueColor:
                                              const AlwaysStoppedAnimation<
                                                Color
                                              >(AppColors.primary),
                                        ),
                                      ),
                                      const Icon(
                                        Icons.trending_up_rounded,
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Avg. Steps',
                                    style: TextStyle(
                                      color: AppColors.textMutedDark,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    thisWeekAvg.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},'),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.textLight,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${percentChange >= 0 ? '+' : ''}${percentChange.toStringAsFixed(1)}% vs last week',
                                    style: TextStyle(
                                      color: percentChange >= 0 ? AppColors.success : AppColors.danger,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    Color baseColor = color;
    Color bgColor = isDark ? color.withOpacity(0.12) : color.withOpacity(0.08);

    if (label == 'Calories') {
      baseColor = const Color(0xFFEF4444); // Red/Rose
      bgColor = isDark ? const Color(0xFF4C0519) : const Color(0xFFFFF1F2);
    } else if (label == 'Distance') {
      baseColor = const Color(0xFF3B82F6); // Blue
      bgColor = isDark
          ? const Color(0xFF1E3A8A).withOpacity(0.3)
          : const Color(0xFFEFF6FF);
    } else if (label == 'Active Time') {
      baseColor = const Color(0xFF22C55E); // Green
      bgColor = isDark
          ? const Color(0xFF064E3B).withOpacity(0.3)
          : const Color(0xFFF0FDF4);
    } else if (label == 'Avg. Pace') {
      baseColor = const Color(0xFF8B5CF6); // Purple
      bgColor = isDark
          ? const Color(0xFF2E1065).withOpacity(0.3)
          : const Color(0xFFF5F3FF);
    }

    final textColor = isDark ? baseColor.withOpacity(0.9) : baseColor;
    final valueColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 104,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? baseColor.withOpacity(0.18)
                : baseColor.withOpacity(0.08),
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18.5),
          child: Stack(
            children: [
              // Wave decoration at bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 32,
                child: CustomPaint(painter: _MetricCardWavePainter(baseColor)),
              ),
              // Card contents
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: isDark
                            ? baseColor.withOpacity(0.15)
                            : baseColor.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: baseColor, size: 15),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      label,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Outfit',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          value,
                          style: TextStyle(
                            color: valueColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Outfit',
                          ),
                        ),
                        if (unit.isNotEmpty) ...[
                          const SizedBox(width: 1.5),
                          Text(
                            unit,
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textMutedLight,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreakDays(
    bool isDark,
    Map<String, int> dailyStepsMap,
    DateTime now,
    int firestoreSteps,
  ) {
    final daysList = <Widget>[];
    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final dateStr =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final hasSteps =
          (i == 0 && firestoreSteps > 0) ||
          (dailyStepsMap.containsKey(dateStr) && dailyStepsMap[dateStr]! > 0);
      final isCurrent = (i == 0); // Today is the last item
      final dayName = _weekdayName(d.weekday)[0]; // e.g., 'M', 'T'

      daysList.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: isCurrent
                      ? (hasSteps
                            ? Colors.amber.withOpacity(0.2)
                            : Colors.transparent)
                      : (hasSteps
                            ? AppColors.success.withOpacity(0.12)
                            : Colors.transparent),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCurrent
                        ? (hasSteps
                              ? Colors.amber
                              : (isDark ? Colors.white24 : Colors.black12))
                        : (hasSteps
                              ? AppColors.success
                              : (isDark ? Colors.white24 : Colors.black12)),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: hasSteps
                      ? Icon(
                          isCurrent ? Icons.star_rounded : Icons.check_rounded,
                          size: 12,
                          color: isCurrent ? Colors.amber : AppColors.success,
                        )
                      : const SizedBox(),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dayName,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: isCurrent
                      ? AppColors.primary
                      : (isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Row(mainAxisSize: MainAxisSize.min, children: daysList);
  }
}

class _MetricCardWavePainter extends CustomPainter {
  final Color color;
  _MetricCardWavePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.08)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height * 0.8)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.6,
        size.width * 0.65,
        size.height * 0.85,
      )
      ..quadraticBezierTo(
        size.width * 0.85,
        size.height * 0.95,
        size.width,
        size.height * 0.75,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);

    // Draw the top stroke of the wave for high fidelity!
    final strokePaint = Paint()
      ..color = color.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final strokePath = Path()
      ..moveTo(0, size.height * 0.8)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.6,
        size.width * 0.65,
        size.height * 0.85,
      )
      ..quadraticBezierTo(
        size.width * 0.85,
        size.height * 0.95,
        size.width,
        size.height * 0.75,
      );

    canvas.drawPath(strokePath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
