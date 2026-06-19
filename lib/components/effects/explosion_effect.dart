import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

/// Texto flotante que muestra el daño infligido a un enemigo y luego
/// desaparece. Se auto-elimina al terminar su animación.
class DamageNumberComponent extends TextComponent {
  DamageNumberComponent({
    required super.position,
    required double damage,
    bool isCritical = false,
  }) : super(
          text: damage.round().toString(),
          anchor: Anchor.center,
          textRenderer: TextPaint(
            style: TextStyle(
              color: isCritical ? Colors.redAccent : Colors.white,
              fontSize: isCritical ? 18 : 13,
              fontWeight: FontWeight.bold,
              shadows: const [
                Shadow(color: Colors.black, blurRadius: 2, offset: Offset(1, 1)),
              ],
            ),
          ),
        );

  @override
  Future<void> onLoad() async {
    add(
      MoveByEffect(
        Vector2(0, -32),
        EffectController(duration: 0.6, curve: Curves.easeOut),
      ),
    );
    add(
      OpacityEffect.fadeOut(
        EffectController(duration: 0.6, startDelay: 0.15),
        onComplete: removeFromParent,
      ),
    );
  }
}

/// Overlay rojo semitransparente que cubre la pantalla brevemente cuando
/// el jugador recibe daño. Se añade/controla desde [PixelDefenderGame].
class DamageFlashEffect extends RectangleComponent with HasGameReference {
  DamageFlashEffect({required Vector2 size})
      : super(
          size: size,
          paint: Paint()..color = Colors.red.withValues(alpha: 0.0),
        );

  double _timer = 0;
  static const double _duration = 0.25;

  void trigger() {
    _timer = _duration;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Mantiene el overlay cubriendo toda la pantalla incluso si la ventana
    // cambia de tamaño (web/desktop) o rota (móvil).
    if (size != game.size) {
      size = game.size.clone();
    }

    if (_timer > 0) {
      _timer -= dt;
      final alpha = (_timer / _duration).clamp(0.0, 1.0) * 0.35;
      paint.color = Colors.red.withValues(alpha: alpha);
    } else {
      paint.color = Colors.red.withValues(alpha: 0.0);
    }
  }
}

/// Utilidad de shake de cámara compatible con `camera.follow(player)`.
///
/// IMPORTANTE: cuando la cámara sigue al jugador con `camera.follow()`,
/// Flame reescribe `viewfinder.position` cada frame. Animar esa posición
/// directamente con un `MoveEffect` competiría con `follow()` y produciría
/// un resultado errático. En su lugar, este shake mantiene un offset
/// independiente que [PixelDefenderGame] debe sumar manualmente sobre la
/// posición de la cámara en su `update` (ver `CameraShake.currentOffset`
/// y `CameraShake.update`).
class CameraShake {
  CameraShake._();

  static double _intensity = 0;
  static double _timer = 0;
  static double _duration = 0.25;
  static final Random _random = Random();

  static void shake(CameraComponent camera, {double intensity = 8, double duration = 0.25}) {
    _intensity = intensity;
    _duration = duration;
    _timer = duration;
  }

  /// Debe llamarse una vez por frame desde el `update` del juego, después
  /// de que `follow()` haya posicionado la cámara, para aplicar el offset.
  static void update(CameraComponent camera, double dt) {
    if (_timer <= 0) return;
    _timer -= dt;

    final decay = (_timer / _duration).clamp(0.0, 1.0);
    final offset = Vector2(
      (_random.nextDouble() * 2 - 1) * _intensity * decay,
      (_random.nextDouble() * 2 - 1) * _intensity * decay,
    );
    camera.viewfinder.position += offset;
  }
}
