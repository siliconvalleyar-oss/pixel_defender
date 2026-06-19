import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pixel_defender/components/enemy/enemy_component.dart';
import 'package:pixel_defender/game/pixel_defender_game.dart';

/// Proyectil disparado por el jugador.
///
/// Diseñado para ser **reutilizado** mediante un pool (ver
/// `BulletPool` en weapon_component.dart) en lugar de crear/destruir
/// instancias constantemente, lo cual es costoso especialmente en móviles.
///
/// Para reutilizar una bala se llama a [reset], que la reconfigura y la
/// vuelve a activar sin pasar por el ciclo completo de construcción.
class BulletComponent extends PositionComponent
    with CollisionCallbacks, HasGameReference<PixelDefenderGame> {
  BulletComponent({super.position})
      : super(
          size: Vector2.all(8),
          anchor: Anchor.center,
        );

  Vector2 direction = Vector2.zero();
  double speed = 480;
  double damage = 8;
  double lifetime = 1.6;
  int piercing = 1;
  bool isCritical = false;
  Color color = Colors.yellowAccent;

  double _elapsed = 0;
  final Set<EnemyComponent> _alreadyHit = {};

  /// Indica si esta bala está actualmente en uso (true) o disponible en
  /// el pool para ser reutilizada (false).
  bool active = false;

  late final CircleHitbox _hitbox;

  @override
  Future<void> onLoad() async {
    _hitbox = CircleHitbox(radius: size.x / 2)..collisionType = CollisionType.active;
    add(_hitbox);
  }

  /// Reconfigura esta bala (ya cargada) para un nuevo disparo, evitando
  /// reconstruir el componente desde cero. Esta es la base del object pooling.
  void fire({
    required Vector2 position,
    required Vector2 direction,
    required double speed,
    required double damage,
    required double lifetime,
    int piercing = 1,
    bool isCritical = false,
    Color color = Colors.yellowAccent,
    Vector2? size,
  }) {
    this.position = position.clone();
    this.direction = direction.normalized();
    this.speed = speed;
    this.damage = damage;
    this.lifetime = lifetime;
    this.piercing = piercing;
    this.isCritical = isCritical;
    this.color = color;
    if (size != null) this.size = size;
    angle = atan2(this.direction.y, this.direction.x);
    _elapsed = 0;
    _alreadyHit.clear();
    active = true;
    this.opacity = 1;
  }

  double opacity = 1;

  void deactivate() {
    active = false;
    position = Vector2(-9999, -9999); // fuera de pantalla, evita colisiones fantasma
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!active) return;

    _elapsed += dt;
    if (_elapsed >= lifetime) {
      deactivate();
      return;
    }

    position += direction * speed * dt;
  }

  @override
  void render(Canvas canvas) {
    if (!active) return;
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2, paint);

    if (isCritical) {
      final glowPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.5 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2 + 2, glowPaint);
    }
  }

  /// Marca a un enemigo como ya golpeado por esta bala (para que el
  /// piercing no golpee al mismo enemigo varias veces) y descuenta
  /// el contador de penetración. Devuelve true si la bala debe desactivarse.
  bool registerHit(EnemyComponent enemy) {
    if (_alreadyHit.contains(enemy)) return false;
    _alreadyHit.add(enemy);
    piercing--;
    if (piercing <= 0) {
      deactivate();
      return true;
    }
    return false;
  }
}
