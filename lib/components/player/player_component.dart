import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pixel_defender/components/player/player_animation.dart';
import 'package:pixel_defender/components/weapons/weapon_component.dart';
import 'package:pixel_defender/game/pixel_defender_game.dart';
import 'package:pixel_defender/models/player_data.dart';
import 'package:pixel_defender/models/weapon_data.dart';
import 'package:pixel_defender/utils/constants.dart';

/// Componente del jugador controlado por el usuario.
///
/// Combina:
/// - Movimiento dirigido por un vector de entrada (joystick/teclado/gamepad).
/// - El modelo [PlayerData] (vida, experiencia, nivel, estadísticas).
/// - La lista de [WeaponComponent] equipados, que disparan automáticamente.
class PlayerComponent extends PositionComponent
    with CollisionCallbacks, HasGameReference<PixelDefenderGame> {
  PlayerComponent({PlayerData? data})
      : data = data ?? PlayerData(),
        super(
          size: Vector2.all(GameConstants.playerSpriteSize),
          anchor: Anchor.center,
        );

  final PlayerData data;
  final PlayerAnimationController animController = PlayerAnimationController();
  final List<WeaponComponent> weapons = [];

  /// Vector de entrada normalizado (-1..1 en cada eje), seteado externamente
  /// por el joystick virtual, teclado o gamepad. PixelDefenderGame es quien
  /// combina todas las fuentes de input y escribe aquí.
  Vector2 inputDirection = Vector2.zero();

  double _invulnerabilityTimer = 0;
  bool get isInvulnerable => _invulnerabilityTimer > 0;

  late final CircleHitbox _hitbox;

  @override
  Future<void> onLoad() async {
    _hitbox = CircleHitbox(radius: size.x / 2)
      ..collisionType = CollisionType.passive;
    add(_hitbox);

    // Arma inicial: pistola automática.
    equipWeapon(WeaponType.pistol);
  }

  void equipWeapon(WeaponType type) {
    final existing = weapons.where((w) => w.instance.type == type);
    if (existing.isNotEmpty) return; // ya equipada; usar levelUpWeapon en su lugar

    final instance = WeaponInstance(type: type);
    final weapon = WeaponComponent(
      instance: instance,
      bulletPool: game.bulletPool,
      random: game.random,
    );
    _syncWeaponMultipliers(weapon);
    weapons.add(weapon);
    add(weapon);
  }

  void levelUpWeapon(WeaponType type) {
    final weapon = weapons.firstWhere((w) => w.instance.type == type);
    if (!weapon.instance.isMaxLevel) {
      weapon.instance.level++;
    }
  }

  void _syncWeaponMultipliers(WeaponComponent weapon) {
    weapon.externalDamageMultiplier = data.stats.damageMultiplier;
    weapon.externalFireRateMultiplier = data.stats.fireRateMultiplier;
    weapon.critChance = data.stats.critChance;
    weapon.critMultiplier = data.stats.critMultiplier;
  }

  /// Debe llamarse tras aplicar cualquier mejora que afecte stats de armas.
  void refreshWeaponStats() {
    for (final weapon in weapons) {
      _syncWeaponMultipliers(weapon);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_invulnerabilityTimer > 0) _invulnerabilityTimer -= dt;

    final isMoving = inputDirection.length2 > GameConstants.joystickDeadZone;
    animController.update(dt, isMoving: isMoving);

    if (isMoving) {
      final clampedInput = inputDirection.length > 1
          ? inputDirection.normalized()
          : inputDirection;
      position += clampedInput * data.stats.speed * dt;

      // Mantiene al jugador dentro de los límites del mundo.
      position.x = position.x.clamp(0, GameConstants.worldWidth);
      position.y = position.y.clamp(0, GameConstants.worldHeight);
    }

    data.survivalTime += dt;
  }

  /// Aplica daño al jugador, respetando invulnerabilidad temporal tras
  /// el último golpe (evita que enemigos en contacto continuo hagan daño
  /// cada frame).
  void takeDamage(double amount) {
    if (isInvulnerable || data.isDead) return;

    data.applyDamage(amount);
    _invulnerabilityTimer = GameConstants.playerInvulnerabilityDuration;
    animController.triggerHurtFlash();
    game.onPlayerDamaged();

    if (data.isDead) {
      game.onPlayerDied();
    }
  }

  void heal(double amount) => data.heal(amount);

  @override
  void render(Canvas canvas) {
    final bodyColor = animController.isFlashing
        ? Colors.red
        : (isInvulnerable ? Colors.blueAccent.withValues(alpha: 0.6) : Colors.lightBlueAccent);

    final bobOffset = animController.bobOffset;
    final rect = Rect.fromLTWH(0, bobOffset, size.x, size.y);

    final paint = Paint()
      ..color = bodyColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(10)),
      paint,
    );

    // Indicador de dirección (un pequeño triángulo) para dar feedback visual
    // de hacia dónde se está moviendo el jugador.
    if (inputDirection.length2 > GameConstants.joystickDeadZone) {
      final dir = inputDirection.normalized();
      final center = Offset(size.x / 2, size.y / 2 + bobOffset);
      final tip = center + Offset(dir.x, dir.y) * (size.x / 2 + 6);
      canvas.drawCircle(tip, 3, Paint()..color = Colors.white);
    }

    // Renderiza los orbes del arma "orbiter" si está equipada (posición
    // relativa al jugador, ya que este componente está en el sistema de
    // coordenadas del mundo).
  }
}
