import 'package:pixel_defender/game/pixel_defender_game.dart';
import 'package:pixel_defender/managers/save_manager.dart';
import 'package:pixel_defender/models/player_data.dart';

/// Orquesta la creación de una nueva partida ([PixelDefenderGame]),
/// aplicando las mejoras permanentes compradas en la meta-progresión
/// antes de que comience el primer frame.
///
/// Mantiene una única instancia "viva" de [PixelDefenderGame] mientras el
/// usuario está en GameScene/PauseMenu/UpgradeScreen/GameOverScreen, y la
/// descarta al volver al menú principal o iniciar una partida nueva.
class GameManager {
  GameManager._();
  static final GameManager instance = GameManager._();

  PixelDefenderGame? _currentGame;

  PixelDefenderGame get currentGame {
    final game = _currentGame;
    if (game == null) {
      throw StateError(
        'No hay partida activa. Llama a GameManager.instance.startNewGame() primero.',
      );
    }
    return game;
  }

  bool get hasActiveGame => _currentGame != null;

  /// Crea una nueva instancia de juego, aplicando las mejoras permanentes
  /// (meta-progresión) como bonificaciones iniciales del [PlayerData].
  PixelDefenderGame startNewGame() {
    SaveManager.instance.loadPermanentUpgrades();

    final playerData = PlayerData();
    playerData.stats.maxHealth +=
        SaveManager.instance.getPermanentBonus('perm_health');
    playerData.currentHealth = playerData.stats.maxHealth;
    playerData.stats.damageMultiplier *=
        1 + SaveManager.instance.getPermanentBonus('perm_damage');
    playerData.stats.speed *=
        1 + SaveManager.instance.getPermanentBonus('perm_speed');

    final game = PixelDefenderGame(initialPlayerData: playerData);
    _currentGame = game;
    return game;
  }

  void endGame() {
    _currentGame = null;
  }
}
