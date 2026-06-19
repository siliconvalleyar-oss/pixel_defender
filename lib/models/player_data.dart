import 'package:pixel_defender/utils/constants.dart';
import 'package:pixel_defender/utils/helpers.dart';

/// Estadísticas mejorables del jugador durante una partida.
///
/// Esta clase es un modelo de datos puro: no conoce Flame ni renderizado.
/// El [PlayerComponent] la usa como fuente de verdad para su comportamiento.
class PlayerStats {
  PlayerStats({
    double? maxHealth,
    double? speed,
    this.damageMultiplier = 1.0,
    this.fireRateMultiplier = 1.0,
    this.critChance = GameConstants.criticalHitChanceBase,
    this.critMultiplier = GameConstants.criticalHitMultiplier,
    this.pickupRadiusMultiplier = 1.0,
    this.armor = 0,
  })  : maxHealth = maxHealth ?? GameConstants.playerBaseMaxHealth,
        speed = speed ?? GameConstants.playerBaseSpeed;

  double maxHealth;
  double speed;
  double damageMultiplier;
  double fireRateMultiplier;
  double critChance;
  double critMultiplier;
  double pickupRadiusMultiplier;
  double armor; // reduce daño plano antes del porcentaje

  PlayerStats copy() => PlayerStats(
        maxHealth: maxHealth,
        speed: speed,
        damageMultiplier: damageMultiplier,
        fireRateMultiplier: fireRateMultiplier,
        critChance: critChance,
        critMultiplier: critMultiplier,
        pickupRadiusMultiplier: pickupRadiusMultiplier,
        armor: armor,
      );
}

/// Estado de progresión del jugador dentro de la partida actual
/// (vida, experiencia, nivel, monedas recolectadas).
class PlayerData {
  PlayerData({PlayerStats? stats})
      : stats = stats ?? PlayerStats(),
        currentHealth = (stats ?? PlayerStats()).maxHealth;

  final PlayerStats stats;

  double currentHealth;
  int level = 1;
  int currentExp = 0;
  int coinsThisRun = 0;
  int kills = 0;
  double survivalTime = 0;

  bool get isDead => currentHealth <= 0;

  int get expToNextLevel => Helpers.expRequiredForLevel(
        level,
        GameConstants.baseExpToLevelUp,
        GameConstants.expCurveMultiplier,
      );

  double get healthPercent =>
      (currentHealth / stats.maxHealth).clamp(0.0, 1.0);

  double get expPercent => (currentExp / expToNextLevel).clamp(0.0, 1.0);

  /// Aplica daño considerando armadura. Devuelve el daño real aplicado.
  double applyDamage(double rawDamage) {
    final mitigated = (rawDamage - stats.armor).clamp(1.0, double.infinity);
    currentHealth = (currentHealth - mitigated).clamp(0.0, stats.maxHealth);
    return mitigated;
  }

  void heal(double amount) {
    currentHealth = (currentHealth + amount).clamp(0.0, stats.maxHealth);
  }

  /// Añade experiencia y devuelve cuántos niveles subió (0 si ninguno).
  int addExperience(int amount) {
    currentExp += amount;
    int levelsGained = 0;
    while (currentExp >= expToNextLevel) {
      currentExp -= expToNextLevel;
      level++;
      levelsGained++;
    }
    return levelsGained;
  }
}
