import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bomb_run/main.dart';
import 'package:bomb_run/controllers/game_controller.dart';
import 'package:bomb_run/core/constants.dart';
import 'package:bomb_run/models/falling_object.dart';
import 'package:bomb_run/services/game_preferences.dart';
import 'package:bomb_run/utils/collision.dart';
import 'package:bomb_run/utils/movement.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'highScore': 42,
      'isSoundOn': true,
      'isMusicOn': true,
    });
    await GamePreferences.init();
  });

  testWidgets('AvoidGame boots to HomePage with start and settings buttons',
      (WidgetTester tester) async {
    await tester.pumpWidget(const AvoidGame());
    await tester.pump();

    expect(find.text('START GAME'), findsOneWidget);
    expect(find.text('SETTINGS'), findsOneWidget);
  });

  testWidgets('Tapping SETTINGS navigates to SettingsPage',
      (WidgetTester tester) async {
    await tester.pumpWidget(const AvoidGame());
    await tester.pump();

    await tester.tap(find.text('SETTINGS'));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('High Score'), findsOneWidget);
    expect(find.text('Game Sound'), findsOneWidget);
  });

  test('isColliding correctly identifies overlapping and separated rectangles', () {
    expect(isColliding(100, 500, 60, 120, 520, 40), isTrue);
    expect(isColliding(100, 500, 60, 200, 500, 40), isFalse);
    expect(isColliding(100, 500, 60, 100, 300, 40), isFalse);
    expect(isColliding(100, 500, 60, 160, 500, 40), isFalse);
  });

  test('Movement helper functions update coordinates accurately', () {
    expect(moveLeft(100.0, 20.0), equals(80.0));
    expect(moveRight(100.0, 20.0), equals(120.0));
  });

  test('GameController initializes with correct default values', () {
    final controller = GameController(initialPlayerX: 100);

    expect(controller.player.x, equals(100));
    expect(controller.score, equals(0));
    expect(controller.lives, equals(3));
    expect(controller.highScore, equals(42));
    expect(controller.shieldActive, isFalse);
    expect(controller.slowActive, isFalse);
    expect(controller.isPaused, isFalse);
    expect(controller.isGameOver, isFalse);

    controller.dispose();
  });

  test('GameController clamps player movement strictly to screen boundaries', () {
    final controller = GameController(initialPlayerX: 10);
    const double screenWidth = 400.0;
    const double maxRight = screenWidth - Constants.playerSize;

    // Moving left past 0 clamps to 0
    controller.movePlayer(true, screenWidth);
    expect(controller.player.x, equals(0.0));

    // Moving right to maxRight
    controller.player.x = maxRight - 10;
    controller.movePlayer(false, screenWidth);
    expect(controller.player.x, equals(maxRight));

    // Moving right past maxRight stays clamped at maxRight
    controller.movePlayer(false, screenWidth);
    expect(controller.player.x, equals(maxRight));

    controller.dispose();
  });

  test('GameController updates score and cleans off-screen objects', () {
    final controller = GameController(initialPlayerX: 100);

    // Add object near bottom
    controller.objects.add(
      FallingObject(x: 200, y: 790, speed: 20),
    );

    // Update world with screen height 800 (object falls to 810 -> offscreen)
    controller.updateWorld(400, 800);

    expect(controller.score, equals(1));
    expect(controller.objects, isEmpty);

    controller.dispose();
  });

  test('GameController activates and manages power-ups safely', () {
    final controller = GameController(initialPlayerX: 100);

    controller.activateShield();
    expect(controller.shieldActive, isTrue);

    controller.activateSlowMotion();
    expect(controller.slowActive, isTrue);
    expect(controller.baseSpeed, equals(Constants.objectFallSpeed / 2));

    controller.dispose();
  });
}
