import 'package:audioplayers/audioplayers.dart';

class GameSounds {
  GameSounds._();

  static bool isSoundOn = true;
  static AudioPlayer? _sfxPlayer;

  static AudioPlayer get _player {
    _sfxPlayer ??= AudioPlayer();
    return _sfxPlayer!;
  }

  static void setSoundEnabled(bool enabled) {
    isSoundOn = enabled;
  }

  static Future<void> _play(String assetPath) async {
    if (!isSoundOn) return;

    try {
      final player = _player;
      await player.stop();
      await player.play(AssetSource(assetPath));
    } catch (_) {}
  }

  // HIT sounds
  static Future<void> hit1() => _play('sounds/hit1.mp3');
  static Future<void> hit2() => _play('sounds/hit2.mp3');
  static Future<void> hit3() => _play('sounds/hit3.mp3');

  // Power-ups
  static Future<void> shield() => _play('sounds/shield.mp3');
  static Future<void> slow() => _play('sounds/slow.mp3');

  // Score sound (verified asset location: assets/sfx/point.wav)
  static Future<void> score() => _play('sfx/point.wav');

  static void dispose() {
    _sfxPlayer?.dispose();
    _sfxPlayer = null;
  }
}
