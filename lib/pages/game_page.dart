import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../core/game_config.dart';
import '../core/sounds.dart';
import '../models/player.dart';
import '../models/falling_object.dart';
import '../utils/collision.dart';
import '../utils/movement.dart';
import '../widgets/player_widget.dart';
import '../widgets/object_widget.dart';
import '../widgets/score_text.dart';
import 'game_over_page.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  // GAME STATE
  late PlayerModel player;
  List<FallingObject> objects = [];
  int score = 0;
  int lives = 3;
  int highScore = 0;
  double baseSpeed = Constants.objectFallSpeed;

  // TIMERS
  Timer? gameLoop;
  Timer? spawner;
  bool shieldActive = false;
  bool slowActive = false;
  Timer? shieldTimer;
  Timer? slowTimer;

  // Pause & countdown
  bool isPaused = false;
  int countdown = 3;
  Timer? countdownTimer;

  // SOUND
  bool isSoundOn = true;

  // Hit cycle counter
  int hitCounter = 0;

  // Play hit1 → hit2 → hit3 → repeat
  void playNextHitSound() {
    if (!isSoundOn) return;

    hitCounter++;

    if (hitCounter == 1) {
      GameSounds.hit1();
    } else if (hitCounter == 2) {
      GameSounds.hit2();
    } else if (hitCounter == 3) {
      GameSounds.hit3();
      hitCounter = 0; // reset
    }
  }

  @override
  void initState() {
    super.initState();
    player = PlayerModel(x: 150);
    loadHighScore();
    loadSoundSetting();
    startGame();
  }

  Future<void> loadSoundSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isSoundOn = prefs.getBool('isSoundOn') ?? true;
    });
  }

  Future<void> loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      highScore = prefs.getInt('highScore') ?? 0;
    });
  }

  Future<void> saveHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    if (score > highScore) {
      await prefs.setInt('highScore', score);
    }
  }

  // START GAME
  void startGame() {
    gameLoop =
        Timer.periodic(const Duration(milliseconds: 16), (timer) {
          updateObjects();
          checkCollision();
        });

    spawner = Timer.periodic(
        Duration(milliseconds: Constants.spawnInterval.toInt()), (_) {
      spawnObject();
    });
  }

  void spawnObject() {
    final width = MediaQuery.of(context).size.width;
    objects.add(FallingObject.random(width, baseSpeed));
  }

  void updateObjects() {
    if (isPaused) return;

    setState(() {
      for (var obj in objects) {
        obj.y += obj.speed;
      }

      objects.removeWhere((obj) {
        if (obj.y > MediaQuery.of(context).size.height) {
          score++;
          if (isSoundOn) GameSounds.score();
          baseSpeed += GameConfig.difficultyIncreaseRate;
          return true;
        }
        return false;
      });
    });
  }

  // POWER UPS
  void activateShield() {
    if (isSoundOn) GameSounds.shield();
    setState(() {
      shieldActive = true;
    });
    shieldTimer?.cancel();
    shieldTimer = Timer(const Duration(seconds: 5), () {
      setState(() {
        shieldActive = false;
      });
    });
  }

  void activateSlowMotion() {
    if (isSoundOn) GameSounds.slow();
    setState(() {
      slowActive = true;
      baseSpeed /= 2;
    });
    slowTimer?.cancel();
    slowTimer = Timer(const Duration(seconds: 5), () {
      setState(() {
        slowActive = false;
        baseSpeed *= 2;
      });
    });
  }

  // COLLISION
  void checkCollision() {
    for (var obj in objects) {
      if (isColliding(
        player.x,
        MediaQuery.of(context).size.height -
            Constants.playerSize -
            20,
        Constants.playerSize,
        obj.x,
        obj.y,
        Constants.objectSize,
      )) {
        if (obj.type == ObjectType.shield) {
          activateShield();
        } else if (obj.type == ObjectType.slow) {
          activateSlowMotion();
        } else {
          if (!shieldActive) {
            playNextHitSound(); // FIXED HIT SEQUENCE

            setState(() {
              lives--;
            });

            if (lives <= 0) {
              gameLoop?.cancel();
              spawner?.cancel();
              saveHighScore();

              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          GameOverPage(score: score)));
            }
          }
        }

        objects.remove(obj);
        break;
      }
    }
  }

  // MOVEMENT
  void movePlayer(bool left) {
    setState(() {
      if (left) {
        player.x = moveLeft(player.x, Constants.playerSpeed);
      } else {
        player.x =
            moveRight(player.x, Constants.playerSpeed);
      }
    });
  }

  // PAUSE SYSTEM
  void pauseGame() {
    if (isPaused) return;
    setState(() {
      isPaused = true;
    });
    gameLoop?.cancel();
    spawner?.cancel();
    showPauseMenu();
  }

  void resumeGame() {
    setState(() {
      isPaused = false;
    });
    startGame();
  }

  void startCountdown() {
    setState(() {
      countdown = 3;
    });
    countdownTimer?.cancel();

    countdownTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            countdown--;
          });

          if (countdown <= 0) {
            timer.cancel();
            resumeGame();
          }
        });
  }

  void restartGame() {
    gameLoop?.cancel();
    spawner?.cancel();
    shieldTimer?.cancel();
    slowTimer?.cancel();
    countdownTimer?.cancel();

    setState(() {
      score = 0;
      lives = 3;
      objects.clear();
      shieldActive = false;
      slowActive = false;
      baseSpeed = Constants.objectFallSpeed;
      isPaused = false;
      hitCounter = 0; // reset sound cycle
    });

    startCountdown();
  }

  void showPauseMenu() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Text(
          "PAUSED",
          style:
          TextStyle(color: Colors.white, fontSize: 28),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              // *** FIX HERE ***
              onPressed: () {
                Navigator.pop(context); // Only pop the dialog
                startCountdown();       // Resume the game after countdown
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,   // Button color
                foregroundColor: Colors.black,  // Text color
              ),
              child: const Text("RESUME"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              // *** FIX HERE ***
              onPressed: () {
                Navigator.pop(context); // Only pop the dialog
                restartGame();          // Restart the game
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,   // Button color
                foregroundColor: Colors.black,  // Text color
              ),
              child: const Text("RESTART"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Pop the dialog
                Navigator.pop(context); // Pop the GamePage to go home
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,   // Button color
                foregroundColor: Colors.white,  // Text color
              ),
              child: const Text("HOME"),
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    gameLoop?.cancel();
    spawner?.cancel();
    shieldTimer?.cancel();
    slowTimer?.cancel();
    countdownTimer?.cancel();
    super.dispose();
  }

  // UI
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (d) {
        var mid =
            MediaQuery.of(context).size.width / 2;
        movePlayer(d.localPosition.dx < mid);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            ...objects.map((o) => ObjectWidget(
                x: o.x, y: o.y, type: o.type)),

            PlayerWidget(x: player.x),
            ScoreText(score: score),

            Positioned(
              top: 40,
              right: 20,
              child: Row(
                children: List.generate(
                    lives,
                        (index) => const Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 4),
                      child: Icon(Icons.favorite,
                          color: Colors.red),
                    )),
              ),
            ),

            // Positioned(
            //   top: 40,
            //   left: 20,
            //   child: Text(
            //     "High: $highScore",
            //     style: const TextStyle(
            //       fontSize: 22,
            //       color: Colors.yellow,
            //       fontWeight: FontWeight.bold,
            //       shadows: [
            //         Shadow(
            //             blurRadius: 3,
            //             color: Colors.black)
            //       ],
            //     ),
            //   ),
            // ),

            if (shieldActive)
              const Positioned(
                top: 80,
                left: 20,
                child: Icon(Icons.shield,
                    color: Colors.blueAccent,
                    size: 32),
              ),

            if (slowActive)
              const Positioned(
                top: 80,
                left: 60,
                child: Icon(Icons.slow_motion_video,
                    color: Colors.greenAccent,
                    size: 32),
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
                onPressed: pauseGame,
              ),
            ),

            if (isPaused && countdown > 0)
              Center(
                child: Text(
                  "$countdown",
                  style: const TextStyle(
                    fontSize: 80,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                          blurRadius: 5,
                          color: Colors.black)
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