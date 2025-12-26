import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

/// VFX Manager for Fairy Forest Healing Idle (MG-0011)
/// Decoration + Idle + Social 게임 전용 이펙트 관리자
class VfxManager extends Component with HasGameRef {
  VfxManager();
  final Random _random = Random();

  // Decoration/Forest Effects
  void showDecorationPlace(Vector2 position) {
    gameRef.add(_createSparkleEffect(position: position, color: Colors.amber, count: 15));
    gameRef.add(_createGroundCircle(position: position, color: Colors.green.shade300));
  }

  void showForestGrow(Vector2 position) {
    gameRef.add(_createRisingEffect(position: position, color: Colors.green, count: 12, speed: 60));
    gameRef.add(_createSparkleEffect(position: position, color: Colors.lightGreen, count: 8));
  }

  void showHealingComplete(Vector2 position) {
    gameRef.add(_createRisingEffect(position: position, color: Colors.pink.shade200, count: 15, speed: 50));
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (!isMounted) return;
        gameRef.add(_createHeartEffect(position: position + Vector2((_random.nextDouble() - 0.5) * 40, -10)));
      });
    }
  }

  void showFriendVisit(Vector2 position) {
    gameRef.add(_createSparkleEffect(position: position, color: Colors.lightBlue, count: 12));
    showNumberPopup(position, '친구 방문!', color: Colors.cyan);
  }

  void showQuestComplete(Vector2 position) {
    gameRef.add(_createExplosionEffect(position: position, color: Colors.amber, count: 25, radius: 60));
    gameRef.add(_createSparkleEffect(position: position, color: Colors.yellow, count: 15));
  }

  void showAmbientParticles(Vector2 position) {
    gameRef.add(_createFloatingParticles(position: position));
  }

  void showNumberPopup(Vector2 position, String text, {Color color = Colors.white}) {
    gameRef.add(_NumberPopup(position: position, text: text, color: color));
  }

  // Private generators
  ParticleSystemComponent _createSparkleEffect({required Vector2 position, required Color color, required int count}) {
    return ParticleSystemComponent(particle: Particle.generate(count: count, lifespan: 0.6, generator: (i) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 40 + _random.nextDouble() * 30;
      return AcceleratedParticle(position: position.clone(), speed: Vector2(cos(angle), sin(angle)) * speed, acceleration: Vector2(0, 30), child: ComputedParticle(renderer: (canvas, particle) {
        final opacity = (1.0 - particle.progress).clamp(0.0, 1.0);
        final size = 3 * (1.0 - particle.progress * 0.5);
        final path = Path();
        for (int j = 0; j < 4; j++) {
          final a = (j * pi / 2);
          if (j == 0) path.moveTo(cos(a) * size, sin(a) * size);
          else path.lineTo(cos(a) * size, sin(a) * size);
        }
        path.close();
        canvas.drawPath(path, Paint()..color = color.withOpacity(opacity));
      }));
    }));
  }

  ParticleSystemComponent _createRisingEffect({required Vector2 position, required Color color, required int count, required double speed}) {
    return ParticleSystemComponent(particle: Particle.generate(count: count, lifespan: 1.0, generator: (i) {
      final spreadX = (_random.nextDouble() - 0.5) * 40;
      return AcceleratedParticle(position: position.clone() + Vector2(spreadX, 0), speed: Vector2(0, -speed), acceleration: Vector2(0, -15), child: ComputedParticle(renderer: (canvas, particle) {
        final opacity = (1.0 - particle.progress).clamp(0.0, 1.0);
        canvas.drawCircle(Offset.zero, 3, Paint()..color = color.withOpacity(opacity));
      }));
    }));
  }

  ParticleSystemComponent _createHeartEffect({required Vector2 position}) {
    return ParticleSystemComponent(particle: Particle.generate(count: 1, lifespan: 1.2, generator: (i) {
      return AcceleratedParticle(position: position.clone(), speed: Vector2((_random.nextDouble() - 0.5) * 15, -35), acceleration: Vector2(0, -15), child: ComputedParticle(renderer: (canvas, particle) {
        final opacity = (1.0 - particle.progress).clamp(0.0, 1.0);
        final size = 8 * (1.0 - particle.progress * 0.3);
        final path = Path();
        path.moveTo(0, size * 0.3);
        path.cubicTo(-size, -size * 0.3, -size * 0.5, -size, 0, -size * 0.5);
        path.cubicTo(size * 0.5, -size, size, -size * 0.3, 0, size * 0.3);
        canvas.drawPath(path, Paint()..color = Colors.pink.withOpacity(opacity));
      }));
    }));
  }

  ParticleSystemComponent _createExplosionEffect({required Vector2 position, required Color color, required int count, required double radius}) {
    return ParticleSystemComponent(particle: Particle.generate(count: count, lifespan: 0.7, generator: (i) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = radius * (0.4 + _random.nextDouble() * 0.6);
      return AcceleratedParticle(position: position.clone(), speed: Vector2(cos(angle), sin(angle)) * speed, acceleration: Vector2(0, 80), child: ComputedParticle(renderer: (canvas, particle) {
        final opacity = (1.0 - particle.progress).clamp(0.0, 1.0);
        canvas.drawCircle(Offset.zero, 4 * (1.0 - particle.progress * 0.3), Paint()..color = color.withOpacity(opacity));
      }));
    }));
  }

  ParticleSystemComponent _createGroundCircle({required Vector2 position, required Color color}) {
    return ParticleSystemComponent(particle: Particle.generate(count: 1, lifespan: 0.8, generator: (i) {
      return ComputedParticle(renderer: (canvas, particle) {
        final progress = particle.progress;
        final opacity = (1.0 - progress).clamp(0.0, 1.0);
        final radius = 15 + progress * 35;
        canvas.drawCircle(Offset(position.x, position.y), radius, Paint()..color = color.withOpacity(opacity * 0.3)..style = PaintingStyle.stroke..strokeWidth = 2);
      });
    }));
  }

  ParticleSystemComponent _createFloatingParticles({required Vector2 position}) {
    return ParticleSystemComponent(particle: Particle.generate(count: 8, lifespan: 2.0, generator: (i) {
      final startX = position.x + (_random.nextDouble() - 0.5) * 100;
      final startY = position.y + (_random.nextDouble() - 0.5) * 80;
      return AcceleratedParticle(position: Vector2(startX, startY), speed: Vector2((_random.nextDouble() - 0.5) * 10, -15), acceleration: Vector2(0, -5), child: ComputedParticle(renderer: (canvas, particle) {
        final opacity = (0.5 - (particle.progress - 0.5).abs()).clamp(0.0, 0.5);
        canvas.drawCircle(Offset.zero, 2, Paint()..color = Colors.white.withOpacity(opacity));
      }));
    }));
  }
}

class _NumberPopup extends TextComponent {
  _NumberPopup({required Vector2 position, required String text, required Color color}) : super(text: text, position: position, anchor: Anchor.center, textRenderer: TextPaint(style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color, shadows: const [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1))])));
  @override Future<void> onLoad() async { await super.onLoad(); add(MoveByEffect(Vector2(0, -25), EffectController(duration: 0.6, curve: Curves.easeOut))); add(OpacityEffect.fadeOut(EffectController(duration: 0.6, startDelay: 0.2))); add(RemoveEffect(delay: 0.8)); }
}
