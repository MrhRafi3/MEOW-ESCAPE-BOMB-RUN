import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/sounds.dart';
import '../services/game_preferences.dart';
import '../widgets/shooting_star_widget.dart';
import 'game_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  int _highScore = 0;
  bool _isSoundOn = true;

  @override
  void initState() {
    super.initState();
    _loadState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _loadState() {
    setState(() {
      _highScore = GamePreferences.getHighScore();
      _isSoundOn = GamePreferences.isSoundEnabled();
    });
  }

  Future<void> _toggleSound() async {
    final nextState = !_isSoundOn;
    await GamePreferences.setSoundEnabled(nextState);
    if (!mounted) return;
    setState(() => _isSoundOn = nextState);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Stack(
        children: [
          const ShootingStarWidget(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  // Top Bar: Sound Quick Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: _toggleSound,
                        icon: Icon(
                          _isSoundOn ? Icons.volume_up : Icons.volume_off,
                          color: _isSoundOn
                              ? AppTheme.neonGreen
                              : Colors.white38,
                          size: 28,
                        ),
                        tooltip: _isSoundOn ? "Mute Sound" : "Enable Sound",
                      ),
                    ],
                  ),

                  const Spacer(flex: 1),

                  // Game Title Banner
                  const Text(
                    "MEOW ESCAPE",
                    style: AppTheme.arcadeTitle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.neonOrange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.neonOrange,
                        width: 1.5,
                      ),
                    ),
                    child: const Text(
                      "⚡ BOMB RUN ⚡",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.5,
                        color: AppTheme.neonOrange,
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Mascot Avatar with Gentle Floating Animation
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.neonCyan.withValues(alpha: 0.35),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/player.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // High Score Pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.neonGold.withValues(alpha: 0.6),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.emoji_events,
                            color: AppTheme.neonGold, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "BEST SCORE: $_highScore",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Actions
                  ArcadeButton(
                    label: "START GAME",
                    icon: Icons.play_arrow_rounded,
                    primaryColor: AppTheme.neonGreen,
                    textColor: Colors.black,
                    onPressed: () async {
                      GameSounds.hit1();
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const GamePage()),
                      );
                      if (mounted) _loadState();
                    },
                  ),

                  const SizedBox(height: 16),

                  ArcadeButton(
                    label: "SETTINGS",
                    icon: Icons.settings_rounded,
                    primaryColor: AppTheme.surfaceDark,
                    textColor: Colors.white,
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsPage()),
                      );
                      if (mounted) _loadState();
                    },
                  ),

                  const Spacer(flex: 1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
