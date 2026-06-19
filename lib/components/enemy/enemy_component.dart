import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pixel_defender/components/effects/particle_effect.dart';
import 'package:pixel_defender/game/pixel_defender_game.dart';
import 'package:pixel_defender/managers/audio_manager.dart';
import 'package:pixel_defender/models/enemy_data.dart';

// Constantes locales para el hot path de update() (evita imports pesados
// repetidos por cada enemigo activo).
const double _kEnemyDespawnRadius = 900;
const double _kContactCooldown = 0.5;
const double _kKnockbackForce = 260;

/// Componente visual + lógico de un enemigo individual.
///
/// La IA es deliberadamente simple ("persigue al jugador en línea recta"),
/// como corresponde a un juego de oleadas masivas: con cientos de enemigos
/// en pantalla, pathfinding complejo sería prohibitivo en rendimiento.
class EnemyComponent extends PositionComponent
    with CollisionCallbacks, HasGameReference<PixelDefenderGame> {
  EnemyComponent({required this.archetype}) : super(anchor: Anchor.center) {
    size = Vector2.all(archetype.spriteSize);
  }

  final EnemyArchetype archetype;

  late double maxHealth;
  late double currentHealth;
  late double speed;
  late double damage;
  late double contactDamage;

  bool isAlive = true;
  double _contactDamageCooldown = 0;
  double _flashTimer = 0;
  double _deathAnimTimer = -1;
  double opacity = 1;

  // Knockback en curso (si lo hay)
  Vector2 _knockbackVelocity = Vector2.zero();

  late final CircleHitbox _hitbox;

  /// Reinicia este enemigo con nuevos valores escalados por dificultad,
  /// permitiendo reutilizar la instancia (pooling de enemigos también
  /// reduce presión de GC durante oleadas largas).
  void initialize({
    required Vector2 position,
    required double healthMultiplier,
    required double speedMultiplier,
    required double damageMultiplier,
  }) {
    this.position = position;
    maxHealth = archetype.baseHealth * healthMultiplier;
    currentHealth = maxHealth;
    speed = archetype.baseSpeed * speedMultiplier;
    damage = archetype.baseDamage * damageMultiplier;
    contactDamage = archetype.contactDamage * damageMultiplier;
    isAlive = true;
    _flashTimer = 0;
    _deathAnimTimer = -1;
    _contactDamageCooldown = 0;
    _knockbackVelocity = Vector2.zero();
    scale = Vector2.all(1);
    opacity = 1;
  }

  @override
  Future<void> onLoad() async {
    _hitbox = CircleHitbox(radius: size.x / 2)
      ..collisionType = CollisionType.passive;
    add(_hitbox);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!isAlive) {
      _updateDeathAnimation(dt);
      return;
    }

    _contactDamageCooldown -= dt;
    if (_flashTimer > 0) _flashTimer -= dt;

    // Despawn si quedó demasiado lejos del jugador (mantiene la simulación acotada).
    final distToPlayer = position.distanceTo(game.player.position);
    if (distToPlayer > _kEnemyDespawnRadius) {
      game.enemySpawnSystem.recycle(this);
      return;
    }

    _applyMovement(dt, distToPlayer);
    _checkContactDamage();
  }

  void _applyMovement(double dt, double distToPlayer) {
    // Aplica knockback si existe, decayendo con el tiempo.
    if (_knockbackVelocity.length2 > 1) {
      position += _knockbackVelocity * dt;
      _knockbackVelocity *= 0.86;
      return;
    }

    if (archetype.isRanged && distToPlayer < 220) {
      // Los enemigos a distancia mantienen el rango en lugar de pegarse al jugador.
      final away = (position - game.player.position).normalized();
      position += away * speed * 0.5 * dt;
      return;
    }

    final direction = (game.player.position - position).normalized();
    position += direction * speed * dt;
  }

  void _checkContactDamage() {
    if (_contactDamageCooldown > 0) return;
    final distToPlayer = position.distanceTo(game.player.position);
    final combinedRadius = size.x / 2 + game.player.size.x / 2;
    if (distToPlayer <= combinedRadius) {
      game.player.takeDamage(contactDamage);
      _contactDamageCooldown = _kContactCooldown;
    }
  }

  /// Aplica daño a este enemigo. Devuelve true si el enemigo murió por
  /// este golpe.
  bool takeDamage(
    double amount, {
    Vector2? knockbackFrom,
    bool isCritical = false,
  }) {
    if (!isAlive) return false;

    currentHealth -= amount;
    _flashTimer = 0.08;

    if (knockbackFrom != null) {
      final dir = (position - knockbackFrom).normalized();
      _knockbackVelocity = dir * _kKnockbackForce;
    }

    game.spawnDamageNumber(position.clone(), amount, isCritical: isCritical);

    if (currentHealth <= 0) {
      _die();
      return true;
    }
    return false;
  }

  void _die() {
    isAlive = false;
    _deathAnimTimer = 0;
    game.onEnemyKilled(this);
    AudioManager.instance.playSfx(SfxType.explosion);
    game.world.add(
      ParticleEffect.explosion(position: position.clone(), color: _baseColor()),
    );
  }

  void _updateDeathAnimation(double dt) {
    _deathAnimTimer += dt;
    const duration = 0.25;
    final t = (_deathAnimTimer / duration).clamp(0.0, 1.0);
    scale = Vector2.all(1 + t * 0.5);
    opacity = 1 - t;

    if (_deathAnimTimer >= duration) {
      game.enemySpawnSystem.recycle(this);
    }
  }

  Color _baseColor() {
    switch (archetype.type) {
      case EnemyType.grunt:
        return Colors.redAccent;
      case EnemyType.runner:
        return Colors.orangeAccent;
      case EnemyType.tank:
        return Colors.brown;
      case EnemyType.ranged:
        return Colors.purpleAccent;
      case EnemyType.boss:
        return Colors.deepPurple;
    }
  }

  @override
  void render(Canvas canvas) {
    final color = _baseColor();
    final paint = Paint()
      ..color = (_flashTimer > 0 ? Colors.white : color).withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final radius = Radius.circular(size.x * 0.25);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), paint);

    // Barra de vida sobre el enemigo (solo si ha recibido daño y no es boss,
    // los bosses tienen su propia barra en el HUD).
    if (currentHealth < maxHealth && !archetype.isBoss && isAlive) {
      final healthPct = (currentHealth / maxHealth).clamp(0.0, 1.0);
      final barWidth = size.x;
      const barHeight = 3.0;
      const barY = -8.0;

      canvas.drawRect(
        Rect.fromLTWH(0, barY, barWidth, barHeight),
        Paint()..color = Colors.black54,
      );
      canvas.drawRect(
        Rect.fromLTWH(0, barY, barWidth * healthPct, barHeight),
        Paint()..color = Colors.greenAccent,
      );
    }
  }
}
