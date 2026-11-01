import 'package:shared_preferences/shared_preferences.dart';
import '../core/sounds.dart';

class GamePreferences {
  static const String _keyHighScore = 'highScore';
  static const String _keySound = 'isSoundOn';
  static const String _keyMusic = 'isMusicOn';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    GameSounds.setSoundEnabled(isSoundEnabled());
  }

  static Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  static int getHighScore() {
    return _prefs?.getInt(_keyHighScore) ?? 0;
  }

  static Future<void> saveHighScore(int score) async {
    final prefs = await _getPrefs();
    if (score > getHighScore()) {
      await prefs.setInt(_keyHighScore, score);
    }
  }

  static Future<void> resetHighScore() async {
    final prefs = await _getPrefs();
    await prefs.setInt(_keyHighScore, 0);
  }

  static bool isSoundEnabled() {
    return _prefs?.getBool(_keySound) ?? true;
  }

  static Future<void> setSoundEnabled(bool enabled) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_keySound, enabled);
    GameSounds.setSoundEnabled(enabled);
  }

  static bool isMusicEnabled() {
    return _prefs?.getBool(_keyMusic) ?? true;
  }

  static Future<void> setMusicEnabled(bool enabled) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_keyMusic, enabled);
  }
}
