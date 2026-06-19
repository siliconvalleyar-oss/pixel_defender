import 'package:flutter/material.dart';
import 'package:pixel_defender/components/enemy/enemy_component.dart';

/// Variante de [EnemyComponent] para jefes.
///
/// Reutiliza toda la lógica base (movimiento, daño, knockback, animación
/// de muerte) y añade un aura pulsante para que destaque claramente entre
/// los enemigos comunes. La barra de vida del jefe se muestra en el HUD
/// en lugar de sobre su cabeza (ver [BossHealthBar] en hud.dart).
class BossComponent extends EnemyComponent {
  BossComponent({required super.archetype}) : assert(archetype.isBoss);

  double _pulseTimer = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _pulseTimer += dt * 3;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (!isAlive) return;

    final pulse = (_pulseTimer % 2 - 1).abs();
    final pulseRadius = size.x / 2 + 6 + pulse * 6;
    final auraPaint = Paint()
      ..color = Colors.deepPurpleAccent.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      pulseRadius,
      auraPaint,
    );
  }
}
