import 'package:flutter_test/flutter_test.dart';
import 'package:bomb_run/main.dart';
import 'package:bomb_run/utils/collision.dart';
import 'package:bomb_run/utils/movement.dart';

void main() {
  testWidgets('AvoidGame boots to HomePage with start and settings buttons',
      (WidgetTester tester) async {
    await tester.pumpWidget(const AvoidGame());
    await tester.pump();

    // Verify main menu buttons exist
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
    // Overlapping boxes (player at 100, 500, size 60; object at 120, 520, size 40)
    expect(isColliding(100, 500, 60, 120, 520, 40), isTrue);

    // Completely separated boxes horizontally
    expect(isColliding(100, 500, 60, 200, 500, 40), isFalse);

    // Completely separated boxes vertically
    expect(isColliding(100, 500, 60, 100, 300, 40), isFalse);

    // Touching edges without overlap
    expect(isColliding(100, 500, 60, 160, 500, 40), isFalse);
  });

  test('Movement helper functions update coordinates accurately', () {
    expect(moveLeft(100.0, 20.0), equals(80.0));
    expect(moveRight(100.0, 20.0), equals(120.0));
  });
}
