/// Catálogo de tipos de armas disponibles para el jugador.
enum WeaponType { pistol, shotgun, laser, orbiter }

/// Configuración base de un arma. Las instancias activas del jugador
/// llevan además un [level] que escala estos valores mediante
/// [WeaponData.statsAtLevel].
class WeaponArchetype {
  const WeaponArchetype({
    required this.type,
    required this.name,
    required this.baseDamage,
    required this.baseFireRate,
    required this.baseProjectileSpeed,
    required this.baseRange,
    required this.projectileCount,
    required this.maxLevel,
    this.piercing = 1,
  });

  final WeaponType type;
  final String name;
  final double baseDamage;
  final double baseFireRate; // disparos por segundo
  final double baseProjectileSpeed;
  final double baseRange;
  final int projectileCount;
  final int maxLevel;
  final int piercing; // cuántos enemigos puede atravesar un proyectil

  static const Map<WeaponType, WeaponArchetype> catalog = {
    WeaponType.pistol: WeaponArchetype(
      type: WeaponType.pistol,
      name: 'Pistola Automática',
      baseDamage: 8,
      baseFireRate: 2.0,
      baseProjectileSpeed: 480,
      baseRange: 420,
      projectileCount: 1,
      maxLevel: 8,
    ),
    WeaponType.shotgun: WeaponArchetype(
      type: WeaponType.shotgun,
      name: 'Escopeta',
      baseDamage: 6,
      baseFireRate: 0.9,
      baseProjectileSpeed: 420,
      baseRange: 280,
      projectileCount: 3,
      maxLevel: 8,
    ),
    WeaponType.laser: WeaponArchetype(
      type: WeaponType.laser,
      name: 'Rayo Láser',
      baseDamage: 14,
      baseFireRate: 1.2,
      baseProjectileSpeed: 700,
      baseRange: 600,
      projectileCount: 1,
      maxLevel: 8,
      piercing: 3,
    ),
    WeaponType.orbiter: WeaponArchetype(
      type: WeaponType.orbiter,
      name: 'Orbe Giratorio',
      baseDamage: 10,
      baseFireRate: 0, // no dispara, orbita continuamente
      baseProjectileSpeed: 0,
      baseRange: 90,
      projectileCount: 2,
      maxLevel: 8,
    ),
  };
}

/// Instancia de un arma equipada por el jugador, con su nivel actual.
class WeaponInstance {
  WeaponInstance({required this.type, this.level = 1});

  final WeaponType type;
  int level;

  WeaponArchetype get archetype => WeaponArchetype.catalog[type]!;

  bool get isMaxLevel => level >= archetype.maxLevel;

  /// Calcula las estadísticas efectivas según el nivel actual del arma.
  /// Cada nivel aumenta daño ~18% y cadencia ~8%, hasta el tope.
  double get damage => archetype.baseDamage * (1 + 0.18 * (level - 1));
  double get fireRate => archetype.baseFireRate * (1 + 0.08 * (level - 1));
  int get projectileCount =>
      archetype.projectileCount + (level ~/ 3); // +1 proyectil cada 3 niveles
}
