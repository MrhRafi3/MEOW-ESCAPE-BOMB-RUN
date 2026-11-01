import 'dart:async';
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

  // TIMERS & POWER-UPS
  Timer? gameLoop;
  Timer? spawner;
  bool shieldActive = false;
  bool slowActive = false;
  Timer? shieldTimer;
  Timer? slowTimer;
  DateTime? shieldEndTime;
  DateTime? slowEndTime;
  Duration shieldRemaining = Duration.zero;
  Duration slowRemaining = Duration.zero;

  // Pause & countdown
  bool isPaused = false;
  int countdown = 0;
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
    if (!mounted) return;
    setState(() {
      isSoundOn = prefs.getBool('isSoundOn') ?? true;
      GameSounds.setSoundEnabled(isSoundOn);
    });
  }

  Future<void> loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
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
    gameLoop?.cancel();
    spawner?.cancel();

    gameLoop = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      updateObjects();
      checkCollision();
    });

    spawner = Timer.periodic(
        Duration(milliseconds: Constants.spawnInterval.toInt()), (_) {
      spawnObject();
    });
  }

  void spawnObject() {
    if (!mounted || isPaused || countdown > 0) return;
    final width = MediaQuery.of(context).size.width;
    objects.add(FallingObject.random(width, baseSpeed));
  }

  void updateObjects() {
    if (!mounted || isPaused || countdown > 0) return;

    setState(() {
      for (var obj in objects) {
        obj.y += obj.speed;
      }

      final screenHeight = MediaQuery.of(context).size.height;
      objects.removeWhere((obj) {
        if (obj.y > screenHeight) {
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
    shieldRemaining = const Duration(seconds: 5);
    shieldEndTime = DateTime.now().add(shieldRemaining);
    shieldTimer = Timer(shieldRemaining, () {
      if (!mounted) return;
      setState(() {
        shieldActive = false;
      });
    });
  }

  void activateSlowMotion() {
    if (isSoundOn) GameSounds.slow();
    setState(() {
      if (!slowActive) {
        slowActive = true;
        baseSpeed /= 2;
        for (var obj in objects) {
          obj.speed /= 2;
        }
      }
    });

    slowTimer?.cancel();
    slowRemaining = const Duration(seconds: 5);
    slowEndTime = DateTime.now().add(slowRemaining);
    slowTimer = Timer(slowRemaining, () {
      if (!mounted) return;
      setState(() {
        if (slowActive) {
          slowActive = false;
          baseSpeed *= 2;
          for (var obj in objects) {
            obj.speed *= 2;
          }
        }
      });
    });
  }

  // COLLISION
  void checkCollision() {
    if (!mounted || isPaused || countdown > 0) return;

    final playerTop =
        MediaQuery.of(context).size.height - Constants.playerSize - 20;

    for (var obj in objects) {
      if (isColliding(
        player.x,
        playerTop,
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
            playNextHitSound();

            setState(() {
              lives--;
            });

            if (lives <= 0) {
              gameLoop?.cancel();
              spawner?.cancel();
              shieldTimer?.cancel();
              slowTimer?.cancel();
              countdownTimer?.cancel();
              saveHighScore();

              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => GameOverPage(score: score),
                ),
              );
              return;
            }
          }
        }

        objects.remove(obj);
        break;
      }
    }
  }

  // MOVEMENT WITH BOUNDARY CLAMPING
  void movePlayer(bool left) {
    if (!mounted) return;
    final screenWidth = MediaQuery.of(context).size.width;
    final maxRight = (screenWidth - Constants.playerSize).clamp(0.0, double.infinity);

    setState(() {
      if (left) {
        player.x = (moveLeft(player.x, Constants.playerSpeed)).clamp(0.0, maxRight);
      } else {
        player.x = (moveRight(player.x, Constants.playerSpeed)).clamp(0.0, maxRight);
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

    // Preserve remaining power-up durations
    if (shieldActive && shieldEndTime != null) {
      shieldRemaining = shieldEndTime!.difference(DateTime.now());
      shieldTimer?.cancel();
      if (shieldRemaining.isNegative) shieldRemaining = Duration.zero;
    }
    if (slowActive && slowEndTime != null) {
      slowRemaining = slowEndTime!.difference(DateTime.now());
      slowTimer?.cancel();
      if (slowRemaining.isNegative) slowRemaining = Duration.zero;
    }

    showPauseMenu();
  }

  void resumeGame() {
    setState(() {
      isPaused = false;
      countdown = 0;
    });

    // Resume remaining power-up durations
    if (shieldActive && shieldRemaining > Duration.zero) {
      shieldEndTime = DateTime.now().add(shieldRemaining);
      shieldTimer = Timer(shieldRemaining, () {
        if (!mounted) return;
        setState(() {
          shieldActive = false;
        });
      });
    }
    if (slowActive && slowRemaining > Duration.zero) {
      slowEndTime = DateTime.now().add(slowRemaining);
      slowTimer = Timer(slowRemaining, () {
        if (!mounted) return;
        setState(() {
          if (slowActive) {
            slowActive = false;
            baseSpeed *= 2;
            for (var obj in objects) {
              obj.speed *= 2;
            }
          }
        });
      });
    }

    startGame();
  }

  void startCountdown() {
    setState(() {
      countdown = 3;
    });
    countdownTimer?.cancel();

    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
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
      countdown = 0;
      hitCounter = 0;
      player.x = 150;
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
          style: TextStyle(color: Colors.white, fontSize: 28),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Pop the dialog
                startCountdown();       // Resume after countdown
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
                restartGame();
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
        if (isPaused || countdown > 0) return;
        var mid = MediaQuery.of(context).size.width / 2;
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
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(Icons.favorite, color: Colors.red),
                    )),
              ),
            ),

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

            if (countdown > 0)
              Center(
                child: Text(
                  "$countdown",
                  style: const TextStyle(
                    fontSize: 80,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(blurRadius: 5, color: Colors.black)
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
