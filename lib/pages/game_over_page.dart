import 'package:flutter/material.dart';
import 'game_page.dart';
import 'home_page.dart';

class GameOverPage extends StatelessWidget {
  final int score;
  const GameOverPage({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "GAME OVER",
              style: TextStyle(
                color: Colors.red,
                fontSize: 36,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(blurRadius: 4, color: Colors.black, offset: Offset(2, 2))
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Score: $score",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const GamePage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent[700],
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: const Text(
                "PLAY AGAIN",
                style: TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomePage()),
                      (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent, // button color
                foregroundColor: Colors.black,        // text color
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              ),
              child: const Text(
                "HOME",
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}