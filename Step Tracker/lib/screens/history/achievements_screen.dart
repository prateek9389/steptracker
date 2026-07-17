import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class AchievementsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> achievements;

  const AchievementsScreen({
    super.key,
    required this.achievements,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF090D16) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('All Achievements', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: achievements.isEmpty
          ? Center(
              child: Text(
                'No achievements yet.\nKeep walking to earn them!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontSize: 16,
                ),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 24,
                childAspectRatio: 0.75,
              ),
              itemCount: achievements.length,
              itemBuilder: (context, index) {
                final a = achievements[index];
                final color = a['color'] as Color;
                final earned = a['sub'] == 'Earned';
                
                return Column(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: earned
                            ? LinearGradient(
                                colors: [color, color.withOpacity(0.6)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: earned ? null : (isDark ? Colors.white12 : Colors.grey.shade300),
                        border: Border.all(
                          color: earned ? color : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: earned
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : [],
                      ),
                      child: Center(
                        child: Text(
                          a['emoji'] as String,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      a['title'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      a['sub'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        color: earned
                            ? AppColors.success
                            : (isDark ? Colors.white38 : Colors.black38),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                  ],
                );
              },
            ),
    );
  }
}
