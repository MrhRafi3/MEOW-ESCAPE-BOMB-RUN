import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_theme.dart';
import '../services/game_preferences.dart';
import '../widgets/shooting_star_widget.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with TickerProviderStateMixin {
  int highScore = 0;
  bool isSoundOn = true;
  bool isMusicOn = true;

  final TextEditingController feedbackController = TextEditingController();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    loadSettings();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _fadeController.forward();
  }

  void loadSettings() {
    setState(() {
      highScore = GamePreferences.getHighScore();
      isSoundOn = GamePreferences.isSoundEnabled();
      isMusicOn = GamePreferences.isMusicEnabled();
    });
  }

  Future<void> confirmResetHighScore() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.cardBorder),
        ),
        title: const Text(
          "Reset High Score?",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Are you sure you want to reset your high score to 0? This cannot be undone.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("CANCEL", style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.neonRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("RESET"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await GamePreferences.resetHighScore();
      if (!mounted) return;
      setState(() {
        highScore = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("High Score Reset!")),
      );
    }
  }

  void submitFeedback() {
    final feedback = feedbackController.text.trim();
    if (feedback.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your feedback.")),
      );
      return;
    }
    feedbackController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Thank you for your feedback!")),
    );
  }

  @override
  void dispose() {
    feedbackController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Settings",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        backgroundColor: AppTheme.bgDark,
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: AppTheme.bgDark,
      body: Stack(
        children: [
          const ShootingStarWidget(),
          FadeTransition(
            opacity: _fadeAnimation,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              children: [
                // High Score Card
                Material(
                  color: AppTheme.surfaceDark.withValues(alpha: 0.9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: const BorderSide(color: AppTheme.cardBorder),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.neonGold.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.emoji_events,
                              color: AppTheme.neonGold, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "High Score",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "$highScore",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded,
                              color: Colors.white60),
                          onPressed: confirmResetHighScore,
                          tooltip: "Reset High Score",
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Audio Settings Card
                Material(
                  color: AppTheme.surfaceDark.withValues(alpha: 0.9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: const BorderSide(color: AppTheme.cardBorder),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SwitchListTile(
                    activeThumbColor: AppTheme.neonGreen,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    secondary: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.neonGreen.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSoundOn ? Icons.volume_up : Icons.volume_off,
                        color: isSoundOn
                            ? AppTheme.neonGreen
                            : Colors.white38,
                        size: 22,
                      ),
                    ),
                    title: const Text(
                      "Game Sound",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: const Text(
                      "Sound effects during gameplay",
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    value: isSoundOn,
                    onChanged: (val) async {
                      await GamePreferences.setSoundEnabled(val);
                      if (!mounted) return;
                      setState(() => isSoundOn = val);
                    },
                  ),
                ),

                const SizedBox(height: 14),

                // Feedback Card
                Material(
                  color: AppTheme.surfaceDark.withValues(alpha: 0.9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: const BorderSide(color: AppTheme.cardBorder),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Feedback",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: feedbackController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "Enter your feedback or suggestions",
                            hintStyle:
                                const TextStyle(color: Colors.white38, fontSize: 14),
                            filled: true,
                            fillColor: AppTheme.bgDark.withValues(alpha: 0.8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: AppTheme.cardBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: AppTheme.cardBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: AppTheme.neonCyan),
                            ),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: submitFeedback,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.neonGreen,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Submit Feedback",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Contact Card
                Material(
                  color: AppTheme.surfaceDark.withValues(alpha: 0.9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: const BorderSide(color: AppTheme.cardBorder),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final Uri emailLaunchUri = Uri(
                        scheme: 'mailto',
                        path: 'mrhrafi99@gmail.com',
                        query: 'subject=Feedback on Meow Escape: Bomb Run',
                      );

                      final canLaunch = await canLaunchUrl(emailLaunchUri);
                      if (canLaunch) {
                        await launchUrl(emailLaunchUri);
                      } else {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text("Could not open email client."),
                          ),
                        );
                      }
                    },
                    child: const ListTile(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Icon(Icons.email_outlined,
                          color: AppTheme.neonCyan, size: 24),
                      title: Text(
                        "Contact Developer",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        "mrhrafi99@gmail.com",
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                      trailing: Icon(Icons.chevron_right_rounded,
                          color: Colors.white38),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // About Card
                Material(
                  color: AppTheme.surfaceDark.withValues(alpha: 0.9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: const BorderSide(color: AppTheme.cardBorder),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: const Icon(Icons.info_outline_rounded,
                        color: AppTheme.neonCyan, size: 24),
                    title: const Text(
                      "About",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: const Text(
                      "Meow Escape: Bomb Run v1.0",
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: Colors.white38),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: AppTheme.cardDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: const BorderSide(color: AppTheme.cardBorder),
                          ),
                          title: const Text(
                            "About Meow Escape",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          content: const Text(
                            "Meow Escape: Bomb Run\nVersion 1.0\n\nA retro-modern mobile arcade experience.\nDeveloped with Flutter by Mrh Rafi 😎",
                            style: TextStyle(color: Colors.white70, height: 1.4),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                "CLOSE",
                                style: TextStyle(color: AppTheme.neonCyan),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Profile Logo & Author Name
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.neonCyan.withValues(alpha: 0.6),
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/my_logo.gif',
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Developed by Mrh Rafi",
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
