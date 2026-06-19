import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

/// Fábrica de efectos de partículas reutilizables, construidos sobre el
/// sistema de partículas nativo de Flame.
///
/// Estos componentes se auto-eliminan al terminar su ciclo de vida
/// (Flame's `ParticleSystemComponent` con `Particle` maneja esto
/// internamente), por lo que no requieren pooling manual: su frecuencia
/// de creación (solo al morir un enemigo o impactar) es mucho menor que
/// la de las balas.
class ParticleEffect {
  ParticleEffect._();

  static final Random _random = Random();

  /// Pequeña explosión radial de partículas, usada al morir un enemigo.
  static ParticleSystemComponent explosion({
    required Vector2 position,
    Color color = Colors.orange,
    int count = 12,
  }) {
    return ParticleSystemComponent(
      position: position,
      particle: Particle.generate(
        count: count,
        lifespan: 0.45,
        generator: (i) {
          final angle = _random.nextDouble() * 2 * pi;
          final speed = 40 + _random.nextDouble() * 90;
          final velocity = Vector2(cos(angle), sin(angle)) * speed;

          return AcceleratedParticle(
            acceleration: velocity * -1.5,
            speed: velocity,
            child: CircleParticle(
              radius: 2 + _random.nextDouble() * 2,
              paint: Paint()..color = color.withValues(alpha: 0.9),
            ),
          );
        },
      ),
    );
  }

  /// Chispazo pequeño al impactar una bala contra un enemigo.
  static ParticleSystemComponent hitSpark({
    required Vector2 position,
    Color color = Colors.white,
  }) {
    return ParticleSystemComponent(
      position: position,
      particle: Particle.generate(
        count: 5,
        lifespan: 0.2,
        generator: (i) {
          final angle = _random.nextDouble() * 2 * pi;
          final speed = 30 + _random.nextDouble() * 40;
          final velocity = Vector2(cos(angle), sin(angle)) * speed;

          return AcceleratedParticle(
            acceleration: velocity * -2,
            speed: velocity,
            child: CircleParticle(
              radius: 1.5,
              paint: Paint()..color = color,
            ),
          );
        },
      ),
    );
  }

  /// Partículas de recolección de moneda/experiencia (efecto de "succión").
  static ParticleSystemComponent pickupSparkle({
    required Vector2 position,
    Color color = Colors.greenAccent,
  }) {
    return ParticleSystemComponent(
      position: position,
      particle: Particle.generate(
        count: 6,
        lifespan: 0.3,
        generator: (i) {
          final angle = _random.nextDouble() * 2 * pi;
          final speed = 20 + _random.nextDouble() * 30;
          return AcceleratedParticle(
            speed: Vector2(cos(angle), sin(angle)) * speed,
            child: CircleParticle(
              radius: 1.5,
              paint: Paint()..color = color.withValues(alpha: 0.8),
            ),
          );
        },
      ),
    );
  }
}
