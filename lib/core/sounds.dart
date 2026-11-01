import 'package:audioplayers/audioplayers.dart';

class GameSounds {
  GameSounds._();

  static bool isSoundOn = true;

  static Future<void> _play(String assetPath) async {
    if (!isSoundOn) return;

    try {
      final player = AudioPlayer();
      await player.play(AssetSource(assetPath));

      Future.delayed(const Duration(seconds: 3), () {
        player.dispose();
      });
    } catch (_) {}
  }

  // HIT sounds
  static Future<void> hit1() => _play('sounds/hit1.mp3');
  static Future<void> hit2() => _play('sounds/hit2.mp3');
  static Future<void> hit3() => _play('sounds/hit3.mp3');

  // Power-ups
  static Future<void> shield() => _play('sounds/shield.mp3');
  static Future<void> slow() => _play('sounds/slow.mp3');

  // Score sound
  static Future<void> score() => _play('sounds/point.mp3');
}