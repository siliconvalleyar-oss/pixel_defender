/// Catálogo de tipos de enemigos disponibles.
enum EnemyType { grunt, runner, tank, ranged, boss }

/// Datos de configuración (no-mutables) para una clase de enemigo.
///
/// Cada [EnemyType] tiene una [EnemyArchetype] asociada que define sus
/// valores base. El [EnemySpawnSystem] escala estos valores con la
/// dificultad de la oleada actual.
class EnemyArchetype {
  const EnemyArchetype({
    required this.type,
    required this.baseHealth,
    required this.baseSpeed,
    required this.baseDamage,
    required this.expReward,
    required this.coinReward,
    required this.spriteSize,
    required this.contactDamage,
    this.isRanged = false,
    this.isBoss = false,
  });

  final EnemyType type;
  final double baseHealth;
  final double baseSpeed;
  final double baseDamage;
  final int expReward;
  final int coinReward;
  final double spriteSize;
  final double contactDamage;
  final bool isRanged;
  final bool isBoss;

  static const Map<EnemyType, EnemyArchetype> catalog = {
    EnemyType.grunt: EnemyArchetype(
      type: EnemyType.grunt,
      baseHealth: 18,
      baseSpeed: 55,
      baseDamage: 6,
      expReward: 2,
      coinReward: 1,
      spriteSize: 28,
      contactDamage: 6,
    ),
    EnemyType.runner: EnemyArchetype(
      type: EnemyType.runner,
      baseHealth: 10,
      baseSpeed: 110,
      baseDamage: 4,
      expReward: 2,
      coinReward: 1,
      spriteSize: 22,
      contactDamage: 4,
    ),
    EnemyType.tank: EnemyArchetype(
      type: EnemyType.tank,
      baseHealth: 80,
      baseSpeed: 32,
      baseDamage: 14,
      expReward: 6,
      coinReward: 4,
      spriteSize: 40,
      contactDamage: 14,
    ),
    EnemyType.ranged: EnemyArchetype(
      type: EnemyType.ranged,
      baseHealth: 14,
      baseSpeed: 48,
      baseDamage: 8,
      expReward: 4,
      coinReward: 3,
      spriteSize: 26,
      contactDamage: 5,
      isRanged: true,
    ),
    EnemyType.boss: EnemyArchetype(
      type: EnemyType.boss,
      baseHealth: 600,
      baseSpeed: 40,
      baseDamage: 25,
      expReward: 80,
      coinReward: 50,
      spriteSize: 80,
      contactDamage: 25,
      isBoss: true,
    ),
  };
}
