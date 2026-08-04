import 'package:flutter/animation.dart';

class SpringCurve extends Curve {
  final double damping;

  const SpringCurve({this.damping = 15});

  @override
  double transformInternal(double t) {
    const b = 0.1;
    const c = 0.1;
    return 1 -
        (t - 1) * (t - 1) * (t - 1) * (t - 1) +
        b * (t - 1) * (t - 1) * (c - t);
  }
}
