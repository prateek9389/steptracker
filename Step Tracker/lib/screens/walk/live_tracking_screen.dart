import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../widgets/live_map_card.dart';
import '../../providers/walk_provider.dart';
import '../../services/walk_service.dart';
import '../../models/walk_session.dart';
import 'walk_summary_screen.dart';

class LiveTrackingScreen extends ConsumerStatefulWidget {
  const LiveTrackingScreen({super.key});

  @override
  ConsumerState<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends ConsumerState<LiveTrackingScreen> {
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _confirmStopWorkout() {
    final act = ref.read(activeWalkStreamProvider).value;
    if (act == null) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Finish Workout?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Are you sure you want to stop and record this workout in StrideAI history?',
                style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondaryDark)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog

                setState(() {
                  _isSaving = true;
                });

                // Snapshot the session NOW before stopWalk() clears it.
                // stopWalk() only adds endTime and completed status — all the
                // real metrics (distance, steps, avgSpeed, route…) are already
                // in _currentSession.  We build the final summary object here
                // with the same data plus the end timestamp.
                final walkService = ref.read(walkServiceProvider);
                final snapshot = walkService.currentSession;

                await walkService.stopWalk();

                if (!context.mounted) return;

                if (snapshot != null) {
                  // Build the completed session with endTime so the summary
                  // shows the right duration string.
                  final completedSession = snapshot.copyWith(
                    trackingStatus: TrackingStatus.completed,
                    endTime: DateTime.now(),
                  );
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => WalkSummaryScreen(activity: completedSession),
                    ),
                  );
                } else {
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Save Workout', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }


  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final walkService = ref.watch(walkServiceProvider);
    
    return StreamBuilder<WalkSession?>(
      stream: walkService.localSessionStream,
      initialData: walkService.currentSession,
      builder: (context, snapshot) {
        final walkSession = snapshot.data;
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        if (_isSaving) {
          return Scaffold(
            backgroundColor: isDark ? const Color(0xFF090D16) : Colors.white,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
                  const SizedBox(height: 24),
                  Text('Saving Workout...', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        }

        if (walkSession == null) {
          return Scaffold(
            backgroundColor: isDark ? const Color(0xFF090D16) : Colors.white,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      strokeWidth: 4.5,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Locating GPS Signal...',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Establishing connection with satellite sensors...',
                    style: TextStyle(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final act = walkSession;
        final isPaused = act.trackingStatus == TrackingStatus.paused;

        return Scaffold(
          body: Stack(
            children: [
              // 1. Full Screen Map
          Positioned.fill(
            bottom: 290, // Leave room for metrics sheet at bottom
            child: LiveMapCard(
              points: act.route,
              height: double.infinity,
              interactive: true,
            ),
          ),

          // Map Header Details (Signal strength, GPS Status, Dismiss button)
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.gps_fixed_rounded, color: AppColors.primary, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'WALK',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                // Discard Button
                IconButton(
                  icon: const CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: Icon(Icons.close_rounded, color: Colors.white),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFF0F172A),
                        title: const Text('Discard Workout?'),
                        content: const Text('This will delete all telemetry records collected for this workout.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              await ref.read(walkServiceProvider).stopWalk();
                              if (context.mounted) {
                                Navigator.of(context).pop();
                                Navigator.of(context).pop();
                              }
                            },
                            child: const Text('Discard', style: TextStyle(color: AppColors.danger)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // 3. Pause Overlay Screen (Moved here so it doesn't cover controls)
          if (isPaused)
            Positioned.fill(
              bottom: 290, // Match the map's bottom padding
              child: Container(
                color: Colors.black.withOpacity(0.65),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.pause_circle_filled_rounded, size: 84, color: AppColors.primary),
                      const SizedBox(height: 16),
                      Text(
                        'Workout Paused',
                        style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'GPS tracking is suspended temporarily.',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 2. Sliding Metrics Sheet
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              // Removed fixed height to fix responsive overflow
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -6)),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // Hug content tightly
                    children: [
                      // Giant Steps / Distance Display
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('DISTANCE', style: TextStyle(color: AppColors.textMutedDark, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        act.distanceKm.toStringAsFixed(2),
                                        style: theme.textTheme.displayMedium?.copyWith(
                                          fontFamily: 'Outfit',
                                          fontWeight: FontWeight.w900,
                                          fontSize: 40,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Text('km', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('DURATION', style: TextStyle(color: AppColors.textMutedDark, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    act.durationString,
                                    style: theme.textTheme.displayMedium?.copyWith(
                                      fontFamily: 'Outfit',
                                      fontWeight: FontWeight.w900,
                                      fontSize: 40,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Row of Metrics
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSubMetric('Steps', '${act.steps}'),
                          _buildSubMetric('Calories', '${act.calories} kcal'),
                          _buildSubMetric('Avg Speed', '${act.avgSpeedKmH.toStringAsFixed(1)} km/h'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSubMetric('Current Pace', '${act.currentPaceString} /km'),
                          _buildSubMetric('Avg Pace', '${act.paceString} /km'),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Controls Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!isPaused)
                            GestureDetector(
                              onTap: () => ref.read(walkServiceProvider).pauseWalk(),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.pause_rounded, color: Colors.black, size: 28),
                              ),
                            )
                          else
                            GestureDetector(
                              onTap: () => ref.read(walkServiceProvider).resumeWalk(),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.primary, width: 2),
                                ),
                                child: const Icon(Icons.play_arrow_rounded, color: AppColors.primary, size: 28),
                              ),
                            ),
                          const SizedBox(width: 32),
                          // Stop button (Always visible)
                          GestureDetector(
                            onTap: _confirmStopWorkout,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: AppColors.danger,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.stop_rounded, color: Colors.white, size: 28),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _buildSubMetric(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppColors.textMutedDark, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
