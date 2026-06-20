import 'dart:math' show atan2, min, pi;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pixel_defender/components/player/player_animation.dart';
import 'package:pixel_defender/components/weapons/weapon_component.dart';
import 'package:pixel_defender/game/pixel_defender_game.dart';
import 'package:pixel_defender/models/player_data.dart';
import 'package:pixel_defender/models/weapon_data.dart';
import 'package:pixel_defender/utils/constants.dart';

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

  Vector2 inputDirection = Vector2.zero();

  double _invulnerabilityTimer = 0;
  bool get isInvulnerable => _invulnerabilityTimer > 0;

  late final CircleHitbox _hitbox;
  late final Sprite _shipSprite;

  @override
  Future<void> onLoad() async {
    _hitbox = CircleHitbox(radius: size.x / 2)
      ..collisionType = CollisionType.passive;
    add(_hitbox);

    _shipSprite = await Sprite.load('naves/nave_00.png', images: game.images);

    equipWeapon(WeaponType.pistol);
  }

  void equipWeapon(WeaponType type) {
    final existing = weapons.where((w) => w.instance.type == type);
    if (existing.isNotEmpty) return;

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

      position.x = position.x.clamp(0, GameConstants.worldWidth);
      position.y = position.y.clamp(0, GameConstants.worldHeight);

      angle = atan2(inputDirection.y, inputDirection.x) + pi / 2;
    }

    data.survivalTime += dt;
  }

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
    final bobOffset = animController.bobOffset;

    canvas.save();
    canvas.translate(0, bobOffset);

    final spriteSize = _shipSprite.srcSize;
    final scale = min(size.x / spriteSize.x, size.y / spriteSize.y);
    final scaled = spriteSize * scale;
    final offset = (size - scaled) / 2;

    final paint = Paint();
    if (animController.isFlashing) {
      paint.colorFilter = const ColorFilter.mode(Colors.red, BlendMode.srcATop);
    } else if (isInvulnerable) {
      paint.colorFilter = const ColorFilter.mode(
        Colors.blueAccent,
        BlendMode.srcATop,
      );
      paint.color = Colors.white.withValues(alpha: 0.6);
    }

    _shipSprite.render(canvas, position: offset, size: scaled, overridePaint: paint);
    canvas.restore();
  }
}
