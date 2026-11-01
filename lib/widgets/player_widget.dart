import 'package:flutter/material.dart';
import '../core/constants.dart';

class PlayerWidget extends StatelessWidget {
  final double x;
  final double bottom;

  const PlayerWidget({
    required this.x,
    this.bottom = 20,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: bottom,
      left: x,
      child: Image.asset(
        'assets/images/player.png',
        width: Constants.playerSize,
        height: Constants.playerSize,
      ),
    );
  }
}
