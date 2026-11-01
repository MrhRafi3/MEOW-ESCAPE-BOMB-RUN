import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/sounds.dart';
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
  final TextEditingController contactController = TextEditingController();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    loadHighScore();
    loadSoundAndMusicSettings();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _fadeController.forward();
  }

  // -------------------------
  // Load High Score
  // -------------------------
  Future<void> loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      highScore = prefs.getInt('highScore') ?? 0;
    });
  }

  // -------------------------
  // Load Sound & Music Settings
  // -------------------------
  Future<void> loadSoundAndMusicSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      isSoundOn = prefs.getBool('isSoundOn') ?? true;
      isMusicOn = prefs.getBool('isMusicOn') ?? true;
      GameSounds.setSoundEnabled(isSoundOn);
    });
  }

  // -------------------------
  // Reset High Score
  // -------------------------
  Future<void> resetHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('highScore', 0);
    if (!mounted) return;
    setState(() {
      highScore = 0;
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("High Score Reset!")));
  }

  // -------------------------
  // Submit Feedback
  // -------------------------
  void submitFeedback() {
    final feedback = feedbackController.text.trim();
    if (feedback.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter your feedback.")));
      return;
    }
    feedbackController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Thank you for your feedback!")));
  }

  // -------------------------
  // Submit Contact Info
  // -------------------------
  void submitContact() {
    final contact = contactController.text.trim();
    if (contact.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter your contact info.")));
      return;
    }
    contactController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Contact info received!")));
  }

  @override
  void dispose() {
    feedbackController.dispose();
    contactController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const ShootingStarWidget(), // floating stars behind content
          FadeTransition(
            opacity: _fadeAnimation,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // High Score
                Card(
                  color: Colors.black87,
                  child: ListTile(
                    leading: const Icon(Icons.star, color: Colors.yellow),
                    title: const Text("High Score",
                        style: TextStyle(color: Colors.white)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("$highScore",
                            style: const TextStyle(
                                color: Colors.yellow,
                                fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: resetHighScore,
                          tooltip: "Reset High Score",
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // Sound & Music
                Card(
                  color: Colors.black87,
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text("Game Sound",
                            style: TextStyle(color: Colors.white)),
                        value: isSoundOn,
                        onChanged: (val) async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('isSoundOn', val);
                          GameSounds.setSoundEnabled(val);
                          if (!mounted) return;
                          setState(() => isSoundOn = val);
                        },
                        secondary: const Icon(Icons.volume_up,
                            color: Colors.greenAccent),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),

                // Feedback
                Card(
                  color: Colors.black87,
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Feedback",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: feedbackController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: "Enter your feedback",
                            hintStyle: TextStyle(color: Colors.white54),
                            filled: true,
                            fillColor: Colors.black54,
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: submitFeedback,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.greenAccent,
                              foregroundColor: Colors.black,
                              elevation: 5,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15))),
                          child: const Text("Submit Feedback"),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // Contact
                Card(
                  color: Colors.black87,
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
                              content: Text("Could not open email client.")),
                        );
                      }
                    },
                    child: const ListTile(
                      leading: Icon(Icons.email, color: Colors.greenAccent),
                      title: Text(
                        "Contact",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        "mrhrafi99@gmail.com",
                        style: TextStyle(color: Colors.white70),
                      ),
                      trailing: Icon(Icons.send, color: Colors.greenAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // About
                Card(
                  color: Colors.black87,
                  child: ListTile(
                    leading: const Icon(Icons.info, color: Colors.blueAccent),
                    title: const Text("About",
                        style: TextStyle(color: Colors.white)),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: Colors.black87,
                          title: const Text("About",
                              style: TextStyle(color: Colors.white)),
                          content: const Text(
                            "Meow Escape: Bomb Run \nVersion 1.0\nDeveloped by Mrh Rafi 😎",
                            style: TextStyle(color: Colors.white70),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Close",
                                  style: TextStyle(color: Colors.blueAccent)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Profile Logo & Author Name
                Center(
                  child: Column(
                    children: [
                      ClipOval(
                        child: Image.asset(
                          'assets/images/my_logo.gif',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.95, end: 1.05),
                          duration: const Duration(seconds: 1),
                          curve: Curves.easeInOut,
                          builder: (context, scale, child) {
                            return Transform.scale(
                              scale: scale,
                              child: child,
                            );
                          },
                          child: Text(
                            "Developed by Mrh Rafi",
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1.2,
                              shadows: const [
                                Shadow(
                                  blurRadius: 3,
                                  color: Colors.black,
                                  offset: Offset(1, 1),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
