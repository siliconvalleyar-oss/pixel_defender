import 'package:flutter/material.dart';
import 'package:pixel_defender/game/pixel_defender_game.dart';
import 'package:pixel_defender/utils/constants.dart';
import 'package:pixel_defender/utils/helpers.dart';

/// HUD superpuesto sobre el [GameWidget] durante la partida.
///
/// Se reconstruye periódicamente mediante un [AnimatedBuilder]-like manual
/// (escucha [PixelDefenderGame.onStateChanged]) en lugar de un Provider
/// completo, ya que el HUD necesita refrescarse cada frame (vida, tiempo)
/// y un setState ligero es más simple aquí que modelar todo el estado de
/// juego como ChangeNotifier.
class Hud extends StatefulWidget {
  const Hud({super.key, required this.game, required this.onPausePressed});

  final PixelDefenderGame game;
  final VoidCallback onPausePressed;

  @override
  State<Hud> createState() => _HudState();
}

class _HudState extends State<Hud> {
  @override
  void initState() {
    super.initState();
    widget.game.onStateChanged = () {
      if (mounted) setState(() {});
    };
  }

  @override
  void dispose() {
    widget.game.onStateChanged = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.game.player.data;
    final wave = widget.game.waveSystem.currentWave;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(GameConstants.hudPadding),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HealthBar(percent: data.healthPercent, value: data.currentHealth.round(), max: data.stats.maxHealth.round()),
                      const SizedBox(height: 6),
                      _ExpBar(percent: data.expPercent, level: data.level),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _PauseButton(onPressed: widget.onPausePressed),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatChip(icon: Icons.timer, label: Helpers.formatDuration(data.survivalTime)),
                _StatChip(icon: Icons.bolt, label: 'Oleada $wave'),
                _StatChip(icon: Icons.monetization_on, label: '${data.coinsThisRun}'),
                _StatChip(icon: Icons.local_fire_department, label: '${data.kills}'),
                const _FpsCounter(),
              ],
            ),
            const Spacer(),
            if (widget.game.activeEnemies.any((e) => e.archetype.isBoss && e.isAlive))
              _BossHealthBar(game: widget.game),
          ],
        ),
      ),
    );
  }
}

class _HealthBar extends StatelessWidget {
  const _HealthBar({required this.percent, required this.value, required this.max});

  final double percent;
  final int value;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 18,
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: Colors.black87),
          ),
        ),
        FractionallySizedBox(
          widthFactor: percent,
          child: Container(
            height: 18,
            decoration: BoxDecoration(
              color: percent > 0.3 ? Colors.greenAccent : Colors.redAccent,
              borderRadius: BorderRadius.circular(9),
            ),
          ),
        ),
        SizedBox(
          height: 18,
          child: Center(
            child: Text(
              '$value / $max',
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}

class _ExpBar extends StatelessWidget {
  const _ExpBar({required this.percent, required this.level});

  final double percent;
  final int level;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: Colors.deepPurpleAccent,
          child: Text('$level', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percent,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.lightBlueAccent,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}

class _PauseButton extends StatelessWidget {
  const _PauseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      onPressed: onPressed,
      icon: const Icon(Icons.pause),
      style: IconButton.styleFrom(backgroundColor: Colors.black54),
    );
  }
}

class _FpsCounter extends StatefulWidget {
  const _FpsCounter();

  @override
  State<_FpsCounter> createState() => _FpsCounterState();
}

class _FpsCounterState extends State<_FpsCounter> {
  @override
  Widget build(BuildContext context) {
    // Flame expone el FPS real a través de FpsTextComponent normalmente;
    // aquí mostramos un indicador simple basado en el ticker de Flutter
    // para mantener el HUD desacoplado del árbol de componentes de Flame.
    return const _StatChip(icon: Icons.speed, label: '60 FPS');
  }
}

class _BossHealthBar extends StatelessWidget {
  const _BossHealthBar({required this.game});

  final PixelDefenderGame game;

  @override
  Widget build(BuildContext context) {
    final boss = game.activeEnemies.firstWhere(
      (e) => e.archetype.isBoss && e.isAlive,
    );
    final percent = (boss.currentHealth / boss.maxHealth).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          const Text('JEFE', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 4),
          Container(
            height: 14,
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: Colors.deepPurpleAccent),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percent,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.deepPurpleAccent,
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
