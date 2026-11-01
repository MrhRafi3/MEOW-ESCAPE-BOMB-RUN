import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/game_page.dart';
import 'pages/settings_page.dart';
import 'services/game_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GamePreferences.init();
  runApp(const AvoidGame());
}

class AvoidGame extends StatelessWidget {
  const AvoidGame({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Meow Escape: Bomb Run",
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/game': (context) => const GamePage(),
        '/settings': (context) => const SettingsPage(),
      },
    );
  }
}
