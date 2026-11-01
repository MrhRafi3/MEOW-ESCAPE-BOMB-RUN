import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'shooting_star.dart';
import 'shooting_star_painter.dart';

class ShootingStarWidget extends StatefulWidget {
  final int starCount;
  final double maxSpeed;

  const ShootingStarWidget({super.key, this.starCount = 50, this.maxSpeed = 3});

  @override
  State<ShootingStarWidget> createState() => _ShootingStarWidgetState();
}

class _ShootingStarWidgetState extends State<ShootingStarWidget> {
  final List<ShootingStar> stars = [];
  late Timer timer;
  final Random random = Random();

  @override
  void initState() {
    super.initState();

    // Initialize stars with random positions, length, and speed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;

      for (int i = 0; i < widget.starCount; i++) {
        stars.add(ShootingStar(
          x: random.nextDouble() * screenWidth,
          y: random.nextDouble() * screenHeight,
          length: 5 + random.nextDouble() * 10,
          speed: 0.5 + random.nextDouble() * widget.maxSpeed,
        ));
      }

      // Start animation loop
      timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
        setState(() {
          for (var star in stars) {
            star.update(screenWidth, screenHeight);
          }
        });
      });
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ShootingStarPainter(stars),
      child: Container(),
    );
  }
}