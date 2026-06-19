import 'package:flutter/material.dart';
import 'package:pixel_defender/managers/audio_manager.dart';
import 'package:pixel_defender/models/player_data.dart';
import 'package:pixel_defender/services/storage_service.dart';
import 'package:pixel_defender/utils/helpers.dart';

/// Pantalla mostrada al morir el jugador, con un resumen de la partida
/// (tiempo sobrevivido, nivel, kills, monedas) y el récord histórico.
class GameOverScreen extends StatelessWidget {
  const GameOverScreen({
    super.key,
    required this.playerData,
    required this.wave,
    required this.onRetry,
    required this.onExitToMenu,
  });

  final PlayerData playerData;
  final int wave;
  final VoidCallback onRetry;
  final VoidCallback onExitToMenu;

  @override
  Widget build(BuildContext context) {
    final highScore = StorageService.instance.highScore;

    return Container(
      color: const Color(0xFF0E0E14),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.dangerous, color: Colors.redAccent, size: 56),
                  const SizedBox(height: 12),
                  const Text(
                    'HAS CAÍDO',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _StatRow(label: 'Tiempo sobrevivido', value: Helpers.formatDuration(playerData.survivalTime)),
                  _StatRow(label: 'Oleada alcanzada', value: '$wave'),
                  _StatRow(label: 'Nivel alcanzado', value: '${playerData.level}'),
                  _StatRow(label: 'Enemigos eliminados', value: '${playerData.kills}'),
                  _StatRow(label: 'Monedas obtenidas', value: '${playerData.coinsThisRun}'),
                  const Divider(color: Colors.white24, height: 32),
                  _StatRow(
                    label: 'Récord histórico',
                    value: '$highScore',
                    highlight: true,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        AudioManager.instance.playSfx(SfxType.uiClick);
                        onRetry();
                      },
                      icon: const Icon(Icons.replay),
                      label: const Text('Jugar de nuevo'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.deepPurpleAccent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        AudioManager.instance.playSfx(SfxType.uiClick);
                        onExitToMenu();
                      },
                      icon: const Icon(Icons.home),
                      label: const Text('Menú principal'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                      ),
                    ),
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

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value, this.highlight = false});

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              color: highlight ? Colors.amber : Colors.white,
              fontSize: highlight ? 18 : 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
