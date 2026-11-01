bool isColliding(
    double playerX,
    double playerY,
    double playerSize,
    double objX,
    double objY,
    double objSize,
    ) {
  return (playerX < objX + objSize &&
      playerX + playerSize > objX &&
      playerY < objY + objSize &&
      playerY + playerSize > objY);
}