import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/falling_object.dart';

class ObjectWidget extends StatelessWidget {
  final double x;
  final double y;
  final ObjectType type;

  const ObjectWidget({super.key, required this.x, required this.y, this.type = ObjectType.normal});

  @override
  Widget build(BuildContext context) {
    String assetPath = 'assets/images/rock.png'; // default object

    switch (type) {
      case ObjectType.shield:
        assetPath = 'assets/images/shield.png';
        break;
      case ObjectType.slow:
        assetPath = 'assets/images/slow.png';
        break;
      default:
        assetPath = 'assets/images/rock.png';
    }

    return Positioned(
      top: y,
      left: x,
      child: SizedBox(
        width: Constants.objectSize,
        height: Constants.objectSize,
        child: Image.asset(assetPath),
      ),
    );
  }
}