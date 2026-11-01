import 'dart:math';

enum ObjectType { normal, shield, slow }

class FallingObject {
  double x;
  double y;
  double speed;
  ObjectType type;

  FallingObject({
    required this.x,
    required this.y,
    required this.speed,
    this.type = ObjectType.normal,
  });

  static FallingObject random(double screenWidth, double baseSpeed) {
    // Randomly decide object type
    ObjectType type = ObjectType.normal;
    double chance = (Random().nextDouble());
    if (chance < 0.05) {
      type = ObjectType.shield; // 5% chance shield
    } else if (chance < 0.10) {
      type = ObjectType.slow; // 5% chance slow motion
    }

    return FallingObject(
      x: Random().nextDouble() * (screenWidth - 40),
      y: -50,
      speed: baseSpeed,
      type: type,
    );
  }
}