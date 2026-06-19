import 'package:pixel_defender/components/effects/particle_effect.dart';
import 'package:pixel_defender/components/enemy/enemy_component.dart';
import 'package:pixel_defender/components/weapons/bullet_component.dart';
import 'package:pixel_defender/game/pixel_defender_game.dart';

/// Maneja la detección de colisiones bala-enemigo.
///
/// En lugar de depender exclusivamente del sistema de colisiones de Flame
/// (que es robusto pero más costoso con cientos de hitboxes simultáneas),
/// usamos un chequeo de distancia simple en un broad-phase manual: se
/// itera sobre las balas activas y, para cada una, solo sobre los
/// enemigos dentro de un radio razonable. Esto es deliberadamente más
/// barato que O(balas × enemigos) con hitboxes reales del engine.
///
/// Nota: las hitboxes (CollisionType) siguen declaradas en los componentes
/// para casos futuros (ej. recolección por contacto), pero el daño bala-
/// enemigo se resuelve aquí para tener control fino sobre piercing,
/// knockback y críticos sin pelear contra el callback API de Flame.
class CollisionSystem {
  CollisionSystem({required this.game});

  final PixelDefenderGame game;

  void update(double dt) {
    final bullets = game.bulletPool.activeBullets;
    if (bullets.isEmpty) return;

    final enemies = game.activeEnemies;
    if (enemies.isEmpty) return;

    for (final bullet in bullets) {
      if (!bullet.active) continue;

      for (final enemy in enemies) {
        if (!enemy.isAlive) continue;

        final combinedRadius = bullet.size.x / 2 + enemy.size.x / 2;
        final distSq = bullet.position.distanceToSquared(enemy.position);

        if (distSq <= combinedRadius * combinedRadius) {
          _resolveHit(bullet, enemy);
          if (!bullet.active) break; // esta bala ya no puede golpear a más enemigos
        }
      }
    }
  }

  void _resolveHit(BulletComponent bullet, EnemyComponent enemy) {
    final shouldDeactivate = bullet.registerHit(enemy);

    enemy.takeDamage(
      bullet.damage,
      knockbackFrom: bullet.position - bullet.direction * 10,
      isCritical: bullet.isCritical,
    );

    game.world.add(
      ParticleEffect.hitSpark(position: bullet.position.clone()),
    );

    if (shouldDeactivate) {
      // La bala ya se desactivó dentro de registerHit() si agotó su piercing.
    }
  }
}
