import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../providers/profile_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/walk_provider.dart';
import '../weight/weight_tracker_screen.dart';
import '../insights/health_insights_screen.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

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

  void _openProfileModal(BuildContext context, Widget screen) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => screen,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileStreamProvider);
    final themeState = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    final p = profileState.value;
    if (p == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final xp = p.xp;
    final xpToNextLevel = p.level * 1000;
    final xpPercent = (xpToNextLevel > 0) ? (xp / xpToNextLevel).clamp(0.0, 1.0) : 0.0;

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
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  pinned: false,
                  floating: true,
                  snap: true,
                  backgroundColor: innerBoxIsScrolled
                      ? (isDark ? AppColors.backgroundDark : const Color(0xFFF1F5F9))
                      : Colors.transparent,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  titleSpacing: 24.0,
                  toolbarHeight: 60.0,
                  title: Text(
                    'Your Profile',
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  ),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: IconButton(
                        icon: const Icon(Icons.settings_rounded, color: AppColors.primary, size: 24),
                        onPressed: () {
                          Navigator.of(context).pushNamed('/settings');
                        },
                      ),
                    ),
                  ],
                ),
              ];
            },
            body: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 110.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                // Avatar and Level Info card
                GlassCard(
                  gradient: isDark
                      ? const LinearGradient(
                          colors: [Color(0xFF1E1B4B), Color(0xFF2E1065)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : const LinearGradient(
                          colors: [Color(0xFFF3E8FF), Color(0xFFFAE8FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.6),
                            child: p.photoUrl.startsWith('http')
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(36),
                                    child: Image.network(
                                      p.photoUrl,
                                      width: 72,
                                      height: 72,
                                      fit: BoxFit.cover,
                                      errorBuilder: (ctx, err, st) => const Icon(Icons.person_rounded, size: 44, color: AppColors.primary),
                                    ),
                                  )
                                : Icon(
                                    _getAvatarIcon(p.photoUrl),
                                    size: 44,
                                    color: AppColors.primary,
                                  ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context).pushNamed('/edit-profile');
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.edit_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              p.name,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (FirebaseAuth.instance.currentUser?.email != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                FirebaseAuth.instance.currentUser!.email!,
                                style: TextStyle(
                                  color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                              ),
                              child: Text(
                                'Level ${p.level}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Physical Parameter Grid
                Text(
                  'Physical Diagnostics',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: [
                    _buildParamTile(
                      label: 'Height',
                      value: '${p.height.toInt()} cm',
                      icon: Icons.straighten_rounded,
                      baseColor: const Color(0xFF10B981),
                      isDark: isDark,
                      lightBg: const Color(0xFFECFDF5),
                      darkBg: const Color(0xFF064E3B).withOpacity(0.2),
                    ),
                    _buildParamTile(
                      label: 'Weight',
                      value: '${p.weight} kg',
                      icon: Icons.monitor_weight_rounded,
                      baseColor: const Color(0xFFF97316),
                      isDark: isDark,
                      lightBg: const Color(0xFFFFF7ED),
                      darkBg: const Color(0xFF7C2D12).withOpacity(0.2),
                    ),
                    _buildParamTile(
                      label: 'Age / Gender',
                      value: '${p.age} y / ${p.gender}',
                      icon: Icons.people_rounded,
                      baseColor: const Color(0xFF3B82F6),
                      isDark: isDark,
                      lightBg: const Color(0xFFEFF6FF),
                      darkBg: const Color(0xFF1E3A8A).withOpacity(0.2),
                    ),
                    _buildParamTile(
                      label: 'Goal (Steps)',
                      value: '${p.dailyGoal}',
                      icon: Icons.track_changes_rounded,
                      baseColor: const Color(0xFFEC4899),
                      isDark: isDark,
                      lightBg: const Color(0xFFFDF2F8),
                      darkBg: const Color(0xFF701A75).withOpacity(0.2),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Connected Metrics Actions
                _buildActionCard(
                  icon: Icons.monitor_weight_outlined,
                  title: 'Weight History & BMI',
                  desc: 'Current BMI: ${p.bmi.toStringAsFixed(1)} (${p.bmiCategory})',
                  onTap: () => _openProfileModal(context, const WeightTrackerScreen()),
                  baseColor: const Color(0xFF8B5CF6),
                  isDark: isDark,
                  lightBg: const Color(0xFFF5F3FF),
                  darkBg: const Color(0xFF2E1065).withOpacity(0.2),
                ),
                const SizedBox(height: 16),
                _buildActionCard(
                  icon: Icons.assignment_outlined,
                  title: 'Weekly Health Reports',
                  desc: 'AI health summaries and fitness trends.',
                  onTap: () => _openProfileModal(context, const HealthInsightsScreen()),
                  baseColor: const Color(0xFF0284C7),
                  isDark: isDark,
                  lightBg: const Color(0xFFF0F9FF),
                  darkBg: const Color(0xFF0C4A6E).withOpacity(0.2),
                ),
                const SizedBox(height: 24),

                // System Settings
                Text(
                  'System Settings',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                GlassCard(
                  gradient: isDark
                      ? const LinearGradient(
                          colors: [Color(0xFF1E1B4B), Color(0xFF131130)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : const LinearGradient(
                          colors: [Color(0xFFFDFBFF), Color(0xFFF5F3FF)], // Soft violet-tinted white
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  child: Column(
                    children: [
                      // Dark Mode Switch
                      Row(
                        children: [
                          const Icon(Icons.dark_mode_outlined, color: AppColors.primary),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Text('Dark UI Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                          Switch(
                            value: themeState == ThemeMode.dark,
                            activeColor: AppColors.primary,
                            onChanged: (val) {
                              themeNotifier.toggleTheme();
                            },
                          ),
                        ],
                      ),
                      Divider(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06), height: 24),


                      // Connected Devices
                      _buildSettingRow(Icons.smartphone_rounded, 'Connected Devices', 'Phone sensors active'),
                      Divider(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06), height: 24),



                      // Log out
                      _buildSettingRow(
                        Icons.logout_rounded,
                        'Logout',
                        'Sign out of ${p.name}',
                        onTap: () async {
                          // Sign out of Firebase Auth
                          await ref.read(firebaseAuthServiceProvider).signOut();
                          
                          // Redirect to login screen
                          if (context.mounted) {
                            Navigator.of(context).pushReplacementNamed('/login');
                          }
                        },
                      ),
                    ],
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

  Widget _buildParamTile({
    required String label,
    required String value,
    required IconData icon,
    required Color baseColor,
    required bool isDark,
    required Color lightBg,
    required Color darkBg,
  }) {
    final bgColor = isDark ? darkBg : lightBg;
    final textColor = isDark ? baseColor.withOpacity(0.9) : baseColor;
    final valueColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? baseColor.withOpacity(0.15) : baseColor.withOpacity(0.08),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Outfit',
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark ? baseColor.withOpacity(0.12) : baseColor.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: baseColor, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: valueColor,
              fontFamily: 'Outfit',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String desc,
    required VoidCallback onTap,
    required Color baseColor,
    required bool isDark,
    required Color lightBg,
    required Color darkBg,
  }) {
    final bgColor = isDark ? darkBg : lightBg;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final descColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? baseColor.withOpacity(0.15) : baseColor.withOpacity(0.08),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? baseColor.withOpacity(0.15) : baseColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: baseColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: textColor,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: TextStyle(
                      color: descColor,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingRow(IconData icon, String title, String desc, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondaryDark),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(color: AppColors.textMutedDark, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMutedDark),
        ],
      ),
    );
  }
}
