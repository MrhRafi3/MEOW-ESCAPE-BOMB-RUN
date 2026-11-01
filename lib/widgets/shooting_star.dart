import 'dart:math';

class ShootingStar {
  double x;
  double y;
  double length;
  double speed;

  ShootingStar({required this.x, required this.y, required this.length, required this.speed});

  void update(double screenWidth, double screenHeight) {
    x -= speed; // move left
    y += speed / 2; // move slightly down

    // Reset star if it goes off-screen
    if (x + length < 0 || y - length > screenHeight) {
      x = screenWidth + length;
      y = Random().nextDouble() * screenHeight;
    }
  }
}