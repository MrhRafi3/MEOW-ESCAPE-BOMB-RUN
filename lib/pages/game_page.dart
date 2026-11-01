import 'dart:async';
import 'package:flutter/material.dart';
import '../controllers/game_controller.dart';
import '../core/constants.dart';
import '../widgets/object_widget.dart';
import '../widgets/player_widget.dart';
import '../widgets/score_text.dart';
import 'game_over_page.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late final GameController _controller;
  Timer? _gameLoop;
  Timer? _spawner;

  @override
  void initState() {
    super.initState();
    _controller = GameController();
    _controller.onGameOver = _handleGameOver;

    _startGameLoops();
  }

  void _startGameLoops() {
    _gameLoop?.cancel();
    _spawner?.cancel();

    _gameLoop = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!mounted) return;
      final size = MediaQuery.of(context).size;
      _controller.updateWorld(size.width, size.height);
    });

    _spawner = Timer.periodic(
      Duration(milliseconds: Constants.spawnInterval.toInt()),
      (_) {
        if (!mounted) return;
        final size = MediaQuery.of(context).size;
        _controller.spawnObject(size.width);
      },
    );
  }

  void _handleGameOver() {
    if (!mounted) return;
    _gameLoop?.cancel();
    _spawner?.cancel();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GameOverPage(score: _controller.score),
      ),
    );
  }

  void _pauseGame() {
    _controller.pause();
    _gameLoop?.cancel();
    _spawner?.cancel();
    _showPauseMenu();
  }

  void _resumeAfterCountdown() {
    _controller.startCountdown(() {
      if (!mounted) return;
      _startGameLoops();
    });
  }

  void _restartGame() {
    final size = MediaQuery.of(context).size;
    _controller.restart(size.width);
    _resumeAfterCountdown();
  }

  void _showPauseMenu() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Text(
          "PAUSED",
          style: TextStyle(color: Colors.white, fontSize: 28),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _resumeAfterCountdown();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                foregroundColor: Colors.black,
              ),
              child: const Text("RESUME"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _restartGame();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.black,
              ),
              child: const Text("RESTART"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text("HOME"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _gameLoop?.cancel();
    _spawner?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final screenWidth = MediaQuery.of(context).size.width;

        return GestureDetector(
          onTapDown: (d) {
            _controller.movePlayer(
              d.localPosition.dx < (screenWidth / 2),
              screenWidth,
            );
          },
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                ..._controller.objects.map(
                  (o) => ObjectWidget(x: o.x, y: o.y, type: o.type),
                ),

                PlayerWidget(x: _controller.player.x),
                ScoreText(score: _controller.score),

                Positioned(
                  top: 40,
                  right: 20,
                  child: Row(
                    children: List.generate(
                      _controller.lives,
                      (index) => const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(Icons.favorite, color: Colors.red),
                      ),
                    ),
                  ),
                ),

                if (_controller.shieldActive)
                  const Positioned(
                    top: 80,
                    left: 20,
                    child: Icon(
                      Icons.shield,
                      color: Colors.blueAccent,
                      size: 32,
                    ),
                  ),

                if (_controller.slowActive)
                  const Positioned(
                    top: 80,
                    left: 60,
                    child: Icon(
                      Icons.slow_motion_video,
                      color: Colors.greenAccent,
                      size: 32,
                    ),
                  ),

                Positioned(
                  top: 70,
                  right: 20,
                  child: IconButton(
                    icon: const Icon(
                      Icons.pause_circle_filled,
                      color: Colors.white,
                      size: 36,
                    ),
                    onPressed: _pauseGame,
                  ),
                ),

                if (_controller.countdown > 0)
                  Center(
                    child: Text(
                      "${_controller.countdown}",
                      style: const TextStyle(
                        fontSize: 80,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(blurRadius: 5, color: Colors.black),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
