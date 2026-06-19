import 'package:flutter/material.dart';
import 'package:pixel_defender/managers/audio_manager.dart';
import 'package:pixel_defender/models/upgrade_data.dart';

/// Overlay mostrado al subir de nivel, presentando 3 opciones de mejora
/// entre las que el jugador debe elegir una para continuar.
class UpgradeScreen extends StatelessWidget {
  const UpgradeScreen({
    super.key,
    required this.options,
    required this.onSelected,
  });

  final List<UpgradeOption> options;
  final ValueChanged<UpgradeOption> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '¡SUBISTE DE NIVEL!',
              style: TextStyle(
                color: Colors.amber,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Elige una mejora',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: options
                    .map(
                      (option) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                        child: _UpgradeCard(
                          option: option,
                          onTap: () {
                            AudioManager.instance.playSfx(SfxType.uiClick);
                            onSelected(option);
                          },
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpgradeCard extends StatelessWidget {
  const _UpgradeCard({required this.option, required this.onTap});

  final UpgradeOption option;
  final VoidCallback onTap;

  IconData get _icon {
    switch (option.kind) {
      case UpgradeKind.newWeapon:
        return Icons.add_circle;
      case UpgradeKind.weaponLevelUp:
        return Icons.upgrade;
      case UpgradeKind.maxHealth:
        return Icons.favorite;
      case UpgradeKind.speed:
        return Icons.directions_run;
      case UpgradeKind.damage:
        return Icons.bolt;
      case UpgradeKind.fireRate:
        return Icons.speed;
      case UpgradeKind.critChance:
        return Icons.flash_on;
      case UpgradeKind.pickupRadius:
        return Icons.radar;
      case UpgradeKind.armor:
        return Icons.shield;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1E1E2A),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.deepPurpleAccent.withValues(alpha: 0.2),
                child: Icon(_icon, color: Colors.deepPurpleAccent),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      option.description,
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white30),
            ],
          ),
        ),
      ),
    );
  }
}
