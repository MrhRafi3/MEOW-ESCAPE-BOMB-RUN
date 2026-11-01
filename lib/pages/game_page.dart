import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../controllers/game_controller.dart';
import '../core/app_theme.dart';
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

  static const double _maxPlayfieldWidth = 480.0;

  @override
  void initState() {
    super.initState();
    _controller = GameController();
    _controller.onGameOver = _handleGameOver;

    _startGameLoops();
  }

  double _getPlayfieldWidth(double screenWidth) {
    return min(screenWidth, _maxPlayfieldWidth);
  }

  double _getPlayerBottom(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return bottomInset + 20.0;
  }

  void _startGameLoops() {
    _gameLoop?.cancel();
    _spawner?.cancel();

    _gameLoop = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!mounted) return;
      final size = MediaQuery.of(context).size;
      final playfieldWidth = _getPlayfieldWidth(size.width);
      final playerBottom = _getPlayerBottom(context);

      _controller.updateWorld(
        playfieldWidth,
        size.height,
        bottomOffset: playerBottom,
      );
    });

    _spawner = Timer.periodic(
      Duration(milliseconds: Constants.spawnInterval.toInt()),
      (_) {
        if (!mounted) return;
        final size = MediaQuery.of(context).size;
        final playfieldWidth = _getPlayfieldWidth(size.width);
        _controller.spawnObject(playfieldWidth);
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
    final playfieldWidth = _getPlayfieldWidth(size.width);
    _controller.restart(playfieldWidth);
    _resumeAfterCountdown();
  }

  void _showPauseMenu() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.cardDark.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.neonCyan.withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.neonCyan.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "GAME PAUSED",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: AppTheme.neonCyan,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ArcadeButton(
                  label: "RESUME",
                  icon: Icons.play_arrow_rounded,
                  primaryColor: AppTheme.neonGreen,
                  textColor: Colors.black,
                  width: double.infinity,
                  onPressed: () {
                    Navigator.pop(context);
                    _resumeAfterCountdown();
                  },
                ),
                const SizedBox(height: 12),
                ArcadeButton(
                  label: "RESTART",
                  icon: Icons.replay_rounded,
                  primaryColor: AppTheme.neonOrange,
                  textColor: Colors.black,
                  width: double.infinity,
                  onPressed: () {
                    Navigator.pop(context);
                    _restartGame();
                  },
                ),
                const SizedBox(height: 12),
                ArcadeButton(
                  label: "HOME",
                  icon: Icons.home_rounded,
                  primaryColor: AppTheme.surfaceDark,
                  textColor: Colors.white,
                  width: double.infinity,
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
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
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final playfieldWidth = _getPlayfieldWidth(screenWidth);
    final isPillarboxed = screenWidth > _maxPlayfieldWidth;
    final playerBottom = _getPlayerBottom(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SizedBox(
          width: playfieldWidth,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Container(
                decoration: BoxDecoration(
                  color: AppTheme.bgDark,
                  border: isPillarboxed
                      ? const Border.symmetric(
                          vertical: BorderSide(
                            color: AppTheme.cardBorder,
                            width: 2,
                          ),
                        )
                      : null,
                ),
                child: Stack(
                  children: [
                    // Interactive touch layer for player movement
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (details) {
                          _controller.movePlayer(
                            details.localPosition.dx < (playfieldWidth / 2),
                            playfieldWidth,
                          );
                        },
                        onHorizontalDragUpdate: (details) {
                          _controller.movePlayerByDelta(
                            details.delta.dx,
                            playfieldWidth,
                          );
                        },
                      ),
                    ),

                    // Falling Hazards and Power-Ups
                    ..._controller.objects.map(
                      (o) => ObjectWidget(x: o.x, y: o.y, type: o.type),
                    ),

                    // Player Cat positioned above home indicator
                    PlayerWidget(
                      x: _controller.player.x,
                      bottom: playerBottom,
                    ),

                    // Safe-Area Protected In-Game HUD
                    Align(
                      alignment: Alignment.topCenter,
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  // Score Badge
                                  ScoreText(score: _controller.score),

                                  const Spacer(),

                                  // Fixed 3-Heart Container
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceDark
                                          .withValues(alpha: 0.85),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: AppTheme.cardBorder,
                                        width: 1.2,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: List.generate(3, (index) {
                                        final isFull =
                                            index < _controller.lives;
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 2),
                                          child: Icon(
                                            isFull
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            color: isFull
                                                ? AppTheme.neonRed
                                                : Colors.white24,
                                            size: 20,
                                          ),
                                        );
                                      }),
                                    ),
                                  ),

                                  const SizedBox(width: 10),

                                  // Pause Button (Isolated from touch movement)
                                  InkWell(
                                    onTap: _pauseGame,
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceDark
                                            .withValues(alpha: 0.85),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppTheme.cardBorder,
                                          width: 1.2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.pause_rounded,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              // Active Buff Status Indicators
                              Row(
                                children: [
                                  if (_controller.shieldActive)
                                    Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.neonCyan
                                            .withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppTheme.neonCyan,
                                          width: 1.2,
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.shield_rounded,
                                              color: AppTheme.neonCyan,
                                              size: 16),
                                          SizedBox(width: 4),
                                          Text(
                                            "SHIELD ACTIVE",
                                            style: TextStyle(
                                              color: AppTheme.neonCyan,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1.1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (_controller.slowActive)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.neonGreen
                                            .withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppTheme.neonGreen,
                                          width: 1.2,
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.slow_motion_video_rounded,
                                              color: AppTheme.neonGreen,
                                              size: 16),
                                          SizedBox(width: 4),
                                          Text(
                                            "SLOW-MO",
                                            style: TextStyle(
                                              color: AppTheme.neonGreen,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1.1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Countdown Overlay
                    if (_controller.countdown > 0)
                      Center(
                        child: Container(
                          width: 120,
                          height: 120,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.neonCyan,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.neonCyan
                                    .withValues(alpha: 0.4),
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Text(
                            "${_controller.countdown}",
                            style: const TextStyle(
                              fontSize: 64,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
