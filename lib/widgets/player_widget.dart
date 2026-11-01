import 'package:flutter/material.dart';
import '../core/constants.dart';

class PlayerWidget extends StatelessWidget {
  final double x;
  const PlayerWidget({required this.x, super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      left: x,
      child: Image.asset(
        'assets/images/player.png',
        width: Constants.playerSize,
        height: Constants.playerSize,
      ),
    );
  }
}