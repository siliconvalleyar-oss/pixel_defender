import 'package:flutter/material.dart';
import 'package:pixel_defender/managers/audio_manager.dart';
import 'package:pixel_defender/managers/save_manager.dart';
import 'package:pixel_defender/services/storage_service.dart';
import 'package:pixel_defender/systems/achievement_system.dart';

/// Pantalla de menú principal: punto de entrada tras el splash.
///
/// Ofrece jugar una nueva partida, comprar mejoras permanentes con las
/// monedas acumuladas (meta-progresión), ver logros, y acceder a ajustes.
class MainMenu extends StatefulWidget {
  const MainMenu({
    super.key,
    required this.onPlay,
    required this.onSettings,
  });

  final VoidCallback onPlay;
  final VoidCallback onSettings;

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  @override
  void initState() {
    super.initState();
    AudioManager.instance.playMenuMusic();
  }

  @override
  Widget build(BuildContext context) {
    final coins = StorageService.instance.coins;
    final highScore = StorageService.instance.highScore;

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E14),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              const Text(
                'PIXEL\nDEFENDER',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.monetization_on, color: Colors.amber, size: 18),
                  const SizedBox(width: 4),
                  Text('$coins', style: const TextStyle(color: Colors.white70)),
                  const SizedBox(width: 16),
                  const Icon(Icons.emoji_events, color: Colors.orangeAccent, size: 18),
                  const SizedBox(width: 4),
                  Text('$highScore', style: const TextStyle(color: Colors.white70)),
                ],
              ),
              const Spacer(),
              _MenuButton(
                label: 'JUGAR',
                icon: Icons.play_arrow,
                primary: true,
                onPressed: () {
                  AudioManager.instance.playSfx(SfxType.uiClick);
                  widget.onPlay();
                },
              ),
              const SizedBox(height: 12),
              _MenuButton(
                label: 'Mejoras',
                icon: Icons.upgrade,
                onPressed: () {
                  AudioManager.instance.playSfx(SfxType.uiClick);
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: const Color(0xFF1E1E2A),
                    isScrollControlled: true,
                    builder: (_) => const _PermanentUpgradesSheet(),
                  ).then((_) => setState(() {}));
                },
              ),
              const SizedBox(height: 12),
              _MenuButton(
                label: 'Logros',
                icon: Icons.emoji_events,
                onPressed: () {
                  AudioManager.instance.playSfx(SfxType.uiClick);
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: const Color(0xFF1E1E2A),
                    isScrollControlled: true,
                    builder: (_) => const _AchievementsSheet(),
                  );
                },
              ),
              const SizedBox(height: 12),
              _MenuButton(
                label: 'Ajustes',
                icon: Icons.settings,
                onPressed: () {
                  AudioManager.instance.playSfx(SfxType.uiClick);
                  widget.onSettings();
                },
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.primary = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: primary ? Colors.deepPurpleAccent : const Color(0xFF2D2D40),
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}

class _PermanentUpgradesSheet extends StatefulWidget {
  const _PermanentUpgradesSheet();

  @override
  State<_PermanentUpgradesSheet> createState() => _PermanentUpgradesSheetState();
}

class _PermanentUpgradesSheetState extends State<_PermanentUpgradesSheet> {
  @override
  void initState() {
    super.initState();
    SaveManager.instance.loadPermanentUpgrades();
  }

  @override
  Widget build(BuildContext context) {
    final upgrades = SaveManager.instance.permanentUpgrades;
    final coins = StorageService.instance.coins;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Mejoras Permanentes',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    const Icon(Icons.monetization_on, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text('$coins', style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...upgrades.map((upgrade) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    tileColor: const Color(0xFF14141C),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    title: Text(upgrade.name, style: const TextStyle(color: Colors.white)),
                    subtitle: Text(
                      '${upgrade.description}\nNivel ${upgrade.currentLevel}/${upgrade.maxLevel}',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    isThreeLine: true,
                    trailing: upgrade.isMaxed
                        ? const Icon(Icons.check_circle, color: Colors.greenAccent)
                        : TextButton(
                            onPressed: StorageService.instance.coins >= upgrade.nextCost
                                ? () async {
                                    await SaveManager.instance.purchasePermanentUpgrade(upgrade.id);
                                    setState(() {});
                                  }
                                : null,
                            child: Text('${upgrade.nextCost} 🪙'),
                          ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _AchievementsSheet extends StatelessWidget {
  const _AchievementsSheet();

  @override
  Widget build(BuildContext context) {
    final system = AchievementSystem();
    final unlocked = system.unlockedAchievements;
    final locked = system.lockedAchievements;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Logros',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: ListView(
                shrinkWrap: true,
                children: [
                  ...unlocked.map((a) => ListTile(
                        leading: const Icon(Icons.emoji_events, color: Colors.amber),
                        title: Text(a.title, style: const TextStyle(color: Colors.white)),
                        subtitle: Text(a.description, style: const TextStyle(color: Colors.white54)),
                      )),
                  ...locked.map((a) => ListTile(
                        leading: const Icon(Icons.lock, color: Colors.white24),
                        title: Text(a.title, style: const TextStyle(color: Colors.white38)),
                        subtitle: Text(a.description, style: const TextStyle(color: Colors.white24)),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
