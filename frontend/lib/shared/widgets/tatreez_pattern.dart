import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/constants/app_colors.dart';

class TatreezPattern extends StatelessWidget {
  final double size;
  final Color? color;
  final double opacity;

  const TatreezPattern({
    super.key,
    this.size = 100.0,
    this.color,
    this.opacity = 0.1,
  });

  @override
  Widget build(BuildContext context) {
    final patternColor = color ?? AppColors.primary;
    
    return CustomPaint(
      size: Size(size, size),
      painter: TatreezPainter(
        color: patternColor,
        opacity: opacity,
      ),
    );
  }
}

class TatreezPainter extends CustomPainter {
  final Color color;
  final double opacity;

  TatreezPainter({
    required this.color,
    this.opacity = 0.1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: opacity * 0.3)
      ..style = PaintingStyle.fill;

    // Traditional Palestinian tatreez pattern - geometric design
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width / 4;

    // Draw central diamond pattern
    final diamondPath = Path();
    diamondPath.moveTo(centerX, centerY - radius);
    diamondPath.lineTo(centerX + radius, centerY);
    diamondPath.lineTo(centerX, centerY + radius);
    diamondPath.lineTo(centerX - radius, centerY);
    diamondPath.close();
    
    canvas.drawPath(diamondPath, paint);

    // Draw inner diamond
    final innerRadius = radius * 0.6;
    final innerDiamondPath = Path();
    innerDiamondPath.moveTo(centerX, centerY - innerRadius);
    innerDiamondPath.lineTo(centerX + innerRadius, centerY);
    innerDiamondPath.lineTo(centerX, centerY + innerRadius);
    innerDiamondPath.lineTo(centerX - innerRadius, centerY);
    innerDiamondPath.close();
    
    canvas.drawPath(innerDiamondPath, fillPaint);

    // Draw corner triangles
    final triangleSize = radius * 0.4;
    
    // Top-left triangle
    final topLeftPath = Path();
    topLeftPath.moveTo(centerX - radius, centerY - radius);
    topLeftPath.lineTo(centerX - radius + triangleSize, centerY - radius);
    topLeftPath.lineTo(centerX - radius, centerY - radius + triangleSize);
    topLeftPath.close();
    canvas.drawPath(topLeftPath, paint);

    // Top-right triangle
    final topRightPath = Path();
    topRightPath.moveTo(centerX + radius, centerY - radius);
    topRightPath.lineTo(centerX + radius - triangleSize, centerY - radius);
    topRightPath.lineTo(centerX + radius, centerY - radius + triangleSize);
    topRightPath.close();
    canvas.drawPath(topRightPath, paint);

    // Bottom-left triangle
    final bottomLeftPath = Path();
    bottomLeftPath.moveTo(centerX - radius, centerY + radius);
    bottomLeftPath.lineTo(centerX - radius + triangleSize, centerY + radius);
    bottomLeftPath.lineTo(centerX - radius, centerY + radius - triangleSize);
    bottomLeftPath.close();
    canvas.drawPath(bottomLeftPath, paint);

    // Bottom-right triangle
    final bottomRightPath = Path();
    bottomRightPath.moveTo(centerX + radius, centerY + radius);
    bottomRightPath.lineTo(centerX + radius - triangleSize, centerY + radius);
    bottomRightPath.lineTo(centerX + radius, centerY + radius - triangleSize);
    bottomRightPath.close();
    canvas.drawPath(bottomRightPath, paint);

    // Draw connecting lines
    canvas.drawLine(
      Offset(centerX - radius, centerY),
      Offset(centerX + radius, centerY),
      paint,
    );
    canvas.drawLine(
      Offset(centerX, centerY - radius),
      Offset(centerX, centerY + radius),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Alternative tatreez pattern - more complex geometric design
class ComplexTatreezPattern extends StatelessWidget {
  final double size;
  final Color? color;
  final double opacity;

  const ComplexTatreezPattern({
    super.key,
    this.size = 100.0,
    this.color,
    this.opacity = 0.1,
  });

  @override
  Widget build(BuildContext context) {
    final patternColor = color ?? AppColors.primary;
    
    return CustomPaint(
      size: Size(size, size),
      painter: ComplexTatreezPainter(
        color: patternColor,
        opacity: opacity,
      ),
    );
  }
}

class ComplexTatreezPainter extends CustomPainter {
  final Color color;
  final double opacity;

  ComplexTatreezPainter({
    required this.color,
    this.opacity = 0.1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: opacity * 0.2)
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width / 3;

    // Draw octagon pattern
    final octagonPath = Path();
    for (int i = 0; i < 8; i++) {
      final angle = i * (3.14159 / 4);
      final x = centerX + radius * math.cos(angle);
      final y = centerY + radius * math.sin(angle);
      
      if (i == 0) {
        octagonPath.moveTo(x, y);
      } else {
        octagonPath.lineTo(x, y);
      }
    }
    octagonPath.close();
    canvas.drawPath(octagonPath, paint);

    // Draw inner star pattern
    final innerRadius = radius * 0.6;
    final starPath = Path();
    for (int i = 0; i < 10; i++) {
      final angle = i * (3.14159 / 5);
      final currentRadius = i % 2 == 0 ? innerRadius : innerRadius * 0.5;
      final x = centerX + currentRadius * math.cos(angle);
      final y = centerY + currentRadius * math.sin(angle);
      
      if (i == 0) {
        starPath.moveTo(x, y);
      } else {
        starPath.lineTo(x, y);
      }
    }
    starPath.close();
    canvas.drawPath(starPath, fillPaint);

    // Draw corner decorations
    final cornerSize = radius * 0.3;
    for (int i = 0; i < 4; i++) {
      final angle = i * (3.14159 / 2);
      final x = centerX + radius * math.cos(angle);
      final y = centerY + radius * math.sin(angle);
      
      final cornerPath = Path();
      cornerPath.moveTo(x, y);
      cornerPath.lineTo(x + cornerSize * math.cos(angle + 0.785), y + cornerSize * math.sin(angle + 0.785));
      cornerPath.lineTo(x + cornerSize * math.cos(angle - 0.785), y + cornerSize * math.sin(angle - 0.785));
      cornerPath.close();
      canvas.drawPath(cornerPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Helper function for math operations
double cos(double angle) => math.cos(angle);
double sin(double angle) => math.sin(angle); 