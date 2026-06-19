import 'package:pixel_defender/models/weapon_data.dart';

/// Tipos de mejora que pueden ofrecerse al subir de nivel.
enum UpgradeKind {
  newWeapon,
  weaponLevelUp,
  maxHealth,
  speed,
  damage,
  fireRate,
  critChance,
  pickupRadius,
  armor,
}

/// Representa una opción de mejora mostrada en [UpgradeScreen].
class UpgradeOption {
  const UpgradeOption({
    required this.id,
    required this.kind,
    required this.title,
    required this.description,
    required this.value,
    this.weaponType,
  });

  final String id;
  final UpgradeKind kind;
  final String title;
  final String description;
  final double value; // magnitud del efecto (porcentaje o flat, según kind)
  final WeaponType? weaponType;
}

/// Mejora permanente comprada con monedas fuera de la partida (meta-progresión).
class PermanentUpgrade {
  PermanentUpgrade({
    required this.id,
    required this.name,
    required this.description,
    required this.costPerLevel,
    required this.maxLevel,
    required this.effectPerLevel,
    this.currentLevel = 0,
  });

  final String id;
  final String name;
  final String description;
  final int costPerLevel;
  final int maxLevel;
  final double effectPerLevel;
  int currentLevel;

  bool get isMaxed => currentLevel >= maxLevel;
  int get nextCost => costPerLevel * (currentLevel + 1);
  double get totalEffect => effectPerLevel * currentLevel;

  static List<PermanentUpgrade> defaultCatalog() => [
        PermanentUpgrade(
          id: 'perm_health',
          name: 'Vitalidad',
          description: '+10 vida máxima inicial por nivel',
          costPerLevel: 50,
          maxLevel: 10,
          effectPerLevel: 10,
        ),
        PermanentUpgrade(
          id: 'perm_damage',
          name: 'Poder de Fuego',
          description: '+5% daño global por nivel',
          costPerLevel: 75,
          maxLevel: 10,
          effectPerLevel: 0.05,
        ),
        PermanentUpgrade(
          id: 'perm_speed',
          name: 'Agilidad',
          description: '+4% velocidad de movimiento por nivel',
          costPerLevel: 60,
          maxLevel: 10,
          effectPerLevel: 0.04,
        ),
        PermanentUpgrade(
          id: 'perm_coins',
          name: 'Fortuna',
          description: '+10% monedas obtenidas por nivel',
          costPerLevel: 80,
          maxLevel: 10,
          effectPerLevel: 0.10,
        ),
      ];
}
