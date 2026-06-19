import 'package:pixel_defender/models/enemy_data.dart';

/// Define qué tipos de enemigos "normales" (no-boss) pueden aparecer en
/// una oleada dada, junto a su peso relativo de aparición.
///
/// A medida que avanzan las oleadas se desbloquean tipos más fuertes y los
/// débiles van perdiendo peso relativo, generando una sensación natural de
/// progresión de amenaza.
class EnemyTypeTable {
  EnemyTypeTable._();

  static Map<EnemyType, double> weightsForWave(int wave) {
    final weights = <EnemyType, double>{
      EnemyType.grunt: 10,
      EnemyType.runner: 0,
      EnemyType.tank: 0,
      EnemyType.ranged: 0,
    };

    if (wave >= 2) weights[EnemyType.runner] = 6;
    if (wave >= 3) weights[EnemyType.ranged] = 4;
    if (wave >= 4) weights[EnemyType.tank] = 3;

    // El grunt pierde peso relativo con el tiempo (pero nunca desaparece).
    weights[EnemyType.grunt] = (10 - wave * 0.4).clamp(3, 10);

    return weights;
  }

  static bool isBossWave(int wave, int bossInterval) =>
      wave > 0 && wave % bossInterval == 0;
}
