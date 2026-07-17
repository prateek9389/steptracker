import 'package:flutter/material.dart';

class AppColors {
  // Brand Palette
  static const Color primary = Color(0xFF7C3AED);     // Violet
  static const Color secondary = Color(0xFF2563EB);   // Royal Blue
  static const Color accent = Color(0xFFEC4899);      // Pink Accent
  
  // Dark Theme Colors (Primary UI)
  static const Color backgroundDark = Color(0xFF0B1220);
  static const Color cardDark = Color(0xFF161E2E);
  static const Color textDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFF94A3B8); // Slate 400
  static const Color textMutedDark = Color(0xFF64748B);     // Slate 500

  // Light Theme Colors (Secondary Support)
  static const Color backgroundLight = Color(0xFFF8FAFC);   // Slate 50
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color textLight = Color(0xFF0F172A);         // Slate 900
  static const Color textSecondaryLight = Color(0xFF475569); // Slate 600
  static const Color textMutedLight = Color(0xFF94A3B8);     // Slate 400

  // Status/Alert Colors
  static const Color success = Color(0xFF10B981); // Emerald Green
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  // Neon Glowing Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF6D28D9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient neonBlueGradient = LinearGradient(
    colors: [secondary, Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient neonPurpleGradient = LinearGradient(
    colors: [primary, Color(0xFF5B21B6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient neonAccentGradient = LinearGradient(
    colors: [primary, Color(0xFF3B82F6)], // Violet to Blue
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [cardDark, Color(0xFF1E293B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [
      Color(0x1AFFFFFF), // White with 10% opacity
      Color(0x05FFFFFF), // White with 2% opacity
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkBgGradient = LinearGradient(
    colors: [backgroundDark, Color(0xFF070B14)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
