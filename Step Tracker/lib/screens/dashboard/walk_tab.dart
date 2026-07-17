import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' hide ActivityType;
import 'package:permission_handler/permission_handler.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../services/walk_service.dart';
import '../../models/walk_activity.dart';
import '../../services/permission_service.dart';
import '../../services/gps_service.dart';
import '../../providers/auth_provider.dart';

class WalkTab extends ConsumerStatefulWidget {
  const WalkTab({super.key});

  @override
  ConsumerState<WalkTab> createState() => _WalkTabState();
}

class _WalkTabState extends ConsumerState<WalkTab> {
  ActivityType _selectedType = ActivityType.outdoorWalk;

  // Real-time sensor status shown on the status cards
  bool _gpsOk = false;
  bool _sensorOk = false;

  @override
  void initState() {
    super.initState();
    _checkSensorStatus();
  }

  Future<void> _checkSensorStatus() async {
    final gpsEnabled = await Geolocator.isLocationServiceEnabled();
    final locPerm = await Geolocator.checkPermission();
    final activityPerm = await Permission.activityRecognition.status;

    if (!mounted) return;
    setState(() {
      _gpsOk = gpsEnabled &&
          (locPerm == LocationPermission.always ||
              locPerm == LocationPermission.whileInUse);
      _sensorOk = activityPerm.isGranted;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.darkBgGradient : const LinearGradient(
            colors: [Color(0xFFF1F5F9), Color(0xFFF8FAFC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 110.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Record Workout',
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select activity and start StrideAI telemetry tracking.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),

                // Signal and Sensor status indicators
                Row(
                  children: [
                    Expanded(
                      child: _buildStatusCard(
                        icon: Icons.gps_fixed_rounded,
                        title: 'GPS Signal',
                        value: _gpsOk ? 'Ready' : 'Unavailable',
                        color: _gpsOk ? AppColors.success : AppColors.danger,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatusCard(
                        icon: Icons.directions_walk_rounded,
                        title: 'Step Sensor',
                        value: _sensorOk ? 'Ready' : 'No Permission',
                        color: _sensorOk ? AppColors.success : Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Activity selection grid
                Text(
                  'Choose Sport Category',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.4,
                  children: [
                    _buildActivityTile(ActivityType.outdoorWalk, Icons.directions_walk_rounded, 'Outdoor Walk'),
                    _buildActivityTile(ActivityType.indoorWalk, Icons.nordic_walking_rounded, 'Indoor Walk'),
                    _buildActivityTile(ActivityType.running, Icons.directions_run_rounded, 'Running'),
                    _buildActivityTile(ActivityType.hiking, Icons.terrain_rounded, 'Hiking'),
                  ],
                ),
                const SizedBox(height: 48),

                // Start button section
                Center(
                  child: Column(
                    children: [
                      // Large glowing pulse button
                      GestureDetector(
                        onTap: _onStartPressed,
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.primaryGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                blurRadius: 28,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.play_arrow_rounded, size: 50, color: Colors.black),
                                Text(
                                  'START',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Pace target calibrated to steps',
                        style: TextStyle(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          fontSize: 12,
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
    );
  }

  Future<void> _onStartPressed() async {
    final gpsService = ref.read(gpsServiceProvider);
    final permissionService = ref.read(permissionServiceProvider);

    // 1. Request ACTIVITY_RECOGNITION permission (needed for step counting on
    //    Android 10+ / iOS).  Do this BEFORE starting the pedometer.
    final activityStatus = await Permission.activityRecognition.request();
    if (!mounted) return;
    if (activityStatus.isPermanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Step counting needs Activity Recognition permission. '  
            'Please enable it in App Settings.',
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
    }
    // Update sensor status card to reflect the new permission state
    setState(() => _sensorOk = activityStatus.isGranted);

    // 2. Check location permission
    var status = await permissionService.checkLocationPermission();
    if (status == LocationPermission.denied ||
        status == LocationPermission.unableToDetermine) {
      status = await permissionService.requestLocationPermission();
    }

    if (!mounted) return;
    if (status == LocationPermission.deniedForever) {
      final proceed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.settings_suggest_rounded, color: AppColors.accent),
              SizedBox(width: 10),
              Text(
                'Settings Required',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: const Text(
            'Location permission has been permanently denied. '
            'Please open StrideAI App Settings and manually '
            'enable Location permission to track your walk.',
            style: TextStyle(
              color: AppColors.textSecondaryDark,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondaryDark),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary),
              child: const Text(
                'Open Settings',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );

      if (proceed == true) await permissionService.openAppSettingsPage();
      return;
    }

    if (status == LocationPermission.whileInUse ||
        status == LocationPermission.always) {
      // 3. Check GPS service is on
      bool serviceEnabled = await gpsService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        final proceed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24)),
            title: const Row(
              children: [
                Icon(Icons.location_off_rounded, color: AppColors.secondary),
                SizedBox(width: 10),
                Text(
                  'GPS is Disabled',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            content: const Text(
              'StrideAI requires GPS Location Services to track your '
              'walking route, calculate average pace, and save your '
              'distance accurately. Please enable Location Services.',
              style: TextStyle(
                color: AppColors.textSecondaryDark,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.textSecondaryDark),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary),
                child: const Text(
                  'Open Settings',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );

        if (proceed == true) await gpsService.openLocationSettings();
        return;
      }

      // Update GPS status card
      setState(() => _gpsOk = true);

      // 4. All good — start the walk
      final user = ref.read(currentUserProvider);
      if (user != null) {
        ref.read(walkServiceProvider).startWalk(user.uid);
      }
      if (!mounted) return;
      Navigator.of(context).pushNamed('/live-tracking');
    }
  }

  Widget _buildStatusCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 18,
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 10, color: AppColors.textMutedDark, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTile(ActivityType type, IconData icon, String label) {
    final isSelected = _selectedType == type;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => setState(() => _selectedType = type),
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.12)
              : (isDark ? const Color(0xFF161E2E) : Colors.white),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? const Color(0x1AFFFFFF) : const Color(0xFFE2E8F0)),
            width: isSelected ? 2.5 : 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
