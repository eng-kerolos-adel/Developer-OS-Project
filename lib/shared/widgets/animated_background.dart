import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class AnimatedBackground extends StatefulWidget {
  final Widget child;
  final bool showGrid;

  const AnimatedBackground({
    super.key,
    required this.child,
    this.showGrid = true,
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late AnimationController _orb1Controller;
  late AnimationController _orb2Controller;
  late AnimationController _orb3Controller;

  @override
  void initState() {
    super.initState();
    _orb1Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _orb2Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
    _orb3Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _orb1Controller.dispose();
    _orb2Controller.dispose();
    _orb3Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Base background
        Container(
          color: isDark ? AppTheme.darkest : AppTheme.offWhite,
        ),
        // Animated orbs
        AnimatedBuilder(
          animation: Listenable.merge([_orb1Controller, _orb2Controller, _orb3Controller]),
          builder: (context, _) {
            return CustomPaint(
              painter: _OrbPainter(
                orb1Value: _orb1Controller.value,
                orb2Value: _orb2Controller.value,
                orb3Value: _orb3Controller.value,
                isDark: isDark,
              ),
              size: Size.infinite,
            );
          },
        ),
        // Grid overlay
        if (widget.showGrid)
          CustomPaint(
            painter: _GridPainter(isDark: isDark),
            size: Size.infinite,
          ),
        // Content
        widget.child,
      ],
    );
  }
}

class _OrbPainter extends CustomPainter {
  final double orb1Value;
  final double orb2Value;
  final double orb3Value;
  final bool isDark;

  _OrbPainter({
    required this.orb1Value,
    required this.orb2Value,
    required this.orb3Value,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final baseOpacity = isDark ? 0.06 : 0.04;

    // Orb 1 - top left
    final orb1X = size.width * 0.1 + size.width * 0.2 * orb1Value;
    final orb1Y = size.height * 0.05 + size.height * 0.1 * orb1Value;
    _drawOrb(canvas, Offset(orb1X, orb1Y), size.width * 0.5,
        isDark ? Colors.white.withOpacity(baseOpacity) : Colors.black.withOpacity(baseOpacity));

    // Orb 2 - bottom right
    final orb2X = size.width * 0.7 + size.width * 0.15 * math.sin(orb2Value * math.pi);
    final orb2Y = size.height * 0.6 + size.height * 0.1 * orb2Value;
    _drawOrb(canvas, Offset(orb2X, orb2Y), size.width * 0.45,
        isDark ? Colors.white.withOpacity(baseOpacity * 0.8) : Colors.black.withOpacity(baseOpacity * 0.8));

    // Orb 3 - center
    final orb3X = size.width * 0.4 + size.width * 0.1 * math.cos(orb3Value * math.pi);
    final orb3Y = size.height * 0.4 + size.height * 0.08 * orb3Value;
    _drawOrb(canvas, Offset(orb3X, orb3Y), size.width * 0.35,
        isDark ? Colors.white.withOpacity(baseOpacity * 0.5) : Colors.black.withOpacity(baseOpacity * 0.5));
  }

  void _drawOrb(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, color.withOpacity(0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_OrbPainter oldDelegate) =>
      oldDelegate.orb1Value != orb1Value ||
      oldDelegate.orb2Value != orb2Value ||
      oldDelegate.orb3Value != orb3Value;
}

class _GridPainter extends CustomPainter {
  final bool isDark;

  _GridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.03)
      ..strokeWidth = 0.5;

    const spacing = 40.0;

    // Vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    // Horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.isDark != isDark;
}
