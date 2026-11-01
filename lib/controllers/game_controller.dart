import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/constants.dart';
import '../core/game_config.dart';
import '../core/sounds.dart';
import '../models/falling_object.dart';
import '../models/player.dart';
import '../services/game_preferences.dart';
import '../utils/collision.dart';
import '../utils/movement.dart';

class GameController extends ChangeNotifier {
  // GAME ENTITIES & STATE
  late PlayerModel player;
  final List<FallingObject> objects = [];
  int score = 0;
  int lives = 3;
  int highScore = 0;
  double baseSpeed = Constants.objectFallSpeed;

  // POWER-UPS
  bool shieldActive = false;
  bool slowActive = false;
  Timer? _shieldTimer;
  Timer? _slowTimer;
  DateTime? _shieldEndTime;
  DateTime? _slowEndTime;
  Duration _shieldRemaining = Duration.zero;
  Duration _slowRemaining = Duration.zero;

  // PAUSE & COUNTDOWN
  bool isPaused = false;
  int countdown = 0;
  Timer? _countdownTimer;
  bool isGameOver = false;

  // TIMERS
  Timer? _gameLoop;
  Timer? _spawner;

  // HIT CYCLE
  int _hitCounter = 0;

  // CALLBACKS
  VoidCallback? onGameOver;

  GameController({double initialPlayerX = 150}) {
    player = PlayerModel(x: initialPlayerX);
    highScore = GamePreferences.getHighScore();
  }

  void start() {
    _gameLoop?.cancel();
    _spawner?.cancel();

    _gameLoop = Timer.periodic(const Duration(milliseconds: 16), (_) {
      // Loop tick handled in page with current viewport dimensions
    });
  }

  void spawnObject(double screenWidth) {
    if (isPaused || countdown > 0 || isGameOver) return;
    objects.add(FallingObject.random(screenWidth, baseSpeed));
    notifyListeners();
  }

  void updateWorld(double screenWidth, double screenHeight) {
    if (isPaused || countdown > 0 || isGameOver) return;

    for (var obj in objects) {
      obj.y += obj.speed;
    }

    objects.removeWhere((obj) {
      if (obj.y > screenHeight) {
        score++;
        GameSounds.score();
        baseSpeed += GameConfig.difficultyIncreaseRate;
        return true;
      }
      return false;
    });

    _checkCollision(screenWidth, screenHeight);
    notifyListeners();
  }

  void movePlayer(bool left, double screenWidth) {
    if (isPaused || countdown > 0 || isGameOver) return;

    final maxRight =
        (screenWidth - Constants.playerSize).clamp(0.0, double.infinity);

    if (left) {
      player.x =
          (moveLeft(player.x, Constants.playerSpeed)).clamp(0.0, maxRight);
    } else {
      player.x =
          (moveRight(player.x, Constants.playerSpeed)).clamp(0.0, maxRight);
    }

    notifyListeners();
  }

  void _checkCollision(double screenWidth, double screenHeight) {
    final playerTop = screenHeight - Constants.playerSize - 20;

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
            _playNextHitSound();
            lives--;

            if (lives <= 0) {
              _triggerGameOver();
              objects.remove(obj);
              notifyListeners();
              return;
            }
          }
        }

        objects.remove(obj);
        notifyListeners();
        break;
      }
    }
  }

  void _playNextHitSound() {
    _hitCounter++;
    if (_hitCounter == 1) {
      GameSounds.hit1();
    } else if (_hitCounter == 2) {
      GameSounds.hit2();
    } else if (_hitCounter == 3) {
      GameSounds.hit3();
      _hitCounter = 0;
    }
  }

  void activateShield() {
    GameSounds.shield();
    shieldActive = true;
    _shieldTimer?.cancel();
    _shieldRemaining = const Duration(seconds: 5);
    _shieldEndTime = DateTime.now().add(_shieldRemaining);

    _shieldTimer = Timer(_shieldRemaining, () {
      shieldActive = false;
      notifyListeners();
    });

    notifyListeners();
  }

  void activateSlowMotion() {
    GameSounds.slow();

    if (!slowActive) {
      slowActive = true;
      baseSpeed /= 2;
      for (var obj in objects) {
        obj.speed /= 2;
      }
    }

    _slowTimer?.cancel();
    _slowRemaining = const Duration(seconds: 5);
    _slowEndTime = DateTime.now().add(_slowRemaining);

    _slowTimer = Timer(_slowRemaining, () {
      if (slowActive) {
        slowActive = false;
        baseSpeed *= 2;
        for (var obj in objects) {
          obj.speed *= 2;
        }
        notifyListeners();
      }
    });

    notifyListeners();
  }

  void pause() {
    if (isPaused || isGameOver) return;
    isPaused = true;
    _gameLoop?.cancel();
    _spawner?.cancel();

    // Preserve remaining power-up durations
    if (shieldActive && _shieldEndTime != null) {
      _shieldRemaining = _shieldEndTime!.difference(DateTime.now());
      _shieldTimer?.cancel();
      if (_shieldRemaining.isNegative) _shieldRemaining = Duration.zero;
    }

    if (slowActive && _slowEndTime != null) {
      _slowRemaining = _slowEndTime!.difference(DateTime.now());
      _slowTimer?.cancel();
      if (_slowRemaining.isNegative) _slowRemaining = Duration.zero;
    }

    notifyListeners();
  }

  void resume() {
    isPaused = false;
    countdown = 0;

    // Restore active power-ups with remaining durations
    if (shieldActive && _shieldRemaining > Duration.zero) {
      _shieldEndTime = DateTime.now().add(_shieldRemaining);
      _shieldTimer = Timer(_shieldRemaining, () {
        shieldActive = false;
        notifyListeners();
      });
    }

    if (slowActive && _slowRemaining > Duration.zero) {
      _slowEndTime = DateTime.now().add(_slowRemaining);
      _slowTimer = Timer(_slowRemaining, () {
        if (slowActive) {
          slowActive = false;
          baseSpeed *= 2;
          for (var obj in objects) {
            obj.speed *= 2;
          }
          notifyListeners();
        }
      });
    }

    notifyListeners();
  }

  void startCountdown(VoidCallback onCountdownComplete) {
    countdown = 3;
    _countdownTimer?.cancel();
    notifyListeners();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      countdown--;
      notifyListeners();

      if (countdown <= 0) {
        timer.cancel();
        resume();
        onCountdownComplete();
      }
    });
  }

  void restart(double screenWidth) {
    _gameLoop?.cancel();
    _spawner?.cancel();
    _shieldTimer?.cancel();
    _slowTimer?.cancel();
    _countdownTimer?.cancel();

    score = 0;
    lives = 3;
    objects.clear();
    shieldActive = false;
    slowActive = false;
    baseSpeed = Constants.objectFallSpeed;
    isPaused = false;
    countdown = 0;
    _hitCounter = 0;
    isGameOver = false;
    player.x = (screenWidth / 2) - (Constants.playerSize / 2);

    notifyListeners();
  }

  void _triggerGameOver() {
    isGameOver = true;
    _gameLoop?.cancel();
    _spawner?.cancel();
    _shieldTimer?.cancel();
    _slowTimer?.cancel();
    _countdownTimer?.cancel();

    if (score > highScore) {
      highScore = score;
      GamePreferences.saveHighScore(score);
    }

    onGameOver?.call();
  }

  @override
  void dispose() {
    _gameLoop?.cancel();
    _spawner?.cancel();
    _shieldTimer?.cancel();
    _slowTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }
}
