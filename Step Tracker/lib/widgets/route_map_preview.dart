import 'dart:math';
import 'package:flutter/material.dart';
import '../models/walk_activity.dart';
import '../theme/app_colors.dart';

class RouteMapPreview extends StatelessWidget {
  final List<GeoPoint> points;
  final double height;
  final bool interactive;

  const RouteMapPreview({
    Key? key,
    required this.points,
    this.height = 200.0,
    this.interactive = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0x1AFFFFFF) : const Color(0x33000000),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Stack(
          children: [
            // Grid background to look technical
            CustomPaint(
              size: Size.infinite,
              painter: _MapGridPainter(isDark: isDark),
            ),
            // Custom Painter to draw the GPS line
            if (points.isNotEmpty)
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: CustomPaint(
                    painter: _RoutePathPainter(
                      points: points,
                      isDark: isDark,
                    ),
                  ),
                ),
              )
            else
              const Center(
                child: Text(
                  'GPS Signal Weak - Recalibrating',
                  style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
                ),
              ),
            // Map watermark controls
            Positioned(
              right: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black38 : Colors.white70,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.gps_fixed,
                      size: 10,
                      color: isDark ? AppColors.primary : Colors.blueGrey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'StrideAI Engine v2.0',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  final bool isDark;

  _MapGridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? const Color(0x0AFFFFFF) : const Color(0x0E000000)
      ..strokeWidth = 1;

    const spacing = 30.0;
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double j = 0; j < size.height; j += spacing) {
      canvas.drawLine(Offset(0, j), Offset(size.width, j), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MapGridPainter oldDelegate) => false;
}

class _RoutePathPainter extends CustomPainter {
  final List<GeoPoint> points;
  final bool isDark;

  _RoutePathPainter({required this.points, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    // 1. Calculate boundaries to fit path on canvas
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (final pt in points) {
      minLat = min(minLat, pt.latitude);
      maxLat = max(maxLat, pt.latitude);
      minLng = min(minLng, pt.longitude);
      maxLng = max(maxLng, pt.longitude);
    }

    double latSpan = maxLat - minLat;
    double lngSpan = maxLng - minLng;

    // Prevent divide by zero if it's a single point or horizontal/vertical line
    if (latSpan == 0) latSpan = 0.001;
    if (lngSpan == 0) lngSpan = 0.001;

    // Helper: translate lat/lng to canvas coordinates
    Offset getCanvasOffset(GeoPoint pt) {
      // Note: GPS lat increases going UP, canvas y increases going DOWN
      final double x = ((pt.longitude - minLng) / lngSpan) * size.width;
      final double y = size.height - (((pt.latitude - minLat) / latSpan) * size.height);
      return Offset(x, y);
    }

    // 2. Draw route line shadow (glowing neon effect on dark mode)
    if (isDark) {
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0)
        ..color = AppColors.primary.withOpacity(0.4);

      final glowPath = Path();
      glowPath.moveTo(getCanvasOffset(points.first).dx, getCanvasOffset(points.first).dy);
      for (int i = 1; i < points.length; i++) {
        final off = getCanvasOffset(points[i]);
        glowPath.lineTo(off.dx, off.dy);
      }
      canvas.drawPath(glowPath, glowPaint);
    }

    // 3. Draw primary route line
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = LinearGradient(
        colors: [AppColors.primary, AppColors.secondary],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    path.moveTo(getCanvasOffset(points.first).dx, getCanvasOffset(points.first).dy);
    for (int i = 1; i < points.length; i++) {
      final off = getCanvasOffset(points[i]);
      path.lineTo(off.dx, off.dy);
    }
    canvas.drawPath(path, linePaint);

    // 4. Draw Start marker
    final startOffset = getCanvasOffset(points.first);
    final startPaint = Paint()
      ..color = AppColors.secondary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(startOffset, 6.0, startPaint);

    final startBorder = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(startOffset, 6.0, startBorder);

    // 5. Draw End marker
    final endOffset = getCanvasOffset(points.last);
    final endPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(endOffset, 7.0, endPaint);

    final endBorder = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(endOffset, 7.0, endBorder);
  }

  @override
  bool shouldRepaint(covariant _RoutePathPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.isDark != isDark;
  }
}
