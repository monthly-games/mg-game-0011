import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

class HeartEffectComponent extends PositionComponent {
  HeartEffectComponent({required Vector2 position})
      : super(position: position, size: Vector2(30, 30), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    // Float up and fade out
    add(MoveEffect.by(
      Vector2(0, -50),
      EffectController(duration: 1.0),
    ));
    add(OpacityEffect.fadeOut(
      EffectController(duration: 1.0),
      onComplete: () => removeFromParent(),
    ));
  }

  @override
  void render(Canvas canvas) {
    // Draw Heart
    final paint = Paint()..color = Colors.pinkAccent;
    final path = Path();

    // Heart shape logic for 30x30 box
    final width = size.x;
    final height = size.y;

    path.moveTo(0.5 * width, 0.4 * height);
    path.cubicTo(0.2 * width, 0.1 * height, -0.25 * width, 0.6 * height,
        0.5 * width, 1.0 * height);
    path.moveTo(0.5 * width, 0.4 * height);
    path.cubicTo(0.8 * width, 0.1 * height, 1.25 * width, 0.6 * height,
        0.5 * width, 1.0 * height);

    canvas.drawPath(path, paint);
  }
}
