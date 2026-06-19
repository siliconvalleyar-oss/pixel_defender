import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Estados de animación posibles del jugador.
enum PlayerAnimState { idle, walk, hurt }

/// Controla qué "animación" lógica está activa y expone valores derivados
/// (como un bobbing/squash simple) para dar sensación de movimiento sin
/// depender todavía de sprite sheets reales.
///
/// NOTA DE PRODUCCIÓN: esta clase está diseñada para una migración directa
/// a `SpriteAnimationComponent` con sprite sheets reales: basta con
/// sustituir [PlayerComponent.render] por un `SpriteAnimationGroupComponent`
/// que use estos mismos [PlayerAnimState] como claves, cargando los assets
/// desde `assets/images/player/`.
class PlayerAnimationController {
  PlayerAnimState state = PlayerAnimState.idle;
  double _time = 0;
  double _hurtFlashTimer = 0;

  void update(double dt, {required bool isMoving}) {
    _time += dt;
    state = isMoving ? PlayerAnimState.walk : PlayerAnimState.idle;
    if (_hurtFlashTimer > 0) _hurtFlashTimer -= dt;
  }

  void triggerHurtFlash() {
    _hurtFlashTimer = 0.15;
    state = PlayerAnimState.hurt;
  }

  bool get isFlashing => _hurtFlashTimer > 0;

  /// Desplazamiento vertical simulando "bobbing" al caminar.
  double get bobOffset {
    if (state != PlayerAnimState.walk) return 0;
    return (3 * (0.5 - (_time * 8) % 1.0)).abs() - 1.5;
  }

  Color get tint => isFlashing ? Colors.redAccent : Colors.transparent;
}
