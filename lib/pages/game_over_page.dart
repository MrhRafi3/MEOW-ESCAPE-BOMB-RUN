import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../services/game_preferences.dart';
import '../widgets/shooting_star_widget.dart';
import 'game_page.dart';
import 'home_page.dart';

class GameOverPage extends StatelessWidget {
  final int score;
  const GameOverPage({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final highScore = GamePreferences.getHighScore();
    final isNewRecord = score >= highScore && score > 0;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Stack(
        children: [
          const ShootingStarWidget(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title
                    const Text(
                      "GAME OVER",
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.5,
                        color: AppTheme.neonRed,
                        shadows: [
                          Shadow(
                            blurRadius: 16,
                            color: AppTheme.neonRed,
                          ),
                          Shadow(
                            blurRadius: 6,
                            color: Colors.black,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    if (isNewRecord)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.neonGold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.neonGold,
                            width: 1.5,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.emoji_events,
                                color: AppTheme.neonGold, size: 20),
                            SizedBox(width: 8),
                            Text(
                              "NEW RECORD!",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.0,
                                color: AppTheme.neonGold,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 28),

                    // Score Summary Card
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 320),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppTheme.cardBorder,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "FINAL SCORE",
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "$score",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const Divider(
                              color: AppTheme.cardBorder, height: 28),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "BEST SCORE",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              Text(
                                "$highScore",
                                style: const TextStyle(
                                  color: AppTheme.neonGold,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Buttons
                    ArcadeButton(
                      label: "PLAY AGAIN",
                      icon: Icons.replay_rounded,
                      primaryColor: AppTheme.neonGreen,
                      textColor: Colors.black,
                      width: 280,
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const GamePage()),
                        );
                      },
                    ),

                    const SizedBox(height: 14),

                    ArcadeButton(
                      label: "HOME",
                      icon: Icons.home_rounded,
                      primaryColor: AppTheme.surfaceDark,
                      textColor: Colors.white,
                      width: 280,
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const HomePage()),
                          (route) => false,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
