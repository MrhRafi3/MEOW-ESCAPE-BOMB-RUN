import 'package:flutter/material.dart';
import 'shooting_star.dart';

class ShootingStarPainter extends CustomPainter {
  final List<ShootingStar> stars;

  ShootingStarPainter(this.stars);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;

    for (var star in stars) {
      canvas.drawLine(
        Offset(star.x, star.y),
        Offset(star.x + star.length, star.y - star.length / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ShootingStarPainter oldDelegate) => true;
}