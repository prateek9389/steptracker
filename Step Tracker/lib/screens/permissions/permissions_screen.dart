import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/glass_card.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> with WidgetsBindingObserver {
  final Map<String, PermissionItem> _permissions = {
    'activity': PermissionItem(
      title: 'Activity Recognition',
      desc: 'Count your daily steps automatically using built-in phone hardware sensors.',
      icon: Icons.directions_walk_rounded,
      color: AppColors.primary,
    ),
    'gps': PermissionItem(
      title: 'GPS Location',
      desc: 'Map outdoor walking and running paths, and calculate real-time average paces.',
      icon: Icons.gps_fixed_rounded,
      color: AppColors.secondary,
    ),
    'notification': PermissionItem(
      title: 'Notifications',
      desc: 'Send daily step progress milestones, water intake warnings, and AI updates.',
      icon: Icons.notifications_active_rounded,
      color: AppColors.accent,
    ),
    'background': PermissionItem(
      title: 'Background Activity',
      desc: 'Maintain count synchronization and track GPS trails even when the phone is locked.',
      icon: Icons.sync_rounded,
      color: AppColors.primary,
    ),
    'storage': PermissionItem(
      title: 'Local Storage',
      desc: 'Cache workout records locally for instant sync and offline map access.',
      icon: Icons.storage_rounded,
      color: AppColors.secondary,
    ),
  };

  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkCurrentPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkCurrentPermissions();
    }
  }

  Future<void> _checkCurrentPermissions() async {
    for (var key in _permissions.keys) {
      bool isEnabled = false;
      if (key == 'gps') {
        final permission = await Geolocator.checkPermission();
        isEnabled = permission == LocationPermission.whileInUse || permission == LocationPermission.always;
      } else {
        Permission? p;
        switch (key) {
          case 'activity':
            p = Permission.activityRecognition;
            break;
          case 'notification':
            p = Permission.notification;
            break;
          case 'background':
            p = Permission.locationAlways;
            break;
          case 'storage':
            final storageStatus = await Permission.storage.status;
            final photosStatus = await Permission.photos.status;
            isEnabled = storageStatus.isGranted || photosStatus.isGranted;
            break;
        }
        if (p != null) {
          isEnabled = (await p.status).isGranted;
        }
      }
      if (mounted) {
        setState(() {
          _permissions[key]!.isEnabled = isEnabled;
        });
      }
    }
  }

  Future<bool> _requestPermission(String key) async {
    if (key == 'gps') {
      try {
        // 1. Check if GPS services are enabled on the phone
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          // Open Location settings so user can enable it
          await Geolocator.openLocationSettings();
          return false;
        }
      } catch (e) {
        debugPrint('GPS hardware check failed: $e');
      }

      try {
        // 2. Check current Geolocator permission status
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          // Trigger the native location prompt ("While using the app", "Only this time", "Don't allow")
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.deniedForever) {
          // Location permissions are permanently denied, direct user to App Settings
          await openAppSettings();
          // Check again after user returns
          permission = await Geolocator.checkPermission();
        }

        return permission == LocationPermission.whileInUse || permission == LocationPermission.always;
      } catch (e) {
        debugPrint('Geolocator permission request failed: $e');
        return false;
      }
    }

    Permission permission;
    switch (key) {
      case 'activity':
        permission = Permission.activityRecognition;
        break;
      case 'notification':
        permission = Permission.notification;
        break;
      case 'background':
        permission = Permission.locationAlways;
        break;
      case 'storage':
        try {
          final storageStatus = await Permission.storage.status;
          if (storageStatus.isGranted) return true;

          final storageResult = await Permission.storage.request();
          if (storageResult.isGranted) {
            return true;
          } else {
            final photosStatus = await Permission.photos.status;
            if (photosStatus.isGranted) return true;

            final photosResult = await Permission.photos.request();
            if (photosResult.isPermanentlyDenied) {
              await openAppSettings();
              return (await Permission.photos.status).isGranted;
            }
            return photosResult.isGranted;
          }
        } catch (e) {
          debugPrint('Storage/Photos permission request failed: $e');
          return false;
        }
      default:
        return true;
    }

    try {
      final status = await permission.status;
      if (status.isGranted) return true;

      final result = await permission.request();
      if (result.isPermanentlyDenied) {
        await openAppSettings();
        return (await permission.status).isGranted;
      }
      return result.isGranted;
    } catch (e) {
      debugPrint('Permission request failed for $key: $e');
      return false;
    }
  }

  Future<void> _allowAll() async {
    setState(() {
      _isConnecting = true;
    });

    bool allGranted = true;
    for (var key in _permissions.keys) {
      if (!_permissions[key]!.isEnabled) {
        final granted = await _requestPermission(key);
        setState(() {
          _permissions[key]!.isEnabled = granted;
        });
        if (!granted && key == 'gps') {
          allGranted = false; // Only block navigation if GPS location permission is denied
        }
      }
    }

    setState(() {
      _isConnecting = false;
    });

    if (allGranted && mounted) {
      Navigator.of(context).pushReplacementNamed('/profile-setup');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.darkBgGradient : const LinearGradient(
            colors: [Color(0xFFE2E8F0), Color(0xFFF8FAFC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top header text group
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Device Setup',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Enable permissions below to ensure accurate AI calculations and step records.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // List of Permissions (grouped closer together)
                ..._permissions.entries.map((entry) {
                  final key = entry.key;
                  final p = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: GestureDetector(
                      onTap: () async {
                        if (!p.isEnabled) {
                          final granted = await _requestPermission(key);
                          setState(() {
                            p.isEnabled = granted;
                          });
                        } else {
                          setState(() {
                            p.isEnabled = false;
                          });
                        }
                      },
                      child: GlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                        child: Row(
                          children: [
                            // Icon Circle
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: p.color.withOpacity(0.12),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: p.color.withOpacity(0.2),
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(p.icon, size: 22, color: p.color),
                            ),
                            const SizedBox(width: 10),

                            // Text block
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.title,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    p.desc,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 12,
                                      height: 1.3,
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),

                            // State Switch
                            Switch(
                              value: p.isEnabled,
                              activeThumbColor: AppColors.primary,
                              onChanged: (val) async {
                                if (val) {
                                  final granted = await _requestPermission(key);
                                  setState(() {
                                    p.isEnabled = granted;
                                  });
                                } else {
                                  setState(() {
                                    p.isEnabled = false;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                const Spacer(),

                CustomButton(
                  text: 'Grant All Permissions',
                  onPressed: _allowAll,
                  isLoading: _isConnecting,
                  type: ButtonType.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PermissionItem {
  final String title;
  final String desc;
  final IconData icon;
  final Color color;
  bool isEnabled;

  PermissionItem({
    required this.title,
    required this.desc,
    required this.icon,
    required this.color,
    this.isEnabled = false,
  });
}
