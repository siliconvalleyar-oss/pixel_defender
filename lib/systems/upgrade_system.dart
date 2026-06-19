import 'dart:math';
import 'package:pixel_defender/models/upgrade_data.dart';
import 'package:pixel_defender/models/weapon_data.dart';
import 'package:pixel_defender/models/player_data.dart';

/// Genera y aplica las opciones de mejora que se muestran en
/// [UpgradeScreen] cada vez que el jugador sube de nivel.
class UpgradeSystem {
  UpgradeSystem({required this.random});

  final Random random;

  /// Construye una lista de [count] opciones de mejora distintas entre sí,
  /// teniendo en cuenta las armas que el jugador ya tiene equipadas para
  /// no ofrecer armas repetidas más allá de su nivel máximo.
  List<UpgradeOption> generateOptions({
    required List<WeaponInstance> equippedWeapons,
    int count = 3,
  }) {
    final pool = <UpgradeOption>[];

    // Opciones de "nueva arma" si aún hay slots de armas disponibles.
    final equippedTypes = equippedWeapons.map((w) => w.type).toSet();
    for (final type in WeaponType.values) {
      if (!equippedTypes.contains(type) && equippedWeapons.length < 4) {
        final archetype = WeaponArchetype.catalog[type]!;
        pool.add(UpgradeOption(
          id: 'new_weapon_${type.name}',
          kind: UpgradeKind.newWeapon,
          title: 'Nueva Arma: ${archetype.name}',
          description: 'Añade ${archetype.name} a tu arsenal',
          value: 1,
          weaponType: type,
        ));
      }
    }

    // Opciones de mejorar arma existente (si no está al máximo).
    for (final weapon in equippedWeapons) {
      if (!weapon.isMaxLevel) {
        pool.add(UpgradeOption(
          id: 'levelup_${weapon.type.name}',
          kind: UpgradeKind.weaponLevelUp,
          title: '${weapon.archetype.name} Nv.${weapon.level + 1}',
          description: 'Mejora tu ${weapon.archetype.name} al siguiente nivel',
          value: 1,
          weaponType: weapon.type,
        ));
      }
    }

    // Mejoras de estadísticas genéricas, siempre disponibles.
    pool.addAll([
      const UpgradeOption(
        id: 'stat_health',
        kind: UpgradeKind.maxHealth,
        title: 'Vitalidad +20',
        description: 'Aumenta tu vida máxima en 20 puntos',
        value: 20,
      ),
      const UpgradeOption(
        id: 'stat_speed',
        kind: UpgradeKind.speed,
        title: 'Velocidad +10%',
        description: 'Aumenta tu velocidad de movimiento',
        value: 0.10,
      ),
      const UpgradeOption(
        id: 'stat_damage',
        kind: UpgradeKind.damage,
        title: 'Daño +15%',
        description: 'Aumenta el daño de todas tus armas',
        value: 0.15,
      ),
      const UpgradeOption(
        id: 'stat_firerate',
        kind: UpgradeKind.fireRate,
        title: 'Cadencia +12%',
        description: 'Tus armas disparan más rápido',
        value: 0.12,
      ),
      const UpgradeOption(
        id: 'stat_crit',
        kind: UpgradeKind.critChance,
        title: 'Crítico +5%',
        description: 'Aumenta tu probabilidad de golpe crítico',
        value: 0.05,
      ),
      const UpgradeOption(
        id: 'stat_pickup',
        kind: UpgradeKind.pickupRadius,
        title: 'Imán +25%',
        description: 'Aumenta el radio de recolección de experiencia',
        value: 0.25,
      ),
      const UpgradeOption(
        id: 'stat_armor',
        kind: UpgradeKind.armor,
        title: 'Armadura +2',
        description: 'Reduce el daño recibido en 2 puntos',
        value: 2,
      ),
    ]);

    pool.shuffle(random);
    return pool.take(count).toList();
  }

  /// Aplica el efecto de una [UpgradeOption] elegida al modelo del jugador.
  void applyUpgrade(UpgradeOption option, PlayerData playerData) {
    switch (option.kind) {
      case UpgradeKind.maxHealth:
        playerData.stats.maxHealth += option.value;
        playerData.heal(option.value);
        break;
      case UpgradeKind.speed:
        playerData.stats.speed *= (1 + option.value);
        break;
      case UpgradeKind.damage:
        playerData.stats.damageMultiplier *= (1 + option.value);
        break;
      case UpgradeKind.fireRate:
        playerData.stats.fireRateMultiplier *= (1 + option.value);
        break;
      case UpgradeKind.critChance:
        playerData.stats.critChance += option.value;
        break;
      case UpgradeKind.pickupRadius:
        playerData.stats.pickupRadiusMultiplier *= (1 + option.value);
        break;
      case UpgradeKind.armor:
        playerData.stats.armor += option.value;
        break;
      case UpgradeKind.newWeapon:
      case UpgradeKind.weaponLevelUp:
        // Estos casos se gestionan en GameManager, que tiene acceso a la
        // lista de armas equipadas (no vive en PlayerData).
        break;
    }
  }
}
