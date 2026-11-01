import 'dart:math';

double randomDouble(double min, double max) {
  return min + Random().nextDouble() * (max - min);
}