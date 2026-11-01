import 'package:flutter/material.dart';

class ScoreText extends StatelessWidget {
  final int score;
  const ScoreText({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 40,
      left: 20,
      child: Text(
        "Score: $score",
        style: const TextStyle(
          fontSize: 23,
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(blurRadius: 4, color: Colors.black),
          ],
        ),
      ),
    );
  }
}