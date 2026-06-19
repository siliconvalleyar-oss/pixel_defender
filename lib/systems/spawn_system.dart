import 'dart:math';
import 'package:flame/components.dart';
import 'package:pixel_defender/components/enemy/boss_component.dart';
import 'package:pixel_defender/components/enemy/enemy_component.dart';
import 'package:pixel_defender/components/enemy/enemy_types.dart';
import 'package:pixel_defender/game/pixel_defender_game.dart';
import 'package:pixel_defender/models/enemy_data.dart';
import 'package:pixel_defender/utils/constants.dart';
import 'package:pixel_defender/utils/helpers.dart';

/// Gestiona la creación, reutilización (pooling) y reciclaje de enemigos.
///
/// Igual que con las balas, instanciar/destruir cientos de enemigos por
/// minuto sería costoso; este sistema mantiene un pool por tipo de enemigo
/// y los reactiva con [EnemyComponent.initialize] en lugar de recrearlos.
class EnemySpawnSystem {
  EnemySpawnSystem({required this.game, required this.random});

  final PixelDefenderGame game;
  final Random random;

  final Map<EnemyType, List<EnemyComponent>> _pools = {
    for (final type in EnemyType.values) type: <EnemyComponent>[],
  };

  /// Usamos un [Set] (no [List]) porque `spawn()` necesita comprobar
  /// "¿este enemigo del pool ya está activo?" con alta frecuencia; con
  /// cientos de enemigos simultáneos, una búsqueda O(n) en lista se nota.
  final Set<EnemyComponent> _activeSet = {};

  /// Iterable de solo lectura sobre los enemigos activos. Se expone el
  /// [Set] directamente (no una copia) porque este getter se consulta
  /// muchas veces por frame (búsqueda de objetivo de cada arma, sistema
  /// de colisiones, HUD); copiar a [List] en cada llamada generaría
  /// presión de GC innecesaria con cientos de enemigos activos.
  Iterable<EnemyComponent> get active => _activeSet;

  /// Crea (o reutiliza del pool) un enemigo del tipo dado y lo activa
  /// en la posición indicada, escalado según [healthMultiplier],
  /// [speedMultiplier] y [damageMultiplier].
  EnemyComponent spawn({
    required EnemyType type,
    required Vector2 position,
    double healthMultiplier = 1.0,
    double speedMultiplier = 1.0,
    double damageMultiplier = 1.0,
  }) {
    final pool = _pools[type]!;
    EnemyComponent enemy;

    EnemyComponent? available;
    for (final candidate in pool) {
      if (!_activeSet.contains(candidate)) {
        available = candidate;
        break;
      }
    }

    if (available != null) {
      enemy = available;
    } else {
      final archetype = EnemyArchetype.catalog[type]!;
      enemy = type == EnemyType.boss
          ? BossComponent(archetype: archetype)
          : EnemyComponent(archetype: archetype);
      pool.add(enemy);
      game.world.add(enemy);
    }

    enemy.initialize(
      position: position,
      healthMultiplier: healthMultiplier,
      speedMultiplier: speedMultiplier,
      damageMultiplier: damageMultiplier,
    );

    _activeSet.add(enemy);
    return enemy;
  }

  /// Devuelve un enemigo al pool (lo desactiva visualmente, queda
  /// disponible para [spawn] en el futuro).
  void recycle(EnemyComponent enemy) {
    _activeSet.remove(enemy);
    enemy.position = Vector2(-9999, -9999);
  }

  /// Genera un enemigo aleatorio (no-boss) según la tabla de pesos de la
  /// oleada actual, en un anillo alrededor del jugador.
  void spawnRandomForWave(int wave, double difficultyMultiplier) {
    if (_activeSet.length >= GameConstants.maxConcurrentEnemies) return;

    final weights = EnemyTypeTable.weightsForWave(wave);
    final type = Helpers.weightedPick(weights);

    final position = Helpers.randomPointInRing(
      game.player.position,
      minRadius: GameConstants.enemySpawnRadius,
      maxRadius: GameConstants.enemySpawnRadius + 120,
    );

    spawn(
      type: type,
      position: position,
      healthMultiplier: difficultyMultiplier,
      speedMultiplier: 1 + (difficultyMultiplier - 1) * 0.3,
      damageMultiplier: difficultyMultiplier,
    );
  }

  void spawnBoss(int wave, double difficultyMultiplier) {
    final position = Helpers.randomPointInRing(
      game.player.position,
      minRadius: GameConstants.enemySpawnRadius * 0.6,
      maxRadius: GameConstants.enemySpawnRadius * 0.6,
    );

    spawn(
      type: EnemyType.boss,
      position: position,
      healthMultiplier: difficultyMultiplier,
      speedMultiplier: 1.0,
      damageMultiplier: difficultyMultiplier,
    );
  }

  int get activeCount => _activeSet.length;

  void reset() {
    for (final enemy in List.of(_activeSet)) {
      recycle(enemy);
    }
  }
}
