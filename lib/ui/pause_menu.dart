import 'package:flutter/material.dart';
import 'package:pixel_defender/game/pixel_defender_game.dart';
import 'package:pixel_defender/managers/audio_manager.dart';

/// Overlay de pausa, mostrado encima del [GameWidget] cuando
/// [PixelDefenderGame.runState] es [GameRunState.paused].
class PauseMenu extends StatelessWidget {
  const PauseMenu({
    super.key,
    required this.game,
    required this.onResume,
    required this.onRestart,
    required this.onExitToMenu,
  });

  final PixelDefenderGame game;
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onExitToMenu;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Card(
            color: const Color(0xFF1E1E2A),
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'PAUSA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _MenuButton(
                    label: 'Continuar',
                    icon: Icons.play_arrow,
                    onPressed: () {
                      AudioManager.instance.playSfx(SfxType.uiClick);
                      onResume();
                    },
                  ),
                  const SizedBox(height: 12),
                  _MenuButton(
                    label: 'Reiniciar',
                    icon: Icons.refresh,
                    onPressed: () {
                      AudioManager.instance.playSfx(SfxType.uiClick);
                      onRestart();
                    },
                  ),
                  const SizedBox(height: 12),
                  _MenuButton(
                    label: 'Salir al menú',
                    icon: Icons.home,
                    onPressed: () {
                      AudioManager.instance.playSfx(SfxType.uiClick);
                      onExitToMenu();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.label, required this.icon, required this.onPressed});

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: const Color(0xFF2D2D40),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
