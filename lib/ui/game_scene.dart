import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:pixel_defender/game/pixel_defender_game.dart';
import 'package:pixel_defender/managers/game_manager.dart';
import 'package:pixel_defender/models/upgrade_data.dart';
import 'package:pixel_defender/systems/achievement_system.dart';
import 'package:pixel_defender/ui/game_over_screen.dart';
import 'package:pixel_defender/ui/hud.dart';
import 'package:pixel_defender/ui/pause_menu.dart';
import 'package:pixel_defender/ui/upgrade_screen.dart';
import 'package:pixel_defender/ui/virtual_joystick.dart';

/// Escena de juego: combina el [GameWidget] (renderizado de Flame) con
/// toda la UI de Flutter superpuesta (HUD, joystick, pausa, mejoras,
/// game over). Esta separación —Flame para el mundo del juego, Flutter
/// widgets para la UI— es el patrón recomendado por el propio motor Flame.
class GameScene extends StatefulWidget {
  const GameScene({
    super.key,
    required this.onExitToMenu,
  });

  final VoidCallback onExitToMenu;

  @override
  State<GameScene> createState() => _GameSceneState();
}

class _GameSceneState extends State<GameScene> {
  late PixelDefenderGame _game;

  GameRunState _runState = GameRunState.running;
  List<UpgradeOption> _upgradeOptions = [];
  Achievement? _toastAchievement;

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  void _startGame() {
    _game = GameManager.instance.startNewGame();
    _game.onPlayerDeath = () => setState(() => _runState = GameRunState.gameOver);
    _game.onLevelUpReady = (options) {
      setState(() {
        _upgradeOptions = options;
        _runState = GameRunState.leveling;
      });
    };
    _game.onAchievementUnlocked = (achievement) {
      setState(() => _toastAchievement = achievement);
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _toastAchievement = null);
      });
    };
    _runState = GameRunState.running;
  }

  void _togglePause() {
    _game.togglePause();
    setState(() => _runState = _game.runState);
  }

  void _restart() {
    GameManager.instance.endGame();
    setState(_startGame);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF14141C),
      body: Stack(
        children: [
          GameWidget(game: _game),

          // HUD siempre visible mientras hay partida (incluso en pausa, para
          // contexto visual; los controles quedan deshabilitados por el overlay).
          if (_runState != GameRunState.gameOver)
            Hud(game: _game, onPausePressed: _togglePause),

          // Joystick virtual, solo activo durante el juego en curso.
          if (_runState == GameRunState.running)
            Positioned(
              left: 24,
              bottom: 24,
              child: VirtualJoystick(
                onChanged: (direction) => _game.setJoystickInput(direction),
              ),
            ),

          if (_toastAchievement != null)
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Center(child: _AchievementToast(achievement: _toastAchievement!)),
            ),

          if (_runState == GameRunState.paused)
            PauseMenu(
              game: _game,
              onResume: _togglePause,
              onRestart: _restart,
              onExitToMenu: () {
                GameManager.instance.endGame();
                widget.onExitToMenu();
              },
            ),

          if (_runState == GameRunState.leveling)
            UpgradeScreen(
              options: _upgradeOptions,
              onSelected: (option) {
                _game.applyUpgradeChoice(option);
                setState(() => _runState = _game.runState);
              },
            ),

          if (_runState == GameRunState.gameOver)
            GameOverScreen(
              playerData: _game.player.data,
              wave: _game.waveSystem.currentWave,
              onRetry: _restart,
              onExitToMenu: () {
                GameManager.instance.endGame();
                widget.onExitToMenu();
              },
            ),
        ],
      ),
    );
  }
}

class _AchievementToast extends StatelessWidget {
  const _AchievementToast({required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events, color: Colors.amber),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Logro desbloqueado', style: TextStyle(color: Colors.amber, fontSize: 11)),
              Text(achievement.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
