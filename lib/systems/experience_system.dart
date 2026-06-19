import 'package:pixel_defender/models/player_data.dart';

/// Encapsula la lógica de progresión de experiencia/nivel.
///
/// Se mantiene separado de [PlayerData] (que es el modelo de datos) para
/// que la lógica de "qué pasa cuando subo de nivel" (notificar a la UI,
/// disparar la pantalla de mejoras, etc.) viva en un solo lugar.
class ExperienceSystem {
  ExperienceSystem({required this.playerData, this.onLevelUp});

  final PlayerData playerData;

  /// Callback invocado una vez por cada nivel ganado. Recibe el nuevo nivel.
  void Function(int newLevel)? onLevelUp;

  /// Añade experiencia al jugador y dispara [onLevelUp] tantas veces como
  /// niveles se hayan ganado (normalmente 1, pero puede ser más con gemas
  /// grandes o jefes).
  void grantExperience(int amount) {
    final levelsGained = playerData.addExperience(amount);
    for (int i = 0; i < levelsGained; i++) {
      onLevelUp?.call(playerData.level);
    }
  }
}
