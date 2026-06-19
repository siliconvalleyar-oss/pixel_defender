import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pixel_defender/components/enemy/enemy_component.dart';
import 'package:pixel_defender/components/weapons/bullet_component.dart';
import 'package:pixel_defender/game/pixel_defender_game.dart';
import 'package:pixel_defender/managers/audio_manager.dart';
import 'package:pixel_defender/models/weapon_data.dart';
import 'package:pixel_defender/utils/constants.dart';

/// Pool de objetos [BulletComponent], evita instanciar/destruir balas en
/// cada disparo. Las balas inactivas se reutilizan; si el pool se agota,
/// crece bajo demanda (con un techo razonable implícito por el spawn rate).
class BulletPool {
  BulletPool(this.world);

  final World world;
  final List<BulletComponent> _pool = [];

  void preWarm(int count) {
    for (int i = 0; i < count; i++) {
      final bullet = BulletComponent()..deactivate();
      _pool.add(bullet);
      world.add(bullet);
    }
  }

  BulletComponent obtain() {
    for (final bullet in _pool) {
      if (!bullet.active) return bullet;
    }
    // Pool agotado: crecemos dinámicamente (caso de muchas armas a la vez).
    final bullet = BulletComponent()..deactivate();
    _pool.add(bullet);
    world.add(bullet);
    return bullet;
  }

  int get activeCount => _pool.where((b) => b.active).length;

  /// Lista de balas actualmente en uso. Usado por [CollisionSystem] para
  /// resolver impactos sin recorrer balas inactivas.
  List<BulletComponent> get activeBullets =>
      _pool.where((b) => b.active).toList(growable: false);
}

/// Componente "lógico" que representa un arma equipada por el jugador.
///
/// No tiene representación visual propia (las balas se renderizan solas);
/// su responsabilidad es: trackear cadencia de disparo, encontrar objetivos,
/// y obtener balas del pool para dispararlas.
class WeaponComponent extends Component with HasGameReference<PixelDefenderGame> {
  WeaponComponent({
    required this.instance,
    required this.bulletPool,
    required this.random,
  });

  final WeaponInstance instance;
  final BulletPool bulletPool;
  final Random random;

  double _cooldown = 0;
  double _orbitAngle = 0;

  /// Multiplicadores externos (provienen de PlayerStats) aplicados sobre
  /// las estadísticas base del arma.
  double externalDamageMultiplier = 1.0;
  double externalFireRateMultiplier = 1.0;
  double critChance = GameConstants.criticalHitChanceBase;
  double critMultiplier = GameConstants.criticalHitMultiplier;

  @override
  void update(double dt) {
    super.update(dt);

    final playerPos = game.player.position;

    if (instance.archetype.type == WeaponType.orbiter) {
      _updateOrbiter(dt, playerPos);
      return;
    }

    _cooldown -= dt;
    if (_cooldown > 0) return;

    final target = _findNearestEnemy(playerPos, instance.archetype.baseRange);
    if (target == null) return;

    _fireAt(playerPos, target);

    final effectiveFireRate = instance.fireRate * externalFireRateMultiplier;
    _cooldown = effectiveFireRate > 0 ? 1 / effectiveFireRate : 1;
  }

  EnemyComponent? _findNearestEnemy(Vector2 origin, double maxRange) {
    EnemyComponent? nearest;
    double bestDistSq = maxRange * maxRange;

    for (final enemy in game.activeEnemies) {
      if (!enemy.isAlive) continue;
      final distSq = enemy.position.distanceToSquared(origin);
      if (distSq < bestDistSq) {
        bestDistSq = distSq;
        nearest = enemy;
      }
    }
    return nearest;
  }

  void _fireAt(Vector2 origin, EnemyComponent target) {
    final baseDirection = (target.position - origin).normalized();
    final count = instance.projectileCount;

    // Para múltiples proyectiles (ej. escopeta), repartimos un ángulo de
    // dispersión alrededor de la dirección base.
    const spreadRadians = 0.35;
    for (int i = 0; i < count; i++) {
      final t = count == 1 ? 0.0 : (i / (count - 1)) - 0.5;
      final angleOffset = spreadRadians * t;
      final dir = _rotate(baseDirection, angleOffset);

      final bullet = bulletPool.obtain();
      final isCrit = random.nextDouble() < critChance;
      final dmg = instance.damage *
          externalDamageMultiplier *
          (isCrit ? critMultiplier : 1.0);

      bullet.fire(
        position: origin,
        direction: dir,
        speed: instance.archetype.baseProjectileSpeed,
        damage: dmg,
        lifetime: GameConstants.bulletDefaultLifetime,
        piercing: instance.archetype.piercing,
        isCritical: isCrit,
        color: _colorForWeapon(instance.type),
      );
    }

    AudioManager.instance.playSfx(SfxType.shoot);
  }

  Vector2 _rotate(Vector2 vector, double radians) {
    final cosA = cos(radians);
    final sinA = sin(radians);
    return Vector2(
      vector.x * cosA - vector.y * sinA,
      vector.x * sinA + vector.y * cosA,
    );
  }

  Color _colorForWeapon(WeaponType type) {
    switch (type) {
      case WeaponType.pistol:
        return Colors.yellowAccent;
      case WeaponType.shotgun:
        return Colors.orangeAccent;
      case WeaponType.laser:
        return Colors.cyanAccent;
      case WeaponType.orbiter:
        return Colors.purpleAccent;
    }
  }

  // -------------------------------------------------------------------
  // Arma orbital: no usa el pool de balas, daña por contacto continuo.
  // -------------------------------------------------------------------
  double _orbiterDamageCooldown = 0;
  final Map<EnemyComponent, double> _orbiterHitCooldowns = {};

  void _updateOrbiter(double dt, Vector2 playerPos) {
    _orbitAngle += dt * 2.4;
    _orbiterDamageCooldown -= dt;

    final count = instance.projectileCount;
    final radius = instance.archetype.baseRange;

    for (int i = 0; i < count; i++) {
      final angle = _orbitAngle + (2 * pi / count) * i;
      final orbPos = playerPos + Vector2(cos(angle), sin(angle)) * radius;

      for (final enemy in game.activeEnemies) {
        if (!enemy.isAlive) continue;
        final dist = enemy.position.distanceTo(orbPos);
        if (dist < enemy.size.x / 2 + 10) {
          final lastHit = _orbiterHitCooldowns[enemy] ?? 0;
          if (lastHit <= 0) {
            final dmg = instance.damage * externalDamageMultiplier;
            enemy.takeDamage(dmg, knockbackFrom: playerPos, isCritical: false);
            _orbiterHitCooldowns[enemy] = 0.4;
          }
        }
      }
    }

    _orbiterHitCooldowns.updateAll((key, value) => value - dt);
  }

  /// Posiciones actuales de los orbes, usado por el renderer del jugador
  /// para dibujarlos.
  List<Vector2> get orbiterPositions {
    if (instance.archetype.type != WeaponType.orbiter) return [];
    final playerPos = game.player.position;
    final count = instance.projectileCount;
    final radius = instance.archetype.baseRange;
    return List.generate(count, (i) {
      final angle = _orbitAngle + (2 * pi / count) * i;
      return playerPos + Vector2(cos(angle), sin(angle)) * radius;
    });
  }
}
